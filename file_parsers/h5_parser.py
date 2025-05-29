#!/usr/bin/env python3

import h5py
import numpy as np
import pandas as pd
import argparse
pd.options.mode.copy_on_write = True

# -k 10x --which_cells all -t 5000 10000 -i /fh/fast/_IRC/FHIL/user/dgratz/h5_parser/GEMX3p-F1A_raw_molecule_info.h5 -o /fh/fast/_IRC/FHIL/user/dgratz/h5_parser/test/test_out.csv

def parse_arguments():
    parser = argparse.ArgumentParser(description="Downsample counts from an HDF5 file.")
    parser.add_argument(
        '-i', "--h5_file", 
        type=str, 
        required=True, 
        help="Path to the HDF5 file (e.g., GEMX3p-F1A_raw_molecule_info.h5)"
    )
    parser.add_argument(
        "--downsample_by", 
        type=str, 
        choices=['read', 'umi'], 
        default='read', 
        help="Downsample by 'read' or 'umi' (default: 'read')"
    )
    parser.add_argument(
        "--which_cells", 
        type=str, 
        choices=['all', 'called'], 
        default='all', 
        help="Consider 'all' cells or only 'called' cells (default: 'all')"
    )
    parser.add_argument(
        '-t', "--target_reads_per_cell", 
        type=int, 
        nargs='+', 
        default=[5000, 7500, 10000, 12500, 15000, 17500, 20000, 22500, 25000],
        help="Target number of reads per cell for downsampling (default: 5000-25000 by 2500 step increments)"
    )
    parser.add_argument(
        '-o', "--output_file", 
        type=str, 
        default="downsample_results.csv", 
        help="Output file to save the results (default: downsample_results.csv)"
    )
    parser.add_argument(
        '-r', "--random_seed", 
        type=int, 
        default=35, 
        help="Seed for random sampling (default: 35)"
    )
    parser.add_argument(
        '-k', "--kit", 
        type=str, 
        required=True,
        choices=['10x', 'Fluent'], 
        help="Kit vendor pipeline that produced h5 (choices: 10x, Fluent)"
    )
    parser.add_argument(
        '-c', "--called_cells_file", 
        type=str, 
        help="File of passing barcodes based on sensitivity chioce for Fluent"
    )
    return parser.parse_args()

def read_h5(h5_file, kit, called_cells_file):
    print('parsing h5 file')
    kit_columns_10x = {
        'reads':'/count',
        'umi':'umi',
        'barcode_idx':'/barcode_idx',
        'feature_idx':'/feature_idx',
        'passing_barcodes':'/barcode_info/pass_filter'
    }
    kit_columns_fluent = {
        'reads':'/counts',
        'umi':'mis',
        'barcode_idx':'/barcodes',
        'feature_idx':'/genes',
        'passing_barcodes':''
    }
    if kit == '10x':
        kit_columns = kit_columns_10x
    elif kit == 'Fluent':
        kit_columns = kit_columns_fluent
    with h5py.File(h5_file, 'r') as h5:
        data = pd.DataFrame({
            'umi': h5[kit_columns['umi']][:],  # 2bit encoded
            'reads': h5[kit_columns['reads']][:],#.astype(np.uint32),  # counts per UMI
            'barcode_idx': h5[kit_columns['barcode_idx']][:],#.astype(np.uint64),
            'feature_idx': h5[kit_columns['feature_idx']][:]#.astype(np.uint32)
        })
        if kit == '10x':
            passing_barcodes = h5[kit_columns['passing_barcodes']][:, 0]
        elif kit == 'Fluent':
            ## the csv is 1 indexed, the h5 is 0 indexed hahahahahahahahahahahahaha
            passing_barcodes = pd.read_table(called_cells_file, header=None).squeeze() - 1
        data['called_cell'] = np.isin(data['barcode_idx'], passing_barcodes)
    print('h5 parsing complete')
    return (data, passing_barcodes)

def downsample_counts(arr, target_count):
    # if sum(arr) <= target_count:
    #     return arr 
    indices = np.repeat(np.arange(len(arr)), arr)
    sampled_indices = np.random.choice(indices, size=target_count, replace=False)
    downsampled_counts = np.bincount(sampled_indices, minlength=len(arr))
    return pd.Series(downsampled_counts)

def summarise(data, grouping='barcode_idx'): #, filtering_query='called_cell and downsampled_counts > 0'
    ## Only UMIs with nonzero reads
    data = data.query('downsampled_counts > 0')
    data = (
            ## only UMIs in called cells
            data.query('called_cell') #[(data['called_cell']) & (data['downsampled_counts'] > 0)]
            .groupby(grouping)
            .agg(
                gene_count=('feature_idx', 'nunique'),
                umi_count=('feature_idx', 'count'),
                read_count=('downsampled_counts', 'sum')
            )
        )
    cells = data.shape[0]
    result = {
        'median_gene_count': data['gene_count'].median(),
        'median_umi_count': data['umi_count'].median(),
        'mean_reads_in_cells': data['read_count'].mean().round(),
        'cells': cells # rowcounts
    }
    return pd.Series(result)

def downsample(data, target_reads, which_cells, downsample_by):
    if which_cells == 'called':
        data = data[data['called_cell']]
    if downsample_by == 'read':
        if sum(data['reads']) > target_reads:
            data['downsampled_counts'] = downsample_counts(data['reads'], target_reads)
        else:
            data['downsampled_counts'] = data['reads']
        # remove UMIs with no supporting reads left
        # data = data[data['downsampled_counts'] > 0]
        result = summarise(data)
    return result

def count_reads_in_cells(data):
    return sum(data[data['called_cell']]['reads'])


def main():
    args = parse_arguments()
    np.random.seed(args.random_seed)
    data, passing_barcodes = read_h5(args.h5_file, args.kit, args.called_cells_file)
    data_summary = downsample(data, sum(data['reads']), args.which_cells, args.downsample_by )
    print('Data summary:')
    print(data_summary)
    results = []
    for target_reads_per_cell in args.target_reads_per_cell:
        target_reads = target_reads_per_cell * len(passing_barcodes)
        median_results = downsample(data, target_reads, args.which_cells, args.downsample_by)
        print(f"Results for target reads per cell = {target_reads_per_cell}:")
        print(median_results)
        median_results['target_reads_per_cell'] = target_reads_per_cell
        results.append(median_results)
    with open(args.output_file, 'w') as f:
        total_reads = sum(data['reads'])
        reads_in_cells = count_reads_in_cells(data)
        header=f"##Total_reads:{total_reads};reads_in_cells:{reads_in_cells};ratio:{round(reads_in_cells / total_reads, 4)}\n"
        f.write(header)  # Write the comment header
        results_df = pd.DataFrame(results)
        results_df.to_csv(f, index=False)
    print(f"Results saved to {args.output_file}")

if __name__ == "__main__":
    main()

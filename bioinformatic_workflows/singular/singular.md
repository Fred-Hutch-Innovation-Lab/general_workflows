# Singular data analysis guide

This guide is for working with Singular g4x data after sequencing. The platform is still in development (as of 2025-10-27), so there are not many published resources for working with data in 3rd party ecosystems. This is likely to change as Singular is developing resources internally, but they are not yet public. If you are referring to this sometime in the future, check Singular's website for updated guides.

# Receiving singular data

See the `Singular External Client sFTP Usage Guide.pdf` for details on connecting to Singular's data transfer portal. Singular data outputs can be multiple terabytes, so you will likely want to use a FTP for faster & more stable downloads. Data then needs to be extracted for use with 3rd party tools. The extracted data is not much larger than the compressed data (< 2x in my experience), but make sure you have enough space on whatever drive you're working with. 

`tar -xzvf <file>` 

# Loading Singular data

Python is the preferred ecosystem for working with Singular data, as there are more spatial analysis packages in Python than R and the computational advantages of Python making working with large spatial datasets easier. 

There are currently 2 methods for loading data into python. One is to just use the h5 file in the `single_cell_data` output folder. This will give you an anndata object that also retains spatial coordinates. This is simpler and covers lots of use cases. However, it does not include the images, point level information, or segmentation mask. These may not be necessary for your analysis, so you should only worry about them if you need them. 

Loading the h5 can be done with the `io` module of the `anndata` package

```{python}
from anndata import io as aio
obj = aio.read_h5ad("singular_outputs/A01/single_cell_data/feature_matrix.h5")
```

Move the coordiantes from the `.obs` to `.uns` for compatibility with `squidpy` spatial plotting api.

```{python}
spatial_array = np.array(list(zip(obj.obs['cell_x'], obj.obs['cell_y'])))
obj.obs = obj.obs.loc[:, ~obj.obs.columns.isin(["cell_x", "cell_y", "expanded_cell_x", "expanded_cell_y"])]
obj.obsm['spatial'] = spatial_array
```

## Advanced loading of full spatial object as Zarr

A [pull request](https://github.com/scverse/spatialdata-io/pull/281) is open on the `spatialdata-io` package for reading singular data. You can install this PR, then load the data with the following:

```{python}
import spatialdata_io as sio

## Necessary for loading singular data to avoid crashing
import PIL
PIL.Image.MAX_IMAGE_PIXELS = 5000000000

obj = sio.g4x(
    here(f"02_data/01_raw-data/singular/"),
    include_he = False,
    include_segmentation = True,
    include_protein = False,
    include_transcripts = True,
    include_tables = True,
    mode="append"
)
```

The first time you load the data, it may take 30 mins to several hours, especially if you choose to include the images. The data is written out to a Zarr as it is loaded. Subsequent loadings should take a minute or two. With `mode="append"`, subsequent re-runs of `sio.g4x` with different inclusions will load what has already been converted to Zarr and convert any new data inclusions. 

# Protein data

Protein data is caclulated at the cell-level internally in the singular data and is available in the `.obs` of the spatialdata object as cell-level metadata columns labeled `<protein>-intensity`. This is convenient for quick loading and visualization, but you may want to load the protein data as it's own assay/object for more involved analyses like using protein data for clustering and UMAPs. The workflow below shows how to parse the protein data into a separate layer of a [mudata](https://mudata.readthedocs.io/en/latest/index.html) object. 

```{python}
from anndata import io as aio
import anndata as ad
import muon as mu
from muon import MuData

def parse_singular_h5(file):
    obj = aio.read_h5ad(file)
    obj_obs = obj.obs
    protein_mask = obj_obs.columns.str.contains("intensity_mean")
    
    rna_data = obj.copy()
    rna_data.obs = obj.obs.loc[:, ~protein_mask]
    spatial_array = np.array(list(zip(obj.obs['cell_x'], obj.obs['cell_y'])))
    rna_data.obs = rna_data.obs.loc[:, ~rna_data.obs.columns.isin(["cell_x", "cell_y", "expanded_cell_x", "expanded_cell_y"])]
    
    protein_data = ad.AnnData(obj_obs.loc[:, protein_mask])
    
    ## Append protein identifier to features in case they collide with gene names
    protein_data.var_names = [x.removesuffix('_intensity_mean') for x in protein_data.var.index]
    protein_data.var_names = [x + '_prot' for x in protein_data.var.index]
    
    mdata = mu.MuData({'rna': rna_data, 'prot': protein_data})

    mdata.obsm['spatial'] = spatial_array
    mdata['rna'].obsm['spatial'] = spatial_array
    mdata['prot'].obsm['spatial'] = spatial_array
    mu.pp.intersect_obs(mdata)
    return mdata

```


# Proseg resegmentation

Proseg does not yet have full support for Singular data, but you can still run it to produce improved transcript assignment. Additionally, singular has now rolled out their 'g4x-helpers' library that allows resegmentation of protein data with a resegmented mask.

## Run proseg

Note that Zarr input support is a newer (3.0.10) feature of proseg, so you need an updated proseg install to use this code. You will also have to run the accessory g4x loader to convert their output to Zarr format (see *Advanced loading of full spatial object as Zarr* section). Then, run proseg to also output the geojson object (disabled by default in the newer versions). Note that the coordinate scaling is necessary for priors in Proseg to be accurate.

```{bash}
proseg \
    --x-column x \
    --y-column y \
    --z-column z_level \
    --gene-column gene_name \
    --cell-id-column cell_id \
    --cell-id-unassigned 0 \
    --coordinate-scale 0.3125 \
    --excluded-genes "^(NCS|NCP|gdna)" \
    --zarr-shape nuclei_shapes \
    --zarr-shape-geometry-column geometry \
    --zarr-shape-cell-id-column label \
    --zarr \
    --output-cell-polygons cell-polygons.geojson.gz \
    --output-spatialdata proseg-output.zarr \
    singular-input.zarr
```

This will produce a spatialdata Zarr you can directly load into Python, or you can run the following steps to resegment the Protein data.

## Resegment g4x helper

The `g4x-helper` suite is very new, so this could change. [See documentation](https://docs.singulargenomics.com/G4X-helpers/features/resegment/)

The coordinate scaling from Proseg needs to be reverted to make the coordinates back in the scale of the original dataset. This can be done in python by loading in the Proseg output geojson, scaling the geographies, and writing a geojson back out.

You may have to unzip the Proseg geojson output.

```{python}
import geopandas as gpd
from shapely import affinity
reseg_geojson = gpd.read_file(here("02_data/02_data-processing/C01-cell-polygons.geojson"))
scale_factor = 1/0.3125
reseg_geojson['geometry'] = reseg_geojson['geometry'].apply(
    lambda geom: affinity.scale(geom, xfact=scale_factor, yfact=scale_factor, origin=(0,0))
)
output_path = here("02_data/02_data-processing/C01-cell-polygons_scaled.geojson")
reseg_geojson.to_file(output_path, driver="GeoJSON")
```

Then you can load the scaled proseg mask with the helper tool to get resegmentation of proteins. Note that the reseg tool requires the cell mask geojson to be unzipped.

```{bash}
resegment \
  --run_base /path/to/G4X/output \
  --segmentation_mask /path/to/scaled_proseg_mask.geojson \
  --segmentation_mask_key cell

  # ─── optional ───
  # --sample_id <sample_id> 
  # --out_dir <output_dir> 
  # --threads <n_threads> 
  # --verbose <level>
```

If you're struggling to install `g4x-helper` package, you can use their provided docker container with Apptainer on the HPC, provided you set `--fakeroot` (to access helpers in `/app`) and `--writable-tmpfs` (for `matplotlib` deps). E.g.:

```{bash}
ml Apptainer
apptainer run \
    --bind /fh/fast/_IRC/FHIL/grp/analyses/bm04/ \
    --fakeroot \
    --writable-tmpfs \
    docker://ghcr.io/singular-genomics/g4x-helpers:v0.5.2 \
    resegment \
    --run_base /fh/fast/_IRC/FHIL/grp/analyses/bm04/02_data/01_raw-data/singular/B01/ \
    --segmentation_mask /fh/fast/_IRC/FHIL/grp/analyses/bm04/02_data/02_data-processing/B01-cell-polygons_scaled.geojson  \
    --segmentation_mask_key cell \
    --threads 32 \
    --out_dir B01-resegmentation-output \
    --verbose 1
```

## Merging protein data (old)

**This is an older workflow prior to the resegmentation support (see prior section). It is probably not needed, but kept here for reference posterity.**

Protein data is output as a cell-level corrected expression. There does not appear to be point-level information for protein. I do not have a workflow for re-segmenting protein data with new segmentation masks. This may be possible by using the protein images and working with some software like Sopa or Napari to translate the image to point-level information, but that is more complicated than I was willing to undertake for this pilot. 

For now, the workflow is to use the cell-level protein count info in the original Singular outputs and join them to the proseg outputs using the original cell IDs that seed Proseg's resegmentation. Proseg's cell-level metadata includes an `original_cell_id` column which maps to the original data. Be careful however, as the non-descript index of the Singular `.obs` does not map linearly to the `original_cell_id`. They seem to be close, but not exact, and there is some shuffling. If your protein data is in Zarr format, there is a `label` column in the `.obs` that has the cell ID used by Proseg. You can retrieve the protein data like so 

```{python}
protein_data = spatialdata.read_zarr(here(f"02_data/01_raw-data/singular/{file_id}/{file_id}.zarr"))
protein_data = protein_data.tables['table'].obs.reset_index(drop=True).set_index('label')
protein_mask = protein_data.columns.str.contains("intensity_mean")
```

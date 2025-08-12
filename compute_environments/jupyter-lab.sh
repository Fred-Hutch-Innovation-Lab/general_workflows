## Run with jupyter

## Ideally run this with a screen and grabnode session
## screen
## grabnode
ml purge #don't load jupyter module, rely on UV 
ml uv
uv run --with jupyter jupyter lab --ip=$(hostname) --port=$(fhfreeport) --no-browser

## https://code.visualstudio.com/docs/datascience/jupyter-kernel-management#_existing-jupyter-server
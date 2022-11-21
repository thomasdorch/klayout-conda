# KLayout-GUI
[Work-in-progress]

This is a recipe for building KLayout with GUI on Windows as a conda package using the MSVC2017 compiler and is intended to supplement [this effort](https://github.com/conda-forge/staged-recipes/pull/20396).

For the time being, the package can be installed from [my Anaconda channel](https://anaconda.org/thomasdorch/klayout-gui) with:

```
conda install -c thomasdorch klayout-gui
```

This package installs both the GUI (without a start-menu shortcut) and the KLayout Python package to the conda environment so the full KLayout Python API is accessable from the environment.

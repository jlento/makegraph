# makegraph
Visualize GNU Make data base

## Guide for makefiles
- there must not be a rule for initial input files, i.e. files that make should
  not consider targets

## Examples
### Simple workflow example
Generate graph with

    cd examples/workflow_1
    ../../makegraph
    
Open file `index.html` with browser and click target `all` to expand the
svg-image. Existing pre-requirements (files) should be green, missing
pre-requirements red, and the ones that make considers to be targets blue. Phony
targets, i.e. targets that are not files, should be transparent.

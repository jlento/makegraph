# makegraph

Visualize GNU Make data base

## How makegraph works
Currently `makegraph` command

1. dry-runs `make` and outputs the data base in text format
2. parses the `make` output to simple text format files, one file for
   each (recursive) make invocation
3. generates a static svg-images from from the simple text files
4. generates an index page `index.html` for the svg-images 

In future, hopefully, `makegraph` command

1. dry-runs `make` and outputs the data base in text format
2. parses the `make` output to single json-file
3. generates the image(s) from the json-data in browser

## How to read the svg-files

After running `makegraph`, open file `index.html` with browser and click any of the sub-makes listed to open the svg-images.

The nodes, i.e. make targets, are colored.

green : existing pre-requirements and up-to-date files
red : missing pre-requirements that do not have an associated rule
blue : targets that make considers for remaking are

Phony targets, i.e. targets that are not files, are transparent. Full path
names of the nodes are shown when cursor is hovered over.

Dependencies are shown with lines. The targets are on the right and their dependencies on the left.

## Advice for makefiles

- there must not be a rule for initial input files, i.e. files that make should
  not consider targets

## Examples

### Any makefile

Pick any project, which uses GNU Make, and run `makegraph` instead of `make`,

    cd /your/project/build/dir
    /path/to/makegraph [any make options you would normally give to make]


### Simple workflow example

Generate graph with

    cd examples/workflow_1
    ../../makegraph

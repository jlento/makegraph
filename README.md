# makegraph

Visualize GNU Make data base

## Project status

Please consider the current state as a "scetch" or proof-of-concept.

## How to draw make dependency graph

### Generate graph

Use script `makegraph` to

1. dry-run GNU Make instead of actually running `make`
2. convert the GNU Make "debug" and "data base" output to JSON
3. wrap the JSON data into a single html file, along with the JavaScript code
   that takes care of the visualization

The arguments to `makegraph` are passed to `make`, so you can run for example

```bash
./makegraph -C ../elmerfem/build > index.html
```

The produced file may be large, depending on the graph, but compresses very
well, with for example

```bash
gzip -k index.html
```

### Open the graph in a browser

Open the file in a browser, for example, with:

```bash
chromium-browser index.html
```

Zoom and translate the graph as usual.


### Export SVG

Install some "Export SVG" browser plugin to export to plain SVG.


## How to interpret the figures

The nodes, i.e. make targets, are colored.

- green : existing pre-requirements and up-to-date files
- red : missing pre-requirements that do not have an associated rule
- blue : targets that make considers for remaking

Phony targets, i.e. targets that are not files, are transparent. Full path
names of the nodes are shown when cursor is hovered over.

Dependencies are shown with lines. The targets are on the right and their
dependencies on the left.

## Advice for the makefiles

- there should not be a rule for initial input files, i.e. files that make
  should not consider targets
- avoid phony targets
- avoid the use of recursive make

#!/bin/bash

# Howto visualize the cmake generated build of the Elmer FEM software

git clone https://github.com/ElmerCSC/elmerfem.git
mkdir build
cd $_
cmake ../elmerfem
../../../makegraph > ../index.html
chromium-browser ../index.html


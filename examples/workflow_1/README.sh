#!/bin/bash

# How to visualize a simple workflow Makefile

../../makegraph > index.html
chromium-browser index.html

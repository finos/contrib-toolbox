#!/bin/bash
mkdir -p build
cp *.py *.yaml setup.cfg build
pip install pyyaml -t build
pip install PyGithub -t build
zip -r build.zip build

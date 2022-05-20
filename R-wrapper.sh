#!/bin/bash

# set TMPDIR variable
export TMPDIR=$_CONDOR_SCRATCH_DIR

Rscript mcpi.R $1
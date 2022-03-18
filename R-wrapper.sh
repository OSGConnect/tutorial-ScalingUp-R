#!/bin/bash

# set TMPDIR variable
export TMPDIR=$_CONDOR_SCRATCH_DIR

module load r
Rscript --no-save $1

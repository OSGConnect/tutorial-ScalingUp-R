#!/bin/bash
 source /cvmfs/oasis.opensciencegrid.org/osg/modules/lmod/current/init/bash
 module load R
 Rscript $1 > mcpi.$2.out

#!/bin/bash
cat mcpi*.out | awk '{ sum += $2; print $2} END { print "---------------\n" sum/NR"  " NR }'

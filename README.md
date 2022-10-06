---
ospool:
    path: software_examples/r/tutorial-ScalingUp-R/README.md
---

# Scaling up compute resources

Scaling up the computational resources is a big advantage for doing
certain large scale calculations on OSG. Consider the extensive
sampling for a multi-dimensional Monte Carlo integration or molecular
dynamics simulation with several initial conditions. These type of
calculations require submitting lot of jobs.

In the previous example, we submitted the job to a single worker
machine. About a million CPU hours per day are available to OSG users
on an opportunistic basis.  Learning how to scale up and control large
numbers of jobs to realizing the full potential of distributed high
throughput computing on the OSG.

In this section, we will see how to scale up the calculations with
simple example. Once we understand the basic HTCondor script, it is easy
to scale up.

## Background

For this example, we will use computational methods to estimate pi. First,
we will define a square inscribed by a unit circle from which we will 
randomly sample points. The ratio of the points outside the circle to 
the points in the circle is calculated which approaches pi/4. 

This method converges extremely slowly, which makes it great for a 
CPU-intensive exercise (but bad for a real estimation!).

## Set up an R Job

First, we'll need to create a working directory, you can either run 
`$ tutorial ScalingUp-R` or type the following:

    $ mkdir tutorial-ScalingUp-R
    $ cd tutorial-ScalingUp-R

## Create and test an R Script

Create an R script by typing the following into a file called `mcpi.R`:

	args = commandArgs(trailingOnly = TRUE)
	iternum = as.numeric(args[[1]]) + 100

	montecarloPi <- function(trials) {
	  count = 0
	  for(i in 1:trials) {
		if((runif(1,0,1)^2 + runif(1,0,1)^2)<1) {
		  count = count + 1
		}
	  }
	  return((count*4)/trials)
	}
 
	montecarloPi(iternum)


If you want to test the script, start an R container, and then run 
the script using `Rscript`: 

	$ singularity shell \
	   /cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0
	Singularity osgvo-r:3.5.0:~> Rscript mcpi.R 10
	[1] 3.14
	Singularity osgvo-r:3.5.0:~> exit
	$ 

If we were running a more intensive script, we would want to test our pipeline 
with a shortened, test script first.

## Create an Executable

As discussed in the [Run R Jobs tutorial](https://portal.osg-htc.org/documentation/software_examples_for_osg/r/tutorial-ScalingUp-R/), we need to prepare the job 
execution and the job submission scripts. First, make a wrapper script 
called `R-wrapper.sh`. 

	#!/bin/bash
	
	# set TMPDIR variable
	export TMPDIR=$_CONDOR_SCRATCH_DIR

	Rscript mcpi.R

This script will set the location for temporary files and execute our R script.

Test the wrapper script to ensure it works:

## Create a Submit File and Log Directory

Now that we have both our R script and wrapper script written and tested, 
we can begin building the submit file for our job. If we want to submit several 
jobs, we need to track log, out and error files for each
job. An easy way to do this is to use the Cluster and Process ID
values to create unique files for each process in our job.

Create a submit file named `R.submit`:

	+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0"

	executable = R-wrapper.sh
	arguments = $(Process)
	transfer_input_files = mcpi.R    
		
	log = log/job.log.$(Cluster).$(Process)
	error = log/job.error.$(Cluster).$(Process)
	output = log/mcpi.out.$(Cluster).$(Process)  
	
	queue 100

Note the `queue 100`.  This tells Condor to enqueue 100 copies of this job
as one cluster. Also, notice the use of `$(Cluster)` and `$(Process)` to specify unique 
output files. HTCondor will replace these with the Cluster and Process ID numbers for each 
individual process within the cluster. Let's make the `log` directory that will 
hold these files for us.

	$ mkdir log

## Submit the Jobs

Now it is time to submit our job! You'll see something like the following upon submission:

	$ condor_submit R.submit
	Submitting job(s).........................
	100 job(s) submitted to cluster 837.

Apply your `condor_q` knowledge to see this job
progress. Check your `log` folder to see the individual output files.

## Post Process⋅

Once the jobs are completed, you can use the information in the output files 
to calculate an average of all of our computed estimates of Pi.

To see this, we can use the command:

	$ cat log/mcpi*.out* | awk '{ sum += $2; print $2"   "NR} END { print "---------------\n Grand Average = " sum/NR }'

# Key Points

- Scaling up the computational resources on OSG is crucial to taking full advantage of grid computing.
- Changing the value of `Queue` allows the user to scale up the resources.
- `Arguments` allows you to pass parameters to a job script.
- `$(Cluster)` and `$(Process)` can be used to name log files uniquely.

# Getting Help

For assistance or questions, please email the OSG User Support team at 
<mailto:support@opensciencegrid.org>.

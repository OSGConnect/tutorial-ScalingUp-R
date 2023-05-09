---
ospool:
    path: software_examples/r/tutorial-ScalingUp-R/README.md
---

# Scaling up compute resources

Scaling up the computational resources is a big advantage for doing
certain large scale calculations on OSPool. Consider the extensive
sampling for a multi-dimensional Monte Carlo integration or molecular
dynamics simulation with several initial conditions. These type of
calculations require submitting a lot of jobs.

About a million CPU hours per day are available to OSPool users
on an opportunistic basis. Learning how to scale up and control large
numbers of jobs is key to realizing the full potential of distributed high
throughput computing on the OSPool.

In this tutorial, we will see how to scale up calculations for a
simple example. To download the materials for this tutorial, use the command

    $ git clone https://github.com/OSGConnect/tutorial-ScalingUp-R

## Background

For this example, we will use computational methods to estimate &pi;. First,
we will define a square inscribed by a unit circle from which we will 
randomly sample points. The ratio of the points outside the circle to 
the points in the circle is calculated, which approaches &pi;/4. 

This method converges extremely slowly, which makes it great for a 
CPU-intensive exercise (but bad for a real estimation!).

## Set up an R Job

If you downloaded the tutorial files, you should see the directory
"tutorial-ScalingUp-R" when you run the `ls` command. 
This directory contains the files used in this tutorial.
Alternatively, you can write the necessary files from scratch. 
In that case, create a working directory using the command 

    $ mkdir tutorial-ScalingUp-R

Either way, move into the directory before continuing:

    $ cd tutorial-ScalingUp-R

## Create and test an R Script

Our code is a simple R script that does the estimation. 
It takes in a single argument in order to differentiate the jobs. 
The code for the script is contained in the file `mcpi.R`.
If you didn't download the tutorial files, create an R script
called `mcpi.R` and add the following contents:

	#!/usr/bin/env Rscript
	
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

The header at the top of the file (the line starting with `#!`) indicates that this script is 
meant to be run using R. 

If we were running a more intensive script, we would want to test our pipeline 
with a shortened, test script first.

> If you want to test the script, start an R container, and then run 
> the script using `Rscript`. For example: 
> 
>     $ apptainer shell \
>	   /cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0
>     Singularity :~/tutorial-ScalingUp-R> Rscript mcpi.R 10
>     [1] 3.14
>     Singularity :~/tutorial-ScalingUp-R> exit
>     $ 

## Create a Submit File and Log Directories

Now that we have our R script written and tested, 
we can begin building the submit file for our job. If we want to submit several 
jobs, we need to track log, output, and error files for each
job. An easy way to do this is to use the Cluster and Process ID
values assigned by HTCondor to create unique files for each job in our 
overall workflow.

In this example, the submit file is called `R.submit`.
If you did not download the tutorial files, create a submit file named `R.submit`
and add the following contents:

	+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0"

	executable = mcpi.R
	arguments = $(Process)

	#transfer_input_files = 
	should_transfer_files = YES
	when_to_transfer_output = ON_EXIT

	log = logs/job.log.$(Cluster).$(Process)
	error = logs/job.error.$(Cluster).$(Process)
	output = output/mcpi.out.$(Cluster).$(Process)

	request_cpus = 1
	request_memory = 1GB
	request_disk = 1GB

	queue 100

If you did not download the tutorial files, you will also need to create the
`logs` and `output` directories to hold the files that will be created for each job.
You can create both directories at once with the command

    $ mkdir logs output

There are several items to note about this submit file:

  * The `queue 100` statement in the submit file. This tells Condor to enqueue 100 copies 
    of this job as one cluster. 
  * The submit variables `$(Cluster)` and `$(Process)`. These are used to specify unique output files. 
    HTCondor will replace these with the Cluster and Process ID numbers for each individual process 
    within the cluster. The `$(Process)` variable is also passed as an argument to our R script.

## Submit the Jobs

Now it is time to submit our job! You'll see something like the following upon submission:

	$ condor_submit R.submit
	Submitting job(s).........................
	100 job(s) submitted to cluster 837.

Apply your `condor_q` knowledge to see the progress of these jobs. 
Check your `logs` folder to see the error and HTCondor log 
files and the `output` folder to see the results of the scripts. 

## Post Process

Once the jobs are completed, you can use the information in the output files 
to calculate an average of all of our computed estimates of &pi;.

To see this, we can use the command:

	$ cat output/mcpi*.out* | awk '{ sum += $2; print $2"   "NR} END { print "---------------\n Grand Average = " sum/NR }'

# Key Points

- Scaling up the number of jobs is crucial for taking full advantage of the computational resources of the OSPool.
- Changing the `queue` statement allows the user to scale up the resources.
- The `arguments` option can be used to pass parameters to a job script.
- The submit variables `$(Cluster)` and `$(Process)` can be used to name log files uniquely.

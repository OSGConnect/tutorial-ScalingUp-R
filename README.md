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

About a million CPU hours per day are available to OSG users
on an opportunistic basis.  Learning how to scale up and control large
numbers of jobs to realizing the full potential of distributed high
throughput computing on the OSG.

In this section, we will see how to scale up calculations with
simple example. 

## Background

For this example, we will use computational methods to estimate pi. First,
we will define a square inscribed by a unit circle from which we will 
randomly sample points. The ratio of the points outside the circle to 
the points in the circle is calculated which approaches pi/4. 

This method converges extremely slowly, which makes it great for a 
CPU-intensive exercise (but bad for a real estimation!).

## Set up an R Job

First, we'll need to create a working directory, you can either run 
`$ git clone https://github.com/OSGConnect/tutorial-ScalingUp-R` or type the following:

    $ mkdir tutorial-ScalingUp-R
    $ cd tutorial-ScalingUp-R

## Create and test an R Script

Our code is a simple R script that does the estimation. It takes in a single argument, simply 
for the purposes of differentiating the jobs. If you didn't run the tutorial command to 
generate files, create an R script by typing the following into a file called `mcpi.R`:

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

The header at the top of the file indicates that this script is 
meant to be run using R. 

> If you want to test the script, start an R container, and then run 
> the script using `Rscript`: 
> 
>     $ singularity shell \
>	   /cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0
>     Singularity osgvo-r:3.5.0:~> Rscript mcpi.R 10
>     [1] 3.14
>     Singularity osgvo-r:3.5.0:~> exit
>     $ 

If we were running a more intensive script, we would want to test our pipeline 
with a shortened, test script first.

## Create a Submit File and Log Directory

Now that we have our R script written and tested, 
we can begin building the submit file for our job. If we want to submit several 
jobs, we need to track log, out and error files for each
job. An easy way to do this is to use the Cluster and Process ID
values assigned by HTCondor to create unique files for each job in our 
overall workflow.

If you did not download the files for this example with the `tutorial` command, 
create a submit file named `R.submit`:

	universe = vanilla
	+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0"

	executable = mcpi.R
	arguments = $(Process)

	#transfer_input_files = 
	should_transfer_files = YES
	when_to_transfer_output = ON_EXIT

	output = output/mcpi.out.$(Cluster).$(Process)

	log = logs/job.log.$(Cluster).$(Process)
	error = logs/job.error.$(Cluster).$(Process)

	request_cpus = 1
	request_memory = 1GB
	request_disk = 1GB

	queue 100

Note the `queue 100`.  This tells Condor to enqueue 100 copies of this job
as one cluster. Also, notice the use of `$(Cluster)` and `$(Process)` to specify unique 
output files. HTCondor will replace these with the Cluster and Process ID numbers for each 
individual process within the cluster. 

## Submit the Jobs

Now it is time to submit our job! You'll see something like the following upon submission:

	$ condor_submit R.submit
	Submitting job(s).........................
	100 job(s) submitted to cluster 837.

Apply your `condor_q` knowledge to see this job
progress. Check your `logs` folder to see the error and HTCondor log 
files and the `output` folder to see the results of the scripts. 

## Post Process⋅

Once the jobs are completed, you can use the information in the output files 
to calculate an average of all of our computed estimates of Pi.

To see this, we can use the command:

	$ cat output/mcpi*.out* | awk '{ sum += $2; print $2"   "NR} END { print "---------------\n Grand Average = " sum/NR }'

# Key Points

- Scaling up the computational resources on OSG is crucial to taking full advantage of grid computing.
- Changing the value of `Queue` allows the user to scale up the resources.
- `Arguments` allows you to pass parameters to a job script.
- `$(Cluster)` and `$(Process)` can be used to name log files uniquely.

# Getting Help

For assistance or questions, please email the OSG User Support team at 
<mailto:support@osg-htc.org>.

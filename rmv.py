#!/usr/bin/env python

# initialize
## find gnuplot version
import os
GNUPLOT_VERSION = float(os.popen("gnuplot --version | awk '{print $2}'").read())
## get args
## pull source and destination from args
## assert source exists
## create destination base directory

# run
## find files
## find resources
## create histograms
## create group resource summaries
## make combined time series
## plot makeflow log
## copy static files
## clean up temporary files

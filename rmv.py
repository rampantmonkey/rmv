#!/usr/bin/env python

# initialize
## find gnuplot version
import os
GNUPLOT_VERSION = float(os.popen("gnuplot --version | awk '{print $2}'").read())

## get args
import argparse
option_parser = argparse.ArgumentParser(description='Visualize resource monitor data')
option_parser.add_argument("source", help="the directory containing your data")
option_parser.add_argument("destination", help="the desired output directory")
args = option_parser.parse_args()

## pull source and destination from args
source_directory      = args.source
destination_directory = args.destination

## assert source exists
if not os.path.isdir(source_directory):
  print "source directory does not exist"
  exit(1)

## create destination base directory
try:
  os.makedirs(destination_directory)
except:
  pass

# run
## find files
## find resources
## create histograms
## create group resource summaries
## make combined time series
## plot makeflow log
## copy static files
## clean up temporary files

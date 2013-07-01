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
summary_paths = []
for r, d, f in os.walk(source_directory):
  for files in f:
    if files.endswith(".summary"):
      summary_paths.append(os.path.join(r, files))

## find resources
## create histograms
## create group resource summaries
## make combined time series
## plot makeflow log
## copy static files
## clean up temporary files

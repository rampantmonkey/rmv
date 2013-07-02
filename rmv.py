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

## create temporary workspace
workspace = '/tmp/rmv'
try:
  os.makedirs(workspace)
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
resources = ["wall_time",
             "cpu_time",
             "max_concurrent_processes",
             "virtual_memory",
             "resident_memory",
             "swap_memory",
             "bytes_read",
             "bytes_written",
             "workdir_num_files",
             "workdir_footprint"
             ]

## load summary data by groups
groups = {}
for sp in summary_paths:
  data_stream = open(sp, 'r')
  summary = {}
  for line in data_stream:
    data = line.strip().split(':', 2)
    data = [x.strip() for x in data]
    key = data[0]
    value = data[1]
    summary[key] = value

  ### determine group name
  group_name = summary.get('command').split(' ')[0]
  while group_name[0] == '.' or group_name[0] == '/':
    group_name = group_name[1:]

  ### insert into groups
  if groups.get(group_name) == None:
    groups[group_name] = [summary]
  else:
    groups[group_name].append(summary)

  data_stream.close()

## create histograms
for r in resources:
  for group_name in groups:
    maximums = []
    for d in groups[group_name]:
      maximums.append(d.get(r))
    directory = workspace + "/" + group_name
    try:
      os.makedirs(directory)
    except:
      pass
    filename = directory + "/" + r
    f = open(filename, "w")
    for m in maximums:
      f.write("%s\n" % m)
    f.close()



## create group resource summaries
## make combined time series
## plot makeflow log
## copy static files
## clean up temporary files

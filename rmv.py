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
### write data by group and resource
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
    data_path = directory + "/" + r
    f = open(data_path, "w")
    for m in maximums:
      f.write("%s\n" % m)
    f.close()
    ### fill in gnuplot template
    image_path = destination_directory + "/" + group_name
    try:
      os.makedirs(image_path)
    except:
      pass
    width = 600
    height = 600
    image_path += "/" + r + "_" + str(width) + "x" + str(height) + "_hist.png"
    binwidth = 1
    gnuplotformat =  "set terminal png transparent size " + str(width) + "," + str(height) + "\n"
    gnuplotformat += "unset key\n"
    gnuplotformat += "set ylabel \"Frequency\"\n"
    gnuplotformat += "set output \"" + image_path + "\"\n"
    gnuplotformat += "binwidth=" + str(binwidth) + "\n"
    gnuplotformat += "set boxwidth binwidth*0.9 absolute\n"
    gnuplotformat += "set style fill solid 0.5\n"
    gnuplotformat += "bin(x,width)=width*floor(x/width)\n"
    gnuplotformat += "set yrange [0:*]\n"
    gnuplotformat += "set xrange [0:*]\n"
    gnuplotformat += "set xlabel \"" + r + "\"\n"
    gnuplotformat += "plot \"" + data_path + "\" using (bin($1,binwidth)):1 smooth freq w boxes\n"
    print gnuplotformat;

## create group resource summaries
## make combined time series
## plot makeflow log
## copy static files
## clean up temporary files

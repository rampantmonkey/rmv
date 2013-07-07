#!/usr/bin/env python

import os
import argparse

def make_path(path):
  try:
    os.makedirs(path)
  except:
    pass

def find_gnuplot_version():
  return float(os.popen("gnuplot --version | awk '{print $2}'").read())

def source_exists(path):
  if not os.path.isdir(path):
    print "source directory does not exist"
    exit(1)

def get_args():
  option_parser = argparse.ArgumentParser(description='Visualize resource monitor data')
  option_parser.add_argument("source", help="the directory containing your data")
  option_parser.add_argument("destination", help="the desired output directory")
  option_parser.add_argument("name", help="the name of the workflow")
  args = option_parser.parse_args()
  return args.source, args.destination, args.name

def find_summary_paths(source):
  summary_paths = []
  for r, d, f in os.walk(source):
    for files in f:
      if files.endswith(".summary"):
        summary_paths.append(os.path.join(r, files))
  return summary_paths

def load_summaries_by_group(paths):
  groups = {}
  for sp in paths:
    data_stream = open(sp, 'r')
    summary = {}
    for line in data_stream:
      data = line.strip().split(':', 2)
      data = [x.strip() for x in data]
      key = data[0]
      value = data[1]
      summary[key] = value
    summary['filename'] = os.path.basename(sp)

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
  return groups

def gnuplot(commands):
  (child_stdin, child_stdout, child_stderr) = os.popen3("gnuplot")
  child_stdin.write("%s\n" % commands)
  child_stdin.close()
  child_stdout.close()
  child_stderr.close()

def fill_histogram_template(width, height, image_path, binwidth, resource_name, data_path):
  result  = "set terminal png transparent size " + str(width) + "," + str(height) + "\n"
  result += "unset key\n"
  result += "set ylabel \"Frequency\"\n"
  result += "set output \"" + image_path + "\"\n"
  result += "binwidth=" + str(binwidth) + "\n"
  result += "set boxwidth binwidth*0.9 absolute\n"
  result += "set style fill solid 0.5\n"
  result += "bin(x,width)=width*floor(x/width)\n"
  result += "set yrange [0:*]\n"
  result += "set xrange [0:*]\n"
  result += "set xlabel \"" + resource_name + "\"\n"
  result += "plot \"" + data_path + "\" using (bin($1,binwidth)):1 smooth freq w boxes\n"
  return result

def rule_id_for_task(task):
  rule_id = task.get('filename').split('.')
  rule_id = rule_id[0].split('-')[-1]
  return rule_id

def resource_group_page(name, group_name, resource, width, height, tasks, out_path):
  page  = "<!doctype html>\n"
  page += "<meta name=\"viewport\" content=\"initial-scale=1.0, width=device-width\" />\n"
  page += "<link rel=\"stylesheet\" type=\"text/css\" media=\"screen, projection\" href\"" + "../../css/style.css\" />\n"
  page += "<title>Workflow</title>\n"
  page += "<div class=\"content\">\n"
  page += "<h1><a href=\"../../index.html\">" + name + "</a> - " + group_name + " - " + resource + "</h1>\n"
  page += "<img src=\"../" + resource + "_" + str(width) + "x" + str(height) + "_hist.png\" class=\"center\" />\n"
  page += "<table>\n"
  page += "<tr><th>Rule Id</th><th>Maximum " + resource +  "</th></tr>\n"
  for d in tasks:
    rule_id = rule_id_for_task(d)
    page += "<tr><td><a href=\"../" + rule_id + ".html\">" + rule_id + "</a></td><td>" + str(d.get(resource)) + "</td></tr>\n"
  page += "</table>\n"
  page += "</div>\n"

  index_path = out_path + "/" + resource
  make_path(index_path)
  index_path += "/" + "index.html"
  f = open(index_path, "w")
  f.write("%s\n" % page)
  f.close()

def compute_binwidth(maximum_value):
  if maximum_value > 40:
    binwidth = maximum_value/40.0
  else:
    binwidth = 1
  return binwidth

def find_maximums(tasks, resource):
  maximums = []
  for d in tasks:
    maximums.append(float(d.get(resource).split(' ')[0]))
  return maximums

def write_maximums(maximums, resource, group_name, base_directory):
  directory = base_directory + "/" + group_name
  make_path(directory)
  data_path = directory + "/" + resource
  f = open(data_path, "w")
  for m in maximums:
    f.write("%d\n" % m)
  f.close()
  return data_path

def task_has_timeseries(task, source_directory):
  base_name = task.get('filename').split('.')[0]
  timeseries_name = base_name + '.series'
  try:
    f = open(source_directory + "/" + timeseries_name)
    f.close()
  except:
    return None
  return timeseries_name

def create_individual_pages(groups, destination_directory, name, resources, source_directory):
  for group_name in groups:
    for task in groups[group_name]:
      timeseries_file = task_has_timeseries(task, source_directory)
      if timeseries_file != None:
        # Generate time series plots
        # Set flag to add plots to page
        print timeseries_file
        print task.get('filename')
      page  = "<html>\n"
      page += "<h1><a href=\"../index.html\">" + name + "</a> - " + group_name + " - " + rule_id_for_task(task) + "</h1>\n"
      page += "<table>\n"
      page += "<tr><td>command</td><td>" + task.get('command') + "</td></tr>\n"
      for r in resources:
        page += "<tr><td><a href=\"" + r + "/index.html\">" + r + "</a></td><td>" + task.get(r) + "</td>\n"
      page += "</html>\n"
      f = open(destination_directory + "/" + group_name + "/" + rule_id_for_task(task) + ".html", "w")
      f.write("%s\n" % page)
      f.close()

def  create_main_page(group_names, name, resources, destination, hist_height=600, hist_width=600):
  out_path = destination + "/index.html"
  f = open(out_path, "w")
  content  = "<!doctype html>\n"
  content += "<meta charset=\"UTF-8\">\n"
  content += '<meta name="viewport" content="initial-scale=1.0, width=device-width" />' + "\n"
  content += '<link rel="stylesheet" type="text/css" media="screen, projection" href="css/style.css" />' + "\n"
  content += '<title>' + name + "Workflow</title>\n"
  content += '<div class="content">' + "\n"
  content += '<h1>' + name + "Workflow</h1>\n"
  for g in group_names:
    content += '<h2>' + g + "</h2>\n"
    for r in resources:
      content += '<a href="' + g + '/' + r + '/index.html"><img src="' + g + "/" + r + "_" + str(hist_width) + "x" + str(hist_height) + '_hist.png" /></a>\n'
    content += "<hr />\n\n"
  content += "</div>\n"
  f.write("%s\n" % content)
  f.close()

def main():
  # initialize
  GNUPLOT_VERSION = find_gnuplot_version()

  (source_directory,
  destination_directory,
  name) = get_args()

  source_exists(source_directory)

  make_path(destination_directory)

  workspace = '/tmp/rmv'
  make_path(workspace)

  # run
  summary_paths = find_summary_paths(source_directory)

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

  groups = load_summaries_by_group(summary_paths)

  hist_large = 600
  hist_small = 250
  for r in resources:
    for group_name in groups:
      maximums = find_maximums(groups[group_name], r)
      data_path = write_maximums(maximums, r, group_name, workspace)

      out_path = destination_directory + "/" + group_name
      make_path(out_path)
      binwidth = compute_binwidth(max(maximums))

      image_path = out_path + "/" + r + "_" + str(hist_large) + "x" + str(hist_large) + "_hist.png"
      gnuplot_format = fill_histogram_template(hist_large, hist_large, image_path, binwidth, r, data_path)
      gnuplot(gnuplot_format)

      image_path = out_path + "/" + r + "_" + str(hist_small) + "x" + str(hist_small) + "_hist.png"
      gnuplot_format = fill_histogram_template(hist_small, hist_small, image_path, binwidth, r, data_path)
      gnuplot(gnuplot_format)

      resource_group_page(name, group_name, r, hist_large, hist_large, groups[group_name], out_path)

  create_individual_pages(groups, destination_directory, name, resources, source_directory)

  create_main_page(groups.keys(), name, resources, destination_directory, hist_small, hist_small)
  ## create group resource summaries
  ## make combined time series
  ## plot makeflow log
  ## copy static files
  ## clean up temporary files

main()

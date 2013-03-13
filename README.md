Menagerie Generator

Build webpage summarizing resource usage of distributed application.

# Input File Formats

## Time series
The time series input format has one header line describing the columns followed by one row of values captured at each sampling interval.

    #wall_clock concurrent_processes cpu_time virtual_memory resident_memory bytes_read bytes_written workdir_number_files_dirs workdir_footprint
    1362750141.056653       1       0.000000        2173    88      372736  0       101     8550.064460
    1362750141.060311       1       0.000000        20003   495     2051945 0       102     8550.064460

## Summary
The summary file contains some general information of the process (start time, end time, command run, ...) and maximums for the resources measured (as described in the time series data).

    command: ./gen_submit_file_split_inputs.pl 3909
    start:                        	1362750140.942097
    end:                          	1362750141.176828
    exit_type:                    	normal
    exit_status:                  	0
    max_concurrent_processes:     	1
    wall_time:                    	0.234731
    cpu_time:                     	0.000000
    virtual_memory:               	20003
    resident_memory:              	495
    bytes_read:                   	2051945
    bytes_written:                	0
    workdir_number_files_dirs:    	102
    workdir_footprint:            	8550.064460

# Contributing

 [![Build Status](https://travis-ci.org/rampantmonkey/menagerie-generator.png?branch=master)](https://travis-ci.org/rampantmonkey/menagerie-generator)

Any design improvements are more than welcome. Just submit a pull request with the changes.



default: all

all: blast bwa shrimp

blast:
	time ruby -Ilib bin/rmv --source ../menagerie-generator-data/blast_2013_03_08_1s --destination ~/Sites/menagerie --name Blast --debug

no-series:
	time ruby -Ilib bin/rmv --source ../menagerie-generator-data/no-series --destination ~/Sites/menagerie --name no-series --debug

new-blast:
	time ruby -Ilib bin/rmv --source ../menagerie-generator-data/monitor-logs-2013_06_14_09-20 --destination ~/Sites/menagerie --name newblast --debug

bwa:
	time ruby -Ilib bin/rmv --source ../menagerie-generator-data/bwa_2013_03_09_1s --destination ~/Sites/menagerie --name BWA

shrimp:
	time ruby -Ilib bin/rmv --source ../menagerie-generator-data/shrimp_2013_03_11c_1s --destination ~/Sites/menagerie --name Shrimp

clean:
	rm -r /tmp/menagerie-generator

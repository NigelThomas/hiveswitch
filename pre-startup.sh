#!/bin/bash
#
# Do any preproject setup needed before loading the StreamLab projects
#
# Assume we are running in the project directory
. /etc/sqlstream/environment

mkdir -p $SQLSTREAM_HOME/classes/net/sf/farrago/dynamic/

echo ... installing the SQLstream schema 
# update setup.sql to replace placeholders with actual values

echo ... running on host=`hostname`
sed -i -e "s/%HOSTNAME%/`hostname`/g" setup.sql

echo ... create script with all the pieces so if it fails it stops and leaves a message at the end of the log
cat input.sql > /tmp/setup.sql


for i in `seq 0 7`
do
    cat setup.sql | sed -e "s/%SCHEMA%/edr_output_$i/" -e "s/%SHARD%/$i/" >> /tmp/setup.sql
done

$SQLSTREAM_HOME/bin/sqllineClient --run=/tmp/setup.sql

rm /tmp/setup.sql



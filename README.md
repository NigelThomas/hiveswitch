# hiveswitch - LOAD to Hive performance test including partitions - with an 8 way sharder

## Unpack the tarball

Unpack `hiveswitch.tgz` into `/home/sqlstream`. This will create a folder tree starting at `/home/sqlstream/hiveswitch`.

## Hive Sink Table

The target Hive table is created in the Hive schema `hiveswitch` with the name `hive_edr_hiveswitch`. The SQL is in `hive_edr_hiveswitch.sql` and needs to be copied to the Hive cluster.

The docker instance does not attempt to manage the remote Hive table; you shoud manually remove data from the table before test runs by:

* ssh to a suitable server (`guavus@192.168.141.102`)
* sudo su -
* kinit 
* use beeline to access tables

## Install s-Server schema and credentials

The SQLstream end of the data flow is created using the install scripts:

```
. /home/sqlstream/hiveswitch/pre-startup.sh
. /home/sqlstream/hiveswitch/pre-server.sh
```

This is managed by the bootstrap utilities present on the docker image `sqlstream/streamlab-git`.

## Starting the processing

For a single processor use the `hiveswitch.sh` script. This will start a container with the name `hiveswitch` - the container name can also be set externally:

```
export CONTAINER_NAME=myspecialname
./hiveswitch.sh
```

To start multiple containers in parallel, use `hiveswitch-parallel.sh <n>` This will start n containers in parallel. The container names will be hiveswitch1,hiveswitch2,...,hiveswitchn. If more than 10 containers are started the names will be hiveswitch01, hiveswitch02, etc up to hiveswitch99; and in the unlikely event that you start more than 100 processors names will start from hiveswitch001.

```
./hiveswitch-parallel.sh 5
```

The containers are monitored and after a period (20 or 25 minutes) the trace files and some other products are copied into a test directory `test-yyyy.MM.dd-HH:mm` under the current working directory.

A second parameter, if set, causes the local ORC output files to be output to a directory of `./${CONTAINER_NAME}` - this may be more performant than writing to the docker image layer.
```
./hiveswitch-parallel.sh 5 Y
```
At the moment, any non-blank parameter 2 value has this effect.


**NOTE**: When starting the docker containers, the caller only needs the two scripts `hiveswitch.sh` and `hiveswitch-parallel.sh`. All other content is pulled from the git remote origin.

## SQLstream schema

The SQLstream end of the data flow is created in the `"hiveswitch"` schema using `sqllineClient --run=/home/sqlstream/hiveswitch/setup.sql` 
(this is included in install.sh).

## Source Data

The data comes from Verizon; A small number of sample CSV files are included here in the edr subdirectory, i.e. `/home/sqlstream/hiveswitch/edr`. The 
foreign stream is `"edr_data_fs"`. Data is pumped into a native stream `"edr_data"`.

To support long running tests the source foreign stream uses the `STATIC_FILES` and `REPEAT` options: 
```
        "STATIC_FILES" 'true',
        "REPEAT" '100'
```
The test data amounts to 600k rows; so the full cycle counts to 60M rows (about 16G).

We have added 3 random values in columns 1, 2 3:

1: -X < secs < X where X = 12 * 60 * 60 = a random time displacement in seconds, +/- 12 hours
2: app_id 0 < app_id < 8
3: cell_id: 0 < cell_id < 8

```
cat RFDR46EUTX_flow_REPORTOCS_20191004061858_test_000000000_508 | awk -F, '{ printf "%d,%s\n", int((24*60*60)*rand())-(12*60*60),int(8*rand()),int(8*rand()),$0;}' | more
```
## Sink

A foreign stream "`edr_data_fs"` is created. This references the `HIVE_SERVER` server. Column names have been lower-cased and normalized to match the Hive table (`hiveswitch.hive_edr_hiveswitch`).

* Local files go to `/home/sqlstream/edr-out` on the docker container

## Credentials

Credentials are mounted from `$HOME/credentials` on the host to `/home/sqlstream/credentials`. These __credentials are not included in this repository__ (for obvious reasons) but can be obtained from nigel.thomas@guavus.com on request.

If the credentials are stored elsewhere on the host, set the environment variable 
The following files are copied to /home/sqlstream by `install.sh`

* `core-site.xml`
* `hdfs-site.xml`
* `svc_sqlstream_guavus.keytab` - this should have 600 permissions (o:rw) and be owned by sqlstream
* `krb5.conf` - should be moved to /etc/krb5.conf

* `testhosts` - an entry to add into the /etc/hosts on the SQLstream host server or docker instance - assuming that the target KDC server is as specified
* `orctest.lic` - a license file

These files are not included in the git repository, but they are included in the tarball.

* `README.md` - documents how to use the credentials

## Starting and stopping the data flow

This is managed by the docker startup; these scripts are generated as the docker container starts.

```
$SQLSTREAM_HOME/bin/sqllineClient --run=startPumps.sql

$SQLSTREAM_HOME/bin/sqllineClient --run=stopPumps.sql
```


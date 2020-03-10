-- source data

CREATE OR REPLACE SCHEMA "edr";
SET SCHEMA '"edr"';


CREATE OR REPLACE FOREIGN TABLE "edr_shards" 
( "app_id" INTEGER
, "cell_id" INTEGER
)
SERVER FILE_SERVER
OPTIONS
( "PARSER" 'CSV'
, "CHARACTER_ENCODING" 'UTF-8'
, "QUOTE_CHARACTER" '"'
, "SEPARATOR" ','
, "SKIP_HEADER" 'true'
, "DIRECTORY" '/home/sqlstream/shards'
, "FILENAME_PATTERN" 'shards.csv'
);

CREATE OR REPLACE FOREIGN STREAM "edr_data_fs"
(
    "secs_offset" INTEGER,
    "app_id" INTEGER,
    "cell_id" INTEGER,
    "sn-end-time" VARCHAR(32),
    "sn-start-time" VARCHAR(32),
    "bearer-3gpp imei" VARCHAR(32),
    "bearer-3gpp imsi" BIGINT,
    "bearer-3gpp rat-type" INTEGER,
    "bearer-3gpp user-location-information" VARCHAR(32),
    "ip-server-ip-address" VARCHAR(16),
    "ip-subscriber-ip-address" VARCHAR(64),
    "p2p-tls-sni" VARCHAR(128),
    "radius-calling-station-id" BIGINT,
    "sn-direction" VARCHAR(16),
    "sn-duration" INTEGER,
    "sn-flow-end-time" VARCHAR(32),
    "sn-flow-id" VARCHAR(32),
    "sn-flow-start-time" VARCHAR(32),
    "sn-server-port" INTEGER,
    "sn-subscriber-port" INTEGER,
    "sn-volume-amt-ip-bytes-downlink" INTEGER,
    "sn-volume-amt-ip-bytes-uplink" INTEGER,
    "sn-closure-reason" INTEGER,
    "event-label" VARCHAR(16)
)
    SERVER "FILE_SERVER"

OPTIONS (
"PARSER" 'CSV',
        "CHARACTER_ENCODING" 'UTF-8',
        "QUOTE_CHARACTER" '"',
        "SEPARATOR" ',',
        "SKIP_HEADER" 'false',                          -- headers stripped from files because of bug with REPEAT

        "DIRECTORY" '/home/sqlstream/edr',
        "FILENAME_PATTERN" '.*REPORTOCS.*\.csv',

                                                        -- the sample data set is 600k rows; this expands that to 60M rows and can be changed to 'FOREVER' if needed
	"STATIC_FILES" 'true',
	"REPEAT" '200'

);


CREATE OR REPLACE STREAM "edr_data_ns"
(
    "event_time" TIMESTAMP,
    "secs_offset" INTEGER,
    "app_id" INTEGER,
    "cell_id" INTEGER,
    "sn-end-time" VARCHAR(32),
    "sn-start-time" VARCHAR(32),
    "bearer-3gpp imei" VARCHAR(32),
    "bearer-3gpp imsi" BIGINT,
    "bearer-3gpp rat-type" INTEGER,
    "bearer-3gpp user-location-information" VARCHAR(32),
    "ip-server-ip-address" VARCHAR(16),
    "ip-subscriber-ip-address" VARCHAR(64),
    "p2p-tls-sni" VARCHAR(128),
    "radius-calling-station-id" BIGINT,
    "sn-direction" VARCHAR(16),
    "sn-duration" INTEGER,
    "sn-flow-end-time" VARCHAR(32),
    "sn-flow-id" VARCHAR(32),
    "sn-flow-start-time" VARCHAR(32),
    "sn-server-port" INTEGER,
    "sn-subscriber-port" INTEGER,
    "sn-volume-amt-ip-bytes-downlink" INTEGER,
    "sn-volume-amt-ip-bytes-uplink" INTEGER,
    "sn-closure-reason" INTEGER,
    "event-label" VARCHAR(16)
)

CREATE OR REPLACE PUMP "edr_input_pump" STOPPED
AS
INSERT INTO "edr_data_ns"
SELECT STREAM
      , char_to_timestamp('MM/dd/yyyy HH:mm:ss:SSS', "sn-end-time") as "event_time"
      , *
FROM   "edr_data_fs"
;



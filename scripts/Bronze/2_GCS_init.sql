/*
============================================================================================
Purpose: Creating Creating GCS and PUB/SUB INTEGRATION (Storage, Notification)
============================================================================================
*/
-- Seleting Database and schema

--DATABASE
USE DATAWAREHOUSE;

--Schema
USE schema BRONZE;

-- CSV File Format
CREATE OR REPLACE FILE FORMAT DataWarehouse.BRONZE.csv_file_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL', 'null');

-- CREATE Storage Init
CREATE OR REPLACE STORAGE INTEGRATION gcs_init
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = GCS
    ENABLED = TRUE
    STORAGE_ALLOWED_LOCATIONS = ('gcs://snowflake-store/CRM_data/source_crm', 'gcs://snowflake-store/ERP_data/source_erp')
    COMMENT = 'Integration of GCS';

DESC STORAGE INTEGRATION gcs_init;

--Create Stage CRM
CREATE OR REPLACE STAGE DATAWAREHOUSE.BRONZE.gcs_crm_stage
    URL = 'gcs://snowflake-store/CRM_data/source_crm'
    STORAGE_INTEGRATION = gcs_init
    FILE_FORMAT = DataWarehouse.BRONZE.csv_file_format;

--Create Stage ERP
CREATE OR REPLACE STAGE DATAWAREHOUSE.BRONZE.gcs_erp_stage
    URL = 'gcs://snowflake-store/ERP_data/source_erp'
    STORAGE_INTEGRATION = gcs_init
    FILE_FORMAT = DataWarehouse.BRONZE.csv_file_format;


LIST @DATAWAREHOUSE.BRONZE.gcs_erp_stage;
    
-- Create notification integration 

CREATE OR REPLACE NOTIFICATION INTEGRATION gcs_notify_init
    TYPE = QUEUE
    ENABLED = TRUE
    NOTIFICATION_PROVIDER = GCP_PUBSUB
    GCP_PUBSUB_SUBSCRIPTION_NAME = 'projects/snowflak/subscriptions/notify-data'
    COMMENT = 'Notification integration for GCS auto-ingest.';

DESC NOTIFICATION INTEGRATION gcs_notify_init;
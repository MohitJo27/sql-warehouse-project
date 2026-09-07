USE DATAWAREHOUSE;
USE SCHEMA Silver;


-- Clean & Load CRM_CUST_INFO

CREATE OR REPLACE DYNAMIC ICEBERG TABLE DATAWAREHOUSE.SILVER.CRM_CUST_INFO
    TARGET_LAG = '24 hours'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'crm/crm_cust_info'
AS
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' 
        ELSE 'n/a' 
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
        ELSE 'n/a' 
    END AS cst_gndr,
    cst_create_date
FROM
(
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM DATAWAREHOUSE.BRONZE.CRM_CUST_INFO
    WHERE cst_id IS NOT NULL
)   
WHERE flag_last = 1;

-- Create and load CRM_PRD_INFO
CREATE OR REPLACE DYNAMIC ICEBERG TABLE  DATAWAREHOUSE.SILVER.crm_prd_info
    TARGET_LAG = '24 hours'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'crm/crm_prd_info'
AS
SELECT
    prd_id,
    REPLACE(SUBSTR(prd_key,1, 5), '-', '_') AS cat_id,
    SUBSTR(prd_key, 7, LENGTH(prd_key)) AS prd_key,
    prd_nm,
    IFNULL(prd_cost, 0) AS prd_cost,
    CASE UPPER(TRIM(prd_line))
            WHEN 'R' THEN 'Road'
            WHEN 'M' THEN 'Mountain'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
    END AS prd_line,
    TO_DATE(PRD_START_DT) AS prd_start_dt,
    TO_DATE(DATEADD(DAY, -1, LEAD(PRD_START_DT) OVER(PARTITION BY prd_key ORDER BY prd_start_dt))) AS prd_end_dt
FROM
    DATAWAREHOUSE.BRONZE.CRM_PRD_INFO;


-- Clean & Load CRM_SALES_DETAILS

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM
    DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS;
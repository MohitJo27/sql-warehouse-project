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

CREATE OR REPLACE DYNAMIC ICEBERG TABLE  DATAWAREHOUSE.SILVER.crm_sales_details
    TARGET_LAG = '24 hours'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'crm/crm_sales_details'
AS
SELECT
    TRIM(sls_ord_num) AS sls_ord_num,
    TRIM(sls_prd_key) AS sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM
    DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS;


--=== ERP

-- Clean & Load ERP_CUST_AZ12

CREATE OR REPLACE DYNAMIC ICEBERG TABLE  DATAWAREHOUSE.SILVER.erp_cust_az12
    TARGET_LAG = '24 hours'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'erp/erp_cust_az12'
AS
SELECT
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTR(cid, 4, LENGTH(cid))
        ELSE cid
    END AS cid,
    CASE 
        WHEN bdate > CURRENT_DATE() THEN NULL
        ELSE bdate
    END AS bdate,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM DATAWAREHOUSE.BRONZE.ERP_CUST_AZ12;


-- Clean & Load ERP_LOC_A101

CREATE OR REPLACE DYNAMIC ICEBERG TABLE  DATAWAREHOUSE.SILVER.erp_loc_a101
    TARGET_LAG = '24 hours'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'erp/erp_loc_a101'
AS
SELECT
    REPLACE(cid, '-', '') AS cid,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) in('US', 'USA') THEN 'United State'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM DATAWAREHOUSE.BRONZE.ERP_LOC_A101;

-- Clean & Load ERP_PX_CAT_G1V2

CREATE OR REPLACE DYNAMIC ICEBERG TABLE  DATAWAREHOUSE.SILVER.erp_px_cat_g1v2
    TARGET_LAG = '24 hours'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'erp/erp_px_cat_g1v2'
AS
SELECT 
    id,
    cat,
    subcat,
    maintenance,
FROM DATAWAREHOUSE.BRONZE.ERP_PX_CAT_G1V2
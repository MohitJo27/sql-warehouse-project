USE DATAWAREHOUSE;
USE SCHEMA Silver;
-- Clean & Load CRM_CUST_INFO

-- Check for Null or duplicate
SELECT 
    sls_prd_key,
    COUNT(*)
FROM DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS
GROUP BY sls_prd_key
HAVING COUNT(*) > 1 OR sls_prd_key IS NULL;

-- Check for unwanted space

SELECT 
    prd_nm
FROM DATAWAREHOUSE.BRONZE.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


-- Clean & Load CRM_PRD_INFO

SELECT top 10 *
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO;

SELECT COUNT(*)
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

SELECT
    TO_DATE(PRD_START_DT) AS prd_start_dt,
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO;

SELECT 
    prd_cost
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
HAVING prd_cost < 0 OR prd_cost IS NULL;

SELECT
    *
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
WHERE prd_end_dt < prd_start_dt;

-- Check for invalid dates
SELECT 
    sls_order_dt
FROM 
     DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS
WHERE sls_order_dt is NULL OR LENGTH(sls_order_dt) = 8
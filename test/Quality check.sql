/* ============================================================
   DATA QUALITY CHECKS — BRONZE LAYER
   Purpose : Validate source data before cleaning & loading
             into SILVER schema.
   ============================================================ */

USE DATAWAREHOUSE;
USE SCHEMA Silver;
/* ------------------------------------------------------------
   1. CRM_SALES_DETAILS — Check for NULLs / Duplicate Keys
   ------------------------------------------------------------ */
SELECT 
    sls_prd_key,
    COUNT(*) AS record_count
FROM DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS
GROUP BY sls_prd_key
HAVING COUNT(*) > 1 
    OR sls_prd_key IS NULL;


/* ------------------------------------------------------------
   2. CRM_PRD_INFO — Check for Unwanted Leading/Trailing Spaces
   ------------------------------------------------------------ */
SELECT 
    prd_nm
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
WHERE prd_nm != TRIM(prd_nm);


/* ------------------------------------------------------------
   3. CRM_PRD_INFO — Quick Preview
   ------------------------------------------------------------ */
SELECT TOP 10 *
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO;


/* ------------------------------------------------------------
   4. CRM_PRD_INFO — Check for NULLs / Duplicate Primary Keys
   ------------------------------------------------------------ */
SELECT 
    prd_id,
    COUNT(*) AS record_count
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
GROUP BY prd_id
HAVING COUNT(*) > 1 
    OR prd_id IS NULL;


/* ------------------------------------------------------------
   5. CRM_PRD_INFO — Standardize Start Date Format
   ------------------------------------------------------------ */
SELECT
    prd_id,
    TO_DATE(prd_start_dt) AS prd_start_dt
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO;


/* ------------------------------------------------------------
   6. CRM_PRD_INFO — Check for Negative or NULL Cost
   ------------------------------------------------------------ */
SELECT 
    prd_id,
    prd_cost
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
WHERE prd_cost < 0 
   OR prd_cost IS NULL;


/* ------------------------------------------------------------
   7. CRM_PRD_INFO — Check for Invalid Date Ranges
      (End date earlier than start date)
   ------------------------------------------------------------ */
SELECT *
FROM DATAWAREHOUSE.BRONZE.CRM_PRD_INFO
WHERE prd_end_dt < prd_start_dt;


/* ------------------------------------------------------------
   8. CRM_SALES_DETAILS — Check for Invalid Dates
      (Ship/Due date earlier than order date)
   ------------------------------------------------------------ */
SELECT *
FROM DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS
WHERE sls_ship_dt < sls_order_dt 
   OR sls_due_dt  < sls_order_dt;


/* ------------------------------------------------------------
   9. CRM_SALES_DETAILS — Check Sales = Quantity * Price
      Also flags NULLs and non-positive values
   ------------------------------------------------------------ */
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM DATAWAREHOUSE.BRONZE.CRM_SALES_DETAILS
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY 
    sls_sales,
    sls_quantity,
    sls_price;


/* ------------------------------------------------------------
   10. ERP_CUST_AZ12 — Data Consistency Check on Gender Values
   ------------------------------------------------------------ */
SELECT DISTINCT gen
FROM DATAWAREHOUSE.BRONZE.ERP_CUST_AZ12;


/* ------------------------------------------------------------
   11. ERP_PX_CAT_G1V2 — Data Consistency Checks
   ------------------------------------------------------------ */
SELECT DISTINCT cat
FROM DATAWAREHOUSE.BRONZE.ERP_PX_CAT_G1V2;

SELECT DISTINCT subcat
FROM DATAWAREHOUSE.BRONZE.ERP_PX_CAT_G1V2;

SELECT DISTINCT maintenance
FROM DATAWAREHOUSE.BRONZE.ERP_PX_CAT_G1V2;
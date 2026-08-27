/*
============================================================================================
Creating TABLES for CRM & ERP Data 
Raw Bronze table (with ENABLE_SCHEMA_EVOLUTION)
============================================================================================
*/
-- ===================CRM======================
-- crm_cust_info
CREATE OR REPLACE TABLE DATAWAREHOUSE.BRONZE.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date	DATE
)
ENABLE_SCHEMA_EVOLUTION = TRUE;

--crm_prd_info
CREATE OR REPLACE TABLE DATAWAREHOUSE.BRONZE.crm_prd_info(
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(9),
    prd_start_dt TIMESTAMP_NTZ,
    prd_end_dt TIMESTAMP_NTZ
)
ENABLE_SCHEMA_EVOLUTION = TRUE;

--crm_sales_details
CREATE OR REPLACE TABLE DATAWAREHOUSE.BRONZE.crm_sales_details(
    sls_ord_num NVARCHAR(20),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT,
    sls_price FLOAT
)
ENABLE_SCHEMA_EVOLUTION = TRUE;

-- ===================ERP======================

--erp_cust_az12
CREATE OR REPLACE TABLE DATAWAREHOUSE.BRONZE.erp_cust_az12(
    CID NVARCHAR(50),
    BDATE DATE,
    GEN NVARCHAR(10)
)
ENABLE_SCHEMA_EVOLUTION = TRUE;

--erp_loc_A101
CREATE OR REPLACE TABLE DATAWAREHOUSE.BRONZE.erp_loc_A101(
    CID NVARCHAR(15),	
    CNTRY NVARCHAR(15)
)
ENABLE_SCHEMA_EVOLUTION = TRUE;

--erp_px_cat_g1v2 
CREATE OR REPLACE TABLE DATAWAREHOUSE.BRONZE.erp_px_cat_g1v2(
    ID NVARCHAR(9),
    CAT NVARCHAR(30),
    SUBCAT NVARCHAR(30),
    MAINTENANCE NVARCHAR(3)
)
ENABLE_SCHEMA_EVOLUTION = TRUE;
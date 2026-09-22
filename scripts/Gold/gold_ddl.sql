-- =====================================================================
-- DIM_CUSTOMERS
-- Purpose : Gold-layer customer dimension. Combines CRM customer master
--           data with ERP demographic (gender/birthdate) and location
--           (country) data into a single conformed dimension.
-- Source  : Reads from Silver dynamic tables (which are themselves
--           auto-refreshing), so row order/content can shift between
--           Gold refreshes.
-- Refresh : Dynamic table, auto-refreshes with up to 24h lag.
-- Storage : Iceberg format on external GCS volume via Snowflake catalog.
-- =====================================================================
CREATE OR REPLACE DYNAMIC ICEBERG TABLE DATAWAREHOUSE.GOLD.dim_customers
    TARGET_LAG = '24 hour'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'gold/dim_customer/dim_customer'
AS
SELECT
    -- Surrogate key: NOTE - ROW_NUMBER() is recalculated on every refresh,
    -- and since Silver is also a dynamic/refreshing source, values here
    -- are NOT guaranteed stable across refreshes. Do not persist/reference
    -- this key outside this pipeline without addressing that.
    ROW_NUMBER() OVER (PARTITION BY YEAR(ca.bdate) ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,              -- CRM system customer ID
    ci.cst_key AS customer_number,         -- CRM business/natural key, used to join to ERP
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    ci.cst_marital_status marital_status,

    -- Business rule: CRM gender is master; fall back to ERP gender if CRM is 'n/a'
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master Gender Info
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    cl.cntry AS country,                   -- Country from ERP location table
    ca.bdate AS birthdate,                 -- Birthdate from ERP customer table
    ci.cst_create_date AS create_date      -- Record creation date from CRM
FROM
    DATAWAREHOUSE.SILVER.CRM_CUST_INFO AS ci
    -- Enrich with ERP demographic data (gender, birthdate)
    LEFT JOIN DATAWAREHOUSE.SILVER.ERP_CUST_AZ12 AS ca
        ON ci.cst_key = ca.cid
    -- Enrich with ERP location data (country)
    LEFT JOIN DATAWAREHOUSE.SILVER.ERP_LOC_A101 AS cl
        ON ci.cst_key = cl.cid;


-- =====================================================================
-- DIM_PRODUCT
-- Purpose : Gold-layer product dimension. Combines CRM product master
--           data with ERP category/subcategory reference data.
-- Filter  : Keeps only current (non-historical) product records —
--           rows with a non-null prd_end_dt are superseded versions.
-- =====================================================================
CREATE OR REPLACE DYNAMIC ICEBERG TABLE DATAWAREHOUSE.GOLD.dim_product
    TARGET_LAG = '24 hour'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'gold/dim_customer/dim_product'
AS
SELECT
    -- Surrogate key: same stability caveat as dim_customers.customer_key
    ROW_NUMBER() OVER (PARTITION BY pc.cat ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
    pi.prd_id AS product_id,           -- CRM system product ID
    pi.prd_key AS product_number,      -- CRM business/natural key, used by fact table joins
    pi.prd_nm AS product_name,
    pi.cat_id AS category_id,          -- FK to ERP category reference table
    pc.cat AS category,
    pc.subcat AS sub_category,
    pi.prd_cost AS product_cost,
    pc.maintenance,
    pi.prd_line AS product_line,
    pi.prd_start_dt AS product_start_date
FROM DATAWAREHOUSE.SILVER.CRM_PRD_INFO AS pi
LEFT JOIN DATAWAREHOUSE.SILVER.ERP_PX_CAT_G1V2 AS pc
    ON pi.cat_id = pc.id
WHERE
    pi.prd_end_dt IS NULL; -- Filtering out historical/expired product versions


-- =====================================================================
-- FACT_SALES
-- Purpose : Gold-layer sales fact table. Grains sales at the order-line
--           level, joined to dim_customers/dim_product to resolve
--           surrogate keys for downstream reporting/BI.
-- Note    : Joins use business keys (product_number, customer_id), so
--           row resolution stays correct each refresh even though the
--           dimension surrogate keys themselves may shift.
-- =====================================================================
CREATE OR REPLACE DYNAMIC ICEBERG TABLE DATAWAREHOUSE.GOLD.fact_sales
    TARGET_LAG = '24 hour'
    WAREHOUSE = COMPUTE_WH
    EXTERNAL_VOLUME = 'gcs_iceberg_volume'
    CATALOG = 'SNOWFLAKE'
    BASE_LOCATION = 'gold/dim_customer/fact_sales'
AS
SELECT
    sd.sls_ord_num AS sale_order_number,   -- Sales order number (natural key)
    dp.product_key,                        -- FK -> dim_product surrogate key
    dc.customer_key,                       -- FK -> dim_customers surrogate key
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM DATAWAREHOUSE.SILVER.CRM_SALES_DETAILS AS sd
-- Resolve product surrogate key via product business key
LEFT JOIN DATAWAREHOUSE.GOLD.DIM_PRODUCT AS dp
    ON sd.sls_prd_key = dp.product_number
-- Resolve customer surrogate key via customer ID
LEFT JOIN DATAWAREHOUSE.GOLD.DIM_CUSTOMERS AS dc
    ON sd.sls_cust_id = dc.customer_id;
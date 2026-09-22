SELECT DISTINCT
    ci.cst_gndr,
    ca.gen AS gender,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master Gender Info
        ELSE COALESCE(ca.gen, 'n/a')
    END AS new_gen
FROM
    DATAWAREHOUSE.SILVER.CRM_CUST_INFO AS ci
    LEFT JOIN
        DATAWAREHOUSE.SILVER.ERP_CUST_AZ12 AS ca
    ON  
        ci.cst_key = ca.cid
    LEFT JOIN
        DATAWAREHOUSE.SILVER.ERP_LOC_A101 AS cl
    On 
        ci.cst_key = cl.cid
ORDER BY 1, 2

-- =============================================================
-- Load Bronze Layer - CRM Source
-- =============================================================
-- NOTA: Ejecutar con \copy desde psql o ajustar ruta al entorno
-- =============================================================

-- CRM: 
TRUNCATE TABLE bronze.crm_cliente_info;
\copy bronze.crm_cliente_info FROM 'datasets/source_crm/cust_info.csv' DELIMITER ',' CSV HEADER;

TRUNCATE TABLE bronze.crm_product_info;
\copy bronze.crm_product_info FROM 'datasets/source_crm/prd_info.csv' DELIMITER ',' CSV HEADER;

TRUNCATE TABLE bronze.crm_ventas_detalles;
\copy bronze.crm_ventas_detalles FROM 'datasets/source_crm/sales_details.csv' DELIMITER ',' CSV HEADER;

-- ERP: 
TRUNCATE TABLE bronze.erp_cust_az12;
\copy bronze.erp_cust_az12 FROM 'datasets/source_erp/CUST_AZ12.csv' DELIMITER ',' CSV HEADER;

TRUNCATE TABLE bronze.erp_loc_a101;
\copy bronze.erp_loc_a101 FROM 'datasets/source_erp/LOC_A101.csv' DELIMITER ',' CSV HEADER;

TRUNCATE TABLE bronze.erp_px_cat_g1v2;
\copy bronze.erp_px_cat_g1v2 FROM 'datasets/source_erp/PX_CAT_G1V2.csv' DELIMITER ',' CSV HEADER;




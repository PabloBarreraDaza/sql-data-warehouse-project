-- =============================================================
-- DDL - Silver Layer
-- =============================================================
-- Descripción : Crea las tablas de la capa Silver con columna
--               de metadata dwh_fec_creacion para trazabilidad.
-- Motor        : PostgreSQL 17
-- =============================================================

CREATE SCHEMA IF NOT EXISTS silver;

-- -------------------------------------------------------------
-- CRM: Customer Info
-- -------------------------------------------------------------
DROP TABLE IF EXISTS silver.crm_cliente_info;
CREATE TABLE silver.crm_cliente_info (
    cl_id               INT,
    cl_key              VARCHAR(50),
    cl_nombre           VARCHAR(50),
    cl_apellido         VARCHAR(50),
    cl_marital_status   VARCHAR(50),
    cl_genero           VARCHAR(50),
    cl_fec_creacion     DATE,
    dwh_fec_creacion    TIMESTAMP DEFAULT NOW()
);

-- -------------------------------------------------------------
-- CRM: Product Info
-- -------------------------------------------------------------
DROP TABLE IF EXISTS silver.crm_product_info;
CREATE TABLE silver.crm_product_info (
    prd_id              INT,
    prd_key             VARCHAR(50),
    prd_nombre          VARCHAR(50),
    prd_coste           INT,
    prd_line            VARCHAR(50),
    prd_start_dt        DATE,
    prd_end_dt          DATE,
    dwh_fec_creacion    TIMESTAMP DEFAULT NOW()
);

-- -------------------------------------------------------------
-- CRM: Ventas Detalles
-- -------------------------------------------------------------
DROP TABLE IF EXISTS silver.crm_ventas_detalles;
CREATE TABLE silver.crm_ventas_detalles (
    vts_ord_num         VARCHAR(50),
    vts_prd_key         VARCHAR(50),
    vts_cl_id           INT,
    vts_order_dt        INT,
    vts_ship_dt         INT,
    vts_due_dt          INT,
    vts_sales           INT,
    vts_cantidad        INT,
    vts_precio          INT,
    dwh_fec_creacion    TIMESTAMP DEFAULT NOW()
);

-- -------------------------------------------------------------
-- ERP: Locations
-- -------------------------------------------------------------
DROP TABLE IF EXISTS silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
    cid                 VARCHAR(50),
    pais                VARCHAR(50),
    dwh_fec_creacion    TIMESTAMP DEFAULT NOW()
);

-- -------------------------------------------------------------
-- ERP: Customers
-- -------------------------------------------------------------
DROP TABLE IF EXISTS silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
    cid                 VARCHAR(50),
    fec_nac             DATE,
    gen                 VARCHAR(50),
    dwh_fec_creacion    TIMESTAMP DEFAULT NOW()
);

-- -------------------------------------------------------------
-- ERP: Product Categories
-- -------------------------------------------------------------
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
    id                  VARCHAR(50),
    cat                 VARCHAR(50),
    subcat              VARCHAR(50),
    maintenance         VARCHAR(50),
    dwh_fec_creacion    TIMESTAMP DEFAULT NOW()
);

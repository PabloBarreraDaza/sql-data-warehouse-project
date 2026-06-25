

CREATE TABLE bronze.crm_cliente_info (
    cl_id              INT,
    cl_key             VARCHAR(50),
    cl_nombre       VARCHAR(50),
    cl_apellido        VARCHAR(50),
    cl_marital_status  VARCHAR(50),
    cl_genero            VARCHAR(50),
    cl_fec_creacion     DATE
);

CREATE TABLE bronze.crm_product_info (
    prd_id       INT,
    prd_key      VARCHAR(50),
    prd_nombre       VARCHAR(50),
    prd_coste     INT,
    prd_line     VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt   DATE
);

CREATE TABLE bronze.crm_ventas_detalles (
    vts_ord_num  VARCHAR(50),
    vts_prd_key  VARCHAR(50),
    vts_cl_id  INT,
    vts_order_dt INT,
    vts_ship_dt  INT,
    vts_due_dt   INT,
    vts_sales    INT,
    vts_cantidad INT,
    vts_precio    INT
);

CREATE TABLE bronze.erp_loc_a101 (
    cid    VARCHAR(50),
    pais  VARCHAR(50)
);

CREATE TABLE bronze.erp_cust_az12 (
    cid    VARCHAR(50),
    fec_nac  DATE,
    gen    VARCHAR(50)
);

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
);

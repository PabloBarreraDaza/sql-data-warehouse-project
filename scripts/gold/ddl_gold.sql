-- =============================================================
-- DDL - Gold Layer: Vistas dimensionales y tabla de hechos
-- =============================================================
-- Descripción : Crea las vistas de la capa Gold siguiendo un
--               esquema estrella listo para reporting y analítica.
-- Tablas origen: Silver layer (crm_cliente_info, erp_cust_az12,
--                erp_loc_a101, crm_product_info, erp_px_cat_g1v2,
--                crm_ventas_detalles)
-- Objetos creados:
--   - gold.dim_customers  (dimensión clientes)
--   - gold.dim_products   (dimensión productos)
--   - gold.fact_sales     (tabla de hechos ventas)
-- =============================================================

CREATE SCHEMA IF NOT EXISTS gold;

-- ====================================================================
-- gold.dim_customers
-- ====================================================================
-- Integra datos de clientes desde crm_cliente_info, erp_cust_az12
-- y erp_loc_a101. El género se resuelve priorizando CRM sobre ERP.
-- Surrogate key generada con ROW_NUMBER() ordenada por cliente_id.
-- ====================================================================

CREATE OR REPLACE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cl_id)   AS cliente_key,
    ci.cl_id                                AS cliente_id,
    ci.cl_key                               AS cliente_numero,
    ci.cl_nombre                            AS nombre,
    ci.cl_apellido                          AS apellido,
    -- Prioriza género de CRM; si es N/A usa ERP; si ambos fallan → N/A
    CASE
        WHEN ci.cl_genero != 'N/A' THEN ci.cl_genero
        ELSE COALESCE(ca.gen, 'N/A')
    END                                     AS genero,
    ci.cl_marital_status                    AS estado_civil,
    ci.cl_fec_creacion                      AS fecha_creacion,
    ca.fec_nac                              AS fecha_nacimiento,
    la.pais                                 AS pais
FROM silver.crm_cliente_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cl_key = ca.cid
LEFT JOIN silver.erp_loc_a101  la ON ci.cl_key = la.cid;

-- ====================================================================
-- gold.dim_products
-- ====================================================================
-- Integra datos de productos desde crm_product_info y erp_px_cat_g1v2.
-- Solo incluye productos activos (prd_end_dt IS NULL = producto vigente).
-- Surrogate key generada con ROW_NUMBER() ordenada por fecha inicio y key.
-- ====================================================================

CREATE OR REPLACE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    )                                       AS product_key,
    pn.prd_id                               AS product_id,
    pn.prd_key                              AS product_number,
    pn.prd_nombre                           AS nombre_producto,
    pn.cat_id                               AS categoria_id,
    pc.cat                                  AS nombre_categoria,
    pc.subcat                               AS nombre_subcategoria,
    pc.maintenance,
    pn.prd_coste                            AS coste_producto,
    pn.prd_line                             AS linea_producto,
    pn.prd_start_dt                         AS fecha_inicio,
    pn.prd_end_dt                           AS fecha_fin
FROM silver.crm_product_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;

-- ====================================================================
-- gold.fact_sales
-- ====================================================================
-- Tabla de hechos de ventas. Conecta con dim_products via product_number
-- y con dim_customers via cliente_id.
-- ====================================================================

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT
    sd.vts_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.cliente_key  AS customer_key,
    sd.vts_order_dt AS order_date,
    sd.vts_ship_dt  AS shipping_date,
    sd.vts_due_dt   AS due_date,
    sd.vts_sales    AS sales_amount,
    sd.vts_cantidad AS cantidad,
    sd.vts_precio   AS precio
FROM silver.crm_ventas_detalles sd
LEFT JOIN gold.dim_products  pr ON sd.vts_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.vts_cl_id   = cu.cliente_id;

-- =============================================================
-- Quality Checks - Silver Layer
-- =============================================================
-- Descripción : Verificaciones de calidad de datos en la capa
--               Silver tras cada carga desde Bronze.
-- Checks incluidos:
--   - Claves primarias NULL o duplicadas
--   - Espacios no deseados en campos de texto
--   - Estandarización y consistencia de datos
--   - Rangos de fechas inválidos
--   - Consistencia entre campos relacionados
-- Uso: Ejecutar después de cada carga a Silver.
--      Resultado esperado: 0 filas en cada check.
-- =============================================================

-- ====================================================================
-- silver.crm_cliente_info
-- ====================================================================

-- Clave primaria: NULLs o duplicados
-- Esperado: 0 filas
SELECT
    cl_id,
    COUNT(*)
FROM silver.crm_cliente_info
GROUP BY cl_id
HAVING COUNT(*) > 1 OR cl_id IS NULL;

-- Espacios no deseados en cl_key
-- Esperado: 0 filas
SELECT cl_key
FROM silver.crm_cliente_info
WHERE cl_key != TRIM(cl_key);

-- Espacios no deseados en cl_nombre y cl_apellido
-- Esperado: 0 filas
SELECT cl_nombre, cl_apellido
FROM silver.crm_cliente_info
WHERE cl_nombre != TRIM(cl_nombre)
   OR cl_apellido != TRIM(cl_apellido);

-- Estandarización: valores distintos de estado civil y género
SELECT DISTINCT cl_marital_status FROM silver.crm_cliente_info;
SELECT DISTINCT cl_genero         FROM silver.crm_cliente_info;

-- ====================================================================
-- silver.crm_product_info
-- ====================================================================

-- Clave primaria: NULLs o duplicados
-- Esperado: 0 filas
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_product_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Espacios no deseados en prd_nombre
-- Esperado: 0 filas
SELECT prd_nombre
FROM silver.crm_product_info
WHERE prd_nombre != TRIM(prd_nombre);

-- Coste negativo o NULL
-- Esperado: 0 filas
SELECT prd_coste
FROM silver.crm_product_info
WHERE prd_coste < 0 OR prd_coste IS NULL;

-- Estandarización: valores distintos de línea de producto
SELECT DISTINCT prd_line FROM silver.crm_product_info;

-- Fechas inválidas: prd_end_dt anterior a prd_start_dt
-- Esperado: 0 filas
SELECT *
FROM silver.crm_product_info
WHERE prd_end_dt < prd_start_dt;

-- ====================================================================
-- silver.crm_ventas_detalles
-- ====================================================================

-- Fechas inválidas en origen Bronze (para referencia)
-- Esperado: ~19 filas conocidas con datos corruptos
SELECT
    vts_order_dt,
    vts_ship_dt,
    vts_due_dt
FROM bronze.crm_ventas_detalles
WHERE vts_order_dt <= 0
   OR LENGTH(vts_order_dt::TEXT) != 8
   OR vts_order_dt > 20500101
   OR vts_order_dt < 19000101;

-- Orden de fechas inválido: order_dt posterior a ship_dt o due_dt
-- Esperado: 0 filas
SELECT *
FROM silver.crm_ventas_detalles
WHERE vts_order_dt > vts_ship_dt
   OR vts_order_dt > vts_due_dt;

-- Consistencia: vts_sales = vts_cantidad * vts_precio
-- Esperado: 0 filas
SELECT DISTINCT
    vts_sales,
    vts_cantidad,
    vts_precio
FROM silver.crm_ventas_detalles
WHERE vts_sales != vts_cantidad * vts_precio
   OR vts_sales    IS NULL OR vts_sales    <= 0
   OR vts_cantidad IS NULL OR vts_cantidad <= 0
   OR vts_precio   IS NULL OR vts_precio   <= 0
ORDER BY vts_sales, vts_cantidad, vts_precio;

-- ====================================================================
-- silver.erp_cust_az12
-- ====================================================================

-- Fechas de nacimiento fuera de rango (< 1924 o futuras)
-- Esperado: 0 filas
SELECT DISTINCT fec_nac
FROM silver.erp_cust_az12
WHERE fec_nac < '1924-01-01'
   OR fec_nac > NOW();

-- Prefijo NAS no eliminado
-- Esperado: 0 filas
SELECT *
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- Estandarización: valores distintos de género
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-- ====================================================================
-- silver.erp_loc_a101
-- ====================================================================

-- Guiones no eliminados en cid
-- Esperado: 0 filas
SELECT *
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- Estandarización: valores distintos de país
SELECT DISTINCT pais
FROM silver.erp_loc_a101
ORDER BY pais;

-- ====================================================================
-- silver.erp_px_cat_g1v2
-- ====================================================================

-- Espacios no deseados en cat, subcat y maintenance
-- Esperado: 0 filas
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat         != TRIM(cat)
   OR subcat      != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- Estandarización: valores distintos de maintenance
SELECT DISTINCT maintenance FROM silver.erp_px_cat_g1v2;

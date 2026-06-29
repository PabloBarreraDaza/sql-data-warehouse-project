-- =============================================================
-- Load Silver Layer - CRM: crm_cliente_info
-- =============================================================
-- Descripción : Limpieza y transformación de datos de clientes
--               desde Bronze hacia Silver.
-- Tabla origen : bronze.crm_cliente_info  (18.494 filas)
-- Tabla destino: silver.crm_cliente_info
-- Transformaciones aplicadas:
--   1. Eliminación de duplicados por cl_id (quedamos con el más reciente)
--   2. TRIM en cl_nombre y cl_apellido (espacios extra)
--   3. Normalización de cl_marital_status (S/M → Single/Married)
--   4. Normalización de cl_genero (F/M → Female/Male)
-- =============================================================
 
-- -------------------------------------------------------------
-- Validación previa (ejecutar manualmente para control de calidad)
-- -------------------------------------------------------------
 
-- Total filas en Bronze
-- SELECT COUNT(*) FROM bronze.crm_cliente_info;
-- Resultado esperado: 18.494 filas
 
-- Filas sin duplicados por cl_id
-- SELECT COUNT(*) FROM (
--     SELECT *, ROW_NUMBER() OVER (PARTITION BY cl_id ORDER BY cl_fec_creacion DESC) AS ranking
--     FROM bronze.crm_cliente_info
-- ) sub WHERE ranking = 1;
-- Resultado esperado: 18.485 filas
 
-- Nombres con espacios extra (deben ser 0 tras la carga)
-- SELECT cl_nombre FROM bronze.crm_cliente_info
-- WHERE cl_nombre != TRIM(cl_nombre);
 
-- -------------------------------------------------------------
-- Carga a Silver
-- -------------------------------------------------------------
 
TRUNCATE TABLE silver.crm_cliente_info;
 
INSERT INTO silver.crm_cliente_info (
    cl_id,
    cl_key,
    cl_nombre,
    cl_apellido,
    cl_marital_status,
    cl_genero,
    cl_fec_creacion
)
SELECT
    cl_id,
    cl_key,
    TRIM(cl_nombre)    AS cl_nombre,
    TRIM(cl_apellido)  AS cl_apellido,
    CASE
        WHEN UPPER(cl_marital_status) = 'S' THEN 'Single'
        WHEN UPPER(cl_marital_status) = 'M' THEN 'Married'
        ELSE 'N/A'
    END AS cl_marital_status,
    CASE
        WHEN UPPER(cl_genero) = 'F' THEN 'Female'
        WHEN UPPER(cl_genero) = 'M' THEN 'Male'
        ELSE 'N/A'
    END AS cl_genero,
    cl_fec_creacion
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cl_id
            ORDER BY cl_fec_creacion DESC
        ) AS ranking
    FROM bronze.crm_cliente_info
) sub
WHERE ranking = 1;
 
-- -------------------------------------------------------------
-- Validación posterior
-- -------------------------------------------------------------
 
-- Verificar filas cargadas en Silver (esperado: 18.485)
-- SELECT COUNT(*) FROM silver.crm_cliente_info;
 
-- Verificar que no quedan duplicados
-- SELECT cl_id, COUNT(*) FROM silver.crm_cliente_info
-- GROUP BY cl_id HAVING COUNT(*) > 1;
 
-- Verificar que no quedan espacios en nombres
-- SELECT * FROM silver.crm_cliente_info
-- WHERE cl_nombre != TRIM(cl_nombre) OR cl_apellido != TRIM(cl_apellido);
 
-- Verificar valores de marital_status y genero
-- SELECT DISTINCT cl_marital_status FROM silver.crm_cliente_info;
-- SELECT DISTINCT cl_genero FROM silver.crm_cliente_info;



-- =============================================================
-- DDL + Load Silver Layer - CRM: crm_product_info
-- =============================================================
-- Descripción : Recreación y carga de la tabla de productos
--               desde Bronze hacia Silver.
-- Tabla origen : bronze.crm_product_info
-- Tabla destino: silver.crm_product_info
-- Transformaciones aplicadas:
--   1. Extracción de cat_id desde los primeros 5 chars de prd_key
--   2. Extracción del prd_key real (desde char 7 en adelante)
--   3. Normalización de prd_line (M/R/S/T → texto legible)
--   4. Coste NULL → 0
--   5. Cálculo de prd_end_dt con LEAD() (día anterior al siguiente start)
-- =============================================================
 
-- -------------------------------------------------------------
-- DDL
-- -------------------------------------------------------------
 
DROP TABLE IF EXISTS silver.crm_product_info;
-- creamos de nuevo la tabla para añadir el nuevo campo
CREATE TABLE silver.crm_product_info (
    prd_id           INT,
    cat_id           VARCHAR(50),
    prd_key          VARCHAR(50),
    prd_nombre       VARCHAR(50),
    prd_coste        INT,
    prd_line         VARCHAR(50),
    prd_start_dt     DATE,
    prd_end_dt       DATE,
    dwh_fec_creacion TIMESTAMP DEFAULT NOW()
);
 
-- -------------------------------------------------------------
-- Validación previa
-- -------------------------------------------------------------
 
-- Total filas en Bronze
-- SELECT COUNT(*) FROM bronze.crm_product_info;
 
-- Revisar valores distintos de prd_line antes de normalizar
-- SELECT DISTINCT prd_line FROM bronze.crm_product_info;
 
-- Revisar estructura de prd_key (prefijo cat + guion + key real)
-- SELECT prd_key,
--        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id_preview,
--        SUBSTRING(prd_key, 7, LENGTH(prd_key))       AS prd_key_preview
-- FROM bronze.crm_product_info LIMIT 10;
 
-- -------------------------------------------------------------
-- Carga a Silver
-- -------------------------------------------------------------
 
TRUNCATE TABLE silver.crm_product_info;
 
INSERT INTO silver.crm_product_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nombre,
    prd_coste,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    -- Extrae cat_id de los primeros 5 chars (para join con erp_px_cat_g1v2)
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')      AS cat_id,
    -- Extrae prd_key real eliminando el prefijo de categoría (chars 1-6)
    SUBSTRING(prd_key, 7, LENGTH(prd_key))            AS prd_key,
    prd_nombre,
    -- Si el coste es NULL se reemplaza por 0
    COALESCE(prd_coste, 0)                            AS prd_coste,
    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'N/A'
    END                                               AS prd_line,
    CAST(prd_start_dt AS DATE)                        AS prd_start_dt,
    -- Calcula end_dt como el día anterior al siguiente start_dt del mismo producto
    CAST(
        LEAD(prd_start_dt) OVER (
            PARTITION BY SUBSTRING(prd_key, 7, LENGTH(prd_key))
            ORDER BY prd_start_dt
        ) - INTERVAL '1 day'
    AS DATE)                                          AS prd_end_dt
FROM bronze.crm_product_info;
 
-- -------------------------------------------------------------
-- Validación posterior
-- -------------------------------------------------------------
 
-- Verificar filas cargadas
-- SELECT COUNT(*) FROM silver.crm_product_info;
 
-- Verificar que prd_line solo tiene valores normalizados
-- SELECT DISTINCT prd_line FROM silver.crm_product_info;
 
-- Verificar que no hay costes NULL
-- SELECT * FROM silver.crm_product_info WHERE prd_coste IS NULL;
 
-- Verificar lógica de end_dt
-- SELECT prd_key, prd_start_dt, prd_end_dt
-- FROM silver.crm_product_info
-- WHERE prd_end_dt IS NOT NULL
-- ORDER BY prd_key, prd_start_dt;

-- =============================================================
-- DDL + Load Silver Layer - CRM: crm_ventas_detalles
-- =============================================================
-- Descripción : Limpieza y transformación de datos de ventas
--               desde Bronze hacia Silver.
-- Tabla origen : bronze.crm_ventas_detalles
-- Tabla destino: silver.crm_ventas_detalles
-- Transformaciones aplicadas:
--   1. Conversión de fechas enteras (YYYYMMDD) a tipo DATE
--   2. Fechas inválidas (0 o longitud != 8) → NULL
--   3. Recálculo de vts_sales si es NULL, <= 0 o inconsistente
--   4. Recálculo de vts_precio si es NULL o <= 0
-- =============================================================

-- Borrado y creación de tabla para cambiar los tipos de dato de las fechas a DATE
DROP TABLE IF EXISTS silver.crm_ventas_detalles;
CREATE TABLE silver.crm_ventas_detalles (
    vts_ord_num      VARCHAR(50),
    vts_prd_key      VARCHAR(50),
    vts_cl_id        INT,
    vts_order_dt     DATE,        -- cambiado de INT a DATE
    vts_ship_dt      DATE,        -- cambiado de INT a DATE
    vts_due_dt       DATE,        -- cambiado de INT a DATE
    vts_sales        INT,
    vts_cantidad     INT,
    vts_precio       INT,
    dwh_fec_creacion TIMESTAMP DEFAULT NOW()
);

-- -------------------------------------------------------------
-- Validación previa
-- -------------------------------------------------------------

-- Revisar fechas con formato inválido
 --SELECT DISTINCT vts_order_dt FROM bronze.crm_ventas_detalles
 --WHERE vts_order_dt = 0 OR LENGTH(vts_order_dt::TEXT) != 8;

-- Revisar ventas inconsistentes (sales != cantidad * precio)
--SELECT * FROM bronze.crm_ventas_detalles
 --WHERE vts_sales != vts_cantidad * ABS(vts_precio)
   -- OR vts_sales IS NULL OR vts_sales <= 0;

-- Revisar precios inválidos
-- SELECT * FROM bronze.crm_ventas_detalles
 -- WHERE vts_precio IS NULL OR vts_precio <= 0;

-- -------------------------------------------------------------
-- Carga a Silver
-- -------------------------------------------------------------

TRUNCATE TABLE silver.crm_ventas_detalles;

INSERT INTO silver.crm_ventas_detalles (
    vts_ord_num,
    vts_prd_key,
    vts_cl_id,
    vts_order_dt,
    vts_ship_dt,
    vts_due_dt,
    vts_sales,
    vts_cantidad,
    vts_precio
)
SELECT
    vts_ord_num,
    vts_prd_key,
    vts_cl_id,
    -- Convierte entero YYYYMMDD a DATE; si es 0 o longitud inválida → NULL
    CASE
        WHEN vts_order_dt = 0 OR LENGTH(vts_order_dt::TEXT) != 8 THEN NULL
        ELSE TO_DATE(vts_order_dt::TEXT, 'YYYYMMDD')
    END AS vts_order_dt,
    CASE
        WHEN vts_ship_dt = 0 OR LENGTH(vts_ship_dt::TEXT) != 8 THEN NULL
        ELSE TO_DATE(vts_ship_dt::TEXT, 'YYYYMMDD')
    END AS vts_ship_dt,
    CASE
        WHEN vts_due_dt = 0 OR LENGTH(vts_due_dt::TEXT) != 8 THEN NULL
        ELSE TO_DATE(vts_due_dt::TEXT, 'YYYYMMDD')
    END AS vts_due_dt,
    -- Recalcula vts_sales si es NULL, <= 0 o no coincide con cantidad * precio
    CASE
        WHEN vts_sales IS NULL OR vts_sales <= 0
          OR vts_sales != vts_cantidad * ABS(vts_precio)
            THEN vts_cantidad * ABS(vts_precio)
        ELSE vts_sales
    END AS vts_sales,
    vts_cantidad,
    -- Recalcula vts_precio si es NULL o <= 0
    CASE
        WHEN vts_precio IS NULL OR vts_precio <= 0
            THEN vts_sales / NULLIF(vts_cantidad, 0)
        ELSE vts_precio
    END AS vts_precio
FROM bronze.crm_ventas_detalles;

-- -------------------------------------------------------------
-- Validación posterior
-- -------------------------------------------------------------

-- Verificar filas cargadas
-- SELECT COUNT(*) FROM silver.crm_ventas_detalles;

-- Verificar que no quedan fechas inválidas
-- SELECT * FROM silver.crm_ventas_detalles
-- WHERE vts_order_dt IS NULL OR vts_ship_dt IS NULL;

-- Verificar consistencia sales = cantidad * precio
-- SELECT * FROM silver.crm_ventas_detalles
-- WHERE vts_sales != vts_cantidad * vts_precio;

-- Verificar que no hay precios ni ventas negativos o nulos
-- SELECT * FROM silver.crm_ventas_detalles
-- WHERE vts_precio <= 0 OR vts_sales <= 0;

-- =============================================================
-- Load Silver Layer - ERP: erp_cust_az12, erp_loc_a101, erp_px_cat_g1v2
-- =============================================================
-- Descripción : Limpieza y transformación de tablas ERP
--               desde Bronze hacia Silver.
-- Transformaciones aplicadas:
--   erp_cust_az12  : Elimina prefijo 'NAS' en cid, fechas futuras → NULL,
--                    normalización de género
--   erp_loc_a101   : Elimina guiones en cid, normalización de países
--   erp_px_cat_g1v2: Carga directa sin transformaciones
-- =============================================================

-- -------------------------------------------------------------
-- erp_cust_az12
-- -------------------------------------------------------------

-- Validación previa
-- Revisar cids con prefijo NAS
-- SELECT * FROM bronze.erp_cust_az12 WHERE cid LIKE 'NAS%';

-- Revisar fechas de nacimiento futuras
-- SELECT * FROM bronze.erp_cust_az12 WHERE fec_nac > NOW();

-- Revisar valores distintos de género
-- SELECT DISTINCT gen FROM bronze.erp_cust_az12;

TRUNCATE TABLE silver.erp_cust_az12;

INSERT INTO silver.erp_cust_az12 (
    cid,
    fec_nac,
    gen
)
SELECT
    -- Elimina prefijo 'NAS' si existe
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
        ELSE cid
    END AS cid,
    -- Fechas de nacimiento futuras → NULL
    CASE
        WHEN fec_nac > NOW() THEN NULL
        ELSE fec_nac
    END AS fec_nac,
    -- Normalización de género
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
        ELSE 'N/A'
    END AS gen
FROM bronze.erp_cust_az12;

-- Validación posterior
-- SELECT COUNT(*) FROM silver.erp_cust_az12;
-- SELECT DISTINCT gen FROM silver.erp_cust_az12;
-- SELECT * FROM silver.erp_cust_az12 WHERE fec_nac IS NULL;
-- SELECT * FROM silver.erp_cust_az12 WHERE cid LIKE 'NAS%';

-- -------------------------------------------------------------
-- erp_loc_a101
-- -------------------------------------------------------------

-- Validación previa
-- Revisar valores distintos de país antes de normalizar
-- SELECT DISTINCT pais FROM bronze.erp_loc_a101;

-- Revisar cids con guiones
-- SELECT * FROM bronze.erp_loc_a101 WHERE cid LIKE '%-%';

TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (
    cid,
    pais
)
SELECT
    -- Elimina guiones del cid para unificar con otras tablas
    REPLACE(cid, '-', '') AS cid,
    -- Normalización de códigos de país a nombres completos
    CASE
        WHEN TRIM(pais) = 'DE'             THEN 'Germany'
        WHEN TRIM(pais) IN ('US', 'USA')   THEN 'United States'
        WHEN TRIM(pais) = '' OR pais IS NULL THEN 'N/A'
        ELSE TRIM(pais)
    END AS pais
FROM bronze.erp_loc_a101;

-- Validación posterior
-- SELECT COUNT(*) FROM silver.erp_loc_a101;
-- SELECT DISTINCT pais FROM silver.erp_loc_a101;
-- SELECT * FROM silver.erp_loc_a101 WHERE cid LIKE '%-%';

-- -------------------------------------------------------------
-- erp_px_cat_g1v2
-- -------------------------------------------------------------

-- Validación previa
-- SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;
-- SELECT DISTINCT cat, subcat FROM bronze.erp_px_cat_g1v2;

TRUNCATE TABLE silver.erp_px_cat_g1v2;

INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

-- Validación posterior
-- SELECT COUNT(*) FROM silver.erp_px_cat_g1v2;
-- SELECT DISTINCT cat FROM silver.erp_px_cat_g1v2;

-- =============================================================
-- Silver Layer - Carga ERP completada
-- =============================================================

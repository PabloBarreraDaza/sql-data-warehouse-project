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

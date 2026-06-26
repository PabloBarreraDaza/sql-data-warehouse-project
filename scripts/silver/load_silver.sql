- =============================================================
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

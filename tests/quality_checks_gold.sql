-- =============================================================
-- Quality Checks - Gold Layer
-- =============================================================
-- Descripción : Verificaciones de integridad y unicidad en la
--               capa Gold tras la creación de las vistas.
-- Checks incluidos:
--   - Unicidad de surrogate keys en dimensiones
--   - Conectividad entre fact_sales y las dimensiones
-- Uso: Ejecutar después de crear las vistas de Gold.
--      Resultado esperado: 0 filas en cada check.
-- =============================================================

-- ====================================================================
-- gold.dim_customers
-- ====================================================================

-- Unicidad de cliente_key (surrogate key)
-- Esperado: 0 filas
SELECT
    cliente_key,
    COUNT(*) AS duplicados
FROM gold.dim_customers
GROUP BY cliente_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- gold.dim_products
-- ====================================================================

-- Unicidad de product_key (surrogate key)
-- Esperado: 0 filas
SELECT
    product_key,
    COUNT(*) AS duplicados
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- gold.fact_sales
-- ====================================================================

-- Conectividad del modelo: detecta hechos sin dimensión asociada
-- Esperado: 0 filas (toda venta debe tener producto y cliente)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.cliente_key = f.customer_key
LEFT JOIN gold.dim_products  p ON p.product_key = f.product_key
WHERE p.product_key IS NULL
   OR c.cliente_key IS NULL;

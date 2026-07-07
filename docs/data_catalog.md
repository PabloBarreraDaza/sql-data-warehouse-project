# Data Catalog - Gold Layer

## Descripción general

La capa Gold es la representación de datos a nivel de negocio, estructurada para dar soporte a casos de uso analíticos y de reporting. Está compuesta por **tablas de dimensiones** y una **tabla de hechos** que modelan las métricas del negocio en un esquema estrella.

---

## 1. `gold.dim_customers`

**Propósito:** Almacena los datos de clientes enriquecidos con información demográfica y geográfica, integrando fuentes CRM y ERP.

| Columna | Tipo | Descripción |
|---|---|---|
| `cliente_key` | INT | Surrogate key que identifica de forma única cada registro de cliente en la dimensión. Generada con ROW_NUMBER(). |
| `cliente_id` | INT | Identificador numérico único del cliente proveniente del sistema CRM. |
| `cliente_numero` | VARCHAR(50) | Código alfanumérico del cliente usado para trazabilidad y referencia (campo `cl_key` en CRM). |
| `nombre` | VARCHAR(50) | Nombre del cliente, con espacios extra eliminados. |
| `apellido` | VARCHAR(50) | Apellido del cliente, con espacios extra eliminados. |
| `genero` | VARCHAR(50) | Género del cliente (`Male`, `Female`, `N/A`). Prioriza el valor CRM; si es N/A usa el valor ERP. |
| `estado_civil` | VARCHAR(50) | Estado civil del cliente (`Married`, `Single`, `N/A`). |
| `fecha_creacion` | DATE | Fecha en la que se creó el registro del cliente en el sistema CRM. |
| `fecha_nacimiento` | DATE | Fecha de nacimiento del cliente proveniente de ERP, formato YYYY-MM-DD. Valores fuera de rango → NULL. |
| `pais` | VARCHAR(50) | País de residencia del cliente proveniente de ERP (ej. `United States`, `Germany`). |

---

## 2. `gold.dim_products`

**Propósito:** Proporciona información sobre los productos y sus atributos, integrando datos de CRM y categorías ERP. Solo incluye productos activos (sin fecha de fin).

| Columna | Tipo | Descripción |
|---|---|---|
| `product_key` | INT | Surrogate key que identifica de forma única cada producto en la dimensión. Generada con ROW_NUMBER(). |
| `product_id` | INT | Identificador numérico único del producto proveniente del sistema CRM. |
| `product_number` | VARCHAR(50) | Código alfanumérico estructurado del producto, usado para categorización e inventario. |
| `nombre_producto` | VARCHAR(50) | Nombre descriptivo del producto. |
| `categoria_id` | VARCHAR(50) | Identificador de la categoría del producto, extraído del prefijo de `prd_key` y usado para el join con ERP. |
| `nombre_categoria` | VARCHAR(50) | Clasificación amplia del producto (ej. `Bikes`, `Components`). Proveniente de ERP. |
| `nombre_subcategoria` | VARCHAR(50) | Clasificación detallada del producto dentro de la categoría (ej. `Road Bikes`). Proveniente de ERP. |
| `maintenance` | VARCHAR(50) | Indica si el producto requiere mantenimiento (`Yes`, `No`). Proveniente de ERP. |
| `coste_producto` | INT | Coste base del producto en unidades monetarias. NULL en origen reemplazado por 0. |
| `linea_producto` | VARCHAR(50) | Línea de producto a la que pertenece (`Mountain`, `Road`, `Touring`, `Other Sales`, `N/A`). |
| `fecha_inicio` | DATE | Fecha desde la que el producto está disponible para la venta. |
| `fecha_fin` | DATE | Fecha en la que el producto dejó de estar vigente. NULL indica producto activo. |

---

## 3. `gold.fact_sales`

**Propósito:** Almacena los datos transaccionales de ventas para análisis. Conecta con las dimensiones mediante surrogate keys.

| Columna | Tipo | Descripción |
|---|---|---|
| `order_number` | VARCHAR(50) | Identificador alfanumérico único de cada pedido de venta (ej. `SO54496`). |
| `product_key` | INT | Surrogate key que conecta el pedido con `gold.dim_products`. |
| `customer_key` | INT | Surrogate key que conecta el pedido con `gold.dim_customers`. |
| `order_date` | DATE | Fecha en la que se realizó el pedido. NULL si la fecha original en Bronze era inválida. |
| `shipping_date` | DATE | Fecha en la que se envió el pedido al cliente. NULL si la fecha original era inválida. |
| `due_date` | DATE | Fecha límite de pago del pedido. NULL si la fecha original era inválida. |
| `sales_amount` | INT | Valor monetario total de la línea de venta. Recalculado si el valor original era incorrecto o inconsistente. |
| `cantidad` | INT | Número de unidades del producto pedidas en la línea de venta. |
| `precio` | INT | Precio por unidad del producto. Recalculado si el valor original era NULL o negativo. |

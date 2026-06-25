# Data Warehouse and Analytics Project 🚀

Proyecto completo de data warehousing y analytics, desde la construcción del almacén de datos hasta la generación de insights accionables. Diseñado como proyecto de portfolio, refleja buenas prácticas de ingeniería de datos y analítica.

---

## 🏗️ Arquitectura de datos

El proyecto sigue la **Medallion Architecture** con tres capas:

| Capa | Descripción |
|------|-------------|
| **Bronze** | Datos raw tal como llegan de los sistemas fuente, ingestados desde CSV a SQL Server. |
| **Silver** | Limpieza, estandarización y normalización de datos para prepararlos para el análisis. |
| **Gold** | Datos listos para el negocio, modelados en esquema estrella para reporting y analítica. |

---

## 📖 Descripción del proyecto

El proyecto abarca las siguientes áreas:

- **Arquitectura de datos** — Diseño de un Data Warehouse moderno con Medallion Architecture.
- **Pipelines ETL** — Extracción, transformación y carga de datos desde los sistemas fuente.
- **Modelado de datos** — Desarrollo de tablas de hechos y dimensiones optimizadas para consultas analíticas.
- **Analytics & Reporting** — Informes y dashboards basados en SQL para generar insights accionables.

> Este repositorio es un recurso ideal para profesionales y estudiantes que quieran demostrar experiencia en SQL Development, Data Architecture, Data Engineering, ETL, Data Modeling y Data Analytics.

---

## 🛠️ Herramientas utilizadas

- **Datasets** — Archivos CSV con los datos del proyecto.
- **SQL Server Express** — Servidor ligero para alojar la base de datos.
- **SSMS** — SQL Server Management Studio, interfaz gráfica para gestionar la base de datos.
- **Git / GitHub** — Control de versiones y colaboración.

---

## 🚀 Requisitos del proyecto

### Data Engineering — Construcción del Data Warehouse

**Objetivo:** Desarrollar un data warehouse moderno en SQL Server para consolidar datos de ventas y habilitar reporting analítico.

**Especificaciones:**

- **Fuentes de datos** — Importación desde dos sistemas (ERP y CRM) en formato CSV.
- **Calidad de datos** — Limpieza y resolución de problemas de calidad antes del análisis.
- **Integración** — Combinación de ambas fuentes en un modelo unificado optimizado para consultas analíticas.
- **Alcance** — Solo se trabaja con el dataset más reciente; no se requiere historización.
- **Documentación** — Documentación clara del modelo de datos para stakeholders y equipos de analítica.

### Data Analysis — BI & Reporting

**Objetivo:** Desarrollar analítica SQL para obtener insights detallados sobre:

- Comportamiento de clientes
- Rendimiento de productos
- Tendencias de ventas

Consulta `docs/requirements.md` para más detalles.

---

## 📂 Estructura del repositorio

```
data-warehouse-project/
│
├── datasets/                       # Datasets raw del proyecto (ERP y CRM)
│
├── docs/                           # Documentación y arquitectura
│   ├── etl.drawio                  # Técnicas y métodos ETL
│   ├── data_architecture.drawio    # Arquitectura del proyecto
│   ├── data_catalog.md             # Catálogo de datasets con descripciones y metadatos
│   ├── data_flow.drawio            # Diagrama de flujo de datos
│   ├── data_models.drawio          # Modelos de datos (esquema estrella)
│   └── naming-conventions.md      # Guía de nomenclatura para tablas, columnas y archivos
│
├── scripts/                        # Scripts SQL para ETL y transformaciones
│   ├── bronze/                     # Extracción y carga de datos raw
│   ├── silver/                     # Limpieza y transformación
│   └── gold/                       # Creación de modelos analíticos
│
├── tests/                          # Scripts de prueba y calidad
│
├── README.md
├── LICENSE
├── .gitignore
└── requirements.txt
```



---

## 🤝 Contacto

Conéctate en YouTube · LinkedIn · Newsletter

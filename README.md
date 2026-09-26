# Auditoría Operativa y Geo-Marketing Farmacéutico 

## Contexto de Negocio
Este proyecto de Business Intelligence desarrolla un cuadro de mando analítico para evaluar la rentabilidad real y el impacto sociodemográfico en una red de puntos de venta farmacéuticos (mercado OTC). El objetivo es superar el análisis clásico de "volumen de facturación" para identificar qué variables (renta per cápita, envejecimiento municipal, tipología de producto) son los verdaderos motores del margen de beneficio.

## Arquitectura de Datos y Metodología
El modelo de datos se ha construido bajo un esquema en estrella optimizado para el motor analítico tabular:
*   **Fact_Ventas:** Tabla de hechos con granularidad a nivel transaccional.
*   **Dimensiones:** `Dim_Farmacia`, `Dim_Producto`, `Dim_Tiempo` y `Dim_Geografia`.
*   **ETL (Power Query):** Integración de microdatos sociodemográficos (fuente: INE), normalización de escalas (resolución de conflictos de truncamiento decimal en variables de renta) y perfilado de datos.
*   **Cálculos (DAX):** Desarrollo de medidas dinámicas para el control de Ticket Medio, % Margen Operativo y Cuota de Mercado.

## Dashboard UI/UX
El diseño visual se ha estructurado bajo principios de carga cognitiva reducida:
1.  **Visión Estratégica:** KPIs macroeconómicos y tendencias de facturación vs. rentabilidad.
2.  **Geo-Marketing:** Correlación estadística (dispersión) entre poder adquisitivo, edad media poblacional y volumen de ventas.
3.  **Rendimiento de la Red:** Matriz de auditoría para el aislamiento de referencias que destruyen margen operativo y análisis causal jerárquico.

<img width="596" height="330" alt="01_Vision_Estrategica" src="https://github.com/user-attachments/assets/845b2129-39e0-4039-b25a-525df24951e8" />
<img width="601" height="332" alt="02_GeoMarketing" src="https://github.com/user-attachments/assets/c8333922-963b-4f0e-9ddb-9f1e839ce6ec" />
<img width="608" height="329" alt="03_Rendimiento_Red" src="https://github.com/user-attachments/assets/7567987a-5fd6-4284-8125-38f039a09296" />




## Insights Clave Detectados
*   **[Insight 1]:** *Ejemplo: La correlación entre la renta per cápita y el ticket medio demuestra que los municipios del cuartil superior generan un 22% más de margen bruto.*
*   **[Insight 2]:** *Ejemplo: El análisis de dispersión reveló 3 farmacias con alta facturación pero margen negativo debido a la sobredispensación de la categoría X.*

## Stack Tecnológico
`Power BI` | `DAX` | `Power Query (M)` | `Modelado Dimensional`

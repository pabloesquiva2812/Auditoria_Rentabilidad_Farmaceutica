-- 1. Dimensión Geografía (Datos INE)
CREATE TABLE Dim_Geografia (
    ID_Municipio VARCHAR(10) PRIMARY KEY,
    Nombre_Municipio VARCHAR(100),
    Renta_Media_Persona NUMERIC(10, 2),
    Edad_Media NUMERIC(5, 2),
    Pct_Mayores_65 NUMERIC(5, 2)
);

-- 2. Dimensión Farmacia (Distribución CGCOF)
CREATE TABLE Dim_Farmacia (
    ID_Farmacia SERIAL PRIMARY KEY,
    ID_Municipio VARCHAR(10) REFERENCES Dim_Geografia(ID_Municipio),
    Ubicacion VARCHAR(20) -- 'Capital' o 'Resto'
);

-- 3. Dimensión Producto (Datos AEMPS filtrados por sw_receta = 0)
CREATE TABLE Dim_Producto (
    Cod_Nacional VARCHAR(10) PRIMARY KEY,
    Nombre_Comercial VARCHAR(150),
    Laboratorio VARCHAR(100),
    Cod_ATC VARCHAR(10),
    Categoria_Terapeutica VARCHAR(150)
);

-- 4. Dimensión Tiempo
CREATE TABLE Dim_Tiempo (
    ID_Fecha DATE PRIMARY KEY,
    Anio INT,
    Mes INT,
    Trimestre INT,
    Dia_Semana INT
);

-- 5. Tabla de Hechos (Transacciones parametrizadas base IQVIA)
CREATE TABLE Fact_Ventas (
    ID_Ticket SERIAL PRIMARY KEY,
    ID_Fecha DATE REFERENCES Dim_Tiempo(ID_Fecha),
    ID_Farmacia INT REFERENCES Dim_Farmacia(ID_Farmacia),
    Cod_Nacional VARCHAR(10) REFERENCES Dim_Producto(Cod_Nacional),
    Unidades INT,
    Precio_Venta NUMERIC(10, 2),
    Coste NUMERIC(10, 2)
);

-- Capa Staging para AEMPS
CREATE TABLE stg_aemps (
    cod_nacional VARCHAR(50),
    presentacion VARCHAR(255),
    laboratorio VARCHAR(255),
    cod_atc VARCHAR(50),
    estado VARCHAR(50),
    comercializado VARCHAR(50),
    observaciones VARCHAR(255)
);

-- Capa Staging para INE (Renta y Demografía)
CREATE TABLE stg_ine (
    municipios VARCHAR(255),
    indicador VARCHAR(255),
    periodo VARCHAR(10),
    total VARCHAR(50)
);

INSERT INTO Dim_Producto (Cod_Nacional, Nombre_Comercial, Laboratorio, Cod_ATC, Categoria_Terapeutica)
SELECT 
    TRIM(cod_nacional), 
    TRIM(presentacion), 
    TRIM(laboratorio), 
    TRIM(cod_atc),
    'Consumer Health / OTC' AS Categoria_Terapeutica
FROM 
    stg_aemps
WHERE 
    UPPER(estado) = 'AUTORIZADO' 
    AND UPPER(comercializado) = 'SI' 
    AND UPPER(observaciones) = 'SIN RECETA';

SELECT * FROM stg_aemps sa ;
SELECT * FROM Dim_Producto;

DROP TABLE stg_aemps;

CREATE TABLE stg_aemps (
    cod_nacional VARCHAR(50),
    presentacion VARCHAR(255),
    laboratorio VARCHAR(255),
    cod_atc VARCHAR(50),
    estado VARCHAR(50),
    comercializado VARCHAR(50),
    observaciones VARCHAR(255)
);
SELECT * FROM stg_aemps;

INSERT INTO Dim_Producto (Cod_Nacional, Nombre_Comercial, Laboratorio, Cod_ATC, Categoria_Terapeutica)
SELECT 
    TRIM(cod_nacional), 
    TRIM(presentacion), 
    TRIM(laboratorio), 
    TRIM(cod_atc),
    'Consumer Health / OTC' AS Categoria_Terapeutica
FROM 
    stg_aemps
WHERE 
    UPPER(estado) = 'AUTORIZADO' 
    AND UPPER(comercializado) = 'SI' 
    AND UPPER(observaciones) = 'SIN RECETA';

SELECT * FROM Dim_Producto dp;
SELECT * FROM stg_ine si; 
DROP TABLE stg_ine;

CREATE TABLE stg_ine (
    municipios VARCHAR(255),
    indicador VARCHAR(255),
    periodo VARCHAR(10),
    total VARCHAR(50)
);

INSERT INTO Dim_Geografia (ID_Municipio, Nombre_Municipio, Renta_Media_Persona, Edad_Media, Pct_Mayores_65)
SELECT 
    SUBSTR(TRIM(municipios), 1, 5) AS ID_Municipio,
    TRIM(SUBSTR(TRIM(municipios), 7)) AS Nombre_Municipio,
    MAX(CASE WHEN indicador LIKE '%Renta neta media por persona%' 
             THEN CAST(REPLACE(total, ',', '.') AS NUMERIC) END) AS Renta_Media_Persona,
    MAX(CASE WHEN indicador LIKE '%Edad media%' 
             THEN CAST(REPLACE(total, ',', '.') AS NUMERIC) END) AS Edad_Media,
    MAX(CASE WHEN indicador LIKE '%Porcentaje%' AND indicador LIKE '%65%' 
             THEN CAST(REPLACE(total, ',', '.') AS NUMERIC) END) AS Pct_Mayores_65
FROM 
    stg_ine
WHERE 
    TRIM(periodo) = '2023'
GROUP BY 
    SUBSTR(TRIM(municipios), 1, 5),
    TRIM(SUBSTR(TRIM(municipios), 7));

SELECT * FROM Dim_Geografia dg; 

WITH RECURSIVE fechas(d) AS (
    SELECT '2023-01-01'
    UNION ALL
    SELECT date(d, '+1 day')
    FROM fechas
    WHERE d < '2023-12-31'
)
INSERT INTO Dim_Tiempo (ID_Fecha, Anio, Mes, Trimestre, Dia_Semana)
SELECT 
    d, 
    CAST(strftime('%Y', d) AS INTEGER),
    CAST(strftime('%m', d) AS INTEGER),
    CASE 
        WHEN CAST(strftime('%m', d) AS INTEGER) IN (1, 2, 3) THEN 1
        WHEN CAST(strftime('%m', d) AS INTEGER) IN (4, 5, 6) THEN 2
        WHEN CAST(strftime('%m', d) AS INTEGER) IN (7, 8, 9) THEN 3
        ELSE 4 
    END,
    CAST(strftime('%w', d) AS INTEGER) -- 0 es Domingo, 6 es Sábado
FROM fechas;

SELECT * FROM Dim_Tiempo dt; 

WITH RECURSIVE sec_farmacias(n) AS (
    SELECT 1 
    UNION ALL 
    SELECT n + 1 FROM sec_farmacias WHERE n < 22273
)
INSERT INTO Dim_Farmacia (ID_Farmacia, ID_Municipio, Ubicacion)
SELECT 
    n,
    -- Asignación aleatoria de un municipio existente en tu tabla geográfica
    (SELECT ID_Municipio FROM Dim_Geografia ORDER BY RANDOM() LIMIT 1),
    -- Distribución clínica del informe CGCOF: 35.5% Capital, 64.5% Resto
    CASE 
        WHEN n <= (22273 * 0.355) THEN 'Capital' 
        ELSE 'Resto' 
    END
FROM sec_farmacias;

SELECT * FROM Dim_Farmacia df;

UPDATE Dim_Farmacia
SET ID_Municipio = (
    SELECT ID_Municipio 
    FROM Dim_Geografia 
    WHERE Dim_Farmacia.ID_Farmacia IS NOT NULL -- Enlace técnico que rompe el caché del optimizador
    ORDER BY RANDOM() 
    LIMIT 1
);

SELECT COUNT(DISTINCT ID_Municipio) AS Municipios_Distintos FROM Dim_Farmacia;

WITH RECURSIVE sec_tickets(n) AS (
    SELECT 1 
    UNION ALL 
    SELECT n + 1 FROM sec_tickets WHERE n < 100000
)
INSERT INTO Fact_Ventas (ID_Fecha, ID_Farmacia, Cod_Nacional, Unidades, Precio_Venta, Coste)
SELECT 
    (SELECT ID_Fecha FROM Dim_Tiempo WHERE sec_tickets.n IS NOT NULL ORDER BY RANDOM() LIMIT 1),
    (SELECT ID_Farmacia FROM Dim_Farmacia WHERE sec_tickets.n IS NOT NULL ORDER BY RANDOM() LIMIT 1),
    (SELECT Cod_Nacional FROM Dim_Producto WHERE sec_tickets.n IS NOT NULL ORDER BY RANDOM() LIMIT 1),
    CASE 
        WHEN (ABS(RANDOM()) % 100) < 60 THEN 1
        WHEN (ABS(RANDOM()) % 100) < 85 THEN 2
        WHEN (ABS(RANDOM()) % 100) < 95 THEN 3
        ELSE 4
    END,
    ROUND(5.00 + (ABS(RANDOM()) % 3500) / 100.0, 2),
    0.00
FROM sec_tickets;

UPDATE Fact_Ventas
SET Coste = ROUND(Precio_Venta * (0.65 + (ABS(RANDOM()) % 10) / 100.0), 2);

SELECT * FROM Fact_Ventas fv; 

DELETE FROM Fact_Ventas;

WITH RECURSIVE sec_tickets(n) AS (
    SELECT 1 
    UNION ALL 
    SELECT n + 1 FROM sec_tickets WHERE n < 100000
)
INSERT INTO Fact_Ventas (ID_Ticket, ID_Fecha, ID_Farmacia, Cod_Nacional, Unidades, Precio_Venta, Coste)
SELECT 
    n, -- Inyectamos el iterador directamente como Primary Key
    (SELECT ID_Fecha FROM Dim_Tiempo WHERE sec_tickets.n IS NOT NULL ORDER BY RANDOM() LIMIT 1),
    (SELECT ID_Farmacia FROM Dim_Farmacia WHERE sec_tickets.n IS NOT NULL ORDER BY RANDOM() LIMIT 1),
    (SELECT Cod_Nacional FROM Dim_Producto WHERE sec_tickets.n IS NOT NULL ORDER BY RANDOM() LIMIT 1),
    CASE 
        WHEN (ABS(RANDOM()) % 100) < 60 THEN 1
        WHEN (ABS(RANDOM()) % 100) < 85 THEN 2
        WHEN (ABS(RANDOM()) % 100) < 95 THEN 3
        ELSE 4
    END,
    ROUND(5.00 + (ABS(RANDOM()) % 3500) / 100.0, 2),
    0.00
FROM sec_tickets;

UPDATE Fact_Ventas
SET Coste = ROUND(Precio_Venta * (0.65 + (ABS(RANDOM()) % 10) / 100.0), 2);


CREATE DATABASE IF NOT EXISTS AgroSmart CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE AgroSmart;

-- ==========================================================
-- A. DOMINIO GEOGRÁFICO (5 TABLAS)
-- ==========================================================
CREATE TABLE estados (
    id_estado INT AUTO_INCREMENT PRIMARY KEY,
    clave_siap SMALLINT UNSIGNED NOT NULL UNIQUE,
    nombre VARCHAR(60) NOT NULL
);

CREATE TABLE ddr (
    id_ddr INT AUTO_INCREMENT PRIMARY KEY,
    id_estado INT NOT NULL,
    clave_siap SMALLINT UNSIGNED NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    UNIQUE KEY uk_estado_ddr (id_estado, clave_siap),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

CREATE TABLE cader (
    id_cader INT AUTO_INCREMENT PRIMARY KEY,
    id_ddr INT NOT NULL,
    clave_siap SMALLINT UNSIGNED NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    UNIQUE KEY uk_ddr_cader (id_ddr, clave_siap),
    FOREIGN KEY (id_ddr) REFERENCES ddr(id_ddr)
);

CREATE TABLE municipios (
    id_municipio INT AUTO_INCREMENT PRIMARY KEY,
    id_estado INT NOT NULL,
    clave_siap SMALLINT UNSIGNED NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    altitud_msnm INT,
    UNIQUE KEY uk_estado_mun (id_estado, clave_siap),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

CREATE TABLE municipio_cader (
    id_municipio_cader INT AUTO_INCREMENT PRIMARY KEY,
    id_municipio INT NOT NULL,
    id_cader INT NOT NULL,
    UNIQUE KEY uk_mun_cader (id_municipio, id_cader),
    FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio),
    FOREIGN KEY (id_cader) REFERENCES cader(id_cader)
);

-- ==========================================================
-- B. DOMINIO AGRÍCOLA E HISTÓRICO DEL CSV (6 TABLAS)
-- ==========================================================
CREATE TABLE categorias_cultivo (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE cultivos (
    id_cultivo INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    clave_siap INT UNSIGNED NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    nombre_cientifico VARCHAR(120),
    dias_cosecha_prom INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES categorias_cultivo(id_categoria)
);

CREATE TABLE ciclos_productivos (
    id_ciclo INT AUTO_INCREMENT PRIMARY KEY,
    clave_siap TINYINT UNSIGNED NOT NULL UNIQUE,
    nombre VARCHAR(40) NOT NULL
);

CREATE TABLE modalidades_produccion (
    id_modalidad INT AUTO_INCREMENT PRIMARY KEY,
    clave_siap TINYINT UNSIGNED NOT NULL UNIQUE,
    nombre VARCHAR(30) NOT NULL
);

CREATE TABLE unidades_medida (
    id_unidad INT AUTO_INCREMENT PRIMARY KEY,
    clave_siap TINYINT UNSIGNED NOT NULL UNIQUE,
    nombre VARCHAR(30) NOT NULL,
    simbolo VARCHAR(15)
);

CREATE TABLE produccion_agricola_historica (
    id_produccion BIGINT AUTO_INCREMENT PRIMARY KEY,
    anio SMALLINT UNSIGNED NOT NULL,
    id_municipio INT NOT NULL,
    id_cader INT NOT NULL,
    id_cultivo INT NOT NULL,
    id_ciclo INT NOT NULL,
    id_modalidad INT NOT NULL,
    id_unidad INT NOT NULL,
    superficie_sembrada DECIMAL(12,2) NOT NULL CHECK (superficie_sembrada >= 0),
    superficie_cosechada DECIMAL(12,2) NOT NULL CHECK (superficie_cosechada >= 0),
    superficie_siniestrada DECIMAL(12,2) NOT NULL CHECK (superficie_siniestrada >= 0),
    volumen_produccion DECIMAL(14,2) NOT NULL CHECK (volumen_produccion >= 0),
    rendimiento DECIMAL(12,2) NULL,
    precio_medio_rural DECIMAL(12,2) NULL,
    valor_produccion DECIMAL(16,2) NOT NULL DEFAULT 0.00,
    UNIQUE KEY uk_hecho_agricola (anio, id_municipio, id_cader, id_cultivo, id_ciclo, id_modalidad, id_unidad),
    FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio),
    FOREIGN KEY (id_cader) REFERENCES cader(id_cader),
    FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo),
    FOREIGN KEY (id_ciclo) REFERENCES ciclos_productivos(id_ciclo),
    FOREIGN KEY (id_modalidad) REFERENCES modalidades_produccion(id_modalidad),
    FOREIGN KEY (id_unidad) REFERENCES unidades_medida(id_unidad)
);

-- ==========================================================
-- C. DOMINIO CLIMÁTICO Y AMBIENTAL (3 TABLAS)
-- ==========================================================
CREATE TABLE tipos_suelo (
    id_tipo_suelo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
);

CREATE TABLE regiones_climaticas (
    id_region_climatica INT AUTO_INCREMENT PRIMARY KEY,
    id_municipio INT NOT NULL UNIQUE,
    id_tipo_suelo INT NOT NULL,
    clima_predominante VARCHAR(80) NOT NULL,
    temp_min_prom DECIMAL(4,1) NOT NULL,
    temp_max_prom DECIMAL(4,1) NOT NULL,
    precipitacion_anual_mm DECIMAL(6,1) NOT NULL,
    humedad_relativa_prom DECIMAL(4,1) NOT NULL,
    disponibilidad_agua ENUM('Alta', 'Media', 'Baja') NOT NULL,
    FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio),
    FOREIGN KEY (id_tipo_suelo) REFERENCES tipos_suelo(id_tipo_suelo)
);

CREATE TABLE requerimientos_cultivo (
    id_requerimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT NOT NULL UNIQUE,
    id_tipo_suelo_ideal INT NOT NULL,
    temp_min_tolerada DECIMAL(4,1) NOT NULL,
    temp_max_tolerada DECIMAL(4,1) NOT NULL,
    requerimiento_hidrico ENUM('Alto', 'Medio', 'Bajo') NOT NULL,
    rendimiento_esperado_ton_ha DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo),
    FOREIGN KEY (id_tipo_suelo_ideal) REFERENCES tipos_suelo(id_tipo_suelo)
);

-- ==========================================================
-- D. DOMINIO DE TEMPORADAS (1 TABLA)
-- ==========================================================
CREATE TABLE calendario_siembra_regional (
    id_calendario INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT NOT NULL,
    id_estado INT NOT NULL,
    mes_inicio_siembra TINYINT NOT NULL CHECK (mes_inicio_siembra BETWEEN 1 AND 12),
    mes_fin_siembra TINYINT NOT NULL CHECK (mes_fin_siembra BETWEEN 1 AND 12),
    mes_cosecha_estimado TINYINT NOT NULL CHECK (mes_cosecha_estimado BETWEEN 1 AND 12),
    notas_agronomicas VARCHAR(255),
    FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo),
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- ==========================================================
-- E. DOMINIO ECONÓMICO Y RENTABILIDAD (4 TABLAS)
-- ==========================================================
CREATE TABLE categorias_insumo (
    id_categoria_insumo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE insumos_agricolas (
    id_insumo INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria_insumo INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    unidad_medida VARCHAR(30) NOT NULL,
    costo_unitario_mxn DECIMAL(10,2) NOT NULL CHECK (costo_unitario_mxn >= 0),
    fecha_actualizacion DATE NOT NULL,
    FOREIGN KEY (id_categoria_insumo) REFERENCES categorias_insumo(id_categoria_insumo)
);

CREATE TABLE estructura_costos_cultivo (
    id_estructura INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT NOT NULL,
    id_insumo INT NOT NULL,
    cantidad_por_hectarea DECIMAL(10,2) NOT NULL CHECK (cantidad_por_hectarea > 0),
    FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo),
    FOREIGN KEY (id_insumo) REFERENCES insumos_agricolas(id_insumo)
);

CREATE TABLE simulaciones_rentabilidad (
    id_simulacion INT AUTO_INCREMENT PRIMARY KEY,
    nombre_productor VARCHAR(100) NOT NULL,
    id_municipio INT NOT NULL,
    id_cultivo INT NOT NULL,
    hectareas DECIMAL(8,2) NOT NULL CHECK (hectareas > 0),
    fecha_siembra DATE NOT NULL,
    costo_total_estimado DECIMAL(14,2) NOT NULL,
    ingreso_estimado DECIMAL(14,2) NOT NULL,
    ganancia_estimada DECIMAL(14,2) NOT NULL,
    rentabilidad_porcentual DECIMAL(8,2) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio),
    FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo)
);

-- ==========================================================
-- F. DOMINIO COMERCIAL Y MERCADOS (3 TABLAS)
-- ==========================================================
CREATE TABLE tipos_establecimiento (
    id_tipo_establecimiento INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE mercados (
    id_mercado INT AUTO_INCREMENT PRIMARY KEY,
    id_tipo_establecimiento INT NOT NULL,
    id_municipio INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    canal_venta ENUM('Mayoreo', 'Medio Mayoreo', 'Menudeo') NOT NULL,
    FOREIGN KEY (id_tipo_establecimiento) REFERENCES tipos_establecimiento(id_tipo_establecimiento),
    FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio)
);

CREATE TABLE precios_comerciales (
    id_precio_comercial INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT NOT NULL,
    id_mercado INT NOT NULL,
    precio_kg_mxn DECIMAL(10,2) NOT NULL CHECK (precio_kg_mxn > 0),
    fecha_consulta DATE NOT NULL,
    FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo),
    FOREIGN KEY (id_mercado) REFERENCES mercados(id_mercado)
);

-- ==========================================================
-- DATOS DE PRUEBA (ZONA CDMX Y ESTADO DE MÉXICO)
-- ==========================================================
INSERT INTO estados (clave_siap, nombre) VALUES (9, 'Ciudad de México'), (15, 'Estado de México');

INSERT INTO ddr (id_estado, clave_siap, nombre) VALUES 
(1, 1, 'Distrito Ciudad de México'), 
(2, 11, 'Texcoco');

INSERT INTO cader (id_ddr, clave_siap, nombre) VALUES 
(1, 1, 'CADER Xochimilco'), 
(1, 2, 'CADER Milpa Alta'),
(2, 1, 'CADER Texcoco');

INSERT INTO municipios (id_estado, clave_siap, nombre, altitud_msnm) VALUES 
(1, 13, 'Xochimilco', 2240),
(1, 9, 'Milpa Alta', 2420),
(1, 11, 'Tláhuac', 2245),
(2, 99, 'Texcoco', 2250);

INSERT INTO municipio_cader (id_municipio, id_cader) VALUES (1, 1), (2, 2), (3, 1), (4, 3);

INSERT INTO categorias_cultivo (nombre) VALUES ('Hortalizas'), ('Cactáceas'), ('Granos y Cereales');

INSERT INTO cultivos (id_categoria, clave_siap, nombre, nombre_cientifico, dias_cosecha_prom) VALUES
(1, 6190000, 'Espinaca', 'Spinacia oleracea', 45),
(1, 7420000, 'Lechuga', 'Lactuca sativa', 65),
(2, 8110000, 'Nopalitos', 'Opuntia ficus-indica', 90),
(3, 7500000, 'Maíz grano', 'Zea mays', 150);

INSERT INTO ciclos_productivos (clave_siap, nombre) VALUES (1, 'Otoño-Invierno'), (2, 'Primavera-Verano'), (3, 'Perennes');
INSERT INTO modalidades_produccion (clave_siap, nombre) VALUES (1, 'Riego'), (2, 'Temporal');
INSERT INTO unidades_medida (clave_siap, nombre, simbolo) VALUES (1, 'Tonelada', 'ton');

INSERT INTO produccion_agricola_historica (anio, id_municipio, id_cader, id_cultivo, id_ciclo, id_modalidad, id_unidad, superficie_sembrada, superficie_cosechada, superficie_siniestrada, volumen_produccion, rendimiento, precio_medio_rural, valor_produccion) VALUES
(2025, 1, 1, 1, 1, 1, 1, 120.00, 120.00, 0.00, 1800.00, 15.00, 9500.00, 17100000.00),
(2025, 2, 2, 3, 3, 2, 1, 2850.00, 2850.00, 0.00, 213750.00, 75.00, 6200.00, 1325250000.00);

INSERT INTO tipos_suelo (nombre, descripcion) VALUES 
('Histosol (Chinampa)', 'Suelo lacustre fértil con alta humedad'),
('Andosol', 'Suelo volcánico de montaña, buen drenaje'),
('Feozem', 'Suelo rico en materia orgánica para valles');

INSERT INTO regiones_climaticas (id_municipio, id_tipo_suelo, clima_predominante, temp_min_prom, temp_max_prom, precipitacion_anual_mm, humedad_relativa_prom, disponibilidad_agua) VALUES
(1, 1, 'Templado subhúmedo', 6.5, 22.5, 750.0, 65.0, 'Alta'),
(2, 2, 'Templado frío de montaña', 4.5, 20.0, 820.0, 60.0, 'Media'),
(3, 1, 'Templado subhúmedo', 6.8, 23.0, 710.0, 62.0, 'Alta'),
(4, 3, 'Templado semiseco', 5.8, 24.0, 640.0, 55.0, 'Media');

INSERT INTO requerimientos_cultivo (id_cultivo, id_tipo_suelo_ideal, temp_min_tolerada, temp_max_tolerada, requerimiento_hidrico, rendimiento_esperado_ton_ha) VALUES
(1, 1, 4.0, 24.0, 'Alto', 16.00),
(2, 1, 5.0, 25.0, 'Alto', 22.00),
(3, 2, 3.0, 32.0, 'Bajo', 70.00),
(4, 3, 8.0, 30.0, 'Medio', 4.50);

INSERT INTO calendario_siembra_regional (id_cultivo, id_estado, mes_inicio_siembra, mes_fin_siembra, mes_cosecha_estimado, notas_agronomicas) VALUES
(1, 1, 9, 2, 1, 'Ideal para temporada fría de otoño-invierno en chinampas.'),
(2, 1, 8, 3, 12, 'Requiere riego constante; tolera heladas ligeras.'),
(3, 1, 1, 12, 4, 'Producción perenne en Milpa Alta; poda sanitaria recomendada.'),
(4, 2, 4, 6, 10, 'Siembra de primavera-verano aprovechando lluvias.');

INSERT INTO categorias_insumo (nombre) VALUES ('Semillas'), ('Fertilizantes y Abonos'), ('Mano de Obra'), ('Agua y Riego');

INSERT INTO insumos_agricolas (id_categoria_insumo, nombre, unidad_medida, costo_unitario_mxn, fecha_actualizacion) VALUES
(1, 'Semilla certificada de hortaliza', 'kg', 480.00, '2026-11-01'),
(2, 'Composta orgánica estabilizada', 'tonelada', 1200.00, '2026-11-01'),
(3, 'Jornal agrícola regional', 'jornal', 350.00, '2026-11-01'),
(4, 'Cuota de riego / bombeo', 'ciclo_ha', 2500.00, '2026-11-01');

INSERT INTO estructura_costos_cultivo (id_cultivo, id_insumo, cantidad_por_hectarea) VALUES
(1, 1, 12.00), (1, 2, 10.00), (1, 3, 45.00), (1, 4, 1.00),
(2, 1, 3.00),  (2, 2, 12.00), (2, 3, 55.00), (2, 4, 1.00),
(3, 2, 15.00), (3, 3, 60.00),
(4, 1, 25.00), (4, 2, 5.00),  (4, 3, 30.00);

INSERT INTO tipos_establecimiento (nombre) VALUES ('Central de Abasto'), ('Mercado Público Mayorista');

INSERT INTO mercados (id_tipo_establecimiento, id_municipio, nombre, canal_venta) VALUES
(1, 1, 'Central de Abasto CDMX (CEDA - Sector Hortalizas)', 'Mayoreo'),
(2, 2, 'Centro de Acopio Nopal-Verdura Milpa Alta', 'Mayoreo'),
(1, 4, 'Mercado Regional de Texcoco', 'Medio Mayoreo');

INSERT INTO precios_comerciales (id_cultivo, id_mercado, precio_kg_mxn, fecha_consulta) VALUES
(1, 1, 18.50, '2026-11-18'),
(2, 1, 14.00, '2026-11-18'),
(3, 2, 9.50, '2026-11-18'),
(4, 3, 7.80, '2026-11-18');

-- Registro inicial para que la tabla CRUD tenga datos al abrir
INSERT INTO simulaciones_rentabilidad (nombre_productor, id_municipio, id_cultivo, hectareas, fecha_siembra, costo_total_estimado, ingreso_estimado, ganancia_estimada, rentabilidad_porcentual) VALUES
('Cooperativa Chinampera Atlapulco', 1, 1, 1.50, '2026-11-22', 54015.00, 444000.00, 389985.00, 721.99);
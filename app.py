from flask import Flask, render_template, request, redirect, url_for
import mysql.connector

app = Flask(__name__)

# Ajusta 'password' si tu MySQL tiene contraseña
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '112107',
    'database': 'AgroSmart'
}

def get_db():
    return mysql.connector.connect(**db_config)

@app.route('/', methods=['GET', 'POST'])
def index():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    # Catálogos para los selectores
    cursor.execute("""
        SELECT m.id_municipio, m.nombre, e.nombre AS estado, rc.clima_predominante, 
               rc.temp_min_prom, rc.temp_max_prom, ts.nombre AS suelo
        FROM municipios m
        JOIN estados e ON m.id_estado = e.id_estado
        JOIN regiones_climaticas rc ON m.id_municipio = rc.id_municipio
        JOIN tipos_suelo ts ON rc.id_tipo_suelo = ts.id_tipo_suelo
    """)
    municipios = cursor.fetchall()

    cursor.execute("SELECT id_cultivo, nombre FROM cultivos")
    cultivos = cursor.fetchall()

    recomendaciones = []
    info_zona = None

    # MOTOR DE RECOMENDACIÓN AGRONÓMICA Y RENTABILIDAD
    if request.method == 'POST' and 'consultar' in request.form:
        id_municipio = int(request.form['id_municipio'])
        mes = int(request.form['mes'])
        hectareas = float(request.form['hectareas'])

        cursor.execute("""
            SELECT m.id_municipio, m.nombre, e.nombre AS estado, rc.clima_predominante,
                   rc.temp_min_prom, rc.temp_max_prom, rc.disponibilidad_agua, ts.nombre AS suelo
            FROM municipios m
            JOIN estados e ON m.id_estado = e.id_estado
            JOIN regiones_climaticas rc ON m.id_municipio = rc.id_municipio
            JOIN tipos_suelo ts ON rc.id_tipo_suelo = ts.id_tipo_suelo
            WHERE m.id_municipio = %s
        """, (id_municipio,))
        info_zona = cursor.fetchone()

        query = """
            SELECT 
                c.id_cultivo,
                c.nombre AS cultivo,
                cat.nombre AS categoria,
                c.dias_cosecha_prom,
                req.rendimiento_esperado_ton_ha,
                cal.notas_agronomicas,
                COALESCE((SELECT SUM(ecc.cantidad_por_hectarea * ia.costo_unitario_mxn)
                          FROM estructura_costos_cultivo ecc
                          JOIN insumos_agricolas ia ON ecc.id_insumo = ia.id_insumo
                          WHERE ecc.id_cultivo = c.id_cultivo), 25000) AS costo_por_ha,
                COALESCE((SELECT MAX(pc.precio_kg_mxn)
                          FROM precios_comerciales pc
                          WHERE pc.id_cultivo = c.id_cultivo), 12.00) AS mejor_precio_kg,
                COALESCE((SELECT mk.nombre
                          FROM precios_comerciales pc
                          JOIN mercados mk ON pc.id_mercado = mk.id_mercado
                          WHERE pc.id_cultivo = c.id_cultivo
                          ORDER BY pc.precio_kg_mxn DESC LIMIT 1), 'Mercado Local') AS mercado_destino
            FROM cultivos c
            JOIN categorias_cultivo cat ON c.id_categoria = cat.id_categoria
            JOIN requerimientos_cultivo req ON c.id_cultivo = req.id_cultivo
            JOIN municipios m ON m.id_municipio = %s
            JOIN regiones_climaticas rc ON m.id_municipio = rc.id_municipio
            LEFT JOIN calendario_siembra_regional cal ON c.id_cultivo = cal.id_cultivo AND cal.id_estado = m.id_estado
            WHERE rc.temp_min_prom >= req.temp_min_tolerada
              AND rc.temp_max_prom <= req.temp_max_tolerada
        """
        cursor.execute(query, (id_municipio,))
        filas = cursor.fetchall()

        for f in filas:
            costo_total = round(float(f['costo_por_ha']) * hectareas, 2)
            toneladas_totales = float(f['rendimiento_esperado_ton_ha']) * hectareas
            ingreso_total = round((toneladas_totales * 1000) * float(f['mejor_precio_kg']), 2)
            ganancia = round(ingreso_total - costo_total, 2)
            rentabilidad = round((ganancia / costo_total) * 100, 2) if costo_total > 0 else 0

            f['hectareas'] = hectareas
            f['id_municipio'] = id_municipio
            f['costo_total'] = costo_total
            f['ingreso_total'] = ingreso_total
            f['ganancia'] = ganancia
            f['rentabilidad'] = rentabilidad
            recomendaciones.append(f)

    # READ: Consultar simulaciones guardadas
    cursor.execute("""
        SELECT s.id_simulacion, s.nombre_productor, m.nombre AS municipio, c.nombre AS cultivo,
               s.hectareas, s.fecha_siembra, s.costo_total_estimado, s.ingreso_estimado,
               s.ganancia_estimada, s.rentabilidad_porcentual
        FROM simulaciones_rentabilidad s
        JOIN municipios m ON s.id_municipio = m.id_municipio
        JOIN cultivos c ON s.id_cultivo = c.id_cultivo
        ORDER BY s.id_simulacion DESC
    """)
    simulaciones = cursor.fetchall()

    # Consultar tabla de precios comerciales
    cursor.execute("""
        SELECT c.nombre AS cultivo, mk.nombre AS mercado, mk.canal_venta, 
               pc.precio_kg_mxn, pc.fecha_consulta
        FROM precios_comerciales pc
        JOIN cultivos c ON pc.id_cultivo = c.id_cultivo
        JOIN mercados mk ON pc.id_mercado = mk.id_mercado
    """)
    precios = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('index.html', municipios=municipios, cultivos=cultivos,
                           recomendaciones=recomendaciones, info_zona=info_zona,
                           simulaciones=simulaciones, precios=precios)

# CREATE
@app.route('/crear', methods=['POST'])
def crear():
    productor = request.form['nombre_productor']
    id_municipio = int(request.form['id_municipio'])
    id_cultivo = int(request.form['id_cultivo'])
    hectareas = float(request.form['hectareas'])
    fecha_siembra = request.form['fecha_siembra']
    costo = float(request.form['costo_total_estimado'])
    ingreso = float(request.form['ingreso_estimado'])
    ganancia = round(ingreso - costo, 2)
    rentabilidad = round((ganancia / costo) * 100, 2) if costo > 0 else 0

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO simulaciones_rentabilidad 
        (nombre_productor, id_municipio, id_cultivo, hectareas, fecha_siembra, 
         costo_total_estimado, ingreso_estimado, ganancia_estimada, rentabilidad_porcentual)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (productor, id_municipio, id_cultivo, hectareas, fecha_siembra, costo, ingreso, ganancia, rentabilidad))
    conn.commit()
    cursor.close()
    conn.close()
    return redirect(url_for('index'))

# UPDATE
@app.route('/actualizar/<int:id_sim>', methods=['POST'])
def actualizar(id_sim):
    nuevas_ha = float(request.form['hectareas'])
    nueva_fecha = request.form['fecha_siembra']

    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT hectareas, costo_total_estimado, ingreso_estimado FROM simulaciones_rentabilidad WHERE id_simulacion = %s", (id_sim,))
    reg = cursor.fetchone()

    if reg and float(reg['hectareas']) > 0:
        factor = nuevas_ha / float(reg['hectareas'])
        nuevo_costo = round(float(reg['costo_total_estimado']) * factor, 2)
        nuevo_ingreso = round(float(reg['ingreso_estimado']) * factor, 2)
        nueva_ganancia = round(nuevo_ingreso - nuevo_costo, 2)
        nueva_rent = round((nueva_ganancia / nuevo_costo) * 100, 2) if nuevo_costo > 0 else 0

        cursor.execute("""
            UPDATE simulaciones_rentabilidad
            SET hectareas = %s, fecha_siembra = %s, costo_total_estimado = %s,
                ingreso_estimado = %s, ganancia_estimada = %s, rentabilidad_porcentual = %s
            WHERE id_simulacion = %s
        """, (nuevas_ha, nueva_fecha, nuevo_costo, nuevo_ingreso, nueva_ganancia, nueva_rent, id_sim))
        conn.commit()

    cursor.close()
    conn.close()
    return redirect(url_for('index'))

# DELETE
@app.route('/eliminar/<int:id_sim>', methods=['POST'])
def eliminar(id_sim):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM simulaciones_rentabilidad WHERE id_simulacion = %s", (id_sim,))
    conn.commit()
    cursor.close()
    conn.close()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)
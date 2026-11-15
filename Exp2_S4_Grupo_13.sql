/*
  DUOC UC - PRY2205 - Experiencia 2 - Semana 4
  Actividad formativa: Desarrollando JOINS en las tablas
  Caso de estudio: Conciertos Chile S.A.
  Autor(es): Nicolás Núñez - Constanza Parra
  Conexion: PRY2205_ACTIVIDAD_S4 (usuario PRY2205_S4)

  IMPORTANTE: Ejecutar antes los dos scripts oficiales de la Semana 4.
  Consultas para Oracle SQL Developer (F5); no modifica datos.
*/

-- =====================================================================
-- CASO 1: LISTADO DE TRABAJADORES
-- Trabajadores con sueldo entre $650.000 y $3.000.000.
-- Orden: ciudad descendente; sueldo base ascendente.
-- =====================================================================
SELECT
    UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)
        AS "Nombre Completo Trabajador",
    TO_CHAR(t.numrut, 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || t.dvrut AS "RUT Trabajador",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
    '$' || TO_CHAR(ROUND(t.sueldo_base), 'FM999G999G999G990',
                   'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo Base"
FROM trabajador t
INNER JOIN tipo_trabajador tt ON tt.id_categoria = t.id_categoria_t
INNER JOIN comuna_ciudad cc ON cc.id_ciudad = t.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC, t.sueldo_base ASC;

-- =====================================================================
-- CASO 2: LISTADO DE CAJEROS
-- Suma de tickets/comisiones por trabajador, solo si la venta total
-- supera $50.000. Cada ticket posee una comision asociada.
-- =====================================================================
SELECT
    TO_CHAR(t.numrut, 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(t.nombre || ' ' || t.appaterno) AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "Total Tickets",
    '$' || TO_CHAR(ROUND(SUM(tc.monto_ticket)), 'FM999G999G999G990',
                   'NLS_NUMERIC_CHARACTERS='',.''') AS "Total Vendido",
    '$' || TO_CHAR(ROUND(SUM(NVL(ct.valor_comision, 0))),
                   'FM999G999G999G990',
                   'NLS_NUMERIC_CHARACTERS='',.''') AS "Comisión Total",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
INNER JOIN tipo_trabajador tt ON tt.id_categoria = t.id_categoria_t
INNER JOIN comuna_ciudad cc ON cc.id_ciudad = t.id_ciudad
INNER JOIN tickets_concierto tc ON tc.numrut_t = t.numrut
LEFT JOIN comisiones_ticket ct ON ct.nro_ticket = tc.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno,
         tt.desc_categoria, cc.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;

-- =====================================================================
-- CASO 3: LISTADO DE BONIFICACIONES
-- Un registro por trabajador con estado civil vigente.
-- LEFT JOIN permite incluir trabajadores sin cargas familiares.
-- Ano de ingreso y antiguedad se calculan dinamicamente.
-- =====================================================================
SELECT
    TO_CHAR(t.numrut, 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        AS "RUT Trabajador",
    INITCAP(t.nombre || ' ' || t.appaterno) AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12)
        AS "Años Antigüedad",
    COUNT(DISTINCT af.numrut_carga) AS "Num. Cargas Familiares",
    INITCAP(i.nombre_isapre) AS "Nombre Isapre",
    '$' || TO_CHAR(ROUND(t.sueldo_base), 'FM999G999G999G990',
                   'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo Base",
    CASE
        WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN
            '$' || TO_CHAR(ROUND(t.sueldo_base * 0.01),
                           'FM999G999G999G990',
                           'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE '0'
    END AS "Bono Fonasa",
    '$' || TO_CHAR(ROUND(t.sueldo_base *
        CASE
            WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12) <= 10
                THEN 0.10
            ELSE 0.15
        END), 'FM999G999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''') AS "Bono Antigüedad",
    INITCAP(a.nombre_afp) AS "Nombre AFP",
    UPPER(ec.desc_estcivil) AS "Estado Civil"
FROM trabajador t
INNER JOIN isapre i ON i.cod_isapre = t.cod_isapre
INNER JOIN afp a ON a.cod_afp = t.cod_afp
INNER JOIN est_civil est ON est.numrut_t = t.numrut
INNER JOIN estado_civil ec ON ec.id_estcivil = est.id_estcivil_est
LEFT JOIN asignacion_familiar af ON af.numrut_t = t.numrut
WHERE est.fecini_estcivil <= TRUNC(SYSDATE)
  AND (est.fecter_estcivil IS NULL
       OR est.fecter_estcivil > TRUNC(SYSDATE))
GROUP BY t.numrut, t.nombre, t.appaterno, t.fecing, t.sueldo_base,
         i.nombre_isapre, a.nombre_afp, ec.desc_estcivil
ORDER BY t.numrut ASC;

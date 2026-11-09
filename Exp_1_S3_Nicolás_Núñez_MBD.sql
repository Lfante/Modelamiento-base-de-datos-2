/*
  DUOC UC - PRY2205 - Experiencia 1 / Semana 3
  Actividad sumativa: Aplicando funciones de agrupacion
  Caso de estudio: ASOCIADOS (Forma B)
  Autor: Nicolas Nunez
  Usuario Oracle: PRY2205_S3

  PRERREQUISITO:
    Ejecutar los scripts oficiales de creacion de usuario y poblado
    en la conexion PRY2205_ACTIVIDAD_S3 antes de estas consultas.

  VARIABLES PARA PROBAR LOS EJEMPLOS DE LA GUIA:
    Caso 1: VALOR_TOTAL_GASTO_COMUN = 100000
    Caso 2: CODIGO_SUCURSAL = 30

  Ejecutar con F5 en Oracle SQL Developer.
*/

-- =====================================================================
-- CASO 1: ANALISIS DE PROPIEDADES
-- Resumen comercial por tipo; se muestran solo grupos cuyo gasto comun
-- total supera el monto proporcionado por el operador.
-- =====================================================================
SELECT
    p.id_tipo_propiedad AS "TIPO",
    COUNT(*) AS "TOTAL_PROPIEDADES",
    '$' || TO_CHAR(ROUND(MAX(p.valor_arriendo)),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "MAX_ARRIENDO",
    '$' || TO_CHAR(ROUND(AVG(p.valor_arriendo)),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "PROMEDIO_ARRIENDO",
    '$' || TO_CHAR(ROUND(MIN(p.valor_arriendo)),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "MIN_ARRIENDO",
    CASE
        WHEN MAX(p.valor_arriendo) <= 1000000 THEN 'ESTÁNDAR'
        ELSE 'PREMIUM'
    END AS "CLASIFICACION",
    '$' || TO_CHAR(ROUND(SUM(NVL(p.valor_gasto_comun, 0))),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "TOTAL_GASTOS_COMUNES"
FROM propiedad p
GROUP BY p.id_tipo_propiedad
HAVING SUM(NVL(p.valor_gasto_comun, 0)) > &VALOR_TOTAL_GASTO_COMUN
ORDER BY SUM(NVL(p.valor_gasto_comun, 0)) DESC;

-- =====================================================================
-- CASO 2: ANTIGUEDAD DE EMPLEADOS
-- Solo Ejecutivos de Arriendo, con mas de 5 anos de antiguedad,
-- excluyendo la sucursal indicada por el operador.
-- =====================================================================
SELECT
    e.nombre_emp || ' ' || e.appaterno_emp AS "Nombre Empleado",
    '$' || TO_CHAR(ROUND(e.sueldo_emp),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo con Formato",
    CASE
        WHEN e.sueldo_emp > 2000000 THEN 'ALTO'
        ELSE 'MEDIO'
    END AS "Clasificacion Sueldo",
    TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12) AS "Anos Antiguedad",
    CASE
        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12) <= 10 THEN
            'Corresponde bono 5%: $' ||
            TO_CHAR(ROUND(e.sueldo_emp * 0.05),
              'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12) <= 20 THEN
            'Corresponde bono 10%: $' ||
            TO_CHAR(ROUND(e.sueldo_emp * 0.10),
              'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE
            'Corresponde bono 15%: $' ||
            TO_CHAR(ROUND(e.sueldo_emp * 0.15),
              'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
    END AS "BONO"
FROM empleado e
WHERE e.id_categoria_emp = 3
  AND e.id_sucursal <> &CODIGO_SUCURSAL
  AND TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12) > 5
ORDER BY e.sueldo_emp DESC;

-- =====================================================================
-- CASO 3: LISTA DE CLIENTES
-- Segmentacion por renta individual. El estado de telefono se determina
-- por la presencia de al menos un celular en cada segmento.
-- Los grupos se filtran segun su renta promedio (> $200.000).
-- =====================================================================
SELECT
    CASE
        WHEN c.renta_cli >= 1000000 THEN 'PREMIUM'
        WHEN c.renta_cli >= 600000 THEN 'ALTA'
        WHEN c.renta_cli >= 300000 THEN 'MEDIA'
        ELSE 'BAJA'
    END AS "CLASIFICACION_RENTA",
    COUNT(*) AS "CANTIDAD_CLIENTES",
    '$' || TO_CHAR(ROUND(AVG(c.renta_cli)),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "RENTA_PROMEDIO",
    CASE
        WHEN COUNT(c.celular_cli) > 0 THEN 'Clientes con Telefono'
        ELSE 'Clientes sin Telefono'
    END AS "ESTADO_TELEFONO"
FROM cliente c
GROUP BY
    CASE
        WHEN c.renta_cli >= 1000000 THEN 'PREMIUM'
        WHEN c.renta_cli >= 600000 THEN 'ALTA'
        WHEN c.renta_cli >= 300000 THEN 'MEDIA'
        ELSE 'BAJA'
    END
HAVING AVG(c.renta_cli) > 200000
ORDER BY CASE
    WHEN MAX(c.renta_cli) >= 1000000 THEN 4
    WHEN MAX(c.renta_cli) >= 600000 THEN 1
    WHEN MAX(c.renta_cli) >= 300000 THEN 2
    ELSE 3
END;

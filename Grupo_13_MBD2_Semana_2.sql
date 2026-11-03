/*
  DUOC UC - PRY2205 - Experiencia 1 / Semana 2
  Creando consultas utilizando funciones SQL
  Esquema: PRY2205_S2
  Ejecutar DESPUES de crear y poblar las tablas con los scripts oficiales.
  Autor: [Nicolás Núñez, Constanza Parra ]
*/

-- ================================================================
-- CASO 1: ANALISIS DE FACTURAS
-- Solo facturas del ano calendario anterior al de ejecucion.
-- ================================================================
SELECT
    f.numfactura AS "N° Factura",
    TO_CHAR(f.fecha, 'DD "de" FMMonth YYYY', 'NLS_DATE_LANGUAGE=SPANISH') AS "Fecha Emisión",
    LPAD(f.rutcliente, 10, '0') AS "RUT Cliente",
    '$' || TO_CHAR(ROUND(f.neto), 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Monto Neto",
    '$' || TO_CHAR(ROUND(f.iva), 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Monto Iva",
    '$' || TO_CHAR(ROUND(f.total), 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Total Factura",
    CASE
        WHEN f.total BETWEEN 0 AND 50000 THEN 'Bajo'
        WHEN f.total BETWEEN 50001 AND 100000 THEN 'Medio'
        ELSE 'Alto'
    END AS "Categoría Monto",
    DECODE(f.codpago,
        1, 'EFECTIVO',
        2, 'TARJETA DEBITO',
        3, 'TARJETA CREDITO',
        'CHEQUE') AS "Forma de pago"
FROM factura f
WHERE f.fecha >= ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12)
  AND f.fecha < TRUNC(SYSDATE, 'YYYY')
ORDER BY f.fecha DESC, f.neto DESC;

-- ================================================================
-- CASO 2: CLASIFICACION DE CLIENTES
-- Solo clientes activos con credito mayor que cero.
-- ================================================================
SELECT
    LPAD(c.rutcliente, 12, '*') AS "RUT",
    INITCAP(c.nombre) AS "Cliente",
    NVL(TO_CHAR(c.telefono), 'Sin teléfono') AS "TELÉFONO",
    NVL(TO_CHAR(c.codcomuna), 'Sin comuna') AS "COMUNA",
    c.estado AS "ESTADO",
    CASE
        WHEN c.saldo / c.credito < 0.5 THEN
            'Bueno ( $' || TO_CHAR(ROUND(c.credito - c.saldo), 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') || ')'
        WHEN c.saldo / c.credito <= 0.8 THEN
            'Regular ( $' || TO_CHAR(ROUND(c.saldo), 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') || ')'
        ELSE 'Crítico'
    END AS "Estado Crédito",
    NVL(SUBSTR(c.mail, INSTR(c.mail, '@') + 1), 'Correo no registrado') AS "Dominio Correo"
FROM cliente c
WHERE c.estado = 'A'
  AND c.credito > 0
ORDER BY c.nombre ASC;

-- ================================================================
-- CASO 3: STOCK DE PRODUCTOS
-- La primera ejecucion solicita 3 parametros (variables de sustitucion).
-- Valores de comprobacion de la Figura 4: 950, 40 y 60.
-- ================================================================
SELECT
    p.codproducto AS "ID",
    INITCAP(p.descripcion) AS "Descripción de Producto",
    CASE
        WHEN p.valorcompradolar IS NULL THEN 'Sin registro'
        ELSE TO_CHAR(p.valorcompradolar, 'TM9', 'NLS_NUMERIC_CHARACTERS='',.''') || ' USD'
    END AS "Compra en USD",
    CASE
        WHEN p.valorcompradolar IS NULL THEN 'Sin registro'
        ELSE '$' || TO_CHAR(ROUND(p.valorcompradolar * &TIPOCAMBIO_DOLAR),
             'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''') || ' PESOS'
    END AS "USD convertido",
    p.totalstock AS "Stock",
    CASE
        WHEN p.totalstock IS NULL THEN 'Sin datos'
        WHEN p.totalstock < &UMBRAL_BAJO THEN '¡ALERTA stock muy bajo!'
        WHEN p.totalstock <= &UMBRAL_ALTO THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END AS "Alerta Stock",
    CASE
        WHEN p.totalstock > 80 THEN
            '$' || TO_CHAR(ROUND(p.vunitario * 0.90),
                  'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE 'N/A'
    END AS "Precio Oferta"
FROM producto p
WHERE UPPER(p.descripcion) LIKE '%ZAPATO%'
  AND UPPER(p.procedencia) = 'I'
ORDER BY p.codproducto DESC;

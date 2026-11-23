/*
  DUOC UC - PRY2205 - Experiencia 2 / Semana 5
  Actividad formativa: Utilizando subconsultas para resolver requerimientos
  Caso de estudio: FinanCorp
  Autores: Nicolás Núñez - Constanza Parra
  Conexión: PRY2205_ACTIVIDAD_S5 (usuario PRY2205_S5)

  REQUISITO PREVIO:
    Ejecutar los scripts oficiales de creación de usuario y poblado.
    Ejecutar este archivo con F5 en Oracle SQL Developer.

  NOTAS:
    - Las fechas se calculan dinámicamente, sin años fijos.
    - Se emplea sintaxis JOIN explícita y subconsultas.
    - El segundo caso crea una tabla física; se incluye limpieza controlada
      para poder repetir la ejecución sin generar ORA-00955.
*/

-- =====================================================================
-- CASO 1: LISTADO DE CLIENTES
-- Trabajadores dependientes cuya profesión es Contador o Vendedor.
-- Solo se incluyen inscripciones posteriores al promedio REDONDEADO
-- de los años de inscripción de TODOS los clientes.
-- =====================================================================
SELECT
    TO_CHAR(c.numrun, 'FM999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || LOWER(c.dvrun) AS "RUT Cliente",
    INITCAP(TRIM(c.pnombre) || ' ' || c.appaterno) AS "Nombre Cliente",
    UPPER(po.nombre_prof_ofic) AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY') AS "Fecha de Inscripción",
    INITCAP(c.direccion) AS "Dirección Cliente"
FROM cliente c
INNER JOIN profesion_oficio po
    ON po.cod_prof_ofic = c.cod_prof_ofic
INNER JOIN tipo_cliente tc
    ON tc.cod_tipo_cliente = c.cod_tipo_cliente
WHERE UPPER(tc.nombre_tipo_cliente) = 'TRABAJADORES DEPENDIENTES'
  AND UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
  AND EXTRACT(YEAR FROM c.fecha_inscripcion) > (
      SELECT ROUND(AVG(EXTRACT(YEAR FROM c2.fecha_inscripcion)), 0)
      FROM cliente c2
  )
ORDER BY c.numrun ASC;

-- =====================================================================
-- CASO 2: AUMENTO DE CRÉDITO
-- Comparar cupo disponible de compra con el MAXIMO cupo disponible
-- de las tarjetas SOLICITADAS durante el año calendario anterior.
-- La consulta resultante se almacena en CLIENTES_CUPOS_COMPRA.
-- =====================================================================

-- Validación complementaria: permite reejecutar el archivo si la tabla
-- de resultados ya fue creada en una prueba anterior. Solo se ignora
-- ORA-00942 (tabla inexistente); cualquier otro error se propaga.
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CLIENTES_CUPOS_COMPRA PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT
    TO_CHAR(c.numrun, 'FM9999999990')
        || '-' || LOWER(c.dvrun) AS "RUT_CLIENTE",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_nacimiento)
        AS "EDAD",
    '$' || TO_CHAR(ROUND(t.cupo_disp_compra),
          'FM999G999G999G990', 'NLS_NUMERIC_CHARACTERS='',.''')
        AS "CUPO_DISPONIBLE_COMPRA",
    UPPER(tc.nombre_tipo_cliente) AS "TIPO_CLIENTE"
FROM cliente c
INNER JOIN tarjeta_cliente t
    ON t.numrun = c.numrun
INNER JOIN tipo_cliente tc
    ON tc.cod_tipo_cliente = c.cod_tipo_cliente
WHERE t.cupo_disp_compra >= (
    SELECT MAX(t2.cupo_disp_compra)
    FROM tarjeta_cliente t2
    WHERE t2.fecha_solic_tarjeta >= ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12)
      AND t2.fecha_solic_tarjeta < TRUNC(SYSDATE, 'YYYY')
)
ORDER BY "EDAD" ASC;

-- Mostrar el contenido creado con el orden solicitado en la Figura 3.
SELECT
    "RUT_CLIENTE",
    "EDAD",
    "CUPO_DISPONIBLE_COMPRA",
    "TIPO_CLIENTE"
FROM CLIENTES_CUPOS_COMPRA
ORDER BY "EDAD" ASC;

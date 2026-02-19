# Cómo importar la lista de pagarés (Documento a liquidar)

**Proyectos Avanzados – Business Central**

---

## 1. Objetivo

Este proceso permite importar desde un archivo Excel una lista de **pagarés** asociados a proyectos y tareas. El sistema actualiza la tabla **Proyecto Movimiento Pago** y rellena el campo **Documento a liquidar** con el número de pagaré correspondiente, filtrando por **Nº Proyecto** y **Nº Tarea**.

---

## 2. Dónde se ejecuta

- Menú: **Pagos Vinculados al Proyecto** (página **Pagos Proyecto**).
- Acción: **Importar pagarés (Documento a liquidar)** (icono de importar).

---

## 3. Formato del archivo Excel

El archivo debe ser **.xlsx** y tener **una hoja** con la siguiente estructura:

| Columna | Contenido        | Descripción                                      |
|--------|-------------------|--------------------------------------------------|
| **A**  | Nº Proyecto       | Código del proyecto (Job No.)                     |
| **B**  | Nº Tarea          | Código de la tarea del proyecto (Job Task No.)   |
| **C**  | Nº Pagaré         | Número del pagaré (Documento a liquidar)        |

- **Fila 1:** debe contener los **encabezados** (se ignora en la importación).
- **Desde la fila 2:** cada fila es una línea a importar.

### Ejemplo de contenido

| A (Nº Proyecto) | B (Nº Tarea) | C (Nº Pagaré) |
|-----------------|--------------|---------------|
| PROY-2024-001   | 1000         | PAG-0001      |
| PROY-2024-001   | 2000         | PAG-0002      |
| PROY-2024-002   | 1000         | PAG-0003      |

---

## 4. Pasos para importar

1. Abrir **Pagos Vinculados al Proyecto** (página **Pagos Proyecto**).
2. Pulsar la acción **Importar pagarés (Documento a liquidar)**.
3. En el cuadro de diálogo, seleccionar el archivo **Excel (.xlsx)** con la lista de pagarés.
4. Elegir la **hoja** a importar (si el libro tiene varias) y confirmar.
5. El sistema procesa el archivo y muestra un mensaje al final con:
   - **Filas procesadas:** número de filas de datos válidas (proyecto + tarea + pagaré informados).
   - **Registros actualizados:** número de registros de **Proyecto Movimiento Pago** a los que se ha asignado el **Documento a liquidar**.

---

## 5. Comportamiento del proceso

- Para **cada fila** del Excel (desde la fila 2) con Nº Proyecto, Nº Tarea y Nº Pagaré informados:
  - Se buscan en **Proyecto Movimiento Pago** todos los registros con ese **Job No.** y **Job Task No.**.
  - En esos registros se rellena el campo **Documento a liquidar** con el **Nº Pagaré** de la fila.
- Las filas en blanco o con algún valor vacío en A, B o C se omiten.
- Si para un proyecto/tarea no existe ningún movimiento en Proyecto Movimiento Pago, esa fila no actualiza registros pero se cuenta como fila procesada.

---

## 6. Recomendaciones

- Comprobar que los **Nº Proyecto** y **Nº Tarea** existan en Business Central y coincidan con los de los movimientos de pago.
- Usar la **primera hoja** del libro o la que contenga la tabla con el formato indicado.
- No dejar filas vacías entre los datos; la primera fila debe ser siempre la de encabezados.

---

## 7. Resumen rápido

| Concepto              | Detalle                                                |
|-----------------------|--------------------------------------------------------|
| Dónde                 | Pagos Proyecto → Importar pagarés (Documento a liquidar) |
| Formato               | Excel .xlsx, fila 1 = encabezados                     |
| Columnas              | A = Nº Proyecto, B = Nº Tarea, C = Nº Pagaré          |
| Tabla actualizada     | Proyecto Movimiento Pago                               |
| Campo rellenado       | Documento a liquidar                                   |

---

*Documento generado para la extensión Proyectos Avanzados.*

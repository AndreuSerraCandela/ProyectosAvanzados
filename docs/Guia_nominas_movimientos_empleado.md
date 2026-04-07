# Nóminas y movimientos de empleado — Guía para el usuario

Este documento describe, de forma resumida, cómo encajan en el sistema la **importación de nóminas**, la **contabilización** y el **pago**, así como la relación con los **movimientos de empleado** y, cuando aplica, con **proyectos**.

---

## 1. Configuración previa

Antes de trabajar con nóminas conviene tener:

- **Configuración de nóminas** (cuentas contables por concepto: devengos, retenciones, SS, cobro de nómina, etc.). Desde la lista o ficha de nóminas puede abrirse la opción **Configurar**.
- **Serie numérica** con código **`NOMINAS`** (necesaria para asignar el número de documento al contabilizar).
- **Código fuente** **`NOMINAS`** (el sistema lo crea automáticamente si no existe al contabilizar desde la ficha).
- Empleados dados de alta en Business Central; la importación puede ayudar a crear empleados si aún no existen, según los datos del Excel.

---

## 2. Importación desde Excel

1. Abra **Lista de nóminas**.
2. Use la acción **Importar desde Excel**.
3. Indique la **fecha** de la nómina cuando el sistema se la solicite.
4. Seleccione el **fichero Excel** con el formato esperado por su proceso (varias hojas / estructura definida por su consultor o administrador).

**Qué ocurre entonces**

- Los datos se vuelcan a las tablas de **cabecera** y **detalle de nóminas** (por empresa, fecha y departamento según el fichero).
- Verá un mensaje de confirmación con el resumen (hojas procesadas, fecha, nóminas procesadas).
- **Aún no se ha registrado nada en contabilidad ni en el mayor de empleados**: solo se han guardado los datos para revisión.

**Recomendación:** abra la **ficha de nóminas** correspondiente y revise importes y empleados antes de contabilizar.

---

## 3. Contabilización (generación del diario)

1. Desde la **ficha Nóminas** (fecha y departamento concretos), pulse **Contabilizar** (o **F9**).
2. El sistema genera el **número de documento** (serie `NOMINAS`), marca la nómina como contabilizada en la ficha y crea las **líneas en el diario general**:
   - Diario: **`GENERAL`**
   - Sección: **`NOMINAS`**
   - Código fuente: **`NOMINAS`**

**Importante para el usuario:** esta acción **prepara** el diario; **debe registrar el diario** en Business Central como hace con cualquier otro asiento (revisar líneas, registrar lote). Hasta que no se registre el diario, los movimientos contables definitivos no quedan cerrados en el sistema.

Si la nómina ya estaba marcada como contabilizada, el sistema puede pedir confirmación antes de volver a generar líneas.

---

## 4. Registro del diario y movimientos de empleado

Cuando se **registra el lote del diario** cuyo código fuente es **`NOMINAS`**, el sistema puede **crear movimientos en el mayor de empleados** asociados a esa nómina:

- Se utiliza el **importe neto a pagar al empleado** según el detalle de nómina (en la lógica actual, el valor del campo **Personal** del detalle).
- Solo se genera movimiento si ese importe **no es cero** y **no existía ya** un movimiento duplicado para el mismo empleado, documento y fecha.
- El movimiento queda descrito de forma orientativa como **“Nómina”** más el **mes** correspondiente.

Así se separa el circuito contable (diario con múltiples cuentas) del **saldo pendiente por empleado** que luego interviene en los pagos.

---

## 5. Pago al empleado

El **pago** se gestiona con la **normalidad de Business Central**:

- Diario de pagos (por ejemplo **pagos** o el diario que utilice su empresa) contra banco, aplicando o liquidando los **movimientos del mayor de empleados** pendientes.

Según la parametrización y extensiones instaladas, al registrar ciertos pagos pueden generarse acciones adicionales en el ámbito de **proyectos** (por ejemplo, movimientos de pago de proyecto vinculados a horas o costes ya imputados). Eso depende de que el movimiento de empleado lleve **proyecto / tarea / línea de planificación** informados y del flujo de pago concreto.

---

## 6. Movimientos de empleado relacionados con proyectos

Si un empleado tiene imputación a **proyecto** (campos como **N.º proyecto**, **N.º tarea**, **N.º línea planificación** en el mayor de empleados):

- Desde **Movimientos de empleado** dispone de la acción **Liquidar movimiento proyecto**, que genera la correspondiente relación en **movimientos de pago del proyecto**, cuando proceda según reglas de negocio.
- Otros procesos (por ejemplo registro de **pagos** en diario) pueden disparar la generación automática de movimientos de pago de proyecto para saldar costes de proyecto del empleado, según fechas y estado de los movimientos.

Para el detalle técnico o excepciones, consulte con su partner o administrador.

---

## 7. Resumen del flujo

| Fase | Qué hace el usuario | Qué hace el sistema |
|------|---------------------|----------------------|
| **Importación** | Lista nóminas → Importar Excel + fecha | Rellena cabecera y detalle de nóminas |
| **Revisión** | Abre ficha Nóminas | — |
| **Contabilizar** | F9 / Contabilizar en ficha | Líneas en diario GENERAL · NOMINAS + n.º documento |
| **Registrar diario** | Diario general, lote NOMINAS | Asientos contables + creación de mov. empleado (neto) si aplica |
| **Pagar** | Diario de pagos estándar BC | Liquidación bancaria / empleado según BC |

---

*Documento generado a partir del comportamiento previsto en la extensión. Cualquier personalización posterior puede variar textos de menú o pasos concretos.*

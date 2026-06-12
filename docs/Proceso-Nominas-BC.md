# Proceso de nóminas en Business Central

**Documento de definición funcional**

*Borrador para validación por el equipo*

---

## Objetivo del documento

Este documento describe **el proceso de nóminas en Business Central**: importación, contabilización, movimientos de empleado y de proyecto, y liquidación por banco. Su finalidad es alinear criterios entre contabilidad, recursos humanos y gestión de proyectos antes de cerrar el desarrollo.

---

## Principios del proceso

### 1. El Excel como origen de los datos y referencia de cuadre

Toda nómina entra por **importación de un Excel**. El sistema toma los importes del fichero y espera que **cuadren entre sí** según las fórmulas indicadas en este documento.

**Requisitos del fichero Excel:**

1. Traiga **una hoja por departamento/centro** (en cada importación se elige **una sola hoja**).
2. Traiga el **CIF de la empresa** correcto (si no coincide, no se importa).
3. Incluya las **columnas requeridas** de la plantilla (empleado, devengado, SS, IRPF, etc.).
4. Incluya al final de la hoja (o en hoja anexa) un **ejemplo de cuadre del asiento** por empleado y por totales — ver sección 3 de este documento.

Si los importes no cuadran, la contabilización se detiene hasta corregir el origen.

---

### 2. Tres registros distintos en cada contabilización

Al **contabilizar** una nómina, por cada empleado el sistema genera **tres movimientos independientes**:

| # | Qué es | Para qué sirve |
|---|--------|----------------|
| 1 | **Movimiento de contabilidad** (diario NOMINAS) | El asiento contable real (cuentas 640, 476, 475, 465, etc.) |
| 2 | **Movimiento de empleado** | Lo que la empresa **debe pagar** al trabajador (y, en su caso, IRPF y SS si van por cuenta de empleado) |
| 3 | **Movimiento de proyecto** | El **coste imputable al proyecto** (no es lo mismo que el líquido a pagar) |

Cada uno cumple una función distinta y, en general, **no comparte el mismo importe**.

---

### 3. Vinculación entre movimiento de empleado y movimiento de proyecto

Para **pagar la nómina por banco** y liquidar correctamente el coste en el proyecto, es necesario que:

- Cada **movimiento de empleado** quede **relacionado** con su **movimiento de proyecto** correspondiente.
- Al registrar el pago, el sistema identifique **qué movimiento de proyecto se está saldando**.

Esa relación se establece mediante el campo **Employee Entry No.** (nº mov. empleado) en el movimiento de proyecto.

Esta vinculación es la base para generar automáticamente el **Proyecto Movimiento Pago** al liquidar el empleado.

---

## 1. Flujo completo (de principio a fin)

```
Excel  →  Importar (1 hoja)  →  Revisar en pantalla Nóminas
                                        ↓
                              Contabilizar nómina
                                        ↓
                    ┌───────────────────┼───────────────────┐
                    ↓                   ↓                   ↓
            Diario contable      Mov. empleado(s)      Mov. proyecto
            (NOMINAS)            (Personal, etc.)    (por partida + tarea)
                    ↓                   ↓                   ↓
            Cuentas contables    Pendiente de pago    Coste imputado
                                        ↓
                              Pago bancario (diario pagos)
                                        ↓
                         Proyecto Movimiento Pago
                    (enlaza pago ↔ mov. proyecto)
```

---

## 2. Columnas del Excel y cómo se calculan los campos clave

### 2.1 Columnas que se importan del Excel (por empleado)

| Columna Excel (plantilla) | Campo en sistema | ¿Se contabiliza? |
|---------------------------|------------------|------------------|
| Código empleado (col. B) | Empleado | — |
| T. Bruto / Devengado | Devengado | Sí (DEBE) |
| S.S. Obrero | S.S Obrero | Sí (HABER, en 476) |
| I.R.P.F. | IRPF | Sí (HABER) |
| S.S. Empresa | SS empresa | Sí (DEBE + HABER en 476) |
| Enfermedad / Accidente | Enfermedad Accidente | Sí (contrapartidas) |
| Bonificación | Bonificación | Sí (HABER) |
| Bonificación Fundae | Bonificación Fundae | Sí (HABER) |
| Anticipos | Anticipos | Sí (HABER) |
| Embargos | Embargos | Sí (HABER) |
| Kms | Kms | Sí (DEBE aparte) |
| Dieta | Dieta | Sí (DEBE aparte) |
| Dto. Especie | Dto. Especie | Sí (DEBE + HABER) |
| Ant.diet | Ant.diet | Sí (HABER + DEBE anticipos) |
| Banco | Banco | Control (no asiento directo) |
| Nº Proyecto / Nº Tarea (por partida) | Job No. / Job Task No. | Imputación a proyecto |

*Otras columnas informativas (P.P.Ex, MEJORA V, COMIDA, etc.) se guardan pero hoy no generan asiento.*

---

### 2.2 Fórmulas que el sistema calcula (deben cuadrar con el Excel)

El sistema aplica estas fórmulas de forma automática. El Excel de origen debe ser coherente con ellas para que el cuadre sea correcto.

**SS total (Seguridad Social total: obrero + empresa)**

```
SS total = S.S Obrero + SS empresa − Bonificación − Bonificación Fundae
```

*Incluye la cuota del trabajador y la de la empresa, menos bonificaciones.*

**Personal (líquido a percibir / lo que va a cuenta 465)**

```
Personal = Devengado − S.S Obrero − IRPF − Anticipos − Embargos
```

*La S.S Obrero ya está descontada del devengado.*

**TC1 (cuota Seguridad Social a ingresar a la TGSS)**

```
TC1 = SS total − Enfermedad Accidente
```

**Coste proyecto (campo de control; no es una sola partida contable)**

```
Coste = Devengado + SS total − Enfermedad Accidente
```

*Referencia del coste total del empleado. No se contabiliza como línea del diario: sirve para comprobar que la suma de las partidas imputadas a proyecto coincide con el coste esperado.*

**Imputación a proyecto (configurable por partida)**

Se puede decidir **qué partidas de la nómina generan movimiento de proyecto** (devengado, SS empresa, SS obrero, etc.). Por cada partida imputada:

- Se indica **Nº Proyecto** y **Nº Tarea** (obligatorio en cada línea).
- Se genera un **movimiento de proyecto** por partida, con el importe de esa partida.
- La **suma** de los importes imputados debe coincidir con el **Coste** de control (o con el criterio acordado).

**Diferencia de control (Banco vs Personal)**

```
Difª = Banco − Personal
```

*Debe ser 0. Si no es 0, el importe del banco no coincide con el líquido calculado.*

---

## 3. Ejemplo de cuadre del asiento (plantilla de validación)

Se recomienda incluir en el Excel un bloque como el siguiente (por empleado y por totales) para verificar el cuadre **antes** de la importación.

### Ejemplo empleado EMP001 — Nómina enero

**Datos de entrada (columnas Excel):**

| Concepto | Importe |
|----------|--------:|
| Devengado | 3.000,00 |
| S.S Obrero | 200,00 |
| IRPF | 400,00 |
| SS empresa | 600,00 |
| Bonificación | 0,00 |
| Bonificación Fundae | 0,00 |
| Enfermedad Accidente | 0,00 |
| Anticipos | 0,00 |
| Embargos | 0,00 |
| Banco | 2.400,00 |

**Cálculos (deben coincidir):**

| Campo | Cálculo | Resultado |
|-------|---------|----------:|
| SS total | 200 + 600 − 0 − 0 | 800,00 |
| Personal | 3.000 − 200 − 400 − 0 − 0 | **2.400,00** |
| TC1 | 800 − 0 | 800,00 |
| Coste proyecto (control) | 3.000 + 800 − 0 | **3.800,00** |
| Difª | 2.400 − 2.400 | **0,00** ✓ |

**Imputación a proyecto (ejemplo: dos partidas, dos tareas):**

| Partida | Importe | Proyecto | Tarea |
|---------|--------:|----------|-------|
| Devengado | 3.000,00 | PRY-001 | 1.1 |
| SS total | 800,00 | PRY-001 | 1.2 |
| **Total imputado** | **3.800,00** | | = Coste de control ✓ |

**Asiento contable que debe cuadrar (DEBE = HABER):**

| Cuenta / concepto | DEBE | HABER |
|-------------------|-----:|------:|
| Devengado (640…) | 3.000,00 | |
| SS empresa (642…) | 600,00 | |
| Organismos SS / 476 (SS Obrero + SS empresa) | | 800,00 |
| IRPF (4751…) | | 400,00 |
| Personal / 465 (empleado) | | 2.400,00 |
| **TOTALES** | **3.600,00** | **3.600,00** |

**Comprobación:** DEBE = HABER → el asiento cuadra.

---

## 4. Qué genera cada partida: contabilidad, empleado y proyecto

### 4.1 Movimiento de CONTABILIDAD (diario NOMINAS)

Todas las partidas del cuadre anterior generan líneas en el diario **GENERAL / NOMINAS**, excepto **Coste** (que no es partida contable).

| Partida | Mov. contable | DEBE / HABER |
|---------|:-------------:|:------------:|
| Devengado (neto de Kms/Dieta/Especie) | Sí | DEBE |
| Kms | Sí | DEBE |
| Dieta | Sí | DEBE |
| Dto. Especie | Sí | DEBE + HABER |
| SS empresa | Sí | DEBE |
| Enfermedad Accidente | Sí | HABER + DEBE (contrapartida) |
| SS Obrero + SS empresa (476) | Sí | HABER |
| IRPF | Sí | HABER |
| Anticipos | Sí | HABER |
| Embargos | Sí | HABER |
| Bonificación / Fundae | Sí | HABER |
| Ant.diet | Sí | HABER + DEBE (anticipos) |
| **Personal** | Sí | HABER (cuenta empleado 465) |

*El campo **Coste** no genera línea en el diario; solo las partidas configuradas generan mov. de proyecto.*

---

### 4.2 Movimiento de EMPLEADO

**Qué es:** el registro en *Mov. contabilidad empleado* que representa una deuda de la empresa con el trabajador (o con Hacienda/SS si va por empleado).

| Partida | ¿Genera mov. empleado? | Tipo Mov. Empleado | Importe |
|---------|:----------------------:|:------------------:|--------:|
| **Personal** (líquido nómina) | **Sí** | Nómina | Personal |
| IRPF | Sí* | IRPF | IRPF |
| SS (476) | Sí* | Seg. Social | SS total (= S.S Obrero + SS empresa − bonificaciones) |

*\*Si en configuración la cuenta está definida como tipo **Empleado**. Si es cuenta contable (G/L), no genera mov. empleado.*

**Nota:** el movimiento de empleado de tipo **Nómina** refleja el importe **Personal** (líquido a percibir), no el Coste ni el Devengado íntegro.

---

### 4.3 Movimiento de PROYECTO

No existe una única partida fija: **se configura qué conceptos de la nómina se imputan al proyecto**. Cada partida seleccionada genera su propio movimiento de proyecto.

| Partida (ejemplo) | ¿A proyecto? | Importe | Proyecto / Tarea |
|-------------------|:------------:|--------:|:----------------:|
| Devengado | Configurable | Devengado (o neto) | Proyecto + **Tarea obligatoria** |
| SS empresa | Configurable | SS empresa | Proyecto + **Tarea obligatoria** |
| S.S Obrero | Configurable | S.S Obrero | Proyecto + **Tarea obligatoria** |
| SS total | Configurable | SS total | Proyecto + **Tarea obligatoria** |
| … otras | Configurable | Importe partida | Proyecto + **Tarea obligatoria** |
| **Personal** | **No** | — | Va a mov. empleado |
| **Coste** (control) | **No** | Suma de control | Verifica cuadre de imputaciones |

**Reglas:**

1. Puede haber **varios movimientos de proyecto por empleado** (uno por cada partida imputada).
2. Cada movimiento lleva **Nº Proyecto** y **Nº Tarea**; sin tarea no se imputa.
3. La suma de importes imputados debe **cuadrar con el Coste** de control (o el criterio definido).
4. Los mov. de empleado **no generan** mov. de proyecto por sí solos; la imputación se hace al contabilizar según configuración.

---

## 5. Relación entre movimiento de empleado y movimiento de proyecto

La correlación entre registros **no es opcional**: cada movimiento de proyecto debe indicar en el campo **Employee Entry No.** el **nº de entrada (Entry No.)** del movimiento de empleado con el que se relaciona. Así, al pagar por banco y generar los **Proyecto Movimiento Pago**, el sistema puede emparejar unos con otros sin ambigüedad.

### Cuadro de correlación (ejemplo empleado EMP001 — nómina enero)

Tras contabilizar, quedan registrados los movimientos siguientes. La columna **Employee Entry No.** en el mov. de proyecto es la clave de enlace.

| Tipo registro | Concepto / partida | Nº Entry (propio) | Importe | Employee Entry No. (enlace) | Correlaciona con | Proyecto / Tarea |
|---------------|-------------------|-------------------|--------:|----------------------------|------------------|------------------|
| **Mov. empleado** | Nómina (Personal) | **12345** | 2.400,00 | — | JLE 50001 y JLE 50002 | — |
| **Mov. proyecto** | Devengado | **50001** | 3.000,00 | **12345** | Mov. empleado 12345 (Nómina) | PRY-001 / 1.1 |
| **Mov. proyecto** | SS total | **50002** | 800,00 | **12345** | Mov. empleado 12345 (Nómina) | PRY-001 / 1.2 |
| **Mov. empleado** *(opcional)* | IRPF | 12346 | 400,00 | — | JLE con Employee Entry No. = 12346 *(si hay partida imputada)* | — |
| **Mov. empleado** *(opcional)* | Seg. Social | 12347 | 800,00 | — | JLE con Employee Entry No. = 12347 *(si hay partida imputada)* | — |

**Regla de correlación:**

1. Al contabilizar, cada **mov. de proyecto** guarda en **Employee Entry No.** el **Entry No.** del **mov. de empleado** que le corresponde (en el ejemplo, los dos JLE apuntan al mov. de nómina 12345).
2. Puede haber **varios mov. de proyecto** para un mismo mov. de empleado (una fila JLE por cada partida imputada).
3. La suma de importes de los JLE vinculados a un mov. de empleado debe **cuadrar** con el criterio de coste acordado (en el ejemplo: 3.000 + 800 = Coste 3.800).

### Al contabilizar

- **Mov. empleado (Nómina):** Entry No. = 12345, Importe = Personal, Tipo = Nómina
- **Mov. proyecto (por partida):** uno o varios registros; cada uno con su Entry No. (50001, 50002…), importe de la partida, Proyecto + **Tarea**, y **Employee Entry No. = 12345**

### Al pagar por banco

1. Se registra un **pago** que liquida el mov. de empleado (Nómina, IRPF o Seg. Social).
2. El sistema busca **todos los mov. de proyecto** con el mismo **Employee Entry No.** que el mov. liquidado.
3. Crea un **Proyecto Movimiento Pago** por cada mov. de proyecto encontrado.

### Cuadro de correlación al pagar (mismo ejemplo EMP001)

| Paso | Qué se liquida | Entry No. mov. empleado | Qué busca el sistema | Qué genera |
|------|----------------|------------------------:|----------------------|------------|
| 1 | Pago bancario del **Personal** (nómina) | **12345** | Todos los mov. de proyecto con Employee Entry No. = **12345** (JLE 50001 y 50002) | Un **Proyecto Movimiento Pago** por cada JLE |
| 2 | Pago de **IRPF** *(si aplica)* | 12346 | Mov. de proyecto con Employee Entry No. = **12346** | Proyecto Movimiento Pago por cada JLE vinculado |
| 3 | Pago de **Seg. Social** *(si aplica)* | 12347 | Mov. de proyecto con Employee Entry No. = **12347** | Proyecto Movimiento Pago por cada JLE vinculado |

**En resumen:** el **Employee Entry No.** del mov. de proyecto identifica de forma unívoca el mov. de empleado que, al liquidarse en banco, dispara la generación del Proyecto Movimiento Pago. Sin ese enlace, el sistema no puede correlacionar pago e imputación de coste.

---

## 6. Puntos pendientes de validación

Agradeceríamos vuestra confirmación sobre los siguientes aspectos, con el fin de cerrar el diseño del proceso:

### A) Excel y cuadre

- ¿El Excel incluirá el **bloque de ejemplo de cuadre** (sección 3) en cada hoja?
- ¿Quién valida que **Difª = 0** (Banco = Personal) antes de importar?
- ¿Una importación = **una hoja** = **un departamento**? (así está configurado ahora)

### B) Proyecto, partidas y tareas

- ¿Qué partidas se imputan a proyecto? (devengado, SS empresa, SS obrero, SS total, otras)
- ¿Cada partida lleva siempre **tarea** propia? Indicad el criterio (ej. devengado → tarea A, SS → tarea B).
- ¿La suma de partidas imputadas debe coincidir siempre con el campo **Coste** de control?

### C) Movimientos de empleado

- ¿Solo **Personal** genera mov. empleado, o también **IRPF** y **SS**? (código preparado para los tres)
- ¿Las cuentas de IRPF y SS en configuración serán tipo **Empleado** o **Cuenta contable**?

### D) Pago

- ¿Un pago bancario liquida **solo la nómina (Personal)** o también IRPF/SS por separado?
- ¿Al pagar, se liquidan todos los mov. de proyecto vinculados al mov. de empleado (Employee Entry No.)?

---

## 7. Resumen en una frase

> **El Excel trae las cifras y debe cuadrar; al contabilizar se generan contabilidad, movimientos de empleado e imputaciones a proyecto (por partida y tarea configuradas); al pagar, el vínculo Employee Entry No. permite liquidar cada mov. de proyecto de forma coherente con el pago.**

---

*Con vuestras respuestas a la sección 6 podremos finalizar el desarrollo e incorporar las modificaciones pendientes.*

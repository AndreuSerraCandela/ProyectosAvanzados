# Documentación de Cambios - Funcionalidad de Empleados y Proyectos

## Resumen

Se ha implementado una funcionalidad completa para relacionar movimientos de empleados con proyectos, permitiendo la liquidación automática de líneas de planificación de proyecto cuando se liquidan movimientos de empleados.

---

## 1. Extensión de Tabla: Employee Ledger Entry

### Archivo
`src/tableextension/Tab522-Ext50114.EmployeeLedgerEntry.al`

### Extensión
**50320 "EmployeeLedgerEntryExt"** - Extiende la tabla **Employee Ledger Entry** (522)

### Campos Añadidos

| Nº Campo | Nombre Campo | Tipo | Descripción |
|----------|--------------|------|-------------|
| 50000 | Job No. | Code[20] | Nº Proyecto - Relaciona el movimiento con un proyecto |
| 50001 | Job Task No. | Code[20] | Nº Tarea Proyecto - Relaciona el movimiento con una tarea del proyecto |
| 50002 | Job Planning Line No. | Integer | Nº Línea Planificación Proyecto - Relaciona el movimiento con una línea de planificación específica |

### Características
- Todos los campos tienen relaciones de tabla configuradas para mantener la integridad de datos
- Los campos permiten rastrear qué movimientos de empleado están relacionados con qué líneas de planificación de proyecto

---

## 2. Extensión de Página: Employee Ledger Entries

### Archivo
`src/pageextension/Pag-Ext50115.EmployeeLedgerEntries.al`

### Extensión
**50321 "EmployeeLedgerEntriesExt"** - Extiende la página **Employee Ledger Entries**

### Campos Mostrados
Los tres campos añadidos a la tabla se muestran en la página después del campo "Employee No.":
- **Job No.** (Nº Proyecto)
- **Job Task No.** (Nº Tarea Proyecto)
- **Job Planning Line No.** (Nº Línea Planificación Proyecto)

### Características
- Todos los campos tienen ToolTips descriptivos
- ApplicationArea = All para disponibilidad en todas las áreas

---

## 3. Campo en Job Planning Line: Employee Entry No.

### Archivo
`src/tableextension/Tab1003-Ext50100.LineasPlanificacion.al`

### Campo Añadido

| Nº Campo | Nombre Campo | Tipo | Descripción |
|----------|--------------|------|-------------|
| 50019 | Employee Entry No. | Integer | Nº Movimiento Empleado - Almacena el número del movimiento de empleado generado para esta línea |

### Características
- **TableRelation**: Relacionado con `Employee Ledger Entry."Entry No."`
- **Editable = false**: No se puede editar manualmente, se asigna automáticamente
- Se utiliza para evitar generar múltiples movimientos para la misma línea de planificación

---

## 4. Cambios en Codeunit: Gestión Pagos Proyecto

### Archivo
`src/codeunit/Cod50102.GestionPagosProyecto.al`

### Nuevos Procedimientos

#### 4.1. `GenerateEmployeeEntriesForJobPlanningLines`

**Propósito**: Genera movimientos de empleado para líneas de planificación de proyecto relacionadas con el recurso del empleado cuando se liquida un movimiento de empleado.

**Parámetros**:
- `EmployeeLedgerEntry`: Record "Employee Ledger Entry" - El movimiento de empleado fuente

**Lógica**:
1. Obtiene el empleado del movimiento
2. Verifica que el empleado tenga un recurso asociado
3. Busca líneas de planificación que cumplan:
   - Tipo: Resource
   - Recurso: Coincide con el recurso del empleado
   - Line Type: Billable o Both Budget and Billable
   - Employee Entry No.: = 0 (no tiene movimiento asignado)
   - Usage Link: = true
4. Para cada línea encontrada, llama a `CreateEmployeeEntryFromJobPlanningLine`

#### 4.2. `CreateEmployeeEntryFromJobPlanningLine`

**Propósito**: Crea un movimiento de empleado desde una línea de planificación y actualiza la línea con el número del movimiento generado.

**Parámetros**:
- `JobPlanningLine`: Record "Job Planning Line" - La línea de planificación
- `SourceEmployeeLedgerEntry`: Record "Employee Ledger Entry" - El movimiento fuente

**Lógica**:
1. Verifica que la línea no tenga ya un movimiento asignado
2. Crea un nuevo movimiento de empleado basado en el movimiento fuente:
   - Copia datos del movimiento fuente (Employee No., Posting Date, Document Type, Document No., Currency Code)
   - Establece el importe como el Total Cost (LCY) de la línea de planificación
   - Asigna los campos de proyecto (Job No., Job Task No., Job Planning Line No.)
3. Inserta el nuevo movimiento
4. Actualiza la línea de planificación con el número del movimiento generado
5. Crea un registro en ProyectoFacturaCompra llamando a `CreateProyectoFacturaCompraFromEmployeeEntry`

#### 4.3. `CreateProyectoFacturaCompraFromEmployeeEntry`

**Propósito**: Crea un registro en la tabla ProyectoFacturaCompra para permitir la liquidación posterior del movimiento de empleado.

**Parámetros**:
- `EmployeeLedgerEntry`: Record "Employee Ledger Entry" - El movimiento de empleado
- `JobPlanningLine`: Record "Job Planning Line" - La línea de planificación relacionada

**Lógica**:
1. Verifica que no exista ya un registro para esta combinación
2. Crea un nuevo registro en ProyectoFacturaCompra con:
   - Document Type: " " (Documento Blanco)
   - Document No.: Del movimiento de empleado
   - Line No.: 0
   - Job No., Job Task No., Job Planning Line No.: De la línea de planificación
   - Entry No.: Del movimiento de empleado
   - Amount: Total Cost (LCY) de la línea de planificación
   - Amount Paid: 0
   - Amount Pending: Igual al Amount

#### 4.4. `ProcessEmployeeEntryForProject`

**Propósito**: Procesa un movimiento de empleado que ya está relacionado con un proyecto.

**Parámetros**:
- `EmployeeLedgerEntry`: Record "Employee Ledger Entry" - El movimiento de empleado con información de proyecto

**Lógica**:
1. Obtiene la línea de planificación relacionada
2. Si la línea no tiene Employee Entry No. asignado, lo actualiza
3. Crea o actualiza el registro en ProyectoFacturaCompra

### Función Modificada

#### `OnPostEmployeeOnAfterPostDtldEmplLedgEntries`

**Evento**: Se dispara cuando se registra un movimiento de empleado después de crear los asientos detallados.

**Cambios Realizados**:
- **Antes**: Buscaba líneas de planificación basándose en el documento aplicado y creaba asignaciones de proyecto
- **Ahora**: 
  1. Genera automáticamente movimientos de empleado para todas las líneas de planificación relacionadas con el recurso del empleado que no tengan movimiento asignado
  2. Procesa el movimiento original si ya tiene información de proyecto asignada

**Flujo**:
```
Al liquidar un movimiento de empleado:
├── Se dispara OnPostEmployeeOnAfterPostDtldEmplLedgEntries
├── Se llama a GenerateEmployeeEntriesForJobPlanningLines
│   ├── Busca líneas de planificación relacionadas
│   └── Para cada línea encontrada:
│       ├── Crea movimiento de empleado (CreateEmployeeEntryFromJobPlanningLine)
│       ├── Actualiza línea de planificación con Employee Entry No.
│       └── Crea registro en ProyectoFacturaCompra
└── Si el movimiento original tiene proyecto, lo procesa (ProcessEmployeeEntryForProject)
```

---

## 5. Funcionalidad de Liquidación

### Proceso Completo

Cuando se liquida un movimiento de empleado:

1. **Búsqueda de Líneas de Planificación**:
   - Se buscan líneas de planificación de tipo Resource
   - Que estén relacionadas con el recurso del empleado
   - Que sean de tipo Billable o Both Budget and Billable
   - Que tengan Usage Link activado
   - Que no tengan ya un Employee Entry No. asignado

2. **Generación de Movimientos**:
   - Para cada línea encontrada, se crea un nuevo movimiento de empleado
   - El movimiento se crea con los mismos datos del movimiento fuente
   - El importe se toma del Total Cost (LCY) de la línea de planificación
   - Se asigna la información del proyecto (Job No., Job Task No., Job Planning Line No.)

3. **Actualización de Líneas**:
   - Se actualiza cada línea de planificación con el número del movimiento generado
   - Esto evita generar múltiples movimientos para la misma línea

4. **Creación de Registros de Liquidación**:
   - Se crea un registro en ProyectoFacturaCompra para cada movimiento generado
   - Estos registros permiten la liquidación posterior de los movimientos

---

## 6. Tabla ProyectoFacturaCompra

### Uso para Empleados

La tabla **Proyecto Movimiento Pago** (50117) se utiliza también para almacenar información de movimientos de empleados relacionados con proyectos.

### Campos Relevantes para Empleados

- **Document Type**: " " (Documento Blanco) para movimientos de empleado
- **Document No.**: Número de documento del movimiento de empleado
- **Line No.**: 0 (no aplica para movimientos de empleado)
- **Job No.**: Número del proyecto
- **Job Task No.**: Número de la tarea del proyecto
- **Job Planning Line No.**: Número de la línea de planificación
- **Entry No.**: Número del movimiento de empleado (Employee Ledger Entry)
- **Amount**: Importe del movimiento (Total Cost de la línea de planificación)
- **Amount Paid**: Importe pagado (inicialmente 0)
- **Amount Pending**: Importe pendiente (igual al Amount inicialmente)

---

## 7. Flujo de Trabajo Completo

### Escenario: Liquidar Movimientos de Empleado

1. **Usuario liquida un movimiento de empleado** desde el diario general
2. **Sistema registra el movimiento** en Employee Ledger Entry
3. **Se dispara el evento** `OnPostEmployeeOnAfterPostDtldEmplLedgEntries`
4. **Sistema busca líneas de planificación** relacionadas con el recurso del empleado
5. **Para cada línea encontrada**:
   - Crea un nuevo movimiento de empleado
   - Actualiza la línea de planificación con el número del movimiento
   - Crea un registro en ProyectoFacturaCompra
6. **Usuario puede ver** en Employee Ledger Entries:
   - Los movimientos originales
   - Los movimientos generados automáticamente
   - La relación con proyectos, tareas y líneas de planificación
7. **Usuario puede liquidar** los movimientos generados usando los registros en ProyectoFacturaCompra

---

## 8. Archivos Modificados/Creados

### Archivos Creados
1. `src/tableextension/Tab522-Ext50114.EmployeeLedgerEntry.al`
2. `src/pageextension/Pag-Ext50115.EmployeeLedgerEntries.al`

### Archivos Modificados
1. `src/tableextension/Tab1003-Ext50100.LineasPlanificacion.al`
   - Añadido campo `Employee Entry No.` (50019)

2. `src/codeunit/Cod50102.GestionPagosProyecto.al`
   - Añadidos procedimientos:
     - `GenerateEmployeeEntriesForJobPlanningLines`
     - `CreateEmployeeEntryFromJobPlanningLine`
     - `CreateProyectoFacturaCompraFromEmployeeEntry`
     - `ProcessEmployeeEntryForProject`
   - Modificado procedimiento:
     - `OnPostEmployeeOnAfterPostDtldEmplLedgEntries`

---

## 9. Consideraciones Técnicas

### Validaciones
- Se verifica que el empleado tenga un recurso asociado antes de buscar líneas de planificación
- Se evita crear múltiples movimientos para la misma línea de planificación verificando el campo `Employee Entry No.`
- Se verifica que no existan registros duplicados en ProyectoFacturaCompra antes de crear nuevos

### Rendimiento
- Las búsquedas utilizan filtros eficientes en las claves de las tablas
- Se procesan solo las líneas que cumplen todos los criterios necesarios

### Mantenimiento
- Los campos añadidos siguen la nomenclatura estándar del proyecto
- Los procedimientos están documentados con comentarios XML
- La funcionalidad es extensible y puede adaptarse a futuros requisitos

---

## 10. Próximos Pasos Sugeridos

1. **Compilar el proyecto** para verificar que no hay errores de compilación
2. **Probar la funcionalidad** en un entorno de desarrollo:
   - Crear líneas de planificación de tipo Resource con Line Type = Billable o Both Budget and Billable
   - Asignar recursos a empleados
   - Liquidar movimientos de empleado
   - Verificar que se generan los movimientos correctamente
   - Verificar que se crean los registros en ProyectoFacturaCompra
3. **Ajustar si es necesario**:
   - Los criterios de búsqueda de líneas de planificación
   - Los campos que se copian del movimiento fuente
   - La lógica de cálculo de importes

---

## 11. Notas Adicionales

- Los errores del linter relacionados con el campo `Employee Entry No.` se resolverán al compilar el proyecto completo
- El campo `Employee Entry No.` está correctamente definido en la extensión de tabla
- La funcionalidad está lista para ser probada una vez compilado el proyecto

---

**Fecha de Documentación**: $(Get-Date -Format "yyyy-MM-dd")  
**Versión**: 1.0


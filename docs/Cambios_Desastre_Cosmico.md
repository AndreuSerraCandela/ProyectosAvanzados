# Cambios del commit "Desastre Cósmico"

## Información del commit

| Campo | Valor |
|-------|--------|
| **Hash** | ea0b71481e2ea892c5b632b518516ee2ac5455f0 |
| **Autor** | AndreuSerraCandela <74787884+AndreuSerraCandela@users.noreply.github.com> |
| **Fecha** | Thu Feb 19 18:54:03 2026 +0100 |
| **Mensaje** | Desastre Cósmico |

## Resumen

- **4 archivos** modificados
- **47 líneas** añadidas
- **2 líneas** eliminadas

---

## Archivos modificados

1. `src/page/Pag50116.JobTaskLinesSubformExt.al`
2. `src/page/Pag50125.PagosProyecto.al`
3. `src/table/Tab50117.ProyectoFacturaCompra.al`
4. `src/tableextension/Tab1001-Ext50103.JobTaskEx.al`

---

## Descripción de los cambios

### Nuevo campo: "Importe Base Pagado" (Base Amount Paid)

Se añade el concepto de **importe base pagado** (sin IVA) en la tabla **Proyecto Movimiento Pago** y se expone en las páginas y en Job Task.

#### 1. Tabla Proyecto Movimiento Pago (`Tab50117.ProyectoFacturaCompra.al`)

- **Nuevo campo** `"Base Amount Paid"` (campo 16): Decimal, solo lectura, con formato moneda.
- El **Key1** incluye ahora `"Base Amount Paid"` en **SumIndexFields** (junto a Amount Paid y Amount Pending).
- En el procedimiento de recálculo de pagos:
  - Se limpia `"Base Amount Paid"` cuando no hay Vendor Ledger Entry.
  - Se calcula **Base Amount Paid** de forma proporcional al importe pagado del proyecto respecto al total de la factura:
    - Se usan las líneas de factura registrada (`Purch. Inv. Line`) para obtener `Line Amount` (base) y `Amount Including VAT` (bruto).
    - Si el bruto ≠ 0: `Base Amount Paid = Round(ProjectPaidAmount * TotalInvoiceBaseAmount / AmountIncludingVAT, 0.01)`.
    - Si no: `Base Amount Paid := ProjectPaidAmount`.

#### 2. Table extension Job Task (`Tab1001-Ext50103.JobTaskEx.al`)

- **Nuevo campo** `"Base Amount Paid"` (50022): FlowField con **CalcFormula** = suma de `"Proyecto Movimiento Pago"."Base Amount Paid"` filtrado por Job No. y Job Task No. (y Totaling).

#### 3. Página Job Task Lines Subform Ext (`Pag50116.JobTaskLinesSubformExt.al`)

- Nuevo **field** `"Base Amount Paid"` (Importe Base Pagado), solo lectura, después de "Amount Paid".
- En el procedimiento que usa `CalcFields`, se añade **"Base Amount Paid"** a los campos calculados: `Rec.CalcFields("Bruto Factura", "Amount Paid", "Base Amount Paid")`.

#### 4. Página Pagos Proyecto (`Pag50125.PagosProyecto.al`)

- Nuevo **field** `"Base Amount Paid"` (Importe Base Pagado), solo lectura, después de "Amount Paid", con ToolTip indicando que es el importe pagado sin IVA correspondiente al proyecto.

---

## Diff completo (git show)

```
commit ea0b71481e2ea892c5b632b518516ee2ac5455f0
Author: AndreuSerraCandela <74787884+AndreuSerraCandela@users.noreply.github.com>
Date:   Thu Feb 19 18:54:03 2026 +0100

    Desastre Cósmico

diff --git a/src/page/Pag50116.JobTaskLinesSubformExt.al b/src/page/Pag50116.JobTaskLinesSubformExt.al
index 34e1855..9097a72 100644
--- a/src/page/Pag50116.JobTaskLinesSubformExt.al
+++ b/src/page/Pag50116.JobTaskLinesSubformExt.al
@@ -276,6 +276,13 @@ page 50116 "Job Task Lines Subform Ext"
                         Page.RunModal(0, JobEntries);
                     end;
                 }
+                field("Base Amount Paid"; Rec."Base Amount Paid")
+                {
+                    ApplicationArea = All;
+                    Caption = 'Importe Base Pagado';
+                    ToolTip = 'Especifica el importe pagado sin IVA para esta tarea.';
+                    Editable = false;
+                }
                 field("Amount Pending"; CalculaBrutoFactura() - Rec."Amount Paid")// CalculaImportePendiente())
                 {
                     ApplicationArea = All;
@@ -898,7 +905,7 @@ page 50116 "Job Task Lines Subform Ext"
         CodeEmphasize := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;
         DescriptionEmphasize := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;
         DescriptionIndent := Rec.Indentation;
-        Rec.CalcFields("Bruto Factura", "Amount Paid");
+        Rec.CalcFields("Bruto Factura", "Amount Paid", "Base Amount Paid");
         //If Rec."Bruto Factura" = 0 Then Rec."Bruto Factura" := CalculaBrutoFactura();


diff --git a/src/page/Pag50125.PagosProyecto.al b/src/page/Pag50125.PagosProyecto.al
index 1e6c750..cbcbb4e 100644
--- a/src/page/Pag50125.PagosProyecto.al
+++ b/src/page/Pag50125.PagosProyecto.al
@@ -77,6 +77,13 @@ page 50125 "Pagos Proyecto"
                     Editable = false;
                     Style = Favorable;
                 }
+                field("Base Amount Paid"; Rec."Base Amount Paid")
+                {
+                    ApplicationArea = All;
+                    Caption = 'Importe Base Pagado';
+                    ToolTip = 'Especifica el importe pagado sin IVA correspondiente a este proyecto';
+                    Editable = false;
+                }
                 field("Amount Pending"; Rec."Amount Pending")
                 {
                     ApplicationArea = All;
diff --git a/src/table/Tab50117.ProyectoFacturaCompra.al b/src/table/Tab50117.ProyectoFacturaCompra.al
index e468343..26dca0e 100644
--- a/src/table/Tab50117.ProyectoFacturaCompra.al
+++ b/src/table/Tab50117.ProyectoFacturaCompra.al
@@ -130,13 +130,22 @@ table 50117 "Proyecto Movimiento Pago"
             TableRelation = "Purchase Header"."No.";
             Editable = false;
         }
+        field(16; "Base Amount Paid"; Decimal)
+        {
+            Caption = 'Importe Base Pagado';
+            DataClassification = ToBeClassified;
+            AutoFormatType = 1;
+            AutoFormatExpression = GetCurrencyCode();
+            DecimalPlaces = 2 : 5;
+            Editable = false;
+        }
     }
 
     keys
     {
         key(Key1; "Document Type", "Document No.", "Line No.", "Job No.", "Job Planning Line No.", "Entry No.")
         {
-            SumIndexFields = "Amount Paid", "Amount Pending";
+            SumIndexFields = "Amount Paid", "Amount Pending", "Base Amount Paid";
             Clustered = true;
         }
         key(Key2; "Job No.", "Job Planning Line No.", "Document No.", "Line No.")
@@ -267,7 +276,9 @@ table 50117 "Proyecto Movimiento Pago"
         VendorLedgerEntry: Record "Vendor Ledger Entry";
         DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
         PurchaseLine: Record "Purchase Line";
+        PurchInvLine: Record "Purch. Inv. Line";
         TotalInvoiceAmount: Decimal;
+        TotalInvoiceBaseAmount: Decimal;
         TotalPaidAmount: Decimal;
         ProjectPaidAmount: Decimal;
     begin
@@ -283,6 +294,7 @@ table 50117 "Proyecto Movimiento Pago"
         if not VendorLedgerEntry.FindFirst() then begin
             Clear("Amount Paid");
             Clear("Amount Pending");
+            Clear("Base Amount Paid");
             Clear("Last Payment Date");
             exit;
         end;
@@ -309,6 +321,15 @@ table 50117 "Proyecto Movimiento Pago"
 
             "Amount Paid" := ProjectPaidAmount;
             "Amount Pending" := "Amount" - "Amount Paid";
+
+            // Importe base pagado (sin IVA): proporción sobre líneas de factura registrada
+            PurchInvLine.SetRange("Document No.", "Posted Document No.");
+            PurchInvLine.CalcSums("Line Amount", "Amount Including VAT");
+            TotalInvoiceBaseAmount := PurchInvLine."Line Amount";
+            if PurchInvLine."Amount Including VAT" <> 0 then
+                "Base Amount Paid" := Round(ProjectPaidAmount * TotalInvoiceBaseAmount / PurchInvLine."Amount Including VAT", 0.01)
+            else
+                "Base Amount Paid" := ProjectPaidAmount;
         end;
 
         // Buscar fecha del último pago
diff --git a/src/tableextension/Tab1001-Ext50103.JobTaskEx.al b/src/tableextension/Tab1001-Ext50103.JobTaskEx.al
index 0e4baf6..9397125 100644
--- a/src/tableextension/Tab1001-Ext50103.JobTaskEx.al
+++ b/src/tableextension/Tab1001-Ext50103.JobTaskEx.al
@@ -309,6 +309,16 @@ tableextension 50303 "JobTaskEx" extends "Job Task" //1001
             Editable = false;
             DecimalPlaces = 2 : 2;
         }
+        field(50022; "Base Amount Paid"; Decimal)
+        {
+            Caption = 'Importe Base Pagado';
+            FieldClass = FlowField;
+            CalcFormula = sum("Proyecto Movimiento Pago"."Base Amount Paid" where("Job No." = field("Job No."),
+                                                                                      "Job Task No." = field("Job Task No."),
+                                                                                      "Job Task No." = field(filter(Totaling))));
+            Editable = false;
+            DecimalPlaces = 2 : 2;
+        }
 
     }
```

---

*Documento generado a partir del commit ea0b71481e2ea892c5b632b518516ee2ac5455f0 ("Desastre Cósmico").*

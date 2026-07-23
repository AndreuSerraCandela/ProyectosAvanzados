/// <summary>
/// Libro de facturas recibidas (compras) por pantalla, exportable a Excel
/// con una hoja por Tipo de Operación2.
/// </summary>
page 50347 "Libro Facturas Recibidas"
{
    ApplicationArea = All;
    Caption = 'Libro de Facturas Recibidas';
    PageType = Worksheet;
    SourceTable = "Libro IVA Buffer";
    SourceTableTemporary = true;
    UsageCategory = ReportsAndAnalysis;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filtros)
            {
                Caption = 'Filtros';
                field(FechaDesde; FechaDesde)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fecha desde';
                    ToolTip = 'Fecha de registro inicial del período.';
                    Editable = true;
                }
                field(FechaHasta; FechaHasta)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fecha hasta';
                    ToolTip = 'Fecha de registro final del período.';
                    Editable = true;
                }
            }
            repeater(Lines)
            {
                Editable = false;
                field("N Orden"; Rec."N Orden")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("N Referencia"; Rec."N Referencia")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Num Factura"; Rec."Num Factura")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fecha Factura"; Rec."Fecha Factura")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fecha Operacion"; Rec."Fecha Operacion")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Concepto; Rec.Concepto)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(NIF; Rec.NIF)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Nombre; Rec.Nombre)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Imponible"; Rec."Base Imponible")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Cuota; Rec.Cuota)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Retencion; Rec.Retencion)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Total Fra"; Rec."Total Fra")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tipo Operacion"; Rec."Tipo Operacion")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Regimen; Rec."Tipo Operacion2")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Nombre Hoja Excel"; Rec."Nombre Hoja Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hoja Excel';
                    Visible = false;
                }
                field("Clausula IVA"; Rec."Clausula IVA")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Motivo Exencion"; Rec."Motivo Exencion")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tipo factura"; Rec."Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Special Scheme Code"; Rec."Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cód. de esquema especial';
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Actualizar)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Actualizar';
                Image = Refresh;
                ToolTip = 'Carga los movimientos de IVA de compra del período indicado.';
                trigger OnAction()
                begin
                    Cargar();
                end;
            }
            action(ExportarExcel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Exportar a Excel';
                Image = ExportToExcel;
                ToolTip = 'Exporta el libro a Excel con una hoja por Tipo de Operación2.';
                trigger OnAction()
                var
                    LibroIVA: Codeunit "Libro IVA";
                begin
                    LibroIVA.ExportarExcel(Rec, 'Libro Facturas Recibidas');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';
                actionref(Actualizar_Promoted; Actualizar) { }
                actionref(ExportarExcel_Promoted; ExportarExcel) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FechaDesde := CalcDate('<-CY>', WorkDate());
        FechaHasta := WorkDate();
        Cargar();
    end;

    var
        FechaDesde: Date;
        FechaHasta: Date;

    local procedure Cargar()
    var
        LibroIVA: Codeunit "Libro IVA";
        VATEntry: Record "VAT Entry";
    begin
        LibroIVA.CargarLibro(Rec, VATEntry.Type::Purchase, FechaDesde, FechaHasta);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}

page 50125 "Pagos Proyecto"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Proyecto Movimiento Pago";
    Caption = 'Pagos Vinculados al Proyecto';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de documento de compra';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de factura registrada';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el proveedor';
                }
                field("Vendor Name"; GetVendorName())
                {
                    ApplicationArea = All;
                    Caption = 'Nombre Proveedor';
                    ToolTip = 'Especifica el nombre del proveedor';
                    Editable = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del proyecto';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de tarea del proyecto';
                }
                field("Job Planning Line No."; Rec."Job Planning Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de línea de planificación del proyecto';
                }
                field("Amount"; Rec."Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Importe Asignado al Proyecto';
                    ToolTip = 'Especifica el importe de la factura asignado a este proyecto';
                    Editable = false;
                    Style = Strong;
                }
                field("Percentage"; Rec."Percentage")
                {
                    ApplicationArea = All;
                    Caption = '% Asignado';
                    ToolTip = 'Especifica el porcentaje asignado (si se usa porcentaje en lugar de importe)';
                    Editable = false;
                    Visible = false;
                }
                field("Amount Paid"; Rec."Amount Paid")
                {
                    ApplicationArea = All;
                    Caption = 'Importe Pagado del Proyecto';
                    ToolTip = 'Especifica el importe pagado correspondiente a este proyecto';
                    Editable = false;
                    Style = Favorable;
                }
                field("Base Amount Paid"; Rec."Base Amount Paid")
                {
                    ApplicationArea = All;
                    Caption = 'Importe Base Pagado';
                    ToolTip = 'Especifica el importe pagado sin IVA correspondiente a este proyecto';
                    Editable = false;
                }
                field("Amount Pending"; Rec."Amount Pending")
                {
                    ApplicationArea = All;
                    Caption = 'Importe Pendiente';
                    ToolTip = 'Especifica el importe pendiente de pago correspondiente a este proyecto';
                    Editable = false;
                    Style = Unfavorable;
                }
                field(PercentagePaid; GetPercentagePaid())
                {
                    ApplicationArea = All;
                    Caption = '% Pagado';
                    ToolTip = 'Especifica el porcentaje pagado respecto al importe asignado al proyecto';
                    Editable = false;
                    DecimalPlaces = 1 : 1;
                    Style = Strong;
                }
                field(PaymentStatus; GetPaymentStatus())
                {
                    ApplicationArea = All;
                    Caption = 'Estado de Pago';
                    ToolTip = 'Especifica el estado de pago del documento';
                    Editable = false;
                    Style = Strong;
                }
                field("Last Payment Date"; Rec."Last Payment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha Último Pago';
                    ToolTip = 'Especifica la fecha del último pago realizado';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Recargar)
            {
                ApplicationArea = All;
                Caption = 'Recargar';
                ToolTip = 'Recarga los datos de pagos';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(VerFactura)
            {
                ApplicationArea = All;
                Caption = 'Ver Factura';
                ToolTip = 'Abre la factura de compra registrada';
                Image = Document;

                trigger OnAction()
                var
                    PurchInvHeader: Record "Purch. Inv. Header";
                begin
                    if Rec."Posted Document No." <> '' then
                        if PurchInvHeader.Get(Rec."Posted Document No.") then
                            Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
                end;
            }
            action(VerPagos)
            {
                ApplicationArea = All;
                Caption = 'Ver Pagos';
                ToolTip = 'Muestra los pagos realizados para esta factura';
                Image = Payment;

                trigger OnAction()
                begin
                    ShowPayments();
                end;
            }
            action(VerLíneasProyecto)
            {
                ApplicationArea = All;
                Caption = 'Ver Líneas del Proyecto';
                ToolTip = 'Muestra las líneas de la factura relacionadas con este proyecto';
                Image = JobLines;

                trigger OnAction()
                begin
                    ShowProjectLines();
                end;
            }
            action(RecalcularPagos)
            {
                ApplicationArea = All;
                Caption = 'Recalcular Pagos';
                ToolTip = 'Recalcula los importes pagados para todas las facturas';
                Image = Refresh;

                trigger OnAction()
                var
                    ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
                begin
                    if Confirm('¿Desea recalcular los importes pagados para todas las facturas mostradas?') then begin
                        if Rec.FindSet() then
                            repeat
                                ProyectoFacturaCompra := Rec;
                                ProyectoFacturaCompra.RecalculatePaymentAmounts();
                            until Rec.Next() = 0;

                        CurrPage.Update(false);
                        Message('Recálculo completado correctamente.');
                    end;
                end;
            }
            action(ReconstruirImportes)
            {
                ApplicationArea = All;
                Caption = 'Reconstruir importes';
                ToolTip = 'Reconstruye Amount, Importe Base, importes pagados y pendientes desde la factura. Si Importe Base Pagado es 0 e Importe Pagado no, lo recalcula.';
                Image = Restore;

                trigger OnAction()
                var
                    ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
                begin
                    CurrPage.SetSelectionFilter(ProyectoFacturaCompra);
                    if Confirm('¿Reconstruir Amount, Importe Base, importes pagados y pendientes para los movimientos mostrados?') then begin
                        if ProyectoFacturaCompra.FindSet() then
                            repeat
                                ProyectoFacturaCompra.RebuildPaymentAmounts();
                            until ProyectoFacturaCompra.Next() = 0;

                        CurrPage.Update(false);
                        Message('Importes reconstruidos correctamente.');
                    end;
                end;
            }
            action("Marcar para liquidar")
            {
                ApplicationArea = All;
                Caption = 'Marcar para liquidar';
                Image = ApplyEntries;
                ToolTip = 'Marca el documento para liquidar';
                trigger OnAction()
                begin
                    MarkForLiquidation();
                end;
            }
            action("Desmarcar para liquidar")
            {
                ApplicationArea = All;
                Caption = 'Desmarcar para liquidar';
                Image = Cancel;
                ToolTip = 'Desmarca el documento para liquidar';
                trigger OnAction()
                begin
                    UnmarkForLiquidation();
                end;
            }
            action(ImportarPagares)
            {
                ApplicationArea = All;
                Caption = 'Importar pagarés (Documento a liquidar)';
                Image = Import;
                ToolTip = 'Importa desde Excel una lista de pagarés con Nº Proyecto y Nº Tarea, y rellena el campo Documento a liquidar en Proyecto Movimiento Pago. Excel: col A = Nº Proyecto, col B = Nº Tarea, col C = Nº Pagaré. Fila 1 = encabezados.';

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit ProcesosProyectos;
                begin
                    ProcesosProyectos.ImportarPagaresDocumentToLiquidate();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(MarcarParaLiquidacionAction; "Marcar para liquidar")
            {
            }
            actionref(DesmarcarParaLiquidacionAction; "Desmarcar para liquidar")
            {
            }
            actionref(VerPagosAction; VerPagos)
            {
            }
            actionref(VerLíneasProyectoAction; VerLíneasProyecto)
            {
            }
            actionref(RecalcularPagosAction; RecalcularPagos)
            {
            }
            actionref(VerFacturaAction; VerFactura)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Los datos ya están en la tabla, no necesitamos calcular
    end;

    trigger OnOpenPage()
    begin
        // El filtro debe establecerse desde donde se llama la página
        if JobNo <> '' then
            SetJobFilter(JobNo);
    end;

    procedure SetDocumento(NewDocumento: Code[20])
    begin
        GDocumento := NewDocumento;

    end;

    procedure MarkForLiquidation()
    var
        ProyectoMovimientoPago: Record "Proyecto Movimiento Pago";
    begin
        CurrPage.SetSelectionFilter(ProyectoMovimientoPago);
        if ProyectoMovimientoPago.FindSet() then
            repeat
                ProyectoMovimientoPago."Document to Liquidate" := GDocumento;
                ProyectoMovimientoPago.Modify();
            until ProyectoMovimientoPago.Next() = 0;
    end;

    procedure UnmarkForLiquidation()
    var
        ProyectoMovimientoPago: Record "Proyecto Movimiento Pago";
    begin
        CurrPage.SetSelectionFilter(ProyectoMovimientoPago);
        if ProyectoMovimientoPago.FindSet() then
            repeat
                ProyectoMovimientoPago."Document to Liquidate" := '';
                ProyectoMovimientoPago.Modify();
            until ProyectoMovimientoPago.Next() = 0;
    end;

    var
        JobNo: Code[20];
        GDocumento: Code[20];

    procedure SetJobFilter(NewJobNo: Code[20])
    begin
        JobNo := NewJobNo;
        Rec.SetRange("Job No.", NewJobNo);
    end;

    local procedure GetPercentagePaid(): Decimal
    begin
        if Rec."Amount" = 0 then
            exit(0);

        exit(Round((Rec."Amount Paid" / Rec."Amount") * 100, 0.1));
    end;

    local procedure GetPaymentStatus(): Text[50]
    begin
        if Rec."Amount Pending" <= 0 then
            exit('Pagado')
        else if Rec."Amount Paid" > 0 then
            exit('Parcialmente Pagado')
        else
            exit('Pendiente');
    end;

    local procedure GetVendorName(): Text[100]
    var
        Vendor: Record Vendor;
    begin
        if Rec."Vendor No." <> '' then
            if Vendor.Get(Rec."Vendor No.") then
                exit(Vendor.Name);
        exit('');
    end;

    local procedure ShowPayments()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PaymentEntryPage: Page "Detailed Vendor Ledg. Entries";
    begin
        if Rec."Posted Document No." = '' then begin
            Message('No hay información de pago disponible para este documento.');
            exit;
        end;

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", Rec."Posted Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", Rec."Vendor No.");

        if VendorLedgerEntry.FindFirst() then begin
            DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
            DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
            DetailedVendorLedgEntry.SetRange(Unapplied, false);
            DetailedVendorLedgEntry.SetFilter(Amount, '<0'); // Pagos

            if DetailedVendorLedgEntry.FindSet() then begin
                PaymentEntryPage.SetTableView(DetailedVendorLedgEntry);
                PaymentEntryPage.RunModal();
            end else
                Message('No se encontraron pagos para esta factura.');
        end else
            Message('No se encontró el asiento del mayor para esta factura.');
    end;

    local procedure ShowProjectLines()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvLinesPage: Page "Posted Purchase Invoice Lines";
    begin
        if Rec."Posted Document No." = '' then begin
            Message('No hay información de líneas disponible.');
            exit;
        end;

        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", Rec."Posted Document No.");
        PurchInvLine.SetRange("Job No.", Rec."Job No.");

        if PurchInvLine.FindSet() then begin
            PurchInvLinesPage.SetTableView(PurchInvLine);
            PurchInvLinesPage.RunModal();
        end else
            Message('No se encontraron líneas de esta factura relacionadas con el proyecto %1.', Rec."Job No.");
    end;
}
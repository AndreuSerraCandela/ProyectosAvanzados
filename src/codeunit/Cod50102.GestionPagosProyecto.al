codeunit 50102 "Gestión Pagos Proyecto"
{
    // Evento cuando se registra una línea de factura de compra
    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterPurchInvLineInsert(var Rec: Record "Purch. Inv. Line")
    var
        PurchaseLine: Record "Purchase Line";
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
    begin
        // Buscar la línea de compra original
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", Rec."Document No.");
        PurchaseLine.SetRange("Line No.", Rec."Line No.");

        if not PurchaseLine.FindFirst() then
            exit;

        // Si la línea tiene Job No., crear asignación automática
        if PurchaseLine."Job No." <> '' then begin
            if PurchInvHeader.Get(Rec."Document No.") then
                VendorNo := PurchInvHeader."Buy-from Vendor No.";

            ProyectoFacturaCompra.Init();
            ProyectoFacturaCompra."Document Type" := PurchaseLine."Document Type";
            ProyectoFacturaCompra."Document No." := PurchaseLine."Document No.";
            ProyectoFacturaCompra."Line No." := PurchaseLine."Line No.";
            ProyectoFacturaCompra."Job No." := PurchaseLine."Job No.";
            ProyectoFacturaCompra."Job Task No." := PurchaseLine."Job Task No.";
            ProyectoFacturaCompra."Job Planning Line No." := PurchaseLine."Job Planning Line No.";
            ProyectoFacturaCompra."Vendor No." := VendorNo;
            ProyectoFacturaCompra."Posted Document No." := Rec."Document No.";

            // Si hay campos de asignación, usarlos
            if PurchaseLine."Job Assignment Percentage" <> 0 then
                ProyectoFacturaCompra."Percentage" := PurchaseLine."Job Assignment Percentage"
            else if PurchaseLine."Job Assignment Amount" <> 0 then
                ProyectoFacturaCompra."Amount" := PurchaseLine."Job Assignment Amount"
            else
                // Si no hay asignación específica, asignar el 100% o el importe completo
                ProyectoFacturaCompra."Amount" := Rec."Line Amount";

            ProyectoFacturaCompra.Insert(true);
        end;
    end;
    // Evento cuando se registra una línea de factura de compra
    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterPurchCrMemoLineInsert(var Rec: Record "Purch. Cr. Memo Line")
    var
        PurchaseLine: Record "Purchase Line";
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
    begin
        // Buscar la línea de compra original
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", Rec."Document No.");
        PurchaseLine.SetRange("Line No.", Rec."Line No.");

        if not PurchaseLine.FindFirst() then
            exit;

        // Si la línea tiene Job No., crear asignación automática
        if PurchaseLine."Job No." <> '' then begin
            if PurchInvHeader.Get(Rec."Document No.") then
                VendorNo := PurchInvHeader."Buy-from Vendor No.";

            ProyectoFacturaCompra.Init();
            ProyectoFacturaCompra."Document Type" := PurchaseLine."Document Type";
            ProyectoFacturaCompra."Document No." := PurchaseLine."Document No.";
            ProyectoFacturaCompra."Line No." := PurchaseLine."Line No.";
            ProyectoFacturaCompra."Job No." := PurchaseLine."Job No.";
            ProyectoFacturaCompra."Job Task No." := PurchaseLine."Job Task No.";
            ProyectoFacturaCompra."Job Planning Line No." := PurchaseLine."Job Planning Line No.";
            ProyectoFacturaCompra."Vendor No." := VendorNo;
            ProyectoFacturaCompra."Posted Document No." := Rec."Document No.";

            // Si hay campos de asignación, usarlos
            if PurchaseLine."Job Assignment Percentage" <> 0 then
                ProyectoFacturaCompra."Percentage" := PurchaseLine."Job Assignment Percentage"
            else if PurchaseLine."Job Assignment Amount" <> 0 then
                ProyectoFacturaCompra."Amount" := PurchaseLine."Job Assignment Amount"
            else
                // Si no hay asignación específica, asignar el 100% o el importe completo
                ProyectoFacturaCompra."Amount" := Rec."Line Amount";

            ProyectoFacturaCompra.Insert(true);
        end;
    end;

    // Evento cuando se registra un pago
    [EventSubscriber(ObjectType::Table, Database::"Detailed Vendor Ledg. Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterDetailedVendorLedgEntryInsert(var Rec: Record "Detailed Vendor Ledg. Entry")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        TotalInvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        ProjectPaymentAmount: Decimal;
    begin
        // Solo procesar aplicaciones de pago
        if (Rec."Entry Type" <> Rec."Entry Type"::Application) or Rec.Unapplied or (Rec.Amount >= 0) then
            exit;

        // Buscar el asiento del mayor de proveedores aplicado (la factura)
        VendorLedgerEntry.SetRange("Entry No.", Rec."Applied Vend. Ledger Entry No.");
        if not VendorLedgerEntry.FindFirst() then
            exit;

        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice then
            exit;

        // Obtener importe del pago (convertir negativo a positivo)
        PaymentAmount := -Rec.Amount;

        // Buscar asignaciones de proyecto para esta factura registrada
        ProyectoFacturaCompra.SetRange("Posted Document No.", VendorLedgerEntry."Document No.");
        ProyectoFacturaCompra.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");

        if ProyectoFacturaCompra.FindSet() then begin
            // Calcular importe total de la factura registrada
            PurchInvLine.SetRange("Document No.", VendorLedgerEntry."Document No.");
            if PurchInvLine.FindSet() then
                repeat
                    TotalInvoiceAmount += PurchInvLine."Line Amount";
                until PurchInvLine.Next() = 0;

            if TotalInvoiceAmount = 0 then
                exit;

            // Distribuir el pago proporcionalmente entre proyectos
            repeat
                if ProyectoFacturaCompra."Percentage" <> 0 then
                    ProjectPaymentAmount := (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
                else
                    ProjectPaymentAmount := (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;

                ProyectoFacturaCompra."Amount Paid" += ProjectPaymentAmount;
                ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
                ProyectoFacturaCompra."Last Payment Date" := Rec."Posting Date";
                ProyectoFacturaCompra.Modify(true);
            until ProyectoFacturaCompra.Next() = 0;
        end;
    end;

    // Procedimiento para crear asignación manual desde línea de compra
    procedure CreateProjectAssignment(PurchaseLine: Record "Purch. Inv. Line"; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; Percentage: Decimal; Amount: Decimal)
    var
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        PurchaseHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
    begin
        if JobNo = '' then
            exit;

        if PurchaseHeader.Get(PurchaseLine."Document No.") then
            VendorNo := PurchaseHeader."Buy-from Vendor No.";

        ProyectoFacturaCompra.Init();
        ProyectoFacturaCompra."Document Type" := ProyectoFacturaCompra."Document Type"::Invoice;
        ProyectoFacturaCompra."Document No." := PurchaseLine."Document No.";
        ProyectoFacturaCompra."Line No." := PurchaseLine."Line No.";
        ProyectoFacturaCompra."Job No." := JobNo;
        ProyectoFacturaCompra."Job Task No." := JobTaskNo;
        ProyectoFacturaCompra."Job Planning Line No." := JobPlanningLineNo;
        ProyectoFacturaCompra."Vendor No." := VendorNo;

        if Percentage <> 0 then
            ProyectoFacturaCompra."Percentage" := Percentage
        else if Amount <> 0 then
            ProyectoFacturaCompra."Amount" := Amount
        else
            Error('Debe especificar un porcentaje o un importe.');

        if ProyectoFacturaCompra.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostDtldVendLedgEntriesOnBeforeUpdateTotalAmounts', '', false, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforeUpdateTotalAmounts(var GenJnlLine: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntryNo: Integer;
        PurchaseLine: Record "Purch. Inv. Line";
    begin
        VendLedgEntryNo := DtldVendLedgEntry."Vendor Ledger Entry No.";
        if VendLedgEntry.Get(VendLedgEntryNo) then begin
            PurchaseLine.SetRange("Document No.", VendLedgEntry."Document No.");
            if PurchaseLine.FindFirst() then
                repeat
                    CreateProjectAssignment(PurchaseLine, PurchaseLine."Job No.", PurchaseLine."Job Task No.", PurchaseLine."Job Planning Line No.", 100, PurchaseLine."Amount");
                until PurchaseLine.Next() = 0;
        end;

    end;
}

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
    // [EventSubscriber(ObjectType::Table, Database::"Detailed Vendor Ledg. Entry", 'OnAfterInsertEvent', '', false, false)]
    // local procedure OnAfterDetailedVendorLedgEntryInsert(var Rec: Record "Detailed Vendor Ledg. Entry")
    // var
    //     VendorLedgerEntry: Record "Vendor Ledger Entry";
    //     ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
    //     PurchInvLine: Record "Purch. Inv. Line";
    //     PurchInvHeader: Record "Purch. Inv. Header";
    //     TotalInvoiceAmount: Decimal;
    //     PaymentAmount: Decimal;
    //     ProjectPaymentAmount: Decimal;
    // begin
    //     // Solo procesar aplicaciones de pago
    //     if (Rec."Entry Type" <> Rec."Entry Type"::Application) or Rec.Unapplied or (Rec.Amount >= 0) then
    //         exit;

    //     // Buscar el asiento del mayor de proveedores aplicado (la factura)
    //     VendorLedgerEntry.SetRange("Entry No.", Rec."Applied Vend. Ledger Entry No.");
    //     if not VendorLedgerEntry.FindFirst() then
    //         exit;

    //     if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice then
    //         exit;

    //     // Obtener importe del pago (convertir negativo a positivo)
    //     PaymentAmount := -Rec.Amount;

    //     // Buscar asignaciones de proyecto para esta factura registrada
    //     ProyectoFacturaCompra.SetRange("Posted Document No.", VendorLedgerEntry."Document No.");
    //     ProyectoFacturaCompra.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
    //     ProyectoFacturaCompra.SetRange("Document Type", ProyectoFacturaCompra."Document Type"::Invoice);
    //     ProyectoFacturaCompra.SetRange("Document No.", PurchaseLine."Document No.");
    //     ProyectoFacturaCompra.Setrange("Line No.", PurchaseLine."Line No.");
    //     ProyectoFacturaCompra.Setrange("Job No.", JobNo);
    //     ProyectoFacturaCompra.Setrange("Job Task No.", JobTaskNo);
    //     ProyectoFacturaCompra.Setrange("Job Planning Line No.", JobPlanningLineNo);
    //     ProyectoFacturaCompra.SetRange("Entry No.", "Entry No.");
    //     ProyectoFacturaCompra.DeleteAll();
    //     if ProyectoFacturaCompra.FindSet() then begin
    //         // Calcular importe total de la factura registrada
    //         PurchInvLine.SetRange("Document No.", VendorLedgerEntry."Document No.");
    //         if PurchInvLine.FindSet() then
    //             repeat
    //                 TotalInvoiceAmount += PurchInvLine."Line Amount";
    //             until PurchInvLine.Next() = 0;

    //         if TotalInvoiceAmount = 0 then
    //             exit;

    //         // Distribuir el pago proporcionalmente entre proyectos
    //         repeat
    //             if ProyectoFacturaCompra."Percentage" <> 0 then
    //                 ProjectPaymentAmount := (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
    //             else
    //                 ProjectPaymentAmount := (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;

    //             ProyectoFacturaCompra."Amount Paid" += ProjectPaymentAmount;
    //             ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
    //             ProyectoFacturaCompra."Last Payment Date" := Rec."Posting Date";
    //             ProyectoFacturaCompra.Modify(true);
    //         until ProyectoFacturaCompra.Next() = 0;
    //     end;
    //end;

    // Procedimiento para crear asignación manual desde línea de compra
    procedure CreateProjectAssignment(PurchaseLine: Record "Purch. Inv. Line"; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; Percentage: Decimal; Amount: Decimal; EntryNo: Integer)
    var
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        ProyectoFacturaCompraOld: Record "Proyecto Movimiento Pago";
        PurchaseHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        Importe: Decimal;
        JobPlaningLine: Record "Job Planning Line";
        AmoindPaid: Decimal;
    begin
        if JobNo = '' then
            exit;

        if PurchaseHeader.Get(PurchaseLine."Document No.") then
            VendorNo := PurchaseHeader."Buy-from Vendor No.";
        ProyectoFacturaCompra.SetRange("Document Type", ProyectoFacturaCompra."Document Type"::Invoice);
        ProyectoFacturaCompra.SetRange("Document No.", PurchaseLine."Document No.");
        ProyectoFacturaCompra.Setrange("Line No.", PurchaseLine."Line No.");
        ProyectoFacturaCompra.Setrange("Job No.", JobNo);
        ProyectoFacturaCompra.Setrange("Job Task No.", JobTaskNo);
        ProyectoFacturaCompra.Setrange("Job Planning Line No.", JobPlanningLineNo);
        ProyectoFacturaCompra.SetRange("Entry No.", EntryNo);
        ProyectoFacturaCompra.DeleteAll();
        ProyectoFacturaCompra.SetRange("Entry No.", 0);
        ProyectoFacturaCompra.DeleteAll();
        ProyectoFacturaCompra.Init();
        ProyectoFacturaCompra."Document Type" := ProyectoFacturaCompra."Document Type"::Invoice;
        ProyectoFacturaCompra."Document No." := PurchaseLine."Document No.";
        ProyectoFacturaCompra."Line No." := PurchaseLine."Line No.";
        ProyectoFacturaCompra."Job No." := JobNo;
        ProyectoFacturaCompra."Job Task No." := JobTaskNo;
        ProyectoFacturaCompra."Job Planning Line No." := JobPlanningLineNo;
        ProyectoFacturaCompra."Vendor No." := VendorNo;
        ProyectoFacturaCompra."Entry No." := EntryNo;


        if Percentage <> 0 then
            ProyectoFacturaCompra.Validate("Percentage", Percentage)

        else if Amount <> 0 then
            ProyectoFacturaCompra.Validate("Amount", Amount)
        else
            Error('Debe especificar un porcentaje o un importe.');
        ProyectoFacturaCompra."Amount Paid" := Amount;
        ProyectoFacturaCompraOld.SetRange("Document Type", ProyectoFacturaCompra."Document Type");
        ProyectoFacturaCompraOld.SetRange("Document No.", ProyectoFacturaCompra."Document No.");
        ProyectoFacturaCompraOld.Setrange("Line No.", PurchaseLine."Line No.");
        ProyectoFacturaCompraOld.Setrange("Job No.", JobNo);
        ProyectoFacturaCompraOld.Setrange("Job Task No.", JobTaskNo);
        ProyectoFacturaCompraOld.Setrange("Job Planning Line No.", JobPlanningLineNo);
        ProyectoFacturaCompraOld.SetFilter("Entry No.", '<>%1', EntryNo);
        If ProyectoFacturaCompraOld.FindFirst() Then
            repeat
                Importe += ProyectoFacturaCompraOld."Amount Paid";
            Until ProyectoFacturaCompraOld.Next() = 0;
        AmoindPaid += Importe;
        If JobPlaningLine.Get(JobNo, JobTaskNo, JobPlanningLineNo) Then
            ProyectoFacturaCompra."Amount Pending" := JobPlaningLine."total Cost" - AmoindPaid;
        ProyectoFacturaCompra.Insert;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostEmployeeOnAfterPostDtldEmplLedgEntries', '', false, false)]
    local procedure OnPostEmployeeOnAfterPostDtldEmplLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var DtldLedgEntryInserted: Boolean)
    var
        EmplEntry: Record "Employee Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        Employee: Record Employee;
    begin
        EmpLEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
        if EmplEntry.FindFirst() then
            repeat
                if Employee.Get(EmplEntry."Employee No.") then
                    repeat
                        JobPlanningLine.SetRange("No.", Employee."Resource No.");
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
                        JobPlanningLine.SetRange("Document Date", CalcDate('<CM+1D-1m>', EmplEntry."Posting Date"), CalcDate('<CM>', EmplEntry."Posting Date"));

                        if JobPlanningLine.Get(Employee."Job No.", Employee."Job Task No.", Employee."Job Planning Line No.") then
                            CreateProjectAssignment(JobPlanningLine, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job Planning Line No.", 0, JobPlanningLine."Amount", JobPlanningLine."Entry No.");
                    until JobPlanningLine.Next() = 0;

            until GLEntry.Next() = 0;

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
            If DtldVendLedgEntry."Entry Type" = DtldVendLedgEntry."Entry Type"::Application Then begin
                //PurchaseLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                PurchaseLine.SetRange("Document No.", VendLedgEntry."Document No.");
                if PurchaseLine.FindFirst() then
                    repeat
                        CreateProjectAssignment(PurchaseLine, PurchaseLine."Job No.", PurchaseLine."Job Task No.", PurchaseLine."Job Planning Line No.", 0, PurchaseLine."Amount", VendLedgEntry."Entry No.");
                    until PurchaseLine.Next() = 0;
            end;
        end;

    end;
}

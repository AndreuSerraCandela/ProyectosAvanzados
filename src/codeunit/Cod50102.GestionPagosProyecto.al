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

    /// <summary>
    /// Genera movimientos de empleado para líneas de planificación de proyecto relacionadas con el recurso del empleado
    /// </summary>
    procedure GenerateEmployeeEntriesForJobPlanningLines(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        Employee: Record Employee;
        JobPlanningLine: Record "Job Planning Line";
    begin
        if not Employee.Get(EmployeeLedgerEntry."Employee No.") then
            exit;

        if Employee."Resource No." = '' then
            exit;

        // Buscar líneas de planificación de tipo Resource relacionadas con el recurso del empleado
        // que sean de tipo Billable o Both Budget and Billable y que no tengan Employee Entry No. asignado
        JobPlanningLine.SetRange("No.", Employee."Resource No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.SetRange("Employee Entry No.", 0);
        JobPlanningLine.SetRange("Usage Link", true);

        if JobPlanningLine.FindSet() then
            repeat
                // Crear movimiento de empleado para esta línea de planificación
                CreateEmployeeEntryFromJobPlanningLine(JobPlanningLine, EmployeeLedgerEntry);
            until JobPlanningLine.Next() = 0;
    end;

    /// <summary>
    /// Crea un movimiento de empleado desde una línea de planificación y un registro en ProyectoFacturaCompra
    /// </summary>
    local procedure CreateEmployeeEntryFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; SourceEmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        NewEmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        // Verificar que no exista ya un movimiento para esta línea
        if JobPlanningLine."Employee Entry No." <> 0 then
            exit;

        // Crear nuevo movimiento de empleado basado en el movimiento fuente
        NewEmployeeLedgerEntry.Init();
        NewEmployeeLedgerEntry."Employee No." := SourceEmployeeLedgerEntry."Employee No.";
        NewEmployeeLedgerEntry."Posting Date" := SourceEmployeeLedgerEntry."Posting Date";
        NewEmployeeLedgerEntry."Document Type" := SourceEmployeeLedgerEntry."Document Type";
        NewEmployeeLedgerEntry."Document No." := SourceEmployeeLedgerEntry."Document No.";
        NewEmployeeLedgerEntry."Currency Code" := SourceEmployeeLedgerEntry."Currency Code";
        NewEmployeeLedgerEntry.Amount := JobPlanningLine."Total Cost (LCY)";
        NewEmployeeLedgerEntry."Remaining Amount" := NewEmployeeLedgerEntry.Amount;
        NewEmployeeLedgerEntry."Original Amount" := NewEmployeeLedgerEntry.Amount;
        NewEmployeeLedgerEntry."Job No." := JobPlanningLine."Job No.";
        NewEmployeeLedgerEntry."Job Task No." := JobPlanningLine."Job Task No.";
        NewEmployeeLedgerEntry."Job Planning Line No." := JobPlanningLine."Line No.";
        NewEmployeeLedgerEntry.Insert(true);

        // Actualizar la línea de planificación con el número de movimiento de empleado
        JobPlanningLine."Employee Entry No." := NewEmployeeLedgerEntry."Entry No.";
        JobPlanningLine.Modify();

        // Crear registro en ProyectoFacturaCompra para esta línea
        CreateProyectoFacturaCompraFromEmployeeEntry(NewEmployeeLedgerEntry, JobPlanningLine);
    end;

    /// <summary>
    /// Crea un registro en ProyectoFacturaCompra desde un movimiento de empleado
    /// </summary>
    local procedure CreateProyectoFacturaCompraFromEmployeeEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; JobPlanningLine: Record "Job Planning Line")
    var
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
    begin
        // Verificar que no exista ya un registro para esta combinación
        ProyectoFacturaCompra.SetRange("Document Type", ProyectoFacturaCompra."Document Type"::" ");
        ProyectoFacturaCompra.SetRange("Document No.", EmployeeLedgerEntry."Document No.");
        ProyectoFacturaCompra.SetRange("Line No.", 0);
        ProyectoFacturaCompra.SetRange("Job No.", JobPlanningLine."Job No.");
        ProyectoFacturaCompra.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        ProyectoFacturaCompra.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        ProyectoFacturaCompra.SetRange("Entry No.", EmployeeLedgerEntry."Entry No.");

        if ProyectoFacturaCompra.FindFirst() then
            exit;

        // Crear nuevo registro
        ProyectoFacturaCompra.Init();
        ProyectoFacturaCompra."Document Type" := ProyectoFacturaCompra."Document Type"::" ";
        ProyectoFacturaCompra."Document No." := EmployeeLedgerEntry."Document No.";
        ProyectoFacturaCompra."Line No." := 0;
        ProyectoFacturaCompra."Job No." := JobPlanningLine."Job No.";
        ProyectoFacturaCompra."Job Task No." := JobPlanningLine."Job Task No.";
        ProyectoFacturaCompra."Job Planning Line No." := JobPlanningLine."Line No.";
        ProyectoFacturaCompra."Entry No." := EmployeeLedgerEntry."Entry No.";
        ProyectoFacturaCompra."Amount" := JobPlanningLine."Total Cost (LCY)";
        ProyectoFacturaCompra."Amount Paid" := 0;
        ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount";
        ProyectoFacturaCompra.Insert(true);
    end;

    /// <summary>
    /// Procesa un movimiento de empleado que está relacionado con un proyecto
    /// </summary>
    local procedure ProcessEmployeeEntryForProject(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if not JobPlanningLine.Get(EmployeeLedgerEntry."Job No.", EmployeeLedgerEntry."Job Task No.", EmployeeLedgerEntry."Job Planning Line No.") then
            exit;

        // Actualizar la línea de planificación con el número de movimiento de empleado si no está asignado
        if JobPlanningLine."Employee Entry No." = 0 then begin
            JobPlanningLine."Employee Entry No." := EmployeeLedgerEntry."Entry No.";
            JobPlanningLine.Modify();
        end;

        // Crear o actualizar registro en ProyectoFacturaCompra
        CreateProyectoFacturaCompraFromEmployeeEntry(EmployeeLedgerEntry, JobPlanningLine);
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

                    // if JobPlanningLine.Get(EmplEntry."Job No.", EmplEntry."Job Task No.", EmplEntry."Job Planning Line No.") then
                    //     CreateProjectAssignment(JobPlanningLine, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job Planning Line No.", 0, JobPlanningLine."Amount", JobPlanningLine."Entry No.");
                    until JobPlanningLine.Next() = 0;

            until EmplEntry.Next() = 0;

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

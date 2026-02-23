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
            else begin
                // Si no hay asignación específica, asignar el 100% o el importe completo
                ProyectoFacturaCompra."Amount" := Rec."Amount Including VAT";
                ProyectoFacturaCompra."Base Amount" := Rec.Amount;
            end;
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
            if PurchaseLine."Job Assignment Percentage" <> 0 then begin
                ProyectoFacturaCompra."Percentage" := PurchaseLine."Job Assignment Percentage";
                PurchaseLine."Job Assignment Amount" := Rec."Amount Including VAT" * PurchaseLine."Job Assignment Percentage" / 100;
            end;
            if PurchaseLine."Job Assignment Amount" <> 0 then begin
                ProyectoFacturaCompra."Amount" := PurchaseLine."Job Assignment Amount";
                ProyectoFacturaCompra."Base Amount" := PurchaseLine."Job Assignment Amount" / (1 + PurchaseLine."VAT %" / 100);
            end else begin
                // Si no hay asignación específica, asignar el 100% o el importe completo
                ProyectoFacturaCompra."Amount" := Rec."Amount Including VAT";
                ProyectoFacturaCompra."Base Amount" := Rec.Amount;
            end;

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
    procedure CreateProjectAssignment(PurchaseLine: Record "Purch. Inv. Line"; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; Percentage: Decimal; Amount: Decimal; BaseAmount: Decimal; EntryNo: Integer)
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
        ProyectoFacturaCompra."Base Amount" := BaseAmount;
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
        ProyectoFacturaCompra."Base Amount Pending" := ProyectoFacturaCompra."Base Amount" - ProyectoFacturaCompra."Base Amount Paid";
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
        ProyectoFacturaCompra."Base Amount" := JobPlanningLine."Total Cost (LCY)";
        ProyectoFacturaCompra."Base Amount Paid" := 0;
        ProyectoFacturaCompra."Base Amount Pending" := ProyectoFacturaCompra."Amount";
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
                        CreateProjectAssignment(PurchaseLine, PurchaseLine."Job No.", PurchaseLine."Job Task No.", PurchaseLine."Job Planning Line No.", 0, PurchaseLine."Amount Including VAT", PurchaseLine.Amount, VendLedgEntry."Entry No.");
                    until PurchaseLine.Next() = 0;
            end;
        end;

    end;

    /// <summary>
    /// Reconstruye la tabla Proyecto Movimiento Pago comparando con Job Ledger Entry (tipo Uso):
    /// - Añade movimientos que están en JLE Usage y no en Pagos Proyecto.
    /// - Rellena Amount y Base Amount si están a 0 (desde factura o JLE).
    /// - Si Base Amount Paid está relleno, recalcula Amount Pending y Base Amount Pending.
    /// </summary>
    procedure RebuildTablaPagosProyectoDesdeJobLedger(var Addidos: Integer; var Actualizados: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        Pago: Record "Proyecto Movimiento Pago";
    begin
        Addidos := 0;
        Actualizados := 0;

        // 1) Añadir movimientos que están en JLE (Usage) y no en Proyecto Movimiento Pago
        JobLedgerEntry.Reset();
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        if JobLedgerEntry.FindSet() then
            repeat
                Pago.Reset();
                Pago.SetRange("Document No.", JobLedgerEntry."Document No.");
                Pago.SetRange("Job No.", JobLedgerEntry."Job No.");
                Pago.SetRange("Job Task No.", JobLedgerEntry."Job Task No.");
                //Pago.SetRange("Job Planning Line No.", JobLedgerEntry."Job Planning Line No.");
                if not Pago.FindFirst() then begin
                    CrearPagoDesdeJobLedgerEntry(JobLedgerEntry, Pago);
                    Addidos += 1;
                end;
            until JobLedgerEntry.Next() = 0;

        // 2) Rellenar Amount y Base Amount en 0 desde factura o JLE
        Pago.Reset();
        if Pago.FindSet() then
            repeat
                if (Pago.Amount = 0) or (Pago."Base Amount" = 0) then begin
                    RellenarAmountYBaseAmountSiCero(Pago);
                    Actualizados += 1;
                end;
            until Pago.Next() = 0;

        // 3) Si Base Amount Paid está relleno, recalcular pendientes
        Pago.Reset();
        Pago.SetFilter("Base Amount Paid", '<>0');
        if Pago.FindSet() then
            repeat
                Pago."Amount Pending" := Pago.Amount - Pago."Amount Paid";
                Pago."Base Amount Pending" := Pago."Base Amount" - Pago."Base Amount Paid";
                Pago.Modify(true);
                Actualizados += 1;
            until Pago.Next() = 0;
    end;

    local procedure CrearPagoDesdeJobLedgerEntry(JobLedgerEntry: Record "Job Ledger Entry"; var Pago: Record "Proyecto Movimiento Pago")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Amnt: Decimal;
        EntryNo: Integer;
        BaseAmnt: Decimal;
    begin
        Pago.Init();
        if PurchInvHeader.Get(JobLedgerEntry."Document No.") then begin
            Pago."Document Type" := Pago."Document Type"::Invoice;
            Pago."Vendor No." := PurchInvHeader."Buy-from Vendor No.";
            Pago."Posted Document No." := JobLedgerEntry."Document No.";
        end else
            Pago."Document Type" := Pago."Document Type"::" ";

        Pago."Document No." := JobLedgerEntry."Document No.";
        Pago."Line No." := 0;
        Pago."Job No." := JobLedgerEntry."Job No.";
        Pago."Job Task No." := JobLedgerEntry."Job Task No.";
        Pago."Job Planning Line No." := 10000;//JobLedgerEntry."Job Planning Line No.";
        Pago."Entry No." := 0;

        if JobLedgerEntry."Bruto Factura" <> 0 then
            Amnt := JobLedgerEntry."Bruto Factura"
        else
            Amnt := JobLedgerEntry."Total Cost (LCY)";
        if JobLedgerEntry."Neto Factura" <> 0 then
            BaseAmnt := JobLedgerEntry."Neto Factura"
        else
            BaseAmnt := JobLedgerEntry."Total Cost";

        Pago.Amount := Amnt;
        Pago."Base Amount" := BaseAmnt;
        Pago."Amount Paid" := 0;
        Pago."Amount Pending" := Amnt;
        Pago."Base Amount Paid" := 0;
        Pago."Base Amount Pending" := BaseAmnt;
        EntryNo := Pago."Entry No.";
        repeat
            EntryNo += 1;
            Pago."Entry No." := EntryNo;
        until Pago.Insert(true);

    end;

    local procedure RellenarAmountYBaseAmountSiCero(var Pago: Record "Proyecto Movimiento Pago")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if (Pago."Posted Document No." <> '') and ((Pago.Amount = 0) or (Pago."Base Amount" = 0)) then begin
            PurchInvLine.SetRange("Document No.", Pago."Posted Document No.");
            PurchInvLine.SetRange("Line No.", Pago."Line No.");
            PurchInvLine.SetRange("Job No.", Pago."Job No.");
            PurchInvLine.SetRange("Job Task No.", Pago."Job Task No.");
            if PurchInvLine.FindFirst() then begin
                Pago.Amount := 0;
                Pago."Base Amount" := 0;
                repeat
                    Pago.Amount += PurchInvLine."Amount Including VAT";
                    Pago."Base Amount" += PurchInvLine."Line Amount";

                until PurchInvLine.Next() = 0;
            end else begin
                // Sin línea con ese Line No.; intentar primera línea del documento
                JobLedgerEntry.SetRange("Document No.", Pago."Document No.");
                JobLedgerEntry.SetRange("Job No.", Pago."Job No.");
                JobLedgerEntry.SetRange("Job Task No.", Pago."Job Task No.");
                JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
                if JobLedgerEntry.FindFirst() then begin
                    Pago.Amount := 0;
                    Pago."Base Amount" := 0;
                    repeat
                        Pago.Amount += JobLedgerEntry."Bruto Factura";
                        Pago."Base Amount" += JobLedgerEntry."Neto Factura";
                    until JobLedgerEntry.Next() = 0;
                end;
            end;
        end;



        Pago."Amount Pending" := Pago.Amount - Pago."Amount Paid";
        Pago."Base Amount Pending" := Pago."Base Amount" - Pago."Base Amount Paid";
        Pago.Modify(true);
    end;
}

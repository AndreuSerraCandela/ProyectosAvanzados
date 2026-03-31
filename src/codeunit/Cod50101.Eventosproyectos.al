codeunit 50302 "Eventos-proyectos"
{
    Permissions = TableData "G/L Entry" = rimd, Tabledata "Job Ledger Entry" = rimd, TableData "Job Register" = rimd, TableData "Proyecto Movimiento Pago" = ri, TableData "Employee Ledger Entry" = r;
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnGenProdPostingGroupOnBeforeValidate, '', false, false)]
    local procedure OnGenProdPostingGroupOnBeforeValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var GenProdPostingGroup: Record "Gen. Product Posting Group"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterGLFinishPosting, '', false, false)]
    local procedure OnAfterGLFinishPosting(GLEntry: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line"; var IsTransactionConsistent: Boolean; FirstTransactionNo: Integer; var GLRegister: Record "G/L Register"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ProyectoMovimientoPago: Record "Proyecto Movimiento Pago";
        AmountToApply: Decimal;
        HasEmplEntry: Boolean;
    begin
        // Solo si la línea es de pago y no es movimiento de proveedor
        if GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment then
            exit;
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then
            exit;
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor Then Exit;


        // Comprobar si hay mov de proyecto con este Entry No. (Job Ledger Entry con Ledger EntryNo. = G/L Entry No.)
        JobLedgerEntry.SetRange("Ledger Entry No.", GLEntry."Entry No.");
        if not JobLedgerEntry.FindFirst() then
            exit;

        // Evitar duplicados: ya existe un mov de pago para este Entry No.
        ProyectoMovimientoPago.SetRange("Entry No.", GLEntry."Entry No.");
        if ProyectoMovimientoPago.FindFirst() then
            exit;

        // Obtener importe y datos del movimiento de empleado si existe (mismo Entry No.)
        HasEmplEntry := EmployeeLedgerEntry.Get(GLEntry."Entry No.");
        AmountToApply := Abs(GLEntry.Amount);

        if AmountToApply = 0 then
            exit;

        // Generar el mov de pago correspondiente
        ProyectoMovimientoPago.Init();
        ProyectoMovimientoPago."Document Type" := ProyectoMovimientoPago."Document Type"::" ";
        ProyectoMovimientoPago."Document No." := GLEntry."Document No.";
        ProyectoMovimientoPago."Line No." := GLEntry."Entry No.";
        ProyectoMovimientoPago."Job No." := JobLedgerEntry."Job No.";
        ProyectoMovimientoPago."Job Task No." := JobLedgerEntry."Job Task No.";
        if HasEmplEntry then
            ProyectoMovimientoPago."Job Planning Line No." := EmployeeLedgerEntry."Job Planning Line No."
        else
            ProyectoMovimientoPago."Job Planning Line No." := 0;
        ProyectoMovimientoPago."Entry No." := GLEntry."Entry No.";
        ProyectoMovimientoPago."Job Entry No." := JobLedgerEntry."Entry No.";
        ProyectoMovimientoPago."Amount Paid" := AmountToApply;
        ProyectoMovimientoPago."Base Amount Paid" := AmountToApply;
        ProyectoMovimientoPago."Posted Document No." := GLEntry."Document No.";
        ProyectoMovimientoPago.Producción := JobLedgerEntry.Producción;

        If ProyectoMovimientoPago.Insert(true) Then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnBeforeUpdateAndDeleteLines, '', false, false)]
    local procedure OnBeforeUpdateAndDeleteLines(var GenJournalLine: Record "Gen. Journal Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    var
        ProcesosProyectos: Codeunit "ProcesosProyectos";
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        Fecha: Date;
        DocNoAnterior: Code[20];
        FechaAnterior: Date;
    begin
        If GenJournalLine.FindFirst() then
            if GenJournalLine."Source Code" = 'NOMINAS' then begin
                DocNo := GenJournalLine."Document No.";
                Fecha := GenJournalLine."Posting Date";
                ProcesosProyectos.CrearMovimientosEmpleadosDesdeDiario(DocNo, Fecha);
            end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnBeforeTestSalesHeader', '', false, false)]
    local procedure OnBeforeTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean; var JobPlanningLine: Record "Job Planning Line")
    begin
        IsHandled := true;
    end;
    //Añadir Que se rellene el campo Job Task No. de gl entry en la codeunit 12
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterCopyGLEntryFromGenJnlLine, '', false, false)]
    local procedure OnAfterCopyGLEntryFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Job No." <> '' then begin
            GLEntry."Job No." := GenJournalLine."Job No.";
            GLEntry."Job Task No." := GenJournalLine."Job Task No.";
        end;
    end;

    /// <summary>
    /// Rellena Neto Factura, Bruto Factura, IVA e IRPF en Job Ledger Entry (desde factura compra si aplica, si no desde Total Cost/Total Price).
    /// Se llama desde el evento OnBeforeApplyUsageLink del codeunit "Job Jnl.-Post Line" (ProcesosProyectos).
    /// </summary>
    procedure DatosFactura(var Rec: Record "Job Ledger Entry")
    var
        PurchaseInvLine: Record "Purch. Inv. Line";
        PurchaseCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchaseInvHeader: Record "Purch. Inv. Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
        GLEntry: Record "G/L Entry";
        ItLedgerEntry: Record "Value Entry";
        JobPlaningLineInvoice: Record "Job Planning Line";
        MovRetencion: Record "Payments Retention Ledger Ent.";
        PagoProyecto: Record "Proyecto Movimiento Pago";
        jobledgerentry: Record "Job Ledger Entry" temporary;
    begin

        If Rec.FindSet() then
            repeat
                jobledgerentry := Rec;
                jobledgerentry.Insert();
            until Rec.Next() = 0;
        if jobledgerentry.FindSet() then
            repeat
                Rec.Get(jobledgerentry."Entry No.");
                If Rec."Ledger Entry Type" = Rec."Ledger Entry Type"::Item then begin
                    ItLedgerEntry.SetRange("Item Ledger Entry No.", Rec."Ledger Entry No.");
                    ItLedgerEntry.FindFirst();
                    If ItLedgerEntry."Document Type" = ItLedgerEntry."Document Type"::"Purchase Invoice" then
                        PurchaseInvLine.Get(itledgerentry."Document No.", itledgerentry."Document Line No.");
                    If ItLedgerEntry."Document Type" = ItLedgerEntry."Document Type"::"Purchase Credit Memo" then
                        PurchaseCrMemoLine.Get(itledgerentry."Document No.", itledgerentry."Document Line No.");
                end;
                If PurchaseInvLine."Line No." <> 0 then begin
                    Rec."Neto Factura" := PurchaseInvLine.Amount;
                    Rec."Bruto Factura" := PurchaseInvLine."Amount Including VAT";
                    Rec."IGIC O IVA" := PurchaseInvLine."VAT %";
                    Rec."Importe IGIC O IVA" := PurchaseInvLine."Amount Including VAT" - PurchaseInvLine.Amount;
                    rec.IRPF := PurchaseInvLine."Retention Amount (IRPF)";
                    Rec."Document Line No." := PurchaseInvLine."Line No.";
                    Rec."Amount Pending" := Rec."Bruto Factura";
                    Rec."Base Amount Pending" := Rec."Neto Factura";
                    Rec.Modify(false);
                    //exit;
                end;
                if PurchaseCrMemoLine."Line No." <> 0 then begin
                    Rec."Neto Factura" := -PurchaseCrMemoLine.Amount;
                    Rec."Bruto Factura" := -PurchaseCrMemoLine."Amount Including VAT";
                    Rec."IGIC O IVA" := (PurchaseCrMemoLine."VAT %");
                    Rec."Importe IGIC O IVA" := -(PurchaseCrMemoLine."Amount Including VAT" - PurchaseCrMemoLine.Amount);
                    rec.IRPF := -PurchaseCrMemoLine."Retention Amount (IRPF)";
                    Rec."Amount Pending" := Rec."Bruto Factura";
                    Rec."Base Amount Pending" := Rec."Neto Factura";
                    Rec."Document Line No." := PurchaseCrMemoLine."Line No.";
                    Rec.Modify(false);
                    //exit;
                end;
                //Error('No se ha encontrado la factura o la nota de crédito');

                // if PurchaseInvHeader.Get(Rec."Document No.") then begin
                //     PurchaseInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
                //     Rec."Neto Factura" := PurchaseInvHeader.Amount;
                //     Rec."Bruto Factura" := PurchaseInvHeader."Amount Including VAT";
                //     Rec."IGIC O IVA" := PurchaseInvHeader."Amount Including VAT" - PurchaseInvHeader.Amount;
                //     MovRetencion.SetRange("Document Type", MovRetencion."Document Type"::Invoice);
                //     MovRetencion.SetRange("Document No.", Rec."Document No.");
                //     if MovRetencion.FindFirst() then
                //         Rec."IRPF" := MovRetencion.Amount
                //     else
                //         Rec."IRPF" := 0;
                //     PagoProyecto.SetRange("Document No.", Rec."Document No.");
                //     PagoProyecto.SetRange("Job No.", Rec."Job No.");
                //     PagoProyecto.SetRange("Job Task No.", Rec."Job Task No.");
                //     If PagoProyecto.Count = 1 Then
                //         if PagoProyecto.FindFirst() then begin
                //             if PagoProyecto."Job Entry No." = 0 then begin
                //                 PagoProyecto."Job Entry No." := Rec."Entry No.";
                //                 PagoProyecto.Modify(false);
                //             end;
                //         end;
                //     If Rec."Entry No." <> 0 Then
                //         Rec.Modify(false);
                // end else begin
                //     Rec."Neto Factura" := Rec."Total Cost";
                //     Rec."Bruto Factura" := Rec."Total Cost (LCY)";
                //     // IVA/IRPF: de momento 0; rellenar desde fuente (ej. extensión Job Journal Line) si se necesita
                //     Rec."IGIC O IVA" := 0;
                //     Rec."Importe IGIC O IVA" := 0;
                //     Rec."IRPF" := 0;
                //     If Rec."Entry No." <> 0 Then
                //         Rec.Modify(false);
                // end;
                Commit();
                liquidarPago(Rec);
            until jobledgerentry.Next() = 0;
    end;

    procedure LiquidarPago(var JobLedgerEntry: Record "Job Ledger Entry")
    begin
        JobLedgerEntry.CalcFields("Amount Paid", "Base Amount Paid");
        JobLedgerEntry."Amount Pending" := JobLedgerEntry."Bruto Factura" - JobLedgerEntry."Amount Paid";
        JobLedgerEntry."Base Amount Pending" := JobLedgerEntry."Neto Factura" - JobLedgerEntry."Base Amount Paid";
        JobLedgerEntry.Modify();
    end;

    /// <summary>
    /// Crea un registro en Proyecto Movimiento Pago con tipo documento blanco para cada Job Ledger Entry seleccionado
    /// que aún no tenga un movimiento de pago. Solo genera cuando no existe ya un Pago con ese Job Entry No.
    /// </summary>
    procedure GenerarMovDePago(var JobLedgerEntry: Record "Job Ledger Entry")
    var
        Pago: Record "Proyecto Movimiento Pago";
    begin
        if not JobLedgerEntry.FindSet() then
            exit;
        repeat
            Pago.Reset();
            Pago.SetRange("Job Entry No.", JobLedgerEntry."Entry No.");
            if not Pago.FindFirst() then
                if not ProvieneDeFacturaCompra(JobLedgerEntry) then
                    CrearPagoTipoBlanco(JobLedgerEntry);
        until JobLedgerEntry.Next() = 0;
    end;

    local procedure ProvieneDeFacturaCompra(JobLedgerEntry: Record "Job Ledger Entry"): Boolean
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        if PurchInvLine.Get(JobLedgerEntry."Document No.", JobLedgerEntry."Document Line No.") then
            exit(true);
        if PurchCrMemoLine.Get(JobLedgerEntry."Document No.", JobLedgerEntry."Document Line No.") then
            exit(true);
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterPostSalesDoc, '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        Cantidad: Decimal;
        Venta: Decimal;
        EntryNo: Integer;
        SalesLine: Record "Sales Invoice Line";
        RegistroProyectos: Record "Job Register";
        Desde: Integer;
        IdJobRegister: Integer;
        Hasta: Integer;
    begin
        if not SalesHeader."Importar desde excel" then
            exit;
        if JobLedgerEntry.FindLast() then
            EntryNo := JobLedgerEntry."Entry No." + 1
        else
            EntryNo := 1;
        Desde := EntryNo;
        SalesLine.SetRange("Document No.", SalesInvHdrNo);
        if SalesLine.FindFirst() then
            repeat
                if SalesLine."Job No." <> '' then begin

                    JobLedgerEntry.Init();
                    JobLedgerEntry."Line Type" := JobLedgerEntry."Line Type"::Billable;
                    JobLedgerEntry."Job No." := SalesLine."Job No.";
                    JobLedgerEntry."Job Task No." := SalesLine."Job Task No.";
                    JobLedgerEntry."Posting Date" := SalesHeader."Posting Date";
                    JobLedgerEntry."Document No." := SalesInvHdrNo;

                    JobLedgerEntry.Type := JobLedgerEntry.Type::Item;
                    JobLedgerEntry."No." := SalesLine."No.";
                    JobLedgerEntry.Description := SalesLine.Description;

                    Cantidad := -SalesLine.Quantity;
                    if Cantidad = 0 then
                        Cantidad := -1;
                    JobLedgerEntry.Quantity := Cantidad;

                    Venta := SalesLine."Line Amount";
                    if Venta <> 0 then begin
                        JobLedgerEntry."Unit Price" := Abs(Venta / JobLedgerEntry.Quantity);
                        JobLedgerEntry."Total Price" := -Venta;
                        JobLedgerEntry."Dimension Set ID" := SalesLine."Dimension Set ID";
                        JobLedgerEntry."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
                        JobLedgerEntry."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
                        JobLedgerEntry."Entry Type" := JobLedgerEntry."Entry Type"::Sale;
                        JobLedgerEntry."Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
                        JobLedgerEntry."Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
                        JobLedgerEntry."Line Amount" := -SalesLine."Line Amount";
                        JobLedgerEntry."Line Amount (LCY)" := -SalesLine."Line Amount";
                        JobLedgerEntry."Unit Price (LCY)" := SalesLine."Unit Price";
                        JobLedgerEntry."Total Price (LCY)" := -SalesLine."Line Amount";

                        JobLedgerEntry."Unit of Measure Code" := SalesLine."Unit of Measure Code";
                    end;

                    repeat
                        JobLedgerEntry."Entry No." := EntryNo;
                        EntryNo += 1;
                    until JobLedgerEntry.INSERT(true);
                end;
            until SalesLine.Next() = 0;
        if RegistroProyectos.FindLast() then
            IdJobRegister := RegistroProyectos."No." + 1
        else
            IdJobRegister := 1;
        RegistroProyectos.Init();

        RegistroProyectos."No." := IdJobRegister;
        RegistroProyectos."Creation Date" := Today;
        RegistroProyectos."Creation Time" := Time;
        RegistroProyectos."From Entry No." := Desde;
        RegistroProyectos."To Entry No." := EntryNo - 1;
        RegistroProyectos."User ID" := UserId;
        RegistroProyectos.Insert();
    end;

    local procedure CrearPagoTipoBlanco(JobLedgerEntry: Record "Job Ledger Entry")
    var
        Pago: Record "Proyecto Movimiento Pago";
    begin
        Pago.Init();
        Pago."Document Type" := Pago."Document Type"::" ";
        Pago."Document No." := JobLedgerEntry."Document No.";
        Pago."Line No." := JobLedgerEntry."Entry No.";
        Pago."Job No." := JobLedgerEntry."Job No.";
        Pago."Job Task No." := JobLedgerEntry."Job Task No.";
        Pago."Job Planning Line No." := 0;
        Pago."Entry No." := 0;
        Pago."Job Entry No." := JobLedgerEntry."Entry No.";
        Pago."Posted Document No." := JobLedgerEntry."Document No.";
        if JobLedgerEntry."Facturado Contra" <> '' then
            Pago."Vendor No." := CopyStr(JobLedgerEntry."Facturado Contra", 1, MaxStrLen(Pago."Vendor No."))
        else
            if JobLedgerEntry."NombreProveedor o Empleado" <> '' then
                Pago."Vendor No." := CopyStr(JobLedgerEntry."NombreProveedor o Empleado", 1, MaxStrLen(Pago."Vendor No."));
        Pago.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Vendor Invoice No.', false, false)]
    LOCAL PROCEDURE Table38_OnValidateVendorInvoiceNo(VAR Rec: Record "Purchase Header"; VAR xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    var
        Vendor: Record Vendor;
    begin
        If Vendor.Get(Rec."Buy-from Vendor No.")
        then
            Rec."Posting Description" := Copystr(FORMAT(Rec."Document Type") + ' ' + Rec."Vendor Invoice No." + ' ' + Vendor.Name, 1, MaxStrLen(Rec."Posting Description"))
        else
            Rec."Posting Description" := FORMAT(Rec."Document Type") + ' ' + Rec."Vendor Invoice No.";
    END;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", OnAfterFromPurchaseLineToJnlLine, '', false, false)]
    local procedure OnAfterFromPurchaseLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchLine: Record "Purchase Line"; SourceCode: Code[10])
    var
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";

    begin

        // ProyectoFacturaCompra.Init();
        // ProyectoFacturaCompra."Document Type" := PurchHeader."Document Type"::Invoice;
        // if PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo" then
        //     ProyectoFacturaCompra."Document No." := PurchCrMemoHeader."No."
        // else
        //     ProyectoFacturaCompra."Document No." := PurchInvHeader."No.";
        // ProyectoFacturaCompra."Line No." := PurchLine."Line No.";
        // ProyectoFacturaCompra."Job No." := PurchLine."Job No.";
        // ProyectoFacturaCompra."Job Task No." := PurchLine."Job Task No.";
        // ProyectoFacturaCompra."Job Planning Line No." := PurchLine."Job Planning Line No.";
        // ProyectoFacturaCompra."Vendor No." := PurchHeader."Buy-from Vendor No.";
        // ProyectoFacturaCompra."Posted Document No." := ProyectoFacturaCompra."Document No.";
        // ProyectoFacturaCompra."Amount" := PurchLine."Amount Including VAT";//-PurchLine."Retention Amount (IRPF)";
        // ProyectoFacturaCompra."Base Amount" := PurchLine.Amount;
        // ProyectoFacturaCompra."Amount Paid" := 0;
        // ProyectoFacturaCompra."Base Amount Paid" := 0;
        // ProyectoFacturaCompra."Amount Pending" := PurchLine."Amount Including VAT";
        // ProyectoFacturaCompra."Base Amount Pending" := PurchLine.Amount;
        // ProyectoFacturaCompra."Last Payment Date" := 0D;
        // If PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo" then begin
        //     //girar los importes
        //     ProyectoFacturaCompra."Amount" := -ProyectoFacturaCompra."Amount";
        //     ProyectoFacturaCompra."Base Amount" := -ProyectoFacturaCompra."Base Amount";
        //     ProyectoFacturaCompra."Amount Pending" := -ProyectoFacturaCompra."Amount Pending";
        //     ProyectoFacturaCompra."Base Amount Pending" := -ProyectoFacturaCompra."Base Amount Pending";
        // end;

        // ProyectoFacturaCompra.Insert(true);
        JobJnlLine."Neto Factura" := PurchLine.Amount;
        JobJnlLine."Bruto Factura" := PurchLine."Amount Including VAT";
        JobJnlLine."Importe IGIC O IVA" := PurchLine."Amount Including VAT" - PurchLine.Amount;
        JobJnlLine."IGIC O IVA" := PurchLine."VAT %";
        JobJnlLine.IRPF := PurchLine."Retention Amount (IRPF)";
        JobJnlLine."Document Line No." := PurchLine."Line No.";
        JobJnlLine."Job Planning Line No. Aux" := PurchLine."Job Planning Line No. Aux";
        JobJnlLine."Producción" := PurchLine."Producción";
        JobJnlLine."NombreProveedor o Empleado" := PurchHeader."Buy-from Vendor No.";



    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", OnAfterRunCode, '', false, false)]
    local procedure OnAfterRunCode(var JobJournalLine: Record "Job Journal Line"; var JobLedgEntryNo: Integer; var JobRegister: Record "Job Register"; var NextEntryNo: Integer)
    var
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        jobledgerentry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobLink: Record "Job Usage Link";
    begin
        ProyectoFacturaCompra.SetRange("Document No.", JobJournalLine."Document No.");
        ProyectoFacturaCompra.SetRange("Line No.", JobJournalLine."Document Line No.");
        if ProyectoFacturaCompra.FindFirst() then begin
            ProyectoFacturaCompra."Job Entry No." := JobLedgEntryNo;
            ProyectoFacturaCompra.Modify(false);
        end;
        JobLedgerEntry.Get(JobLedgEntryNo);
        JobLedgerEntry."Neto Factura" := JobJournalLine."Neto Factura";
        JobLedgerEntry."Bruto Factura" := JobJournalLine."Bruto Factura";
        jobledgerentry.CalcFields("Amount Paid", "Base Amount Paid");
        JobLedgerEntry."Amount Pending" := JobJournalLine."Bruto Factura" - JobLedgerEntry."Amount Paid";
        JobLedgerEntry."Base Amount Pending" := JobJournalLine."Neto Factura" - JobLedgerEntry."Base Amount Paid";
        JobLedgerEntry."IGIC O IVA" := JobJournalLine."IGIC O IVA";
        JobLedgerEntry."Importe IGIC O IVA" := JobJournalLine."Importe IGIC O IVA";
        JobLedgerEntry.IRPF := JobJournalLine.IRPF;
        JobLedgerEntry."Document Line No." := JobJournalLine."Document Line No.";
        If JobJournalLine."Producción" then begin
            JobLedgerEntry.Producción := true;
        end else begin

            if JobPlanningLine.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.") then
                JobLedgerEntry.Producción := JobPlanningLine.Producción;
            // AssignDimensionProduction(JobLedgerEntry, JobPlanningLine);
        end;

        if JobJournalLine."Job Planning Line No. Aux" = 0 Then
            JobJournalLine."Job Planning Line No. Aux" := JobPlanningLine."Line No.";
        JobLedgerEntry."Job Planning Line No. Aux" := JobJournalLine."Job Planning Line No. Aux";
        JobLedgerEntry.Modify(false);
        if not JobLink.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No. Aux", JobLedgerEntry."Entry No.") then begin
            JobLink.Init();
            JobLink."Job No." := JobJournalLine."Job No.";
            JobLink."Job Task No." := JobJournalLine."Job Task No.";
            JobLink."Line No." := JobJournalLine."Job Planning Line No. Aux";
            JobLink."Entry No." := JobLedgerEntry."Entry No.";
            JobLink.Insert(true);
        end;


    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Vendor Cr. Memo No.', false, false)]
    LOCAL PROCEDURE Table38_OnValidateVendorCRNo(VAR Rec: Record "Purchase Header"; VAR xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    var
        Vendor: Record Vendor;
    begin
        If Vendor.Get(Rec."Buy-from Vendor No.")
        then
            Rec."Posting Description" := Copystr(FORMAT(Rec."Document Type") + ' ' + Rec."Vendor Cr. Memo No." + ' ' + Vendor.Name, 1, MaxStrLen(Rec."Posting Description"))
        else
            Rec."Posting Description" := FORMAT(Rec."Document Type") + ' ' + Rec."Vendor Cr. Memo No.";


    END;


    // procedure DatosFactura(DocumentNo: Code[20])
    // var
    //     Rec: Record "Job Ledger Entry";
    //     PurchaseInvHeader: Record "Purch. Inv. Header";
    //     MovRetencion: Record "Payments Retention Ledger Ent.";
    //     PagoProyecto: Record "Proyecto Movimiento Pago";
    // begin
    //     if Rec.IsTemporary then
    //         exit;
    //     Rec.SetRange("Document No.", DocumentNo);
    //     if Rec.FindFirst() then begin
    //         If Rec."Neto Factura" <> 0 Then exit;
    //         if PurchaseInvHeader.Get(Rec."Document No.") then begin
    //             PurchaseInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
    //             Rec."Neto Factura" := PurchaseInvHeader.Amount;
    //             Rec."Bruto Factura" := PurchaseInvHeader."Amount Including VAT";
    //             Rec."IGIC O IVA" := PurchaseInvHeader."Amount Including VAT" - PurchaseInvHeader.Amount;
    //             MovRetencion.SetRange("Document Type", MovRetencion."Document Type"::Invoice);
    //             MovRetencion.SetRange("Document No.", Rec."Document No.");
    //             if MovRetencion.FindFirst() then
    //                 Rec."IRPF" := MovRetencion.Amount
    //             else
    //                 Rec."IRPF" := 0;
    //             PagoProyecto.SetRange("Document No.", Rec."Document No.");
    //             PagoProyecto.SetRange("Job No.", Rec."Job No.");
    //             PagoProyecto.SetRange("Job Task No.", Rec."Job Task No.");
    //             if PagoProyecto.FindFirst() then begin
    //                 PagoProyecto."Amount Paid" := PagoProyecto."Amount Paid";
    //                 PagoProyecto."Base Amount Pending" := PagoProyecto."Base Amount" - PagoProyecto."Base Amount Paid";
    //                 PagoProyecto."Amount Pending" := PagoProyecto."Amount" - PagoProyecto."Amount Paid";

    //                 if PagoProyecto."Amount Pending" = 0 Then begin
    //                     PagoProyecto."Base Amount Paid" := PagoProyecto."Base Amount";
    //                     PagoProyecto."Base Amount Pending" := 0;
    //                 end;
    //                 // no dejar que los importes pagados sean mallores que la factura
    //                 if PagoProyecto."Amount Paid" > PagoProyecto.Amount then begin
    //                     PagoProyecto."Amount Paid" := PagoProyecto.Amount;
    //                     PagoProyecto."Amount Pending" := 0;
    //                 end;
    //                 if PagoProyecto."Base Amount Paid" > PagoProyecto."Base Amount" then begin
    //                     PagoProyecto."Base Amount Paid" := PagoProyecto."Base Amount";
    //                     PagoProyecto."Base Amount Pending" := 0;
    //                 end;
    //                 PagoProyecto.Modify(false);
    //             end;
    //             If Rec."Entry No." <> 0 Then
    //                 Rec.Modify(false);
    //         end else begin
    //             Rec."Neto Factura" := Rec."Total Cost";
    //             Rec."Bruto Factura" := Rec."Total Cost (LCY)";
    //             // IVA/IRPF: de momento 0; rellenar desde fuente (ej. extensión Job Journal Line) si se necesita
    //             Rec."IGIC O IVA" := 0;
    //             Rec."Importe IGIC O IVA" := 0;
    //             Rec."IRPF" := 0;
    //             If Rec."Entry No." <> 0 Then
    //                 Rec.Modify(false);
    //         end;
    //     end;
    // end;
    procedure MarkForLiquidation(var JobLedgerEntry: Record "Job Ledger Entry")
    var
    begin
        if JobLedgerEntry.FindSet() then
            repeat
                JobLedgerEntry."Document to Liquidate" := '';
                JobLedgerEntry.Modify();
            until JobLedgerEntry.Next() = 0;
    end;

    procedure UnmarkForLiquidation(var JobLedgerEntry: Record "Job Ledger Entry")
    var
    begin
        if JobLedgerEntry.FindSet() then
            repeat
                JobLedgerEntry."Document to Liquidate" := '';
                JobLedgerEntry.Modify();
            until JobLedgerEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEvent(var Rec: Record Job)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        SetupJob: Record "Jobs Setup";
    begin
        SetupJob.Get();
        If setupJob."Dimension Proyecto" <> '' then begin
            Dimension.Get(setupJob."Dimension Proyecto");
            If Not DimensionValue.Get(SetupJob."Dimension Proyecto", Rec."No.") then begin
                DimensionValue.Validate("Dimension Code", SetupJob."Dimension Proyecto");
                DimensionValue.Validate(Code, Rec."No.");
                DimensionValue.Validate(Name, Copystr(Rec.Description, 1, MaxStrLen(DimensionValue.Name)));

                DimensionValue.Insert(true);
            end;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnCreateSalesHeaderOnBeforeCheckBillToCustomerNo', '', false, false)]
    local procedure OnCreateSalesHeaderOnBeforeCheckBillToCustomerNo(var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
        If JobPlanningLine."Bill-to Customer No." <> '' then begin
            IsHandled := true;
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader.Validate("Sell-to Customer No.", JobPlanningLine."Bill-to Customer No.");
            SalesHeader.Validate("Bill-to Customer No.", JobPlanningLine."Bill-to Customer No.");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Post-Line", 'OnPostInvoiceContractLineOnBeforeCheckBillToCustomer', '', false, false)]
    local procedure OnPostInvoiceContractLineOnBeforeCheckBillToCustomer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnBeforeUpdateSalesHeader', '', false, false)]
    local procedure OnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean);
    var
        Customer: Record Customer;
        UserSetupMgt: Codeunit "User Setup Management";
    begin
        if SalesHeader."Bill-to Customer No." <> Job."Bill-to Customer No." then begin
            IsHandled := true;
            Customer.Get(SalesHeader."Bill-to Customer No.");
            SalesHeader."Sell-to Customer Templ. Code" := '';
            SalesHeader."Sell-to Customer Name" := Customer.Name;
            SalesHeader."Sell-to Customer Name 2" := Customer."Name 2";
            SalesHeader."Sell-to Phone No." := Customer."Phone No.";
            SalesHeader."Sell-to E-Mail" := Customer."E-Mail";
            SalesHeader."Sell-to Address" := Customer.Address;
            SalesHeader."Sell-to Address 2" := Customer."Address 2";
            SalesHeader."Sell-to City" := Customer.City;
            SalesHeader."Sell-to Post Code" := Customer."Post Code";
            SalesHeader."Sell-to County" := Customer.County;
            SalesHeader."Sell-to Country/Region Code" := Customer."Country/Region Code";
            SalesHeader."Sell-to Contact" := Customer.Contact;
            SalesHeader."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
            SalesHeader.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
            SalesHeader."Tax Area Code" := Customer."Tax Area Code";
            SalesHeader."Tax Liable" := Customer."Tax Liable";
            SalesHeader."VAT Registration No." := Customer."VAT Registration No.";
            SalesHeader."VAT Country/Region Code" := Customer."Country/Region Code";
            SalesHeader."Shipping Advice" := Customer."Shipping Advice";
            SalesHeader."Responsibility Center" := UserSetupMgt.GetRespCenter(0, Customer."Responsibility Center");
            SalesHeader.SetBillToCustomerAddressFieldsFromCustomer(Customer);
        end;
    end;


    [EventSubscriber(ObjectType::Page, Page::"Job Planning Lines", 'OnCreateSalesInvoiceOnBeforeAction', '', false, false)]
    local procedure OnCreateSalesInvoiceOnBeforeAction(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean);
    begin
        JobPlanningLine.SetRange("Bill-to Customer No.", JobPlanningLine."Bill-to Customer No.");
    end;


    /// <summary>
    /// OnRunOnBeforePostPurchLineMyb.
    /// </summary>
    /// <param name="PurchLine">VAR Record "Purchase Line".</param>
    /// <param name="PurchHeader">VAR Record "Purchase Header".</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnRunOnBeforePostPurchLine', '', false, false)]
    procedure OnRunOnBeforePostPurchLineMyb(var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header")
    var
        JobSetup: Record "Jobs Setup";
    begin
        if JobSetup."Cód. Proyecto Obligatorio" then begin
            if (PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo") or
                (PurchLine."Document Type" = PurchLine."Document Type"::Invoice) or
                (PurchLine."Document Type" = PurchLine."Document Type"::Order) then begin
                if not (PurchLine.Type = PurchLine.Type::" ") then begin
                    PurchLine.TestField(PurchLine."Job No.");
                end;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    procedure OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", PurchInvHdrNo);
        if JobLedgerEntry.FindFirst() then
            repeat
                datosfactura(JobLedgerEntry);
            until JobLedgerEntry.Next() = 0;
    end;

    //OnAfterSetPurchaseLineFilters
    //     [EventSubscriber(ObjectType::Codeunit, Codeunit::"Lines Instruction Mgt.", 'OnAfterSetPurchaseLineFilters', '', false, false)]
    //     local procedure OnAfterSetPurchaseLineFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    //     var
    //         JobSetup: Record "Jobs Setup";
    //     begin
    //         /*   JobSetup.Get();
    //            if JobSetup."Cód. Proyecto Obligatorio" then
    //                PurchaseLine.SetFilter("Job No.", '<>%1', '');
    //    */

    //     end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCopyToTempLines', '', false, false)]
    local procedure OnAfterCopyToTempLines(var TempPurchLine: Record "Purchase Line" temporary)
    var
        LineaCompra: Record "Purchase Line";
        JobSetup: Record "Jobs Setup";
    begin
        JobSetup.Get();
        if JobSetup."Cód. Proyecto Obligatorio" then begin
            LineaCompra.SetRange("Document Type", TempPurchLine."Document Type");
            LineaCompra.SetRange("Document No.", TempPurchLine."Document No.");
            LineaCompra.SetFilter(LineaCompra.Type, '%1|%2|%3', LineaCompra.Type::"G/L Account", LineaCompra.Type::Item, LineaCompra.Type::Resource);
            LineaCompra.SetFilter("Job No.", '%1', '');
            if LineaCompra.FindFirst() then
                Error('El proyecto es obligatorio');
        end;

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnCreateSalesHeaderOnBeforeUpdateSalesHeader', '', false, false)]
    local procedure OnCreateSalesHeaderOnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; var Job: Record Job; var IsHandled: Boolean; JobPlanningLine: Record "Job Planning Line")
    begin
        if JobPlanningLine.Count = 1 then begin
            SalesHeader."Cod. Oferta de Proyecto" := JobPlanningLine."Cód Oferta Job";
        end else begin
            SalesHeader."Cod. Oferta de Proyecto" := Job."Cód Oferta Job";
        end;

    end;







    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnBeforeOnInsert', '', false, false)]
    procedure OnBeforeOnInsertMyB(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    var
        Job: Record Job;
    begin
        if Job.Get(JobPlanningLine."Job No.") then begin
            JobPlanningLine."Cód Oferta Job" := Job."Cód Oferta Job";
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnAfterCreateSalesLine', '', false, false)]
    local procedure OnAfterCreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Job: Record Job; var JobPlanningLine: Record "Job Planning Line")
    var
        SalesHeaderOtraEmpresa: Record "Sales Header";
        SalesLineOtraEmpresa: Record "Sales Line";
        CompanyName: Text[100];
        LineNo: Integer;
    begin
        // Si la línea de proyecto tiene rellenado el campo "Facturado Contra", cambiar las líneas de empresa
        if JobPlanningLine."Facturado Contra" <> '' then begin
            CompanyName := JobPlanningLine."Facturado Contra";

            // Cambiar a la empresa especificada
            SalesHeaderOtraEmpresa.ChangeCompany(CompanyName);
            SalesLineOtraEmpresa.ChangeCompany(CompanyName);

            // Verificar si existe la cabecera de factura en la empresa seleccionada
            SalesHeaderOtraEmpresa.SetRange("Document Type", SalesHeader."Document Type");
            SalesHeaderOtraEmpresa.SetRange("No.", SalesHeader."No.");

            if not SalesHeaderOtraEmpresa.FindFirst() then begin
                // Si no existe, crear la cabecera de factura en la empresa seleccionada
                //en lugar de pasar todos los campos, podemos igualar las variables de la cabecera de factura
                SalesHeaderOtraEmpresa := SalesHeader;
                SalesHeaderOtraEmpresa.Insert();
            end;

            // Cambiar las líneas de venta a la empresa seleccionada
            SalesLineOtraEmpresa.SetRange("Document Type", SalesLine."Document Type");
            SalesLineOtraEmpresa.SetRange("Document No.", SalesLine."Document No.");
            if not SalesLineOtraEmpresa.FindFirst() then LineNo := SalesLineOtraEmpresa."Line No." + 10000;
            SalesLineOtraEmpresa := SalesLine;
            SalesLineOtraEmpresa."Line No." := LineNo;
            SalesLineOtraEmpresa.Insert();
            SalesLine.Delete();

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterDocumentReady', '', false, false)]
    local procedure OnAfterDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        Result: JsonToken;
        ResultText: Text;
        Filters: JsonArray;
        filtro: JsonObject;
        filtros: Text;
        TokenFiltro: JsonToken;
        Impresora: Text;
        TempBlob: Codeunit "Temp Blob";
        DocumentOutStream: OutStream;
        size: Integer;
        filename: Text;
        B64: Codeunit "Base64 Convert";
        GenLedgerSetup: Record "General Ledger Setup";
        TM: Record "Tenant Media";
        File64: Text;
        Contrato: Text;
        Proyecto: Text;
        a: Integer;
        RT: Codeunit "Reporting Triggers";
        ObjectType: Option "Report","Page";
        ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml;
        Inf: Record "Company Information";
        AdjuntosInforme: Record "Adjuntos Informe";
        Id: Integer;
    begin
        //{"filterviews":[{"name":"Sales Invoice Header",
        //"tableid":112,"view":"VERSION(1) SORTING(Field3) WHERE(Field3=1(IBC24-00070),Field4=1(5228))"},
        //{"name":"CopyLoop","tableid":2000000026,"view":"VERSION(1) SORTING(Field1) WHERE(Field1=1(1))"},
        //{"name":"Sales Invoice Line","tableid":113,"view":"VERSION(1) SORTING(Field3,Field4) WHERE(Field4=1(0..44050))"},
        //{"name":"Sales Shipment Buffer","tableid":2000000026,"view":"VERSION(1) SORTING(Field1) WHERE(Field1=1(1..0))"},
        //{"name":"Textos","tableid":2000000026,"view":"VERSION(1) SORTING(Field1) WHERE(Field1=1(1..0))"},
        //{"name":"VATCounter","tableid":2000000026,"view":"VERSION(1) SORTING(Field1) WHERE(Field1=1(1..2))"},
        //{"name":"VATClauseEntryCounter","tableid":2000000026,"view":"VERSION(1) SORTING(Field1) WHERE(Field1=1(1..2))"}],
        //"version":1,"objectname":"Factura Venta","objectid":50025,"documenttype":"application/pdf","invokedby":"c25ac6d6-b4e2-4380-9ff5-a18ea44a0bf2"App
        //,"invokeddatetime":"2023-11-28T10:26:33.252+01:00","companyname":"Malla Publicidad","printername":"Bullzip PDF Printer",
        //"duplex":false,"color":false,"defaultcopies":1,"papertray":
        //{"papersourcekind":1,"paperkind":0,"landscape":false,"units":0,"height":0,"width":0},"intent":"Print",
        //"layoutmodel":"Rdlc","layoutname":"./src/report/layout/SalesInvoice.rdlc","layoutmimetype":"",
        //"layoutapplicationid":"00000000-0000-0000-0000-000000000000","reportrunid":"c08679d0-a879-4afd-a4ca-b8a63a021f0a"}
        //recuperar el objectid
        ObjectPayload.Get('objectid', Result);
        if not Evaluate(Id, Result.AsValue().AsText()) then
            exit;
        AdjuntosInforme.SetRange("No. Informe", Result.AsValue().AsInteger());
        if AdjuntosInforme.FindFirst() then begin
            // ObjectPayload.Get('filterviews', Result);
            // Filters := Result.AsArray();
            // foreach Tokenfiltro in filters do begin
            //     If filtros = '' Then begin

            //         filtro := Tokenfiltro.AsObject();
            //         If filtro.Get('view', Result) then begin
            //             Result.WriteTo(filtros);
            //             If Strpos(filtros, 'Field3=') <> 0 Then
            //                 Contrato := Copystr(Filtros, Strpos(filtros, 'Field3=') + 9, 11);
            //         end;
            //     end;

            // end;
            //If Contrato = '' Then exit;
            File64 := GuardaPdfAdjunto(AdjuntosInforme)
        end;
        If File64 = '' Then exit;
        filename := B64.ToBase64(DocumentStream);
        filename := PostDocumentos(filename, File64);
        B64.fromBase64(filename, TargetStream);
        Success := true;
    end;

    procedure PostDocumentos(base1: Text; base2: Text): Text
    Var
        Inf: Record "Company Information";
        RequestType: Option Get,patch,put,post,delete;
        Parametros: Text;
        UrlPdf: Text;
        JsonObj: JsonObject;
        JsonTexT: Text;
        ResPuestaJson: JsonObject;
        PdfToken: JsonToken;
    begin
        Inf.Get();
        if Inf."Url Pdf" <> '' then
            UrlPdf := Inf."Url Pdf"
        else
            UrlPdf := 'https://gateway.malla.es/pdf';

        jsonobj.Add('pdf1', Base1);
        jsonobj.Add('pdf2', base2);
        jsonobj.WriteTo(JsonTexT);
        ResPuestaJson.ReadFrom(RestApi(UrlPdf, RequestType::post, jSonText));
        //Obtener el valor de la key pdf
        if ResPuestaJson.Get('pdf', PdfToken) then
            exit(PdfToken.AsValue().AsText());
    end;

    /// <summary>
    /// RestApi.
    /// </summary>
    /// <param name="url">Text.</param>
    /// <param name="RequestType">Option Get,patch,put,post,delete.</param>
    /// <param name="payload">Text.</param>
    /// <returns>Return value of type Text.</returns>
    procedure RestApi(url: Text; RequestType: Option Get,patch,put,post,delete; payload: Text): Text
    var
        Ok: Boolean;
        Respuesta: Text;
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        ResponseText: Text;
        contentHeaders: HttpHeaders;
        MEDIA_TYPE: Label 'application/json';
    begin
        RequestHeaders := Client.DefaultRequestHeaders();
        //RequestHeaders.Add('Authorization', CreateBasicAuthHeader(Username, Password));

        case RequestType of
            RequestType::Get:
                Client.Get(URL, ResponseMessage);
            RequestType::patch:
                begin
                    RequestContent.WriteFrom(payload);

                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json-patch+json');

                    RequestMessage.Content := RequestContent;

                    RequestMessage.SetRequestUri(URL);
                    RequestMessage.Method := 'PATCH';

                    client.Send(RequestMessage, ResponseMessage);
                end;
            RequestType::post:
                begin
                    RequestContent.WriteFrom(payload);

                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');

                    Client.Post(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                Client.Delete(URL, ResponseMessage);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);

    end;

    local procedure GuardaPdfAdjunto(var AdjuntosInforme: Record "Adjuntos Informe"): Text
    var
        varInStream: InStream;
        varOutStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DocumentStream: OutStream;
        FullFileName: Text;
        IsHandled: Boolean;
        Base64: Codeunit "Base64 Convert";
    begin
        TempBlob.CreateOutStream(DocumentStream);
        AdjuntosInforme."Pdf Adjunto".ExportStream(DocumentStream);
        TempBlob.CreateInStream(varInStream);
        exit(Base64.ToBase64(varInStream));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateJobPlanningLineNo', '', false, false)]
    local procedure OnBeforeValidateJobPlanningLineNo(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", PurchaseLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", PurchaseLine."Job Task No.");
        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
            PurchaseLine.Type::Item:
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        end;
        JobPlanningLine.SetRange("No.", PurchaseLine."No.");
        JobPlanningLine.SetRange("Usage Link", true);
        JobPlanningLine.SetRange("System-Created Entry", false);

        if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then begin
            PurchaseLine."Producción" := JobPlanningLine."Producción";

            purchaseLine.Validate("Job Planning Line No.", 0);
            PurchaseLine."Job Planning Line No. Aux" := JobPlanningLine."Line No.";
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, 'Job Planning Line No.', false, false)]
    local procedure OnBeforeEventValidateJobPlanningLineNo(var Rec: Record "Purchase Line"; xRec: Record "Purchase Line"; CurrFieldNo: Integer);
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if Rec."Job Planning Line No." = 0 Then exit;
        if CurrFieldNo = Rec.FieldNo("Job Planning Line No.") then begin
            JobPlanningLine.Get(Rec."Job No.", Rec."Job Task No.", Rec."Job Planning Line No.");
            Rec."Producción" := JobPlanningLine."Producción";
            Rec."Job Planning Line No. Aux" := JobPlanningLine."Line No.";
            Rec."Job Planning Line No." := 0;
        end;
    end;

    //     internal procedure AssignDimensionProduction(var JobLedgerEntry: Record "Job Ledger Entry"; JobPlanningLine: Record "Job Planning Line")
    //     var
    //         JobsSetup: Record "Jobs Setup";
    //         GlSetup: Record "General Ledger Setup";
    //         DimensionValue: Record "Dimension Value";
    // Dim:Integer;
    //     begin
    //         if JobLedgerEntry.Producción then begin
    //         JobsSetup.Get();
    //         if JobsSetup."Dim. Cód. Producción" = '' then
    //             Error('Debe indicar el Cód. Dimensión Producción en Configuración de proyectos (Jobs Setup).');
    //         if JobsSetup."Dim. Valor Producción" = '' then
    //             Error('Debe indicar el Valor Dimensión Producción en Configuración de proyectos (Jobs Setup).');
    //         if not DimensionValue.Get(JobsSetup."Dim. Cód. Producción", JobsSetup."Dim. Valor Producción") then
    //             Error('El valor de dimensión %1 no existe para la dimensión %2. Revise la configuración de proyectos o cree el valor en Valores de dimensión.',
    //                 JobsSetup."Dim. Valor Producción", JobsSetup."Dim. Cód. Producción");
    //         GlSetup.Get();
    //         If GlSetup."Global Dimension 1 Code"=JobsSetup."Dim. Cód. Producción" then
    //           Dim:=1;
    //         If GlSetup."Global Dimension 2 Code"=JobsSetup."Dim. Cód. Producción" then
    //           Dim:=2;
    //         If GlSetup."Shortcut Dimension 3 Code"=JobsSetup."Dim. Cód. Producción" then
    //           Dim:=3;
    //         If GlSetup."Shortcut Dimension 4 Code"=JobsSetup."Dim. Cód. Producción" then
    //           Dim:=4;
    //        ValidateShortcutDimCode(Dim, JobsSetup."Dim. Valor Producción", JobLedgerEntry);
    //         end;
    //     end;
    //      procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20];Var JobLedgerEntry: Record "Job Ledger Entry")
    //     var
    //       DimMgt: Codeunit "DimensionManagement";  
    //     begin
    //         DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, JobLedgerEntry."Dimension Set ID");
    //     end;




    /// <summary>
    /// Borra los registros de Gen. Product Posting Group pasados (p. ej. con SetSelectionFilter)
    /// y sus configuraciones en General Posting Setup.
    /// </summary>
    procedure DeleteSelectedGenProdPostingGroupsWithSetup(var GenProdPostingGroup: Record "Gen. Product Posting Group"): Integer
    var
        GenPostingSetup: Record "General Posting Setup";
        GenProdPostingGroupToDelete: Record "Gen. Product Posting Group";
        CodesToDelete: List of [Code[20]];
        CodeValue: Code[20];
        Count: Integer;
    begin
        if not GenProdPostingGroup.FindSet() then
            exit(0);
        repeat
            CodesToDelete.Add(GenProdPostingGroup.Code);
        until GenProdPostingGroup.Next() = 0;

        Count := 0;
        foreach CodeValue in CodesToDelete do begin
            if GenProdPostingGroupToDelete.Get(CodeValue) then begin
                GenPostingSetup.SetRange("Gen. Prod. Posting Group", CodeValue);
                GenPostingSetup.DeleteAll(true);
                GenProdPostingGroupToDelete.Delete(true);
                Count += 1;
            end;
        end;
        exit(Count);
    end;

    var
        myInt: Integer;
}
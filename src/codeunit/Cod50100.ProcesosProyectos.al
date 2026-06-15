/// <summary>
/// Codeunit ProcesosProyectos (ID 50100).
/// </summary>
/// 

codeunit 50301 "ProcesosProyectos"
{
    Permissions = TableData "G/L Budget Entry" = rimd, TableData "Job Ledger Entry" = rimd,
    Tabledata "Employee Ledger Entry" = rimd, TableData "Job Register" = rimd, TableData "Proyecto Movimiento Pago" = rimd;
    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Crea una nueva línea en Job Register con el No. siguiente.
    /// From Entry No. = último To Entry No. del registro anterior (si existe).
    /// To Entry No. = último Entry No. de Job Ledger Entry.
    /// </summary>
    procedure ActualizarUltimoRegistroJob()
    var
        JobRegister: Record "Job Register";
        JobLedgerEntry: Record "Job Ledger Entry";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
        NextNo: Integer;
    begin
        // Último To Entry No. del registro anterior (para From Entry No.)
        if JobRegister.FindLast() then begin
            NextNo := JobRegister."No." + 1;
            FromEntryNo := JobRegister."To Entry No.";
        end else begin
            NextNo := 1;
            FromEntryNo := 0;
        end;

        // Último movimiento de Job Ledger Entry (para To Entry No.)
        if JobLedgerEntry.FindLast() then
            ToEntryNo := JobLedgerEntry."Entry No."
        else
            ToEntryNo := 0;

        if ToEntryNo = 0 then
            Error('No hay movimientos en Job Ledger Entry.');

        if FromEntryNo >= ToEntryNo then
            Error('El último registro ya incluye hasta el movimiento %1. No hay nuevos movimientos que registrar.', ToEntryNo);

        JobRegister.Init();
        JobRegister."No." := NextNo;
        JobRegister."From Entry No." := FromEntryNo + 1;
        JobRegister."To Entry No." := ToEntryNo;
        JobRegister."Creation Date" := Today();
        JobRegister."User ID" := UserId;
        //JobRegister."Source Code" := CopyStr('JOB-JNL', 1, MaxStrLen(JobRegister."Source Code"));
        JobRegister.Insert(true);

        Message('Registro de proyectos creado: No. %1, From Entry No. %2, To Entry No. %3.', JobRegister."No.", JobRegister."From Entry No.", JobRegister."To Entry No.");
    end;

    /// <summary>
    /// Importa desde Excel una lista de pagarés con Nº Proyecto y Nº Tarea; actualiza Proyecto Movimiento Pago filtrando por proyecto y tarea y rellenando Document to Liquidate con el nº de pagaré.
    /// Excel: fila 1 = encabezados (Nº Proyecto, Nº Tarea, Nº Pagaré). Desde fila 2: col A = Job No., col B = Job Task No., col C = Document to Liquidate.
    /// </summary>
    procedure ImportarPagaresDocumentToLiquidate()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        JobLedgerEntry: Record "Job Ledger Entry";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DocumentToLiquidate: Code[20];
        RowNo: Integer;
        FilasProcesadas: Integer;
        RegistrosActualizados: Integer;
        FileName: Text[250];
        InStream: InStream;
        SheetName: Text[250];
        MsgImportacion: Label 'Importación finalizada. Filas procesadas: %1. Registros de Proyecto Movimiento Pago actualizados: %2.';
    begin
        if not UploadIntoStream('Seleccionar archivo Excel de pagarés', '', 'Archivos Excel (*.xlsx)|*.xlsx|Todos los archivos (*.*)|*.*', FileName, InStream) then
            exit;

        TempExcelBuffer.DeleteAll();
        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStream);
        TempExcelBuffer.OpenBookStream(InStream, SheetName);
        TempExcelBuffer.ReadSheet();

        FilasProcesadas := 0;
        RegistrosActualizados := 0;

        // Iterar por filas: columna 1 tiene una celda por fila
        TempExcelBuffer.SetRange("Column No.", 1);
        TempExcelBuffer.SetFilter("Row No.", '>1');
        while TempExcelBuffer.FindFirst() do begin
            RowNo := TempExcelBuffer."Row No.";
            JobNo := '';
            JobTaskNo := '';
            DocumentToLiquidate := '';

            TempExcelBuffer.SetRange("Row No.", RowNo);
            if TempExcelBuffer.FindSet() then
                repeat
                    case TempExcelBuffer."Column No." of

                        1:
                            DocumentToLiquidate := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(DocumentToLiquidate));
                        2:
                            JobNo := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(JobNo));
                        3:
                            JobTaskNo := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(JobTaskNo));
                    end;
                until TempExcelBuffer.Next() = 0;

            if (JobNo <> '') and (JobTaskNo <> '') and (DocumentToLiquidate <> '') then begin
                JobLedgerEntry.SetRange("Job No.", JobNo);
                JobLedgerEntry.SetRange("Job Task No.", JobTaskNo);
                if JobLedgerEntry.FindSet() then
                    repeat
                        JobLedgerEntry."Document to Liquidate" := DocumentToLiquidate;
                        JobLedgerEntry.Modify();
                        RegistrosActualizados += 1;
                    until JobLedgerEntry.Next() = 0;
                FilasProcesadas += 1;
            end;

            // Siguiente fila: excluir las ya procesadas
            TempExcelBuffer.SetRange("Column No.", 1);
            TempExcelBuffer.SetFilter("Row No.", '>%1', RowNo);
        end;

        Message(MsgImportacion, FilasProcesadas, RegistrosActualizados);
    end;

    var
        NoOfPurchaseLinesCreated: Integer;
        DimSetIDArr: array[8] of Integer;
        Job: Record Job;
        Factor: Integer;
        DimMgt: Codeunit DimensionManagement;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        Cust: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        Text000: Label 'The lines were successfully transferred to an invoice.';
        Text000_1: Label 'The lines were successfully transferred to an order.';
        Text001: Label 'The lines were not transferred to an invoice.';
        Text001_1: Label 'The lines were not transferred to an invoice.';

        Text002: Label 'There was no %1 with a %2 larger than 0. No lines were transferred.';
        Text003: Label '%1 may not be lower than %2 and may not exceed %3.';
        Text004: Label 'You must specify Invoice No. or New Invoice.';
        Text005: Label 'You must specify Credit Memo No. or New Invoice.';
        Text007: Label 'You must specify %1.';
        TransferExtendedText: Codeunit "Transfer Extended Text";
        JobInvCurrency: Boolean;
        UpdateExchangeRates: Boolean;
        Text008: Label 'The lines were successfully transferred to a credit memo.';
        Text009: Label 'The selected planning lines must have the same %1.';
        Text010: Label 'The currency dates on all planning lines will be updated based on the invoice posting date because there is a difference in currency exchange rates. Recalculations will be based on the Exch. Calculation setup for the Cost and Price values for the job. Do you want to continue?';
        Text011: Label 'The currency exchange rate on all planning lines will be updated based on the exchange rate on the sales invoice. Do you want to continue?';
        Text012: Label 'The %1 %2 does not exist anymore. A printed copy of the document was created before the document was deleted.', Comment = 'The Sales Invoice Header 103001 does not exist in the system anymore. A printed copy of the document was created before deletion.';
        ErrVatPostingSetup: Label 'Fila %1: No se encontró configuración de IVA para el grupo de producto %2 con un %3 de IVA.';
        Prov: Record Vendor;

    //OnCreateSalesInvoiceOnBeforeRunReport
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnCreateSalesInvoiceOnBeforeRunReport', '', false, false)]
    local procedure OnCreateSalesInvoiceOnBeforeRunReport_MyB(var JobPlanningLine: Record "Job Planning Line"; var Done: Boolean; var NewInvoice: Boolean; var PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean; CrMemo: Boolean)
    var
        JobTask: Record "Job Task";
        JobTaskDependiente: Record "Job Task";
    begin
        JobTask.SetRange("Job No.", JobPlanningLine."Job No.");
        JobTask.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        if JobTask.FindFirst() then begin
            if JobTask.Dependencia <> '' then begin
                JobTaskDependiente.SetRange("Job No.", JobTask."Job No.");
                JobTaskDependiente.SetRange(JobTaskDependiente."Job Task No.", JobTask.Dependencia);
                if JobTaskDependiente.FindFirst() then begin
                    if not (JobTaskDependiente."Status Task" = JobTaskDependiente."Status Task"::Completada) then
                        Error('Esta tarea tiene dependencias que no estan completadas');
                end
            end;
        end;
    end;
    //report 1094 "Job Transfer to Sales Invoice"
    [EventSubscriber(ObjectType::Report, Report::"Job Transfer to Sales Invoice", 'OnBeforeSetCustomer', '', false, false)]
    procedure OnBeforeSetCustomer(JobPlanningLine: Record "Job Planning Line"; var BillToCustomerNo: Code[20]; var SellToCustomerNo: Code[20]; var CurrencyCode: Code[20]; var IsHandled: Boolean)
    var
        RJob: Record job;
    begin

        if RJob.Get(JobPlanningLine."Job No.") then
            if (RJob."Bill-to Customer No." <> JobPlanningLine."Bill-to Customer No.") and (JobPlanningLine."Bill-to Customer No." <> '') then begin
                BillToCustomerNo := JobPlanningLine."Bill-to Customer No.";
                IsHandled := true;
            end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnBeforeTestSalesHeader', '', false, false)]
    local procedure OnBeforeTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean; var JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        Rcliente: Record Customer;
    begin

        if (Job."Bill-to Customer No." <> JobPlanningLine."Bill-to Customer No.") and (JobPlanningLine."Bill-to Customer No." <> '') then begin
            if Rcliente.get(JobPlanningLine."Bill-to Customer No.") then
                Job.Get(JobPlanningLine."Job No.");
            if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
                SalesHeader.TestField("Bill-to Customer No.", Rcliente."No.");
                SalesHeader.TestField("Sell-to Customer No.", Rcliente."No.");
            end else begin
                JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                SalesHeader.TestField("Bill-to Customer No.", JobTask."Bill-to Customer No.");
                SalesHeader.TestField("Sell-to Customer No.", JobTask."Sell-to Customer No.");
            end;

            if Job."Currency Code" <> '' then
                SalesHeader.TestField("Currency Code", Job."Currency Code")
            else
                if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
                    SalesHeader.TestField("Currency Code", Job."Invoice Currency Code")
                else
                    SalesHeader.TestField("Currency Code", JobTask."Invoice Currency Code");

            IsHandled := true;
        end;
    end;

    // [EventSubscriber(ObjectType::Codeunit,1012,'OnAfterRunCode','',false,false)]
    // local procedure OnAfterRunCode(var JobJournalLine: Record "Job Journal Line"; var JobLedgEntryNo: Integer; var JobRegister: Record "Job Register"; var NextEntryNo: Integer)
    // var
    // JobPlaningLine: Record "Job Planning Line";
    // begin
    //     If JobPlaningLine.get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.") Then begin
    //         JobPlaningLine.Validate(Quantity,JobPlaningLine.QB);
    //         JobPlaningLine.Modify();
    //     end;
    // end;
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterPostPurchaseDoc, '', false, false)]
    // procedure OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    // var
    //     ItemLedgerEntry: Record "Item Ledger Entry";
    //     PurchaseInvLine: Record "Purch. Inv. Line";
    //     PurchaseCrMemoLine: Record "Purch. Cr. Memo Line";
    //     PurchaseInvHeader: Record "Purch. Inv. Header";
    //     JobLedgerEntry: Record "Job Ledger Entry";
    //     MovRetencion: Record "Payments Retention Ledger Ent.";
    // begin
    //     if (PurchInvHdrNo = '') and (PurchCrMemoHdrNo = '') then
    //         exit;
    //     ItemLedgerEntry.SetRange("Document No.", PurchInvHdrNo);
    //     if not ItemLedgerEntry.FindFirst() then
    //         ItemLedgerEntry.SetRange("Document No.", PurchCrMemoHdrNo);
    //     if ItemLedgerEntry.FindFirst() then begin
    //         repeat
    //             JobLedgerEntry.SetRange("Ledger Entry Type", JobLedgerEntry."Ledger Entry Type"::Item);
    //             JobLedgerEntry.SetRange("Ledger Entry No.", ItemLedgerEntry."Entry No.");
    //             if JobLedgerEntry.FindFirst() then begin

    //                 if PurchaseInvLine.Get(JobLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.") then begin
    //                     JobLedgerEntry."Neto Factura" := PurchaseInvLine.Amount;
    //                     JobLedgerEntry."Bruto Factura" := PurchaseInvline."Amount Including VAT";
    //                     JobLedgerEntry."IGIC O IVA" := PurchaseInvline."Amount Including VAT" - PurchaseInvLine.Amount;
    //                     JobLedgerEntry.IRPF := PurchaseInvline."Retention Amount (IRPF)";
    //                     if JobLedgerEntry."Entry No." <> 0 Then
    //                         JobLedgerEntry.Modify(false);
    //                 end;
    //             end else begin
    //                 if PurchaseCrMemoLine.Get(JobLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.") then begin
    //                     JobLedgerEntry."Neto Factura" := -PurchaseCrMemoLine.Amount;
    //                     JobLedgerEntry."Bruto Factura" := -PurchaseCrMemoLine."Amount Including VAT";
    //                     JobLedgerEntry."IGIC O IVA" := -PurchaseCrMemoLine."Amount Including VAT" - PurchaseCrMemoLine.Amount;
    //                     JobLedgerEntry.IRPF := -PurchaseCrMemoLine."Retention Amount (IRPF)";
    //                     if JobLedgerEntry."Entry No." <> 0 Then
    //                         JobLedgerEntry.Modify(false);
    //                 end;
    //             end;
    //         until ItemLedgerEntry.Next() = 0;
    //         exit;
    //     end;
    //     JobLedgerEntry.SetRange("Document No.", PurchInvHdrNo);
    //     if JobLedgerEntry.FindFirst() then begin
    //         if JobLedgerEntry."Neto Factura" <> 0 Then exit;
    //         if PurchaseInvHeader.Get(JobLedgerEntry."Document No.") then begin
    //             PurchaseInvHeader.CalcFields(Amount, "Amount Including VAT");
    //             JobLedgerEntry."Neto Factura" := PurchaseInvHeader.Amount;
    //             JobLedgerEntry."Bruto Factura" := PurchaseInvHeader."Amount Including VAT";
    //             JobLedgerEntry."IGIC O IVA" := PurchaseInvHeader."Amount Including VAT" - PurchaseInvHeader.Amount;
    //             MovRetencion.SetRange("Document Type", MovRetencion."Document Type"::Invoice);
    //             MovRetencion.SetRange("Document No.", PurchInvHdrNo);
    //             if MovRetencion.FindFirst() then begin
    //                 JobLedgerEntry."IRPF" := MovRetencion.Amount;
    //             end else begin
    //                 JobLedgerEntry."IRPF" := 0;
    //             end;
    //             if JobLedgerEntry."Entry No." <> 0 Then
    //                 JobLedgerEntry.Modify(false);

    //         end else begin
    //             JobLedgerEntry."Neto Factura" := JobLedgerEntry."Total Cost";
    //             JobLedgerEntry."Bruto Factura" := JobLedgerEntry."Total Cost (LCY)";
    //             JobLedgerEntry."IGIC O IVA" := 0;
    //             JobLedgerEntry."Importe IGIC O IVA" := 0;
    //             JobLedgerEntry."IRPF" := 0;
    //             if JobLedgerEntry."Entry No." <> 0 Then
    //                 JobLedgerEntry.Modify(false);

    //         end;
    //     end;
    // end;



    //evento pn insert Job Ledger Entry
    // [EventSubscriber(ObjectType::Table, Database::"Job Ledger Entry", OnBeforeInsertEvent, '', false, false)]
    // local procedure OnBeforeInsertEvent(var Rec: Record "Job Ledger Entry"; RunTrigger: Boolean)
    // var
    //     PurchaseInvHeader: Record "Purch. Inv. Header";
    // begin
    //     if Rec.IsTemporary then
    //         exit;
    //     if Rec."Neto Factura" <> 0 Then exit;
    //     if PurchaseInvHeader.Get(Rec."Document No.") then begin
    //         PurchaseInvHeader.CalcFields(Amount, "Amount Including VAT");
    //         Rec."Neto Factura" := PurchaseInvHeader.Amount;
    //         Rec."Bruto Factura" := PurchaseInvHeader."Amount Including VAT";
    //         Rec."IGIC O IVA" := PurchaseInvHeader."Amount Including VAT" - PurchaseInvHeader.Amount;
    //         Rec."IRPF" := 0;

    //     end else begin
    //         Rec."Neto Factura" := Rec."Total Cost";
    //         Rec."Bruto Factura" := Rec."Total Cost (LCY)";
    //         // IVA/IRPF: de momento 0; rellenar desde fuente (ej. extensión Job Journal Line) si se necesita
    //         Rec."IGIC O IVA" := 0;
    //         Rec."Importe IGIC O IVA" := 0;
    //         Rec."IRPF" := 0;

    //     end;
    // end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", OnBeforeCheckQuantityPosted, '', false, false)]
    local procedure OnBeforeCheckQuantityPosted(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
        // No reducir Quantity por debajo de la cantidad ya registrada (evita "Cantidad no puede ser inferior que cantidad registrada" al facturar varias líneas de la misma tarea/proyecto)
        // if JobPlanningLine.QB >= JobPlanningLine."Qty. Posted" then
        //     JobPlanningLine.Validate(Quantity, JobPlanningLine.QB);
        IsHandled := true;
    end;
    //OnBeforeRunWithCheck OnBeforeRunWithCheck(var JobJournalLine: Record "Job Journal Line")
    //Job Jnl.-Post Line
    [EventSubscriber(ObjectType::Codeunit, 1001, 'OnBeforePostJobOnPurchaseLine', '', false, false)]
    local procedure OnBeforePostJobOnPurchaseLine(var PurchHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line"; var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean; var TempPurchaseLineJob: Record "Purchase Line"; var TempJobJournalLine: Record "Job Journal Line"; var Sourcecode: Code[10])
    var
        JobPlaningLine: Record "Job Planning Line";
    begin
        If JobPlaningLine.get(PurchLine."Job No.", PurchLine."Job Task No.", PurchLine."Job Planning Line No.") Then begin
            if PurchLine."Document Type" = PurchLine."Document Type"::Quote then begin
                JobPlaningLine."Cantidad en Oferta Compra" += PurchLine.Quantity;
                JobPlaningLine."Nº documento Compra" := PurchLine."Document No.";
            end;
            if PurchLine."Document Type" = PurchLine."Document Type"::Order then begin
                JobPlaningLine."Cantidad en Pedido Compra" += PurchLine.Quantity;
                JobPlaningLine."Nº documento Compra" := PurchLine."Document No.";
            end;
            if PurchLine."Document Type" = PurchLine."Document Type"::Invoice then begin
                JobPlaningLine."Cantidad en Factura Compra" += PurchLine.Quantity;
                JobPlaningLine."Nº documento Compra" := PurchInvHeader."No.";
                JobPlaningLine."Cantidad a tr a Factura Compra" := 0;
            end;
            if PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo" then begin
                JobPlaningLine."Cantidad en Factura Compra" -= PurchLine.Quantity;
                JobPlaningLine."Nº documento Compra" := PurchCrMemoHdr."No.";
                JobPlaningLine."Cantidad a tr a Factura Compra" := 0;
            end;

            JobPlaningLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnBeforeRunWithCheck', '', false, false)]
    local procedure OnBeforeRunWithCheck_Myb(var JobJournalLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
        JobTaskDependiente: Record "Job Task";
        Text_001: Label 'Esta tarea tiene dependencias que no estan completadas';
    begin
        JobTask.SetRange("Job No.", JobJournalLine."Job No.");
        JobTask.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        if JobTask.FindFirst() then begin
            if JobTask.Dependencia <> '' then begin
                JobTaskDependiente.SetRange("Job No.", JobTask."Job No.");
                JobTaskDependiente.SetRange(JobTaskDependiente."Job Task No.", JobTask.Dependencia);
                if JobTaskDependiente.FindFirst() then begin
                    if not (JobTaskDependiente."Status Task" = JobTaskDependiente."Status Task"::Completada) then
                        Error(Text_001);
                end
            end;
        end;
    end;

    /// <summary>
    /// CreatePurchaseInvoice.
    /// </summary>
    /// <param name="JobPlanningLine">Record "Job Planning Line".</param>
    /// <param name="CrMemo">Boolean.</param>
    procedure CreatePurchaseInvoice(JobPlanningLine: Record "Job Planning Line"; CrMemo: Boolean);
    var
        PurchaseHeader: Record "Purchase Header";

        GetPurchaseInvoiceNo: Report "Job Transf.to Purch. Invoice";
        //GetSalesCrMemoNo	Report	Job Transfer to Credit Memo	
        GetSalesCrMemoNo: Report "Job Transf Credit Memo Purch";
        Done: Boolean;
        NewInvoice: Boolean;
        PostingDate: Date;
        InvoiceNo: code[20];
        IsHandled: Boolean;

    begin
        IF NOT CrMemo THEN BEGIN
            GetPurchaseInvoiceNo.SetVendor(JobPlanningLine."Job No.");
            GetPurchaseInvoiceNo.RUNMODAL;
            IsHandled := FALSE;
            OnBeforeGetInvoiceNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
            IF NOT IsHandled THEN
                GetPurchaseInvoiceNo.GetInvoiceNo(Done, NewInvoice, PostingDate, InvoiceNo);
        END ELSE BEGIN


            GetSalesCrMemoNo.SetCustomer(JobPlanningLine."Job No.");
            GetSalesCrMemoNo.RUNMODAL;
            IsHandled := FALSE;
            OnBeforeGetCrMemoNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
            IF NOT IsHandled THEN
                GetSalesCrMemoNo.GetCreditMemoNo(Done, NewInvoice, PostingDate, InvoiceNo);

        END;

        IF Done THEN BEGIN
            IF (PostingDate = 0D) AND NewInvoice THEN
                ERROR(Text007, PurchaseHeader.FIELDCAPTION("Posting Date"));
            IF (InvoiceNo = '') AND NOT NewInvoice THEN BEGIN
                IF CrMemo THEN
                    ERROR(Text005);
                ERROR(Text004);
            END;
            CreatePurchaseInvoiceLines(JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate, CrMemo);
        end;
    end;

    /// <summary>
    /// CreatePurchaseOrder.
    /// </summary>
    /// <param name="JobPlanningLine">Record "Job Planning Line".</param>
    procedure CreatePurchaseOrder(JobPlanningLine: Record "Job Planning Line");
    var
        PurchaseHeader: Record "Purchase Header";

        GetPurchaseOrderNo: Report "Job Transf.to Purch. Order";
        //GetSalesCrMemoNo	Report	Job Transfer to Credit Memo	
        GetSalesCrMemoNo: Report "Job Transf Credit Memo Purch";
        Done: Boolean;
        NewInvoice: Boolean;
        PostingDate: Date;
        InvoiceNo: code[20];
        IsHandled: Boolean;

    begin

        GetPurchaseOrderNo.SetVendor(JobPlanningLine."Job No.");
        GetPurchaseOrderNo.RUNMODAL;
        IsHandled := FALSE;
        OnBeforeGetInvoiceNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
        IF NOT IsHandled THEN
            GetPurchaseOrderNo.GetInvoiceNo(Done, NewInvoice, PostingDate, InvoiceNo);


        IF Done THEN BEGIN
            IF (PostingDate = 0D) AND NewInvoice THEN
                ERROR(Text007, PurchaseHeader.FIELDCAPTION("Posting Date"));
            IF (InvoiceNo = '') AND NOT NewInvoice THEN BEGIN

                ERROR(Text004);
            END;
            CreatePurchaseOrderLines(JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate);
        end;
    end;
    /// <summary>
    /// CreatePurchaseOrder.
    /// </summary>
    /// <param name="JobPlanningLine">Record "Job Planning Line".</param>
    procedure CreatePurchaseQuote(JobPlanningLine: Record "Job Planning Line");
    var
        PurchaseHeader: Record "Purchase Header";

        GetPurchaseQuoteNo: Report "Job Transf.to Purch. Quote";
        //GetSalesCrMemoNo	Report	Job Transfer to Credit Memo	
        GetSalesCrMemoNo: Report "Job Transf Credit Memo Purch";
        Done: Boolean;
        NewInvoice: Boolean;
        PostingDate: Date;
        InvoiceNo: code[20];
        IsHandled: Boolean;

    begin

        GetPurchaseQuoteNo.SetVendor(JobPlanningLine."Job No.");
        GetPurchaseQuoteNo.RUNMODAL;
        IsHandled := FALSE;
        OnBeforeGetInvoiceNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
        IF NOT IsHandled THEN
            GetPurchaseQuoteNo.GetInvoiceNo(Done, NewInvoice, PostingDate, InvoiceNo);


        IF Done THEN BEGIN
            IF (PostingDate = 0D) AND NewInvoice THEN
                ERROR(Text007, PurchaseHeader.FIELDCAPTION("Posting Date"));
            IF (InvoiceNo = '') AND NOT NewInvoice THEN BEGIN

                ERROR(Text004);
            END;
            CreatePurchaseQuoteLines(JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate);
        end;
    end;

    /// <summary>
    /// CreatePurchaseOrderLines.
    /// </summary>
    /// <param name="JobNo">code[20].</param>
    /// <param name="JobPlanningLineSource">VAR Record "Job Planning Line".</param>
    /// <param name="OrderNo">Code[20].</param>
    /// <param name="NewOrder">Boolean.</param>
    /// <param name="PostingDate">Date.</param>
    procedure CreatePurchaseOrderLines(JobNo: code[20]; var JobPlanningLineSource: Record "Job Planning Line"; OrderNo: Code[20]; NewOrder: Boolean; PostingDate: Date)
    var
        Job: Record Job;
        JobInvCurrency: Boolean;
        IsHandled: Boolean;
        Cust: Record Customer;
        Prov: Record Vendor;
        // PurchaseHeader2: Record "Purchase Header";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        LineCounter: Integer;
    begin


        //OnBeforeCreatePurchaseInvoiceLines(JobPlanningLine,InvoiceNo,NewInvoice,PostingDate,CreditMemo);

        CLEARALL;
        Job.GET(JobNo);
        IF Job.Blocked = Job.Blocked::All THEN
            Job.TestBlocked;
        IF Job."Currency Code" = '' THEN
            JobInvCurrency := Job."Invoice Currency Code" <> '';
        Job.TESTFIELD("Bill-to Customer No.");

        IsHandled := FALSE;
        //OnCreateSalesInvoiceLinesOnBeforeGetCustomer(JobPlanningLine, Cust, IsHandled);
        IF NOT IsHandled THEN
            //Cust.GET(Job."Bill-to Customer No.");
            Prov.get(JobPlanningLineSource.Cod_Proveedor);

        PurchaseHeader2."Document Type" := PurchaseHeader2."Document Type"::Order;

        IF NOT NewOrder THEN
            PurchaseHeader2.GET(PurchaseHeader2."Document Type", OrderNo);

        PurchaseHeader := PurchaseHeader2;
        //JobPlanningLine.Copy(JobPlanningLineSource);
        //*myb
        JobPlanningLine.SetRange(JobPlanningLine."Job No.", JobPlanningLineSource."Job No.");
        JobPlanningLine.SetRange(JobPlanningLine."Job Task No.", JobPlanningLineSource."Job Task No.");
        //JobPlanningLine.SetRange(JobPlanningLine."Line No.", JobPlanningLineSource."Line No.");
        JobPlanningLine.SetRange(Cod_Proveedor, JobPlanningLineSource.Cod_Proveedor);
        JobPlanningLine.SetRange("Generar Compra", true);
        //MYB
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");

        IF JobPlanningLine.FIND('-') THEN;
        //     REPEAT
        //         IF TransferLine(JobPlanningLine) THEN BEGIN
        //             LineCounter := LineCounter + 1;
        //             IF JobPlanningLine."Job No." <> JobNo THEN
        //                 ERROR(Text009, JobPlanningLine.FIELDCAPTION("Job No."));
        //             IF NewOrder THEN
        //                 TestExchangeRate(JobPlanningLine, PostingDate)
        //             ELSE
        //                 TestExchangeRate(JobPlanningLine, PurchaseHeader."Posting Date");
        //         END;
        //     UNTIL JobPlanningLine.NEXT = 0;

        // IF LineCounter = 0 THEN
        //     ERROR(Text002,
        //       JobPlanningLine.TABLECAPTION,
        //       JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"));

        IF NewOrder THEN
            //CreatePurchaseHeader(Job, PostingDate, JobPlanningLine)
            CreatePurchaseHeaderOrder(Job, PostingDate, JobPlanningLine)
        ELSE
            TestPurchaseHeader(PurchaseHeader, Job, Prov."No.", JobPlanningLine.GetWorkDescription());
        IF JobPlanningLine.FIND('-') THEN
            REPEAT
                IF TransferLine(JobPlanningLine) THEN BEGIN
                    IF JobPlanningLine.Type IN [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    THEN
                        JobPlanningLine.TESTFIELD("No.");


                    //OnCreatePurchaseInvoiceLinesOnBeforeCreatePurchaseLine(JobPlanningLine, PurchaseHeader, PurchaseHeader2, NewInvoice);
                    CreatePurchaseLine(JobPlanningLine, JobPlanningLine."Line No.", JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                    /*
                                        JobPlanningLineInvoice.InitFromJobPlanningLine(JobPlanningLine);
                                        IF NewInvoice THEN
                                            JobPlanningLineInvoice.InitFromPurchase(PurchaseHeader, PostingDate, PurchaseLine."Line No.")
                                        ELSE
                                            JobPlanningLineInvoice.InitFromPurchase(PurchaseHeader, PurchaseHeader."Posting Date", PurchaseLine."Line No.");
                                        JobPlanningLineInvoice.INSERT;

                                        JobPlanningLine.UpdateQtyToTransfer;
                                        JobPlanningLine.MODIFY;
                                        */
                END;
            UNTIL JobPlanningLine.NEXT = 0;
        /*
                IF NoOfPurchaseLinesCreated = 0 THEN
                    ERROR(Text002, JobPlanningLine.TABLECAPTION, JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"));
        */

        COMMIT;
        if JobPlanningLine.FindFirst() then
            repeat
                JobPlanningLine."Generar Compra" := false;
                JobPlanningLine.Modify();
            until JobPlanningLine.Next() = 0;
        Commit();

        MESSAGE(Text000_1);

        // OnAfterCreateSalesInvoiceLines(PurchaseHeader, NewInvoice);
    end;

    /// <summary>
    /// CreatePurchaseQuoteLines.
    /// </summary>
    /// <param name="JobNo">code[20].</param>
    /// <param name="JobPlanningLineSource">VAR Record "Job Planning Line".</param>
    /// <param name="OrderNo">Code[20].</param>
    /// <param name="NewOrder">Boolean.</param>
    /// <param name="PostingDate">Date.</param>
    procedure CreatePurchaseQuoteLines(JobNo: code[20]; var JobPlanningLineSource: Record "Job Planning Line"; QuoteNo: Code[20]; NewQuote: Boolean; PostingDate: Date)
    var
        Job: Record Job;
        JobInvCurrency: Boolean;
        IsHandled: Boolean;
        Cust: Record Customer;
        Prov: Record Vendor;
        // PurchaseHeader2: Record "Purchase Header";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        LineCounter: Integer;
    begin


        //OnBeforeCreatePurchaseInvoiceLines(JobPlanningLine,InvoiceNo,NewInvoice,PostingDate,CreditMemo);

        CLEARALL;
        Job.GET(JobNo);
        IF Job.Blocked = Job.Blocked::All THEN
            Job.TestBlocked;
        IF Job."Currency Code" = '' THEN
            JobInvCurrency := Job."Invoice Currency Code" <> '';
        Job.TESTFIELD("Bill-to Customer No.");

        IsHandled := FALSE;
        //OnCreateSalesInvoiceLinesOnBeforeGetCustomer(JobPlanningLine, Cust, IsHandled);
        IF NOT IsHandled THEN
            //Cust.GET(Job."Bill-to Customer No.");
            Prov.get(JobPlanningLineSource.Cod_Proveedor);

        PurchaseHeader2."Document Type" := PurchaseHeader2."Document Type"::Quote;

        IF NOT NewQuote THEN
            PurchaseHeader2.GET(PurchaseHeader2."Document Type", QuoteNo);

        PurchaseHeader := PurchaseHeader2;
        //JobPlanningLine.Copy(JobPlanningLineSource);
        //*myb
        JobPlanningLine.SetRange(JobPlanningLine."Job No.", JobPlanningLineSource."Job No.");
        JobPlanningLine.SetRange(JobPlanningLine."Job Task No.", JobPlanningLineSource."Job Task No.");
        //JobPlanningLine.SetRange(JobPlanningLine."Line No.", JobPlanningLineSource."Line No.");
        JobPlanningLine.SetRange(Cod_Proveedor, JobPlanningLineSource.Cod_Proveedor);
        JobPlanningLine.SetRange("Generar Compra", true);
        //MYB
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");

        IF JobPlanningLine.FIND('-') THEN;
        //     REPEAT
        //         IF TransferLine(JobPlanningLine) THEN BEGIN
        //             LineCounter := LineCounter + 1;
        //             IF JobPlanningLine."Job No." <> JobNo THEN
        //                 ERROR(Text009, JobPlanningLine.FIELDCAPTION("Job No."));
        //             IF NewQuote THEN
        //                 TestExchangeRate(JobPlanningLine, PostingDate)
        //             ELSE
        //                 TestExchangeRate(JobPlanningLine, PurchaseHeader."Posting Date");
        //         END;
        //     UNTIL JobPlanningLine.NEXT = 0;

        // IF LineCounter = 0 THEN
        //     ERROR(Text002,
        //       JobPlanningLine.TABLECAPTION,
        //       JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"));

        IF NewQuote THEN
            //CreatePurchaseHeader(Job, PostingDate, JobPlanningLine)
            CreatePurchaseHeaderQuote(Job, PostingDate, JobPlanningLine)
        ELSE
            TestPurchaseHeader(PurchaseHeader, Job, Prov."No.", JobPlanningLine.GetWorkDescription());
        IF JobPlanningLine.FIND('-') THEN
            REPEAT
                IF TransferLine(JobPlanningLine) THEN BEGIN
                    IF JobPlanningLine.Type IN [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    THEN
                        JobPlanningLine.TESTFIELD("No.");


                    //OnCreatePurchaseInvoiceLinesOnBeforeCreatePurchaseLine(JobPlanningLine, PurchaseHeader, PurchaseHeader2, NewInvoice);
                    CreatePurchaseLine(JobPlanningLine, JobPlanningLine."Line No.", JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                    /*
                                        JobPlanningLineInvoice.InitFromJobPlanningLine(JobPlanningLine);
                                        IF NewInvoice THEN
                                            JobPlanningLineInvoice.InitFromPurchase(PurchaseHeader, PostingDate, PurchaseLine."Line No.")
                                        ELSE
                                            JobPlanningLineInvoice.InitFromPurchase(PurchaseHeader, PurchaseHeader."Posting Date", PurchaseLine."Line No.");
                                        JobPlanningLineInvoice.INSERT;

                                        JobPlanningLine.UpdateQtyToTransfer;
                                        JobPlanningLine.MODIFY;
                                        */
                END;
            UNTIL JobPlanningLine.NEXT = 0;
        /*
                IF NoOfPurchaseLinesCreated = 0 THEN
                    ERROR(Text002, JobPlanningLine.TABLECAPTION, JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"));
        */

        COMMIT;
        PurchaseHeader.GET(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Categorias := JobPlanningLine.Categorias;
        PurchaseHeader.MODIFY();
        if JobPlanningLine.FindFirst() then
            repeat
                JobPlanningLine."Generar Compra" := false;
                JobPlanningLine.Modify();
            until JobPlanningLine.Next() = 0;
        Commit();

        MESSAGE(Text000_1);

        // OnAfterCreateSalesInvoiceLines(PurchaseHeader, NewInvoice);
    end;

    /// <summary>
    /// CreatePurchaseInvoiceLines.
    /// </summary>
    /// <param name="JobNo">code[20].</param>
    /// <param name="JobPlanningLineSource">VAR Record "Job Planning Line".</param>
    /// <param name="InvoiceNo">Code[20].</param>
    /// <param name="NewInvoice">Boolean.</param>
    /// <param name="PostingDate">Date.</param>
    /// <param name="CreditMemo">Boolean.</param>
    procedure CreatePurchaseInvoiceLines(JobNo: code[20]; var JobPlanningLineSource: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; CreditMemo: Boolean)
    var
        Job: Record Job;
        JobInvCurrency: Boolean;
        IsHandled: Boolean;
        Cust: Record Customer;
        Prov: Record Vendor;
        // PurchaseHeader2: Record "Purchase Header";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        LineCounter: Integer;
    begin


        //OnBeforeCreatePurchaseInvoiceLines(JobPlanningLine,InvoiceNo,NewInvoice,PostingDate,CreditMemo);

        CLEARALL;
        Job.GET(JobNo);
        IF Job.Blocked = Job.Blocked::All THEN
            Job.TestBlocked;
        IF Job."Currency Code" = '' THEN
            JobInvCurrency := Job."Invoice Currency Code" <> '';
        Job.TESTFIELD("Bill-to Customer No.");

        IsHandled := FALSE;
        //OnCreateSalesInvoiceLinesOnBeforeGetCustomer(JobPlanningLine, Cust, IsHandled);
        IF NOT IsHandled THEN
            //Cust.GET(Job."Bill-to Customer No.");
            Prov.get(JobPlanningLineSource.Cod_Proveedor);
        IF CreditMemo THEN
            PurchaseHeader2."Document Type" := PurchaseHeader2."Document Type"::"Credit Memo"
        ELSE
            PurchaseHeader2."Document Type" := PurchaseHeader2."Document Type"::Invoice;
        //PurchaseHeader2."Document Type" := PurchaseHeader2."Document Type"::Order;

        IF NOT NewInvoice THEN
            PurchaseHeader.GET(PurchaseHeader2."Document Type", InvoiceNo);

        //JobPlanningLine.Copy(JobPlanningLineSource);
        //*myb
        JobPlanningLine.SetRange(JobPlanningLine."Job No.", JobPlanningLineSource."Job No.");
        JobPlanningLine.SetRange(JobPlanningLine."Job Task No.", JobPlanningLineSource."Job Task No.");
        //JobPlanningLine.SetRange(JobPlanningLine."Line No.", JobPlanningLineSource."Line No.");
        JobPlanningLine.SetRange(Cod_Proveedor, JobPlanningLineSource.Cod_Proveedor);
        JobPlanningLine.SetRange("Generar Compra", true);
        //MYB
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");

        IF JobPlanningLine.FIND('-') THEN;
        //     REPEAT
        //         IF TransferLine(JobPlanningLine) THEN BEGIN
        //             LineCounter := LineCounter + 1;
        //             IF JobPlanningLine."Job No." <> JobNo THEN
        //                 ERROR(Text009, JobPlanningLine.FIELDCAPTION("Job No."));
        //             IF NewInvoice THEN
        //                 TestExchangeRate(JobPlanningLine, PostingDate)
        //             ELSE
        //                 TestExchangeRate(JobPlanningLine, PurchaseHeader."Posting Date");
        //         END;
        //     UNTIL JobPlanningLine.NEXT = 0;

        // IF LineCounter = 0 THEN
        //     ERROR(Text002,
        //       JobPlanningLine.TABLECAPTION,
        //       JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"));

        IF NewInvoice THEN
            CreatePurchaseHeader(Job, PostingDate, JobPlanningLine)
        ELSE
            TestPurchaseHeader(PurchaseHeader, Job, Prov."No.", JobPlanningLine.GetWorkDescription());
        IF JobPlanningLine.FINDSET THEN
            REPEAT
                IF TransferLine(JobPlanningLine) THEN BEGIN
                    IF JobPlanningLine.Type IN [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    THEN
                        JobPlanningLine.TESTFIELD("No.");


                    OnCreatePurchaseInvoiceLinesOnBeforeCreatePurchaseLine(JobPlanningLine, PurchaseHeader, PurchaseHeader2, NewInvoice);
                    CreatePurchaseLine(JobPlanningLine, JobPlanningLine."Line No.", JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                    /*
                                        JobPlanningLineInvoice.InitFromJobPlanningLine(JobPlanningLine);
                                        IF NewInvoice THEN
                                            JobPlanningLineInvoice.InitFromPurchase(PurchaseHeader, PostingDate, PurchaseLine."Line No.")
                                        ELSE
                                            JobPlanningLineInvoice.InitFromPurchase(PurchaseHeader, PurchaseHeader."Posting Date", PurchaseLine."Line No.");
                                        JobPlanningLineInvoice.INSERT;

                                        JobPlanningLine.UpdateQtyToTransfer;
                                        JobPlanningLine.MODIFY;
                                        */
                END;
            UNTIL JobPlanningLine.NEXT = 0;
        /*
                IF NoOfPurchaseLinesCreated = 0 THEN
                    ERROR(Text002, JobPlanningLine.TABLECAPTION, JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"));
        */
        COMMIT;
        if JobPlanningLine.FindFirst() then
            repeat
                JobPlanningLine.QB := JobPlanningLine.Quantity;
                JobPlanningLine.Modify();
            until JobPlanningLine.Next() = 0;
        Commit();
        IF CreditMemo THEN
            MESSAGE(Text008)
        ELSE
            MESSAGE(Text000);

        // OnAfterCreateSalesInvoiceLines(PurchaseHeader, NewInvoice);
    end;

    /// <summary>
    /// TransferLine.
    /// </summary>
    /// <param name="VAR JobPlanningLine">Record "Job Planning Line".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure TransferLine(VAR JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        JobPlanningLine2: Record "Job Planning Line";
    begin

        /*WITH JobPlanningLine2 DO BEGIN
            IF NOT JobPlanningLine."Contract Line" THEN
                EXIT(FALSE);
            IF JobPlanningLine.Type = JobPlanningLine.Type::Text THEN
                EXIT(TRUE);
            EXIT(JobPlanningLine."Qty. to Transfer to Invoice" <> 0);
        END;
        */

        //repeat
        //  IF NOT JobPlanningLine."Contract Line" THEN
        //Tipo de Línea puede ser ppto, facturable, ppto y facturable en el caso de compra
        //  EXIT(FALSE);
        //  EXIT(true);
        // IF JobPlanningLine.Type = JobPlanningLine.Type::Text THEN
        EXIT(TRUE);
        //EXIT(JobPlanningLine."Qty. to Transfer to Invoice" <> 0);
        //JobPlanningLine.qy
        //until JobPlanningLine.Next = 0;
    end;

    /// <summary>
    /// TestPurchaseHeader.
    /// </summary>
    /// <param name="VAR PurchaseHeader">Record "Purchase Header".</param>
    /// <param name="VAR Job">Record Job.</param>
    /// <param name="Proveedor">Code[20].</param>
    LOCAL procedure TestPurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; VAR Job: Record Job; Proveedor: Code[20]; workdescription: text)
    var
        IsHandled: Boolean;

    begin
        IsHandled := FALSE;
        PurchaseHeader.SetWorkDescription(workdescription);

        OnBeforeTestPurchaseHeader(PurchaseHeader, Job, IsHandled);

        IF IsHandled THEN
            EXIT;

        //PurchaseHeader.TESTFIELD("Bill-to Customer No.", Job."Bill-to Customer No.");
        PurchaseHeader.TESTFIELD(PurchaseHeader."Buy-from Vendor No.", Proveedor);


        IF Job."Currency Code" <> '' THEN
            PurchaseHeader.TESTFIELD("Currency Code", Job."Currency Code")
        ELSE
            PurchaseHeader.TESTFIELD("Currency Code", Job."Invoice Currency Code");

        OnAfterTestPurchaseHeader(PurchaseHeader, Job);
    end;

    /// <summary>
    /// TestExchangeRate.
    /// </summary>
    /// <param name="VAR JobPlanningLine">Record "Job Planning Line".</param>
    /// <param name="PostingDate">Date.</param>
    LOCAL procedure TestExchangeRate(VAR JobPlanningLine: Record "Job Planning Line"; PostingDate: Date)
    begin
        IF JobPlanningLine."Currency Code" <> '' THEN
            IF (CurrencyExchangeRate.ExchangeRate(PostingDate, JobPlanningLine."Currency Code") <> JobPlanningLine."Currency Factor")
            THEN BEGIN
                IF NOT UpdateExchangeRates THEN
                    UpdateExchangeRates := CONFIRM(Text010, TRUE);

                IF UpdateExchangeRates THEN BEGIN
                    JobPlanningLine."Currency Date" := PostingDate;
                    JobPlanningLine."Document Date" := PostingDate;
                    JobPlanningLine.VALIDATE("Currency Date");
                    JobPlanningLine."Last Date Modified" := TODAY;
                    JobPlanningLine."User ID" := USERID;
                    JobPlanningLine.MODIFY(TRUE);
                END ELSE
                    ERROR('');
            END;
    end;

    procedure CreatePurchaseHeader(Job: Record Job; PostingDate: Date; var JobPlanningLine: Record "Job Planning Line")
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
    begin
        PurchaseSetup.GET;
        PurchaseHeader.INIT;
        PurchaseHeader."Document Type" := PurchaseHeader2."Document Type";

        IF PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice THEN
            PurchaseSetup.TESTFIELD("Invoice Nos.");
        IF PurchaseHeader."Document Type" = PurchaseHeader2."Document Type"::"Credit Memo" THEN
            PurchaseSetup.TESTFIELD("Credit Memo Nos.");
        PurchaseHeader."Posting Date" := PostingDate;
        OnBeforeInsertPurchaseHeader(PurchaseHeader, Job);
        PurchaseHeader.INSERT(TRUE);
        //**
        // JobPlanningLine.TestField(Cod_Proveedor, '');
        // JobPlanningLine.TestField("Job No.", '');
        //**
        Prov.get(JobPlanningLine.Cod_Proveedor);
        Job.Get(JobPlanningLine."Job No.");

        //Prov.TESTFIELD(JobPlanningLine.Cod_Proveedor, '');
        //**
        //  Cust.GET(Job."Bill-to Customer No.");
        //  Cust.TESTFIELD("Bill-to Customer No.", '');
        //origan**
        // PurchaseHeader.VALIDATE("Sell-to Customer No.", Job."Bill-to Customer No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", JobPlanningLine.Cod_Proveedor);
        IF Job."Currency Code" <> '' THEN
            PurchaseHeader.VALIDATE("Currency Code", Job."Currency Code")
        ELSE
            PurchaseHeader.VALIDATE("Currency Code", Job."Invoice Currency Code");
        IF PostingDate <> 0D THEN
            PurchaseHeader.VALIDATE("Posting Date", PostingDate);

        IsHandled := FALSE;
        OnCreatePurchaseHeaderOnBeforeUpdatePurchaseHeader(PurchaseHeader, Job, IsHandled);
        IF NOT IsHandled THEN
            UpdatePurchaseHeader(PurchaseHeader, Job);
        OnBeforeModifyPurchaseHeader(PurchaseHeader, Job);
        PurchaseHeader.MODIFY(TRUE);
    end;

    procedure CreatePurchaseHeaderOrder(Job: Record Job; PostingDate: Date; var JobPlanningLine: Record "Job Planning Line")
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
        WorkDescription: Text;
    begin
        PurchaseSetup.GET;
        PurchaseHeader.INIT;
        PurchaseHeader."Document Type" := PurchaseHeader2."Document Type";

        IF PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order THEN
            PurchaseSetup.TESTFIELD("Order Nos.");
        IF PurchaseHeader."Document Type" = PurchaseHeader2."Document Type"::"Return Order" THEN
            PurchaseSetup.TESTFIELD("Return Order Nos.");
        PurchaseHeader."Posting Date" := PostingDate;
        //WorkDescription := JobPlanningLine.GetWorkDescription();
        //PurchaseHeader.SetWorkDescription(WorkDescription);
        OnBeforeInsertPurchaseHeader(PurchaseHeader, Job);
        PurchaseHeader.INSERT(TRUE);
        //**
        // JobPlanningLine.TestField(Cod_Proveedor, '');
        // JobPlanningLine.TestField("Job No.", '');
        //**
        Prov.get(JobPlanningLine.Cod_Proveedor);
        Job.Get(JobPlanningLine."Job No.");

        //Prov.TESTFIELD(JobPlanningLine.Cod_Proveedor, '');
        //**
        //  Cust.GET(Job."Bill-to Customer No.");
        //  Cust.TESTFIELD("Bill-to Customer No.", '');
        //origan**
        // PurchaseHeader.VALIDATE("Sell-to Customer No.", Job."Bill-to Customer No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", JobPlanningLine.Cod_Proveedor);
        IF Job."Currency Code" <> '' THEN
            PurchaseHeader.VALIDATE("Currency Code", Job."Currency Code")
        ELSE
            PurchaseHeader.VALIDATE("Currency Code", Job."Invoice Currency Code");
        IF PostingDate <> 0D THEN
            PurchaseHeader.VALIDATE("Posting Date", PostingDate);

        PurchaseHeader.Validate("No. Proyecto", JobPlanningLine."Job No.");

        IsHandled := FALSE;
        OnCreatePurchaseHeaderOnBeforeUpdatePurchaseHeader(PurchaseHeader, Job, IsHandled);
        IF NOT IsHandled THEN
            UpdatePurchaseHeader(PurchaseHeader, Job);
        OnBeforeModifyPurchaseHeader(PurchaseHeader, Job);
        PurchaseHeader.MODIFY(TRUE);
    end;

    procedure CreatePurchaseHeaderQuote(Job: Record Job; PostingDate: Date; var JobPlanningLine: Record "Job Planning Line")
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
    begin
        PurchaseSetup.GET;
        PurchaseHeader.INIT;
        PurchaseHeader."Document Type" := PurchaseHeader2."Document Type";

        IF PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote THEN
            PurchaseSetup.TESTFIELD("Quote Nos.");
        PurchaseHeader."Posting Date" := PostingDate;
        OnBeforeInsertPurchaseHeader(PurchaseHeader, Job);
        PurchaseHeader.INSERT(TRUE);
        //**
        // JobPlanningLine.TestField(Cod_Proveedor, '');
        // JobPlanningLine.TestField("Job No.", '');
        //**
        Prov.get(JobPlanningLine.Cod_Proveedor);
        Job.Get(JobPlanningLine."Job No.");

        //Prov.TESTFIELD(JobPlanningLine.Cod_Proveedor, '');
        //**
        //  Cust.GET(Job."Bill-to Customer No.");
        //  Cust.TESTFIELD("Bill-to Customer No.", '');
        //origan**
        // PurchaseHeader.VALIDATE("Sell-to Customer No.", Job."Bill-to Customer No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", JobPlanningLine.Cod_Proveedor);
        IF Job."Currency Code" <> '' THEN
            PurchaseHeader.VALIDATE("Currency Code", Job."Currency Code")
        ELSE
            PurchaseHeader.VALIDATE("Currency Code", Job."Invoice Currency Code");
        IF PostingDate <> 0D THEN
            PurchaseHeader.VALIDATE("Posting Date", PostingDate);

        PurchaseHeader.Validate("No. Proyecto", JobPlanningLine."Job No.");

        IsHandled := FALSE;
        OnCreatePurchaseHeaderOnBeforeUpdatePurchaseHeader(PurchaseHeader, Job, IsHandled);
        IF NOT IsHandled THEN
            UpdatePurchaseHeader(PurchaseHeader, Job);
        OnBeforeModifyPurchaseHeader(PurchaseHeader, Job);
        PurchaseHeader.MODIFY(TRUE);
    end;

    /// <summary>
    /// CreatePurchaseLine.
    /// </summary>
    /// <param name="VAR JobPlanningLine">Record "Job Planning Line".</param>
    /// <param name="Linea">Integer.</param>
    /// <param name="JobNo">Code[20].</param>
    /// <param name="Task">Code[20].</param>
    LOCAL procedure CreatePurchaseLine(VAR JobPlanningLine: Record "Job Planning Line"; Linea: Integer; JobNo: Code[20]; Task: Code[20])
    var
        Job: Record Job;
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        Factor: Integer;
        JobPlanningLine2: Record "Job Planning Line";
        DimSetIDArr: array[10] of Integer;
        NoLinea: Integer;
        GlSetup: Record "General Ledger Setup";
        Item: Record Item;
        Resource: Record Resource;
        GLAccount: Record "G/L Account";
        DimSetID: Integer;
    begin

        OnBeforeCreatePurchaseLine(JobPlanningLine, PurchaseHeader, PurchaseHeader2, JobInvCurrency);

        Factor := 1;
        if PurchaseHeader2."Document Type" = PurchaseHeader2."Document Type"::"Credit Memo" then
            Factor := 1;
        //Factor := -1; sino crea el abono en negativo
        //TestTransferred(JobPlanningLine);
        JobPlanningLine.TestField("Planning Date");
        Job.Get(JobPlanningLine."Job No.");
        JobPlanningLine2.Get(JobNo, Task, Linea);
        Clear(PurchaseLine);
        PurchaseLine."Document Type" := PurchaseHeader2."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";


        if (not JobInvCurrency) and (JobPlanningLine2.Type <> JobPlanningLine2.Type::Text) then begin
            PurchaseHeader.TestField("Currency Code", JobPlanningLine2."Currency Code");
            if (Job."Currency Code" <> '') and (JobPlanningLine2."Currency Factor" <> PurchaseHeader."Currency Factor") then begin
                if Confirm(Text011) then begin
                    JobPlanningLine2.Validate("Currency Factor", PurchaseHeader."Currency Factor");
                    JobPlanningLine2.Modify();
                end else
                    Error(Text001);
            end;
            PurchaseHeader.TestField("Currency Code", Job."Currency Code");
        end;
        if JobPlanningLine2.Type = JobPlanningLine2.Type::Text then
            PurchaseLine.Validate(Type, PurchaseLine.Type::" ");
        if JobPlanningLine2.Type = JobPlanningLine2.Type::"G/L Account" then
            PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        if JobPlanningLine2.Type = JobPlanningLine2.Type::Item then
            PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        if JobPlanningLine2.Type = JobPlanningLine2.Type::Resource then
            PurchaseLine.Validate(Type, PurchaseLine.Type::Resource);

        PurchaseLine.Validate("No.", JobPlanningLine2."No.");
        If JobPlanningLine2."Gen. Prod. Posting Group" <> '' Then
            PurchaseLine.Validate("Gen. Prod. Posting Group", JobPlanningLine2."Gen. Prod. Posting Group");
        If PurchaseLine."VAT Prod. Posting Group" <> '' Then
            PurchaseLine.Validate("VAT Prod. Posting Group")
        else begin
            Case PurchaseLine.Type of
                PurchaseLine.Type::Item:
                    Begin
                        Item.Get(PurchaseLine."No.");
                        Item.TestField("VAT Prod. Posting Group");
                        PurchaseLine.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
                    End;
                PurchaseLine.Type::Resource:
                    begin
                        Resource.Get(PurchaseLine."No.");
                        Resource.TestField("VAT Prod. Posting Group");
                        PurchaseLine.Validate("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
                    End;
                PurchaseLine.Type::"G/L Account":
                    begin
                        GLAccount.Get(PurchaseLine."No.");
                        GLAccount.TestField("VAT Prod. Posting Group");
                        PurchaseLine.Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
                    End;
            end;
        end;
        PurchaseLine.Validate("Location Code", JobPlanningLine2."Location Code");
        // PurchaseLine.Validate("Work Type Code", JobPlanningLine."Work Type Code");

        PurchaseLine.Validate("Variant Code", JobPlanningLine2."Variant Code");
        GlSetup.Get();
        if Factor = 0 then Factor := 1;

        if PurchaseLine.Type <> PurchaseLine.Type::" " then begin
            PurchaseLine.Validate("Unit of Measure Code", JobPlanningLine2."Unit of Measure Code");
            //PurchaseLine.Validate(Quantity, Factor * JobPlanningLine."Qty. to Transfer to Invoice");
            case PurchaseHeader2."Document Type" of
                PurchaseHeader2."Document Type"::Quote:
                    PurchaseLine.Validate(Quantity, Factor * (JobPlanningLine2.Quantity - JobPlanningLine."Cantidad en Oferta Compra"));
                PurchaseHeader2."Document Type"::Order:
                    PurchaseLine.Validate(Quantity, Factor * (JobPlanningLine2.Quantity - JobPlanningLine."Cantidad en Pedido Compra"));
                PurchaseHeader2."Document Type"::Invoice, PurchaseHeader2."Document Type"::"Credit Memo":
                    PurchaseLine.Validate(Quantity, Factor * (JobPlanningLine2."Cantidad a tr a Factura Compra"));

            end;

            if JobPlanningLine."Bin Code" <> '' then
                PurchaseLine.Validate("Bin Code", JobPlanningLine2."Bin Code");
            if JobInvCurrency then begin
                Currency.Get(PurchaseLine."Currency Code");

                PurchaseLine.Validate("Unit Cost",
                  Round(JobPlanningLine2."Unit Cost" * PurchaseHeader."Currency Factor",
                    Currency."Unit-Amount Rounding Precision"));

            end else begin
                // PurchaseLine.Validate("Unit Price", JobPlanningLine."Unit Price");
                PurchaseLine.Validate("Direct Unit Cost", JobPlanningLine2."Unit Cost");
                // PurchaseLine.Validate(("Job Unit Price", JobPlanningLine."Unit Cost");
                // PurchaseLine.Validate("Unit Cost (LCY)", JobPlanningLine."Unit Cost (LCY)");
                PurchaseLine.Validate(PurchaseLine."Line Discount %", JobPlanningLine2."Line Discount %");

                // PurchaseLine."Inv. Discount Amount" := 0;
                // PurchaseLine."Inv. Disc. Amount to Invoice" := 0;
                PurchaseLine.UpdateAmounts;
            end;
        end;
        //if not PurchaseHeader."Prices Including VAT" then
        //    PurchaseLine.Validate("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");        
        PurchaseLine."Job No." := JobPlanningLine2."Job No.";
        PurchaseLine."Job Task No." := JobPlanningLine2."Job Task No.";
        PurchaseLine."Job Planning Line No." := JobPlanningLine2."Line No.";

        if PurchaseLine."Job Task No." <> '' then begin
            SourceCodeSetup.Get();
            //Traspasar Dimensiones JobPlanningLine
            DimSetID := GetJobLedgEntryDimSetID(JobPlanningLine);
            if DimSetID = 0 then
                DimSetID := GetDimSetIDFromJobTaskDimension(PurchaseLine."Job No.", PurchaseLine."Job Task No.");
            if DimSetID <> 0 then
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
        end;
        PurchaseLine.Description := JobPlanningLine2.Description;
        PurchaseLine."Description 2" := JobPlanningLine2."Description 2";
        PurchaseLine."Line No." := GetNextLineNo(PurchaseLine);
        //NoLinea := GetNextLineNo(PurchaseLine);
        // PurchaseLine."Line No." := NoLinea;
        OnBeforeInsertPurchaseLine(PurchaseLine, PurchaseHeader, Job, JobPlanningLine2);
        If PurchaseLine."Gen. Prod. Posting Group" = '' Then begin
            Case PurchaseLine.Type of
                PurchaseLine.Type::Item:
                    Begin
                        Item.Get(PurchaseLine."No.");
                        Item.TestField("Gen. Prod. Posting Group");
                        PurchaseLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";

                    End;
                PurchaseLine.Type::Resource:
                    begin
                        Resource.Get(PurchaseLine."No.");
                        Resource.TestField("Gen. Prod. Posting Group");
                        PurchaseLine."Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
                    End;
                PurchaseLine.Type::"G/L Account":
                    begin
                        GLAccount.Get(PurchaseLine."No.");
                        GLAccount.TestField("Gen. Prod. Posting Group");
                        PurchaseLine."Gen. Prod. Posting Group" := GLAccount."Gen. Prod. Posting Group";
                    End;
            end;
        end;
        //unit of measure code
        If PurchaseLine."Unit of Measure Code" = '' Then begin
            Case PurchaseLine.Type of
                PurchaseLine.Type::Item:
                    Begin
                        Item.Get(PurchaseLine."No.");
                        Item.TestField("Purch. Unit of Measure");
                        PurchaseLine."Unit of Measure Code" := Item."Purch. Unit of Measure";

                    End;
                PurchaseLine.Type::Resource:
                    begin
                        Resource.Get(PurchaseLine."No.");
                        Resource.TestField("Base Unit of Measure");
                        PurchaseLine."Unit of Measure Code" := Resource."Base Unit of Measure";
                    End;

            end;
        end;

        PurchaseLine.Insert(true);
        JobPlanningLine.Modify();

        if PurchaseLine.Type <> PurchaseLine.Type::" " then begin
            NoOfPurchaseLinesCreated += 1;
            CalculateInvoiceDiscount(PurchaseLine, PurchaseHeader);
        end;

        if PurchaseHeader."Prices Including VAT" and (PurchaseLine.Type <> PurchaseLine.Type::" ") then begin
            Currency.Initialize(PurchaseLine."Currency Code");
            PurchaseLine."Unit Cost" :=
              Round(
                PurchaseLine."Unit Cost" * (1 + (PurchaseLine."VAT %" / 100)),
                Currency."Unit-Amount Rounding Precision");
            if PurchaseLine.Quantity <> 0 then begin
                PurchaseLine."Line Discount Amount" :=
                  Round(
                    PurchaseLine.Quantity * PurchaseLine."Unit Cost" * PurchaseLine."Line Discount %" / 100,
                    Currency."Amount Rounding Precision");
                PurchaseLine.Validate("Inv. Discount Amount",
                  Round(
                    PurchaseLine."Inv. Discount Amount" * (1 + (PurchaseLine."VAT %" / 100)),
                    Currency."Amount Rounding Precision"));
            end;
            PurchaseLine.Validate("Job Contract Entry No.", JobPlanningLine2."Job Contract Entry No.");
            if JobPlanningLine2.GetWorkDescription() <> '' then
                PurchaseLine.SetWorkDescription(JobPlanningLine2.GetWorkDescription());
            OnBeforeModifyPurchaseLine(PurchaseLine, PurchaseHeader, Job, JobPlanningLine2);
            PurchaseLine.Modify();
            JobPlanningLine2."VAT Unit Price" := PurchaseLine."Unit Cost";
            JobPlanningLine2."VAT Line Discount Amount" := PurchaseLine."Line Discount Amount";
            JobPlanningLine2."VAT Line Amount" := PurchaseLine."Line Amount";
            JobPlanningLine2."VAT %" := PurchaseLine."VAT %";
            JobPlanningLine2.QB := JobPlanningLine.Quantity;
            JobPlanningLine2.Modify();
        end;
        /*
        if TransferExtendedText.SalesCheckIfAnyExtText(PurchaseLine, false) then
            TransferExtendedText.InsertSalesExtText(PurchaseLine);
*/
        if JobPlanningLine.GetWorkDescription() <> '' then begin
            PurchaseLine.SetWorkDescription(JobPlanningLine2.GetWorkDescription());
            //PurchaseLine.Modify();
        end;
        OnAfterCreatePurchaseLine(PurchaseLine, PurchaseHeader, Job, JobPlanningLine2);


    end;

    local procedure GetNextLineNo(PurchaseLine: Record "Purchase Line"): Integer
    var
        NextLineNo: Integer;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        NextLineNo := 10000;
        if PurchaseLine.FindLast then
            NextLineNo := PurchaseLine."Line No." + 10000;
        exit(NextLineNo);
    end;

    local procedure TestTransferred(JobPlanningLine: Record "Job Planning Line"; Tipo: Option Pedido,Factura)
    begin
        //If Tipo=Tipo::Pedido Then exi
        //if JobPlanningLine.Quantity
        //WITH JobPlanningLine DO BEGIN
        //JobPlanningLine.CALCFIELDS("Qty. Transferred to Invoice");
        // IF JobPlanningLine.Quantity > 0 THEN BEGIN
        //     IF (JobPlanningLine."Cantidad a tr a Factura Compra" > 0) AND
        //     (JobPlanningLine."Qty. to Transfer to Invoice" >
        //     (JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice")) OR
        //        (JobPlanningLine."Qty. to Transfer to Invoice" < 0)
        //     THEN
        //         ERROR(Text003, JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"), 0,
        //         JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice");
        // END ELSE BEGIN
        //     IF (JobPlanningLine."Qty. to Transfer to Invoice" > 0) OR
        //        (JobPlanningLine."Qty. to Transfer to Invoice" < 0) AND
        //        (JobPlanningLine."Qty. to Transfer to Invoice" <
        //        (JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice"))
        //     THEN
        //         ERROR(Text003, JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"),
        //         JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice", 0);
        // END;
        // // END;

        // //repeat
        // JobPlanningLine.CALCFIELDS(JobPlanningLine."Qty. Transferred to Invoice");
        // IF JobPlanningLine.Quantity > 0 THEN BEGIN
        //     IF (JobPlanningLine."Qty. to Transfer to Invoice" > 0) AND (JobPlanningLine."Qty. to Transfer to Invoice" > (JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice")) OR
        //        (JobPlanningLine."Qty. to Transfer to Invoice" < 0)
        //     THEN
        //         ERROR(Text003, JobPlanningLine.FIELDCAPTION("Qty. to Transfer to Invoice"), 0, JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice");
        // END ELSE BEGIN
        //     IF (JobPlanningLine."Qty. to Transfer to Invoice" > 0) OR
        //        (JobPlanningLine."Qty. to Transfer to Invoice" < 0) AND (JobPlanningLine."Qty. to Transfer to Invoice" < (JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice"))
        //     THEN
        //         ERROR(Text003, JobPlanningLine.FIELDCAPTION(JobPlanningLine."Qty. to Transfer to Invoice"), JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice", 0);
        // END;
        //until JobPlanningLine.Next = 0;

    end;

    local procedure GetJobLedgEntryDimSetID(JobPlanningLine: Record "Job Planning Line"): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTask: Record "Job Task";
    begin
        if JobPlanningLine."Job Ledger Entry No." = 0 then
            exit(0);

        if JobLedgerEntry.Get(JobPlanningLine."Job Ledger Entry No.") then
            exit(JobLedgerEntry."Dimension Set ID");

        exit(0);
    end;

    local procedure GetDimSetIDFromJobTaskDimension(JobNo: Code[20]; JobTaskNo: Code[20]): Integer
    var
        JobTaskDimension: Record "Job Task Dimension";
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        JobTaskDimension.SetRange("Job No.", JobNo);
        JobTaskDimension.SetRange("Job Task No.", JobTaskNo);
        if not JobTaskDimension.FindSet() then
            exit(0);
        repeat
            if DimValue.Get(JobTaskDimension."Dimension Code", JobTaskDimension."Dimension Value Code") then begin
                TempDimSetEntry."Dimension Code" := JobTaskDimension."Dimension Code";
                TempDimSetEntry."Dimension Value Code" := JobTaskDimension."Dimension Value Code";
                TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                TempDimSetEntry.Insert(true);
            end;
        until JobTaskDimension.Next() = 0;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure GetLedgEntryDimSetID(JobPlanningLine: Record "Job Planning Line"): Integer
    var
        ResLedgEntry: Record "Res. Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        if JobPlanningLine."Ledger Entry No." = 0 then
            exit(0);

        case JobPlanningLine."Ledger Entry Type" of
            JobPlanningLine."Ledger Entry Type"::Resource:
                begin
                    ResLedgEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(ResLedgEntry."Dimension Set ID");
                end;
            JobPlanningLine."Ledger Entry Type"::Item:
                begin
                    ItemLedgEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(ItemLedgEntry."Dimension Set ID");
                end;
            JobPlanningLine."Ledger Entry Type"::"G/L Account":
                begin
                    GLEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(GLEntry."Dimension Set ID");
                end;
            else
                exit(0);
        end;
    end;

    LOCAL procedure UpdatePurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; Job: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := FALSE;
        OnBeforeUpdatePurchaseHeader(PurchaseHeader, Job, IsHandled);
        IF IsHandled THEN
            EXIT;
        /*
                PurchaseHeader."Bill-to Contact No." := Job."Bill-to Contact No.";
                PurchaseHeader."Bill-to Contact" := Job."Bill-to Contact";
                PurchaseHeader."Bill-to Name" := Job."Bill-to Name";
                PurchaseHeader."Bill-to Address" := Job."Bill-to Address";
                PurchaseHeader."Bill-to Address 2" := Job."Bill-to Address 2";
                PurchaseHeader."Bill-to City" := Job."Bill-to City";
                PurchaseHeader."Bill-to Post Code" := Job."Bill-to Post Code";

                PurchaseHeader."Sell-to Contact No." := Job."Bill-to Contact No.";
                PurchaseHeader."Sell-to Contact" := Job."Bill-to Contact";
                PurchaseHeader."Sell-to Customer Name" := Job."Bill-to Name";
                PurchaseHeader."Sell-to Address" := Job."Bill-to Address";
                PurchaseHeader."Sell-to Address 2" := Job."Bill-to Address 2";
                PurchaseHeader."Sell-to City" := Job."Bill-to City";
                PurchaseHeader."Sell-to Post Code" := Job."Bill-to Post Code";
                */

        PurchaseHeader."Ship-to Contact" := Job."Bill-to Contact";
        PurchaseHeader."Ship-to Name" := Job."Bill-to Name";
        PurchaseHeader."Ship-to Address" := Job."Bill-to Address";
        PurchaseHeader."Ship-to Address 2" := Job."Bill-to Address 2";
        PurchaseHeader."Ship-to City" := Job."Bill-to City";
        PurchaseHeader."Ship-to Post Code" := Job."Bill-to Post Code";

    end;

    local procedure CalculateInvoiceDiscount(var PurcharseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        TotalPurchaseHeader: Record "Purchase Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        TotalPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        TotalPurchaseHeader.CalcFields("Recalculate Invoice Disc.");

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Calc. Inv. Discount" and
           (PurcharseLine."Document No." <> '') and
           (TotalPurchaseHeader."Vendor Posting Group" <> '') and
           TotalPurchaseHeader."Recalculate Invoice Disc."
        then
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurcharseLine);

    end;

    procedure CreateJobLocation(pJob: Record Job)
    //TODO PDTE DE PROBAR 15/09/25 UPDATE VERSION 26.05
    var
        Location: Record Location;
        FinLocation: Record Location;
        RJob: Record Job;
        JobsSetup: Record "Jobs Setup";
        // NoSeriesMgt1: Codeunit NoSeriesManagement;
        NoSeriesMgt: Codeunit "No. Series";
    begin
        JobsSetup.Get();
        JobsSetup.TestField("No.Serie Almacen de Proyecto");
        if pJob."Cod Almacen de Proyecto" = '' then
            // NoSeriesMgt.InitSeries(JobsSetup."No.Serie Almacen de Proyecto", '', 0D, pjob."Cod Almacen de Proyecto", JobsSetup."No.Serie Almacen de Proyecto");
            NoSeriesMgt.AreRelated(JobsSetup."No.Serie Almacen de Proyecto", pjob."Cod Almacen de Proyecto");
        pJob.Modify();

        FinLocation.SetRange(Code, pJob."Cod Almacen de Proyecto");
        if not FinLocation.FindFirst() then begin
            Location.Reset();
            Location.Validate(Code, pJob."Cod Almacen de Proyecto");
            Location.Validate("No proyecto", pJob."No.");
            Location.Name := pJob.Description;
            Location.Insert();

        end;

    end;

    // FinLocation.SetRange(Code, pJob."No.");
    // pJob.TestField(pJob."Nomemglatura Proyecto");
    // FinLocation.SetRange(Code, pJob."Nomemglatura Proyecto");
    // if not FinLocation.FindFirst() then begin
    //     Location.Reset();
    //     Location.Validate(Code, pJob."Nomemglatura Proyecto");
    //     Location.Validate("No proyecto", pJob."No.");
    //     Location.Name := pJob.Description;
    //     Location.Insert();

    // end;




    /// <summary>
    /// GetJobPlanningLineInvoices.
    /// </summary>
    /// <param name="JobPlanningLine">Record "Job Planning Line".</param>
    procedure GetJobPlanningLineInvoices(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        ClearAll;
        //with JobPlanningLine do begin
        if JobPlanningLine."Line No." = 0 then
            exit;
        JobPlanningLine.TestField("Job No.");
        JobPlanningLine.TestField("Job Task No.");

        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        if JobPlanningLineInvoice.Count = 1 then begin
            JobPlanningLineInvoice.FindFirst;
            OpenPurchaseInvoice(JobPlanningLineInvoice);
        end else
            PAGE.RunModal(PAGE::"Job Invoices", JobPlanningLineInvoice);
        //end;
    end;

    procedure OpenPurchaseInvoice(JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    var
        PurchaseHeader: Record "purchase Header";
        PurchaseInvHeader: Record "Purch. Inv. Header";
        PurchaseCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeOpenSalesInvoice(JobPlanningLineInvoice, IsHandled);
        if IsHandled then
            exit;

        //  with JobPlanningLineInvoice do
        case JobPlanningLineInvoice."Document Type" of
            JobPlanningLineInvoice."Document Type"::Invoice:
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Purchase Invoice", PurchaseHeader);
                end;
            JobPlanningLineInvoice."Document Type"::"Credit Memo":
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Purchase Credit Memo", PurchaseHeader);
                end;
            JobPlanningLineInvoice."Document Type"::"Posted Invoice":
                begin
                    if not PurchaseInvHeader.Get(JobPlanningLineInvoice."Document No.") then
                        Error(Text012, PurchaseInvHeader.TableCaption, JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Posted Purchase Invoice", PurchaseInvHeader);
                end;
            JobPlanningLineInvoice."Document Type"::"Posted Credit Memo":
                begin
                    if not PurchaseCrMemoHeader.Get(JobPlanningLineInvoice."Document No.") then
                        Error(Text012, PurchaseCrMemoHeader.TableCaption, JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Posted Purchase Credit Memo", PurchaseCrMemoHeader);
                end;
        end;

        // OnAfterOpenSalesInvoice(JobPlanningLineInvoice);
    end;

    internal procedure CrearPresupuesto(var Rec: Record Job)
    var
        JSetup: Record "Jobs Setup";
        Setup: Record "General Ledger Setup";
        Dimension: Record "Dimension Value";
        BudgetEntry: Record "G/L Budget Entry";
        JobPlaningLine: Record "Job Planning Line";
        Res: Record Resource;
        Item: Record Item;
        Customer: Record Customer;
        GroupSetup: Record "General Posting Setup";
        Linea: Integer;
    begin
        Customer.Get(Rec."Bill-to Customer No.");
        BudgetEntry.SetRange("Job No.", Rec."No.");
        BudgetEntry.DeleteAll();
        BudgetEntry.SetRange("Job No.");
        JobPlaningLine.SetRange("Job No.", Rec."No.");
        JobPlaningLine.SetFilter("Line Type", '%1|%2', JobPlaningLine."Line Type"::"Both Budget and Billable", JobPlaningLine."Line Type"::"Budget");
        If BudgetEntry.FindLast() then Linea := BudgetEntry."Entry No." + 1 else Linea := 1;
        Setup.Get();
        JSetup.Get();

        JobPlaningLine.FindSet();
        repeat
            BudgetEntry.Init();
            BudgetEntry."Entry No." := Linea;
            Linea += 1;
            BudgetEntry.Date := JobPlaningLine."Planning Date";
            BudgetEntry."Job No." := Rec."No.";
            BudgetEntry."Budget Name" := Rec."Cód. Presupuesto";
            Case JobPlaningLine.Type Of
                "Job Planning Line Type"::"G/L Account":
                    begin
                        BudgetEntry."G/L Account No." := JobPlaningLine."No.";

                    end;
                "Job Planning Line Type"::"Resource":
                    begin
                        Res.Get(JobPlaningLine."No.");
                        GroupSetup.Get(Customer."Gen. Bus. Posting Group", Res."Gen. Prod. Posting Group");
                        BudgetEntry."G/L Account No." := GroupSetup."Purch. Account";
                    end;
                "Job Planning Line Type"::Item:
                    begin
                        Item.Get(JobPlaningLine."No.");
                        GroupSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
                        BudgetEntry."G/L Account No." := GroupSetup."Purch. Account";
                    end;

            End;
            if JSetup."Dimension Proyecto" <> '' Then begin
                If JSetup."Dimension Proyecto" = Setup."Global Dimension 1 Code" Then
                    BudgetEntry.Validate("Global Dimension 1 Code", Job."No.");
                If JSetup."Dimension Proyecto" = Setup."Global Dimension 2 Code" Then
                    BudgetEntry.Validate("Global Dimension 2 Code", Job."No.");
                if JSetup."Dimension Proyecto" = Setup."Shortcut Dimension 3 Code" Then
                    BudgetEntry.Validate("Budget Dimension 3 Code", Job."No.");
                if JSetup."Dimension Proyecto" = Setup."Shortcut Dimension 4 Code" Then
                    BudgetEntry.Validate("Budget Dimension 4 Code", Job."No.");


            end;
            BudgetEntry.Validate("Global Dimension 1 Code", Job."Global Dimension 1 Code");
            BudgetEntry.Validate("Global Dimension 2 Code", Job."Global Dimension 2 Code");
            BudgetEntry.Validate(Amount, JobPlaningLine."Total Cost");

            BudgetEntry.Description := JobPlaningLine.Description;
            if BudgetEntry.Amount <> 0 then begin

                if not BudgetEntry.Insert(true) then
                    repeat
                        Linea += 1;
                        BudgetEntry."Entry No." := Linea;

                    until BudgetEntry.Insert(true);
            end;

        until JobPlaningLine.Next() = 0;
        Message('Se ha generado el presupuesto para este proyecto');
    end;

    internal procedure CreaLineaUso(JobNo: Code[20]; JobTaskNo: Code[20]; Tipo: Text; NoCuenta: Code[20]; Descripcion: Text; Cantidad: Decimal; Cost: Decimal; Venta: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.Init();
        JobLedgerEntry."Job No." := JobNo;
        JobLedgerEntry."Job Task No." := JobTaskNo;
        JobLedgerEntry."Posting Date" := Today;
        JobLedgerEntry."Document No." := CopyStr(JobNo, 1, MaxStrLen(JobLedgerEntry."Document No."));

        // Determinar Type según el Tipo (columna C)
        case UpperCase(Tipo) of
            'CUENTA', 'G/L ACCOUNT', 'GL ACCOUNT':
                begin
                    JobLedgerEntry.Type := JobLedgerEntry.Type::"G/L Account";
                    JobLedgerEntry."No." := NoCuenta;
                end;
            'PRODUCTO', 'ITEM':
                begin
                    JobLedgerEntry.Type := JobLedgerEntry.Type::Item;
                    JobLedgerEntry."No." := NoCuenta;
                end;
            'RECURSO', 'RESOURCE':
                begin
                    JobLedgerEntry.Type := JobLedgerEntry.Type::Resource;
                    JobLedgerEntry."No." := NoCuenta;
                end;
        end;

        JobLedgerEntry.Description := Descripcion;
        if Cantidad <> 0 then
            JobLedgerEntry.Quantity := Cantidad
        else
            JobLedgerEntry.Quantity := 1;

        if Cost <> 0 then begin
            JobLedgerEntry."Unit Cost" := Cost / JobLedgerEntry.Quantity;
            JobLedgerEntry."Total Cost" := Cost;
        end;

        if Venta <> 0 then begin
            JobLedgerEntry."Unit Price" := Venta / JobLedgerEntry.Quantity;
            JobLedgerEntry."Total Price" := Venta;
        end;

        JobLedgerEntry.INSERT(true);
    end;

    /// <summary>
    /// Crea un movimiento de proyecto (Job Ledger Entry) de tipo uso a partir de una línea de factura de venta,
    /// de forma análoga a CreaLineaUso pero con datos de Sales Header y Sales Line.
    /// </summary>
    internal procedure CrearJobPlaningLineVta(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        Cantidad: Decimal;
        Venta: Decimal;
        lineNo: Integer;
    begin
        JobPlanningLine.SetRange("Job No.", SalesLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", SalesLine."Job Task No.");
        JobPlanningLine.SetRange("Document No.", SalesHeader."Posting No.");
        JobPlanningLine.SetRange("Line No.", SalesLine."Line No.");
        JobPlanningLine.DeleteAll();
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", SalesLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", SalesLine."Job Task No.");
        If JobPlanningLine.Findlast() then lineNo := JobPlanningLine."Line No." + 10000 else lineNo := 10000;

        JobPlanningLine.Init();
        JobPlanningLine."Job No." := SalesLine."Job No.";
        JobPlanningLine."Job Task No." := SalesLine."Job Task No.";
        JobPlanningLine."Planning Date" := SalesHeader."Document Date";
        JobPlanningLine."Document No." := SalesHeader."Posting No.";
        JobPlanningLine."Line No." := lineNo;
        JobPlanningLine.Description := SalesLine.Description;
        Cantidad := SalesLine.Quantity;
        if Cantidad = 0 then
            Cantidad := 1;
        JobPlanningLine."Qty. to Invoice" := Cantidad;
        JobPlanningLine.Quantity := Cantidad;

        Venta := SalesLine."Line Amount";
        if Venta <> 0 then begin
            JobPlanningLine."Unit Price" := Venta / JobPlanningLine.Quantity;
            JobPlanningLine."Total Price" := Venta;
        end;
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := SalesLine."No.";
        JobPlanningLine."Line Type" := JobPlanningLine."Line Type"::Billable;
        JobPlanningLine.Insert();
        JobPlanningLineInvoice.Init();
        JobPlanningLineInvoice."Job No." := SalesLine."Job No.";
        JobPlanningLineInvoice."Job Task No." := SalesLine."Job Task No.";
        JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
        JobPlanningLineInvoice."Document No." := SalesHeader."Posting No.";
        JobPlanningLineInvoice."Line No." := SalesLine."Line No.";
        JobPlanningLineInvoice."Quantity Transferred" := Cantidad;
        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::Invoice;
        JobPlanningLineInvoice.Insert();



    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, 'OnBeforeCreateDimSetFromJobTaskDim', '', false, false)]

    procedure OnBeforeCreateDimSetFromJobTaskDimMyB(JobNo: Code[20]; JobTaskNo: Code[20]; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20]; var NewDimSetID: Integer; var IsHandled: Boolean)
    var
        JobSetup: Record "Jobs Setup";
        JobTaskDimension: Record "Job Task Dimension";
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;

    begin

        JobSetup.Get();
        if JobSetup.DimensionJobProveedor then begin
            //with JobTaskDimension do begin
            JobTaskDimension.SetRange("Job No.", JobNo);
            JobTaskDimension.SetRange("Job Task No.", JobTaskNo);
            if JobTaskDimension.FindSet then begin
                repeat
                    DimValue.Get(JobTaskDimension."Dimension Code", JobTaskDimension."Dimension Value Code");
                    TempDimSetEntry."Dimension Code" := JobTaskDimension."Dimension Code";
                    TempDimSetEntry."Dimension Value Code" := JobTaskDimension."Dimension Value Code";
                    TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                    TempDimSetEntry.Insert(true);
                until JobTaskDimension.Next() = 0;
                NewDimSetID := DimensionManagement.GetDimensionSetID(TempDimSetEntry);
                DimensionManagement.UpdateGlobalDimFromDimSetID(NewDimSetID, GlobalDimVal1, GlobalDimVal2);
            end;
            //end;
            IsHandled := JobSetup.DimensionJobProveedor;
        end;


    end;

    procedure ActualizarArbolTareas(JobNo: Code[20])
    var
        JobTask: Record "Job Task";
        JobTaskChild: Record "Job Task";
        JobSetup: Record "Jobs Setup";
        LongitudPrefijo: Integer;
        LongitudCapitulo: Integer;
        LongitudTarea: Integer;
        EsCapitulo: Boolean;
        TieneHijas: Boolean;
    begin
        // Obtener configuración
        JobSetup.Get();

        // Determinar el Job No. a procesar


        // Calcular la longitud esperada de un capítulo
        JobSetup.TestField("Digitos Capítulo");
        LongitudPrefijo := StrLen(JobSetup."Prefijo Capítulo");
        LongitudCapitulo := LongitudPrefijo + 1 + JobSetup."Digitos Capítulo"; // Prefijo + '.' + dígitos

        // Recorrer todas las tareas del proyecto ordenadas por número
        JobTask.Reset();
        JobTask.SetRange("Job No.", JobNo);
        if JobTask.FindSet() then
            repeat
                LongitudTarea := StrLen(JobTask."Job Task No.");

                // Determinar si es capítulo: la longitud debe coincidir con la longitud esperada de capítulo
                EsCapitulo := ((LongitudTarea = LongitudCapitulo) and
                              (CopyStr(JobTask."Job Task No.", 1, LongitudPrefijo) = JobSetup."Prefijo Capítulo"))
                              Or (JobTask."Tipo Partida" = JobTask."Tipo Partida"::Capítulo);

                // Establecer Tipo Partida
                if EsCapitulo then
                    JobTask."Tipo Partida" := JobTask."Tipo Partida"::"Capítulo"
                else
                    JobTask."Tipo Partida" := JobTask."Tipo Partida"::"Subcapítulo";

                // Verificar si tiene tareas hijas (tareas que empiezan con el número de esta tarea seguido de un punto o carácter)
                TieneHijas := false;
                JobTaskChild.Reset();
                JobTaskChild.SetRange("Job No.", JobNo);
                // Buscar tareas que empiecen con el número de esta tarea pero que sean diferentes (hijas)
                JobTaskChild.SetFilter("Job Task No.", JobTask."Job Task No." + '?*');
                if JobTaskChild.FindFirst() then
                    TieneHijas := true;

                // Establecer Job Task Type y Totaling
                if TieneHijas then begin
                    JobTask."Job Task Type" := JobTask."Job Task Type"::Total;
                    // Totaling = número de tarea '..' número de tarea '9999999'
                    // Formato similar al código existente: "1.01..1.019999999"
                    JobTask.Validate(Totaling, JobTask."Job Task No." + '..' + JobTask."Job Task No." + 'Z');
                end else begin
                    JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                    JobTask.Totaling := '';
                end;

                // Establecer indentación = strlen del número de tarea
                JobTask.Indentation := StrLen(JobTask."Job Task No.");

                JobTask.Modify();
            until JobTask.Next() = 0;


    end;



    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseInvoiceLines(PurchaseHeader: Record "Purchase Header"; NewInvoice: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseLine(VAR PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseInvoiceLines(VAR JobPlanningLine: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; CreditMemo: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchaseLine(VAR PurchaseLine: Record "Purchase Line"; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvoiceNo(JobPlanningLine: Record "Job Planning Line"; Done: Boolean; NewInvoice: Boolean; PostingDate: Date; VAR InvoiceNo: Code[20]; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCrMemoNo(JobPlanningLine: Record "Job Planning Line"; Done: Boolean; NewInvoice: Boolean; PostingDate: Date; VAR InvoiceNo: Code[20]; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; Job: Record Job)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; Job: Record Job)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchaseLine(VAR PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseLine(VAR PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPurchaseInvoice(VAR JobPlanningLineInvoice: Record "Job Planning Line Invoice"; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; Job: Record Job; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; Job: Record Job; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestPurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; Job: Record Job)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseHeaderOnBeforeUpdatePurchaseHeader(VAR PurchaseHeader: Record "Purchase Header"; VAR Job: Record Job; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseInvoiceLinesOnBeforeCreatePurchaseLine(VAR JobPlanningLine: Record "Job Planning Line"; PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; NewInvoice: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseInvoiceLinesOnBeforeGetCustomer(JobPlanningLine: Record "Job Planning Line"; VAR Customer: Record Customer; VAR IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchaseInvoiceJobTaskOnBeforeCreatePurchaseLine(VAR JobPlanningLine: Record "Job Planning Line"; PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header")
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseLine(var JobPlanningLine: Record "Job Planning Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; var JobInvCurrency: Boolean)
    begin

    end;

    procedure ImportarJobLedgerEntriesDesdeExcel(JobNo: Code[20])
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        InStream: InStream;
        FileName: Text;
        RowNo: Integer;
        JobTaskNo: Code[20];
        BudgetCode: Code[100];
        Fic: Text[100];
        Descripcion: Text[100];
        FechaFactura: Date;
        NumeroFactura: Code[50];
        ProveedorEmpleado: Text[100];
        NetoFactura: Decimal;
        IGICOIVA: Decimal;
        ImporteIGICOIVA: Decimal;
        Budget: Decimal;
        IRPF: Decimal;
        BrutoFactura: Decimal;
        FechaVTO: Date;
        Estado: Text[100];
        FechaPago: Date;
        ImportedEntries: Integer;
        SheetName: Text;
        Job: Record Job;
        LineNo: Integer;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        Employee: Record Employee;
        Resource: Record Resource;
        Tipo: Text[20];
        NoCuenta: Code[20];
        RegistroPresupuestario: Text[100];
        FacturadoContra: Text[100];
        CIFProveedor: Text[30];
        Item: Record Item;
        JobsSetup: Record "Jobs Setup";
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        Ishandled: Boolean;
        ImportedEntriesPagado: Decimal;
        ProyectoMovimientoPago: Record "Proyecto Movimiento Pago";
        Descripcion2: Text[50];
        esProveedor: Boolean;
        esEmpleado: Boolean;
        rInf: Record "Company Information";
        //CtaCble: Text[30];
        GenNegPostingGrup: Record "Gen. Business Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        ClasificacionGasto: Text[100];
        Categorias: Record Categorias;
        IcParter: Record "Ic Partner";
        Customer: Record Customer;
        RegistroProyectos: Record "Job Register";
        IdJobRegister: Integer;
        Desde: Integer;
        Eventosproyectos: Codeunit "Eventos-proyectos";
        ImporteProduccion: Decimal;
        ImporteNA: Decimal;
        DescripcionProduccion: Text[100];
        EsDesdobleProduccion: Boolean;
        BudgetNormal: Decimal;
        JobPlanningLineProd: Record "Job Planning Line";
        JobPlanningLineNormal: Record "Job Planning Line";
    begin
        rInf.Get();
        rInf.TestField("Cta Contable Mov");
        if RegistroProyectos.FindLast() then
            IdJobRegister := RegistroProyectos."No." + 1
        else
            IdJobRegister := 1;

        if not Job.Get(JobNo) then
            Error('El proyecto %1 no existe.', JobNo);

        if Job.Status <> Job.Status::Open then
            Error('El proyecto debe estar en estado Abierto para importar movimientos.');

        // Limpiar buffer temporal
        TempExcelBuffer.DeleteAll();
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.Deleteall;
        Commit();

        // Cargar datos del Excel
        if UploadIntoStream('Seleccionar archivo Excel', '', 'Archivos Excel (*.xlsx)|*.xlsx|Todos los archivos (*.*)|*.*', FileName, InStream) then begin
            SheetName := TempExcelBuffer.SelectSheetsNameStream(InStream);
            TempExcelBuffer.OpenBookStream(InStream, SheetName);
            TempExcelBuffer.ReadSheet();
        end else
            exit;

        ImportedEntries := 0;

        // Procesar cada fila del Excel
        if TempExcelBuffer.FindSet() then
            repeat
                RowNo := TempExcelBuffer."Row No.";

                // Saltar fila de encabezados (asumiendo que está en la fila 1)
                if RowNo = 1 then begin
                    // Saltar esta fila y continuar con la siguiente
                end else begin
                    // Inicializar variables
                    JobTaskNo := '';
                    BudgetCode := '';
                    Descripcion := '';
                    FechaFactura := 0D;
                    NumeroFactura := '';
                    ProveedorEmpleado := '';
                    NetoFactura := 0;
                    IGICOIVA := 0;
                    ImporteIGICOIVA := 0;
                    esProveedor := false;
                    esEmpleado := false;
                    IRPF := 0;
                    BrutoFactura := 0;
                    FechaVTO := 0D;
                    Estado := '';
                    FechaPago := 0D;
                    Budget := 0;
                    Tipo := '';
                    NoCuenta := '';
                    Fic := '';
                    RegistroPresupuestario := '';
                    FacturadoContra := '';
                    CIFProveedor := '';
                    ClasificacionGasto := '';
                    ImportedEntriesPagado := 0;
                    ImporteProduccion := 0;
                    ImporteNA := 0;
                    DescripcionProduccion := '';
                    // Buscar datos de esta fila
                    TempExcelBuffer.SetRange("Row No.", RowNo);
                    if TempExcelBuffer.FindSet() then
                        repeat
                            case TempExcelBuffer."Column No." of
                                1: // Columna A - CÓDIGO PRESUPUESTARIOBUSINESS CENTRAL (Job Task No.)
                                    JobTaskNo := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(JobTask."Job Task No."));
                                2: // Columna B - FIC
                                    FIC := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Fic));
                                3: // Columna C - Registro Presupuestario
                                    RegistroPresupuestario := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(RegistroPresupuestario));
                                4: // Columna D - CÓDIGO PRESUPUESTARIO
                                    BudgetCode := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(BudgetCode));
                                5: // Columna E - DESCRIPCIÓN
                                    Descripcion := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Descripcion));
                                6: // Columna F - Clasificación Gasto
                                    ClasificacionGasto := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(ClasificacionGasto));
                                7: //Columna G - FacturadoContra
                                    FacturadoContra := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(FacturadoContra));
                                9: // Columna I - FECHA FRA (Fecha Factura)
                                    begin
                                        if TempExcelBuffer."Cell Value as Text" <> '' then
                                            if not Evaluate(FechaFactura, TempExcelBuffer."Cell Value as Text") then
                                                FechaFactura := 0D;
                                    end;
                                10: // Columna J - NÚMERO DE FACTURA
                                    NumeroFactura := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(NumeroFactura));
                                11: // Columna K - CIF PRoveedor
                                    CIFProveedor := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(CIFProveedor));
                                12: // Columna L - PROVEEDOR / EMPLEADO
                                    ProveedorEmpleado := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(ProveedorEmpleado));
                                13: // Columna M - Descripcion2
                                    Descripcion2 := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Descripcion2));
                                14: // Columna N - Presupuesto
                                    if not Evaluate(Budget, TempExcelBuffer."Cell Value as Text") then
                                        Budget := 0;
                                15: // Columna O - NETO FACTURA
                                    if not Evaluate(NetoFactura, TempExcelBuffer."Cell Value as Text") then
                                        NetoFactura := 0;
                                16: // Columna P - IGIC O IVA
                                    if not Evaluate(IGICOIVA, TempExcelBuffer."Cell Value as Text") then
                                        IGICOIVA := 0;
                                17: // Columna Q - IMPORTE IGIC O IVA
                                    if not Evaluate(ImporteIGICOIVA, TempExcelBuffer."Cell Value as Text") then
                                        ImporteIGICOIVA := 0;
                                18: // Columna R - IRPF
                                    if not Evaluate(IRPF, TempExcelBuffer."Cell Value as Text") then
                                        IRPF := 0;
                                19: // Columna S - BRUTO FACTURA
                                    if not Evaluate(BrutoFactura, TempExcelBuffer."Cell Value as Text") then
                                        BrutoFactura := 0;
                                20: // Columna T - FECHA VTO
                                    begin
                                        if TempExcelBuffer."Cell Value as Text" <> '' then
                                            if not Evaluate(FechaVTO, TempExcelBuffer."Cell Value as Text") then
                                                FechaVTO := 0D;
                                    end;
                                21: // Columna U - ESTADO
                                    Estado := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Estado));
                                22:// COLUMNA V - PAGADO
                                    begin
                                        if TempExcelBuffer."Cell Value as Text" <> '' then
                                            if not Evaluate(ImportedEntriesPagado, TempExcelBuffer."Cell Value as Text") then
                                                ImportedEntriesPagado := 0;

                                    end;
                                24: // Columna X - FECHA DE PAGO
                                    begin
                                        if TempExcelBuffer."Cell Value as Text" <> '' then
                                            if not Evaluate(FechaPago, TempExcelBuffer."Cell Value as Text") then
                                                FechaPago := 0D;
                                    end;
                                29: // Columna AC - IMPORTE PRODUCCIÓN
                                    if not Evaluate(ImporteProduccion, TempExcelBuffer."Cell Value as Text") then
                                        ImporteProduccion := 0;
                                30: // Columna AD - IMPORTE N/A (resta del presupuesto línea normal)
                                    if not Evaluate(ImporteNA, TempExcelBuffer."Cell Value as Text") then
                                        ImporteNA := 0;
                                31: // Columna AE - Descripción producción
                                    DescripcionProduccion := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(DescripcionProduccion));
                            end;
                            If TempExcelBuffer.xlColID = '' Then TempExcelBuffer.Validate("Column No.");
                        //if TempExcelBuffer.xlColID = rInf."Cta Contable Mov" Then CtaCble := TempExcelBuffer."Cell Value as Text";
                        until TempExcelBuffer.Next() = 0;
                    If FacturadoContra <> '' Then begin
                        IcParter.SetRange("Inbox Details", FacturadoContra);
                        if Not IcParter.FindFirst() then Error('No existe el socio %1', FacturadoContra);
                    end;
                    // Si hay Job Task No., crear o verificar Job Task
                    if (JobTaskNo <> '') and (Descripcion <> '') then begin
                        ImportedEntries += 1;
                        if not JobTask.Get(JobNo, JobTaskNo) then begin
                            // Crear Job Task si no existe
                            JobTask.Init();
                            JobTask."Job No." := JobNo;
                            JobTask."Job Task No." := JobTaskNo;
                            JobTask.Description := Descripcion;
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            JobTask."WIP-Total" := JobTask."WIP-Total"::" ";
                            JobTask.Insert(true);
                        end else begin
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            JobTask.Modify(false);
                        end;

                        // Determinar el tipo y número de cuenta basándose en el proveedor/empleado o descripción
                        // Por defecto, usar G/L Account si no se puede determinar
                        Tipo := 'PRODUCTO';
                        NoCuenta := JobTaskNo;

                        // Intentar encontrar el proveedor o empleado
                        Vendor.Reset();
                        if (ProveedorEmpleado <> '') or (CIFProveedor <> '') then begin
                            If Not Vendor.Get(ProveedorEmpleado) then
                                Vendor.SetRange("VAT Registration No.", CIFProveedor)
                            else
                                Vendor.SetRange("No.", ProveedorEmpleado);
                            if Vendor.FindFirst() then begin
                                // Si es proveedor, usar la cuenta contable del proveedor
                                esProveedor := true;
                                ProveedorEmpleado := Vendor."No.";
                                Tipo := 'PRODUCTO';
                            end else Begin
                                Employee.SetRange(Name, ProveedorEmpleado);
                                if Employee.FindFirst() then begin
                                    // Si es empleado, usar el recurso asociado
                                    if Employee."Resource No." <> '' then begin
                                        if Resource.Get(Employee."Resource No.") then begin
                                            //NoCuenta := Resource."No.";
                                            //Tipo := 'RECURSO';
                                            esEmpleado := true;
                                        end;
                                    end;
                                end else
                                    ProveedorEmpleado := '';
                            end;
                        end else
                            Vendor.Init();

                        // // Si no se encontró cuenta, usar Budget Code como cuenta contable
                        // if NoCuenta = '' then begin
                        //     if Tipo = 'CUENTA' then begin
                        //         NoCuenta := CopyStr(BudgetCode, 1, MaxStrLen(NoCuenta));
                        //         // Verificar si es una cuenta contable válida
                        //         if not GLAccount.Get(NoCuenta) then begin
                        //             // Crear cuenta contable si no existe
                        //             GLAccount.Init();
                        //             GLAccount."No." := NoCuenta;
                        //             GLAccount.Name := CopyStr(Descripcion, 1, MaxStrLen(GLAccount.Name));
                        //             GLAccount."Account Type" := GLAccount."Account Type"::Posting;
                        //             GLAccount."Direct Posting" := true;
                        //             GLAccount.Insert(true);
                        //         end;
                        //         Tipo := 'CUENTA';
                        //     end;
                        // end;

                        // Solo crear Job Planning Line y Job Ledger Entry si hay una cuenta válida
                        if NoCuenta <> '' then begin
                            // Crear Job Planning Line si no existe para esta combinación
                            LineNo := 10000;
                            JobPlanningLine.Reset();
                            JobPlanningLine.SetRange("Job No.", JobNo);
                            if JobTask.Get(JobNo, JobTaskNo) Then begin
                                if JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting then begin
                                    JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                                    JobTask.Modify(false);
                                end;

                            end else begin

                            end;

                            if Not JobPlanningLine.FindLast() then
                                LineNo := JobPlanningLine."Line No." + 10000;

                            // Buscar si ya existe una línea de planificación para esta combinación
                            // JobPlanningLine.SetRange("Job No.", JobNo);
                            // JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
                            // JobPlanningLine.SetRange("No.", NoCuenta);
                            //if not JobPlanningLine.FindFirst() then begin
                            // Crear nueva Job Planning Line
                            JobPlanningLine.Init();
                            JobPlanningLine."Job No." := JobNo;
                            JobPlanningLine."Job Task No." := JobTaskNo;
                            JobPlanningLine."Line No." := LineNo;
                            JobPlanningLine."Facturado Contra" := FacturadoContra;
                            JobPlanningLine.Categorias := ClasificacionGasto;
                            If Not Categorias.Get(ClasificacionGasto) then begin
                                Categorias.Init();
                                Categorias.Code := ClasificacionGasto;
                                Categorias.Description := ClasificacionGasto;
                                Categorias.Insert();
                            end;
                            // Determinar Type según el Tipo
                            case UpperCase(Tipo) of
                                'CUENTA', 'G/L ACCOUNT', 'GL ACCOUNT':
                                    begin
                                        JobPlanningLine."Type" := JobPlanningLine."Type"::"G/L Account";
                                        JobPlanningLine."No." := NoCuenta;
                                    end;
                                'PRODUCTO', 'ITEM':
                                    begin
                                        JobPlanningLine."Type" := JobPlanningLine."Type"::Item;
                                        JobPlanningLine."No." := NoCuenta;

                                        if not Item.Get(NoCuenta) then begin
                                            Item.Init();
                                            Item."No." := NoCuenta;
                                            // Item."Gen. Prod. Posting Group" := BudgetCode; //Item."No.";
                                            Item.Description := CopyStr(Descripcion, 1, MaxStrLen(Item.Description));
                                            JobsSetup.Get();
                                            ItemTempl.Get(JobsSetup."Item Template");
                                            // Si el Item Template está configurado, usarlo
                                            if (JobsSetup."Item Template" <> '') and ItemTempl.Get(JobsSetup."Item Template") then begin
                                                // Usar el template para crear el Item
                                                ItemTemplMgt.CreateItemFromTemplate(Item, Ishandled, JobsSetup."Item Template");
                                                // If Item.Get(NoCuenta) then begin
                                                //     //Grear Grupo registro prodducto por producto


                                                //     Item.Modify(true);
                                                // end;
                                            end else begin
                                                // Si no hay template configurado, Error
                                                Error('No hay template configurado para crear el Producto %1', NoCuenta);
                                            end;

                                        end;
                                        // If Not GenProdPostingGroup.Get(BudgetCode) Then begin//Item."Gen. Prod. Posting Group") then begin
                                        //     GenProdPostingGroup.Init();
                                        //     GenProdPostingGroup."Code" := BudgetCode; //Item."Gen. Prod. Posting Group";
                                        //     GenProdPostingGroup.Description := Descripcion; // Item."Gen. Prod. Posting Group";
                                        //     GenProdPostingGroup.Insert(true);
                                        // end;
                                        // If GenNegPostingGrup.FindFirst Then
                                        //     repeat
                                        //         if Not GenPostingSetup.Get(GenNegPostingGrup.Code, GenProdPostingGroup.Code) Then begin
                                        //             GenPostingSetup.Init;
                                        //             GenPostingSetup."Gen. Bus. Posting Group" := GenNegPostingGrup.Code;
                                        //             GenPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup.Code;

                                        //             GenPostingSetup.Insert();
                                        //         end;
                                        //         GenPostingSetup."Purch. Account" := CtaCble;
                                        //         GenPostingSetup.Modify();
                                        //     until GenNegPostingGrup.next = 0;

                                    end;
                                'RECURSO', 'RESOURCE':
                                    begin
                                        JobPlanningLine."Type" := JobPlanningLine."Type"::Resource;
                                        JobPlanningLine."No." := NoCuenta;
                                    end;
                            end;

                            BudgetNormal := 0;
                            EsDesdobleProduccion := ImporteProduccion <> 0;
                            if EsDesdobleProduccion then begin
                                if DescripcionProduccion = '' then
                                    Error('Si informa importe producción (col. AC), debe indicar la descripción de producción (col. AE).');
                                if Budget < ImporteProduccion then
                                    Error(
                                      'El importe producción (col. AC) %1 no puede superar el presupuesto (col. N) %2.',
                                      ImporteProduccion, Budget);
                                // Línea normal: presupuesto (N) menos producción (AC). Col. AD (Importe N/A) se lee por si se usa en informes; no resta del presupuesto aquí.
                                BudgetNormal := Budget - ImporteProduccion;
                            end;

                            JobPlanningLine.Description := Descripcion;
                            JobPlanningLine.Quantity := 1;
                            if BrutoFactura <> 0 then begin
                                // JobPlanningLine."Unit Cost (LCY)" := BrutoFactura; // DFS DESCOMENTÉ POR LO DE LOS TOTALES
                                // JobPlanningLine."Total Cost (LCY)" := BrutoFactura; // DFS DESCOMENTÉ POR LO DE LOS TOTALES

                            end;
                            if EsDesdobleProduccion then begin
                                if BudgetNormal <> 0 then begin
                                    JobPlanningLine."Total Cost (LCY)" := BudgetNormal;
                                    JobPlanningLine."Unit Cost (LCY)" := BudgetNormal;
                                    JobPlanningLine."Total Cost" := BudgetNormal;
                                    JobPlanningLine."Unit Cost" := BudgetNormal;
                                    JobPlanningLine."Schedule Line" := true;
                                end else begin
                                    JobPlanningLine."Total Cost (LCY)" := 0;
                                    JobPlanningLine."Unit Cost (LCY)" := 0;
                                    JobPlanningLine."Total Cost" := 0;
                                    JobPlanningLine."Unit Cost" := 0;
                                    JobPlanningLine."Schedule Line" := false;
                                end;
                                JobPlanningLine.Validate(Producción, false);

                            end else
                                if Budget <> 0 then begin
                                    JobPlanningLine."Total Cost (LCY)" := Budget;
                                    JobPlanningLine."Unit Cost (LCY)" := Budget;
                                    JobPlanningLine."Total Cost" := Budget;
                                    JobPlanningLine."Unit Cost" := Budget;
                                    JobPlanningLine."Schedule Line" := true;
                                    JobPlanningLine.Validate(Producción, false);
                                end;
                            If FacturadoContra <> '' Then begin
                                IcParter.SetRange("Inbox Details", FacturadoContra);
                                if Not IcParter.FindFirst() then Error('No existe el socio %1', FacturadoContra);
                                IcParter.TestField("Customer No.");
                                JobPlanningLine."Bill-to Customer No." := IcParter."Customer No.";
                            end;
                            if esProveedor then begin
                                JobPlanningLine.Validate("Cod_Proveedor", Vendor."No.");
                            end;
                            JobPlanningLine."Usage Link" := true;
                            If (JobPlanningLine."Total Cost (LCY)" <> 0) Then begin
                                repeat
                                    JobPlanningLine."Line No." := LineNo;
                                    LineNo += 10000;
                                until JobPlanningLine.Insert(true);
                            end;

                            if EsDesdobleProduccion then begin
                                JobPlanningLineNormal := JobPlanningLine;
                                JobPlanningLineProd := JobPlanningLineNormal;
                                LineNo := JobPlanningLineNormal."Line No." + 10000;
                                JobPlanningLineProd."Total Cost (LCY)" := ImporteProduccion;
                                JobPlanningLineProd."Unit Cost (LCY)" := ImporteProduccion;
                                JobPlanningLineProd."Total Cost" := ImporteProduccion;
                                JobPlanningLineProd."Unit Cost" := ImporteProduccion;
                                JobPlanningLineProd."Schedule Line" := true;
                                JobPlanningLineProd.Description := DescripcionProduccion;
                                JobPlanningLineProd.Validate(Producción, true);
                                repeat
                                    JobPlanningLineProd."Line No." := LineNo;
                                    LineNo += 10000;
                                until JobPlanningLineProd.Insert(true);
                            end;

                            //end;

                            if (ImportedEntriesPagado <> 0) then begin
                                ProyectoMovimientoPago.SetRange("Job No.", JobNo);
                                ProyectoMovimientoPago.SetRange("Document No.", CopyStr(NumeroFactura, 1, MaxStrLen(ProyectoMovimientoPago."Document No.")));
                                ProyectoMovimientoPago.SetRange("Job Task No.", JobTaskNo);
                                ProyectoMovimientoPago.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
                                if ProyectoMovimientoPago.FindLast() then
                                    LineNo := ProyectoMovimientoPago."Line No." + 10000
                                else
                                    LineNo := 10000;
                                ProyectoMovimientoPago.Init();
                                if esProveedor then
                                    ProyectoMovimientoPago."Document Type" := ProyectoMovimientoPago."Document Type"::Invoice
                                else
                                    ProyectoMovimientoPago."Document Type" := ProyectoMovimientoPago."Document Type"::" ";
                                if esProveedor then
                                    ProyectoMovimientoPago."Vendor No." := Vendor."No."
                                else
                                    ProyectoMovimientoPago."Vendor No." := Employee."No.";
                                ProyectoMovimientoPago."Document Type" := ProyectoMovimientoPago."Document Type"::" ";
                                ProyectoMovimientoPago."Document No." := CopyStr(NumeroFactura, 1, MaxStrLen(ProyectoMovimientoPago."Document No."));
                                ProyectoMovimientoPago."Job Entry No." := JobLedgerEntry."Entry No.";
                                ProyectoMovimientoPago."Line No." := 0;
                                ProyectoMovimientoPago."Job No." := JobNo;
                                ProyectoMovimientoPago."Job Task No." := JobTaskNo;
                                ProyectoMovimientoPago.Validate("Amount Paid", ImportedEntriesPagado);
                                if ProyectoMovimientoPago."Amount Paid" = BrutoFactura Then begin
                                    ProyectoMovimientoPago."Base Amount Paid" := NetoFactura;
                                end else
                                    if BrutoFactura <> 0 then
                                        //calcular en base al % del pruto sobre el importe pagado
                                        ProyectoMovimientoPago."Base Amount Paid" := ImportedEntriesPagado * NetoFactura / BrutoFactura;

                                // if EsDesdobleProduccion then begin
                                //     ProyectoMovimientoPago."Job Planning Line No." := JobPlanningLineNormal."Line No.";
                                //     ProyectoMovimientoPago.Producción := JobPlanningLineNormal.Producción;
                                // end else begin
                                //     ProyectoMovimientoPago."Job Planning Line No." := JobPlanningLine."Line No.";
                                //     ProyectoMovimientoPago.Producción := JobPlanningLine.Producción;
                                // end;
                                repeat
                                    ProyectoMovimientoPago."Line No." := LineNo;
                                    LineNo += 10000;
                                until ProyectoMovimientoPago.Insert();
                            end;

                            // Verificar si ya existe un Job Ledger Entry con los mismos datos para evitar duplicados
                            // Si NetoFactura+BrutoFactura no es 0, creo el Movimiento de Proyecto con el NetoFactura y el BrutoFactura
                            if NetoFactura + BrutoFactura <> 0 then begin
                                JobLedgerEntry.Reset();
                                if JobLedgerEntry.FindLast() then
                                    LineNo := JobLedgerEntry."Entry No." + 1
                                else
                                    LineNo := 1;
                                if Desde = 0 Then Desde := LineNo;
                                JobLedgerEntry.Init();
                                JobLedgerEntry."Entry No." := LineNo;
                                JobLedgerEntry."Job No." := JobNo;
                                JobLedgerEntry."Job Task No." := JobTaskNo;
                                //JobLedgerEntry."Job Planning Line No." := JobPlanningLine."Line No.";
                                JobLedgerEntry."Posting Date" := Today;
                                if FechaFactura <> 0D then
                                    JobLedgerEntry."Posting Date" := FechaFactura;

                                // Determinar Type según el Tipo
                                case UpperCase(Tipo) of
                                    'CUENTA', 'G/L ACCOUNT', 'GL ACCOUNT':
                                        begin
                                            JobLedgerEntry."Type" := JobLedgerEntry."Type"::"G/L Account";
                                            JobLedgerEntry."No." := NoCuenta;
                                        end;
                                    'PRODUCTO', 'ITEM':
                                        begin
                                            JobLedgerEntry."Type" := JobLedgerEntry."Type"::Item;
                                            JobLedgerEntry."No." := NoCuenta;
                                        end;
                                    'RECURSO', 'RESOURCE':
                                        begin
                                            JobLedgerEntry."Type" := JobLedgerEntry."Type"::Resource;
                                            JobLedgerEntry."No." := NoCuenta;
                                        end;
                                end;

                                JobLedgerEntry.Description := Descripcion;
                                JobLedgerEntry.Quantity := 1;
                                if NetoFactura <> 0 then begin
                                    //   JobLedgerEntry."Unit Cost" := BrutoFactura;   DFS
                                    JobLedgerEntry."Unit Cost (LCY)" := NetoFactura;   //DFS    

                                    // JobLedgerEntry."Total Cost" := BrutoFactura;  //DFS
                                    JobLedgerEntry."Total Cost (LCY)" := NetoFactura;
                                    JobLedgerEntry."Total Cost" := NetoFactura;
                                    JobLedgerEntry."Unit Cost" := NetoFactura;
                                end;

                                // Campos personalizados
                                JobLedgerEntry."Budget Code" := BudgetCode;
                                JobLedgerEntry."Neto Factura" := NetoFactura;
                                JobLedgerEntry."Base Amount Pending" := NetoFactura;
                                JobLedgerEntry."Amount Pending" := BrutoFactura;
                                JobLedgerEntry."IGIC O IVA" := IGICOIVA;
                                JobLedgerEntry."Importe IGIC O IVA" := ImporteIGICOIVA;
                                JobLedgerEntry."IRPF" := IRPF;
                                JobLedgerEntry."Bruto Factura" := BrutoFactura;
                                JobLedgerEntry."Fecha VTO" := FechaVTO;
                                JobLedgerEntry."Estado" := Estado;

                                if NumeroFactura <> '' then begin
                                    JobLedgerEntry."Document No." := CopyStr(NumeroFactura, 1, MaxStrLen(JobLedgerEntry."Document No."));
                                    JobLedgerEntry."External Document No." := CopyStr(NumeroFactura, 1, MaxStrLen(JobLedgerEntry."External Document No."));
                                end;

                                JobLedgerEntry."Fecha Pago" := FechaPago;
                                JobLedgerEntry."NombreProveedor o Empleado" := ProveedorEmpleado;
                                JobLedgerEntry."Facturado Contra" := FacturadoContra;
                                JobLedgerEntry."FIC" := FIC;
                                JobLedgerEntry."RegistroPresupuestario" := RegistroPresupuestario;
                                JobLedgerEntry.Producción := EsDesdobleProduccion;
                                // if EsDesdobleProduccion then begin
                                //     JobLedgerEntry.Producción := JobPlanningLineNormal.Producción;
                                //     Eventosproyectos.AssignDimensionProduction(JobLedgerEntry, JobPlanningLineNormal);
                                // end else begin
                                //     JobLedgerEntry.Producción := JobPlanningLine.Producción;
                                //     Eventosproyectos.AssignDimensionProduction(JobLedgerEntry, JobPlanningLine);
                                // end;
                                repeat
                                    JobLedgerEntry."Entry No." := LineNo;
                                    LineNo += 1;
                                until JobLedgerEntry.Insert();
                                //ImportedEntries += 1;
                            end;

                        end; // Cerrar if NoCuenta <> ''
                    end; // Cerrar if (JobTaskNo <> '') and (Descripcion <> '')

                    // Restaurar filtro para siguiente iteración
                    TempExcelBuffer.SetRange("Row No.");
                end;
            until TempExcelBuffer.Next() = 0;
        RegistroProyectos.Init();
        RegistroProyectos."No." := IdJobRegister;
        RegistroProyectos."Creation Date" := Today;
        RegistroProyectos."Creation Time" := Time;
        RegistroProyectos."From Entry No." := Desde;
        RegistroProyectos."To Entry No." := LineNo;
        RegistroProyectos."User ID" := UserId;
        RegistroProyectos.Insert();

        Message('Se importaron %1 movimientos correctamente.', ImportedEntries);
    end;

    local procedure NormalizarEncabezadoNomina(Texto: Text): Text
    begin
        Texto := UpperCase(Texto);
        Texto := DelChr(Texto, '=', ' ');
        Texto := DelChr(Texto, '=', '.');
        Texto := DelChr(Texto, '=', '/');
        Texto := DelChr(Texto, '=', '(');
        Texto := DelChr(Texto, '=', ')');
        Texto := QuitarAcentosNomina(Texto);
        exit(Texto);
    end;

    local procedure QuitarAcentosNomina(Texto: Text): Text
    var
        Desde: Text;
        Hasta: Text;
        i: Integer;
        CarDesde: Text;
        CarHasta: Text;
        Pos: Integer;
    begin
        Desde := 'ÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
        Hasta := 'AAAAEEEEIIIIOOOOUUUUN';
        for i := 1 to StrLen(Desde) do begin
            CarDesde := CopyStr(Desde, i, 1);
            CarHasta := CopyStr(Hasta, i, 1);
            Pos := StrPos(Texto, CarDesde);
            while Pos > 0 do begin
                Texto := CopyStr(Texto, 1, Pos - 1) + CarHasta + CopyStr(Texto, Pos + 1);
                Pos := StrPos(Texto, CarDesde);
            end;
        end;
        exit(Texto);
    end;

    local procedure RemoverCaracterDeTexto(Texto: Text; Caracter: Text[1]): Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(Texto, Caracter);
        while Pos > 0 do begin
            Texto := CopyStr(Texto, 1, Pos - 1) + CopyStr(Texto, Pos + 1);
            Pos := StrPos(Texto, Caracter);
        end;
        exit(Texto);
    end;

    local procedure ConvertirDecimalTextoExcel(Texto: Text): Text
    var
        PosComa: Integer;
        PosPunto: Integer;
        UltimoSep: Integer;
        i: Integer;
        Car: Text[1];
        DigitosTrasSep: Integer;
    begin
        Texto := DelChr(Texto, '=', ' ');
        Texto := RemoverCaracterDeTexto(Texto, '€');
        if Texto = '' then
            exit('');

        PosComa := 0;
        PosPunto := 0;
        for i := StrLen(Texto) downto 1 do begin
            Car := CopyStr(Texto, i, 1);
            if (Car = ',') and (PosComa = 0) then
                PosComa := i;
            if (Car = '.') and (PosPunto = 0) then
                PosPunto := i;
        end;

        if (PosComa > 0) and (PosPunto > 0) then begin
            if PosComa > PosPunto then begin
                // Europeo: 12.933,28
                Texto := RemoverCaracterDeTexto(Texto, '.');
                PosComa := StrPos(Texto, ',');
                if PosComa > 0 then
                    Texto := CopyStr(Texto, 1, PosComa - 1) + '.' + CopyStr(Texto, PosComa + 1);
            end else
                // Americano: 12,933.28
                Texto := RemoverCaracterDeTexto(Texto, ',');
        end else
            if PosComa > 0 then
                Texto := CopyStr(Texto, 1, PosComa - 1) + '.' + CopyStr(Texto, PosComa + 1)
            else
                if PosPunto > 0 then begin
                    DigitosTrasSep := StrLen(Texto) - PosPunto;
                    if DigitosTrasSep = 3 then
                        Texto := RemoverCaracterDeTexto(Texto, '.');
                end;

        exit(Texto);
    end;

    local procedure LeerTextoCeldaExcel(var ExcelBuff: Record "Excel Buffer" temporary; Fila: Integer; Columna: Integer): Text
    begin
        if Columna <= 0 then
            exit('');
        ExcelBuff.Reset();
        ExcelBuff.SetRange("Row No.", Fila);
        ExcelBuff.SetRange("Column No.", Columna);
        if ExcelBuff.FindFirst() then
            exit(ExcelBuff."Cell Value as Text");
        exit('');
    end;

    local procedure CaracterADigito(Car: Text[1]): Integer
    begin
        case Car of
            '0':
                exit(0);
            '1':
                exit(1);
            '2':
                exit(2);
            '3':
                exit(3);
            '4':
                exit(4);
            '5':
                exit(5);
            '6':
                exit(6);
            '7':
                exit(7);
            '8':
                exit(8);
            '9':
                exit(9);
            else
                exit(-1);
        end;
    end;

    local procedure CadenaDigitosADecimal(ParteEntera: Text; ParteDecimal: Text): Decimal
    var
        Entero: Decimal;
        Fraccion: Decimal;
        Divisor: Decimal;
        i: Integer;
        Car: Text[1];
        Dig: Integer;
    begin
        Entero := 0;
        for i := 1 to StrLen(ParteEntera) do begin
            Car := CopyStr(ParteEntera, i, 1);
            Dig := CaracterADigito(Car);
            if Dig >= 0 then
                Entero := Entero * 10 + Dig;
        end;

        if ParteDecimal = '' then
            exit(Entero);

        Fraccion := 0;
        Divisor := 1;
        for i := 1 to StrLen(ParteDecimal) do begin
            Car := CopyStr(ParteDecimal, i, 1);
            Dig := CaracterADigito(Car);
            if Dig >= 0 then begin
                Fraccion := Fraccion * 10 + Dig;
                Divisor := Divisor * 10;
            end;
        end;

        exit(Entero + (Fraccion / Divisor));
    end;

    /// <summary>
    /// Convierte texto numérico sin usar Evaluate (evita locale ES: punto=miles).
    /// </summary>
    local procedure TextoADecimalInvariante(Texto: Text; ValorAbsoluto: Boolean): Decimal
    var
        TextoNorm: Text;
        ParteEntera: Text;
        ParteDecimal: Text;
        Pos: Integer;
        Negativo: Boolean;
        Resultado: Decimal;
    begin
        Texto := DelChr(Texto, '=', ' ');
        if Texto = '' then
            exit(0);

        Negativo := CopyStr(Texto, 1, 1) = '-';
        if Negativo then
            Texto := CopyStr(Texto, 2);

        TextoNorm := ConvertirDecimalTextoExcel(Texto);
        if TextoNorm = '' then
            exit(0);

        Pos := StrPos(TextoNorm, '.');
        if Pos > 0 then begin
            ParteEntera := CopyStr(TextoNorm, 1, Pos - 1);
            ParteDecimal := CopyStr(TextoNorm, Pos + 1);
        end else begin
            ParteEntera := TextoNorm;
            ParteDecimal := '';
        end;

        if ParteEntera = '' then
            ParteEntera := '0';

        Resultado := CadenaDigitosADecimal(ParteEntera, ParteDecimal);
        if Negativo then
            Resultado := -Resultado;
        if ValorAbsoluto then
            Resultado := Abs(Resultado);
        exit(Resultado);
    end;

    local procedure ImporteDesdeRegistroCeldaExcel(ExcelBuff: Record "Excel Buffer" temporary; ValorAbsoluto: Boolean): Decimal
    begin
        exit(TextoADecimalInvariante(ExcelBuff."Cell Value as Text", ValorAbsoluto));
    end;

    local procedure LeerImportesFilaNomina(
        var ExcelBuff: Record "Excel Buffer" temporary;
        Fila: Integer;
        ColDevengado: Integer;
        ColSSObrero: Integer;
        ColIRPF: Integer;
        ColSSEmpresa: Integer;
        ColEnfermedadAccidente: Integer;
        ColBonificacion: Integer;
        ColBonificacionFundae: Integer;
        ColBanco: Integer;
        ColKms: Integer;
        ColDieta: Integer;
        ColPPEx: Integer;
        ColMejoraV: Integer;
        ColComida: Integer;
        ColDietas: Integer;
        ColPPVaca: Integer;
        ColPLFlex: Integer;
        ColIndemni: Integer;
        ColAntDiet: Integer;
        ColAnticipos: Integer;
        ColEmbargos: Integer;
        var Devengado: Decimal;
        var SSObrero: Decimal;
        var IRPF: Decimal;
        var SSEmpresa: Decimal;
        var EnfermedadAccidente: Decimal;
        var Bonificacion: Decimal;
        var BonificacionFundae: Decimal;
        var Anticipos: Decimal;
        var Embargos: Decimal;
        var Dieta: Decimal;
        var Kms: Decimal;
        var Banco: Decimal;
        var PPEx: Decimal;
        var MejoraV: Decimal;
        var Comida: Decimal;
        var Dietas: Decimal;
        var PPVaca: Decimal;
        var PLFlex: Decimal;
        var Indemni: Decimal;
        var AntDiet: Decimal)
    var
        ColNo: Integer;
    begin
        Devengado := 0;
        SSObrero := 0;
        IRPF := 0;
        SSEmpresa := 0;
        EnfermedadAccidente := 0;
        Bonificacion := 0;
        BonificacionFundae := 0;
        Anticipos := 0;
        Embargos := 0;
        Dieta := 0;
        Kms := 0;
        Banco := 0;
        PPEx := 0;
        MejoraV := 0;
        Comida := 0;
        Dietas := 0;
        PPVaca := 0;
        PLFlex := 0;
        Indemni := 0;
        AntDiet := 0;

        ExcelBuff.Reset();
        ExcelBuff.SetRange("Row No.", Fila);
        if not ExcelBuff.FindSet() then
            exit;

        repeat
            ColNo := ExcelBuff."Column No.";
            if ColNo = ColDevengado then
                Devengado := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColSSObrero then
                SSObrero := ImporteDesdeRegistroCeldaExcel(ExcelBuff, true);
            if ColNo = ColIRPF then
                IRPF := ImporteDesdeRegistroCeldaExcel(ExcelBuff, true);
            if ColNo = ColSSEmpresa then
                SSEmpresa := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColEnfermedadAccidente then
                EnfermedadAccidente := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColBonificacion then
                Bonificacion := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColBonificacionFundae then
                BonificacionFundae := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColAnticipos then
                Anticipos := ImporteDesdeRegistroCeldaExcel(ExcelBuff, true);
            if ColNo = ColEmbargos then
                Embargos := ImporteDesdeRegistroCeldaExcel(ExcelBuff, true);
            if ColNo = ColDieta then
                Dieta := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColKms then
                Kms := ImporteDesdeRegistroCeldaExcel(ExcelBuff, true);
            if ColNo = ColBanco then
                Banco := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColPPEx then
                PPEx := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColMejoraV then
                MejoraV := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColComida then
                Comida := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColDietas then
                Dietas := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColPPVaca then
                PPVaca := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColPLFlex then
                PLFlex := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColIndemni then
                Indemni := ImporteDesdeRegistroCeldaExcel(ExcelBuff, false);
            if ColNo = ColAntDiet then
                AntDiet := ABS(ImporteDesdeRegistroCeldaExcel(ExcelBuff, true));
        until ExcelBuff.Next() = 0;

        // Respaldo: lectura directa por columna (por si FindSet no devolvió alguna celda)
        if ColDevengado > 0 then
            if Devengado = 0 then
                Devengado := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColDevengado), false);
        if ColBanco > 0 then
            if Banco = 0 then
                Banco := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColBanco), false);
        if ColSSObrero > 0 then
            if SSObrero = 0 then
                SSObrero := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColSSObrero), true);
        if ColIRPF > 0 then
            if IRPF = 0 then
                IRPF := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColIRPF), true);
        if ColSSEmpresa > 0 then
            if SSEmpresa = 0 then
                SSEmpresa := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColSSEmpresa), false);
    end;

    local procedure TextoContieneDigitos(Texto: Text): Boolean
    var
        i: Integer;
        Car: Text[1];
    begin
        for i := 1 to StrLen(Texto) do begin
            Car := CopyStr(Texto, i, 1);
            if Car in ['0' .. '9'] then
                exit(true);
        end;
        exit(false);
    end;

    local procedure EsTextoCodigoEmpleado(Texto: Text): Boolean
    begin
        if Texto = '' then
            exit(false);
        if StrLen(Texto) > 20 then
            exit(false);
        // Columna C = nombre (p. ej. MARCIAS PEREZ...); no usarlo como código
        if (StrLen(Texto) > 10) and (not TextoContieneDigitos(Texto)) then
            exit(false);
        exit(true);
    end;

    local procedure ExtraerCodigoDesdeCeldaTrabajador(Texto: Text): Text
    var
        i: Integer;
        Car: Text[1];
        Codigo: Text;
        EnCodigo: Boolean;
    begin
        Texto := DelChr(Texto, '=', ' ');
        if Texto = '' then
            exit('');

        EnCodigo := false;
        for i := 1 to StrLen(Texto) do begin
            Car := CopyStr(Texto, i, 1);
            if Car in ['0' .. '9'] then begin
                Codigo += Car;
                EnCodigo := true;
            end else
                if EnCodigo then
                    exit(Codigo);
        end;
        exit(Codigo);
    end;

    local procedure ObtenerCodigoEmpleadoFila(var ExcelBuff: Record "Excel Buffer" temporary; Fila: Integer): Text
    var
        Codigo: Text;
        TextoCelda: Text;
    begin
        // Plantilla AF: código col. B (2); a veces código+nombre juntos en col. C (3)
        Codigo := DelChr(LeerTextoCeldaExcel(ExcelBuff, Fila, 2), '=', ' ');
        if EsTextoCodigoEmpleado(Codigo) then
            exit(CopyStr(Codigo, 1, 20));

        TextoCelda := LeerTextoCeldaExcel(ExcelBuff, Fila, 3);
        Codigo := ExtraerCodigoDesdeCeldaTrabajador(TextoCelda);
        if EsTextoCodigoEmpleado(Codigo) then
            exit(CopyStr(Codigo, 1, 20));

        Codigo := DelChr(LeerTextoCeldaExcel(ExcelBuff, Fila, 1), '=', ' ');
        if EsTextoCodigoEmpleado(Codigo) then
            exit(CopyStr(Codigo, 1, 20));
        exit('');
    end;

    local procedure EsFilaEmpleadoNomina(var ExcelBuff: Record "Excel Buffer" temporary; Fila: Integer): Boolean
    var
        Codigo: Text;
    begin
        Codigo := ObtenerCodigoEmpleadoFila(ExcelBuff, Fila);
        if not EsTextoCodigoEmpleado(Codigo) then
            exit(false);
        if CopyStr(UpperCase(Codigo), 1, 7) = 'SECCIÓN' then
            exit(false);
        if StrPos(UpperCase(Codigo), 'TOTAL') > 0 then
            exit(false);
        exit(true);
    end;

    local procedure FilaTieneImportesNomina(
        Devengado: Decimal;
        Banco: Decimal;
        SSObrero: Decimal;
        IRPF: Decimal;
        SSEmpresa: Decimal): Boolean
    begin
        exit((Devengado <> 0) or (Banco <> 0) or (SSObrero <> 0) or (IRPF <> 0) or (SSEmpresa <> 0));
    end;

    local procedure BuscarFilaInicioDatosNomina(
        var ExcelBuff: Record "Excel Buffer" temporary;
        FilaEncabezados: Integer;
        ColDevengado: Integer;
        ColBanco: Integer;
        ColSSObrero: Integer;
        ColIRPF: Integer;
        ColSSEmpresa: Integer): Integer
    var
        Fila: Integer;
        Devengado: Decimal;
        Banco: Decimal;
        SSObrero: Decimal;
        IRPF: Decimal;
        SSEmpresa: Decimal;
    begin
        for Fila := FilaEncabezados + 1 to FilaEncabezados + 15 do
            if EsFilaEmpleadoNomina(ExcelBuff, Fila) then begin
                Devengado := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColDevengado), false);
                Banco := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColBanco), false);
                SSObrero := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColSSObrero), true);
                IRPF := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColIRPF), true);
                SSEmpresa := TextoADecimalInvariante(LeerTextoCeldaExcel(ExcelBuff, Fila, ColSSEmpresa), false);
                if FilaTieneImportesNomina(Devengado, Banco, SSObrero, IRPF, SSEmpresa) then
                    exit(Fila);
            end;
        exit(FilaEncabezados + 1);
    end;

    local procedure ExtraerDepartamentoDesdeCentro(Texto: Text): Code[20]
    var
        Pos: Integer;
        Resto: Text;
    begin
        if Texto = '' then
            exit('');
        Pos := StrPos(Texto, ' - ');
        if Pos > 0 then begin
            Resto := CopyStr(Texto, Pos + 3);
            Resto := DelChr(Resto, '<>', ' ');
            exit(CopyStr(Resto, 1, 20));
        end;
        exit(ExtraerUltimaPalabra(Texto));
    end;

    local procedure IdentificarColumnasPlantillaNomina(
        var ExcelBuff: Record "Excel Buffer" temporary;
        FilaEncabezados: Integer;
        var ColDevengado: Integer;
        var ColSSObrero: Integer;
        var ColIRPF: Integer;
        var ColSSEmpresa: Integer;
        var ColCosteEmpresa: Integer;
        var ColEnfermedadAccidente: Integer;
        var ColBonificacion: Integer;
        var ColBonificacionFundae: Integer;
        var ColBanco: Integer;
        var ColKms: Integer;
        var ColDieta: Integer;
        var ColPPEx: Integer;
        var ColMejoraV: Integer;
        var ColComida: Integer;
        var ColDietas: Integer;
        var ColPPVaca: Integer;
        var ColPLFlex: Integer;
        var ColIndemni: Integer;
        var ColAntDiet: Integer;
        var ColAnticipos: Integer;
        var ColEmbargos: Integer)
    var
        j: Integer;
        As: Text;
    begin
        ColDevengado := 0;
        ColSSObrero := 0;
        ColIRPF := 0;
        ColSSEmpresa := 0;
        ColCosteEmpresa := 0;
        ColEnfermedadAccidente := 0;
        ColBonificacion := 0;
        ColBonificacionFundae := 0;
        ColBanco := 0;
        ColKms := 0;
        ColDieta := 0;
        ColPPEx := 0;
        ColMejoraV := 0;
        ColComida := 0;
        ColDietas := 0;
        ColPPVaca := 0;
        ColPLFlex := 0;
        ColIndemni := 0;
        ColAntDiet := 0;
        ColAnticipos := 0;
        ColEmbargos := 0;

        for j := 1 to 48 do begin
            As := NormalizarEncabezadoNomina(LeerTextoCeldaExcel(ExcelBuff, FilaEncabezados, j));
            if As <> '' then
                if StrPos(As, 'DIETASANT') > 0 then
                    ColAntDiet := j
                else if StrPos(As, 'DIETASEXE') > 0 then
                    ColDietas := j
                else if (StrPos(As, 'DIETAS') > 0) and (StrPos(As, 'ANT') = 0) and (StrPos(As, 'EXE') = 0) then
                    ColDietas := j
                else if (StrPos(As, 'TBRUTO') > 0) or (StrPos(As, 'TOTBRUTO') > 0) then
                    ColDevengado := j
                else if (StrPos(As, 'TLIQUIDO') > 0) or (StrPos(As, 'TOTALLIQ') > 0) or (StrPos(As, 'BANCO') > 0) then
                    ColBanco := j
                else if (StrPos(As, 'SSOBRERA') > 0) or (StrPos(As, 'SSTRAB') > 0) or (StrPos(As, 'SSTRABAJADOR') > 0) or (StrPos(As, 'SEGURIDADSOCIALTRAB') > 0) then
                    ColSSObrero := j
                else if StrPos(As, 'SSEMPRESA') > 0 then
                    ColSSEmpresa := j
                else if (StrPos(As, 'CUOTAIRPF') > 0) or ((StrPos(As, 'IRPF') > 0) and (StrPos(As, 'BASE') = 0)) then
                    ColIRPF := j
                else if (StrPos(As, 'REDBON') > 0) or ((StrPos(As, 'BONIFIC') > 0) and (StrPos(As, 'FUNDAE') = 0)) then
                    ColBonificacion := j
                else if StrPos(As, 'FUNDAE') > 0 then
                    ColBonificacionFundae := j
                else if StrPos(As, 'TOTALTC1') > 0 then
                    ColEnfermedadAccidente := j
                else if StrPos(As, 'ANTICIPOS') > 0 then
                    ColAnticipos := j
                else if (StrPos(As, 'ANTIKM') > 0) or (StrPos(As, 'ANTKM') > 0) then
                    ColKms := j
                else if StrPos(As, 'SBASE') > 0 then
                    ColPPEx := j
                else if (StrPos(As, 'MEJORAVOL') > 0) or (StrPos(As, 'MEJORA') > 0) then
                    ColMejoraV := j
                else if (StrPos(As, 'PLUSFLEX') > 0) or (StrPos(As, 'PLFLEX') > 0) then
                    ColPLFlex := j
                else if StrPos(As, 'PERNOCTAS') > 0 then
                    ColDieta := j
                else if (StrPos(As, 'COMIDAS') > 0) or (StrPos(As, 'COMIDA') > 0) then
                    ColComida := j
                else if (As = 'KM') or (StrPos(As, 'KMS') = 1) then
                    ColKms := j
                else if (StrPos(As, 'INDEMNIZAC') > 0) or (StrPos(As, 'INDEMNI') > 0) then
                    ColIndemni := j
                else if (StrPos(As, 'VACACIONES') > 0) or (StrPos(As, 'PPVACA') > 0) then
                    ColPPVaca := j
                else if StrPos(As, 'EMBARGO') > 0 then
                    ColEmbargos := j
                else if (StrPos(As, 'COSTEEMPR') > 0) or (StrPos(As, 'COSTEEMP') > 0) then
                    ColCosteEmpresa := j
                else if (StrPos(As, 'ENFERMEDAD') > 0) or (StrPos(As, 'ACCIDENTE') > 0) or (StrPos(As, 'BASEACC') > 0) then
                    ColEnfermedadAccidente := j
                else if (StrPos(As, '0030') > 0) or (StrPos(As, 'PPEX') > 0) then
                    ColPPEx := j
                else if StrPos(As, '0038') > 0 then
                    ColMejoraV := j
                else if StrPos(As, '0140') > 0 then
                    ColComida := j
                else if StrPos(As, '0209') > 0 then
                    ColDietas := j
                else if StrPos(As, '0211') > 0 then
                    ColPPVaca := j
                else if StrPos(As, '0321') > 0 then
                    ColPLFlex := j
                else if StrPos(As, '0599') > 0 then
                    ColIndemni := j
                else if (StrPos(As, '0795') > 0) or (StrPos(As, 'ANTDIET') > 0) then
                    ColAntDiet := j;
        end;
    end;

    /// <summary>
    /// Contabiliza nóminas directamente desde Excel sin pasar por la tabla de nóminas
    /// </summary>
    procedure ContabilizarNominasDesdeExcel(nImp: Code[20]; rFec: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        NoSeriesMgt: Codeunit "No. Series";
        rBco: Record "Bank Account";
        AcountInfo: Text[250];
        AccNo: Integer;
        TotSum: Integer;
        Ventana: Dialog;
        LINEA: Integer;
        Employee: Record Employee;
        rOr: Record "Source Code";
        GlSetup: Record "General Ledger Setup";
        Doc: Code[20];
        ExcelBuff: Record "Excel Buffer" temporary;
        TempExcelFile: Codeunit "Temp Blob";
        OutStr: OutStream;
        Filename: Text[250];
        Instream: InStream;
        Hoja: Text[50];
        Ok: Boolean;
        EmpresaNombre: Text[30];
        i: Integer;
        Total: Integer;
        CodigoEmpleado: Text[100];
        Devengado: Decimal;
        SSObrero: Decimal;
        IRPF: Decimal;
        SSEmpresa: Decimal;
        EnfermedadAccidente: Decimal;
        Bonificacion: Decimal;
        BonificacionFundae: Decimal;
        Anticipos: Decimal;
        Embargos: Decimal;
        DtoEspecie: Decimal;
        Dieta: Decimal;
        Kms: Decimal;
        Banco: Decimal;
        PPEx: Decimal;
        MejoraV: Decimal;
        Comida: Decimal;
        Dietas: Decimal;
        PPVaca: Decimal;
        PLFlex: Decimal;
        Indemni: Decimal;
        AntDiet: Decimal;
        Nose: Variant;
        As: Text;
        Importe: Decimal;
        rDep: Record "Company Information";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        CIFEmpresaActual: Text[20];
        DepartamentoHoja: Code[20];
        FilaEncabezados: Integer;
        ColDevengado: Integer;
        ColSSObrero: Integer;
        ColIRPF: Integer;
        ColSSEmpresa: Integer;
        ColCosteEmpresa: Integer;
        ColEnfermedadAccidente: Integer;
        ColBonificacion: Integer;
        ColBonificacionFundae: Integer;
        ColBanco: Integer;
        ColKms: Integer;
        ColDieta: Integer;
        ColPPEx: Integer;
        ColMejoraV: Integer;
        ColComida: Integer;
        ColDietas: Integer;
        ColPPVaca: Integer;
        ColPLFlex: Integer;
        ColIndemni: Integer;
        ColAntDiet: Integer;
        ColAnticipos: Integer;
        ColEmbargos: Integer;
        j: Integer;
        CifEncontrado: Boolean;
        ContadorNominas: Integer;
        UltimoEmpleado: Code[20];
        FilaVacia: Integer;
    begin
        GlSetup.Get;

        // Subir archivo Excel
        UploadIntoStream('Elija el fichero Excel de nóminas', '', 'Excel (*.xlsx;*.xls)|*.xlsx;*.xls', Filename, Instream);
        if Filename = '' then
            Error('No se seleccionó ningún archivo');

        // Copiar stream para poder reabrir cada hoja desde el inicio
        TempExcelFile.CreateOutStream(OutStr);
        CopyStream(OutStr, Instream);
        TempExcelFile.CreateInStream(Instream);

        // Obtener empresa actual
        EmpresaNombre := CompanyName;

        // Obtener CIF de la empresa actual
        rDep.Get();
        CIFEmpresaActual := rDep."VAT Registration No.";
        if CIFEmpresaActual = '' then
            Error('La empresa actual no tiene CIF configurado. Configure el CIF en Información de Empresa.');

        // Seleccionar una sola hoja del Excel
        Hoja := ExcelBuff.SelectSheetsNameStream(Instream);
        if Hoja = '' then
            Error('No se seleccionó ninguna hoja del archivo Excel.');

        TempExcelFile.CreateInStream(Instream);

        // Configurar diario
        NoSeries.SetRange(Code, 'NOMINAS');
        if not NoSeries.FindFirst() then
            Error('No existe la serie de documentos "NOMINAS"');

        GenJnlLine.SetRange("Journal Template Name", 'GENERAL');
        GenJnlLine.SetRange("Journal Batch Name", 'NOMINAS');
        if GenJnlLine.FindLast() then
            LINEA := GenJnlLine."Line No." + 10000
        else
            LINEA := 10000;

        if not rOr.Get('NOMINAS') then begin
            rOr.Code := 'NOMINAS';
            rOr.Description := 'Nóminas';
            rOr.Insert();
        end;

        // Contador total de nóminas procesadas
        ContadorNominas := 0;

        // Abrir y procesar la hoja seleccionada
        ExcelBuff.Reset();
        ExcelBuff.DeleteAll();
        ExcelBuff.OpenBookStream(Instream, Hoja);
        ExcelBuff.ReadSheet();

        // Validar CIF/NIF empresa (plantilla AF: fila 5 "Empresa: ... NIF: ...")
        CifEncontrado := false;
        for j := 4 to 6 do
            if ExcelBuff.Get(j, 1) then begin
                As := ExcelBuff."Cell Value as Text";
                if (CIFEmpresaActual <> '') and (StrPos(As, CIFEmpresaActual) > 0) then
                    CifEncontrado := true;
            end;
        if not CifEncontrado then
            Error('El CIF de la empresa no coincide con el del Excel en la hoja %1.', Hoja);

        // Centro/departamento (plantilla AF: fila 6 "Centro: ... - GENERAL")
        DepartamentoHoja := '';
        if ExcelBuff.Get(6, 1) then begin
            As := ExcelBuff."Cell Value as Text";
            DepartamentoHoja := ExtraerDepartamentoDesdeCentro(As);
        end;
        if DepartamentoHoja = '' then
            if ExcelBuff.Get(2, 4) then begin
                As := ExcelBuff."Cell Value as Text";
                DepartamentoHoja := ExtraerUltimaPalabra(As);
            end;
        if DepartamentoHoja = '' then
            Error('No se pudo determinar el departamento en la hoja %1.', Hoja);

        // Crear departamento si no existe
        CrearDepartamentoSiNoExiste(DepartamentoHoja);

        // Fila encabezados: buscar "TRABAJADOR" (plantilla AF fila 8)
        FilaEncabezados := 0;
        for j := 7 to 11 do
            if ExcelBuff.Get(j, 3) then
                if StrPos(NormalizarEncabezadoNomina(ExcelBuff."Cell Value as Text"), 'TRABAJADOR') > 0 then begin
                    FilaEncabezados := j;
                    break;
                end;
        if FilaEncabezados = 0 then
            FilaEncabezados := 8;

        IdentificarColumnasPlantillaNomina(
            ExcelBuff, FilaEncabezados,
            ColDevengado, ColSSObrero, ColIRPF, ColSSEmpresa, ColCosteEmpresa,
            ColEnfermedadAccidente, ColBonificacion, ColBonificacionFundae, ColBanco,
            ColKms, ColDieta, ColPPEx, ColMejoraV, ColComida, ColDietas, ColPPVaca,
            ColPLFlex, ColIndemni, ColAntDiet, ColAnticipos, ColEmbargos);

        if ColDevengado = 0 then
            Error('No se encontró la columna T. BRUTO en la fila %1 del Excel.', FilaEncabezados);

        // Procesar filas del Excel
        AcountInfo := 'Procesando hoja: #1####################\Progreso: @2@@@@@@@@@@@@@@@@';
        Ventana.Open(AcountInfo);
        Ventana.Update(1, Hoja);
        i := BuscarFilaInicioDatosNomina(
            ExcelBuff, FilaEncabezados, ColDevengado, ColBanco, ColSSObrero, ColIRPF, ColSSEmpresa);
        Total := 1000;
        UltimoEmpleado := '';
        FilaVacia := 0;

        while (i <= Total) do begin
            Ventana.Update(2, Round(i * 100 / Total, 1));

            CodigoEmpleado := ObtenerCodigoEmpleadoFila(ExcelBuff, i);
            if EsFilaEmpleadoNomina(ExcelBuff, i) then begin
                FilaVacia := 0;
                UltimoEmpleado := CodigoEmpleado;

                DtoEspecie := 0;
                LeerImportesFilaNomina(
                    ExcelBuff, i,
                    ColDevengado, ColSSObrero, ColIRPF, ColSSEmpresa, ColEnfermedadAccidente,
                    ColBonificacion, ColBonificacionFundae, ColBanco, ColKms, ColDieta,
                    ColPPEx, ColMejoraV, ColComida, ColDietas, ColPPVaca, ColPLFlex, ColIndemni,
                    ColAntDiet, ColAnticipos, ColEmbargos,
                    Devengado, SSObrero, IRPF, SSEmpresa, EnfermedadAccidente,
                    Bonificacion, BonificacionFundae, Anticipos, Embargos,
                    Dieta, Kms, Banco, PPEx, MejoraV, Comida, Dietas, PPVaca, PLFlex, Indemni, AntDiet);

                if FilaTieneImportesNomina(Devengado, Banco, SSObrero, IRPF, SSEmpresa) then begin
                    if not Employee.Get(CodigoEmpleado) then
                        CrearEmpleadoSiNoExiste(Employee, CodigoEmpleado, EmpresaNombre, ExcelBuff, i);

                    if Employee.Get(CodigoEmpleado) then begin
                        if Doc = '' then begin
                            if NoSeries.Code <> '' then begin
                                Clear(NoSeriesMgt);
                                Doc := NoSeriesMgt.GetNextNo(NoSeries.Code, rFec, false);
                            end else
                                Doc := Format(rFec, 0, '<Year4><Month,2><Day,2>');
                        end;

                        GuardarNominaDetalle(
                            Employee, rFec, DepartamentoHoja,
                            Devengado, SSObrero, IRPF, SSEmpresa, EnfermedadAccidente,
                            Bonificacion, BonificacionFundae, Anticipos, Embargos,
                            DtoEspecie, Dieta, Kms, Banco,
                            PPEx, MejoraV, Comida, Dietas, PPVaca, PLFlex, Indemni, AntDiet);
                        ContadorNominas += 1;
                    end;
                end;
            end else begin
                FilaVacia += 1;
                if FilaVacia >= 5 then
                    break;
            end;
            i += 1;
        end;

        ExcelBuff.CloseBook();
        Ventana.Update(2, 100);
        ActualizarCabecerasDepartamento(DepartamentoHoja, rFec);

        Ventana.Close();

        Message('Nóminas importadas correctamente.\Hoja: %1\Fecha: %2\Nóminas procesadas: %3\Puede revisarlas y contabilizarlas desde la página de Nóminas.', Hoja, rFec, ContadorNominas);
    end;

    /// <summary>
    /// Crea un empleado si no existe, usando información del Excel si está disponible
    /// </summary>
    local procedure CrearEmpleadoSiNoExiste(var
                                                Employee: Record Employee;
                                                CodigoEmpleado: Code[20];
                                                EmpresaNombre: Text[30];

var
ExcelBuff: Record "Excel Buffer" temporary;
Fila: Integer)
    var
        NombreEmpleado: Text[100];
        CIFEmpleado: Text[20];
    begin
        // Cambiar a la empresa correcta
        Employee.ChangeCompany(EmpresaNombre);

        // Verificar que no exista (por si acaso)
        if Employee.Get(CodigoEmpleado) then
            exit;

        // Plantilla AF: nombre col. C (3), NIF col. D (4)
        NombreEmpleado := CopyStr(LeerTextoCeldaExcel(ExcelBuff, Fila, 3), 1, MaxStrLen(Employee."First Name"));
        CIFEmpleado := CopyStr(LeerTextoCeldaExcel(ExcelBuff, Fila, 4), 1, 20);

        // Crear nuevo empleado
        Employee.Init();
        Employee."No." := CodigoEmpleado;

        // Asignar nombre si está disponible
        if NombreEmpleado <> '' then begin
            Employee."First Name" := NombreEmpleado;
            Employee."Last Name" := '';
        end else begin
            // Si no hay nombre, usar el código como nombre
            Employee."First Name" := CodigoEmpleado;
        end;

        // Fecha de alta (usar fecha actual)
        Employee."Employment Date" := Today;

        // Insertar el empleado
        if Employee.Insert(true) then
            Commit();
    end;

    /// <summary>
    /// Guarda una nómina en la tabla de detalle
    /// </summary>
    local procedure GuardarNominaDetalle(
        Employee: Record Employee;
        Fecha: Date;
        Departamento: Code[20];
        Devengado: Decimal;
        SSObrero: Decimal;
        IRPF: Decimal;
        SSEmpresa: Decimal;
        EnfermedadAccidente: Decimal;
        Bonificacion: Decimal;
        BonificacionFundae: Decimal;
        Anticipos: Decimal;
        Embargos: Decimal;
        DtoEspecie: Decimal;
        Dieta: Decimal;
        Kms: Decimal;
        Banco: Decimal;
        PPEx: Decimal;
        MejoraV: Decimal;
        Comida: Decimal;
        Dietas: Decimal;
        PPVaca: Decimal;
        PLFlex: Decimal;
        Indemni: Decimal;
        AntDiet: Decimal)
    var
        rNomDet: Record "Nominas Detalle";
    begin
        // El departamento viene del Excel (hoja)

        // Cambiar a la empresa correcta

        // Buscar por fecha + empleado (evita duplicados si el departamento cambió)
        rNomDet.Reset();
        rNomDet.SetRange(Fecha, Fecha);
        rNomDet.SetRange(Empleado, Employee."No.");

        if rNomDet.FindFirst() then begin
            rNomDet.Departamento := Departamento;
            rNomDet.CopiarDimensionesDesdeEmpleado(Employee."No.");
            rNomDet.Devengado := Devengado;
            rNomDet."S.S Obrero" := SSObrero;
            rNomDet.IRPF := IRPF;
            rNomDet."SS empresa" := SSEmpresa;
            rNomDet."Enfermedad Accidente" := EnfermedadAccidente;
            rNomDet."Bonificación" := Bonificacion;
            rNomDet."Bonificación Fundae" := BonificacionFundae;
            rNomDet.Anticipos := Anticipos;
            rNomDet.Embargos := Embargos;
            rNomDet."Dto. Especie" := DtoEspecie;
            rNomDet.Dieta := Dieta;
            rNomDet.Kms := Kms;
            rNomDet.Banco := Banco;
            rNomDet."P.P.Ex" := PPEx;
            rNomDet."MEJORA V" := MejoraV;
            rNomDet.COMIDA := Comida;
            rNomDet.DIETAS := Dietas;
            rNomDet."P.P Vaca" := PPVaca;
            rNomDet."PL. FLEX" := PLFlex;
            rNomDet.Indemni := Indemni;
            rNomDet."Ant.diet" := AntDiet;
            rNomDet.Validate(Devengado);
            rNomDet.Validate("S.S Obrero");
            rNomDet.Validate(IRPF);
            rNomDet.Validate("SS empresa");
            rNomDet.Validate("Enfermedad Accidente");
            rNomDet.Validate("Bonificación");
            rNomDet.Validate("Bonificación Fundae");
            rNomDet.Validate(Anticipos);
            rNomDet.Validate(Embargos);
            rNomDet.Validate(Banco);
            rNomDet.Modify(true);
        end else begin
            // Crear nuevo registro
            rNomDet.Init();
            rNomDet.Fecha := Fecha;
            rNomDet.Empleado := Employee."No.";
            rNomDet.Departamento := Departamento;
            rNomDet.CopiarDimensionesDesdeEmpleado(Employee."No.");
            rNomDet.Devengado := Devengado;
            rNomDet."S.S Obrero" := SSObrero;
            rNomDet.IRPF := IRPF;
            rNomDet."SS empresa" := SSEmpresa;
            rNomDet."Enfermedad Accidente" := EnfermedadAccidente;
            rNomDet."Bonificación" := Bonificacion;
            rNomDet."Bonificación Fundae" := BonificacionFundae;
            rNomDet.Anticipos := Anticipos;
            rNomDet.Embargos := Embargos;
            rNomDet."Dto. Especie" := DtoEspecie;
            rNomDet.Dieta := Dieta;
            rNomDet.Kms := Kms;
            rNomDet.Banco := Banco; // Banco es el líquido a percibir (TOTAL.LIQ del Excel)
            rNomDet."P.P.Ex" := PPEx;
            rNomDet."MEJORA V" := MejoraV;
            rNomDet.COMIDA := Comida;
            rNomDet.DIETAS := Dietas;
            rNomDet."P.P Vaca" := PPVaca;
            rNomDet."PL. FLEX" := PLFlex;
            rNomDet.Indemni := Indemni;
            rNomDet."Ant.diet" := AntDiet;
            // Calcular campos calculados usando Validate para que se ejecuten los triggers
            rNomDet.Validate(Devengado);
            rNomDet.Validate("S.S Obrero");
            rNomDet.Validate(IRPF);
            rNomDet.Validate("SS empresa");
            rNomDet.Validate("Enfermedad Accidente");
            rNomDet.Validate("Bonificación");
            rNomDet.Validate("Bonificación Fundae");
            rNomDet.Validate(Kms);
            rNomDet.Validate(Dieta);
            rNomDet.Validate("Dto. Especie");
            rNomDet.Validate(Anticipos);
            rNomDet.Validate(Embargos);
            rNomDet.Validate(Banco);
            rNomDet.Insert(true);
        end;
    end;

    local procedure CuentaRequiereDimensionesNomina(Cuenta: Code[20]): Boolean
    begin
        exit(CopyStr(Cuenta, 1, 1) in ['6', '7']);
    end;

    local procedure AsignarDimensionesLineaNomina(
        var GenJnlLine: Record "Gen. Journal Line";
        NominaDetalle: Record "Nominas Detalle";
        Employee: Record Employee;
        UsarDimensiones: Boolean)
    begin
        if not UsarDimensiones then begin
            GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            exit;
        end;
        if NominaDetalle."Dimension Set ID" <> 0 then
            GenJnlLine.Validate("Dimension Set ID", NominaDetalle."Dimension Set ID")
        else begin
            if NominaDetalle."Shortcut Dimension 1 Code" <> '' then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", NominaDetalle."Shortcut Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            if NominaDetalle."Shortcut Dimension 2 Code" <> '' then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", NominaDetalle."Shortcut Dimension 2 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
        end;
        // No asignar Job No./Task en el diario: el coste al proyecto se imputa con CrearMovimientoProyectoNominaDetalle
        // para evitar que Job Post-Line (estándar) genere movimientos duplicados al registrar.
    end;

    local procedure AsignarDimensionesMovimientoEmpleadoNomina(
        var EmplLedgEntry: Record "Employee Ledger Entry";
        NominaDetalle: Record "Nominas Detalle";
        Employee: Record Employee)
    begin
        if NominaDetalle."Shortcut Dimension 1 Code" <> '' then
            EmplLedgEntry."Global Dimension 1 Code" := NominaDetalle."Shortcut Dimension 1 Code"
        else
            EmplLedgEntry."Global Dimension 1 Code" := Employee."Global Dimension 1 Code";
        if NominaDetalle."Shortcut Dimension 2 Code" <> '' then
            EmplLedgEntry."Global Dimension 2 Code" := NominaDetalle."Shortcut Dimension 2 Code"
        else
            EmplLedgEntry."Global Dimension 2 Code" := GetProgramaNominas(Employee."No.");
    end;

    procedure CalculaImporteDebe(Importe: Decimal; var ImporteSS: Decimal; var ImporteDevengado: Decimal; Cuenta: Code[20]): Decimal
    begin
        if CopyStr(Cuenta, 1, 3) = '642' then
            ImporteSS += Importe;
        if CopyStr(Cuenta, 1, 3) = '640' then
            ImporteDevengado += Importe;
        exit(Importe);
    end;

    procedure CalculaImporteHaber(Importe: Decimal; var ImporteSS: Decimal; var ImporteDevengado: Decimal; Cuenta: Code[20]): Decimal
    begin
        if CopyStr(Cuenta, 1, 3) = '642' then
            ImporteSS -= Importe;
        if CopyStr(Cuenta, 1, 3) = '640' then
            ImporteDevengado -= Importe;
        exit(Importe);
    end;
    /// <summary>
    /// Crea las líneas de diario para una nómina
    /// </summary>
    procedure CrearLineasDiarioNominas(
        var GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        NominaDetalle: Record "Nominas Detalle";
        EmpresaNombre: Text[30];
        Fecha: Date;
        DocNo: Code[20];
        var LINEA: Integer;
        rOr: Record "Source Code"; var SSProyecto: Decimal; var DevengadoProyecto: Decimal)
    var
        Cuenta: Code[20];
        Devengado: Decimal;
        SSObrero: Decimal;
        IRPF: Decimal;
        SSEmpresa: Decimal;
        EnfermedadAccidente: Decimal;
        Bonificacion: Decimal;
        BonificacionFundae: Decimal;
        Anticipos: Decimal;
        Embargos: Decimal;
        DtoEspecie: Decimal;
        Dieta: Decimal;
        Kms: Decimal;
        Personal: Decimal;
        AntDiet: Decimal;
        ImportePersonalLinea: Decimal;
        AntDietContrapartida: Enum "Ant.diet Contrapartida Nóminas";
    begin
        Devengado := NominaDetalle.Devengado;
        SSObrero := NominaDetalle."S.S Obrero";
        IRPF := NominaDetalle.IRPF;
        SSEmpresa := NominaDetalle."SS empresa";
        EnfermedadAccidente := NominaDetalle."Enfermedad Accidente";
        Bonificacion := NominaDetalle."Bonificación";
        BonificacionFundae := NominaDetalle."Bonificación Fundae";
        Anticipos := NominaDetalle.Anticipos;
        Embargos := NominaDetalle.Embargos;
        DtoEspecie := NominaDetalle."Dto. Especie";
        Dieta := NominaDetalle.Dieta;
        Kms := NominaDetalle.Kms;
        Personal := NominaDetalle.Personal;
        AntDiet := NominaDetalle."Ant.diet";
        AntDietContrapartida := GetAntDietContrapartidaNominas(EmpresaNombre, Employee."No.");
        ImportePersonalLinea := Personal;
        if AntDietContrapartida = AntDietContrapartida::Personal then
            ImportePersonalLinea += AntDiet;
        // Devengado
        if Devengado - Kms - DtoEspecie - Dieta <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Devengado');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(Devengado - Kms - DtoEspecie - Dieta, SSProyecto, DevengadoProyecto, Cuenta));

            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Kms
        if Kms <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Kms');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(Kms, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Especie Debe
        if DtoEspecie <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Especie Debe');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(DtoEspecie, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Especie Haber
        if DtoEspecie <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Especie Haber');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(DtoEspecie, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Dietas
        if Dieta <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Dieta');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(Dieta, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Anticipos
        if Anticipos <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            GenJnlLine."Account No." := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Anticipos');
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(Anticipos, SSProyecto, DevengadoProyecto, GenJnlLine."Account No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Embargos
        if Embargos <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            GenJnlLine."Account No." := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Embargos');
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(Embargos, SSProyecto, DevengadoProyecto, GenJnlLine."Account No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Bonificación
        if Bonificacion <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Bonificación');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("debit Amount", CalculaImporteDebe(Bonificacion, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Bonificación Fundae
        if BonificacionFundae <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Bonificación Fundae');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(BonificacionFundae, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // SS Empresa
        if SSEmpresa <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'SS Empresa');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(SSEmpresa, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, true);
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Enfermedad Accidente
        if EnfermedadAccidente <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Enfermedad Accidente');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(EnfermedadAccidente, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;

            // Enfermedad Accidente 2 (Debe)
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Enfermedad Accidente 2');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(EnfermedadAccidente, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // 476 Organismos SS Acreedores (SS Obrero + SS Empresa)
        // Según PGC, la cuenta 476 debe incluir tanto SS Obrero como SS Empresa
        if (SSObrero <> 0) or (SSEmpresa <> 0) then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := AcountType(EmpresaNombre, Employee."No.", 'S.S Obrero');
            GenJnlLine."Tipo Mov. Empleado" := GenJnlLine."Tipo Mov. Empleado"::"Seg. Social";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'S.S Obrero'); // 476
            if Cuenta <> Employee."No." then GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            // La cuenta 476 debe incluir SS Obrero + SS Empresa
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(SSObrero + SSEmpresa + Bonificacion, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;


        // IRPF
        if IRPF <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := AcountType(EmpresaNombre, Employee."No.", 'IRPF');
            GenJnlLine."Tipo Mov. Empleado" := GenJnlLine."Tipo Mov. Empleado"::IRPF;
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'IRPF');
            if Cuenta <> Employee."No." then GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(IRPF, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // 465 Remuneraciones pendientes de pago (Personal - líquido a percibir)
        // Si Ant.diet va contra Personal, su importe se suma a esta línea.
        if ImportePersonalLinea <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := AcountType(EmpresaNombre, Employee."No.", 'Personal');
            GenJnlLine."Tipo Mov. Empleado" := GenJnlLine."Tipo Mov. Empleado"::Nomina;
            //Tiene que ser empleado, si o si
            if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::Employee then
                error('El tipo de cuenta debe ser Employee para el personal %1', Employee."No.");
            GenJnlLine.Validate("Account Type");
            // Usar cuenta 465 (Personal/Cobro Nómina)
            Cuenta := Employee."No.";
            GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Personal');
            if Cuenta = '' then
                Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Cobro Nómina');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(ImportePersonalLinea, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Ant.diet (0795-Ant.diet): no se contabiliza si la configuración es Sin contrapartida.
        //if AntDietContrapartida <> AntDietContrapartida::"Sin contrapartida" then begin
        Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Ant.diet');
        if (Cuenta <> '') and (AntDiet <> 0) then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Ant.diet');
            If Cuenta = '' Then Error('No se encontró la cuenta de Ant.diet en la configuración');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", CalculaImporteHaber(AntDiet, SSProyecto, DevengadoProyecto, Cuenta));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
            if AntDietContrapartida = AntDietContrapartida::Anticipos then begin
                // Contrapartida Anticipo Dieta
                GenJnlLine.Init;
                GenJnlLine."Journal Template Name" := 'GENERAL';
                GenJnlLine."Journal Batch Name" := 'NOMINAS';
                GenJnlLine."Line No." := LINEA;
                GenJnlLine."Posting Date" := Fecha;
                GenJnlLine."Document No." := DocNo;
                GenJnlLine."Source Code" := rOr.Code;
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine.Validate("Account Type");
                Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Anticipos');
                if Cuenta = '' then
                    Error('No se encontró la cuenta de Anticipos en la configuración para la contrapartida de Ant.diet.');
                GenJnlLine."Account No." := Cuenta;
                GenJnlLine.Validate("Account No.");
                GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
                GenJnlLine.Validate("Debit Amount", CalculaImporteDebe(AntDiet, SSProyecto, DevengadoProyecto, Cuenta));
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
                GenJnlLine."Gen. Bus. Posting Group" := '';
                GenJnlLine."Gen. Prod. Posting Group" := '';
                GenJnlLine."VAT Bus. Posting Group" := '';
                GenJnlLine."VAT Prod. Posting Group" := '';
                AsignarDimensionesLineaNomina(GenJnlLine, NominaDetalle, Employee, CuentaRequiereDimensionesNomina(Cuenta));
                GenJnlLine.Insert;
                LINEA := LINEA + 10000;
            end;
        end;
        //end;
    end;

    /// <summary>
    /// Crea movimientos de proyecto por empleado: coste principal (sin SS empresa) en Nº Tarea,
    /// y SS empresa (642) en Nº Tarea SS, cada uno vinculado a su mov. de empleado por Employee Entry No.
    /// </summary>
    procedure CrearMovimientosProyectoDesdeNomina(DocNo: Code[20]; Fecha: Date)
    var
        NominaDetalle: Record "Nominas Detalle";
        NominaCab: Record "Cabecera Nominas";
    begin
        NominaCab.SetRange(Fecha, Fecha);
        NominaCab.SetRange("Nº Documento", DocNo);
        if not NominaCab.FindFirst() then
            Error('No se encontró la nómina para el documento %1 y fecha %2', DocNo, Fecha);

        NominaDetalle.SetRange(Fecha, Fecha);
        NominaDetalle.SetRange(Departamento, NominaCab.Departamento);
        if NominaDetalle.FindSet(true) then
            repeat
                CrearMovimientoProyectoNominaDetalle(NominaDetalle, DocNo, Fecha, CompanyName);
            until NominaDetalle.Next() = 0;
    end;

    local procedure CrearMovimientoProyectoNominaDetalle(var NominaDetalle: Record "Nominas Detalle"; DocNo: Code[20]; Fecha: Date; EmpresaNombre: Text[30])
    var
        Employee: Record Employee;
        JobTask: Record "Job Task";
        ImporteNomina: Decimal;
        ImporteSSEmpresa: Decimal;
        JobLedgerEntryNo: Integer;
    begin
        if (NominaDetalle."Job Ledger Entry No." <> 0) and
           ((NominaDetalle."SS empresa" = 0) or (NominaDetalle."Job Ledger Entry No. SS" <> 0))
        then
            exit;

        ImporteSSEmpresa := NominaDetalle."SS Proyecto";
        ImporteNomina := NominaDetalle."Devengado Proyecto";

        if (ImporteNomina = 0) and (ImporteSSEmpresa = 0) then
            exit;

        if NominaDetalle."Job No." = '' then
            Error('El empleado %1 tiene coste proyecto pero no tiene Nº Proyecto.', NominaDetalle.Empleado);

        if not Employee.Get(NominaDetalle.Empleado) then
            Error('No existe el empleado %1.', NominaDetalle.Empleado);

        if (ImporteNomina <> 0) and (NominaDetalle."Job Ledger Entry No." = 0) then begin
            if NominaDetalle."Job Task No." = '' then
                Error('El empleado %1 tiene coste proyecto %2 pero no tiene Nº Tarea.', NominaDetalle.Empleado, ImporteNomina);
            JobTask.Get(NominaDetalle."Job No.", NominaDetalle."Job Task No.");
            JobLedgerEntryNo := InsertarMovimientoProyectoNomina(
                NominaDetalle, Employee, DocNo, Fecha, EmpresaNombre,
                NominaDetalle."Job Task No.", ImporteNomina, 'Devengado', '',
                ObtenerEmployeeEntryNoNomina(NominaDetalle, Employee."No.", DocNo, Fecha, NominaDetalle."Employee Entry No.", Enum::"Tipo Mov. Empleado"::Nomina));
            NominaDetalle."Job Ledger Entry No." := JobLedgerEntryNo;
        end;

        if (ImporteSSEmpresa <> 0) and (NominaDetalle."Job Ledger Entry No. SS" = 0) then begin
            if NominaDetalle."Job Task No. SS" = '' then
                Error('El empleado %1 tiene SS empresa %2 pero no tiene Nº Tarea SS.', NominaDetalle.Empleado, ImporteSSEmpresa);
            JobTask.Get(NominaDetalle."Job No.", NominaDetalle."Job Task No. SS");
            JobLedgerEntryNo := InsertarMovimientoProyectoNomina(
                NominaDetalle, Employee, DocNo, Fecha, EmpresaNombre,
                NominaDetalle."Job Task No. SS", ImporteSSEmpresa, 'SS Empresa', ' SS',
                ObtenerEmployeeEntryNoNomina(NominaDetalle, Employee."No.", DocNo, Fecha, NominaDetalle."Employee Entry No. SS", Enum::"Tipo Mov. Empleado"::"Seg. Social"));
            NominaDetalle."Job Ledger Entry No. SS" := JobLedgerEntryNo;
        end;

        NominaDetalle.Modify(true);
    end;

    local procedure InsertarMovimientoProyectoNomina(
        NominaDetalle: Record "Nominas Detalle";
        Employee: Record Employee;
        DocNo: Code[20];
        Fecha: Date;
        EmpresaNombre: Text[30];
        JobTaskNo: Code[20];
        Importe: Decimal;
        ConceptoCuenta: Text[30];
        SufijoDescripcion: Text[10];
        EmployeeEntryNo: Integer): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        Cuenta: Code[20];
        EntryNo: Integer;
    begin
        if Importe = 0 then
            exit(0);
        if EmployeeEntryNo = 0 then
            Error('El empleado %1 no tiene movimiento de empleado para imputar %2 al proyecto.', Employee."No.", ConceptoCuenta);

        JobLedgerEntry.Init();
        EntryNo := GetNextJobLedgerEntryNoNomina();
        JobLedgerEntry."Entry No." := EntryNo;
        JobLedgerEntry."Job No." := NominaDetalle."Job No.";
        JobLedgerEntry."Job Task No." := JobTaskNo;
        JobLedgerEntry."Entry Type" := JobLedgerEntry."Entry Type"::Usage;
        JobLedgerEntry."Posting Date" := Fecha;
        JobLedgerEntry."Document No." := CopyStr(DocNo, 1, MaxStrLen(JobLedgerEntry."Document No."));
        JobLedgerEntry."External Document No." := CopyStr(DocNo, 1, MaxStrLen(JobLedgerEntry."External Document No."));
        JobLedgerEntry.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha) + ' ' + Employee.Name + SufijoDescripcion, 1, MaxStrLen(JobLedgerEntry.Description));
        JobLedgerEntry.Quantity := 1;

        if (ConceptoCuenta = 'Devengado') and (Employee."Resource No." <> '') then begin
            JobLedgerEntry.Type := JobLedgerEntry.Type::Resource;
            JobLedgerEntry."No." := Employee."Resource No.";
        end else begin
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", ConceptoCuenta);
            if Cuenta = '' then
                Error('El empleado %1 no tiene cuenta configurada para %2 en nóminas.', Employee."No.", ConceptoCuenta);
            JobLedgerEntry.Type := JobLedgerEntry.Type::"G/L Account";
            JobLedgerEntry."No." := Cuenta;
        end;

        JobLedgerEntry."Unit Cost" := Importe;
        JobLedgerEntry."Total Cost" := Importe;
        JobLedgerEntry."Unit Cost (LCY)" := Importe;
        JobLedgerEntry."Total Cost (LCY)" := Importe;
        JobLedgerEntry."Neto Factura" := Importe;
        JobLedgerEntry."Bruto Factura" := Importe;
        JobLedgerEntry."Base Amount Pending" := Importe;
        JobLedgerEntry."Amount Pending" := Importe;
        JobLedgerEntry."NombreProveedor o Empleado" := CopyStr(Employee.Name, 1, MaxStrLen(JobLedgerEntry."NombreProveedor o Empleado"));
        JobLedgerEntry."Employee Entry No." := EmployeeEntryNo;

        AsignarDimensionesJobLedgerDesdeNomina(JobLedgerEntry, NominaDetalle, Employee);

        repeat
            JobLedgerEntry."Entry No." := EntryNo;
            EntryNo += 1;
        until JobLedgerEntry.Insert();

        exit(JobLedgerEntry."Entry No.");
    end;

    local procedure ObtenerEmployeeEntryNoNomina(
        NominaDetalle: Record "Nominas Detalle";
        EmployeeNo: Code[20];
        DocNo: Code[20];
        Fecha: Date;
        EmployeeEntryNoGuardado: Integer;
        TipoMovEmpleado: Enum "Tipo Mov. Empleado"): Integer
    begin
        if EmployeeEntryNoGuardado <> 0 then
            exit(EmployeeEntryNoGuardado);
        exit(BuscarMovimientoEmpleadoNomina(EmployeeNo, DocNo, Fecha, TipoMovEmpleado));
    end;

    local procedure BuscarMovimientoEmpleadoNomina(EmployeeNo: Code[20]; DocNo: Code[20]; Fecha: Date; TipoMovEmpleado: Enum "Tipo Mov. Empleado"): Integer
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        EmplLedgEntry.SetRange("Employee No.", EmployeeNo);
        EmplLedgEntry.SetRange("Document No.", DocNo);
        EmplLedgEntry.SetRange("Posting Date", Fecha);
        EmplLedgEntry.SetRange("Tipo Mov. Empleado", TipoMovEmpleado);
        if EmplLedgEntry.FindFirst() then
            exit(EmplLedgEntry."Entry No.");
        exit(0);
    end;

    local procedure AsignarDimensionesJobLedgerDesdeNomina(var JobLedgerEntry: Record "Job Ledger Entry"; NominaDetalle: Record "Nominas Detalle"; Employee: Record Employee)
    begin
        if NominaDetalle."Dimension Set ID" <> 0 then
            JobLedgerEntry.Validate("Dimension Set ID", NominaDetalle."Dimension Set ID")
        else begin
            if NominaDetalle."Shortcut Dimension 1 Code" <> '' then
                JobLedgerEntry.Validate("Global Dimension 1 Code", NominaDetalle."Shortcut Dimension 1 Code")
            else
                JobLedgerEntry.Validate("Global Dimension 1 Code", Employee."Global Dimension 1 Code");
            if NominaDetalle."Shortcut Dimension 2 Code" <> '' then
                JobLedgerEntry.Validate("Global Dimension 2 Code", NominaDetalle."Shortcut Dimension 2 Code")
            else
                JobLedgerEntry.Validate("Global Dimension 2 Code", GetProgramaNominas(Employee."No."));
        end;
    end;

    local procedure GetNextJobLedgerEntryNoNomina(): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if JobLedgerEntry.FindLast() then
            exit(JobLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    /// <summary>
    /// Crea movimientos de empleado cuando se registra el diario de nóminas
    /// Se ejecuta mediante EventSubscriber cuando se registra el diario
    /// </summary>
    procedure CrearMovimientosEmpleadosDesdeDiario(DocNo: Code[20]; Fecha: Date)
    var
        Employee: Record Employee;
        rNomDet: Record "Nominas Detalle";
        rNom: Record "Cabecera Nominas";
        EmployeeEntryNo: Integer;
        EmployeeEntryNoSS: Integer;
        Modificado: Boolean;
    begin
        rNom.SetRange(Fecha, Fecha);
        rNom.SetRange("Nº Documento", DocNo);
        if not rNom.FindFirst() then
            Error('No se encontró la nómina para el documento %1 y fecha %2', DocNo, Fecha);

        rNomDet.SetRange(Fecha, Fecha);
        rNomDet.SetRange(Departamento, rNom.Departamento);
        if rNomDet.FindSet(true) then
            repeat
                if Employee.Get(rNomDet.Empleado) then begin
                    Modificado := false;
                    EmployeeEntryNo := BuscarMovimientoEmpleadoNomina(Employee."No.", DocNo, Fecha, Enum::"Tipo Mov. Empleado"::Nomina);
                    if EmployeeEntryNo <> rNomDet."Employee Entry No." then begin
                        rNomDet."Employee Entry No." := EmployeeEntryNo;
                        Modificado := true;
                    end;
                    EmployeeEntryNoSS := BuscarMovimientoEmpleadoNomina(Employee."No.", DocNo, Fecha, Enum::"Tipo Mov. Empleado"::"Seg. Social");
                    if EmployeeEntryNoSS <> rNomDet."Employee Entry No. SS" then begin
                        rNomDet."Employee Entry No. SS" := EmployeeEntryNoSS;
                        Modificado := true;
                    end;
                    if Modificado then
                        rNomDet.Modify();
                end;
            until rNomDet.Next() = 0;
    end;

    /// <summary>
    /// Obtiene el nombre del mes en español
    /// </summary>
    local procedure ObtenerMesEspanol(Fecha: Date): Text[20]
    var
        Mes: Integer;
    begin
        Mes := Date2DMY(Fecha, 2);
        case Mes of
            1:
                exit('enero');
            2:
                exit('febrero');
            3:
                exit('marzo');
            4:
                exit('abril');
            5:
                exit('mayo');
            6:
                exit('junio');
            7:
                exit('julio');
            8:
                exit('agosto');
            9:
                exit('septiembre');
            10:
                exit('octubre');
            11:
                exit('noviembre');
            12:
                exit('diciembre');
        end;
    end;

    /// <summary>
    /// Indica si Ant.diet contrapartida va a Anticipos o se suma a Personal en el diario de nóminas.
    /// </summary>
    local procedure GetAntDietContrapartidaNominas(Empresa: Code[41]; Empleado: Code[20]): Enum "Ant.diet Contrapartida Nóminas"
    var
        rConf: Record "Nominas Configuración";
    begin
        if rConf.Get(Empleado) then
            exit(rConf."Ant.diet Contrapartida");
        if rConf.Get('') then
            exit(rConf."Ant.diet Contrapartida");
        exit(Enum::"Ant.diet Contrapartida Nóminas"::"Sin contrapartida");
    end;

    /// <summary>
    /// Obtiene la cuenta contable de un concepto de nómina
    /// Accede directamente a la tabla "Nominas Configuración" (50215) usando la empresa seleccionada
    /// </summary>
    local procedure GetCuentaConceptoNominas(Empresa: Code[41]; Empleado: Code[20]; Concepto: Text): Code[20]
    var
        rConf: Record "Nominas Configuración";
        Cuenta: Code[20];
    begin
        Cuenta := '';

        // Intentar obtener configuración específica del empleado
        if rConf.Get(Empleado) then begin
            case Concepto of
                'Devengado':
                    Cuenta := rConf.Devengado;
                'IRPF':
                    if rConf."Account Type IRPF" = rConf."Account Type IRPF"::"G/L Account" then
                        Cuenta := rConf.IRPF
                    else
                        Cuenta := Empleado;
                'S.S Obrero':
                    if rConf."Account Type Seg Social" = rConf."Account Type Seg Social"::"G/L Account" then
                        Cuenta := rConf."S.S Obrero"
                    else
                        Cuenta := Empleado;
                'SS Empresa':
                    Cuenta := rConf."SS empresa";

                'SS Empresa 2':
                    if rConf."Account Type Seg Social" = rConf."Account Type Seg Social"::"G/L Account" then
                        Cuenta := rConf."SS empresa 2"
                    else
                        Cuenta := Empleado;
                'Enfermedad Accidente':
                    Cuenta := rConf."Enfermedad Accidente";
                'Enfermedad Accidente 2':
                    Cuenta := rConf."Enfermedad Accidente 2";
                'Bonificación':
                    Cuenta := rConf.Bonificación;
                'Bonificación Fundae':
                    Cuenta := rConf."Bonificación Fundae";
                'Kms':
                    Cuenta := rConf.Kms;
                'Dieta':
                    Cuenta := rConf.Dieta;
                'Especie Debe':
                    Cuenta := rConf."Especie Debe";
                'Especie Haber':
                    Cuenta := rConf."Especie Haber";
                'Anticipos':
                    Cuenta := rConf.Anticipos;
                'Embargos':
                    Cuenta := rConf.Embargos;
                'Banco':
                    Cuenta := rConf.Banco;
                'Personal':
                    begin
                        if rConf."Account Type" = rConf."Account Type"::"G/L Account" then
                            Cuenta := rConf.Personal
                        else
                            Cuenta := Empleado;
                    end;

                'Cobro Nómina':
                    Cuenta := rConf."Cobro Nómina";
                'Ant.diet':
                    Cuenta := rConf."Ant.diet";
                'Coste':
                    Cuenta := rConf.Coste;
            end;
            if Cuenta <> '' then
                exit(Cuenta);
        end;

        // Si no hay configuración específica del empleado, buscar configuración general (empleado vacío)
        if rConf.Get('') then begin
            case Concepto of
                'Devengado':
                    Cuenta := rConf.Devengado;
                'IRPF':
                    If rConf."Account Type IRPF" = rConf."Account Type IRPF"::"G/L Account" then
                        Cuenta := rConf.IRPF
                    else
                        Cuenta := Empleado;
                'S.S Obrero':
                    If rConf."Account Type Seg Social" = rConf."Account Type Seg Social"::"G/L Account" then
                        Cuenta := rConf."S.S Obrero"
                    else
                        Cuenta := Empleado;
                'SS Empresa':
                    Cuenta := rConf."SS empresa";
                'SS Empresa 2':
                    If rConf."Account Type Seg Social" = rConf."Account Type Seg Social"::"G/L Account" then
                        Cuenta := rConf."SS empresa 2"
                    else
                        Cuenta := Empleado;
                'Enfermedad Accidente':
                    Cuenta := rConf."Enfermedad Accidente";
                'Enfermedad Accidente 2':
                    Cuenta := rConf."Enfermedad Accidente 2";
                'Bonificación':
                    Cuenta := rConf.Bonificación;
                'Bonificación Fundae':
                    Cuenta := rConf."Bonificación Fundae";
                'Kms':
                    Cuenta := rConf.Kms;
                'Dieta':
                    Cuenta := rConf.Dieta;
                'Especie Debe':
                    Cuenta := rConf."Especie Debe";
                'Especie Haber':
                    Cuenta := rConf."Especie Haber";
                'Anticipos':
                    Cuenta := rConf.Anticipos;
                'Embargos':
                    Cuenta := rConf.Embargos;
                'Banco':
                    Cuenta := rConf.Banco;
                'Personal':
                    if rConf."Account Type" = rConf."Account Type"::"G/L Account" then
                        Cuenta := rConf.Personal
                    else
                        Cuenta := Empleado;
                'Cobro Nómina':
                    Cuenta := rConf."Cobro Nómina";
                'Ant.diet':
                    Cuenta := rConf."Ant.diet";
                'Coste':
                    Cuenta := rConf.Coste;
            end;
            if Cuenta <> '' then
                exit(Cuenta);
        end;

        // Si no hay configuración por empresa, buscar configuración general (empresa y empleado vacíos)
        rConf.ChangeCompany(Empresa);
        if rConf.Get(Empleado) then begin
            case Concepto of
                'Devengado':
                    Cuenta := rConf.Devengado;
                'IRPF':
                    Cuenta := rConf.IRPF;
                'S.S Obrero':
                    Cuenta := rConf."S.S Obrero";
                'SS Empresa':
                    Cuenta := rConf."SS empresa";
                'SS Empresa 2':
                    Cuenta := rConf."SS empresa 2";
                'Enfermedad Accidente':
                    Cuenta := rConf."Enfermedad Accidente";
                'Enfermedad Accidente 2':
                    Cuenta := rConf."Enfermedad Accidente 2";
                'Bonificación':
                    Cuenta := rConf.Bonificación;
                'Bonificación Fundae':
                    Cuenta := rConf."Bonificación Fundae";
                'Kms':
                    Cuenta := rConf.Kms;
                'Dieta':
                    Cuenta := rConf.Dieta;
                'Especie Debe':
                    Cuenta := rConf."Especie Debe";
                'Especie Haber':
                    Cuenta := rConf."Especie Haber";
                'Anticipos':
                    Cuenta := rConf.Anticipos;
                'Embargos':
                    Cuenta := rConf.Embargos;
                'Banco':
                    Cuenta := rConf.Banco;
                'Personal':
                    begin
                        if rConf."Account Type" = rConf."Account Type"::"G/L Account" then
                            Cuenta := rConf.Personal
                        else
                            Cuenta := Empleado;
                    end;

                'Cobro Nómina':
                    Cuenta := rConf."Cobro Nómina";
                'Ant.diet':
                    Cuenta := rConf."Ant.diet";
                'Coste':
                    Cuenta := rConf.Coste;
            end;
            if Cuenta <> '' then
                exit(Cuenta);
        end;

        // Si no hay configuración específica del empleado, buscar configuración general (empleado vacío)
        if rConf.Get('') then begin
            case Concepto of
                'Devengado':
                    Cuenta := rConf.Devengado;
                'IRPF':
                    Cuenta := rConf.IRPF;
                'S.S Obrero':
                    Cuenta := rConf."S.S Obrero";
                'SS Empresa':
                    Cuenta := rConf."SS empresa";
                'SS Empresa 2':
                    Cuenta := rConf."SS empresa 2";
                'Enfermedad Accidente':
                    Cuenta := rConf."Enfermedad Accidente";
                'Enfermedad Accidente 2':
                    Cuenta := rConf."Enfermedad Accidente 2";
                'Bonificación':
                    Cuenta := rConf.Bonificación;
                'Bonificación Fundae':
                    Cuenta := rConf."Bonificación Fundae";
                'Kms':
                    Cuenta := rConf.Kms;
                'Dieta':
                    Cuenta := rConf.Dieta;
                'Especie Debe':
                    Cuenta := rConf."Especie Debe";
                'Especie Haber':
                    Cuenta := rConf."Especie Haber";
                'Anticipos':
                    Cuenta := rConf.Anticipos;
                'Embargos':
                    Cuenta := rConf.Embargos;
                'Banco':
                    Cuenta := rConf.Banco;
                'Personal':
                    if rConf."Account Type" = rConf."Account Type"::"G/L Account" then
                        Cuenta := rConf.Personal
                    else
                        Cuenta := Empleado;
                'Cobro Nómina':
                    Cuenta := rConf."Cobro Nómina";
                'Ant.diet':
                    Cuenta := rConf."Ant.diet";
                'Coste':
                    Cuenta := rConf.Coste;
            end;
            if Cuenta <> '' then
                exit(Cuenta);
        end;

        exit(Cuenta);
    end;

    /// <summary>
    /// Obtiene el programa de un empleado
    /// </summary>
    internal procedure GetProgramaNominas(Empleado: Code[20]): Code[20]
    var
        Employee: Record Employee;
        rConf: Record "Nominas Configuración";
    begin
        if Employee.Get(Empleado) then
            exit(Employee."Global Dimension 2 Code");

        // Si el empleado no tiene programa, intentar obtenerlo de la configuración
        // Intentar obtener configuración específica del empleado
        if rConf.Get(Empleado) then
            exit(rConf.Programa);

        // Buscar configuración general (empleado vacío)
        if rConf.Get('') then
            exit(rConf.Programa);

        // Si hay programa por defecto, usarlo
        if rConf."Programa por defecto" <> '' then
            exit(rConf."Programa por defecto");

        exit('');
    end;

    /// <summary>
    /// Extrae el nombre del departamento después del número
    /// Formato esperado: "NIVEL 4           07         EL MAL HIJO"
    /// Devuelve: "EL MAL HIJO"
    /// </summary>
    local procedure ExtraerUltimaPalabra(Texto: Text): Code[20]
    var
        i: Integer;
        j: Integer;
        EncontradoNumero: Boolean;
        PosNumero: Integer;
        Resultado: Text;
        Caracter: Text;
    begin
        if Texto = '' then
            exit('');

        // Buscar el último número en el texto (el código del departamento, ej: "07")
        EncontradoNumero := false;
        PosNumero := 0;

        for i := StrLen(Texto) downto 1 do begin
            Caracter := CopyStr(Texto, i, 1);
            if (Caracter >= '0') and (Caracter <= '9') then begin
                if not EncontradoNumero then begin
                    PosNumero := i;
                    EncontradoNumero := true;
                end;
            end else begin
                if EncontradoNumero then begin
                    // Hemos encontrado el final del número, extraer todo lo que viene después
                    Resultado := CopyStr(Texto, i + 1);
                    // Eliminar espacios al inicio y al final
                    Resultado := DelChr(Resultado, '<', ' ');
                    Resultado := DelChr(Resultado, '>', ' ');
                    // Si hay múltiples espacios, reemplazarlos por uno solo
                    while StrPos(Resultado, '  ') > 0 do
                        Resultado := DelStr(Resultado, StrPos(Resultado, '  '), 1);
                    exit(CopyStr(Resultado, 1, MaxStrLen(Resultado)));
                end;
            end;
        end;

        // Si encontramos un número pero no hay texto después, buscar desde el número hacia adelante
        if EncontradoNumero and (PosNumero > 0) then begin
            // Buscar el final del número (puede tener 1 o 2 dígitos)
            j := PosNumero;
            while (j <= StrLen(Texto)) and (CopyStr(Texto, j, 1) >= '0') and (CopyStr(Texto, j, 1) <= '9') do
                j += 1;

            // Extraer todo después del número
            Resultado := CopyStr(Texto, j);
            Resultado := DelChr(Resultado, '<', ' ');
            Resultado := DelChr(Resultado, '>', ' ');
            while StrPos(Resultado, '  ') > 0 do
                Resultado := DelStr(Resultado, StrPos(Resultado, '  '), 1);
            exit(CopyStr(Resultado, 1, MaxStrLen(Resultado)));
        end;

        // Si no se encuentra número, devolver la última palabra como fallback
        Resultado := DelChr(Texto, '>', ' ');
        for i := StrLen(Resultado) downto 1 do begin
            if CopyStr(Resultado, i, 1) = ' ' then begin
                Resultado := CopyStr(Resultado, i + 1);
                exit(CopyStr(Resultado, 1, MaxStrLen(Resultado)));
            end;
        end;

        exit(CopyStr(Resultado, 1, MaxStrLen(Resultado)));
    end;

    /// <summary>
    /// Actualiza las cabeceras de nóminas para un departamento y fecha específicos
    /// </summary>
    local procedure ActualizarCabecerasDepartamento(Departamento: Code[20]; Fecha: Date)
    var
        rNomDet: Record "Nominas Detalle";
        NominaCab: Record "Cabecera Nominas";
    begin
        // Recalcular totales desde el detalle para asegurar que todos los registros se incluyan
        rNomDet.SetRange(Fecha, Fecha);
        rNomDet.SetRange(Departamento, Departamento);

        if not NominaCab.Get(Fecha, Departamento) then
            exit;

        NominaCab.Devengado := 0;
        NominaCab."S.S Obrero" := 0;
        NominaCab.IRPF := 0;
        NominaCab."SS empresa" := 0;
        NominaCab."Enfermedad Accidente" := 0;
        NominaCab.Banco := 0;
        NominaCab.Personal := 0;
        NominaCab."Bonificación" := 0;
        NominaCab."Bonificación Fundae" := 0;
        NominaCab.Kms := 0;
        NominaCab."Dto. Especie" := 0;
        NominaCab.Dieta := 0;
        NominaCab.Anticipos := 0;
        NominaCab.Embargos := 0;

        // Procesar todos los registros
        if rNomDet.Find('-') then begin
            repeat
                NominaCab.Devengado += rNomDet.Devengado;
                NominaCab."S.S Obrero" += rNomDet."S.S Obrero";
                NominaCab.IRPF += rNomDet.IRPF;
                NominaCab."SS empresa" += rNomDet."SS empresa";
                NominaCab."Enfermedad Accidente" += rNomDet."Enfermedad Accidente";
                NominaCab.Banco += rNomDet.Banco;
                NominaCab.Personal += rNomDet.Personal;
                NominaCab."Bonificación" += rNomDet."Bonificación";
                NominaCab."Bonificación Fundae" += rNomDet."Bonificación Fundae";
                NominaCab.Kms += rNomDet.Kms;
                NominaCab."Dto. Especie" += rNomDet."Dto. Especie";
                NominaCab.Dieta += rNomDet.Dieta;
                NominaCab.Anticipos += rNomDet.Anticipos;
                NominaCab.Embargos += rNomDet.Embargos;
            until rNomDet.Next() = 0;
        end;

        NominaCab.Personal := NominaCab.Devengado - NominaCab."S.S Obrero" - NominaCab.IRPF - NominaCab.Anticipos - NominaCab.Embargos;
        NominaCab.Modify(true);
        Commit();
    end;

    /// <summary>
    /// Crea un departamento (Dimension Value) si no existe
    /// </summary>
    local procedure CrearDepartamentoSiNoExiste(Departamento: Code[20])
    var
        DimValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        DimCode: Code[20];
    begin
        if Departamento = '' then
            exit;

        // Obtener código de dimensión global 1
        GLSetup.Get();
        DimCode := GLSetup."Global Dimension 1 Code";
        if DimCode = '' then
            Error('No está configurada la Dimensión Global 1. Configurela en Configuración Contabilidad.');

        // Verificar si ya existe
        if DimValue.Get(DimCode, Departamento) then
            exit;

        // Crear nuevo departamento
        DimValue.Init();
        DimValue."Dimension Code" := DimCode;
        DimValue.Code := Departamento;
        DimValue.Name := Departamento;
        DimValue."Dimension Value Type" := DimValue."Dimension Value Type"::Standard;
        DimValue.Blocked := false;
        DimValue.Insert(true);
    end;

    local procedure AcountType(EmpresaNombre: Text[30]; Empleado: Code[20]; Concepto: Text): Enum Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Account Type"
    var
        rConf: Record "Nominas Configuración";
    begin
        Case Concepto of
            'Personal':
                begin
                    if rConf.Get(Empleado) then
                        exit(rConf."Account Type");
                    if rConf.Get('') then
                        exit(rConf."Account Type");
                    if rConf.ChangeCompany(EmpresaNombre) then begin
                        if rConf.Get(Empleado) then
                            exit(rConf."Account Type");
                        if rConf.Get('') then
                            exit(rConf."Account Type");

                    end;
                    exit(rConf."Account Type");
                end;

            'IRPF':
                begin
                    if rConf.Get(Empleado) then
                        exit(rConf."Account Type Irpf");
                    if rConf.Get('') then
                        exit(rConf."Account Type Irpf");
                    if rConf.ChangeCompany(EmpresaNombre) then begin
                        if rConf.Get(Empleado) then
                            exit(rConf."Account Type Irpf");
                        if rConf.Get('') then
                            exit(rConf."Account Type Irpf");

                    end;
                    exit(rConf."Account Type Irpf");
                end;
            'S.S Obrero':
                begin
                    if rConf.Get(Empleado) then
                        exit(rConf."Account Type Seg Social");
                    if rConf.Get('') then
                        exit(rConf."Account Type Seg Social");
                    if rConf.ChangeCompany(EmpresaNombre) then begin
                        if rConf.Get(Empleado) then
                            exit(rConf."Account Type Seg Social");
                        if rConf.Get('') then
                            exit(rConf."Account Type Seg Social");
                    end;
                    exit(rConf."Account Type Seg Social");
                end;
        end;
        exit(rConf."Account Type");

    end;

    /// <summary>
    /// Importa facturas de venta desde Excel.
    /// Columnas: A=Fecha, B=Importe, C=% IVA, D=Importe IVA, E=Total, F=CIF cliente, G=Nombre, H=Texto registro, I=Cuenta contable, J=Nº factura, K=Proyecto.
    /// </summary>
    procedure ImportarFacturasDesdeExcel()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        //GLAccount: Record "G/L Account";
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesSetup: Record "Sales & Receivables Setup";
        InStream: InStream;
        FileName: Text;
        SheetName: Text;
        RowNo: Integer;
        Fecha: Date;
        Importe: Decimal;
        PctIVA: Decimal;
        ImporteIVA: Decimal;
        Total: Decimal;
        CIFCliente: Text[30];
        NombreCliente: Text[100];
        TextoRegistro: Text[100];
        CuentaContable: Code[20];
        NumeroFactura: Text[50];
        ProyectoNo: Code[20];
        LineNo: Integer;
        Importadas: Integer;
        ErrMsg: Label 'Fila %1: No se encontró cliente con CIF %2.';
        ErrCuenta: Label 'Fila %1: La cuenta contable %2 no existe.';
        ErrProyecto: Label 'Fila %1: El proyecto %2 no existe.';
        ErrTarea: Label 'Fila %1: La tarea %2 no existe.';
        ErrItem: Label 'Fila %1: El item %2 no existe.';
        VatPostingSetup: Record "VAT Posting Setup";
        Dimensiones: array[8] of Code[20];
        CodCliente: Code[20];
        Tarea: Code[20];
        Empresa: Text;
        GenSetupPostingGroup: Record "General Posting Setup";
        FillInvPostingNo: Boolean;
        JobPlanningLine: Record "Job Planning Line";
        CreateInvoice: codeunit "Job Create-Invoice";
        SalesLine: Record "Sales Line";
    begin
        TempExcelBuffer.DeleteAll();
        if not UploadIntoStream('Seleccionar archivo Excel de facturas', '', 'Archivos Excel (*.xlsx)|*.xlsx|Todos (*.*)|*.*', FileName, InStream) then
            exit;
        FillInvPostingNo := Confirm('Rellenar No. de Registro de Factura?', false);
        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStream);
        TempExcelBuffer.OpenBookStream(InStream, SheetName);
        TempExcelBuffer.ReadSheet();

        Importadas := 0;
        if not TempExcelBuffer.FindSet() then
            exit;

        repeat
            RowNo := TempExcelBuffer."Row No.";
            // esta es la fila 1
            //A-FECHA FACTURA	
            //B-BASE IMPONIBLE	
            //C-% IVA	
            //D-IMPORTE IVA	
            //E-TOTAL FACTURA	
            //F-CIF CLIENTE	
            //G-COD CLIENTE	
            //H-NOMBRE  CLIENTE	
            //I-TEXTO	
            //J-CUENTA DE INGRESO
            //K-Nº FACTURA	
            //L-PROYECTO	
            //M-TAREA	
            //N-EMPRESA	DIM1
            //O-PROYECTO	DIM2
            //P-SUBMEDIO	
            //Q-DIM4	
            //R-DIM5	
            //S-DIM6	

            if RowNo > 1 then begin
                Fecha := 0D;
                Importe := 0;
                PctIVA := 0;
                ImporteIVA := 0;
                Total := 0;
                CIFCliente := '';
                CodCliente := '';
                Tarea := '';
                NombreCliente := '';
                TextoRegistro := '';
                CuentaContable := '';
                NumeroFactura := '';
                ProyectoNo := '';
                Empresa := '';
                Dimensiones[1] := '';
                Dimensiones[2] := '';
                Dimensiones[3] := '';
                Dimensiones[4] := '';
                Dimensiones[5] := '';
                Dimensiones[6] := '';
                Dimensiones[7] := '';
                Dimensiones[8] := '';
                TempExcelBuffer.SetRange("Row No.", RowNo);
                if TempExcelBuffer.FindSet() then
                    repeat
                        case TempExcelBuffer."Column No." of
                            1: // A - Fecha
                                if TempExcelBuffer."Cell Value as Text" <> '' then
                                    if not Evaluate(Fecha, TempExcelBuffer."Cell Value as Text") then
                                        Fecha := 0D;
                            2: // B - Importe
                                if not Evaluate(Importe, TempExcelBuffer."Cell Value as Text") then
                                    Importe := 0;
                            3: // C - % IVA
                                if not Evaluate(PctIVA, TempExcelBuffer."Cell Value as Text") then
                                    PctIVA := 0;
                            4: // D - Importe IVA
                                if not Evaluate(ImporteIVA, TempExcelBuffer."Cell Value as Text") then
                                    ImporteIVA := 0;
                            5: // E - Total
                                if not Evaluate(Total, TempExcelBuffer."Cell Value as Text") then
                                    Total := 0;
                            6: // F - CIF cliente
                                CIFCliente := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Customer."VAT Registration No."));

                            7: // G - Cod cliente
                                CodCliente := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(CodCliente));
                            8: // H - Nombre cliente
                                NombreCliente := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(NombreCliente));
                            9: // I - Texto registro
                                TextoRegistro := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(TextoRegistro));
                            10: // J - Cuenta contable
                                CuentaContable := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(CuentaContable));
                            11: // K - Nº factura (No. / Posting No. -> External Document No.)
                                NumeroFactura := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(NumeroFactura));
                            12: // L - Proyecto
                                ProyectoNo := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(ProyectoNo));
                            13: // M - Tarea
                                Tarea := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Tarea));
                            14: // N - Dimension 1
                                Dimensiones[1] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[1]));
                            15: // O - Dimension 2
                                Dimensiones[2] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[2]));
                            16: // P - Dimension 3
                                Dimensiones[3] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[3]));
                            17: // Q - Dimension 4
                                Dimensiones[4] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[4]));
                            18: // R - Dimension 5
                                Dimensiones[5] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[5]));
                            19: // S - Dimension 6
                                Dimensiones[6] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[6]));
                        // 20: // R - Dimension 7
                        //     Dimensiones[7] := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Dimensiones[7]));
                        end;
                    until TempExcelBuffer.Next() = 0;
                TempExcelBuffer.SetRange("Row No.");

                if ((CIFCliente <> '') or (CodCliente <> '')) and (CuentaContable <> '') then begin
                    Customer.Reset();
                    if CodCliente = '' then begin
                        Customer.SetRange("VAT Registration No.", CIFCliente);
                        if not Customer.FindFirst() then begin
                            Error(ErrMsg, RowNo, CIFCliente);
                            exit;
                        end;
                    end else
                        Customer.Get(CodCliente);
                    if not Item.Get(Tarea) then begin
                        Error(ErrItem, RowNo, Tarea);
                        exit;
                    end;
                    if ProyectoNo <> '' then begin
                        if not Job.Get(ProyectoNo) then begin
                            Error(ErrProyecto, RowNo, ProyectoNo);
                            exit;
                        end;
                    end;
                    if Tarea <> '' then begin
                        if not JobTask.Get(ProyectoNo, Tarea) then begin
                            Error(ErrTarea, RowNo, Tarea);
                            exit;
                        end;
                    end;
                    Customer.TestField("Gen. Bus. Posting Group");
                    Customer.TestField("VAT Bus. Posting Group");

                    // Buscar o crear cabecera: mismo cliente + mismo External Document No. + mismo proyecto
                    SalesHeader.Reset();
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
                    SalesHeader.SetRange("External Document No.", NumeroFactura);
                    SalesHeader.SetRange("No.Proyecto", ProyectoNo);
                    if not SalesHeader.FindFirst() then begin
                        SalesHeader.Init();
                        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                        SalesHeader."No." := '';
                        SalesHeader.Insert(true);
                        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
                        SalesHeader.Validate("Posting Date", Fecha);
                        SalesHeader."Importar desde excel" := true;
                        SalesHeader."External Document No." := CopyStr(NumeroFactura, 1, MaxStrLen(SalesHeader."External Document No."));
                        SalesHeader."No.Proyecto" := ProyectoNo;
                        if FillInvPostingNo then
                            SalesHeader."Posting No." := NumeroFactura;
                        SalesHeader.Modify(true);
                        jobplanningline.SetRange("Document No.", SalesHeader."No.");
                        jobplanningline.DeleteAll();

                    end;
                    //Crear Jobline
                    JobPlanningLine.Reset();
                    JobPlanningLine.SetRange("Job No.", ProyectoNo);
                    JobPlanningLine.SetRange("Job Task No.", Tarea);
                    If JobPlanningLine.FindLast() then
                        LineNo := JobPlanningLine."Line No." + 10000
                    else
                        LineNo := 10000;
                    JobPlanningLine.Init();
                    JobPlanningLine."Job No." := ProyectoNo;
                    JobPlanningLine."Job Task No." := Tarea;
                    JobPlanningLine."Document No." := SalesHeader."No.";
                    JobPlanningLine."Planning Date" := SalesHeader."Posting Date";
                    JobPlanningLine."Line No." := LineNo;
                    JobPlanningLine.Description := TextoRegistro;
                    JobPlanningLine.Quantity := 1;
                    JobPlanningLine.Validate("Unit Price", Importe);
                    Item.Get(Tarea);
                    JobPlanningLine."Unit of Measure Code" := item."Base Unit of Measure";
                    JobPlanningLine."Unit Price" := Importe;
                    JobPlanningLine."Total Price" := Importe;
                    JobPlanningLine."Qty. to Transfer to Invoice" := 1;
                    JobPlanningLine."Contract Line" := true;
                    JobPlanningLine.Type := JobPlanningLine.Type::Item;
                    JobPlanningLine."No." := Tarea;
                    JobPlanningLine."Line Type" := JobPlanningLine."Line Type"::Billable;
                    Item.Get(Tarea);
                    Item.TestField("VAT Prod. Posting Group");
                    Item.TestField("Gen. Prod. Posting Group");

                    JobPlanningLine.Insert();
                    // OCrear Job Planning Line
                    CreateInvoice.CreateSalesInvoiceLines(ProyectoNo, JobPlanningLine, SalesHeader."No.", false, SalesHeader."Posting Date", SalesHeader."Posting Date", false);
                    Commit();
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                    SalesLine.SetRange("Document No.", SalesHeader."No.");
                    SalesLine.FindLast();


                    // deberia buscar un grupo registro iva producto que en la configurtacion con el grupo viva negocio del cliente , tenga un PCTIV
                    VatPostingSetup.Reset();
                    VatPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                    VatPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
                    VatPostingSetup.SetRange("VAT %", PctIVA);
                    if not VatPostingSetup.FindFirst() then begin
                        Error(ErrVatPostingSetup, RowNo, Customer."VAT Bus. Posting Group", PctIVA);
                        exit;
                    end;
                    SalesLine."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
                    SalesLine.Validate("VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");

                    Item.Get(Tarea);
                    Item.TestField("Gen. Prod. Posting Group");
                    Item.TestField("VAT Prod. Posting Group");
                    SalesLine.Validate("Unit Price", Importe);

                    // Cargar dimensiones: construir Dimension Set ID desde array Dimensiones (columnas L a R) y asignar a la línea
                    SalesLine."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
                    SalesLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                    SalesLine.Validate("Dimension Set ID", GetDimSetIDFromDimensionesArray(Dimensiones));
                    SalesLine."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
                    SalesLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                    SalesLine."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
                    SalesLine."VAT Prod. Posting Group" := VatPostingSetup."VAT Prod. Posting Group";
                    //testfield en salesline "VAT Bus. Posting Group" y "VAT Prod. Posting Group"
                    SalesLine.TestField("VAT Bus. Posting Group");
                    SalesLine.TestField("VAT Prod. Posting Group");
                    //testfield en salesline "Gen. Bus. Posting Group" y "Gen. Prod. Posting Group"
                    SalesLine.TestField("Gen. Bus. Posting Group");
                    SalesLine.TestField("Gen. Prod. Posting Group");
                    SalesLine.Modify();
                    //Importadas += 1;

                    // deberia buscar un grupo registro iva producto que en la configurtacion con el grupo viva negocio del cliente , tenga un PCTIV
                    // VatPostingSetup.Reset();
                    // VatPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                    // VatPostingSetup.SetRange("VAT %", PctIVA);
                    // if not VatPostingSetup.FindFirst() then begin
                    //     Error(ErrVatPostingSetup, RowNo, Customer."Gen. Bus. Posting Group", PctIVA);
                    //     exit;
                    // end;
                    // SalesLine.Validate("VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");

                    // SalesLine."Job No." := ProyectoNo;
                    // SalesLine."Job Task No." := Tarea;
                    // Item.Get(Tarea);
                    // Item.TestField("Gen. Prod. Posting Group");
                    // SalesLine.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
                    // // Cargar dimensiones: construir Dimension Set ID desde array Dimensiones (columnas L a R) y asignar a la línea
                    // SalesLine."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
                    // SalesLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                    // SalesLine.Validate("Dimension Set ID", GetDimSetIDFromDimensionesArray(Dimensiones));
                    // SalesLine.Insert(true);
                    // SalesLine."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
                    // SalesLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                    // SalesLine.Modify();
                    Importadas += 1;
                    //CrearJobPlaningLineVta(SalesHeader, SalesLine);
                end; // CIFCliente <> ''
            end; // RowNo > 1

        until TempExcelBuffer.Next() = 0;

        Message('Se importaron %1 línea(s) de factura correctamente.', Importadas);
    end;

    /// <summary>
    /// Construye un Dimension Set ID a partir del array de códigos de valor de dimensión (Dimensiones[1]..[8]).
    /// Los códigos de dimensión se toman de General Ledger Setup: [1]=Global Dim 1, [2]=Global Dim 2, [3]=Shortcut Dim 3, [4]=Shortcut Dim 4.
    /// </summary>
    local procedure GetDimSetIDFromDimensionesArray(Dimensiones: array[8] of Code[20]): Integer
    var
        GlSetup: Record "General Ledger Setup";
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        DimCode: Code[20];
        i: Integer;
    begin
        GlSetup.Get();
        for i := 1 to 8 do
            if Dimensiones[i] <> '' then begin
                case i of
                    1:
                        DimCode := GlSetup."Global Dimension 1 Code";
                    2:
                        DimCode := GlSetup."Global Dimension 2 Code";
                    3:
                        DimCode := GlSetup."Shortcut Dimension 3 Code";
                    4:
                        DimCode := GlSetup."Shortcut Dimension 4 Code";
                    else
                        DimCode := '';
                end;
                if (DimCode <> '') and DimValue.Get(DimCode, Dimensiones[i]) then begin
                    TempDimSetEntry."Dimension Code" := DimCode;
                    TempDimSetEntry."Dimension Value Code" := Dimensiones[i];
                    TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                    TempDimSetEntry.Insert(true);
                end;
            end;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;
}

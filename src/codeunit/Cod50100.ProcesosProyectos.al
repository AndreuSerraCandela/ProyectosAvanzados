/// <summary>
/// Codeunit ProcesosProyectos (ID 50100).
/// </summary>
/// 

codeunit 50301 "ProcesosProyectos"
{
    Permissions = TableData "G/L Budget Entry" = rimd, TableData "Job Ledger Entry" = rimd,
    Tabledata "Employee Ledger Entry" = rimd;
    trigger OnRun()
    begin
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
    [EventSubscriber(ObjectType::Codeunit, 1012, 'OnBeforeApplyUsageLink', '', false, false)]
    local procedure OnBeforeApplyUsageLink(var JobLedgerEntry: Record "Job Ledger Entry"; var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnUseOnBeforeModify', '', false, false)]
    local procedure OnUseOnBeforeModify(var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.Validate(Quantity, JobPlanningLine.QB);
        //JobPlanningLine.Modify();
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
        PurchaseLine.Validate("Gen. Prod. Posting Group", JobPlanningLine2."Gen. Prod. Posting Group");
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
            DimSetIDArr[1] := PurchaseLine."Dimension Set ID";
            DimSetIDArr[2] :=
              DimMgt.CreateDimSetFromJobTaskDim(
                PurchaseLine."Job No.", PurchaseLine."Job Task No.", PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");
            DimSetIDArr[3] := GetLedgEntryDimSetID(JobPlanningLine2);
            DimSetIDArr[4] := GetJobLedgEntryDimSetID(JobPlanningLine2);

            DimMgt.CreateDimForPurchLineWithHigherPriorities(
              PurchaseLine,
              0,
              DimSetIDArr[5],
              PurchaseLine."Shortcut Dimension 1 Code",
              PurchaseLine."Shortcut Dimension 2 Code",
             // SourceCodeSetup.Purchases,
             SourceCodeSetup."Primary Key",
              DATABASE::Job);
            //DATABASE::JOB);
            PurchaseLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(
                DimSetIDArr, PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");

        end;
        PurchaseLine.Description := JobPlanningLine2.Description;
        PurchaseLine."Description 2" := JobPlanningLine2."Description 2";
        PurchaseLine."Line No." := GetNextLineNo(PurchaseLine);
        //NoLinea := GetNextLineNo(PurchaseLine);
        // PurchaseLine."Line No." := NoLinea;
        OnBeforeInsertPurchaseLine(PurchaseLine, PurchaseHeader, Job, JobPlanningLine2);

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
    begin
        if JobPlanningLine."Job Ledger Entry No." = 0 then
            exit(0);

        if JobLedgerEntry.Get(JobPlanningLine."Job Ledger Entry No.") then
            exit(JobLedgerEntry."Dimension Set ID");

        exit(0);
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
        CtaCble: Text[30];
        GenNegPostingGrup: Record "Gen. Business Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        ClasificacionGasto: Text[100];
        Categorias: Record Categorias;
        IcParter: Record "Ic Partner";
        Customer: Record Customer;
    begin
        rInf.Get();
        rInf.TestField("Cta Contable Mov");
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
                            end;
                            If TempExcelBuffer.xlColID = '' Then TempExcelBuffer.Validate("Column No.");
                            if TempExcelBuffer.xlColID = rInf."Cta Contable Mov" Then CtaCble := TempExcelBuffer."Cell Value as Text";
                        until TempExcelBuffer.Next() = 0;
                    If FacturadoContra <> '' Then begin
                        IcParter.SetRange("Inbox Details", FacturadoContra);
                        if Not IcParter.FindFirst() then Error('No existe el socio %1', FacturadoContra);
                    end;
                    // Si hay Job Task No., crear o verificar Job Task
                    if (JobTaskNo <> '') and (Descripcion <> '') then begin
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
                                end;
                            end;
                        end;

                        // Si no se encontró cuenta, usar Budget Code como cuenta contable
                        if NoCuenta = '' then begin
                            if Tipo = 'CUENTA' then begin
                                NoCuenta := CopyStr(BudgetCode, 1, MaxStrLen(NoCuenta));
                                // Verificar si es una cuenta contable válida
                                if not GLAccount.Get(NoCuenta) then begin
                                    // Crear cuenta contable si no existe
                                    GLAccount.Init();
                                    GLAccount."No." := NoCuenta;
                                    GLAccount.Name := CopyStr(Descripcion, 1, MaxStrLen(GLAccount.Name));
                                    GLAccount."Account Type" := GLAccount."Account Type"::Posting;
                                    GLAccount."Direct Posting" := true;
                                    GLAccount.Insert(true);
                                end;
                                Tipo := 'CUENTA';
                            end;
                        end;

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
                                            Item."Gen. Prod. Posting Group" := BudgetCode; //Item."No.";
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
                                        If Not GenProdPostingGroup.Get(BudgetCode) Then begin//Item."Gen. Prod. Posting Group") then begin
                                            GenProdPostingGroup.Init();
                                            GenProdPostingGroup."Code" := BudgetCode; //Item."Gen. Prod. Posting Group";
                                            GenProdPostingGroup.Description := Descripcion; // Item."Gen. Prod. Posting Group";
                                            GenProdPostingGroup.Insert(true);
                                        end;
                                        If GenNegPostingGrup.FindFirst Then
                                            repeat
                                                if Not GenPostingSetup.Get(GenNegPostingGrup.Code, GenProdPostingGroup.Code) Then begin
                                                    GenPostingSetup.Init;
                                                    GenPostingSetup."Gen. Bus. Posting Group" := GenNegPostingGrup.Code;
                                                    GenPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup.Code;

                                                    GenPostingSetup.Insert();
                                                end;
                                                GenPostingSetup."Purch. Account" := CtaCble;
                                                GenPostingSetup.Modify();
                                            until GenNegPostingGrup.next = 0;

                                    end;
                                'RECURSO', 'RESOURCE':
                                    begin
                                        JobPlanningLine."Type" := JobPlanningLine."Type"::Resource;
                                        JobPlanningLine."No." := NoCuenta;
                                    end;
                            end;

                            JobPlanningLine.Description := Descripcion;
                            JobPlanningLine.Quantity := 1;
                            if BrutoFactura <> 0 then begin
                                // JobPlanningLine."Unit Cost (LCY)" := BrutoFactura; // DFS DESCOMENTÉ POR LO DE LOS TOTALES
                                // JobPlanningLine."Total Cost (LCY)" := BrutoFactura; // DFS DESCOMENTÉ POR LO DE LOS TOTALES

                            end;
                            if Budget <> 0 then begin
                                JobPlanningLine."Total Cost (LCY)" := Budget;
                                JobPlanningLine."Unit Cost (LCY)" := Budget;
                                JobPlanningLine."Total Cost" := Budget;
                                JobPlanningLine."Unit Cost" := Budget;
                                JobPlanningLine."Schedule Line" := true;

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
                            repeat
                                JobPlanningLine."Line No." := LineNo;
                                LineNo += 10000;
                            until JobPlanningLine.Insert(true);

                            //end;
                            if ImportedEntriesPagado <> 0 then begin
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
                                ProyectoMovimientoPago."Line No." := 0;
                                if LineNo = 10000 Then ProyectoMovimientoPago.Validate(Amount, BrutoFactura);
                                ProyectoMovimientoPago."Job No." := JobNo;
                                ProyectoMovimientoPago."Job Task No." := JobTaskNo;
                                ProyectoMovimientoPago.Validate("Amount Paid", ImportedEntriesPagado);
                                ProyectoMovimientoPago."Job Planning Line No." := JobPlanningLine."Line No.";
                                repeat
                                    ProyectoMovimientoPago."Line No." := LineNo;
                                    LineNo += 10000;
                                until ProyectoMovimientoPago.Insert();
                            end;

                            // Verificar si ya existe un Job Ledger Entry con los mismos datos para evitar duplicados
                            JobLedgerEntry.Reset();
                            if JobLedgerEntry.FindLast() then
                                LineNo := JobLedgerEntry."Entry No." + 1
                            else
                                LineNo := 1;
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
                            if BrutoFactura <> 0 then begin
                                //   JobLedgerEntry."Unit Cost" := BrutoFactura;   DFS
                                JobLedgerEntry."Unit Cost (LCY)" := BrutoFactura;   //DFS    

                                // JobLedgerEntry."Total Cost" := BrutoFactura;  //DFS
                                JobLedgerEntry."Total Cost (LCY)" := BrutoFactura;
                                JobLedgerEntry."Total Cost" := BrutoFactura;
                                JobLedgerEntry."Unit Cost" := BrutoFactura;
                            end;

                            // Campos personalizados
                            JobLedgerEntry."Budget Code" := BudgetCode;
                            JobLedgerEntry."Neto Factura" := NetoFactura;
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
                            repeat
                                JobLedgerEntry."Entry No." := LineNo;
                                LineNo += 1;
                            until JobLedgerEntry.Insert();
                            ImportedEntries += 1;

                        end; // Cerrar if NoCuenta <> ''
                    end; // Cerrar if (JobTaskNo <> '') and (Descripcion <> '')

                    // Restaurar filtro para siguiente iteración
                    TempExcelBuffer.SetRange("Row No.");
                end;
            until TempExcelBuffer.Next() = 0;

        Message('Se importaron %1 movimientos correctamente.', ImportedEntries);
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
        Filename: Text[250];
        Instream: InStream;
        Hoja: Text[50];
        NameValue: Record "Name/Value Buffer" temporary;
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
        j: Integer;
        ContadorNominas: Integer;
        TotalHojas: Integer;
        HojasProcesadas: Integer;
        ContadorNominasHoja: Integer;
        UltimoEmpleado: Code[20];
        FilaVacia: Integer;
    begin
        GlSetup.Get;

        // Subir archivo Excel
        UploadIntoStream('Elija el fichero Excel de nóminas', '\\documentos\prueba.xlsx', 'Documentos excel (*.xlsx)|*.xlsx', Filename, Instream);
        if Filename = '' then
            Error('No se seleccionó ningún archivo');

        // Obtener empresa actual
        EmpresaNombre := CompanyName;

        // Obtener CIF de la empresa actual
        rDep.Get();
        CIFEmpresaActual := rDep."VAT Registration No.";
        if CIFEmpresaActual = '' then
            Error('La empresa actual no tiene CIF configurado. Configure el CIF en Información de Empresa.');

        // Obtener lista de hojas
        ExcelBuff.GetSheetsNameListFromStream(Instream, NameValue);

        // Procesar todas las hojas automáticamente
        if not NameValue.FindSet() then
            Error('No se encontraron hojas en el archivo Excel.');

        // Configurar diario (una sola vez para todas las hojas)
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
        TotalHojas := 0;
        HojasProcesadas := 0;

        // Contar total de hojas para el progreso
        NameValue.Reset();
        if NameValue.FindSet() then
            repeat
                TotalHojas += 1;
            until NameValue.Next() = 0;

        // Procesar cada hoja
        NameValue.Reset();
        if NameValue.FindSet() then
            repeat
                Hoja := NameValue.Value;
                if Hoja <> '' then begin
                    HojasProcesadas += 1;

                    // Abrir hoja Excel
                    ExcelBuff.OpenBookStream(Instream, Hoja);
                    ExcelBuff.ReadSheet;

                    // Leer CIF de la empresa desde la fila 4, columna A y validar que coincida con la empresa actual
                    if ExcelBuff.Get(4, 1) then begin
                        As := ExcelBuff."Cell Value as Text";
                        // El CIF está en las últimas posiciones de la columna A
                        // Validar que el CIF del Excel coincida con el CIF de la empresa actual
                        if (CIFEmpresaActual <> '') and (StrPos(As, CIFEmpresaActual) > 0) then begin
                            // Leer departamento de la fila 2, columna D
                            // Formato: "NIVEL 4           03         DIRECTIVO"
                            // El departamento es la última palabra
                            DepartamentoHoja := '';
                            if ExcelBuff.Get(2, 4) then begin
                                As := ExcelBuff."Cell Value as Text";
                                // Extraer la última palabra (el departamento)
                                DepartamentoHoja := ExtraerUltimaPalabra(As);
                                if DepartamentoHoja <> '' then begin
                                    // Crear departamento si no existe
                                    CrearDepartamentoSiNoExiste(DepartamentoHoja);

                                    // Buscar fila de encabezados para identificar las columnas
                                    // Los encabezados están en la fila 8 (antes de los datos que empiezan en fila 9)
                                    FilaEncabezados := 8;
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

                                    // Buscar encabezados en la fila 8
                                    for j := 1 to 30 do begin
                                        if ExcelBuff.Get(FilaEncabezados, j) then begin
                                            As := UpperCase(ExcelBuff."Cell Value as Text");
                                            // Eliminar espacios y paréntesis para normalizar
                                            As := DelChr(As, '=', ' ');
                                            As := DelChr(As, '=', '(');
                                            As := DelChr(As, '=', ')');

                                            if StrPos(As, 'TOT.BRUTO') > 0 then
                                                ColDevengado := j
                                            else if (StrPos(As, 'SSTRAB') > 0) or (StrPos(As, 'SS.TRAB') > 0) or (StrPos(As, 'SEGURIDADSOCIALTRAB') > 0) then
                                                ColSSObrero := j
                                            else if (StrPos(As, 'IRPF') > 0) and (StrPos(As, 'TRI') > 0) then
                                                ColIRPF := j
                                            else if (StrPos(As, 'SSEMPRESA') > 0) or (StrPos(As, 'SS.EMPRESA') > 0) then
                                                ColSSEmpresa := j
                                            else if (StrPos(As, 'COSTEEMP') > 0) then
                                                ColCosteEmpresa := j
                                            else if (StrPos(As, 'ENFERMEDAD') > 0) or (StrPos(As, 'ACCIDENTE') > 0) or (StrPos(As, 'BASEACC') > 0) then
                                                ColEnfermedadAccidente := j
                                            else if (StrPos(As, 'BONIFIC') > 0) or (StrPos(As, 'BONIF') > 0) then
                                                ColBonificacion := j
                                            else if (StrPos(As, 'FUNDAE') > 0) then
                                                ColBonificacionFundae := j
                                            else if (StrPos(As, 'BANCO') > 0) or (StrPos(As, 'TOTAL.LIQ') > 0) or (StrPos(As, 'TOTALLIQ') > 0) then
                                                ColBanco := j
                                            else if (StrPos(As, 'KMS') > 0) or (StrPos(As, 'KM') > 0) then
                                                ColKms := j
                                            else if (StrPos(As, 'DIETA') > 0) and (StrPos(As, 'DIETAS') = 0) then
                                                ColDieta := j
                                            // Buscar nuevas columnas con códigos numéricos
                                            // Buscar por código numérico o por texto, más flexible
                                            else if (StrPos(As, '0030') > 0) or (StrPos(As, 'PPEX') > 0) or (StrPos(As, 'P.P.EX') > 0) or (StrPos(As, 'P.PEX') > 0) then
                                                if ColPPEx = 0 then
                                                    ColPPEx := j
                                                else if (StrPos(As, '0038') > 0) or (StrPos(As, 'MEJORA') > 0) then
                                                    if ColMejoraV = 0 then
                                                        ColMejoraV := j
                                                    else if (StrPos(As, '0140') > 0) or (StrPos(As, 'COMIDA') > 0) then
                                                        if ColComida = 0 then
                                                            ColComida := j
                                                        else if (StrPos(As, '0209') > 0) or (StrPos(As, 'DIETAS') > 0) then
                                                            // Solo si no es la columna Dieta (singular)
                                                            if (ColDietas = 0) and (ColDieta <> j) then
                                                                ColDietas := j
                                                            else if (StrPos(As, '0211') > 0) or (StrPos(As, 'PPVACA') > 0) or (StrPos(As, 'P.PVACA') > 0) or (StrPos(As, 'PVACA') > 0) then
                                                                if ColPPVaca = 0 then
                                                                    ColPPVaca := j
                                                                else if (StrPos(As, '0321') > 0) or (StrPos(As, 'PLFLEX') > 0) or (StrPos(As, 'PL.FLEX') > 0) then
                                                                    if ColPLFlex = 0 then
                                                                        ColPLFlex := j
                                                                    else if (StrPos(As, '0599') > 0) or (StrPos(As, 'INDEMNI') > 0) then
                                                                        if ColIndemni = 0 then
                                                                            ColIndemni := j
                                                                        else if (StrPos(As, '0795') > 0) or (StrPos(As, 'ANT.DIET') > 0) or (StrPos(As, 'ANTDIET') > 0) then
                                                                            if ColAntDiet = 0 then ColAntDiet := j;
                                        end;
                                    end;

                                    // Si no se encontraron columnas, intentar buscar en otras filas
                                    if (ColDevengado = 0) and (ColSSObrero = 0) and (ColIRPF = 0) then begin
                                        // Intentar buscar en la fila 7 o 9
                                        for FilaEncabezados := 7 to 9 do begin
                                            for j := 1 to 30 do begin
                                                if ExcelBuff.Get(FilaEncabezados, j) then begin
                                                    As := UpperCase(ExcelBuff."Cell Value as Text");
                                                    As := DelChr(As, '=', ' ');
                                                    if StrPos(As, 'TOT.BRUTO') > 0 then
                                                        ColDevengado := j
                                                    else if (StrPos(As, 'SSTRAB') > 0) or (StrPos(As, 'SS.TRAB') > 0) then
                                                        ColSSObrero := j
                                                    else if (StrPos(As, 'IRPF') > 0) and (StrPos(As, 'TRI') > 0) then
                                                        ColIRPF := j
                                                    else if (StrPos(As, 'SSEMPRESA') > 0) then
                                                        ColSSEmpresa := j
                                                    else if (StrPos(As, 'COSTEEMP') > 0) then
                                                        ColCosteEmpresa := j;
                                                end;
                                            end;
                                            if ColDevengado > 0 then
                                                break;
                                        end;
                                    end;

                                    // Procesar filas del Excel
                                    AcountInfo := 'Procesando hoja #1#### de #2####: #3####################\Progreso: @4@@@@@@@@@@@@@@@@';
                                    if HojasProcesadas = 1 then
                                        Ventana.Open(AcountInfo);
                                    Ventana.Update(1, HojasProcesadas);
                                    Ventana.Update(2, TotalHojas);
                                    Ventana.Update(3, Hoja);
                                    i := 9; // Las nóminas empiezan en la fila 9
                                    Total := 1000; // Ajustar según necesidad
                                    ContadorNominasHoja := 0;
                                    UltimoEmpleado := '';
                                    FilaVacia := 0; // Contador de filas vacías consecutivas

                                    while (i <= Total) do begin
                                        Ventana.Update(4, Round(i * 100 / Total, 1));

                                        // Leer código de empleado de la columna B (columna 2)
                                        if ExcelBuff.Get(i, 2) then begin
                                            FilaVacia := 0; // Resetear contador si hay datos
                                            CodigoEmpleado := ExcelBuff."Cell Value as Text";
                                            // Limpiar espacios y validar que sea un código válido
                                            CodigoEmpleado := DelChr(CodigoEmpleado, '=', ' ');
                                            // Si el código está vacío, intentar leer de la columna A
                                            if CodigoEmpleado = '' then begin
                                                if ExcelBuff.Get(i, 1) then begin
                                                    CodigoEmpleado := ExcelBuff."Cell Value as Text";
                                                    CodigoEmpleado := DelChr(CodigoEmpleado, '=', ' ');
                                                end;
                                            end;

                                            // Validar que sea un código válido (no vacío, no "Sección", y que tenga al menos un carácter)
                                            if (CodigoEmpleado <> '') and (CopyStr(UpperCase(CodigoEmpleado), 1, 7) <> 'SECCIÓN') and (StrLen(CodigoEmpleado) > 0) then begin
                                                // Guardar el último empleado procesado para anticipos/embargos
                                                UltimoEmpleado := CodigoEmpleado;
                                                // Buscar o crear empleado (en la empresa actual)
                                                if not Employee.Get(CodigoEmpleado) then begin
                                                    // Crear empleado si no existe
                                                    CrearEmpleadoSiNoExiste(Employee, CodigoEmpleado, EmpresaNombre, ExcelBuff, i);
                                                end;

                                                if Employee.Get(CodigoEmpleado) then begin
                                                    // Leer valores del Excel usando las columnas identificadas
                                                    Devengado := 0;
                                                    SSObrero := 0;
                                                    IRPF := 0;
                                                    SSEmpresa := 0;
                                                    EnfermedadAccidente := 0;
                                                    Bonificacion := 0;
                                                    BonificacionFundae := 0;
                                                    Anticipos := 0;
                                                    Embargos := 0;
                                                    DtoEspecie := 0;
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

                                                    // Leer Devengado (TOT. BRUTO)
                                                    if ColDevengado > 0 then begin
                                                        if ExcelBuff.Get(i, ColDevengado) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Devengado, As) then;
                                                        end;
                                                    end;

                                                    // Leer S.S Obrero (SS TRAB)
                                                    if ColSSObrero > 0 then begin
                                                        if ExcelBuff.Get(i, ColSSObrero) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(SSObrero, As) then;
                                                        end;
                                                    end;

                                                    // Leer IRPF (0999-TRI.IRPF)
                                                    if ColIRPF > 0 then begin
                                                        if ExcelBuff.Get(i, ColIRPF) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(IRPF, As) then;
                                                        end;
                                                    end;

                                                    // Leer SS empresa de la columna U (21) específicamente
                                                    // La SS empresa está en la columna U, no confundir con COSTE EMP
                                                    if ExcelBuff.Get(i, 21) then begin
                                                        As := ExcelBuff."Cell Value as Text";
                                                        As := DelChr(As, '=', ' ');
                                                        if As <> '' then
                                                            if Evaluate(SSEmpresa, As) then;
                                                    end;

                                                    // Si no se encontró en columna U, intentar con la columna detectada
                                                    if (SSEmpresa = 0) and (ColSSEmpresa > 0) and (ColSSEmpresa <> 21) then begin
                                                        if ExcelBuff.Get(i, ColSSEmpresa) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            As := DelChr(As, '=', ' ');
                                                            if As <> '' then
                                                                if Evaluate(SSEmpresa, As) then;
                                                        end;
                                                    end;

                                                    // Leer Enfermedad Accidente (BASE ACC)
                                                    if ColEnfermedadAccidente > 0 then begin
                                                        if ExcelBuff.Get(i, ColEnfermedadAccidente) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(EnfermedadAccidente, As) then;
                                                        end;
                                                    end;

                                                    // Leer Bonificación
                                                    if ColBonificacion > 0 then begin
                                                        if ExcelBuff.Get(i, ColBonificacion) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Bonificacion, As) then;
                                                        end;
                                                    end;

                                                    // Leer Bonificación Fundae
                                                    if ColBonificacionFundae > 0 then begin
                                                        if ExcelBuff.Get(i, ColBonificacionFundae) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(BonificacionFundae, As) then;
                                                        end;
                                                    end;

                                                    // Leer Banco (TOTAL.LIQ. - líquido a percibir)
                                                    if ColBanco > 0 then begin
                                                        if ExcelBuff.Get(i, ColBanco) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Banco, As) then;
                                                        end;
                                                    end;

                                                    // Leer Kms
                                                    if ColKms > 0 then begin
                                                        if ExcelBuff.Get(i, ColKms) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Kms, As) then;
                                                        end;
                                                    end;

                                                    // Leer Dieta
                                                    if ColDieta > 0 then begin
                                                        if ExcelBuff.Get(i, ColDieta) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Dieta, As) then;
                                                        end;
                                                    end;

                                                    // Leer P.P.Ex (0030)
                                                    if ColPPEx > 0 then begin
                                                        if ExcelBuff.Get(i, ColPPEx) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(PPEx, As) then;
                                                        end;
                                                    end;

                                                    // Leer MEJORA V (0038)
                                                    if ColMejoraV > 0 then begin
                                                        if ExcelBuff.Get(i, ColMejoraV) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(MejoraV, As) then;
                                                        end;
                                                    end;

                                                    // Leer COMIDA (0140)
                                                    if ColComida > 0 then begin
                                                        if ExcelBuff.Get(i, ColComida) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Comida, As) then;
                                                        end;
                                                    end;

                                                    // Leer DIETAS (0209)
                                                    if ColDietas > 0 then begin
                                                        if ExcelBuff.Get(i, ColDietas) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Dietas, As) then;
                                                        end;
                                                    end;

                                                    // Leer P.P Vaca (0211)
                                                    if ColPPVaca > 0 then begin
                                                        if ExcelBuff.Get(i, ColPPVaca) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(PPVaca, As) then;
                                                        end;
                                                    end;

                                                    // Leer PL. FLEX (0321)
                                                    if ColPLFlex > 0 then begin
                                                        if ExcelBuff.Get(i, ColPLFlex) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(PLFlex, As) then;
                                                        end;
                                                    end;

                                                    // Leer Indemni. (0599)
                                                    if ColIndemni > 0 then begin
                                                        if ExcelBuff.Get(i, ColIndemni) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(Indemni, As) then;
                                                        end;
                                                    end;

                                                    // Leer Ant.diet (0795-Ant.diet)
                                                    if ColAntDiet > 0 then begin
                                                        if ExcelBuff.Get(i, ColAntDiet) then begin
                                                            As := ExcelBuff."Cell Value as Text";
                                                            if As <> '' then
                                                                if Evaluate(AntDiet, As) then;
                                                        end;
                                                    end;

                                                    // Guardar siempre que haya un empleado válido
                                                    // Generar número de documento si no existe
                                                    if Doc = '' then begin
                                                        if NoSeries.Code <> '' then begin
                                                            Clear(NoSeriesMgt);
                                                            Doc := NoSeriesMgt.GetNextNo(NoSeries.Code, rFec, false);
                                                        end else
                                                            Doc := Format(rFec, 0, '<Year4><Month,2><Day,2>');
                                                    end;

                                                    // Guardar en tabla de nóminas detalle
                                                    GuardarNominaDetalle(
                                                        Employee, rFec, DepartamentoHoja,
                                                        Devengado, SSObrero, IRPF, SSEmpresa, EnfermedadAccidente,
                                                        Bonificacion, BonificacionFundae, Anticipos, Embargos,
                                                        DtoEspecie, Dieta, Kms, Banco,
                                                        PPEx, MejoraV, Comida, Dietas, PPVaca, PLFlex, Indemni, AntDiet);
                                                    ContadorNominas += 1;
                                                end;
                                            end else begin
                                                // Buscar anticipos, embargos, etc. en la columna B
                                                if ExcelBuff.Get(i, 2) then begin
                                                    As := ExcelBuff."Cell Value as Text";
                                                    if As <> '' then begin
                                                        As := UpperCase(As);
                                                        case CopyStr(As, 1, 7) of
                                                            'ANTICIP', 'ANTICIPO':
                                                                begin
                                                                    if ExcelBuff.Get(i, 7) then begin
                                                                        As := ExcelBuff."Cell Value as Text";
                                                                        if As <> '' then
                                                                            if Evaluate(Importe, As) then begin
                                                                                // Buscar el último empleado procesado para añadir el anticipo
                                                                                // Esto requeriría mantener una referencia al último empleado
                                                                            end;
                                                                    end;
                                                                end;
                                                            'EMBARGO':
                                                                begin
                                                                    if ExcelBuff.Get(i, 7) then begin
                                                                        As := ExcelBuff."Cell Value as Text";
                                                                        if As <> '' then
                                                                            if Evaluate(Importe, As) then begin
                                                                                // Similar al anticipo
                                                                            end;
                                                                    end;
                                                                end;
                                                            'DTO ESP', 'DESC ESP':
                                                                begin
                                                                    if ExcelBuff.Get(i, 7) then begin
                                                                        As := ExcelBuff."Cell Value as Text";
                                                                        if As <> '' then
                                                                            if Evaluate(Importe, As) then begin
                                                                                // Similar al anticipo
                                                                            end;
                                                                    end;
                                                                end;
                                                        end;
                                                    end;
                                                end;
                                            end;
                                        end else begin
                                            // Si no hay datos en la columna B, incrementar contador de filas vacías
                                            FilaVacia += 1;
                                            // Si hay 5 filas vacías consecutivas, asumir que terminó el archivo
                                            if FilaVacia >= 5 then
                                                break;
                                        end;
                                        i += 1;
                                    end;

                                    // Cerrar la hoja actual
                                    ExcelBuff.CloseBook();

                                    // Actualizar progreso
                                    Ventana.Update(4, 100);

                                    // Forzar actualización de cabecera después de procesar la hoja
                                    // para asegurar que todos los totales estén correctos
                                    ActualizarCabecerasDepartamento(DepartamentoHoja, rFec);
                                end;
                            end;
                        end;
                    end;
                end;
            until NameValue.Next() = 0;

        Ventana.Close();

        // Mostrar mensaje con información
        Message('Nóminas importadas correctamente.\Hojas procesadas: %1 de %2\Fecha: %3\Nóminas procesadas: %4\Puede revisarlas y contabilizarlas desde la página de Nóminas.', HojasProcesadas, TotalHojas, rFec, ContadorNominas);
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

        // Intentar leer nombre del empleado de la columna C (3) si está disponible
        if ExcelBuff.Get(Fila, 3) then
            NombreEmpleado := CopyStr(ExcelBuff."Cell Value as Text", 1, MaxStrLen(Employee."First Name"));

        // Intentar leer CIF del empleado de la columna A (1) si está disponible
        // Nota: La tabla Employee no tiene campo VAT Registration No. estándar
        // Se puede usar el campo "Social Security No." si está disponible
        if ExcelBuff.Get(Fila, 1) then
            CIFEmpleado := CopyStr(ExcelBuff."Cell Value as Text", 1, 20);

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

        // Buscar si ya existe el registro
        rNomDet.SetRange(Fecha, Fecha);
        rNomDet.SetRange(Empleado, Employee."No.");
        rNomDet.SetRange(Departamento, Departamento);

        if rNomDet.FindFirst() then begin
            // Actualizar registro existente
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
            rNomDet.Personal := Devengado - SSObrero - IRPF - Anticipos - Embargos;
            rNomDet.Modify();
        end else begin
            // Crear nuevo registro
            rNomDet.Init();
            rNomDet.Fecha := Fecha;
            rNomDet.Empleado := Employee."No.";
            rNomDet.Departamento := Departamento;
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

    /// <summary>
    /// Crea las líneas de diario para una nómina
    /// </summary>
    procedure CrearLineasDiarioNominas(
        var GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        EmpresaNombre: Text[30];
        Fecha: Date;
        DocNo: Code[20];
        var LINEA: Integer;
        rOr: Record "Source Code";
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
        Personal: Decimal;
        AntDiet: Decimal)
    var
        Cuenta: Code[20];
    begin
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", Devengado - Kms - DtoEspecie - Dieta);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", Kms);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", DtoEspecie);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", DtoEspecie);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", Dieta);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", Anticipos);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", Embargos);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", Bonificacion);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", BonificacionFundae);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code");
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", SSEmpresa);
            GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."));
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", EnfermedadAccidente);
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."))
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Debit Amount", EnfermedadAccidente);
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."))
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'S.S Obrero'); // 476
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            // La cuenta 476 debe incluir SS Obrero + SS Empresa
            GenJnlLine.Validate("Credit Amount", SSObrero + SSEmpresa);
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."))
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
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
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'IRPF');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", IRPF);
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."))
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // 465 Remuneraciones pendientes de pago (Personal - líquido a percibir)
        // Según PGC, el Personal (Devengado - SS Obrero - IRPF - Anticipos - Embargos) debe ir a cuenta 465
        if Personal <> 0 then begin
            GenJnlLine.Init;
            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'NOMINAS';
            GenJnlLine."Line No." := LINEA;
            GenJnlLine."Posting Date" := Fecha;
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Source Code" := rOr.Code;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account Type");
            // Usar cuenta 465 (Personal/Cobro Nómina)
            Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Personal');
            if Cuenta = '' then
                Cuenta := GetCuentaConceptoNominas(EmpresaNombre, Employee."No.", 'Cobro Nómina');
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", Personal);
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."))
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;

        // Ant.diet (0795-Ant.diet)
        if AntDiet <> 0 then begin
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
            GenJnlLine."Account No." := Cuenta;
            GenJnlLine.Validate("Account No.");
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 1 Code", Employee."Global Dimension 1 Code")
            else
                GenJnlLine.Validate("Shortcut Dimension 1 Code", '');
            GenJnlLine.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
            GenJnlLine.Validate("Credit Amount", AntDiet);
            if CopyStr(Cuenta, 1, 1) in ['6', '7'] then
                GenJnlLine.Validate("Shortcut Dimension 2 Code", GetProgramaNominas(Employee."No."))
            else
                GenJnlLine.Validate("Shortcut Dimension 2 Code", '');
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            GenJnlLine."Gen. Bus. Posting Group" := '';
            GenJnlLine."Gen. Prod. Posting Group" := '';
            GenJnlLine."VAT Bus. Posting Group" := '';
            GenJnlLine."VAT Prod. Posting Group" := '';
            GenJnlLine.Insert;
            LINEA := LINEA + 10000;
        end;
    end;

    /// <summary>
    /// Crea movimientos de empleado cuando se registra el diario de nóminas
    /// Se ejecuta mediante EventSubscriber cuando se registra el diario
    /// </summary>
    procedure CrearMovimientosEmpleadosDesdeDiario(DocNo: Code[20]; Fecha: Date)
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        Employee: Record Employee;
        rNomDet: Record "Nominas Detalle";
        rNom: Record "Cabecera Nominas";
        NetoAPagar: Decimal;
    begin
        // Buscar en nóminas detalle por fecha y documento
        rNom.SetRange(Fecha, Fecha);
        rNom.SetRange("Nº Documento", DocNo);
        if rNom.FindFirst() then begin
            rNomDet.SetRange(Fecha, Fecha);
            rNomDet.SetRange(Departamento, rNom.Departamento);
        end else
            error('No se encontró la nómina para el documento %1 y fecha %2', DocNo, Fecha);
        // Buscar por el documento guardado en la cabecera de nóminas
        // Como no tenemos el documento en detalle, buscamos todas las nóminas de esa fecha
        // y verificamos que no se haya creado ya el movimiento

        if rNomDet.FindSet() then
            repeat
                if Employee.Get(rNomDet.Empleado) then begin
                    // Verificar si ya existe el movimiento para evitar duplicados
                    EmplLedgEntry.Reset();
                    EmplLedgEntry.SetRange("Employee No.", Employee."No.");
                    EmplLedgEntry.SetRange("Document No.", DocNo);
                    EmplLedgEntry.SetRange("Posting Date", Fecha);

                    if not EmplLedgEntry.FindFirst() then begin
                        // Usar Banco que es el líquido a percibir (neto a pagar)
                        NetoAPagar := rNomDet.Personal;

                        // Solo crear movimiento si hay importe a pagar
                        if NetoAPagar <> 0 then begin
                            // Obtener el siguiente número de entrada
                            EmplLedgEntry.Reset();
                            EmplLedgEntry.SetCurrentKey("Entry No.");
                            if EmplLedgEntry.FindLast() then
                                EmplLedgEntry."Entry No." := EmplLedgEntry."Entry No." + 1
                            else
                                EmplLedgEntry."Entry No." := 1;

                            // Inicializar el nuevo registro
                            EmplLedgEntry.Init();
                            EmplLedgEntry."Employee No." := Employee."No.";
                            EmplLedgEntry."Posting Date" := Fecha;
                            EmplLedgEntry."Document Type" := EmplLedgEntry."Document Type"::Payment;
                            EmplLedgEntry."Document No." := DocNo;
                            EmplLedgEntry.Description := CopyStr('Nómina ' + ObtenerMesEspanol(Fecha), 1, 50);
                            EmplLedgEntry."Currency Code" := '';
                            EmplLedgEntry.Amount := NetoAPagar;
                            EmplLedgEntry."Remaining Amount" := NetoAPagar;
                            EmplLedgEntry."Original Amount" := NetoAPagar;
                            EmplLedgEntry."Global Dimension 1 Code" := Employee."Global Dimension 1 Code";
                            EmplLedgEntry."Global Dimension 2 Code" := GetProgramaNominas(Employee."No.");
                            EmplLedgEntry.Insert(true);
                        end;
                    end;
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
                    Cuenta := rConf.Personal;
                'Cobro Nómina':
                    Cuenta := rConf."Cobro Nómina";
                'Ant.diet':
                    Cuenta := rConf."Ant.diet";
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
                    Cuenta := rConf.Personal;
                'Cobro Nómina':
                    Cuenta := rConf."Cobro Nómina";
                'Ant.diet':
                    Cuenta := rConf."Ant.diet";
            end;
            if Cuenta <> '' then
                exit(Cuenta);
        end;

        // Si no hay configuración por empresa, buscar configuración general (empresa y empleado vacíos)
        rConf.ChangeCompany('');
        if rConf.Get('', '') then begin
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
            end;
        end;

        exit(Cuenta);
    end;

    /// <summary>
    /// Obtiene el programa de un empleado
    /// </summary>
    local procedure GetProgramaNominas(Empleado: Code[20]): Code[20]
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
}

codeunit 50302 "Eventos-proyectos"
{
    Permissions = TableData "G/L Entry" = rimd, Tabledata "Job Ledger Entry" = rimd;
    trigger OnRun()
    begin

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
        PurchaseInvHeader: Record "Purch. Inv. Header";
        MovRetencion: Record "Payments Retention Ledger Ent.";
        PagoProyecto: Record "Proyecto Movimiento Pago";
    begin
        if Rec.IsTemporary then
            exit;
        if PurchaseInvHeader.Get(Rec."Document No.") then begin
            PurchaseInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
            Rec."Neto Factura" := PurchaseInvHeader.Amount;
            Rec."Bruto Factura" := PurchaseInvHeader."Amount Including VAT";
            Rec."IGIC O IVA" := PurchaseInvHeader."Amount Including VAT" - PurchaseInvHeader.Amount;
            MovRetencion.SetRange("Document Type", MovRetencion."Document Type"::Invoice);
            MovRetencion.SetRange("Document No.", Rec."Document No.");
            if MovRetencion.FindFirst() then
                Rec."IRPF" := MovRetencion.Amount
            else
                Rec."IRPF" := 0;
            PagoProyecto.SetRange("Document No.", Rec."Document No.");
            If Rec."Facturado Contra" <> '' Then
                PagoProyecto.SetRange("Vendor No.", Rec."Facturado Contra")
            else
                PagoProyecto.SetRange("Vendor No.");
            PagoProyecto.SetRange("Job No.", Rec."Job No.");
            PagoProyecto.SetRange("Job Task No.", Rec."Job Task No.");
            if PagoProyecto.FindFirst() then begin
                PagoProyecto."Amount Paid" := PagoProyecto."Amount Paid";
                PagoProyecto."Base Amount Pending" := PagoProyecto."Base Amount" - PagoProyecto."Base Amount Paid";
                PagoProyecto."Amount Pending" := PagoProyecto."Amount" - PagoProyecto."Amount Paid";
                if PagoProyecto."Amount Pending" = 0 Then begin
                    PagoProyecto."Base Amount Paid" := PagoProyecto."Base Amount";
                    PagoProyecto."Base Amount Pending" := 0;
                end;
                // no dejar que los importes pagados sean mallores que la factura
                if PagoProyecto."Amount Paid" > PagoProyecto.Amount then begin
                    PagoProyecto."Amount Paid" := PagoProyecto.Amount;
                    PagoProyecto."Amount Pending" := 0;
                end;
                if PagoProyecto."Base Amount Paid" > PagoProyecto."Base Amount" then begin
                    PagoProyecto."Base Amount Paid" := PagoProyecto."Base Amount";
                    PagoProyecto."Base Amount Pending" := 0;
                end;
                PagoProyecto.Modify(false);
            end;
            If Rec."Entry No." <> 0 Then
                Rec.Modify(false);
        end else begin
            Rec."Neto Factura" := Rec."Total Cost";
            Rec."Bruto Factura" := Rec."Total Cost (LCY)";
            // IVA/IRPF: de momento 0; rellenar desde fuente (ej. extensión Job Journal Line) si se necesita
            Rec."IGIC O IVA" := 0;
            Rec."Importe IGIC O IVA" := 0;
            Rec."IRPF" := 0;
            If Rec."Entry No." <> 0 Then
                Rec.Modify(false);
        end;
    end;


    procedure DatosFactura(DocumentNo: Code[20])
    var
        Rec: Record "Job Ledger Entry";
        PurchaseInvHeader: Record "Purch. Inv. Header";
        MovRetencion: Record "Payments Retention Ledger Ent.";
        PagoProyecto: Record "Proyecto Movimiento Pago";
    begin
        if Rec.IsTemporary then
            exit;
        Rec.SetRange("Document No.", DocumentNo);
        if Rec.FindFirst() then begin
            If Rec."Neto Factura" <> 0 Then exit;
            if PurchaseInvHeader.Get(Rec."Document No.") then begin
                PurchaseInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
                Rec."Neto Factura" := PurchaseInvHeader.Amount;
                Rec."Bruto Factura" := PurchaseInvHeader."Amount Including VAT";
                Rec."IGIC O IVA" := PurchaseInvHeader."Amount Including VAT" - PurchaseInvHeader.Amount;
                MovRetencion.SetRange("Document Type", MovRetencion."Document Type"::Invoice);
                MovRetencion.SetRange("Document No.", Rec."Document No.");
                if MovRetencion.FindFirst() then
                    Rec."IRPF" := MovRetencion.Amount
                else
                    Rec."IRPF" := 0;
                PagoProyecto.SetRange("Document No.", Rec."Document No.");
                PagoProyecto.SetRange("Job No.", Rec."Job No.");
                PagoProyecto.SetRange("Job Task No.", Rec."Job Task No.");
                if PagoProyecto.FindFirst() then begin
                    PagoProyecto."Amount Paid" := PagoProyecto."Amount Paid";
                    PagoProyecto."Base Amount Pending" := PagoProyecto."Base Amount" - PagoProyecto."Base Amount Paid";
                    PagoProyecto."Amount Pending" := PagoProyecto."Amount" - PagoProyecto."Amount Paid";

                    if PagoProyecto."Amount Pending" = 0 Then begin
                        PagoProyecto."Base Amount Paid" := PagoProyecto."Base Amount";
                        PagoProyecto."Base Amount Pending" := 0;
                    end;
                    // no dejar que los importes pagados sean mallores que la factura
                    if PagoProyecto."Amount Paid" > PagoProyecto.Amount then begin
                        PagoProyecto."Amount Paid" := PagoProyecto.Amount;
                        PagoProyecto."Amount Pending" := 0;
                    end;
                    if PagoProyecto."Base Amount Paid" > PagoProyecto."Base Amount" then begin
                        PagoProyecto."Base Amount Paid" := PagoProyecto."Base Amount";
                        PagoProyecto."Base Amount Pending" := 0;
                    end;
                    PagoProyecto.Modify(false);
                end;
                If Rec."Entry No." <> 0 Then
                    Rec.Modify(false);
            end else begin
                Rec."Neto Factura" := Rec."Total Cost";
                Rec."Bruto Factura" := Rec."Total Cost (LCY)";
                // IVA/IRPF: de momento 0; rellenar desde fuente (ej. extensión Job Journal Line) si se necesita
                Rec."IGIC O IVA" := 0;
                Rec."Importe IGIC O IVA" := 0;
                Rec."IRPF" := 0;
                If Rec."Entry No." <> 0 Then
                    Rec.Modify(false);
            end;
        end;
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

    //OnAfterSetPurchaseLineFilters
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Lines Instruction Mgt.", 'OnAfterSetPurchaseLineFilters', '', false, false)]
    local procedure OnAfterSetPurchaseLineFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        JobSetup: Record "Jobs Setup";
    begin
        /*   JobSetup.Get();
           if JobSetup."Cód. Proyecto Obligatorio" then
               PurchaseLine.SetFilter("Job No.", '<>%1', '');
   */

    end;

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
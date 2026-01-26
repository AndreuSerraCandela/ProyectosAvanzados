codeunit 50302 "Eventos-proyectos"
{
    trigger OnRun()
    begin

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




    var
        myInt: Integer;
}
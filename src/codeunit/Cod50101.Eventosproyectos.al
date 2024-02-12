codeunit 50101 "Eventos-proyectos"
{
    trigger OnRun()
    begin

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

    var
        myInt: Integer;
}
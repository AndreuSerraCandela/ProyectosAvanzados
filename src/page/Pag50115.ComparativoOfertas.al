page 50115 "Comparativo Ofertas" //50
{
    PageType = List;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = Const(Quote));
    CardPageId = "Purchase Quote";

    layout
    {
        area(Content)
        {
            repeater(Detalle)
            {

                field("No. Proyecto"; Rec."No. Proyecto")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. Proyecto field.';
                }
                field("Descripcion Proyecto"; DescripcionProyecto())
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Descripcion Proyecto field.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the vendor who delivers the products.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor who delivers the products.';
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date that you want the vendor to deliver your order. The field is used to calculate the latest date you can order, as follows: requested receipt date - lead time calculation = order date. If you do not need delivery on a specific date, you can leave the field blank.';
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the posting of the purchase document will be recorded.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the related document was created.';
                }

                field(Categoría; Rec.Categorias)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Categorias field.';
                }
                field(Aceptada; Rec.Aceptada)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Aceptada field.';
                }

                field("Total Amount Excl. VAT"; TotalPurchaseLine.Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalExclVATCaption(Currency.Code);
                    Caption = 'Total Amount Excl. VAT';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                }
                field("Total VAT Amount"; VATAmount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalVATCaption(Currency.Code);
                    Caption = 'Total VAT';
                    Editable = false;
                    ToolTip = 'Specifies the sum of VAT amounts on all lines in the document.';
                }
                field("Total Amount Incl. VAT"; TotalPurchaseLine."Amount Including VAT")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalInclVATCaption(Currency.Code);
                    Caption = 'Total Amount Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the sum of the value in the Line Amount Incl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                }
            }
        }
    }



    var
        myInt: Integer;
        Currency: Record Currency;
        DocumentTotals: Codeunit "Document Totals";

    protected var
        TotalPurchaseHeader: Record "Purchase Header";
        TotalPurchaseLine: Record "Purchase Line";
        ShortcutDimCode: array[8] of Code[20];
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
        VATAmount: Decimal;

    trigger OnAfterGetRecord()
    begin
        GetTotalsPurchaseHeader();
        CalculateTotals();

    end;

    local procedure GetTotalsPurchaseHeader()
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange("Document Type", Rec."Document Type");
        if PurchLine.FindSet() then
            DocumentTotals.GetTotalPurchaseHeaderAndCurrency(PurchLine, TotalPurchaseHeader, Currency);
    end;

    procedure ClearTotalPurchaseHeader();
    begin
        Clear(TotalPurchaseHeader);
    end;

    local procedure DescripcionProyecto(): Text
    var
        Job: Record Job;
    begin
        If Job.Get(Rec."No. Proyecto") then
            exit(Job.Description)
        else
            exit('');
    end;

    procedure CalculateTotals()
    var
        PurchLine: Record "Purchase Line";
        xPurchLine: Record "Purchase Line";
    begin

        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange("Document Type", Rec."Document Type");
        xPurchLine.SetFilter("Document No.", '<>%1', Rec."No.");
        xPurchLine.SetRange("Document Type", Rec."Document Type");
        if not xPurchLine.FindSet() then xPurchLine.init;
        if PurchLine.FindSet() then
            DocumentTotals.PurchaseCheckIfDocumentChanged(PurchLine, xPurchLine);
        DocumentTotals.CalculatePurchaseSubPageTotals(
          TotalPurchaseHeader, TotalPurchaseLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        DocumentTotals.RefreshPurchaseLine(PurchLine);
    end;
}
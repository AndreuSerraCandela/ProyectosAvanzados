pageextension 50305 "PurchaseOrder" extends "Purchase Order" //50
{
    layout
    {
        addlast(General)
        {

            field("No. Proyecto"; Rec."No. Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Proyecto field.';
            }

            /*
            field("Your Reference"; Rec."Your Reference")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Your Reference field.';
            }
            */
        }
        modify("Quote No.")
        {
            trigger OnDrillDown()
            var
                PurchaseQuote: Record "Purchase Header";
                PurchaQuoteArchiva: Record "Purchase Header Archive";
            begin

                PurchaQuoteArchiva.SetRange("Document Type", PurchaQuoteArchiva."Document Type"::Quote);
                PurchaQuoteArchiva.SetRange("No.", Rec."Quote No.");
                if PurchaQuoteArchiva.Findlast() then
                    Page.RunModal(Page::"Purchase Quote Archives", PurchaQuoteArchiva);

                // PurchaseQuote.SetRange("Document Type", PurchaseQuote."Document Type"::Quote);
                // PurchaseQuote.SetRange("No.", Rec."Quote No.");
                // if PurchaseQuote.FindFirst then
                //     Page.RunModal(Page::"Purchase Quotes", PurchaseQuote);
            end;
        }
        addafter("Quote No.")
        {
            group("Work Description")
            {
                Caption = 'Work Description';
                field(WorkDescription; WorkDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies the products or service being offered';

                    trigger OnValidate()
                    begin
                        Rec.SetWorkDescription(WorkDescription);
                    end;
                }
            }
        }
    }

    actions
    {


    }

    var
        myInt: Integer;
        WorkDescription: Text;

    trigger OnAfterGetRecord()
    begin
        WorkDescription := Rec.GetWorkDescription();
    end;
}
pageextension 50315 "PurchaseInvoice" extends "Purchase Invoice" //52
{
    layout
    {
        addlast(General)
        {

            field("No. Proyecto"; Rec."No. Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Proyecto field.';
            }

            /*
            field("Your Reference"; Rec."Your Reference")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Your Reference field.';
            }
            */
        }

        addafter("Vendor Invoice No.")
        {
            group("Work Description")
            {
                Caption = 'Work Description';
                field(WorkDescription; WorkDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies the products or service being offered';

                    trigger OnValidate()
                    begin
                        Rec.SetWorkDescription(WorkDescription);
                    end;
                }
            }
        }
    }



    var
        myInt: Integer;
        WorkDescription: Text;

    trigger OnAfterGetRecord()
    begin
        WorkDescription := Rec.GetWorkDescription();
    end;
}
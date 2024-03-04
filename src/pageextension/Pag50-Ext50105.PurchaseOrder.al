pageextension 50105 "PurchaseOrder" extends "Purchase Order" //50
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
            begin
                PurchaseQuote.SetRange("Document Type", PurchaseQuote."Document Type"::Quote);
                PurchaseQuote.SetRange("No.", Rec."Quote No.");
                if PurchaseQuote.FindFirst then
                    Page.RunModal(Page::"Purchase Quotes", PurchaseQuote);
            end;
        }
    }

    actions
    {


    }

    var
        myInt: Integer;
}
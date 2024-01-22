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
    }

    actions
    {


    }

    var
        myInt: Integer;
}
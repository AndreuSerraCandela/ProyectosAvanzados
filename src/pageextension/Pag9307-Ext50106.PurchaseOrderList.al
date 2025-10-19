pageextension 50306 "PurchaseOrderList" extends "Purchase Order List" //9307
{
    layout
    {
        addlast(Control1)
        {
            field("No. Proyecto"; Rec."No. Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Proyecto field.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
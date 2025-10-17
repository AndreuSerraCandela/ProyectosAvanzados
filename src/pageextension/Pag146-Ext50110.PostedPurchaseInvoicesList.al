pageextension 50310 "Posted Purchase Invoices List" extends "Posted Purchase Invoices" //146
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
}
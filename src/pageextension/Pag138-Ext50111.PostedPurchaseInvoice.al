pageextension 50111 "Posted Purchase Invoice" extends "Posted Purchase Invoice" //138
{
    layout
    {
        addafter("Vendor Invoice No.")
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
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
            field("Work Description"; Rec."Work Description")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Work Description field.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
        WorkDescription: Text;

    trigger OnAfterGetRecord()
    begin
        WorkDescription := Rec.GetWorkDescription();
    end;



}
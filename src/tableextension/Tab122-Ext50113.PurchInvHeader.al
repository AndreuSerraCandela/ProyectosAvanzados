tableextension 50113 "Purch. Inv. Header" extends "Purch. Inv. Header" //122
{
    fields
    {
        // Add changes to table fields here
        field(50100; "No. Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Proyecto';
            TableRelation = Job."No.";
        }
    }

    var
        myInt: Integer;
}
tableextension 50109 "PurchHeader" extends "Purchase Header" //38
{
    fields
    {
        field(50100; "No. Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Proyecto';
            TableRelation = Job."No.";
        }
        field(50101; "Cod. Oferta"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
    }


    var
        myInt: Integer;


}
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
        field(90002; Categorias; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Categorias;
        }
        field(90003; Aceptada; Boolean)
        {
            DataClassification = ToBeClassified;

        }
    }


    var
        myInt: Integer;


}
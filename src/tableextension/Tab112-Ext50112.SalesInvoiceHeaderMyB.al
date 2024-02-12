tableextension 50112 "SalesInvoiceHeaderMyB" extends "Sales Invoice Header" //112
{
    fields
    {
        field(50100; "Cod. Oferta de Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(50101; "No.Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}
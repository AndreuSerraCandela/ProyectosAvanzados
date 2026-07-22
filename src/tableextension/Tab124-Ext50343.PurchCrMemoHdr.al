tableextension 50343 "Purch. Cr. Memo Hdr. Ext" extends "Purch. Cr. Memo Hdr." //124
{
    fields
    {
        field(50100; "No. Proyecto"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No. Proyecto';
            TableRelation = Job."No.";
        }
    }
}

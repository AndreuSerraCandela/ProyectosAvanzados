tableextension 50337 "Employee Posting Group Ext" extends "Employee Posting Group" //5221
{
    fields
    {
        field(50100; "Cuenta IRPF"; Code[20])
        {
            Caption = 'Cuenta IRPF', Comment = 'ESP="Cuenta IRPF"';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(50101; "Cuenta Seg Social"; Code[20])
        {
            Caption = 'Cuenta Seg. Social', Comment = 'ESP="Cuenta Seg Social"';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }
}

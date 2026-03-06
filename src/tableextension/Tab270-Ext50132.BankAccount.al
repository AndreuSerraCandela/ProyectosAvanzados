tableextension 50335 "Bank Account Ext" extends "Bank Account" //270
{
    fields
    {
        field(50000; Operacion; Enum "Operacion Banco")
        {
            Caption = 'Operacion';
            DataClassification = CustomerContent;
        }
    }
}

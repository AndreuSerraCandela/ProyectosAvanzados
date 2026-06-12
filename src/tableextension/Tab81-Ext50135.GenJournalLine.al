tableextension 50340 "Gen. Journal Line Ext" extends "Gen. Journal Line" //81
{
    fields
    {
        field(50100; "Tipo Mov. Empleado"; Enum "Tipo Mov. Empleado")
        {
            Caption = 'Tipo Mov. Empleado', Comment = 'ESP="Tipo Mov. Empleado"';
            DataClassification = CustomerContent;
        }
    }
}

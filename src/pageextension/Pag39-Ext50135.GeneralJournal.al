pageextension 50341 "General Journal Ext" extends "General Journal" //39
{
    layout
    {
        addafter("Account No.")
        {
            field("Tipo Mov. Empleado"; Rec."Tipo Mov. Empleado")
            {
                ApplicationArea = All;
                ToolTip = 'Clasifica el movimiento de empleado: nómina, IRPF o Seguridad Social.', Comment = 'ESP="Clasifica el movimiento de empleado: nómina, IRPF o Seguridad Social."';
            }
        }
    }
}

pageextension 50338 "Employee Posting Groups Ext" extends "Employee Posting Groups"
{
    layout
    {
        addafter("Payables Account")
        {
            field("Cuenta IRPF"; Rec."Cuenta IRPF")
            {
                ApplicationArea = All;
                ToolTip = 'Cuenta contable de IRPF para este grupo de registro de empleado.', Comment = 'ESP="Cuenta contable de IRPF para este grupo de registro de empleado."';
            }
            field("Cuenta Seg Social"; Rec."Cuenta Seg Social")
            {
                ApplicationArea = All;
                ToolTip = 'Cuenta contable de Seguridad Social para este grupo de registro de empleado.', Comment = 'ESP="Cuenta contable de Seguridad Social para este grupo de registro de empleado."';
            }
        }
    }
}

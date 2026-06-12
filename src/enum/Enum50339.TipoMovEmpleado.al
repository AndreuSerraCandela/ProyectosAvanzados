enum 50339 "Tipo Mov. Empleado"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Nomina)
    {
        Caption = 'Nómina', Comment = 'ESP="Nómina"';
    }
    value(2; IRPF)
    {
        Caption = 'IRPF', Comment = 'ESP="IRPF"';
    }
    value(3; "Seg. Social")
    {
        Caption = 'Seg. Social', Comment = 'ESP="Seg. Social"';
    }
}

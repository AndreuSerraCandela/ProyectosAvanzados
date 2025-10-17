tableextension 50304 GLAccountProyectosAvanzados extends "G/L Account" //15
{
    fields
    {
        field(50100; "Mostrar en lineas de planif."; Boolean)
        {
            //  Caption = '';
            Caption = 'Mostrar en lineas de planif.', comment = 'ESP="Mostrar en lineas de planificacion"';
            DataClassification = ToBeClassified;
        }
    }
}

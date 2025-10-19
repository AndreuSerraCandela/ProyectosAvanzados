pageextension 50302 GLAccountCardProyectosAvanzado extends "G/L Account Card" //17
{
    layout
    {
        addafter("Direct Posting")
        {

            field("Mostrar en lineas de planif."; Rec."Mostrar en lineas de planif.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Mostrar en lineas de planif. field.', Comment = 'ESP="Mostrar en lineas de planificacion"';
            }
        }

    }
}

pageextension 50336 "Bank Account Card Ext" extends "Bank Account Card" //370
{
    layout
    {
        addlast(General)
        {
            field(Operacion; Rec.Operacion)
            {
                ApplicationArea = All;
                Caption = 'Operacion';
                ToolTip = 'Especifica el tipo de operación: Préstamo, Credito o ninguno.';
            }
        }
    }
}

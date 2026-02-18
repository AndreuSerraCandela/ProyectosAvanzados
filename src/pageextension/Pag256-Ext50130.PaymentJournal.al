/// <summary>
/// PageExtension Payment Journal Ext (ID 50130) - Extiende Payment Journal (256).
/// Añade los campos Job No. y Job Task No. al diario de pagos.
/// </summary>
pageextension 50332 "Payment Journal Ext" extends "Payment Journal"
{
    layout
    {
        addafter("Account No.")
        {
            field("Job No."; Rec."Job No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Nº Proyecto';
                ToolTip = 'Especifica el número del proyecto asociado a esta línea del diario de pagos.';
            }
            field("Job Task No."; Rec."Job Task No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Nº Tarea Proyecto';
                ToolTip = 'Especifica el número de la tarea del proyecto asociada a esta línea del diario de pagos.';
            }
        }
    }
}

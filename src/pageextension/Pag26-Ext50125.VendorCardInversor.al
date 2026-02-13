/// <summary>
/// PageExtension Vendor Card (ID 50326) extends Vendor Card.
/// Muestra el campo Inversor en la ficha del proveedor.
/// </summary>
pageextension 50326 "Vendor Card Inversor" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field(Inversor; Rec.Inversor)
            {
                ApplicationArea = All;
                ToolTip = 'Indica si el proveedor es inversor.';
            }
        }
    }
}

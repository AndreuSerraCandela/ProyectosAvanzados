/// <summary>
/// PageExtension Vendor List (ID 50327) extends Vendor List.
/// Muestra el campo Inversor en la lista de proveedores.
/// </summary>
pageextension 50327 "Vendor List Inversor" extends "Vendor List"
{
    layout
    {
        addafter(Name)
        {
            field(Inversor; Rec.Inversor)
            {
                ApplicationArea = All;
                ToolTip = 'Indica si el proveedor es inversor.';
            }
        }
    }
}

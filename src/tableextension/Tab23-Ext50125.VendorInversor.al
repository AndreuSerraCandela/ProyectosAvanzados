/// <summary>
/// TableExtension Vendor (ID 50325) extends Record Vendor.
/// Añade el campo Inversor a la tabla de proveedores.
/// </summary>
tableextension 50325 "Vendor Inversor" extends Vendor
{
    fields
    {
        field(50100; Inversor; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Inversor';
        }
    }
}

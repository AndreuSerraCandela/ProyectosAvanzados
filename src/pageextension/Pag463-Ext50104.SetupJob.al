/// <summary>
/// PageExtension SetupJob (ID 50104) extends Record Jobs Setup //463.
/// </summary>
pageextension 50104 "SetupJob" extends "Jobs Setup" //463
{
    layout
    {
        addlast(General)
        {

            field(DimensionJobProveedor; Rec.DimensionJobProveedor)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Asigna la Dimension del Proveedor cuando hacemos un pedido/factura de compra desde la linea de planificacion field.';
            }
            field("Cód. Proyecto Obligatorio"; Rec."Cód. Proyecto Obligatorio")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Obliga el proyecto en Documentos Pedido/Factura field.';
            }

        }
        addlast(Numbering)
        {
            field("No. serie Ofertas en Proyectos"; Rec."No. serie Ofertas en Proyectos")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the specifica el código de la serie numérica que se va a utilizar para asignar números de ofertas a los proyectos. field.';
            }
        }
    }
}
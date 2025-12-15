/// <summary>
/// PageExtension SetupJob (ID 50104) extends Record Jobs Setup //463.
/// </summary>
pageextension 50304 "SetupJob" extends "Jobs Setup" //463
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
            field("Digitos Capítulo"; Rec."Digitos Capítulo")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Número de dígitos que se van a utilizar para asignar números de capítulos a los proyectos. field.';
            }
            field("Digitos Subcapítulo"; Rec."Digitos Subcapítulo")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Número de dígitos que se van a utilizar para asignar números de subcapítulos a los proyectos. field.';
            }
            field("Prefijo Capítulo"; Rec."Prefijo Capítulo")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Prefijo que se va a utilizar para asignar números de capítulos a los proyectos. field.';
            }
            field("Dimension Proyecto"; Rec."Dimension Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Dimension Proyecto field.';
            }
            field("Dias a Sumar"; Rec."Dias a Sumar")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Dias a Sumar field.';
            }
            field("Multiples Dependencias"; Rec."Multiples Dependencias")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Multiples Dependencias field.', Comment = '%';
            }
            //ItemTemplate
            field("Item Template"; Rec."Item Template")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Item Template field.';
            }

        }
        addlast(Numbering)
        {
            field("No. serie Ofertas en Proyectos"; Rec."No. serie Ofertas en Proyectos")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the specifica el código de la serie numérica que se va a utilizar para asignar números de ofertas a los proyectos. field.';
            }
            field("No.Serie Almacen de Proyecto"; Rec."No.Serie Almacen de Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Serie Almacen en Pryectos field.';
            }
        }
    }
}
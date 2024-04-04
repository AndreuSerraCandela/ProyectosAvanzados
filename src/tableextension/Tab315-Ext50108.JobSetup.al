/// <summary>
/// TableExtension JobSetup (ID 50108) extends Record Jobs Setup //315.
/// </summary>
tableextension 50108 "JobSetup" extends "Jobs Setup" //315
{
    fields
    {
        field(50100; DimensionJobProveedor; Boolean)
        {
            DataClassification = ToBeClassified;
            //si esta activado el campo para realizar los pedidos/facturas de compra desde proyecto debemos hacer que
            //coja la dimension del proveedor, trae la del cliente porque es una linea de planificacion y tiene la del cliente de proyecto.
            Caption = 'Asigna la Dimension del Proveedor cuando hacemos un pedido/factura de compra desde la linea de planificacion';
        }
        field(50101; "Cód. Proyecto Obligatorio"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cód. Proyecto Obligatorios en Documentos Pedido/Factura';
        }
        field(50102; "No. serie Ofertas en Proyectos"; Code[10])
        {
            //DataClassification = ToBeClassified;
            TableRelation = "No. Series";
            //Caption = 'Especifica el código de la serie numérica que se va a utilizar para asignar números de ofertas a los proyectos.';
            //'Especifica el código de la serie numérica que se va a utilizar para asignar números de ofertas a los proyectos.';
            Caption = 'No. Serie Ofertas en Proyectos';
        }
        field(50103; "No.Serie Almacen de Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
            Caption = 'No. Serie Almacen en Pryectos';
        }
        field(50104; "Digitos Capítulo"; Integer)
        {

        }
        field(50105; "Digitos Subcapítulo"; Integer)
        { }
        field(50106; "Prefijo Capítulo"; Code[10])
        { }

    }

    var
        myInt: Integer;
}

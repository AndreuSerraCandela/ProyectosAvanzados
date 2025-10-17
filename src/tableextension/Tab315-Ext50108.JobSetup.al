/// <summary>
/// TableExtension JobSetup (ID 50208) extends Record Jobs Setup //315.
/// </summary>
tableextension 50308 "JobSetup" extends "Jobs Setup" //315
{
    fields
    {
        field(50200; DimensionJobProveedor; Boolean)
        {
            DataClassification = ToBeClassified;
            //si esta activado el campo para realizar los pedidos/facturas de compra desde proyecto debemos hacer que
            //coja la dimension del proveedor, trae la del cliente porque es una linea de planificacion y tiene la del cliente de proyecto.
            Caption = 'Asigna la Dimension del Proveedor cuando hacemos un pedido/factura de compra desde la linea de planificacion';
        }
        field(50201; "Cód. Proyecto Obligatorio"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cód. Proyecto Obligatorios en Documentos Pedido/Factura';
        }
        field(50202; "No. serie Ofertas en Proyectos"; Code[10])
        {
            //DataClassification = ToBeClassified;
            TableRelation = "No. Series";
            //Caption = 'Especifica el código de la serie numérica que se va a utilizar para asignar números de ofertas a los proyectos.';
            //'Especifica el código de la serie numérica que se va a utilizar para asignar números de ofertas a los proyectos.';
            Caption = 'No. Serie Ofertas en Proyectos';
        }
        field(50203; "No.Serie Almacen de Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
            Caption = 'No. Serie Almacen en Pryectos';
        }
        field(50204; "Digitos Capítulo"; Integer)
        {

        }
        field(50205; "Digitos Subcapítulo"; Integer)
        { }
        field(50206; "Prefijo Capítulo"; Code[10])
        { }
        field(50207; "Dimension Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            Caption = 'Dimension Proyecto';
        }
        field(50208; "Dias a Sumar"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Dias a Sumar';
        }
        field(50209; "Multiples Dependencias"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

    }

    //    procedure ProyectoMultiple()
    procedure ProyectoMultiple(): Boolean
    begin
        if rec.Get() then
            exit(rec."Multiples Dependencias");
    end;


    var
        myInt: Integer;
}

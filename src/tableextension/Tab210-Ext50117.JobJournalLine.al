/// <summary>
/// TableExtension JobJournalLineExt (ID 50117) extends Record Job Journal Line (210).
/// Incluye los mismos campos que la extensión de Job Ledger Entry para uso en diario.
/// </summary>
tableextension 50323 "JobJournalLineExt" extends "Job Journal Line" //210
{
    fields
    {
        field(50019; "Employee Entry No."; Integer)
        {
            Caption = 'Nº Movimiento Empleado';
            DataClassification = ToBeClassified;
            TableRelation = "Employee Ledger Entry"."Entry No.";
        }
        field(50020; "Budget Code"; Code[100])
        {
            Caption = 'Código Presupuestario';
            DataClassification = ToBeClassified;
        }
        field(50021; "Neto Factura"; Decimal)
        {
            Caption = 'Neto Factura';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
        }
        field(50022; "IGIC O IVA"; Decimal)
        {
            Caption = 'IGIC O IVA';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
        }
        field(50023; "Importe IGIC O IVA"; Decimal)
        {
            Caption = 'Importe IGIC O IVA';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
        }
        field(50024; "IRPF"; Decimal)
        {
            Caption = 'IRPF';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
        }
        field(50025; "Bruto Factura"; Decimal)
        {
            Caption = 'Bruto Factura';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
        }
        field(50026; "Fecha VTO"; Date)
        {
            Caption = 'Fecha VTO';
            DataClassification = ToBeClassified;
        }
        field(50027; "Estado"; Text[100])
        {
            Caption = 'Estado';
            DataClassification = ToBeClassified;
        }
        field(50028; "NombreProveedor o Empleado"; Text[100])
        {
            Caption = 'Nombre Proveedor o Empleado';
            DataClassification = ToBeClassified;
        }
        field(50029; "Facturado Contra"; Text[100])
        {
            Caption = 'Facturado Contra';
            DataClassification = ToBeClassified;
        }
        field(50030; "FIC"; Text[100])
        {
            Caption = 'FIC';
            DataClassification = ToBeClassified;
        }
        field(50031; "RegistroPresupuestario"; Text[100])
        {
            Caption = 'Registro Presupuestario';
            DataClassification = ToBeClassified;
        }
        field(50032; "Fecha Pago"; Date)
        {
            Caption = 'Fecha Pago';
            DataClassification = ToBeClassified;
        }
        field(50033; "Clasificación Gasto"; Text[100])
        {
            Caption = 'Clasificación Gasto';
            DataClassification = ToBeClassified;
        }
        field(50037; "Document Line No."; Integer)
        {
            Caption = 'Nº Línea Documento';
            DataClassification = ToBeClassified;
        }
        //Producción
        field(50038; "Producción"; Boolean)
        {
            Caption = 'Producción';
            DataClassification = ToBeClassified;
        }
        //Job Line Aux
        field(50039; "Job Planning Line No. Aux"; Integer)
        {
            Caption = 'Nº Línea Planificación Proyecto Auxiliar';
            DataClassification = ToBeClassified;
        }


    }
}

/// <summary>
/// TableExtension JobLedgerEntryExt (ID 50116) extends Record Job Ledger Entry//169.
/// </summary>
tableextension 50322 "JobLedgerEntryExt" extends "Job Ledger Entry" //169
{
    fields
    {
        field(50017; Pendiente; Boolean)
        {
            Caption = 'Pendiente';
            DataClassification = ToBeClassified;
        }
        field(50018; "Amount Paid"; Decimal)
        {
            Caption = 'Importe Pagado';
            FieldClass = FlowField;
            CalcFormula = sum("Proyecto Movimiento Pago"."Amount Paid" where("Document No." = field("Document No."), "Job Task No." = field("Job Task No."), "Job No." = field("Job No.")));
            Editable = false;
            DecimalPlaces = 2 : 2;
        }
        field(50019; "Employee Entry No."; Integer)
        {
            Caption = 'Nº Movimiento Empleado';
            DataClassification = ToBeClassified;
            TableRelation = "Employee Ledger Entry"."Entry No.";
            Editable = false;
        }
        //CÓDIGO PRESUPUESTARIO
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
        //NombreProveedor o Empleado
        field(50028; "NombreProveedor o Empleado"; Text[100])
        {
            Caption = 'Nombre Proveedor o Empleado';
            DataClassification = ToBeClassified;
        }
        //FacturadoContra
        field(50029; "Facturado Contra"; Text[100])
        {
            Caption = 'Facturado Contra';
            DataClassification = ToBeClassified;
        }
        //FIC
        field(50030; "FIC"; Text[100])
        {
            Caption = 'FIC';
            DataClassification = ToBeClassified;
        }
        //RegistroPresupuestario
        field(50031; "RegistroPresupuestario"; Text[100])
        {
            Caption = 'Registro Presupuestario';
            DataClassification = ToBeClassified;
        }
        // field(50028; "Numero Factura"; Code[50])
        // {
        //     Caption = 'Número Factura';
        //     DataClassification = ToBeClassified;
        // }
        // field(50029; "Fecha Factura"; Date)
        // {
        //     Caption = 'Fecha Factura';
        //     DataClassification = ToBeClassified;
        // }
        field(50032; "Fecha Pago"; Date)
        {
            Caption = 'Fecha Pago';
            DataClassification = ToBeClassified;
        }
    }
}

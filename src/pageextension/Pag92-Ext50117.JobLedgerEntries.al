/// <summary>
/// PageExtension JobLedgerEntriesExt (ID 50117) extends Record Job Ledger Entries.
/// </summary>
pageextension 50323 "JobLedgerEntriesExt" extends "Job Ledger Entries"
{
    layout
    {
        addafter("Job Task No.")
        {
            field("Amount Paid"; Rec."Amount Paid")
            {
                ApplicationArea = All;
                Caption = 'Importe Pagado';
                ToolTip = 'Especifica el importe total pagado para esta entrada del mayor de proyectos.';
            }
            field("Employee Entry No."; Rec."Employee Entry No.")
            {
                ApplicationArea = All;
                Caption = 'Nº Movimiento Empleado';
                ToolTip = 'Especifica el número del movimiento de empleado asociado a esta entrada del mayor de proyectos.';
            }
            field("Budget Code"; Rec."Budget Code")
            {
                ApplicationArea = All;
                Caption = 'Código Presupuestario';
                ToolTip = 'Especifica el código presupuestario asociado a esta entrada.';
            }
            field("Estado"; Rec."Estado")
            {
                ApplicationArea = All;
                Caption = 'Estado';
                ToolTip = 'Especifica el estado de esta entrada.';
            }
            field("Fecha Pago"; Rec."Fecha Pago")
            {
                ApplicationArea = All;
                Caption = 'Fecha Pago';
                ToolTip = 'Especifica la fecha de pago de esta entrada.';
            }
            field("Fecha VTO"; Rec."Fecha VTO")
            {
                ApplicationArea = All;
                Caption = 'Fecha VTO';
                ToolTip = 'Especifica la fecha de vencimiento de esta entrada.';
            }
        }
        addafter(Description)
        {

            field("NombreProveedor o Empleado"; Rec."NombreProveedor o Empleado")
            {
                ApplicationArea = All;
                Caption = 'Nombre Proveedor o Empleado';
                ToolTip = 'Especifica el nombre del proveedor o empleado asociado a esta entrada.';
            }
            field("Facturado Contra"; Rec."Facturado Contra")
            {
                ApplicationArea = All;
                Caption = 'Facturado Contra';
                ToolTip = 'Especifica contra quién se facturó esta entrada.';
            }
            field("FIC"; Rec."FIC")
            {
                ApplicationArea = All;
                Caption = 'FIC';
                ToolTip = 'Especifica el código FIC asociado a esta entrada.';
            }
            field("RegistroPresupuestario"; Rec."RegistroPresupuestario")
            {
                ApplicationArea = All;
                Caption = 'Registro Presupuestario';
                ToolTip = 'Especifica el registro presupuestario asociado a esta entrada.';
            }
            field("Neto Factura"; Rec."Neto Factura")
            {
                ApplicationArea = All;
                Caption = 'Neto Factura';
                ToolTip = 'Especifica el importe neto de la factura.';
            }
            field("IGIC O IVA"; Rec."IGIC O IVA")
            {
                ApplicationArea = All;
                Caption = 'IGIC O IVA';
                ToolTip = 'Especifica el porcentaje de IGIC o IVA.';
            }
            field("Importe IGIC O IVA"; Rec."Importe IGIC O IVA")
            {
                ApplicationArea = All;
                Caption = 'Importe IGIC O IVA';
                ToolTip = 'Especifica el importe de IGIC o IVA.';
            }
            field("IRPF"; Rec."IRPF")
            {
                ApplicationArea = All;
                Caption = 'IRPF';
                ToolTip = 'Especifica el importe de IRPF.';
            }
            field("Bruto Factura"; Rec."Bruto Factura")
            {
                ApplicationArea = All;
                Caption = 'Bruto Factura';
                ToolTip = 'Especifica el importe bruto de la factura.';
            }
            field(Pendiente; Rec.Pendiente)
            {
                ApplicationArea = All;
                Caption = 'Pendiente';
                ToolTip = 'Especifica si esta entrada está pendiente.';
            }
        }
    }

    actions
    {
        addafter("Transfer To Planning Lines")
        {
            action("Rellenar Datos Factura")
            {
                ApplicationArea = All;
                Image = Invoice;
                trigger OnAction()
                var
                    Eventosproyectos: Codeunit "Eventos-proyectos";
                begin
                    Eventosproyectos.DatosFactura(Rec);
                end;

            }
        }
    }
}


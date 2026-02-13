/// <summary>
/// PageExtension Sales Invoice List: añade acción para cargar facturas desde Excel.
/// </summary>
pageextension 50328 "Sales Invoice List Carga Excel" extends "Sales Invoice List"
{
    actions
    {
        addfirst(Processing)
        {
            action(CargarFacturasDesdeExcel)
            {
                ApplicationArea = All;
                Caption = 'Cargar facturas desde Excel';
                ToolTip = 'Importa facturas desde un archivo Excel. Columnas: A=Fecha, B=Importe, C=% IVA, D=Importe IVA, E=Total, F=CIF cliente, G=Nombre, H=Texto registro, I=Cuenta contable, J=Nº factura, K=Proyecto';
                Image = ImportExcel;

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit ProcesosProyectos;
                begin
                    ProcesosProyectos.ImportarFacturasDesdeExcel();
                end;
            }
        }
    }
}

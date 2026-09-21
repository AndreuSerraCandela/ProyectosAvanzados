/// <summary>
/// Añade acción para cargar facturas de compra desde plantilla Excel BEPREMIERE.
/// </summary>
pageextension 50349 "Purchase Invoices Carga Excel" extends "Purchase Invoices" //9308
{
    actions
    {
        addfirst(Processing)
        {
            action(CargarFacturasCompraDesdeExcel)
            {
                ApplicationArea = All;
                Caption = 'Cargar facturas desde Excel';
                ToolTip = 'Importa facturas de compra desde la plantilla Excel BEPREMIERE (Proyecto, Tarea, Proveedor, Cuenta/Producto, IVA, IRPF, dims...).';
                Image = ImportExcel;

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit ProcesosProyectos;
                begin
                    ProcesosProyectos.ImportarFacturasCompraDesdeExcel();
                end;
            }
        }
    }
}

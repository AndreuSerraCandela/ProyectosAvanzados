pageextension 50319 JobListExt extends "Job List"
{


    layout
    {

    }

    actions
    {
        addlast("&Job")
        {
            action("Pendiente de facturar")
            {
                ApplicationArea = Jobs;
                trigger OnAction()
                var
                    LineasPlanificacion: Record "Job Planning Line";
                    PagLineasPlanificacion: Page "Pendiente facturar";
                    FiltroFecha: Date;
                begin
                    // LineasPlanificacion.SetFilter(LineasPlanificacion."Planning Date", CalcDate('<CM>', Today), CalcDate('<-CM>', Today));
                    LineasPlanificacion.SetFilter("Line Type", '%1|%2', LineasPlanificacion."Line Type"::Billable, LineasPlanificacion."Line Type"::"Both Budget and Billable");
                    LineasPlanificacion.SetFilter("Qty. to Invoice", '<>%1', 0);
                    // LineasPlanificacion.SetRange("Planning Date", CalcDate('<-CM>', Today), CalcDate('<CM>', Today));
                    if LineasPlanificacion.FindFirst() then;
                    PagLineasPlanificacion.SetTableView(LineasPlanificacion);
                    PagLineasPlanificacion.RunModal();
                end;
            }

            action("Matriz Ventas por Proyecto")
            {
                ApplicationArea = Jobs;
                Caption = 'Matriz Ventas por Proyecto';
                ToolTip = 'Muestra la matriz de ventas por proyecto pendientes de facturación';
                Image = Sales;

                trigger OnAction()
                begin
                    Page.Run(Page::"Matriz Ventas Proyecto");
                end;
            }

        }



        addlast(Category_Process)
        {
            actionref(Pendiente_facturar_promoted; "Pendiente de facturar") { }
            actionref(Matriz_Ventas_Proyecto_promoted; "Matriz Ventas por Proyecto") { }
            //actionref(Pendiente_facturar_Mes_actual; "Pendiente facturar Mes actual") { }
            // actionref(Pendiente_facturar_Mes_anterior; "Pendiente facturar Mes anterior") { }
        }
    }



    // 


}

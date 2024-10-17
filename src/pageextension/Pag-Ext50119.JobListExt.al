pageextension 50119 JobListExt extends "Job List"
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





            // }

        }



        addlast(Category_Process)
        {
            actionref(Pendiente_facturar_promoted; "Pendiente de facturar") { }
            //actionref(Pendiente_facturar_Mes_actual; "Pendiente facturar Mes actual") { }
            // actionref(Pendiente_facturar_Mes_anterior; "Pendiente facturar Mes anterior") { }
        }
    }



    // 

}

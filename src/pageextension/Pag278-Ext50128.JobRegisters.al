/// <summary>
/// PageExtension Job Registers Ext (ID 50128) - Extiende Job Registers (278).
/// Añade acción para actualizar último registro (nueva línea en Job Register).
/// </summary>
pageextension 50329 "Job Registers Ext" extends "Job Registers"
{
    actions
    {
        addfirst(Processing)
        {
            action(ActualizarUltimoRegistro)
            {
                ApplicationArea = Jobs;
                Caption = 'Actualizar último registro';
                Image = UpdateDescription;
                ToolTip = 'Crea una nueva línea en el registro de proyectos con el No. siguiente. From Entry No. = último To Entry No. del registro anterior (si existe). To Entry No. = último movimiento de Job Ledger Entry.';

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit ProcesosProyectos;
                begin
                    ProcesosProyectos.ActualizarUltimoRegistroJob();
                end;
            }
        }
    }
}

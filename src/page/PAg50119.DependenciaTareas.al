page 50119 "Dependencias de Tareas"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Dependecias de Tareas";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Job No."; Rec."Job No.")
                {
                    ToolTip = 'Specifies the value of the Job No. field.', Comment = '%';
                }

                field("Cód. Tarea"; Rec."Cód. Tarea")
                {
                    ToolTip = 'Specifies the value of the MyField field.', Comment = '%';
                }

                field("Tareas Dependiente"; Rec."Tareas Dependiente")
                {
                    ToolTip = 'Specifies the value of the Tareas Dependiente field.', Comment = '%';
                    TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
                    trigger OnValidate()

                    begin
                        JobTask.SetRange("Job No.", Rec."Job No.");
                        JobTask.SetRange("Job Task No.", Rec."Tareas Dependiente");
                        if JobTask.FindFirst() then
                            if JobTask."Tipo Dependencia fecha" = TipoFecha::" " then
                                JobTask."Tipo Dependencia fecha" := TipoFecha::"De fin a inicio";
                        //JobTask.Validate("Retardo", JobTask.Retardo);
                        //CalcularRetardo(JobTask, rec."Cód. Tarea", Rec."Tareas Dependiente");


                    end;
                }
                field("Tipo Dependencia fecha"; Rec."Tipo Dependencia fecha")
                {
                    ToolTip = 'Specifies the value of the Tipo Dependencia fecha field.', Comment = '%';
                }
                field(Retraso; Rec.Retraso)
                {
                    ToolTip = 'Specifies the value of the Retraso field.', Comment = '%';
                }

            }
        }

    }
    var
        JobTask: Record "Job Task";

    trigger OnClosePage()
    begin
        JobTask.SetRange("Job No.", rec."Job No.");
        if JobTask.FindFirst() then
            CalcularFechaTarea(JobTask, rec."Cód. Tarea", Rec."Tareas Dependiente");
    end;




}
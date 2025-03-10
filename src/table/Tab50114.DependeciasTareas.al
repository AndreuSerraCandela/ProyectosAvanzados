table 50114 "Dependecias de Tareas"
{
    DataClassification = ToBeClassified;
    DrillDownPageId = "Dependencias de Tareas";
    LookupPageId = "Dependencias de Tareas";

    fields
    {
        field(1; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Job."No.";
        }
        field(5; "Cód. Tarea"; Code[20])
        {
            Caption = 'Cód Tarea';
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(6; "Tareas Dependiente"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            trigger OnValidate()
            var
                JobTask: Record "Job Task";
            begin
                JobTask.SetRange("Job No.", Rec."Job No.");
                JobTask.SetRange("Job Task No.", Rec."Tareas Dependiente");
                if JobTask.FindFirst() then
                    if JobTask."Tipo Dependencia fecha" = TipoFecha::" " then
                        JobTask."Tipo Dependencia fecha" := TipoFecha::"De fin a inicio";
                //JobTask.Validate("Retardo", JobTask.Retardo);
                CalcularRetardo(JobTask, Rec."Tareas Dependiente");


            end;
        }

    }



    keys
    {
        key(PK; "Job No.", "Cód. Tarea", "Tareas Dependiente")
        {
            Clustered = true;
        }
    }



    procedure CalcularRetardo(var jobTask: Record "Job Task"; tareaDependencia: code[20])
    var
        jobTask2: Record "Job Task";
        jobSetup: Record "Jobs Setup";
    begin
        jobTask2.SetRange("Job No.", jobTask."Job No.");
        jobTask2.SetRange("Job Task No.", tareaDependencia);
        if jobTask2.Get(jobTask."Job No.", jobTask.Dependencia) then begin
            Case jobTask2."Tipo Dependencia fecha" of
                TipoFecha::"De fin a inicio":
                    begin
                        jobTask2."Fecha inicio Tarea" := jobTask."Fecha fin Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
                        jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");

                        jobTask2."Fecha fin Tarea" := jobTask."Fecha inicio tarea" + jobTask."Dias Tarea";
                        jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha fin Tarea");
                    end;
                TipoFecha::"De inicio a inicio":
                    begin
                        jobTask2."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
                        jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
                        jobTask2."Fecha fin Tarea" := jobTask."Fecha inicio Tarea" + jobTask."Dias Tarea";
                        jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha fin Tarea");
                    end;
                TipoFecha::"De fin a fin":
                    begin
                        jobTask2."Fecha fin Tarea" := jobTask."Fecha fin Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
                        jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha Fin Tarea");
                        jobTask2."Fecha inicio Tarea" := jobTask."Fecha fin Tarea" - jobTask."Dias Tarea";
                        jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
                    end;
                TipoFecha::"De inicio a fin":
                    begin
                        jobTask2."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
                        jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
                        jobTask2."Fecha fin Tarea" := jobTask."Fecha inicio Tarea" + jobTask."Dias Tarea";
                        jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
                    end;
            end;
            jobTask2.Modify();
        end;
    end;


}
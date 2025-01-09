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
                if JobTask.FindFirst() then begin
                    if JobTask."Tipo Dependencia fecha" = TipoFecha::" " then
                        JobTask."Tipo Dependencia fecha" := TipoFecha::"De fin a inicio";
                END;
                //JobTask.Validate("Retardo", JobTask.Retardo);
                CalcularRetardo(JobTask, rec."Cód. Tarea", Rec."Tareas Dependiente");


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



    procedure CalcularRetardo(var jobTask: Record "Job Task"; CodTarea: Code[20]; tareaDependencia: code[20])
    var
        jobTask2: Record "Job Task";
        jobSetup: Record "Jobs Setup";
        TareasTemporales: Record "Job Task" temporary;
        TareaDependiente: Record "Dependecias de Tareas";
        FechaTareInicio: Date;
        FechaTareaFin: Date;
    begin
        TareaDependiente.SetRange("Job No.", jobTask."Job No.");
        TareaDependiente.SetRange("Cód. Tarea", CodTarea);
        if TareaDependiente.FindFirst() then begin
            repeat
                TareasTemporales.Validate("Job No.", TareaDependiente."Job No.");
                TareasTemporales.Validate("Job Task No.", TareaDependiente."Tareas Dependiente");
                GetDatosTarea(TareaDependiente."Job No.", TareaDependiente."Tareas Dependiente", jobTask2);
                TareasTemporales := jobTask2;
                //TareasTemporales."Tipo Dependencia fecha" := jobTask2."Tipo Dependencia fecha";
                //tare
                // if not TareasTemporales.FindFirst() then
                TareasTemporales.Insert();
            until TareaDependiente.Next() = 0;

        end;
        TareasTemporales.SetCurrentKey("Fecha inicio Tarea");
        TareasTemporales.SetRange("Job No.", jobTask."Job No.");
        if TareasTemporales.FindFirst() then
            FechaTareInicio := TareasTemporales."Fecha inicio Tarea";


        TareasTemporales.SetCurrentKey("Fecha fin Tarea");
        TareasTemporales.Ascending(false);
        TareasTemporales.SetRange("Job No.", jobTask."Job No.");
        if TareasTemporales.FindFirst() then
            FechaTareaFin := TareasTemporales."Fecha fin Tarea";
        //FechaTareaFin

        // TareasTemporales.SetCurrentKey("Fecha inicio Tarea", "Fecha fin Tarea");
        // TareasTemporales.SetRange("Job No.", jobTask."Job No.");

        // if TareasTemporales.FindFirst() then begin
        //     Case TareasTemporales."Tipo Dependencia fecha" of
        //         TipoFecha::"De fin a inicio":
        //             begin
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask."Fecha fin Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");

        //                 TareasTemporales."Fecha fin Tarea" := jobTask."Fecha inicio tarea" + jobTask."Dias Tarea";
        //                 TareasTemporales."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha fin Tarea");
        //             end;
        //         TipoFecha::"De inicio a inicio":
        //             begin
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
        //                 TareasTemporales."Fecha fin Tarea" := jobTask."Fecha inicio Tarea" + jobTask."Dias Tarea";
        //                 TareasTemporales."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha fin Tarea");
        //             end;
        //         TipoFecha::"De fin a fin":
        //             begin
        //                 TareasTemporales."Fecha fin Tarea" := jobTask."Fecha fin Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
        //                 TareasTemporales."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha Fin Tarea");
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask."Fecha fin Tarea" - jobTask."Dias Tarea";
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
        //             end;
        //         TipoFecha::"De inicio a fin":
        //             begin
        //                 // jobTask2."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
        //                 // jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
        //                 // jobTask2."Fecha fin Tarea" := jobTask."Fecha inicio Tarea" + jobTask."Dias Tarea";
        //                 // jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
        //                 //  TareasTemporales."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
        //                 TareasTemporales."Fecha inicio Tarea" := jobTask.CalculaFestivo(FechaTareInicio);
        //                 //   TareasTemporales."Fecha fin Tarea" := FechaTareInicio + jobTask."Dias Tarea";
        //                 TareasTemporales."Fecha fin Tarea" := jobTask.CalculaFestivo(FechaTareaFin);
        //             end;
        //     end;
        //     TareasTemporales.Modify();
        // end;


        jobTask2.SetRange("Job No.", jobTask."Job No.");
        jobTask2.SetRange("Job Task No.", CodTarea);
        if jobTask2.FindFirst() then begin
            // if jobTask2.Get(jobTask."Job No.", jobTask.Dependencia) then begin
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
                        // jobTask2."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
                        // jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
                        // jobTask2."Fecha fin Tarea" := jobTask."Fecha inicio Tarea" + jobTask."Dias Tarea";
                        // jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(jobTask."Fecha inicio Tarea");
                        jobTask2."Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + jobTask.Retardo + jobSetup."Dias a Sumar";
                        jobTask2."Fecha inicio Tarea" := jobTask.CalculaFestivo(FechaTareInicio);
                        jobTask2."Fecha fin Tarea" := FechaTareInicio + jobTask."Dias Tarea";
                        jobTask2."Fecha fin Tarea" := jobTask.CalculaFestivo(FechaTareaFin);
                    end;
            end;
            jobTask2.Modify();
        end;
    end;

    procedure GetDatosTarea(var jobNo: Code[20]; var Tarea: Code[20]; var pJobTareas: Record "Job Task")
    var

    begin
        pJobTareas.SetRange("Job No.", jobNo);
        pJobTareas.SetRange("Job Task No.", Tarea);
        if pJobTareas.FindFirst() then;


    end;
}
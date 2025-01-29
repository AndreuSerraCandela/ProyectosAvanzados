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
                CalcularFechaTarea(JobTask, rec."Cód. Tarea", Rec."Tareas Dependiente");


            end;
        }

        field(7; "Tipo Dependencia fecha"; Enum TipoFecha)
        {
            DataClassification = ToBeClassified;
            //  TableRelation = "Job Task"."Tipo Dependencia fecha" where("Job No." = field("Job No."), "Job Task No." = field("Tareas Dependiente"));

        }
        field(8; "Retraso"; Integer)
        {
            DataClassification = ToBeClassified;
        }


    }



    keys
    {
        key(PK; "Job No.", "Cód. Tarea", "Tareas Dependiente")
        {
            Clustered = true;
        }
    }



    procedure CalcularFechaTarea(var jobTask: Record "Job Task"; CodTarea: Code[20]; tareaDependencia: code[20])
    var
        ConfSetup: Record "Jobs Setup";
        jobTask2: Record "Job Task";
        jobTask3: Record "Job Task";
        jobSetup: Record "Jobs Setup";
        TareasTemporales: Record "Job Task" temporary;
        TareaDependiente: Record "Dependecias de Tareas";
        FechaTareInicio: Date;
        FechaTareaFin: Date;
        FechaTarea: Date;
        cliente: Record Customer;
        pTipoFecha: Enum TipoFecha;
        pTipoInicio: Enum TipoFecha;
        pTipoFin: Enum TipoFecha;
    begin
        ConfSetup.Get();

        TareaDependiente.SetCurrentKey("Tipo Dependencia fecha");
        TareaDependiente.Ascending;
        TareaDependiente.SetRange("Job No.", jobTask."Job No.");
        TareaDependiente.SetRange("Cód. Tarea", CodTarea);
        if TareaDependiente.FindFirst() then begin
            repeat
                Case TareaDependiente."Tipo Dependencia fecha" of
                    TipoFecha::"De fin a inicio":
                        begin
                            //(var jobNo: Code[20]; var Tarea: Code[20]; var pJobTareas: Record "Job Task")
                            GetDatosTarea(jobTask."Job No.", TareaDependiente."Tareas Dependiente", jobTask2);
                            if FechaTareaFin = 0D then
                                FechaTareaFin := jobTask2.CalculaFestivo(jobTask2."Fecha fin Tarea");
                            IF FechaTareaFin < jobTask2."Fecha fin Tarea" then
                                FechaTareaFin := jobTask2.CalculaFestivo(jobTask2."Fecha fin Tarea");

                            //FechaTareaFin := FechaTareaFin + 1 + TareaDependiente.Retraso;
                            FechaTareaFin := FechaTareaFin + TareaDependiente.Retraso;
                            FechaTareaFin := jobTask2.CalculaFestivo(FechaTareaFin);
                            pTipoFecha := TareaDependiente."Tipo Dependencia fecha";
                            pTipoInicio := TareaDependiente."Tipo Dependencia fecha";
                        end;
                    TipoFecha::"De inicio a inicio":
                        begin
                            GetDatosTarea(jobTask."Job No.", TareaDependiente."Tareas Dependiente", jobTask2);
                            if FechaTareInicio = 0D then
                                FechaTareInicio := jobTask2.CalculaFestivo(jobTask2."Fecha inicio Tarea");
                            IF FechaTareInicio < jobTask2."Fecha inicio Tarea" then
                                FechaTareInicio := jobTask2.CalculaFestivo(jobTask2."Fecha inicio Tarea");

                            // FechaTareInicio := FechaTareInicio + 1 + TareaDependiente.Retraso;
                            FechaTareInicio := FechaTareInicio + TareaDependiente.Retraso;
                            FechaTareInicio := jobTask2.CalculaFestivo(FechaTareInicio);
                            pTipoFecha := TareaDependiente."Tipo Dependencia fecha";
                            pTipoInicio := TareaDependiente."Tipo Dependencia fecha";
                        end;

                    TipoFecha::"De fin a fin":
                        begin
                            //(var jobNo: Code[20]; var Tarea: Code[20]; var pJobTareas: Record "Job Task")
                            GetDatosTarea(jobTask."Job No.", TareaDependiente."Tareas Dependiente", jobTask2);
                            if FechaTareaFin = 0D then
                                FechaTareaFin := jobTask2.CalculaFestivo(jobTask2."Fecha fin Tarea");
                            IF FechaTareaFin < jobTask2."Fecha fin Tarea" then
                                FechaTareaFin := jobTask2.CalculaFestivo(jobTask2."Fecha fin Tarea");

                            //FechaTareaFin := FechaTareaFin + 1 + TareaDependiente.Retraso;
                            FechaTareaFin := FechaTareaFin + TareaDependiente.Retraso;
                            FechaTareaFin := jobTask2.CalculaFestivo(FechaTareaFin);
                            pTipoFecha := TareaDependiente."Tipo Dependencia fecha";
                            pTipoFin := TareaDependiente."Tipo Dependencia fecha";
                        end;
                    TipoFecha::"De inicio a fin":
                        begin
                            GetDatosTarea(jobTask."Job No.", TareaDependiente."Tareas Dependiente", jobTask2);
                            if FechaTareInicio = 0D then
                                FechaTareInicio := jobTask2.CalculaFestivo(jobTask2."Fecha inicio Tarea");
                            IF FechaTareInicio < jobTask2."Fecha inicio Tarea" then
                                FechaTareInicio := jobTask2.CalculaFestivo(jobTask2."Fecha inicio Tarea");

                            //FechaTareInicio := FechaTareInicio + 1 + TareaDependiente.Retraso;
                            FechaTareInicio := FechaTareInicio + TareaDependiente.Retraso;
                            FechaTareInicio := jobTask2.CalculaFestivo(FechaTareInicio);
                            pTipoFecha := TareaDependiente."Tipo Dependencia fecha";
                            pTipoFin := TareaDependiente."Tipo Dependencia fecha";
                        end;

                end;
                if FechaTareaFin < FechaTareInicio then begin
                    FechaTarea := FechaTareInicio;
                    if not (pTipoInicio = pTipoInicio::" ") then
                        pTipoFecha := pTipoInicio;
                end else begin
                    FechaTarea := FechaTareaFin;
                    if not (pTipoFin = pTipoFin::" ") then
                        pTipoFecha := pTipoFin;
                end;
            until TareaDependiente.Next() = 0;



            jobTask3.SetRange("Job No.", jobTask."Job No.");
            jobTask3.SetRange("Job Task No.", CodTarea);
            IF jobTask3.FindFirst() then begin
                case pTipoFecha of
                    pTipoFecha::"De inicio a fin":
                        begin
                            FechaTarea := jobTask3.CalculaFestivo(FechaTarea);
                            jobTask3.Validate(jobTask3."Fecha fin Tarea", FechaTarea);
                            jobTask3.Validate("Fecha inicio Tarea", 0D);
                            jobTask3.Validate("Dias Tarea", 0);
                            IF jobTask3."Fecha inicio Tarea" = 0D then
                                jobTask3.Validate("Fecha inicio Tarea", FechaTarea);

                            if jobTask3."Dias Tarea" <> 0 then begin
                                jobTask3."Fecha inicio Tarea" := jobTask3."Fecha inicio Tarea" - jobTask3."Dias Tarea";
                                // jobTask3.Validate(jobTask3."Fecha inicio Tarea");
                                // end else begin
                                //     jobTask3."Fecha inicio Tarea" := jobTask3."Fecha inicio Tarea" - ConfSetup."Dias a Sumar";
                            end;
                        end;
                    pTipoFecha::"De fin a fin":
                        begin
                            FechaTarea := jobTask3.CalculaFestivo(FechaTarea);
                            jobTask3.Validate(jobTask3."Fecha fin Tarea", FechaTarea);
                            jobTask3.Validate("Fecha inicio Tarea", 0D);
                            jobTask3.Validate("Dias Tarea", 0);
                            IF jobTask3."Fecha inicio Tarea" = 0D then
                                jobTask3.Validate("Fecha inicio Tarea", FechaTarea);

                            if jobTask3."Dias Tarea" <> 0 then begin
                                jobTask3."Fecha inicio Tarea" := jobTask3."Fecha inicio Tarea" - jobTask3."Dias Tarea";
                                //jobTask3.Validate(jobTask3."Fecha inicio Tarea");
                                // end else begin
                                //     jobTask3."Fecha inicio Tarea" := jobTask3."Fecha inicio Tarea" - ConfSetup."Dias a Sumar";
                            end;

                        end;
                    pTipoFecha::"De fin a inicio":
                        begin
                            FechaTarea := FechaTarea + 1;
                            FechaTarea := jobTask3.CalculaFestivo(FechaTarea);
                            jobTask3.Validate(jobTask3."Fecha inicio Tarea", FechaTarea);
                            jobTask3.Validate(jobTask3."Fecha fin Tarea", 0D);
                            jobTask3.Validate("Dias Tarea", 0);

                            if jobTask3."Fecha fin Tarea" = 0D then
                                jobTask3.Validate(jobTask3."Fecha fin Tarea", jobTask3."Fecha inicio Tarea");

                            if jobTask3."Dias Tarea" <> 0 then begin
                                jobTask3."Fecha fin Tarea" := jobTask3."Fecha fin Tarea" + jobTask3."Dias Tarea";
                                jobTask3.Validate(jobTask3."Fecha fin Tarea");
                                // end else begin
                                //     jobTask3."Fecha fin Tarea" := jobTask3."Fecha fin Tarea" + ConfSetup."Dias a Sumar";
                            end;
                        end;
                    pTipoFecha::"De inicio a inicio":
                        begin
                            FechaTarea := FechaTarea + 1;
                            FechaTarea := jobTask3.CalculaFestivo(FechaTarea);
                            jobTask3.Validate(jobTask3."Fecha inicio Tarea", FechaTarea);
                            jobTask3.Validate(jobTask3."Fecha fin Tarea", 0D);
                            jobTask3.Validate("Dias Tarea", 0);

                            if jobTask3."Fecha fin Tarea" = 0D then
                                jobTask3.Validate(jobTask3."Fecha fin Tarea", jobTask3."Fecha inicio Tarea");

                            if jobTask3."Dias Tarea" <> 0 then begin
                                jobTask3."Fecha fin Tarea" := jobTask3."Fecha fin Tarea" + jobTask3."Dias Tarea";
                                //  jobTask3.Validate(jobTask3."Fecha fin Tarea");
                                // end else begin
                                //     jobTask3."Fecha fin Tarea" := jobTask3."Fecha fin Tarea" + ConfSetup."Dias a Sumar";
                            end;
                        end;
                end;
                jobTask3."Tipo Dependencia fecha" := pTipoFecha;
                jobTask3.Modify();
            END;

        end ELSE begin
            jobTask2.SetRange("Job No.", "Job No.");
            jobTask2.SetRange("Job Task No.", CodTarea);
            IF jobTask2.FindFirst() then begin
                jobTask2."Fecha inicio Tarea" := 0D;
                jobTask2."Fecha fin Tarea" := 0D;
                jobTask2."Dias Tarea" := 0;
                jobTask2."Tipo Dependencia fecha" := jobTask2."Tipo Dependencia fecha"::" ";
                jobTask2.Modify(false);
            end;

        end;
        // TareasTemporales.SetCurrentKey("Fecha inicio Tarea");
        // TareasTemporales.SetRange("Job No.", jobTask."Job No.");
        // if TareasTemporales.FindFirst() then
        //     FechaTareInicio := TareasTemporales."Fecha inicio Tarea";


        // TareasTemporales.SetCurrentKey("Fecha fin Tarea");
        // TareasTemporales.Ascending(false);
        // TareasTemporales.SetRange("Job No.", jobTask."Job No.");
        // if TareasTemporales.FindFirst() then
        //     FechaTareaFin := TareasTemporales."Fecha fin Tarea";
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

        /*
                jobTask2.SetRange("Job No.", jobTask."Job No.");
                jobTask2.SetRange("Job Task No.", CodTarea);
                if jobTask2.FindFirst() then begin
                    FechaTareInicio := jobTask2."Fecha inicio Tarea";
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
                */
    end;

    procedure GetDatosTarea(var jobNo: Code[20]; var Tarea: Code[20]; var pJobTareas: Record "Job Task")
    var
        PECOMO: Record "Purchase Header";
        PAG: Page "Blanket Purchase Order";
    begin
        pJobTareas.SetRange("Job No.", jobNo);
        pJobTareas.SetRange("Job Task No.", Tarea);
        if pJobTareas.FindFirst() then;


    end;
}
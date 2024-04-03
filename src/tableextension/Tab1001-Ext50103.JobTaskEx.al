tableextension 50103 "JobTaskEx" extends "Job Task" //1001
{
    fields
    {

        field(50000; "Status Task"; Enum "Status Task")
        {
            DataClassification = ToBeClassified;
            Caption = 'Estado Tarea';
            // ValuesAllowed = ' ', "Completado";

        }
        field(50001; Dependencia; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Dependencia';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

        }
        field(50010; "Tipo Dependencia fecha"; Enum TipoFecha)
        {

        }
        field(50011; "Retardo"; Integer)
        {
            DataClassification = ToBeClassified;
            // De fin a inicio: la tarea B no puede empezar antes de que finalice la tarea A
            // Este tipo de dependencia se produce cuando la tarea inicial debe completarse para que pueda comenzar la siguiente. 
            // Si la tarea A se completa con retraso, entonces la tarea B también comenzará con retraso modificando su fecha.

            // De inicio a inicio: la tarea B no puede empezar antes de que empiece la tarea A.
            // Una dependencia de inicio a inicio se produce cuando una tarea secundaria no puede empezar hasta que comience la tarea inicial. No es necesario que las dos tareas empiecen al mismo tiempo; la tarea B puede comenzar después de la tarea A, siempre que la tarea A haya comenzado.

            // De fin a fin: la tarea B no puede terminar antes de que finalice la tarea A
            // Una dependencia de fin a fin significa que la tarea inicial debe completarse para que se pueda completar la siguiente. La tarea A y la tarea B están directamente relacionadas y, por tanto, pueden realizarse al mismo tiempo, aunque la tarea B depende de la tarea A.

            // De inicio a fin: la tarea A no puede terminar antes de que empiece la tarea B
            // En una dependencia de inicio a fin, la tarea inicial no se puede finalizar hasta que haya comenzado la tarea secundaria. Sin embargo, la tarea B no tiene que terminar al mismo tiempo que comienza la tarea A.
            trigger OnValidate()
            var
                jobTask: Record "Job Task";
            begin
                if jobTask.Get(Rec."Job No.", Rec.Dependencia) then begin
                    Case Rec."Tipo Dependencia fecha" of
                        TipoFecha::"De fin a inicio":
                            begin
                                "Fecha inicio Tarea" := jobTask."Fecha fin Tarea" + Retardo;
                                "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");

                                "Fecha fin Tarea" := "Fecha inicio tarea" + "Dias Tarea";
                                "Fecha fin Tarea" := CalculaFestivo("Fecha fin Tarea");
                            end;
                        TipoFecha::"De inicio a inicio":
                            begin
                                "Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + Retardo;
                                "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                "Fecha fin Tarea" := "Fecha inicio Tarea" + "Dias Tarea";
                                "Fecha fin Tarea" := CalculaFestivo("Fecha fin Tarea");
                            end;
                        TipoFecha::"De fin a fin":
                            begin
                                "Fecha fin Tarea" := jobTask."Fecha fin Tarea" + Retardo;
                                "Fecha fin Tarea" := CalculaFestivo("Fecha Fin Tarea");
                                "Fecha inicio Tarea" := "Fecha fin Tarea" - "Dias Tarea";
                                "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                            end;
                        TipoFecha::"De inicio a fin":
                            begin
                                "Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + Retardo;
                                "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                "Fecha fin Tarea" := "Fecha inicio Tarea" + "Dias Tarea";
                                "Fecha fin Tarea" := CalculaFestivo("Fecha inicio Tarea");
                            end;
                    end;
                end;

                //Modify();
            end;

        }
        field(50002; "Fecha inicio Tarea"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                If ("Fecha inicio Tarea" <> 0D) and (("Fecha fin Tarea" <> 0D) or ("Dias Tarea" <> 0)) then begin
                    "Fecha fin Tarea" := "Fecha inicio Tarea" + "Dias Tarea";
                    "Fecha fin Tarea" := CalculaFestivo("Fecha Fin Tarea");
                    CalculaFechas();
                end;
            end;
        }
        field(50003; "Fecha fin Tarea."; Blob)
        {
            DataClassification = ToBeClassified;

        }
        field(50005; "Fecha fin Tarea"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                If ("Fecha inicio Tarea" <> 0D) and (("Fecha fin Tarea" <> 0D) or ("Dias Tarea" <> 0)) then
                    if "Fecha fin Tarea" = 0D then "Fecha fin Tarea" := "Fecha inicio Tarea";
                if "Fecha inicio Tarea" = 0D then "Fecha inicio Tarea" := "Fecha fin Tarea";
                "Dias Tarea" := "Fecha fin Tarea" - "Fecha inicio Tarea";
                CalculaFechas();

            end;
        }

        field(50004; "WIP %"; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                MensajeLbl: Label '¿Desea cambiar el estado de la tarea a completada?';
            begin
                if "WIP %" = 100 then
                    if Confirm(MensajeLbl, true) then
                        Rec.Validate("Status Task", "Status Task"::Completada);
            end;
        }
        field(50102; "Versión Base"; Integer)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50006; "Venta Inicial"; Decimal)
        {
            //DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Price (LCY)" where("Job No." = field("Job No."),
                                                                                         "Job Task No." = field("Job Task No."), "Version No." = field("Versión Base")));
            AutoFormatType = 1;
            BlankZero = true;
            Editable = false;
        }
        field(50007; "Coste Inicial"; Decimal)
        {
            //  DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Cost (LCY)" where("Job No." = field("Job No."),
            "Job Task No." = field("Job Task No."), "Version No." = field("Versión Base")));
            AutoFormatType = 1;
            BlankZero = true;
            Editable = false;
        }
        field(50008; "Dias Tarea"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                If ("Fecha inicio Tarea" <> 0D) and (("Fecha fin Tarea" <> 0D) or ("Dias Tarea" <> 0)) then
                    if "Fecha inicio Tarea" = 0D then "Fecha inicio Tarea" := "Fecha fin Tarea";
                "Fecha fin Tarea" := "Fecha inicio Tarea" + "Dias Tarea";
                Modify();
                CalculaFechas();
                ;
            end;
        }

    }


    procedure CalculaFechas()
    var
        JobTaskNiv: Record "Job Task";

    begin
        Modify();
        Commit;
        JobTaskNiv.SetRange("Job No.", Rec."Job No.");
        JobTaskNiv.SetRange(Dependencia, Rec."Job Task No.");
        if JobTaskNiv.FindSet() then
            repeat

                JobTaskNiv.validate(Retardo, JobTaskNiv.Retardo);
                JobTaskNiv.Modify();
                Commit;
                JobTaskNiv.CalculaFechas();
            until JobTaskNiv.Next() = 0;
    end;


    local procedure CalculaFestivo(FechainicioTarea: Date): date
    var
        Festivo: Record "Base Calendar Change";
        Dia: Integer;
    begin
        Dia := Date2DWY(FechainicioTarea, 1);
        If Dia = 6 then
            FechainicioTarea := FechainicioTarea + 2;
        if Dia = 7 then
            FechainicioTarea := FechainicioTarea + 1;
        Festivo.SetRange(Nonworking, true);
        if not Festivo.Find() then exit(FechainicioTarea);
        Festivo.SetRange("Date", FechainicioTarea);
        Festivo.SetRange(nonworking, true);
        if Festivo.Find() then
            repeat
                FechainicioTarea := FechainicioTarea + 1;
                if Date2DWY(FechainicioTarea, 1) = 6 then
                    FechainicioTarea := FechainicioTarea + 2;
                Festivo.SetRange("Date", FechainicioTarea);
            until not Festivo.Find();
        exit(FechainicioTarea);
    end;



}
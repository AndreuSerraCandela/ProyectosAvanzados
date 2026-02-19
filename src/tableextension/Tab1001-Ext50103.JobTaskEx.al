tableextension 50303 "JobTaskEx" extends "Job Task" //1001
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
            trigger OnValidate()
            begin
                if "Tipo Dependencia fecha" = TipoFecha::" " then
                    "Tipo Dependencia fecha" := TipoFecha::"De fin a inicio";
                Validate("Retardo", Rec.Retardo);
            end;

        }
        field(50010; "Tipo Dependencia fecha"; Enum TipoFecha)
        {
            trigger OnValidate()
            begin
                Validate("Retardo", Rec.Retardo);
            end;

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
                jobSetup: Record "Jobs Setup";
            begin
                jobSetup.Get();
                if not jobSetup."Multiples Dependencias" then begin
                    if jobTask.Get(Rec."Job No.", Rec.Dependencia) then begin
                        Case Rec."Tipo Dependencia fecha" of
                            TipoFecha::"De fin a inicio":
                                begin
                                    "Fecha inicio Tarea" := jobTask."Fecha fin Tarea" + Retardo + jobSetup."Dias a Sumar";
                                    //"Fecha inicio Tarea" := SumarDias_SinContarFestivos(jobTask."Fecha fin Tarea", Retardo + jobSetup."Dias a Sumar");
                                    //SumarDias_SinContarFestivos
                                    "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");

                                    // "Fecha fin Tarea" := "Fecha inicio tarea" + "Dias Tarea";
                                    "Fecha fin Tarea" := SumarDias_SinContarFestivos("Fecha inicio tarea", "Dias Tarea");
                                    "Fecha fin Tarea" := CalculaFestivo("Fecha fin Tarea");
                                end;
                            TipoFecha::"De inicio a inicio":
                                begin
                                    "Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + Retardo + jobSetup."Dias a Sumar";
                                    "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                    "Fecha fin Tarea" := SumarDias_SinContarFestivos("Fecha inicio Tarea", "Dias Tarea");
                                    "Fecha fin Tarea" := CalculaFestivo("Fecha fin Tarea");
                                end;
                            TipoFecha::"De fin a fin":
                                begin
                                    "Fecha fin Tarea" := jobTask."Fecha fin Tarea" + Retardo + jobSetup."Dias a Sumar";
                                    "Fecha fin Tarea" := CalculaFestivo("Fecha Fin Tarea");
                                    "Fecha inicio Tarea" := "Fecha fin Tarea" - "Dias Tarea";
                                    "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                end;
                            TipoFecha::"De inicio a fin":
                                begin
                                    "Fecha inicio Tarea" := jobTask."Fecha inicio Tarea" + Retardo + jobSetup."Dias a Sumar";
                                    "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                    "Fecha fin Tarea" := SumarDias_SinContarFestivos("Fecha inicio Tarea", "Dias Tarea");
                                    "Fecha fin Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                end;
                        end;
                    end;
                end else begin
                    if jobTask.Get(Rec."Job No.", Rec."Job Task No.") then begin
                        Case Rec."Tipo Dependencia fecha" of
                            TipoFecha::"De fin a inicio":
                                begin
                                    "Fecha inicio Tarea" := SumarDias_SinContarFestivos(jobTask."Fecha fin Tarea", Retardo + jobSetup."Dias a Sumar");
                                    "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                    // "Fecha fin Tarea" := "Fecha inicio tarea" + "Dias Tarea";
                                    "Fecha fin Tarea" := SumarDias_SinContarFestivos("Fecha inicio tarea", "Dias Tarea");
                                    "Fecha fin Tarea" := CalculaFestivo("Fecha fin Tarea");
                                end;
                            TipoFecha::"De inicio a inicio":
                                begin
                                    "Fecha inicio Tarea" := SumarDias_SinContarFestivos(jobTask."Fecha fin Tarea", Retardo + jobSetup."Dias a Sumar");
                                    "Fecha inicio Tarea" := CalculaFestivo("Fecha inicio Tarea");
                                    // "Fecha fin Tarea" := "Fecha inicio tarea" + "Dias Tarea";
                                    "Fecha fin Tarea" := SumarDias_SinContarFestivos("Fecha inicio tarea", "Dias Tarea");
                                    "Fecha fin Tarea" := CalculaFestivo("Fecha fin Tarea");
                                end;

                            TipoFecha::" ":
                                begin
                                    if rec."Fecha fin Tarea" <> 0D then
                                        "Fecha fin Tarea" := SumarDias_SinContarFestivos("Fecha inicio tarea", Rec.Retardo);
                                end;
                        end;
                    end;

                    //Modify();
                end;
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
                if "Fecha inicio Tarea" = 0D then
                    "Fecha inicio Tarea" := "Fecha fin Tarea";

                IF (REC."Fecha fin Tarea" <> xRec."Fecha fin Tarea") OR
                   (REC."Fecha inicio Tarea" <> XREC."Fecha inicio Tarea") then begin
                    "Dias Tarea" := 0;
                    if rec."Fecha fin Tarea" <> 0D then
                        rec."Dias Tarea" := "Fecha fin Tarea" - "Fecha inicio Tarea";
                END;
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
        field(50103; "Versión Final"; Integer)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50006; "Venta Inicial"; Decimal)
        {
            //DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Price (LCY)" where("Job No." = field("Job No."),
                                                                                         "Job Task No." = field("Job Task No."),
                                                                                         "Job Task No." = field(filter(Totaling)),
                                                                                         "Version No." = field("Versión Base")));
            AutoFormatType = 1;
            BlankZero = true;
            Editable = false;
        }
        field(50007; "Coste Inicial"; Decimal)
        {
            //  DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                                 "Job Task No." = field("Job Task No."),
                                                                                 "Job Task No." = field(filter(Totaling)),
                                                                                 "Version No." = field("Versión Base")));
            AutoFormatType = 1;
            BlankZero = true;
            Editable = false;
        }
        field(50107; "Coste Forecast"; Decimal)
        {
            //  DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                                 "Job Task No." = field("Job Task No."),
                                                                                 "Job Task No." = field(filter(Totaling))
                                                                                 , "Version No." = field("Versión Final")));
            AutoFormatType = 1;
            BlankZero = true;
            Editable = false;
        }
        field(50008; "Dias Tarea"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                rec.CalcFields(Dependencia2);
                // if Rec.Dependencia2 = 0 then begin
                If (Rec."Fecha inicio Tarea" <> 0D) and ((Rec."Fecha fin Tarea" <> 0D) or (Rec."Dias Tarea" <> 0)) then
                    if Rec."Fecha inicio Tarea" = 0D then Rec."Fecha inicio Tarea" := Rec."Fecha fin Tarea";

                if (rec."Tipo Dependencia fecha" = rec."Tipo Dependencia fecha"::"De fin a fin") or
                  (rec."Tipo Dependencia fecha" = "Tipo Dependencia fecha"::"De inicio a fin") then begin
                    IF Rec."Dias Tarea" <> 0 then
                        rec."Fecha inicio Tarea" := RestarDias_SinContarFestivos(Rec."Fecha fin Tarea", Rec."Dias Tarea");
                end else begin
                    IF Rec."Dias Tarea" <> 0 then
                        Rec."Fecha fin Tarea" := SumarDias_SinContarFestivos(Rec."Fecha inicio Tarea", Rec."Dias Tarea"); // + "Dias Tarea";
                                                                                                                          //  end else begin
                end;

                //   end;

                Modify();
                CalculaFechas();
                // if ConfProyecto.ProyectoMultiple() then
                //     RecalcularTarea();
            end;
        }
        field(50009; "Tipo Partida"; Enum "Tipo Partida")
        {
            DataClassification = ToBeClassified;
            Caption = 'Tipo Partida';
            // ValuesAllowed = ' ', "Completado";

        }
        field(50015; Dependencia2; Integer)
        {
            // DataClassification = ToBeClassified;
            Caption = 'Dependencia', comment = 'ESP="Dependencia"';
            FieldClass = FlowField;
            CalcFormula = count("Dependecias de Tareas" where("Job No." = field("Job No."), "Cód. Tarea" = field("Job Task No.")));

        }
        field(50016; "IMprte Pagado"; Decimal)
        {
            Caption = 'Importe Pagado';
            ObsoleteState = Removed;

        }
        field(50017; Pendiente; Boolean)
        { }
        field(50018; "Amount Paid"; Decimal)
        {
            Caption = 'Importe Pagado';
            FieldClass = FlowField;
            //CalcFormula = sum("Proyecto Movimiento Pago"."Amount Paid" where("Job Task No." = field("Job Task No."), "Job No." = field("Job No.")));
            CalcFormula = sum("Proyecto Movimiento Pago"."Amount Paid" where("Job No." = field("Job No."),
                                                                                      "Job Task No." = field("Job Task No."),
                                                                                      "Job Task No." = field(filter(Totaling))));
            Editable = false;
            DecimalPlaces = 2 : 2;
        }
        field(50019; "Tota Cost"; Decimal)
        {
            Caption = 'Total Cost';
            FieldClass = FlowField;
            CalcFormula = sum("Job Ledger Entry"."Total Cost (LCY)" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."),
                                                                            "Job Task No." = field(filter(Totaling))));
            Editable = false;
            DecimalPlaces = 2 : 2;
        }
        //Campo Calculado Bruto Factura
        field(50021; "Bruto Factura"; Decimal)
        {
            Caption = 'Bruto Factura';
            FieldClass = FlowField;
            CalcFormula = sum("Job Ledger Entry"."Bruto Factura" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."),
                                                                            "Job Task No." = field(filter(Totaling))));
            Editable = false;
            DecimalPlaces = 2 : 2;
        }
        field(50020; "Importe Comprometido"; Decimal)
        {
            Caption = 'Importe Comprometido';
            FieldClass = FlowField;
            CalcFormula = sum("Purchase Line"."Outstanding Amount" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."),
            "Job Task No." = field(filter(Totaling))));
            Editable = false;
            DecimalPlaces = 2 : 2;
        }
        field(50022; "Base Amount Paid"; Decimal)
        {
            Caption = 'Importe Base Pagado';
            FieldClass = FlowField;
            CalcFormula = sum("Proyecto Movimiento Pago"."Base Amount Paid" where("Job No." = field("Job No."),
                                                                                      "Job Task No." = field("Job Task No."),
                                                                                      "Job Task No." = field(filter(Totaling))));
            Editable = false;
            DecimalPlaces = 2 : 2;
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


    procedure CalculaFestivo(FechainicioTarea: Date): date
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



    procedure SumarDias_SinContarFestivos(FechainicioTarea: Date; diasAsumar: integer): date
    var
        Festivo: Record "Base Calendar Change";
        Dia: Integer;
        DiaAContador: Integer;
    begin
        Clear(DiaAContador);
        if (diasAsumar = 0) or (diasAsumar = 1) then
            exit(FechainicioTarea);
        DiaAContador := 1;
        repeat
            DiaAContador := DiaAContador + 1;
            FechainicioTarea := FechainicioTarea + 1;
            FechainicioTarea := CalculaFestivo(FechainicioTarea);
            Dia := Date2DWY(FechainicioTarea, 1);
            If Dia = 6 then
                FechainicioTarea := FechainicioTarea + 2;
            if Dia = 7 then
                FechainicioTarea := FechainicioTarea + 1;

        until DiaAContador >= diasAsumar;

        exit(FechainicioTarea);
    end;

    procedure RestarDias_SinContarFestivos(FechaTarea: Date; diasAsumar: integer): date
    var
        Festivo: Record "Base Calendar Change";
        Dia: Integer;
        DiaA: Integer;
    begin
        DiaA := 1;
        repeat
            DiaA := DiaA + 1;
            FechaTarea := FechaTarea - 1;
            FechaTarea := CalculaFestivo_Dis(FechaTarea);
            Dia := Date2DWY(FechaTarea, 1);
            If Dia = 6 then
                FechaTarea := FechaTarea - 2;
            if Dia = 7 then
                FechaTarea := FechaTarea - 1;

        until DiaA = diasAsumar;

        exit(FechaTarea);
    end;

    procedure CalculaFestivo_Dis(FechainicioTarea: Date): date
    var
        Festivo: Record "Base Calendar Change";
        Dia: Integer;
    begin
        Dia := Date2DWY(FechainicioTarea, 1);
        If Dia = 6 then
            //FechainicioTarea := FechainicioTarea + 2;
            FechainicioTarea := FechainicioTarea - 1;
        if Dia = 7 then
            //FechainicioTarea := FechainicioTarea + 1;
            FechainicioTarea := FechainicioTarea - 2;
        Festivo.SetRange(Nonworking, true);
        if not Festivo.Find() then exit(FechainicioTarea);
        Festivo.SetRange("Date", FechainicioTarea);
        Festivo.SetRange(nonworking, true);
        if Festivo.Find() then
            repeat
                FechainicioTarea := FechainicioTarea - 1;
                if Date2DWY(FechainicioTarea, 1) = 6 then
                    FechainicioTarea := FechainicioTarea - 1;
                Festivo.SetRange("Date", FechainicioTarea);
            until not Festivo.Find();
        exit(FechainicioTarea);
    end;


    procedure RecalcularTarea()
    var
        Tareas: Record "Job Task";
        DependenciaTareas: Record "Dependecias de Tareas";
        TareaAfectada: Code[20];
    begin
        Tareas.SetRange("Job No.", Rec."Job No.");
        Tareas.SetRange("Job Task No.", Rec."Job Task No.");
        if Tareas.FindFirst() then;
        DependenciaTareas.SetRange("Job No.", Rec."Job No.");
        DependenciaTareas.SetRange("Tareas Dependiente", rec."Job Task No.");
        if DependenciaTareas.FindFirst() then begin
            TareaAfectada := DependenciaTareas."Cód. Tarea";
            DependenciaTareas.CalcularFechaTarea(Tareas, TareaAfectada, rec."Job Task No.");
        end;

    end;


    var
        ConfProyecto: Record "Jobs Setup";

}
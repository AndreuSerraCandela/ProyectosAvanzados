tableextension 50103 "JobTaskEx" extends "Job Task" //1001
{
    fields
    {

        field(50000; "Status Task"; Enum "Status Task")
        {
            DataClassification = ToBeClassified;
            Caption = 'Tipo Tarea';
            // ValuesAllowed = ' ', "Completado";

        }
        field(50001; Dependencia; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Dependencia';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

        }
        field(50002; "Fecha inicio Tarea"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                If ("Fecha inicio Tarea" <> 0D) and (("Fecha fin Tarea" <> 0D) or ("Dias Tarea" <> 0)) then
                    CalculaFechas(1, false, "Fecha inicio Tarea", "Fecha fin Tarea", "Dias Tarea");
                Modify();
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
                    CalculaFechas(1, false, "Fecha inicio Tarea", "Fecha fin Tarea", "Dias Tarea");
                Modify();
            end;
        }

        field(50004; "WIP %"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50006; "Venta Inicial"; Decimal)
        {
            //DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Price (LCY)" where("Job No." = field("Job No."),
                                                                                         "Job Task No." = field("Job Task No."), "Version No." = const(1)));
            AutoFormatType = 1;
            BlankZero = true;
            Editable = false;
        }
        field(50007; "Coste Inicial"; Decimal)
        {
            //  DataClassification = ToBeClassified;
            FieldClass = FlowField;
            CalcFormula = sum("Hist. Job Planning Line"."Total Cost (LCY)" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Version No." = const(1)));
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
                    CalculaFechas(1, false, "Fecha inicio Tarea", "Fecha fin Tarea", "Dias Tarea");
                Modify();
            end;
        }

    }


    procedure CalculaFechas(Nivel: Integer; ActualizarDependencias: Boolean; Var FechaInicio: Date; var FechaFin: Date; var Dias: Integer)
    var
        JobTaskNiv: Record "Job Task";

    begin
        If Nivel = 1 then begin
            ActualizarDependencias := Confirm('¿Desea actualizar las dependencias?');

            if Dias <> 0 then
                FechaFin := FechaInicio + Dias
            else
                Dias := FechaFin - FechaInicio;
            JobTaskNiv.SetRange("Job No.", Rec."Job No.");
            JobTaskNiv.SetRange(Dependencia, Rec."Job Task No.");
            if JobTaskNiv.FindSet() then begin
                JobTaskNiv.CalculaFechas(Nivel + 1, ActualizarDependencias, FechaInicio, FechaFin, Dias);
                JobTaskNiv.Modify();
            end;
        end else begin
            JobTaskNiv.SetRange("Job No.", Rec."Job No.");
            JobTaskNiv.SetRange(Dependencia, Rec."Job Task No.");
            if JobTaskNiv.FindSet() then begin
                JobTaskNiv.CalculaFechas(Nivel + 1, ActualizarDependencias, FechaInicio, FechaFin, Dias);
                JobTaskNiv.Modify();
            end;
        end;
    end;
}
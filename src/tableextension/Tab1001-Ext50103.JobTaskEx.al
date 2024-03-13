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
            trigger OnValidate()
            begin

            end;
        }
        field(50002; "Fecha inicio Tarea"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(50003; "Fecha fin Tarea."; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(50005; "Fecha fin Tarea"; Date)
        {
            DataClassification = ToBeClassified;
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

    }

}
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

    }

}
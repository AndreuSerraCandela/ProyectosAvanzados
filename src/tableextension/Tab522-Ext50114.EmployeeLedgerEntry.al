/// <summary>
/// TableExtension EmployeeLedgerEntryExt (ID 50114) extends Record Employee Ledger Entry//522.
/// </summary>
tableextension 50320 "EmployeeLedgerEntryExt" extends "Employee Ledger Entry" //522
{
    fields
    {
        field(50000; "Job No."; Code[20])
        {
            Caption = 'Nº Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = Job."No.";
        }
        field(50001; "Job Task No."; Code[20])
        {
            Caption = 'Nº Tarea Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(50002; "Job Planning Line No."; Integer)
        {
            Caption = 'Nº Línea Planificación Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."));
        }
    }
}


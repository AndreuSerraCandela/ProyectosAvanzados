/// <summary>
/// TableExtension G/L Entry Ext (ID 50131) - Extiende G/L Entry (17).
/// Añade el campo Job Task No.
/// </summary>
tableextension 50333 "G/L Entry Ext" extends "G/L Entry"
{
    fields
    {
        field(50030; "Job Task No."; Code[20])
        {
            Caption = 'Nº Tarea Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
    }
}

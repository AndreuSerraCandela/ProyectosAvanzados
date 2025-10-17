tableextension 50307 budgetentry extends "G/L Budget Entry"
{
    fields
    {
        field(50103; "Job No."; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Nº Proyecto';
            TableRelation = Job."No.";
        }
    }
}
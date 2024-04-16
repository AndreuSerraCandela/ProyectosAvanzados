pageextension 50114 BusgetEntries extends "G/L Budget Entries"
{
    layout
    {
        addbefore("Global Dimension 1 Code")
        {
            field("Job No."; Rec."Job No.")
            {
                ApplicationArea = All;
                Caption = 'Nº Proyecto';

            }
        }
    }
}
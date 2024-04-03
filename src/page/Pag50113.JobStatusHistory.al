page 50113 "Job Status History"
{
    Caption = 'Histórico de cambios de estado de proyecto';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Job Status History";
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field("Date & Time Action"; Rec."Date&Time")
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
                field("Old Status"; Rec."Old Status")
                {
                    ApplicationArea = All;
                }
                field("New Status"; Rec."New Status")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
/// <summary>
/// PageExtension JobTaskLinesSubformEX (ID 50101) extends Record Job Task Lines Subform.
/// </summary>
pageextension 50101 "JobTaskLinesSubformEX" extends "Job Task Lines Subform"
{
    layout
    {
        addfirst(Control1)
        {
            field(Dependencia; Rec.Dependencia)
            {
                ApplicationArea = all;

            }
            field("Status Task"; Rec."Status Task")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
    }
}
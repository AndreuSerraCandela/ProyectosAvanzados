/// <summary>
/// PageExtension JobTaskLinesSubformEX (ID 50101) extends Record Job Task Lines Subform.
/// </summary>
pageextension 50101 "JobTaskLinesSubformEX" extends "Job Task Lines Subform" //1001
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
            field("Fecha inicio Tarea"; Rec."Fecha inicio Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Fecha inicio Tarea field.';
            }
            field("Fecha fin Tarea"; Rec."Fecha fin Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Fecha fin Tarea field.';
            }
            field("WIP %"; Rec."WIP %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the WIP % field.';
            }

        }
    }

    actions
    {
    }
}
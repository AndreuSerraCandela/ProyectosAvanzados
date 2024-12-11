page 50119 "Dependencias de Tareas"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Dependecias de Tareas";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Job No."; Rec."Job No.")
                {
                    ToolTip = 'Specifies the value of the Job No. field.', Comment = '%';
                }

                field("Cód. Tarea"; Rec."Cód. Tarea")
                {
                    ToolTip = 'Specifies the value of the MyField field.', Comment = '%';
                }
                field("Tareas Dependiente"; Rec."Tareas Dependiente")
                {
                    ToolTip = 'Specifies the value of the Tareas Dependiente field.', Comment = '%';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
}
/// <summary>
/// PageExtension EmployeeLedgerEntriesExt (ID 50115) extends Record Employee Ledger Entries.
/// </summary>
pageextension 50321 "EmployeeLedgerEntriesExt" extends "Employee Ledger Entries"
{
    layout
    {
        addafter("Employee No.")
        {
            field("Job No."; Rec."Job No.")
            {
                ApplicationArea = All;
                Caption = 'Nº Proyecto';
                ToolTip = 'Especifica el número del proyecto asociado a esta entrada del mayor de empleados.';
            }
            field("Job Task No."; Rec."Job Task No.")
            {
                ApplicationArea = All;
                Caption = 'Nº Tarea Proyecto';
                ToolTip = 'Especifica el número de la tarea del proyecto asociada a esta entrada del mayor de empleados.';
            }
            field("Job Planning Line No."; Rec."Job Planning Line No.")
            {
                ApplicationArea = All;
                Caption = 'Nº Línea Planificación Proyecto';
                ToolTip = 'Especifica el número de la línea de planificación del proyecto asociada a esta entrada del mayor de empleados.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }
}


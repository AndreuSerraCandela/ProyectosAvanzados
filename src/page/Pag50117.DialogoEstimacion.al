page 50117 DialogoEstimacion
{
    ApplicationArea = All;
    Caption = 'Estimacion', Comment = 'ESP="Estimacion"';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(CodEstimacion; CodEstimacion)
            {
                ApplicationArea = All;
                Caption = 'Cód. Estimacion', Comment = 'ESP="Código Estimacion"';


            }
        }
    }



    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then begin



        end;
    end;

    procedure GetValueCode(): Code[20]
    begin
        exit(CodEstimacion);
    end;

    var
        CodEstimacion: code[20];
}
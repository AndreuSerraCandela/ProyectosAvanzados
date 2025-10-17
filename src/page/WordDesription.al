page 50121 WordDesription
{
    PageType = Card;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(WorkDescription; WorkDescription)
                {
                    Caption = 'Descripción ampliada';
                    ApplicationArea = All;
                    MultiLine = true;
                    RowSpan = 4;

                }
            }
        }
    }

    var
        WorkDescription: Text;

    procedure SetWorkDescription(NewWorkDescription: Text)
    begin
        WorkDescription := NewWorkDescription;
    end;

    procedure GetWorkDescription(): Text
    begin
        exit(WorkDescription);
    end;
}
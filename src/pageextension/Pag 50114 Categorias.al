page 50114 "Categorías"
{
    PageType = List;
    SourceTable = Categorias;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Categorías';
    layout
    {
        area(content)
        {
            repeater(Categorias)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
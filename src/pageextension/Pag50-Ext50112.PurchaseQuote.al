pageextension 50112 "PurchaseQuote" extends "Purchase Quote" //50
{
    layout
    {
        addlast(General)
        {

            field("No. Proyecto"; Rec."No. Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Proyecto field.';
            }
            field(Categoría; Rec.Categorias)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Categorias field.';
            }
            field(Aceptada; Rec.Aceptada)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Aceptada field.';
            }
            /*
            field("Your Reference"; Rec."Your Reference")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Your Reference field.';
            }
            */
        }
    }

    actions
    {


    }

    var
        myInt: Integer;
}

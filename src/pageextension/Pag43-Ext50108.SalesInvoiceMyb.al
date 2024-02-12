pageextension 50108 "SalesInvoiceMyb" extends "Sales Invoice" //43
{
    layout
    {
        addlast(General)
        {

            field("Cod. Oferta de Proyecto"; Rec."Cod. Oferta de Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Cod. Oferta de Proyecto field.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
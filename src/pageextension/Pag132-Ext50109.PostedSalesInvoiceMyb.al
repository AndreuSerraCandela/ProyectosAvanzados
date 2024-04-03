pageextension 50109 "PostedSalesInvoiceMyb" extends "Posted Sales Invoice"//132
{
    layout
    {
        addafter("External Document No.")
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
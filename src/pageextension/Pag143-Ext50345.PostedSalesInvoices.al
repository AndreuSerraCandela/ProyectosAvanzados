pageextension 50345 "Posted Sales Invoices Ext" extends "Posted Sales Invoices" //143
{
    layout
    {
        addlast(Control1)
        {
            field("VAT Registration No."; Rec."VAT Registration No.")
            {
                ApplicationArea = All;
                Caption = 'CIF';
                ToolTip = 'NIF/CIF del cliente.';
            }
        }
    }
}

pageextension 50346 "Posted Sales Credit Memos Ext" extends "Posted Sales Credit Memos" //144
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

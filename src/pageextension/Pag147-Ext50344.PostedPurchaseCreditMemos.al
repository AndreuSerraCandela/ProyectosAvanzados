pageextension 50344 "Posted Purch. Cr. Memos Ext" extends "Posted Purchase Credit Memos" //147
{
    layout
    {
        addlast(Control1)
        {
            field("No. Proyecto"; Rec."No. Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Proyecto field.';
            }
            field("VAT Registration No."; Rec."VAT Registration No.")
            {
                ApplicationArea = All;
                Caption = 'CIF';
                ToolTip = 'NIF/CIF del proveedor.';
            }
        }
    }
}

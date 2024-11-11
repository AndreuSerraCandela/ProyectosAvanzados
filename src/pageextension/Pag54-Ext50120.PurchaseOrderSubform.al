pageextension 50120 PurchaseOrderSubform extends "Purchase Order Subform" //54
{
    layout
    {
        addlast(Control1)
        {

        }
        modify("Job No.")
        {
            Visible = true;
        }
        modify("Job Task No.")
        {
            Visible = true;
        }

    }

}
pageextension 50320 PurchaseOrderSubform extends "Purchase Order Subform" //54
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
        modify(Description)
        {
            StyleExpr = DescriptionEmphasize;
            // field("Work Description"; Rec."Work Description")
            // {
            ApplicationArea = All;
            trigger OnAssistEdit()
            var
                WordDesription: Page WordDesription;
            begin
                WordDesription.SetWorkDescription(Rec.GetWorkDescription);
                WordDesription.RunModal();
                Rec.SetWorkDescription(WordDesription.GetWorkDescription());

            end;
            // }
        }
        addafter("Job Planning Line No.")
        {
            field("Job Planning Line No. Aux"; Rec."Job Planning Line No. Aux")
            {
                ApplicationArea = All;
            }
        }
        modify("Job Planning Line No.")
        {
            Visible = false;
        }

    }
    var
        DescriptionEmphasize: Text;

    trigger OnAfterGetRecord()
    begin
        If Rec.GetWorkDescription() <> '' then
            DescriptionEmphasize := 'StrongAccent'
        else
            DescriptionEmphasize := '';
    end;

}
pageextension 50322 PurchaseOrderSubformEx extends "Purch. Invoice Subform"
{
    layout
    {
        addafter("Job Planning Line No.")
        {
            field("Job Planning Line No. Aux"; Rec."Job Planning Line No. Aux")
            {
                ApplicationArea = All;
            }
        }
        modify("Job Planning Line No.")
        {
            Visible = false;
        }
    }
}
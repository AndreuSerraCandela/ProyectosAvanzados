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
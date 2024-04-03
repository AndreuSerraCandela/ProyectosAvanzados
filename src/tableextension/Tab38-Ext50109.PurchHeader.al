tableextension 50109 "PurchHeader" extends "Purchase Header" //38
{
    fields
    {
        field(50100; "No. Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Proyecto';
            TableRelation = Job."No.";
        }
        field(50101; "Cod. Oferta"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(90002; Categorias; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Categorias;
        }
        field(90003; Aceptada; Boolean)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                JobPlaningLine: Record "Job Planning Line";
                Lines: Record "Purchase Line";
            begin
                if Aceptada then begin
                    Lines.SetRange("Document Type", Rec."Document Type");
                    Lines.SetRange("Document No.", Rec."No.");
                    if Lines.FindSet() then
                        repeat
                            JobPlaningLine.SetRange("No.", Lines."Job No.");
                            JobPlaningLine.SetRange("Line No.", Lines."Job Planning Line No.");

                            if JobPlaningLine.FindSet() then begin
                                JobPlaningLine.Validate("Unit Cost", Lines."Direct Unit Cost");
                                JobPlaningLine.Validate("Line Discount %", Lines."Line Discount %");
                                JobPlaningLine.Modify();
                            end;
                        until Lines.Next() = 0;

                end;
            end;

        }
    }


    var
        myInt: Integer;


}
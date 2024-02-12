tableextension 50102 "PurcharseLine_Job" extends "Purchase Line" //39
{
    fields
    {

        field(50000; "Job Contract Entry No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Contract Entry No.';
            Editable = false;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                IsHandled: Boolean;
                DummyDefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                IsHandled := false;
                OnBeforeValidateJobContractEntryNo(xRec, IsHandled);
                if IsHandled then
                    exit;

                JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
                JobPlanningLine.SetRange("Job Contract Entry No.", "Job Contract Entry No.");
                JobPlanningLine.FindFirst();

                //CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])', '20.0')]                
                //CreateDim(Type.AsInteger(),"No.");

                CreateDim(DummyDefaultDimSource);
                /*CreateDim(
                      DATABASE::Job, "Job No.",
                      //  DimMgt.TypeToTableID3(Type.AsInteger()), "No.",
                      DimMgt.TypeToTableID2(Type.AsInteger()), "No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Work Center", "Work Center No.");
*/
            end;
        }
    }


    [InternalEvent(true)]
    local procedure OnBeforeValidateJobContractEntryNo(var xRec: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    var
        myInt: Integer;
        DimMgt: Codeunit DimensionManagement;
}

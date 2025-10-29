tableextension 50302 "PurcharseLine_Job" extends "Purchase Line" //39
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
        field(90005; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        field(50001; "Job Assignment Percentage"; Decimal)
        {
            Caption = '% Asignación Proyecto';
            ToolTip = 'Especifica el porcentaje de la línea que se asignará al proyecto. Si se utiliza porcentaje, el importe debe ser 0.';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            MaxValue = 100;

            trigger OnValidate()
            var
                ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
            begin
                if "Job Assignment Percentage" <> 0 then begin
                    // Si se establece porcentaje, borrar asignaciones por importe para esta línea
                    ProyectoFacturaCompra.SetRange("Document Type", "Document Type");
                    ProyectoFacturaCompra.SetRange("Document No.", "Document No.");
                    ProyectoFacturaCompra.SetRange("Line No.", "Line No.");
                    ProyectoFacturaCompra.SetFilter("Amount", '<>%1', 0);
                    if ProyectoFacturaCompra.FindSet() then
                        ProyectoFacturaCompra.DeleteAll();
                end;
            end;
        }
        field(50002; "Job Assignment Amount"; Decimal)
        {
            Caption = 'Importe Asignación Proyecto';
            ToolTip = 'Especifica el importe de la línea que se asignará al proyecto. Si se utiliza importe, el porcentaje debe ser 0.';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DecimalPlaces = 2 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
            begin
                if "Job Assignment Amount" <> 0 then begin
                    // Si se establece importe, borrar asignaciones por porcentaje para esta línea
                    ProyectoFacturaCompra.SetRange("Document Type", "Document Type");
                    ProyectoFacturaCompra.SetRange("Document No.", "Document No.");
                    ProyectoFacturaCompra.SetRange("Line No.", "Line No.");
                    ProyectoFacturaCompra.SetFilter("Percentage", '<>%1', 0);
                    if ProyectoFacturaCompra.FindSet() then
                        ProyectoFacturaCompra.DeleteAll();
                end;
            end;
        }
    }
    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Work Description");
        "Work Description".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    /// <summary>
    /// Retrieves work description from the sales header.
    /// </summary>
    /// <returns>Work description.</returns>
    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;

    [InternalEvent(true)]
    local procedure OnBeforeValidateJobContractEntryNo(var xRec: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    var
        myInt: Integer;
        DimMgt: Codeunit DimensionManagement;
}

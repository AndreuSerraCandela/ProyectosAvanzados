pageextension 50311 "Posted Purchase Invoice" extends "Posted Purchase Invoice" //138
{
    layout
    {
        addafter("Vendor Invoice No.")
        {

            field("No. Proyecto"; Rec."No. Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the No. Proyecto field.';
            }
            field("Work Description"; Rec."Work Description")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Work Description field.';
            }
        }
    }

    actions
    {
        addafter(Approvals)
        {
            //Genera Mov Pago
            action(GeneraMovPago)
            {
                ApplicationArea = All;
                Caption = 'Genera Mov Pago';
                Image = CalculateInvoiceDiscount;
                ToolTip = 'Genera Mov Pago';
                trigger OnAction()
                var
                    ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
                    PurchInvHeader: Record "Purch. Inv. Header";
                    VendorNo: Code[20];
                    PurchaseLine: Record "Purchase Line";
                    PreassignedNo: Code[20];
                    JobAssignmentPercentage: Decimal;
                    JobAssignmentAmount: Decimal;
                    PurcInvLine: Record "Purch. Inv. Line";
                begin
                    PurcInvLine.SetRange("Document No.", Rec."No.");
                    if PurcInvLine.FindSet() then
                        repeat

                            // Si la línea tiene Job No., crear asignación automática
                            if PurcInvLine."Job No." <> '' then begin
                                if PurchInvHeader.Get(PurcInvLine."Document No.") then begin
                                    VendorNo := PurchInvHeader."Buy-from Vendor No.";
                                    PreassignedNo := PurchInvHeader."Pre-Assigned No.";
                                end;

                                ProyectoFacturaCompra.Init();
                                ProyectoFacturaCompra."Document Type" := ProyectoFacturaCompra."Document Type"::Invoice;
                                ProyectoFacturaCompra."Document No." := PurchInvHeader."Pre-Assigned No.";
                                ProyectoFacturaCompra."Line No." := PurcInvLine."Line No.";
                                ProyectoFacturaCompra."Job No." := PurcInvLine."Job No.";
                                ProyectoFacturaCompra."Job Task No." := PurcInvLine."Job Task No.";
                                ProyectoFacturaCompra."Job Planning Line No." := PurcInvLine."Job Planning Line No.";
                                ProyectoFacturaCompra."Vendor No." := VendorNo;
                                ProyectoFacturaCompra."Posted Document No." := PurcInvLine."Document No.";

                                // Si hay campos de asignación, usarlos
                                PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
                                PurchaseLine.SetRange("Document No.", PreassignedNo);
                                PurchaseLine.SetRange("Line No.", PurcInvLine."Line No.");
                                if PurchaseLine.FindFirst() then begin
                                    JobAssignmentPercentage := PurchaseLine."Job Assignment Percentage";
                                    JobAssignmentAmount := PurchaseLine."Job Assignment Amount";
                                end else
                                    JobAssignmentAmount := PurcInvLine."Amount Including VAT";
                                if JobAssignmentPercentage <> 0 then begin
                                    ProyectoFacturaCompra."Percentage" := JobAssignmentPercentage;
                                    JobAssignmentAmount := Rec."Amount Including VAT" * JobAssignmentPercentage / 100;
                                end;
                                if JobAssignmentAmount <> 0 then begin
                                    ProyectoFacturaCompra."Amount" := JobAssignmentAmount;
                                    ProyectoFacturaCompra."Base Amount" := JobAssignmentAmount / (1 + PurchaseLine."VAT %" / 100);
                                end else begin
                                    // Si no hay asignación específica, asignar el 100% o el importe completo
                                    ProyectoFacturaCompra."Amount" := PurcInvLine."Amount Including VAT";
                                    ProyectoFacturaCompra."Base Amount" := PurcInvLine.Amount;

                                end;
                                ProyectoFacturaCompra.Insert(true);
                            end;
                        until PurcInvLine.Next() = 0;
                end;
            }
        }
    }

    var
        myInt: Integer;
        WorkDescription: Text;

    trigger OnAfterGetRecord()
    begin
        WorkDescription := Rec.GetWorkDescription();
    end;



}
page 50126 "Pagos Asociados Factbox"
{
    PageType = ListPart;
    SourceTable = "Proyecto Movimiento Pago";
    Caption = 'Pagos Asociados';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de documento';
                    Style = Strong;
                    StyleExpr = ShowStrongStyle;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de proveedor';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de documento registrado';
                    Visible = false;
                }
                field("Amount"; Rec."Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el importe asignado al proyecto';
                    Style = Strong;
                }
                field("Amount Paid"; Rec."Amount Paid")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el importe pagado';
                    Style = Favorable;
                    StyleExpr = ShowFavorableStyle;
                }
                field("Amount Pending"; Rec."Amount Pending")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el importe pendiente';
                    Style = Unfavorable;
                    StyleExpr = ShowUnfavorableStyle;
                }
                field("Percentage"; Rec."Percentage")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el porcentaje asignado';
                    Visible = false;
                }
                field(PercentagePaid; GetPercentagePaid())
                {
                    ApplicationArea = All;
                    Caption = '% Pagado';
                    ToolTip = 'Especifica el porcentaje pagado';
                    DecimalPlaces = 1 : 1;
                    Style = Strong;
                }
                field("Last Payment Date"; Rec."Last Payment Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la fecha del último pago';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(VerDetalle)
            {
                ApplicationArea = All;
                Caption = 'Ver Detalle';
                ToolTip = 'Abre la página completa de pagos del proyecto';
                Image = Payment;

                trigger OnAction()
                var
                    PagosProyecto: Page "Pagos Proyecto";
                begin
                    PagosProyecto.SetJobFilter(JobNoFilter);
                    PagosProyecto.RunModal();
                end;
            }
            action(Recalcular)
            {
                ApplicationArea = All;
                Caption = 'Recalcular Pagos';
                ToolTip = 'Recalcula los importes pagados para todas las facturas del proyecto';
                Image = Refresh;

                trigger OnAction()
                var
                    ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
                begin
                    if Confirm('¿Desea recalcular los importes pagados para todas las facturas del proyecto?') then begin
                        ProyectoFacturaCompra.SetRange("Job No.", JobNoFilter);
                        if ProyectoFacturaCompra.FindSet() then
                            repeat
                                ProyectoFacturaCompra.RecalculatePaymentAmounts();
                            until ProyectoFacturaCompra.Next() = 0;

                        CurrPage.Update(false);
                        Message('Recálculo completado correctamente.');
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStyleExpressions();
    end;

    var
        JobNoFilter: Code[20];
        ShowStrongStyle: Boolean;
        ShowFavorableStyle: Boolean;
        ShowUnfavorableStyle: Boolean;

    procedure SetJobFilter(JobNo: Code[20])
    begin
        JobNoFilter := JobNo;
        Rec.SetRange("Job No.", JobNo);
    end;

    local procedure GetPercentagePaid(): Decimal
    begin
        if Rec."Amount" = 0 then
            exit(0);

        exit(Round((Rec."Amount Paid" / Rec."Amount") * 100, 0.1));
    end;

    local procedure UpdateStyleExpressions()
    begin
        ShowFavorableStyle := (Rec."Amount Paid" > 0) and (Rec."Amount Pending" > 0);
        ShowUnfavorableStyle := Rec."Amount Pending" > 0;
        ShowStrongStyle := Rec."Amount Pending" = 0; // Pagado completamente
    end;
}

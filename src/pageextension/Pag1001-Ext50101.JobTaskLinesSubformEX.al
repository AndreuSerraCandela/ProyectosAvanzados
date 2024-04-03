/// <summary>
/// PageExtension JobTaskLinesSubformEX (ID 50101) extends Record Job Task Lines Subform.
/// </summary>
pageextension 50101 "JobTaskLinesSubformEX" extends "Job Task Lines Subform" //1001
{
    layout
    {
        addafter(Description)
        {
            field(Dependencia; Rec.Dependencia)
            {
                ApplicationArea = all;

            }
            field("Tipo Dependencia fecha"; rec."Tipo Dependencia fecha")
            {
                ApplicationArea = all;

            }
            field(Retardo; rec.Retardo)
            {
                ApplicationArea = all;

            }
            field("Status Task"; Rec."Status Task")
            {
                ApplicationArea = all;
            }
            field("Fecha inicio Tarea"; Rec."Fecha inicio Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Fecha inicio Tarea field.';
            }
            field("Dias Tarea"; Rec."Dias Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Dias Tarea field.';
            }
            field("Fecha fin Tarea"; Rec."Fecha fin Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Fecha fin Tarea field.';
            }
            field("WIP %"; Rec."WIP %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the WIP % field.';
            }
            field("Venta Inicial"; Rec."Venta Inicial")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Venta Inicial field.';
                Editable = false;
            }
            field("Coste Inicial"; Rec."Coste Inicial")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Coste Inicial field.';
                Editable = false;
            }
            field("Pedidos Pendientes"; PedidosPendientes())
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the WIP Amount field.';
                trigger OnDrillDown()
                var
                    PurchLine: Record "Purchase Line";
                begin
                    PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                    PurchLine.SetRange("Job No.", Rec."Job No.");
                    PurchLine.SetRange("Job Task No.", Rec."Job Task No.");
                    PurchLine.SetFilter("Outstanding Amount", '<>%1', 0);
                    Page.RunModal(0, PurchLine);
                end;
            }

        }

    }

    actions
    {
    }

    local procedure PedidosPendientes(): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Job No.", Rec."Job No.");
        PurchLine.SetRange("Job Task No.", Rec."Job Task No.");
        PurchLine.CalcSums("Outstanding Amount");
        If PurchLine.FindFirst() then exit(PurchLine."Outstanding Amount");


    end;
}
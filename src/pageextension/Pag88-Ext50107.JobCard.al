pageextension 50107 "JobCard" extends "Job Card" //88
{
    layout
    {
        // Add changes to page layout here
        addafter("Your Reference")
        {

            field("Cód Oferta Job"; Rec."Cód Oferta Job")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Cód Oferta Job field.';
                Visible = false;
            }
            field("Cod Almacen de Proyecto"; Rec."Cod Almacen de Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Nomenglatura Proyecto almacen field.';
                Editable = false;
                DrillDown = true;
            }


        }
        addafter("Sell-to Customer Name")
        {

            field("Project Status"; Rec."Project Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Project Status field.', Comment = 'ESP="Estado Proyecto"';
            }
            field("Versión Base"; rec."Versión Base")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Versión Base field.', Comment = 'ESP="Versión Base"';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("Asignar Oferta")
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    rec.AddOfertaaProyecto();
                end;
            }
            action("Calcular nueva estimación")
            {
                Image = Calculate;
                ApplicationArea = All;
                Caption = 'Calcular nueva estimación';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Calcula la nueva estimación de costes y horas para la línea de planificación de trabajo seleccionada.';
                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Planning Line";
                    HistJobPlanningLine: Record "Hist. Job Planning Line";
                    Job: Record Job;
                    Ver: Integer;
                    MenEstimacionLbl: Label '¿Se ha generado la nueva estimacion %1, a fecha %2?';
                begin
                    Job.Get(Rec."No.");
                    If Job."Versión Base" = 0 Then Job."Versión Base" := 1;
                    JobPlanningLine.SetRange("Job No.", Rec."No.");
                    HistJobPlanningLine.SetRange("Job No.", Rec."No.");
                    if HistJobPlanningLine.FindLast() then
                        Ver := HistJobPlanningLine."Version No." + 1
                    else
                        Ver := 1;
                    if JobPlanningLine.FindSet() then
                        repeat
                            HistJobPlanningLine.TransferFields(JobPlanningLine);
                            HistJobPlanningLine."Version No." := Ver;
                            HistJobPlanningLine.INSERT;
                        until JobPlanningLine.NEXT = 0;

                    if JobPlanningLine.FindSet() then
                        repeat
                            HistJobPlanningLine.SetRange("Version No.", job."Versión Base");
                            HistJobPlanningLine.SETRANGE("Line No.", JobPlanningLine."Line No.");
                            if Not HistJobPlanningLine.FindFirst() Then begin
                                HistJobPlanningLine.TransferFields(JobPlanningLine);
                                HistJobPlanningLine."Version No." := job."Versión Base";
                                HistJobPlanningLine.INSERT;
                                Message(MenEstimacionLbl, Job."Versión Base", Today());
                            end;
                            // JobPlanningLine."Importe Inicial Venta" := HistJobPlanningLine."Total Price";
                            // JobPlanningLine."Importe Inicial Coste" := HistJobPlanningLine."Total Cost";
                            JobPlanningLine."Importe Inicial Venta" := HistJobPlanningLine."Total Price (LCY)";
                            JobPlanningLine."Importe Inicial Coste" := HistJobPlanningLine."Total Cost (LCY)";
                            JobPlanningLine.Modify();
                        until JobPlanningLine.NEXT = 0;

                end;


            }
            action("Ver Estimaciones")
            {
                Image = History;
                ApplicationArea = All;
                Caption = 'Ver Estimaciones';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Muestra las estimaciones de costes y horas para la línea de planificación de trabajo seleccionada.';
                trigger OnAction()
                var
                    HistJobPlanningLine: Record "Hist. Job Planning Line";
                begin
                    HistJobPlanningLine.SETRANGE("Job No.", Rec."No.");
                    Page.RunModal(0, HistJobPlanningLine);
                end;
            }


            action("Crear Almacen de Proyecto")
            {
                Caption = 'Crear Almacen de Proyecto';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    CodProyecto: Codeunit ProcesosProyectos;
                begin
                    CodProyecto.CreateJobLocation(Rec);
                end;
            }
            action("Movimiento de Almacen de proyecto")
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    // Pag92JobLEntries: Page "Job Ledger Entries";
                    MovProyecto: record "Job Ledger Entry";
                begin
                    MovProyecto.SetRange("Location Code", rec."Cod Almacen de Proyecto");
                    page.RunModal(92, MovProyecto);

                end;
            }

        }
        addlast(History)
        {
            action("Historico Estados")
            {
                ApplicationArea = All;
                Image = Status;
                Caption = 'Historico Estados';

                trigger OnAction()
                var
                    HistorioStatus: Record "Job Status History";
                begin
                    HistorioStatus.SetRange("Job No.", Rec."No.");
                    Page.RunModal(50113, HistorioStatus);

                end;
            }
        }
        addlast("&Job")

        {
            action("Order Job")
            {

                ApplicationArea = all;
                // Caption = 'Purchase  Order';
                Caption = 'Pedido Compra';
                Image = Purchase;
                RunObject = Page "purchase order list";
                RunPageLink = "No. Proyecto" = FIELD("No.");


            }
            action("Quote Job")
            {

                ApplicationArea = all;
                // Caption = 'Purchase  Order';
                Caption = 'Oferta Compra';
                Image = Purchase;
                RunObject = Page "Purchase Quotes";
                RunPageLink = "No. Proyecto" = FIELD("No.");


            }
            action("Return Job")
            {

                ApplicationArea = all;
                //Caption = 'Purchase Return Order';
                Caption = 'Ped. Dev.Compra';
                Image = Purchase;
                RunObject = Page "Purchase Return Order List";
                RunPageLink = "No. Proyecto" = FIELD("No.");
                ToolTip = 'Filter purchase order for jobs';
            }
            action("Comparativa Ofertas")
            {
                ApplicationArea = All;
                Caption = 'Comparativa Ofertas';
                Image = Purchase;
                RunObject = Page "Comparativo Ofertas";
                RunPageLink = "No. Proyecto" = FIELD("No.");
                ToolTip = 'Comparativa de ofertas';

            }
        }
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
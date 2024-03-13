#pragma warning disable DOC0101
/// <summary>
/// PageExtension JobPlanningLinesEx (ID 50100) extends Record Job Planning Lines.
/// </summary>
pageextension 50100 "JobPlanningLinesEx" extends "Job Planning Lines" //1007
#pragma warning restore DOC0101
{
    layout
    {
        addafter(Description)
        {
            field("Bill-to Customer No."; Rec."Bill-to Customer No.")
            {
                ApplicationArea = All;
            }
        }

        // Add changes to page layout here
        addfirst(Control1)
        {
            field("Generar Compra"; rec."Generar Compra")
            {
                ApplicationArea = all;

            }
            field(Cod_Proveedor; rec.Cod_Proveedor)
            {
                ApplicationArea = all;

            }
            field(Nombre; Rec.Nombre)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Nombre field.';
            }

            field("Cód Oferta Job"; Rec."Cód Oferta Job")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Cód Oferta Job field.';
            }

        }
        addafter("Document No.")
        {
            field("Nº documento Compra"; Rec."Nº documento Compra")
            {
                ApplicationArea = all;
                Visible = false;
            }
            field(Categoría; Rec.Categorias)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Categoría field.';
            }
        }
        addafter(Quantity)
        {
            field("Cantidad a tr a Factura Compra"; Rec."Cantidad a tr a Factura Compra")
            {
                ApplicationArea = All;
            }
            field("Cantidad en Factura Compra"; Rec."Cantidad en Factura Compra")
            {
                ApplicationArea = All;
            }
            field("Importe Inicial Coste"; Rec."Importe Inicial Coste")
            {
                ApplicationArea = All;
            }
            field("Importe Inicial Venta"; Rec."Importe Inicial Venta")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addafter("Job - Planning Lines")
        {
            group("Function Compras")
            {
                Caption = 'Funciones Compra';
                action("Create Purchase Invoice")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Crear Factura Compra';
                    // Caption = 'Create &Purchase Invoice', comment = 'ESP="Crear Factura Compra"';
                    Ellipsis = true;
                    Image = JobPurchaseInvoice;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Use a batch job to help you create purchase invoices for the involved job tasks.';

                    trigger OnAction()
                    begin
                        CreatePurcharseInvoice(false);
                    end;
                }
                action("Create Purchase Order")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Crear Pedido Compra';
                    // Caption = 'Create &Purchase Order', comment = 'ESP="Crear Pedido Compra"';
                    Ellipsis = true;
                    Image = JobPurchaseInvoice;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Use a batch job to help you create purchase orders for the involved job tasks.';

                    trigger OnAction()
                    begin
                        // CreatePurcharseInvoice(false);
                        CreatePurcharseOrder();
                    end;
                }
                action("Create Purcharse &Credit Memo")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Crear Abono Compra';
                    // Caption = 'Create Purchase &Credit Memo', comment = 'ESP="Crear Abono Compra"';
                    Ellipsis = true;
                    Image = CreditMemo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a Purchase credit memo for the selected job planning line.';

                    trigger OnAction()
                    begin
                        CreatePurcharseInvoice(true);
                    end;
                }
                action("Create Purchase Quote")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Crear Oferta Compra';
                    // Caption = 'Create &Purchase Quote', comment = 'ESP="Crear Oferta Compra"';
                    Ellipsis = true;
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Use a batch job to help you create purchase orders for the involved job tasks.';

                    trigger OnAction()
                    begin
                        // CreatePurcharseInvoice(false);
                        CreatePurcharseQuote();
                    end;
                }
                action("Ver Comparativa Ofertas")
                {
                    ApplicationArea = All;
                    Caption = 'Ver Comparativa Ofertas';
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Muestra la comparativa de ofertas para la línea de planificación de trabajo seleccionada.';
                    trigger OnAction()
                    var
                        Quotes: Record "Purchase Header";
                    begin
                        Quotes.SETRANGE("No. Proyecto", Rec."Job No.");
                        Page.RunModal(Page::"Comparativo Ofertas", qUOTES);

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
                    begin
                        Job.Get(Rec."Job No.");
                        If Job."Versión Base" = 0 Then Job."Versión Base" := 1;
                        JobPlanningLine.SetRange("Job No.", Rec."Job No.");


                        HistJobPlanningLine.SetRange("Job No.", Rec."Job No.");
                        if HistJobPlanningLine.FindLast() then
                            Ver := HistJobPlanningLine."Version No." + 1
                        else
                            Ver := 1;
                        if Ver = 1 then begin
                            if JobPlanningLine.FindFirst() then;
                            JobPlanningLine."Importe Inicial Venta" := JobPlanningLine."Total Price";
                            JobPlanningLine."Importe Inicial Coste" := JobPlanningLine."Total Cost";
                            JobPlanningLine.Modify();
                        end;
                        if JobPlanningLine.FindSet() then
                            repeat
                                HistJobPlanningLine.TransferFields(JobPlanningLine);
                                HistJobPlanningLine."Version Date" := Today();
                                HistJobPlanningLine."Version No." := Ver;
                                if not HistJobPlanningLine.INSERT() then;
                            until JobPlanningLine.NEXT = 0;

                        if JobPlanningLine.FindSet() then
                            repeat
                                HistJobPlanningLine.SetRange("Version No.", job."Versión Base");
                                HistJobPlanningLine.SETRANGE("Line No.", JobPlanningLine."Line No.");
                                HistJobPlanningLine.FindFirst();
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
                        HistJobPlanningLine.SETRANGE("Job No.", Rec."Job No.");
                        Page.RunModal(0, HistJobPlanningLine);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        /*
        Clear(Nombre);
        if RProveedore.Get(rec.Cod_Proveedor) then begin
            Nombre := RProveedore.Name;
        end else
            Clear(Nombre);
*/
    end;
    /// <summary>
    /// CreatePurcharseInvoice.
    /// </summary>
    /// <param name="CrMemo">Boolean.</param>
    procedure CreatePurcharseInvoice(CrMemo: Boolean);
    begin
        rec.TESTFIELD("Line No.");
        JobPlanningLine.COPY(Rec);
        CurrPage.SETSELECTIONFILTER(JobPlanningLine);
        JobCreateInvoice.CreatePurchaseInvoice(JobPlanningLine, CrMemo)
    end;

    /// <summary>
    /// CreatePurcharseOrder.
    /// </summary>
    procedure CreatePurcharseOrder();
    begin
        rec.TESTFIELD("Line No.");
        JobPlanningLine.COPY(Rec);
        CurrPage.SETSELECTIONFILTER(JobPlanningLine);
        JobCreateInvoice.CreatePurchaseOrder(JobPlanningLine);
    end;

    procedure CreatePurcharseQuote();
    begin
        rec.TESTFIELD("Line No.");
        JobPlanningLine.COPY(Rec);
        CurrPage.SETSELECTIONFILTER(JobPlanningLine);
        JobCreateInvoice.CreatePurchaseQuote(JobPlanningLine);
    end;

    var
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit ProcesosProyectos;
        CrMemo: Boolean;
        //  Nombre: Text[100];
        RProveedore: Record Vendor;
}
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
                    Caption = 'Create &Purchase Invoice';
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
                    Caption = 'Create &Purchase Order';
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
                    Caption = 'Create Purchase &Credit Memo';
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

    var
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit ProcesosProyectos;
        CrMemo: Boolean;
        //  Nombre: Text[100];
        RProveedore: Record Vendor;
}
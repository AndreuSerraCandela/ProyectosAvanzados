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
        }
        addafter("Sell-to Customer Name")
        {

            field("Project Status"; Rec."Project Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Project Status field.', Comment = 'ESP="Estado Proyecto"';
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
/// <summary>
/// PageExtension Vendor Ledger Entries Ext (ID 50129) - Extiende Vendor Ledger Entries (29).
/// Añade acción para asociar documento a liquidar a los movimientos de Proyecto Movimiento Pago vinculados a los movimientos seleccionados.
/// </summary>
pageextension 50331 "Vendor Ledger Entries Ext" extends "Vendor Ledger Entries"
{
    actions
    {
        addfirst(Processing)
        {
            action(AsociarDocumentoLiquidar)
            {
                ApplicationArea = All;
                Caption = 'Asociar documento a liquidar';
                Image = ApplyEntries;
                ToolTip = 'Asocia un documento (pedido/factura) a liquidar a los movimientos de la tabla Proyecto Movimiento Pago vinculados a los movimientos de proveedor seleccionados.';

                trigger OnAction()
                var
                    PagosProyecto: Page "Pagos Proyecto";
                begin

                    PagosProyecto.SetDocumento(Rec."Document No.");
                    PagosProyecto.RunModal();

                    CurrPage.Update(false);
                end;
            }
        }
    }
}

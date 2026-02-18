tableextension 50319 "Vendor Ledger Entry Ext" extends "Vendor Ledger Entry"
{
    fields
    {
        field(50000; "Project Payment Entry"; Boolean)
        {
            Caption = 'Entrada Pago Proyecto';
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    trigger OnAfterInsert()
    var
        ProyectoFacturaCompra: Record "Proyecto Movimiento Pago";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TotalInvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        GlEntry: Record "G/L Entry";
    begin
        // Si es un pago (aplicación), distribuir entre proyectos
        if "Document Type" <> "Document Type"::Payment then
            exit;

        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", "Entry No.");
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        DetailedVendorLedgEntry.SetFilter(Amount, '<0'); // Pagos son negativos

        if DetailedVendorLedgEntry.FindSet() then
            repeat
                // Buscar la factura aplicada
                VendorLedgerEntry.SetRange("Entry No.", DetailedVendorLedgEntry."Applied Vend. Ledger Entry No.");
                if VendorLedgerEntry.FindFirst() then begin
                    if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Invoice then begin
                        PaymentAmount := -DetailedVendorLedgEntry.Amount; // Convertir a positivo

                        // Buscar asignaciones de proyecto para esta factura
                        ProyectoFacturaCompra.SetRange("Posted Document No.", VendorLedgerEntry."Document No.");
                        ProyectoFacturaCompra.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
                        if ProyectoFacturaCompra.FindSet() then begin
                            // Calcular importe total de la factura registrada
                            PurchInvLine.SetRange("Document No.", VendorLedgerEntry."Document No.");
                            if PurchInvLine.FindSet() then
                                repeat
                                    TotalInvoiceAmount += PurchInvLine."Line Amount";
                                until PurchInvLine.Next() = 0;

                            // Distribuir el pago proporcionalmente
                            if TotalInvoiceAmount <> 0 then
                                repeat
                                    if ProyectoFacturaCompra."Percentage" <> 0 then
                                        ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
                                    else
                                        ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;

                                    ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
                                    ProyectoFacturaCompra."Last Payment Date" := "Posting Date";
                                    ProyectoFacturaCompra.Modify(true);
                                until ProyectoFacturaCompra.Next() = 0;
                        end;

                    end;
                    PaymentAmount := -DetailedVendorLedgEntry.Amount; // Convertir a positivo
                                                                      // Buscar el Nº de Documento en la tabla ProyectoFacturaCompra por Document To Liquidate
                    ProyectoFacturaCompra.SetRange("Document to Liquidate", VendorLedgerEntry."Document No.");
                    if ProyectoFacturaCompra.FindSet() then
                        repeat
                            TotalInvoiceAmount += ProyectoFacturaCompra.Amount;
                        until ProyectoFacturaCompra.Next() = 0;
                    if TotalInvoiceAmount <> 0 then
                        repeat
                            if ProyectoFacturaCompra."Percentage" <> 0 then
                                ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
                            else
                                ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;
                            ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
                            ProyectoFacturaCompra."Last Payment Date" := "Posting Date";
                            ProyectoFacturaCompra.Modify(true);
                        until ProyectoFacturaCompra.Next() = 0;
                    If GlEntry.Get(VendorLedgerEntry."Entry No.") then
                        if (GlEntry."Job No." <> '') and (GlEntry."Job Task No." <> '') then begin
                            PaymentAmount := -DetailedVendorLedgEntry.Amount; // Convertir a positivo
                                                                              // Buscar el Nº de Documento en la tabla ProyectoFacturaCompra por Document To Liquidate
                            ProyectoFacturaCompra.SetRange("Job No.", GlEntry."Job No.");
                            ProyectoFacturaCompra.SetRange("Job Task No.", GlEntry."Job Task No.");
                            if ProyectoFacturaCompra.FindSet() then
                                repeat
                                    TotalInvoiceAmount += ProyectoFacturaCompra.Amount;
                                until ProyectoFacturaCompra.Next() = 0;
                            if TotalInvoiceAmount <> 0 then
                                repeat
                                    if ProyectoFacturaCompra."Percentage" <> 0 then
                                        ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
                                    else
                                        ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;
                                    ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
                                    ProyectoFacturaCompra."Last Payment Date" := "Posting Date";
                                    ProyectoFacturaCompra.Modify(true);
                                until ProyectoFacturaCompra.Next() = 0;


                        end;
                end;
            until DetailedVendorLedgEntry.Next() = 0;
    end;

    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
}

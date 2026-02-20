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
        Eventosproyectos: Codeunit "Eventos-proyectos";
        MovRetencion: Record "Payments Retention Ledger Ent.";
        Irpf: Decimal;
        TotalAmount: Decimal;
        encontrado: Boolean;
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
                        Eventosproyectos.DatosFactura(VendorLedgerEntry."Document No.");
                        MovRetencion.SetRange("Document Type", MovRetencion."Document Type"::Invoice);
                        MovRetencion.SetRange("Document No.", VendorLedgerEntry."Document No.");
                        if MovRetencion.FindFirst() then
                            Irpf := MovRetencion.Amount
                        else
                            Irpf := 0;
                        PaymentAmount := -DetailedVendorLedgEntry.Amount; // Convertir a positivo

                        // Buscar asignaciones de proyecto para esta factura
                        ProyectoFacturaCompra.SetRange("Posted Document No.", VendorLedgerEntry."Document No.");
                        ProyectoFacturaCompra.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
                        if ProyectoFacturaCompra.FindSet() then begin
                            // Calcular importe total de la factura registrada
                            PurchInvLine.SetRange("Document No.", VendorLedgerEntry."Document No.");
                            if PurchInvLine.FindSet() then
                                repeat
                                    TotalInvoiceAmount += PurchInvLine."Amount Including VAT";
                                    TotalAmount += PurchInvLine."Line Amount";
                                until PurchInvLine.Next() = 0;
                            //TotalAmount := TotalAmount + Irpf;
                            // Distribuir el pago proporcionalmente
                            if TotalInvoiceAmount <> 0 then
                                repeat
                                    if ProyectoFacturaCompra."Percentage" <> 0 then
                                        ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
                                    else
                                        ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;
                                    ProyectoFacturaCompra."Base Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Base Amount") / TotalAmount;
                                    ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
                                    ProyectoFacturaCompra."Base Amount Pending" := ProyectoFacturaCompra."Base Amount" - ProyectoFacturaCompra."Base Amount Paid";
                                    if ProyectoFacturaCompra."Amount Pending" = 0 Then begin
                                        ProyectoFacturaCompra."Base Amount Paid" := ProyectoFacturaCompra."Base Amount";
                                        ProyectoFacturaCompra."Base Amount Pending" := 0;
                                    end;
                                    ProyectoFacturaCompra."Last Payment Date" := "Posting Date";
                                    ProyectoFacturaCompra.Modify(true);
                                    encontrado := true;
                                    // no dejar que los importes pagados sean mallores que la factura
                                    if ProyectoFacturaCompra."Amount Paid" > ProyectoFacturaCompra.Amount then begin
                                        ProyectoFacturaCompra."Amount Paid" := ProyectoFacturaCompra.Amount;
                                        ProyectoFacturaCompra."Amount Pending" := 0;
                                    end;
                                    if ProyectoFacturaCompra."Base Amount Paid" > ProyectoFacturaCompra."Base Amount" then begin
                                        ProyectoFacturaCompra."Base Amount Paid" := ProyectoFacturaCompra."Base Amount";
                                        ProyectoFacturaCompra."Base Amount Pending" := 0;
                                    end;
                                until ProyectoFacturaCompra.Next() = 0;
                            if encontrado then exit;
                        end;

                    end;
                    PaymentAmount := -DetailedVendorLedgEntry.Amount; // Convertir a positivo
                                                                      // Buscar el Nº de Documento en la tabla ProyectoFacturaCompra por Document To Liquidate
                    ProyectoFacturaCompra.SetRange("Document to Liquidate", VendorLedgerEntry."Document No.");
                    ProyectoFacturaCompra.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
                    if ProyectoFacturaCompra.FindSet() then
                        repeat
                            TotalInvoiceAmount += ProyectoFacturaCompra.Amount;
                        until ProyectoFacturaCompra.Next() = 0;
                    if (not encontrado) and (TotalInvoiceAmount <> 0) then
                        repeat
                            if ProyectoFacturaCompra."Percentage" <> 0 then
                                ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Percentage") / 100
                            else
                                ProyectoFacturaCompra."Amount Paid" += (PaymentAmount * ProyectoFacturaCompra."Amount") / TotalInvoiceAmount;
                            ProyectoFacturaCompra."Amount Pending" := ProyectoFacturaCompra."Amount" - ProyectoFacturaCompra."Amount Paid";
                            ProyectoFacturaCompra."Last Payment Date" := "Posting Date";
                            // no dejar que los importes pagados sean mallores que la factura
                            if ProyectoFacturaCompra."Amount Paid" > ProyectoFacturaCompra.Amount then begin
                                ProyectoFacturaCompra."Amount Paid" := ProyectoFacturaCompra.Amount;
                                ProyectoFacturaCompra."Amount Pending" := 0;
                            end;
                            if ProyectoFacturaCompra."Base Amount Paid" > ProyectoFacturaCompra."Base Amount" then begin
                                ProyectoFacturaCompra."Base Amount Paid" := ProyectoFacturaCompra."Base Amount";
                                ProyectoFacturaCompra."Base Amount Pending" := 0;
                            end;

                            ProyectoFacturaCompra.Modify(true);
                            encontrado := true;
                        until ProyectoFacturaCompra.Next() = 0;

                    If (not encontrado) and (GlEntry.Get(VendorLedgerEntry."Entry No.")) then
                        if (GlEntry."Job No." <> '') and (GlEntry."Job Task No." <> '') then begin
                            PaymentAmount := -DetailedVendorLedgEntry.Amount; // Convertir a positivo
                            ProyectoFacturaCompra.reset;                                                  // Buscar el Nº de Documento en la tabla ProyectoFacturaCompra por Document To Liquidate
                            ProyectoFacturaCompra.SetRange("Job No.", GlEntry."Job No.");
                            ProyectoFacturaCompra.SetRange("Job Task No.", GlEntry."Job Task No.");
                            ProyectoFacturaCompra.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
                            ProyectoFacturaCompra.SetRange("Document No.", GlEntry."Document No.");
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
                                    // no dejar que los importes pagados sean mallores que la factura
                                    if ProyectoFacturaCompra."Amount Paid" > ProyectoFacturaCompra.Amount then begin
                                        ProyectoFacturaCompra."Amount Paid" := ProyectoFacturaCompra.Amount;
                                        ProyectoFacturaCompra."Amount Pending" := 0;
                                    end;
                                    if ProyectoFacturaCompra."Base Amount Paid" > ProyectoFacturaCompra."Base Amount" then begin
                                        ProyectoFacturaCompra."Base Amount Paid" := ProyectoFacturaCompra."Base Amount";
                                        ProyectoFacturaCompra."Base Amount Pending" := 0;
                                    end;
                                until ProyectoFacturaCompra.Next() = 0;


                        end;
                end;
            until DetailedVendorLedgEntry.Next() = 0;
    end;

    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
}

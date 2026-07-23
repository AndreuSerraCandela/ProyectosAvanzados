/// <summary>
/// Carga el buffer del Libro IVA (compras/ventas) y exporta a Excel con una hoja por Tipo Operación2.
/// </summary>
codeunit 50347 "Libro IVA"
{
    procedure CargarLibro(var Buffer: Record "Libro IVA Buffer"; TipoMov: Enum "General Posting Type"; FechaDesde: Date; FechaHasta: Date)
    var
        VATEntry: Record "VAT Entry";
        ProcesosProyectos: Codeunit ProcesosProyectos;
        NOrden: Integer;
        DocAnterior: Code[20];
        IRPFDoc: Decimal;
        IRPFAsignado: Boolean;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        VATEntry.SetCurrentKey(Type, "Posting Date");
        VATEntry.SetRange(Type, TipoMov);
        if FechaDesde <> 0D then
            VATEntry.SetFilter("Posting Date", '%1..%2', FechaDesde, FechaHasta)
        else
            if FechaHasta <> 0D then
                VATEntry.SetFilter("Posting Date", '..%1', FechaHasta);

        NOrden := 0;
        DocAnterior := '';
        if VATEntry.FindSet() then
            repeat
                if VATEntry."Document No." <> DocAnterior then begin
                    DocAnterior := VATEntry."Document No.";
                    IRPFDoc := ObtenerIRPFDocumento(VATEntry);
                    IRPFAsignado := false;
                end;

                NOrden += 1;
                Buffer.Init();
                Buffer."Entry No." := VATEntry."Entry No.";
                Buffer."N Orden" := NOrden;
                Buffer."N Referencia" := VATEntry."Transaction No.";
                Buffer."Document No." := VATEntry."Document No.";
                Buffer."Document Type" := CopyStr(Format(VATEntry."Document Type"), 1, 30);
                Buffer."Posting Date" := VATEntry."Posting Date";
                Buffer."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
                Buffer."VAT Entry Type" := VATEntry.Type;
                Buffer."Fecha Factura" := VATEntry."Document Date";
                if Buffer."Fecha Factura" = 0D then
                    Buffer."Fecha Factura" := VATEntry."Posting Date";
                Buffer."Fecha Operacion" := VATEntry."VAT Reporting Date";
                if Buffer."Fecha Operacion" = 0D then
                    Buffer."Fecha Operacion" := VATEntry."Posting Date";
                Buffer."Num Factura" := ObtenerNumFactura(VATEntry);
                Buffer.Concepto := ObtenerConcepto(VATEntry, Buffer."Num Factura");
                Buffer.NIF := ProcesosProyectos.ObtenerCIFClienteProveedor(VATEntry);
                Buffer.Nombre := ProcesosProyectos.ObtenerNombreClienteProveedor(VATEntry);
                Buffer."Base Imponible" := VATEntry.Base;
                Buffer."VAT %" := VATEntry."VAT %";
                Buffer.Cuota := VATEntry.Amount;
                if not IRPFAsignado then begin
                    Buffer.Retencion := IRPFDoc;
                    IRPFAsignado := true;
                end else
                    Buffer.Retencion := 0;
                Buffer."Total Fra" := Buffer."Base Imponible" + Buffer.Cuota - Buffer.Retencion;
                Buffer."Tipo Operacion" := ProcesosProyectos.CalcularTipoOperacion(VATEntry);
                Buffer."Tipo Operacion2" := ProcesosProyectos.CalcularRegimenOperacion(VATEntry, false);
                Buffer."Clausula IVA" := ProcesosProyectos.ObtenerClausulaIVA(VATEntry);
                Buffer."Motivo Exencion" := ProcesosProyectos.ObtenerMotivoExencion(VATEntry);
                Buffer."Invoice Type" := ObtenerInvoiceType(VATEntry);
                Buffer."Special Scheme Code" := ObtenerSpecialSchemeCode(VATEntry);
                Buffer."Nombre Hoja Excel" := NombreHojaDesdeTipoOperacion2(Buffer."Tipo Operacion2");
                Buffer.Insert();
            until VATEntry.Next() = 0;

        RenumerarPorHoja(Buffer);
    end;

    local procedure RenumerarPorHoja(var Buffer: Record "Libro IVA Buffer")
    var
        UltimaHoja: Text[31];
        NOrdenHoja: Integer;
    begin
        UltimaHoja := '';
        NOrdenHoja := 0;
        Buffer.Reset();
        Buffer.SetCurrentKey("Nombre Hoja Excel", "N Orden");
        if Buffer.FindSet() then
            repeat
                if Buffer."Nombre Hoja Excel" <> UltimaHoja then begin
                    UltimaHoja := Buffer."Nombre Hoja Excel";
                    NOrdenHoja := 0;
                end;
                NOrdenHoja += 1;
                Buffer."N Orden" := NOrdenHoja;
                Buffer.Modify();
            until Buffer.Next() = 0;
        Buffer.Reset();
    end;

    procedure ExportarExcel(var Buffer: Record "Libro IVA Buffer"; NombreLibro: Text)
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempHojas: Record "Libro IVA Buffer" temporary;
        PrimeraHoja: Boolean;
        NombreHoja: Text[31];
        UltimaHoja: Text[31];
        CompanyInfo: Record "Company Information";
        FechaDesde: Date;
        FechaHasta: Date;
    begin
        Buffer.Reset();
        if not Buffer.FindFirst() then begin
            Message('No hay datos para exportar. Pulse Actualizar primero.');
            exit;
        end;

        CompanyInfo.Get();
        ObtenerRangoFechas(Buffer, FechaDesde, FechaHasta);

        TempHojas.Reset();
        TempHojas.DeleteAll();
        UltimaHoja := '';
        Buffer.Reset();
        Buffer.SetCurrentKey("Nombre Hoja Excel", "N Orden");
        if Buffer.FindSet() then
            repeat
                if Buffer."Nombre Hoja Excel" <> UltimaHoja then begin
                    UltimaHoja := Buffer."Nombre Hoja Excel";
                    TempHojas.Init();
                    TempHojas."Entry No." := Buffer."Entry No.";
                    TempHojas."Nombre Hoja Excel" := Buffer."Nombre Hoja Excel";
                    TempHojas."Tipo Operacion2" := Buffer."Tipo Operacion2";
                    TempHojas.Insert();
                end;
            until Buffer.Next() = 0;

        PrimeraHoja := true;
        TempHojas.Reset();
        if TempHojas.FindSet() then
            repeat
                NombreHoja := TempHojas."Nombre Hoja Excel";
                if NombreHoja = '' then
                    NombreHoja := 'Otros';

                TempExcelBuffer.DeleteAll();
                EscribirCabeceraHoja(TempExcelBuffer, NombreLibro, TempHojas."Tipo Operacion2", CompanyInfo.Name, FechaDesde, FechaHasta);
                EscribirFilasHoja(TempExcelBuffer, Buffer, NombreHoja);

                if PrimeraHoja then begin
                    TempExcelBuffer.CreateNewBook(NombreHoja);
                    PrimeraHoja := false;
                end else
                    TempExcelBuffer.SelectOrAddSheet(NombreHoja);

                TempExcelBuffer.WriteSheet(NombreHoja, CompanyName(), UserId());
            until TempHojas.Next() = 0;

        TempExcelBuffer.CloseBook();
        DescargarExcelSinDocumentService(
            TempExcelBuffer,
            CopyStr(NombreLibro + '_' + Format(Today, 0, '<Year4><Month,2><Day,2>') + '.xlsx', 1, 250));
        Buffer.Reset();
    end;

    local procedure DescargarExcelSinDocumentService(var TempExcelBuffer: Record "Excel Buffer" temporary; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        // OpenExcel usa OneDrive/Document Service; si no está configurado falla.
        // SaveToStream + DownloadFromStream descarga el fichero al navegador.
        TempBlob.CreateOutStream(OutStr);
        TempExcelBuffer.SaveToStream(OutStr, true);
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    local procedure EscribirCabeceraHoja(var ExcelBuf: Record "Excel Buffer" temporary; NombreLibro: Text; TipoOp2: Text; Empresa: Text; FechaDesde: Date; FechaHasta: Date)
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(NombreLibro + ' - ' + TipoOp2, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);

        ExcelBuf.NewRow();

        ExcelBuf.NewRow();
        ExcelBuf.AddColumn('Empresa: ' + Empresa, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);

        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(
            StrSubstNo('Período De %1 a %2', Format(FechaDesde), Format(FechaHasta)),
            false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);

        ExcelBuf.NewRow();
        ExcelBuf.AddColumn('Fecha: ' + Format(Today), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);

        ExcelBuf.NewRow();

        ExcelBuf.NewRow();
        ExcelBuf.AddColumn('Nº Orden', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('N. Referencia', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Núm. Fact.', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Fecha Factura', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Fecha Operación', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Concepto', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('N.I.F.', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Expedidor/Destinatario', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Base Imponible', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('% IVA/IGIC', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Cuota', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Retención', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Total Fra.', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Tipo de Operación', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Tipo de Operación2', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Cláusula IVA', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Motivo de exención', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Invoice Type', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Cód. de esquema especial', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn('Nº documento', false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure EscribirFilasHoja(var ExcelBuf: Record "Excel Buffer" temporary; var Buffer: Record "Libro IVA Buffer"; NombreHoja: Text[31])
    begin
        Buffer.Reset();
        Buffer.SetCurrentKey("Nombre Hoja Excel", "N Orden");
        Buffer.SetRange("Nombre Hoja Excel", NombreHoja);
        if Buffer.FindSet() then
            repeat
                ExcelBuf.NewRow();
                ExcelBuf.AddColumn(Buffer."N Orden", false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer."N Referencia", false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer."Num Factura", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Format(Buffer."Fecha Factura"), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Format(Buffer."Fecha Operacion"), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer.Concepto, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer.NIF, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer.Nombre, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Base Imponible", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer."VAT %", false, '', false, false, false, '0.00', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer.Cuota, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer.Retencion, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer."Total Fra", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                ExcelBuf.AddColumn(Buffer."Tipo Operacion", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Tipo Operacion2", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Clausula IVA", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Motivo Exencion", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Invoice Type", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Special Scheme Code", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(Buffer."Document No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            until Buffer.Next() = 0;
        Buffer.Reset();
    end;

    local procedure ObtenerRangoFechas(var Buffer: Record "Libro IVA Buffer"; var FechaDesde: Date; var FechaHasta: Date)
    begin
        FechaDesde := 0D;
        FechaHasta := 0D;
        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                if (FechaDesde = 0D) or (Buffer."Posting Date" < FechaDesde) then
                    FechaDesde := Buffer."Posting Date";
                if Buffer."Posting Date" > FechaHasta then
                    FechaHasta := Buffer."Posting Date";
            until Buffer.Next() = 0;
    end;

    local procedure NombreHojaDesdeTipoOperacion2(TipoOp2: Text[100]): Text[31]
    begin
        case TipoOp2 of
            'Régimen General':
                exit('Facturas');
            'Inversión del sujeto pasivo (ISP)':
                exit('Sujeto pasivo');
            'Operaciones no sujetas por reglas de localización':
                exit('No sujetas');
            else
                if TipoOp2 = '' then
                    exit('Otros')
                else
                    exit(CopyStr(TipoOp2, 1, 31));
        end;
    end;

    local procedure ObtenerNumFactura(VATEntry: Record "VAT Entry"): Text[35]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        case VATEntry.Type of
            VATEntry.Type::Sale:
                begin
                    if SalesInvHeader.Get(VATEntry."Document No.") then
                        if SalesInvHeader."External Document No." <> '' then
                            exit(CopyStr(SalesInvHeader."External Document No.", 1, 35))
                        else
                            exit(VATEntry."Document No.");
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then
                        if SalesCrMemoHeader."External Document No." <> '' then
                            exit(CopyStr(SalesCrMemoHeader."External Document No.", 1, 35))
                        else
                            exit(VATEntry."Document No.");
                end;
            VATEntry.Type::Purchase:
                begin
                    if PurchInvHeader.Get(VATEntry."Document No.") then
                        if PurchInvHeader."Vendor Invoice No." <> '' then
                            exit(CopyStr(PurchInvHeader."Vendor Invoice No.", 1, 35))
                        else
                            exit(VATEntry."Document No.");
                    if PurchCrMemoHeader.Get(VATEntry."Document No.") then
                        if PurchCrMemoHeader."Vendor Cr. Memo No." <> '' then
                            exit(CopyStr(PurchCrMemoHeader."Vendor Cr. Memo No.", 1, 35))
                        else
                            exit(VATEntry."Document No.");
                end;
        end;
        exit(VATEntry."Document No.");
    end;

    local procedure ObtenerConcepto(VATEntry: Record "VAT Entry"; NumFactura: Text[35]): Text[100]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        case VATEntry.Type of
            VATEntry.Type::Sale:
                begin
                    if SalesInvHeader.Get(VATEntry."Document No.") then
                        if SalesInvHeader."Posting Description" <> '' then
                            exit(CopyStr(SalesInvHeader."Posting Description", 1, 100));
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then
                        if SalesCrMemoHeader."Posting Description" <> '' then
                            exit(CopyStr(SalesCrMemoHeader."Posting Description", 1, 100));
                    exit(CopyStr('Fra. Nº.' + NumFactura, 1, 100));
                end;
            VATEntry.Type::Purchase:
                begin
                    if PurchInvHeader.Get(VATEntry."Document No.") then
                        if PurchInvHeader."Posting Description" <> '' then
                            exit(CopyStr(PurchInvHeader."Posting Description", 1, 100));
                    if PurchCrMemoHeader.Get(VATEntry."Document No.") then
                        if PurchCrMemoHeader."Posting Description" <> '' then
                            exit(CopyStr(PurchCrMemoHeader."Posting Description", 1, 100));
                    exit(CopyStr('Su Fra. Nº.' + NumFactura, 1, 100));
                end;
        end;
        exit('');
    end;

    procedure ObtenerInvoiceType(VATEntry: Record "VAT Entry"): Text[50]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        case VATEntry.Type of
            VATEntry.Type::Sale:
                begin
                    if SalesInvHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(SalesInvHeader."Invoice Type"), 1, 50));
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(SalesCrMemoHeader."Invoice Type"), 1, 50));
                end;
            VATEntry.Type::Purchase:
                begin
                    if PurchInvHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(PurchInvHeader."Invoice Type"), 1, 50));
                    if PurchCrMemoHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(PurchCrMemoHeader."Invoice Type"), 1, 50));
                end;
        end;
        exit('');
    end;

    local procedure ObtenerSpecialSchemeCode(VATEntry: Record "VAT Entry"): Text[100]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        case VATEntry.Type of
            VATEntry.Type::Sale:
                begin
                    if SalesInvHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(SalesInvHeader."Special Scheme Code"), 1, 100));
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(SalesCrMemoHeader."Special Scheme Code"), 1, 100));
                end;
            VATEntry.Type::Purchase:
                begin
                    if PurchInvHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(PurchInvHeader."Special Scheme Code"), 1, 100));
                    if PurchCrMemoHeader.Get(VATEntry."Document No.") then
                        exit(CopyStr(Format(PurchCrMemoHeader."Special Scheme Code"), 1, 100));
                end;
        end;
        exit('');
    end;

    local procedure ObtenerIRPFDocumento(VATEntry: Record "VAT Entry"): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        MovRetencion: Record "Payments Retention Ledger Ent.";
        TotalIRPF: Decimal;
    begin
        TotalIRPF := 0;
        case VATEntry.Type of
            VATEntry.Type::Purchase:
                begin
                    PurchInvLine.SetRange("Document No.", VATEntry."Document No.");
                    if PurchInvLine.FindSet() then
                        repeat
                            TotalIRPF += PurchInvLine."Retention Amount (IRPF)";
                        until PurchInvLine.Next() = 0
                    else begin
                        PurchCrMemoLine.SetRange("Document No.", VATEntry."Document No.");
                        if PurchCrMemoLine.FindSet() then
                            repeat
                                TotalIRPF += PurchCrMemoLine."Retention Amount (IRPF)";
                            until PurchCrMemoLine.Next() = 0;
                    end;
                end;
            VATEntry.Type::Sale:
                begin
                    MovRetencion.SetRange("Document No.", VATEntry."Document No.");
                    if MovRetencion.FindSet() then
                        repeat
                            TotalIRPF += MovRetencion.Amount;
                        until MovRetencion.Next() = 0;
                end;
        end;
        exit(TotalIRPF);
    end;
}

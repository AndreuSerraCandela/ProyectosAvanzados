/// <summary>
/// Buffer temporal para Libro de facturas emitidas/recibidas (pantalla + Excel).
/// </summary>
table 50347 "Libro IVA Buffer"
{
    Caption = 'Libro IVA Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov. IVA';
        }
        field(2; "N Orden"; Integer)
        {
            Caption = 'Nº Orden';
        }
        field(3; "N Referencia"; Integer)
        {
            Caption = 'N. Referencia';
        }
        field(4; "Num Factura"; Text[35])
        {
            Caption = 'Núm. Fact.';
        }
        field(5; "Fecha Factura"; Date)
        {
            Caption = 'Fecha Factura';
        }
        field(6; "Fecha Operacion"; Date)
        {
            Caption = 'Fecha Operación';
        }
        field(7; Concepto; Text[100])
        {
            Caption = 'Concepto';
        }
        field(8; "NIF"; Text[20])
        {
            Caption = 'N.I.F.';
        }
        field(9; Nombre; Text[100])
        {
            Caption = 'Expedidor/Destinatario';
        }
        field(10; "Base Imponible"; Decimal)
        {
            Caption = 'Base Imponible';
            DecimalPlaces = 2 : 2;
        }
        field(11; "VAT %"; Decimal)
        {
            Caption = '% IVA/IGIC';
            DecimalPlaces = 0 : 5;
        }
        field(12; Cuota; Decimal)
        {
            Caption = 'Cuota';
            DecimalPlaces = 2 : 2;
        }
        field(13; Retencion; Decimal)
        {
            Caption = 'Retención IRPF';
            DecimalPlaces = 2 : 2;
        }
        field(14; "Total Fra"; Decimal)
        {
            Caption = 'Total Fra.';
            DecimalPlaces = 2 : 2;
        }
        field(15; "Tipo Operacion"; Text[50])
        {
            Caption = 'Tipo de Operación';
        }
        field(16; "Tipo Operacion2"; Text[100])
        {
            Caption = 'Tipo de Operación2';
        }
        field(17; "Clausula IVA"; Code[20])
        {
            Caption = 'Cláusula IVA';
        }
        field(18; "Motivo Exencion"; Text[30])
        {
            Caption = 'Motivo de exención';
        }
        field(19; "Invoice Type"; Text[50])
        {
            Caption = 'Invoice Type';
        }
        field(26; "Special Scheme Code"; Text[100])
        {
            Caption = 'Cód. de esquema especial';
        }
        field(20; "Document No."; Code[20])
        {
            Caption = 'Nº documento';
        }
        field(21; "Document Type"; Text[30])
        {
            Caption = 'Tipo documento';
        }
        field(22; "Posting Date"; Date)
        {
            Caption = 'Fecha registro';
        }
        field(23; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Cliente/Proveedor';
        }
        field(24; "VAT Entry Type"; Enum "General Posting Type")
        {
            Caption = 'Tipo mov. IVA';
        }
        field(25; "Nombre Hoja Excel"; Text[31])
        {
            Caption = 'Nombre hoja Excel';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Hoja; "Nombre Hoja Excel", "N Orden")
        {
        }
        key(Fecha; "Posting Date", "Entry No.")
        {
        }
    }
}

table 50117 "Proyecto Movimiento Pago"
{
    Caption = 'Proyecto Movimiento Pago';
    DataClassification = ToBeClassified;
    DrillDownPageId = "Pagos Proyecto";
    LookupPageId = "Pagos Proyecto";

    fields
    {
        field(1; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Tipo Documento';
            DataClassification = ToBeClassified;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Nº Documento';
            DataClassification = ToBeClassified;
            // Si es Documento Blanco a G/L Entry, si es Pago a Vendor Entry
            TableRelation = if ("Document Type" = const(" ")) "G/L Entry"."Document No." else
            "Vendor Ledger Entry"."Document No.";

        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Nº Línea';
            DataClassification = ToBeClassified;
        }
        field(4; "Job No."; Code[20])
        {
            Caption = 'Nº Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = Job."No.";
        }
        field(5; "Job Task No."; Code[20])
        {
            Caption = 'Nº Tarea Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            Editable = false;
        }
        field(13; "Job Planning Line No."; Integer)
        {
            Caption = 'Nº Línea Planificación Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."));
            Editable = false;
        }
        field(6; "Percentage"; Decimal)
        {
            Caption = 'Porcentaje';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            MaxValue = 100;


        }
        field(7; "Amount"; Decimal)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla  "Movimiento Proyecto"';
            Caption = 'Importe';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            DecimalPlaces = 2 : 5;
            MinValue = 0;

        }
        field(8; "Amount Paid"; Decimal)
        {
            Caption = 'Importe Pagado';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(9; "Amount Pending"; Decimal)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla  "Movimiento Proyecto"';
            Caption = 'Importe Pendiente';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(10; "Last Payment Date"; Date)
        {
            Caption = 'Fecha Último Pago';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Nº Proveedor';
            DataClassification = ToBeClassified;
            TableRelation = Vendor."No.";
            Editable = false;
        }
        field(12; "Posted Document No."; Code[20])
        {
            Caption = 'Nº Doc. Registrado';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(14; "Entry No."; Integer)
        {
            TableRelation = if ("Document Type" = const(" ")) "G/L Entry"."Entry No." else
            "Vendor Ledger Entry"."Entry No.";
            ValidateTableRelation = false;
        }
        //documento a liquidar
        field(15; "Document to Liquidate"; Code[20])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla  "Movimiento Proyecto"';
            Caption = 'Documento a liquidar';
            DataClassification = ToBeClassified;
            TableRelation = "Purchase Header"."No.";
            Editable = false;
        }
        field(16; "Base Amount"; Decimal)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla  "Movimiento Proyecto"';

            Caption = 'Importe Base';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(17; "Base Amount Paid"; Decimal)
        {
            Caption = 'Importe Base Pagado';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        //Base amount pending
        field(18; "Base Amount Pending"; Decimal)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla  "Movimiento Proyecto"';

            Caption = 'Importe Base Pendiente';
            DataClassification = ToBeClassified;
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        //Job Entry No.
        field(19; "Job Entry No."; Integer)
        {
            Caption = 'Nº Movimiento Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = "Job Ledger Entry"."Entry No.";
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.", "Job No.", "Job Planning Line No.", "Entry No.")
        {
            SumIndexFields = "Amount Paid", "Base Amount Paid";
            Clustered = true;
        }
        key(Key2; "Job No.", "Job Planning Line No.", "Document No.", "Line No.")
        {
        }
        key(Key3; "Posted Document No.", "Line No.", "Job No.", "Job Planning Line No.")
        {
            SumIndexFields = "Amount Paid", "Base Amount Paid";
        }
        key(Key6; "Posted Document No.", "Vendor No.")
        {
            SumIndexFields = "Amount Paid", "Base Amount Paid";
        }
        key(Key4; "Vendor No.", "Document No.")
        {
            SumIndexFields = "Amount Paid", "Base Amount Paid";
        }
        key(Key5; "Job Planning Line No.", "Job No.")
        {
        }
        key(Key7; "Job Entry No.")
        {
            SumIndexFields = "Amount Paid", "Base Amount Paid";
        }

    }

    trigger OnInsert()
    begin
        ValidateProjectAssignment();
        ValidatePaymentAmounts();
    end;

    trigger OnModify()
    begin
        ValidateProjectAssignment();
        // UpdatePaymentAmounts();
    end;

    trigger OnDelete()
    begin
        // No permitir borrar si hay pagos registrados
        if "Amount Paid" <> 0 then
            Error('No se puede eliminar la asignación porque ya existen pagos registrados.');
    end;

    var
        PurchaseLine: Record "Purchase Line";

    local procedure ValidateProjectAssignment()
    var
        Job: Record Job;
    begin
        if "Job No." = '' then
            exit;

        Job.Get("Job No.");

        // Verificar que el proyecto esté abierto
        if Job.Status <> Job.Status::Open then
            Error('El proyecto %1 debe estar en estado Abierto.', "Job No.");
    end;

    /// <summary>
    /// Comprueba que la suma de movimientos de pago por Job Entry No. no supere el importe del movimiento de proyecto,
    /// y que la suma de movimientos de pago por Entry No. (documento blanco) no supere el importe de ese entry.
    /// Debe llamarse desde la función de la página/codeunit antes de Insert o al modificar desde la página.
    /// </summary>
    procedure ValidatePaymentAmounts()
    var
        ProyectoMovimientoPago: Record "Proyecto Movimiento Pago";
        JobLedgerEntry: Record "Job Ledger Entry";
        GLEntry: Record "G/L Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        TotalPaidJob: Decimal;
        TotalPaidEntry: Decimal;
        MaxAmountJob: Decimal;
        MaxAmountEntry: Decimal;
    begin
        // 1) Suma de movimientos de pago para este Job Entry No. no puede superar el importe del movimiento de proyecto
        if "Job Entry No." <> 0 then begin
            ProyectoMovimientoPago.Reset();
            ProyectoMovimientoPago.SetRange("Job Entry No.", "Job Entry No.");
            ProyectoMovimientoPago.CalcSums("Amount Paid");
            TotalPaidJob := ProyectoMovimientoPago."Amount Paid" - xRec."Amount Paid" + Rec."Amount Paid";

            if not JobLedgerEntry.Get("Job Entry No.") then
                Error('No existe el movimiento de proyecto Nº %1.', "Job Entry No.");
            MaxAmountJob := JobLedgerEntry."Bruto Factura";
            if MaxAmountJob = 0 then
                MaxAmountJob := Abs(JobLedgerEntry."Total Cost (LCY)");
            if TotalPaidJob > MaxAmountJob then
                Error('La suma de importes pagados (%1) para el movimiento de proyecto Nº %2 no puede superar el importe del movimiento (%3).',
                    TotalPaidJob, "Job Entry No.", MaxAmountJob);
        end;

        // 2) Suma de movimientos de pago para este Entry No. (documento blanco) no puede superar el importe de ese entry
        if ("Document Type" = "Document Type"::" ") and ("Entry No." <> 0) then begin
            ProyectoMovimientoPago.Reset();
            ProyectoMovimientoPago.SetRange("Document Type", "Document Type"::" ");
            ProyectoMovimientoPago.SetRange("Entry No.", "Entry No.");
            ProyectoMovimientoPago.CalcSums("Amount Paid");
            TotalPaidEntry := ProyectoMovimientoPago."Amount Paid" - xRec."Amount Paid" + Rec."Amount Paid";

            MaxAmountEntry := 0;
            if GLEntry.Get("Entry No.") then
                MaxAmountEntry := Abs(GLEntry.Amount)
            else
                if EmployeeLedgerEntry.Get("Entry No.") then begin
                    EmployeeLedgerEntry.CalcFields("Original Amount");
                    MaxAmountEntry := Abs(EmployeeLedgerEntry."Original Amount");
                end;
            if (MaxAmountEntry > 0) and (TotalPaidEntry > MaxAmountEntry) then
                Error('La suma de importes pagados (%1) para el Entry No. %2 no puede superar el importe del movimiento (%3).',
                    TotalPaidEntry, "Entry No.", MaxAmountEntry);
        end;
    end;



    local procedure GetCurrencyCode(): Code[10]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseHeader.Get("Document Type", "Document No.") then
            exit(PurchaseHeader."Currency Code")
        else
            exit('');
    end;

    // local procedure UpdatePaymentAmounts()
    // var
    //     VendorLedgerEntry: Record "Vendor Ledger Entry";
    //     DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    //     PurchInvLine: Record "Purch. Inv. Line";
    //     TotalInvoiceAmount: Decimal;
    //     TotalInvoiceBaseAmount: Decimal;
    //     TotalPaidAmount: Decimal;
    //     ProjectPaidAmount: Decimal;
    // begin
    //     if "Posted Document No." = '' then
    //         exit;

    //     // Buscar el asiento del mayor de proveedores
    //     VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
    //     VendorLedgerEntry.SetRange("Document No.", "Posted Document No.");
    //     VendorLedgerEntry.SetRange("Vendor No.", "Vendor No.");
    //     VendorLedgerEntry.SetRange("Entry No.", "Entry No.");

    //     if not VendorLedgerEntry.FindFirst() then begin
    //         Clear("Amount Paid");
    //         Clear("Amount Pending");
    //         Clear("Base Amount Paid");
    //         Clear("Last Payment Date");
    //         exit;
    //     end;

    //     VendorLedgerEntry.CalcFields("Original Amount", "Remaining Amount");
    //     TotalInvoiceAmount := VendorLedgerEntry."Original Amount";
    //     TotalPaidAmount := TotalInvoiceAmount - VendorLedgerEntry."Remaining Amount";

    //     // Calcular el importe total de la línea de factura
    //     PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
    //     PurchaseLine.SetRange("Document No.", "Document No.");
    //     if PurchaseLine.FindSet() then
    //         repeat
    //             if PurchaseLine."Document No." = "Posted Document No." then
    //                 TotalInvoiceAmount += PurchaseLine."Line Amount";
    //         until PurchaseLine.Next() = 0;

    //     // Calcular proporción pagada para este proyecto
    //     if TotalInvoiceAmount <> 0 then begin
    //         if "Percentage" <> 0 then
    //             ProjectPaidAmount := (TotalPaidAmount * "Percentage") / 100
    //         else
    //             ProjectPaidAmount := (TotalPaidAmount * "Amount") / TotalInvoiceAmount;

    //         "Amount Paid" := ProjectPaidAmount;
    //         "Amount Pending" := "Amount" - "Amount Paid";

    //         // Importe base pagado (sin IVA): proporción sobre líneas de factura registrada
    //         PurchInvLine.SetRange("Document No.", "Posted Document No.");
    //         PurchInvLine.CalcSums("Line Amount", "Amount Including VAT");
    //         TotalInvoiceBaseAmount := PurchInvLine."Line Amount";

    //         if PurchInvLine."Amount Including VAT" <> 0 then
    //             "Base Amount Paid" := Round(ProjectPaidAmount * TotalInvoiceBaseAmount / PurchInvLine."Amount Including VAT", 0.01)
    //         else
    //             "Base Amount Paid" := ProjectPaidAmount;
    //         if VendorLedgerEntry."Remaining Amount" = 0 Then
    //             "Base Amount Paid" := PurchInvLine."Line Amount";
    //         "Base Amount Pending" := PurchInvLine."Line Amount" - "Base Amount Paid";
    //         if VendorLedgerEntry."Remaining Amount" = 0 Then
    //             "Base Amount Pending" := 0;
    //     end;

    //     // Buscar fecha del último pago
    //     DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
    //     DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
    //     DetailedVendorLedgEntry.SetRange(Unapplied, false);
    //     DetailedVendorLedgEntry.SetFilter(Amount, '<0');

    //     if DetailedVendorLedgEntry.FindSet() then
    //         repeat
    //             if DetailedVendorLedgEntry."Posting Date" > "Last Payment Date" then
    //                 "Last Payment Date" := DetailedVendorLedgEntry."Posting Date";
    //         until DetailedVendorLedgEntry.Next() = 0;

    //     Modify(true);
    // end;

    // procedure RecalculatePaymentAmounts()
    // begin
    //     UpdatePaymentAmounts();
    // end;

    /// <summary>
    /// Reconstruye Amount, Base Amount, importes pagados y pendientes desde la factura registrada.
    /// Si Base Amount Paid queda 0 y Amount Paid no, asigna Base Amount Paid := Amount Paid.
    /// </summary>
    // procedure RebuildPaymentAmounts()
    // var
    //     PurchInvLine: Record "Purch. Inv. Line";
    // begin
    //     if "Posted Document No." <> '' then begin
    //         PurchInvLine.SetRange("Document No.", "Posted Document No.");
    //         PurchInvLine.SetRange("Line No.", "Line No.");
    //         PurchInvLine.CalcSums("Line Amount", "Amount Including VAT");
    //         if PurchInvLine.FindFirst() then begin
    //             If Amount = 0 then Amount := PurchInvLine."Amount Including VAT";
    //             If "Base Amount" = 0 then "Base Amount" := PurchInvLine."Line Amount";
    //         end;
    //     end;
    //     "Amount Pending" := "Amount" - "Amount Paid";

    //     if ("Base Amount Paid" = 0) and ("Amount Paid" <> 0) then begin
    //         "Base Amount Paid" := "Base Amount" * "Amount Paid" / "Amount";
    //         "Base Amount Pending" := "Base Amount" - "Base Amount Paid";
    //         if "Amount Paid" = Amount Then begin
    //             "Base Amount Paid" := "Base Amount";
    //             "Base Amount Pending" := 0;
    //             "Amount Pending" := 0;
    //         end;
    //         Modify(true);
    //     end;
    // end;
}

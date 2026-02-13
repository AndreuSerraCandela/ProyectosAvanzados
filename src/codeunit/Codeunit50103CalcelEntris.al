
/// <summary>
/// Codeunit Cancel Entries (ID 7001101).
/// </summary>
Codeunit 50103 "Cancel Entries"
{

    TableNo = 17;
    Permissions = TableData 17 = rimd,
    tabledata 32 = rimd,
    tabledata 5802 = rimd,
                TableData 21 = rimd,
                TableData 25 = rimd,
                TableData 45 = rimd,
                TableData 169 = rimd,
                TableData 203 = rimd,
                TableData 240 = rimd,
                TableData 241 = rimd,
                TableData 254 = rimd,
                TableData 271 = rimd,
                TableData 355 = rimd,
                TableData 379 = rimd,
                TableData 380 = rimd,
                TableData 7000002 = rimd,
                TableData 7000003 = rimd,
                TableData 7000004 = rimd,
                tabledata 7000006 = RIMD,
                tabledata 112 = rimd,
                tabledata 110 = rimd,
                tabledata 111 = rimd,
                tabledata 122 = rimd,
                tabledata 120 = rimd,
                tabledata 121 = rimd,
                tabledata 123 = rimd,
                tabledata 124 = rimd,
                tabledata 125 = rimd,
                tabledata 113 = rimd,
                tabledata 114 = rimd,
                tabledata 6650 = rimd,
                tabledata 6651 = rimd,
                tabledata 6660 = rimd,
                tabledata 6661 = rimd,
                tabledata "G/L Entry - Vat Entry Link" = rimd,
                tabledata 5601 = rimd,
                tabledata "FA Register" = rimd,
                tabledata 115 = rimd;


    var
        gcGenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        LinDiarioGeneral: Record 81;
        ClosedCartera: Record "Closed Cartera Doc.";
        PostCartera: Record "Posted Cartera Doc.";
        rPostSalesHeader: Record 112;
        rPostPurchHeader: Record 122;
        Job: Record Job;
        wDocFilter: Text;
        JobEntry: Record "Job Ledger Entry";
        rGlEntry: Record "G/L Entry";
        GlEntryLink: Record "G/L Entry - Vat Entry Link";
        CustEntry: Record 21;
        DetCustEntry: Record 379;
        DocCartera: Record "Cartera Doc.";
        VendorEntry: Record 25;
        DetVendorEntry: Record 380;
        BankEntry: Record 271;
        c11: Codeunit 11;
        VatEntry: Record 254;
        r45: Record 45;
        rPurchHeader: Record 38;
        rPostPurchLine: Record 123;
        rPostPurchLine2: Record 123;
        rPurchLine: Record 39;


    trigger OnRun()
    BEGIN
        // RegMovsContaAnulado.LOCKTABLE;
        // IF RegMovsContaAnulado.FIND('+') THEN
        //   NoAsientoAnulado := RegMovsContaAnulado."Transaction No." + 1
        // ELSE
        NoAsientoAnulado := 1;

        // MovContabilidadAnulado.LOCKTABLE;
        // IF MovContabilidadAnulado.FIND('+') THEN
        //   NoMovAnulado := MovContabilidadAnulado."Entry No."
        // ELSE
        NoMovAnulado := 0;

        // MovIVAAnulado.LOCKTABLE;
        // IF MovIVAAnulado.FIND('+') THEN
        //   NoMovIVAAnulado := MovIVAAnulado."Entry No."
        // ELSE
        NoMovIVAAnulado := 0;

        RegMovsConta.RESET;                   //$002
        RegMovsConta.SETFILTER(RegMovsConta."From Entry No.", '%1', Rec."Entry No.");
        //$002(I)
        //RegMovsConta.FIND('-');
        IF NOT RegMovsConta.FIND('-') THEN BEGIN
            RegMovsConta.SETRANGE(RegMovsConta."From Entry No.");
            RegMovsConta.SETFILTER(RegMovsConta."To Entry No.", '%1', Rec."Entry No.");
            RegMovsConta.FIND('-');
            RegMovsConta."From Entry No." := RegMovsConta."To Entry No.";  //no hago nada con mov.iva
        END;
        //$002(F)

        // RegMovsContaAnulado.INIT;
        // RegMovsContaAnulado."Transaction No." := NoAsientoAnulado;
        // RegMovsContaAnulado."From Entry No." := NoMovAnulado + 1;
        // RegMovsContaAnulado."Creation Date" := RegMovsConta."Creation Date";
        // RegMovsContaAnulado."User ID" := USERID;
        // RegMovsContaAnulado."Source Code" := RegMovsConta."Source Code";
        // RegMovsContaAnulado."Journal Batch Name" := RegMovsConta."Journal Batch Name";
        // RegMovsContaAnulado."Posting Date" := RegMovsConta."Posting Date";
        // RegMovsContaAnulado."Period Trans. No." := RegMovsConta."Period Trans. No.";
        // RegMovsContaAnulado."From VAT Entry No." := NoMovIVAAnulado + 1;

        FOR i := RegMovsConta."From Entry No." TO RegMovsConta."To Entry No." DO BEGIN
            MovContabilidad.GET(i);
            GlEntryLink.SetRange("G/L Entry No.", MovContabilidad."Entry No.");
            GlEntryLink.DeleteAll();
            //   MovContabilidadAnulado.INIT;
            //   MovContabilidadAnulado.TRANSFERFIELDS(MovContabilidad);
            NoMovAnulado := NoMovAnulado + 1;
            //   MovContabilidadAnulado."Entry No." := NoMovAnulado;
            //   MovContabilidadAnulado.INSERT;

            //  MovDimensiones.GET(DATABASE::"G/L Entry",MovContabilidad."Entry No.");
            //   MovDimensiones.SETRANGE(MovDimensiones."Table ID",DATABASE::"G/L Entry");
            //   MovDimensiones.SETRANGE(MovDimensiones."Entry No.",MovContabilidad."Entry No.");
            //   IF MovDimensiones.FIND('-') THEN
            //     MovDimensiones.DELETEALL;
            MovContabilidad.DELETE;

            AnulaMovCli(i);
            AnulaMovProv(i);
            AnulaMovBanco(i);
            FOR k := RegMovsConta."From VAT Entry No." TO RegMovsConta."To VAT Entry No." DO BEGIN
                AnulaMovIVA(k);
            END;

            CASE RegMovsConta."Source Code" OF
                'VENTAS':
                    AnulaEfecto(0, i);
                'COMPRAS':
                    AnulaEfecto(1, i);
            END;
        END;

        // RegMovsContaAnulado."To VAT Entry No." := NoMovIVAAnulado;
        // RegMovsContaAnulado.INSERT;

        MovRecurso.SETCURRENTKEY("Document No.", "Posting Date");
        MovRecurso.SETRANGE("Document No.", Rec."Document No.");
        MovRecurso.SETRANGE("Posting Date", Rec."Posting Date");
        IF MovRecurso.FIND('-') THEN
            AnulaMovRecurso;

        MovProyecto.SETCURRENTKEY("Document No.", "Posting Date");
        MovProyecto.SETRANGE("Document No.", Rec."Document No.");
        MovProyecto.SETRANGE("Posting Date", Rec."Posting Date");
        IF MovProyecto.FIND('-') THEN
            AnulaMovProyecto;

        // RegMovsContaAnulado."To Entry No." := NoMovAnulado;
        // RegMovsContaAnulado.MODIFY;
        RegMovsConta.DELETE;
    END;


    VAR
        Text90000: Label 'VENTAS';
        Text90001: Label 'COMPRAS';
        MovContabilidad: Record 17;
        RegMovsConta: Record 45;
        MovCliente: Record 21;
        MovProveedor: Record 25;
        MovIVA: Record 254;
        MovBanco: Record 271;
        DocCerrado: Record 7000004;
        Doc: Record 7000002;
        MovRecurso: Record 203;
        MovProyecto: Record 169;
        NoMovAnulado: Integer;
        NoAsientoAnulado: Integer;
        NoMovIVAAnulado: Integer;
        i: Integer;
        k: Integer;
        MovDimensiones: Record 355;




    /// <summary>
    /// DesmarcaFacturaVenta.
    /// </summary>
    /// <param name="Vendor Invoice No.">Code[20].</param>
    /// <param name="Empresa Factura">Text[30].</param>


    PROCEDURE AnulaMovCli(NoMov: Integer);
    VAR
        MovCli: Record 21;
        DetMovCliente: Record 379;
    BEGIN
        IF MovCliente.GET(NoMov) THEN BEGIN
            // MovClienteAnulado.INIT;
            // MovClienteAnulado.TRANSFERFIELDS(MovCliente);
            DetMovCliente.RESET;
            DetMovCliente.SETCURRENTKEY("Cust. Ledger Entry No.", "Posting Date");
            DetMovCliente.SETRANGE("Cust. Ledger Entry No.", MovCliente."Entry No.");
            // $001-
            //DetMovCliente.SETRANGE(DetMovCliente."Posting Date",MovCliente."Posting Date");
            // $001+
            IF DetMovCliente.FIND('-') THEN
                REPEAT
                    IF NOT (DetMovCliente."Entry Type" IN [DetMovCliente."Entry Type"::Application,
                    DetMovCliente."Entry Type"::"Appln. Rounding",
                    DetMovCliente."Entry Type"::"Correction of Remaining Amount"]) THEN BEGIN
                        //   MovClienteAnulado.Amount := MovClienteAnulado.Amount + DetMovCliente.Amount;
                        //   MovClienteAnulado."Amount (LCY)" := MovClienteAnulado."Amount (LCY)" + DetMovCliente."Amount (LCY)";
                        //   MovClienteAnulado."Debit Amount" := MovClienteAnulado."Debit Amount" + DetMovCliente."Debit Amount";
                        //   MovClienteAnulado."Credit Amount" := MovClienteAnulado."Credit Amount" + DetMovCliente."Credit Amount";
                        //   MovClienteAnulado."Debit Amount (LCY)" := MovClienteAnulado."Debit Amount (LCY)" + DetMovCliente."Debit Amount (LCY)";
                        //   MovClienteAnulado."Credit Amount (LCY)" := MovClienteAnulado."Credit Amount (LCY)" + DetMovCliente."Credit Amount (LCY)";
                    END;
                    IF DetMovCliente."Entry Type" IN [DetMovCliente."Entry Type"::"Initial Entry", DetMovCliente."Entry Type"::Expenses]
                    THEN BEGIN
                        //   MovClienteAnulado."Original Amount" := MovClienteAnulado."Original Amount" + DetMovCliente.Amount;
                        //   MovClienteAnulado."Original Amount (LCY)" := MovClienteAnulado."Original Amount (LCY)" + DetMovCliente."Amount (LCY)";
                    END;
                    DetMovCliente.DELETE;
                UNTIL DetMovCliente.NEXT = 0;
            // MovClienteAnulado."Entry No." := NoMovAnulado;
            // MovClienteAnulado.Open :=FALSE;
            // MovClienteAnulado.INSERT;
            // MovDimensiones.SETRANGE(MovDimensiones."Table ID");
            // MovDimensiones.SETRANGE(MovDimensiones."Entry No.");
            // MovDimensiones.SETRANGE(MovDimensiones."Table ID",DATABASE::"Cust. Ledger Entry");
            // MovDimensiones.SETRANGE(MovDimensiones."Entry No.",MovCliente."Entry No.");
            // IF MovDimensiones.FIND('-') THEN
            //   MovDimensiones.DELETEALL;
            MovCliente.DELETE;
        END;
    END;

    /// <summary>
    /// SetDocFilter.
    /// </summary>
    /// <param name="pDocFilter">Text[250].</param>
    procedure SetDocFilter(pDocFilter: Text[250])
    begin

        //SetDocFilter

        wDocFilter := pDocFilter;
    end;

    /// <summary>
    /// CambiaClienteContabilidad.
    /// </summary>
    /// <param name="VAR GlEntry">Record "G/L Entry".</param>
    /// <param name="Cliente">Code[20].</param>
    /// <param name="ClienteV">Code[20].</param>
    /// <param name="VatR">Text.</param>
    procedure CambiaClienteContabilidad(VAR GlEntry: Record "G/L Entry"; Cliente: Code[20]; ClienteV: Code[20]; VatR: Text)
    begin
        //BorrarContabilidad

        IF GlEntry.FIND('-') THEN
            REPEAT

                //Customer
                IF CustEntry.GET(GlEntry."Entry No.") THEN BEGIN
                    CustEntry."Sell-to Customer No." := Clientev;
                    CustEntry."Customer No." := Cliente;
                    CustEntry.MODIFY;
                    DetCustEntry.SETCURRENTKEY("Cust. Ledger Entry No.", "Posting Date");
                    DetCustEntry.SETRANGE("Cust. Ledger Entry No.", CustEntry."Entry No.");
                    DetCustEntry.MODIFYALL(DetCustEntry."Customer No.", Cliente);
                    DocCartera.SETRANGE("Entry No.", CustEntry."Entry No.");
                    DocCartera.MODIFYALL(DocCartera."Account No.", Cliente);
                    ClosedCartera.SETRANGE("Entry No.", CustEntry."Entry No.");
                    ClosedCartera.MODIFYALL("Account No.", Cliente);
                    PostCartera.SETRANGE("Entry No.", CustEntry."Entry No.");
                    PostCartera.MODIFYALL("Account No.", Cliente);
                    // IF DocCartera.FIND('-') THEN DocCartera.DELETEALL;
                END;

                //Vendor
                // IF VendorEntry.GET(GlEntry."Entry No.") THEN BEGIN
                //     VendorEntry."Posting Date" := Fecha;
                //     VendorEntry.MODIFY;
                //     DetVendorEntry.SETCURRENTKEY("Vendor Ledger Entry No.", "Posting Date");
                //     DetVendorEntry.SETRANGE("Vendor Ledger Entry No.", VendorEntry."Entry No.");
                //     DetVendorEntry.MODIFYALL(DetVendorEntry."Posting Date", Fecha);
                //     DocCartera.SETRANGE("Entry No.", VendorEntry."Entry No.");
                //     DocCartera.MODIFYALL(DocCartera."Posting Date", Fecha);

                // END;

                // //Banco
                // IF BankEntry.GET(GlEntry."Entry No.") THEN BEGIN
                //     BankEntry."Posting Date" := Fecha;
                //     BankEntry.MODIFY;
                // END;

                //Vat Entry
                VatEntry.SETCURRENTKEY("Transaction No.");
                VatEntry.SETRANGE("Transaction No.", GlEntry."Transaction No.");
                IF VatEntry.FIND('-') THEN
                    REPEAT
                        VatEntry."Bill-to/Pay-to No." := Cliente;
                        VatEntry."VAT Registration No." := VatR;
                        VatEntry.MODIFY;
                    UNTIL VatEntry.NEXT = 0;
                GlEntry."Source No." := Cliente;
                GlEntry.MODIFY;
            // IF r45.GET(GlEntry."Transaction No.") THEN BEGIN
            //     r45."Posting Date" := Fecha;
            //     r45.MODIFY;
            // END;

            UNTIL GlEntry.NEXT = 0;
    end;

    /// <summary>
    /// CambiaProveedorContabilidad.
    /// </summary>
    /// <param name="VAR GlEntry">Record "G/L Entry".</param>
    /// <param name="Proveedor">Code[20].</param>
    /// <param name="ProveedorC">Code[20].</param>
    /// <param name="VatR">Text.</param>
    procedure CambiaProveedorContabilidad(VAR GlEntry: Record "G/L Entry"; Proveedor: Code[20]; ProveedorC: Code[20]; VatR: Text)
    begin
        //BorrarContabilidad

        IF GlEntry.FIND('-') THEN
            REPEAT

                //Customer
                IF VendorEntry.GET(GlEntry."Entry No.") THEN BEGIN
                    VendorEntry."Buy-from Vendor No." := ProveedorC;
                    VendorEntry."Vendor No." := Proveedor;
                    VendorEntry.MODIFY;
                    DetVendorEntry.SETCURRENTKEY("Vendor Ledger Entry No.", "Posting Date");
                    DetVendorEntry.SETRANGE("Vendor Ledger Entry No.", VendorEntry."Entry No.");
                    DetVendorEntry.MODIFYALL(DetVendorEntry."Vendor No.", Proveedor);
                    DocCartera.SETRANGE("Entry No.", VendorEntry."Entry No.");
                    DocCartera.MODIFYALL(DocCartera."Account No.", Proveedor);
                    ClosedCartera.SETRANGE("Entry No.", VendorEntry."Entry No.");
                    ClosedCartera.MODIFYALL("Account No.", Proveedor);
                    PostCartera.SETRANGE("Entry No.", VendorEntry."Entry No.");
                    PostCartera.MODIFYALL("Account No.", Proveedor);
                    // IF DocCartera.FIND('-') THEN DocCartera.DELETEALL;
                END;

                //Vendor
                // IF VendorEntry.GET(GlEntry."Entry No.") THEN BEGIN
                //     VendorEntry."Posting Date" := Fecha;
                //     VendorEntry.MODIFY;
                //     DetVendorEntry.SETCURRENTKEY("Vendor Ledger Entry No.", "Posting Date");
                //     DetVendorEntry.SETRANGE("Vendor Ledger Entry No.", VendorEntry."Entry No.");
                //     DetVendorEntry.MODIFYALL(DetVendorEntry."Posting Date", Fecha);
                //     DocCartera.SETRANGE("Entry No.", VendorEntry."Entry No.");
                //     DocCartera.MODIFYALL(DocCartera."Posting Date", Fecha);

                // END;

                // //Banco
                // IF BankEntry.GET(GlEntry."Entry No.") THEN BEGIN
                //     BankEntry."Posting Date" := Fecha;
                //     BankEntry.MODIFY;
                // END;

                //Vat Entry
                VatEntry.SETCURRENTKEY("Transaction No.");
                VatEntry.SETRANGE("Transaction No.", GlEntry."Transaction No.");
                IF VatEntry.FIND('-') THEN
                    REPEAT
                        VatEntry."Bill-to/Pay-to No." := Proveedor;
                        VatEntry."VAT Registration No." := VatR;
                        VatEntry.MODIFY;
                    UNTIL VatEntry.NEXT = 0;
                GlEntry."Source No." := Proveedor;
                GlEntry.MODIFY;
            // IF r45.GET(GlEntry."Transaction No.") THEN BEGIN
            //     r45."Posting Date" := Fecha;
            //     r45.MODIFY;
            // END;

            UNTIL GlEntry.NEXT = 0;
    end;

    Procedure CambiarClienteFacturaVenta(No: Code[20]; Cliente: Code[20])
    var
        rPostSalesLine: Record 113;
        Cust: Record Customer;
        Cust2: Record Customer;
        OldCli: Code[20];
        MovProducto: Record 32;
        ValueEntry: Record 5802;
        MovRecurso: Record "Res. Ledger Entry";

    begin
        //AnularFacturaVenta
        Cust.Get(Cliente);
        rPostSalesHeader.Get(No);
        wDocFilter := No;
        OldCli := rPostSalesHeader."Bill-to Customer No.";
        If Cust."Bill-to Customer No." = '' Then Cust."Bill-to Customer No." := Cust."No.";
        Cust2.Get(Cust."Bill-to Customer No.");
        rPostSalesHeader.SETFILTER("No.", wDocFilter);
        IF rPostSalesHeader.FIND('-') THEN BEGIN

            JobEntry.SETCURRENTKEY(JobEntry."Document No.", JobEntry."Posting Date", JobEntry.Type);
            JobEntry.SETRANGE(JobEntry."Document No.", rPostSalesHeader."No.");
            JobEntry.SETRANGE(JobEntry."Posting Date", rPostSalesHeader."Posting Date");
            JobEntry.SetRange("Entry Type", JobEntry."Entry Type"::Sale);
            rPostSalesLine.SetRange("Document No.", rPostSalesHeader."No.");
            If rPostSalesLine.FindFirst() Then
                repeat
                    If Job.Get(rPostSalesLine."Job No.") Then begin
                        If Job."Bill-to Customer No." <> Cust2."No." Then begin
                            Job."Bill-to Customer No." := Cust2."No.";
                            //
                            Cust2.TestField("Customer Posting Group");
                            Job."Bill-to Name" := Cust2.Name;
                            Job."Bill-to Name 2" := Cust2."Name 2";
                            Job."Bill-to Address" := Cust2.Address;
                            Job."Bill-to Address 2" := Cust2."Address 2";
                            Job."Bill-to City" := Cust2.City;
                            Job."Bill-to Post Code" := Cust2."Post Code";
                            Job."Bill-to Country/Region Code" := Cust2."Country/Region Code";
                            Job."Customer Disc. Group" := Cust2."Customer Disc. Group";
                            Job."Customer Price Group" := Cust2."Customer Price Group";
                            Job."Language Code" := Cust2."Language Code";
                            Job."Bill-to County" := Cust2.County;
                            Job.Reserve := Cust.Reserve;
                            Job.UpdateBillToContact(Job."Bill-to Customer No.");
                            Job.CopyDefaultDimensionsFromCustomer();
                            //
                            Job.Modify();
                        End;
                    end;
                    rPostSalesLine."Sell-to Customer No." := Cust."No.";
                    rPostSalesLine."Bill-to Customer No." := Cust2."No.";
                    rPostSalesLine.Modify();
                Until rPostSalesLine.Next() = 0;
            rPostSalesHeader."Sell-to Customer No." := Cust."No.";
            rPostSalesHeader."Bill-to Customer No." := Cust2."No.";
            rPostSalesHeader."Sell-to Customer Name" := Cust.Name;
            rPostSalesHeader."Sell-to Customer Name 2" := Cust."Name 2";
            rPostSalesHeader."Sell-to Phone No." := Cust."Phone No.";
            rPostSalesHeader."Sell-to E-Mail" := Cust."E-Mail";
            rPostSalesHeader."Sell-to Address" := Cust.Address;
            rPostSalesHeader."Sell-to Address 2" := Cust."Address 2";
            rPostSalesHeader."Sell-to City" := Cust.City;
            rPostSalesHeader."Sell-to Post Code" := Cust."Post Code";
            rPostSalesHeader."Sell-to County" := Cust.County;
            rPostSalesHeader."Sell-to Country/Region Code" := Cust."Country/Region Code";
            rPostSalesHeader."Sell-to Contact" := Cust.Contact;
            rPostSalesHeader."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
            rPostSalesHeader."VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            rPostSalesHeader."Tax Area Code" := Cust."Tax Area Code";
            rPostSalesHeader."Tax Liable" := Cust."Tax Liable";
            rPostSalesHeader."VAT Registration No." := Cust."VAT Registration No.";
            rPostSalesHeader."VAT Country/Region Code" := Cust."Country/Region Code";
            rPostSalesHeader."Bill-to Name" := Cust2.Name;
            rPostSalesHeader."Bill-to Name 2" := Cust2."Name 2";
            rPostSalesHeader."Bill-to Address" := Cust2.Address;
            rPostSalesHeader."Bill-to Address 2" := Cust2."Address 2";
            rPostSalesHeader."Bill-to City" := Cust2.City;
            rPostSalesHeader."Bill-to Post Code" := Cust2."Post Code";
            rPostSalesHeader."Bill-to County" := Cust2.County;
            rPostSalesHeader."Bill-to Country/Region Code" := Cust2."Country/Region Code";
            rPostSalesHeader."Bill-to Contact" := Cust2.Contact;
            rPostSalesHeader."Payment Terms Code" := Cust2."Payment Terms Code";
            rPostSalesHeader."Payment Method Code" := Cust2."Payment Method Code";
            rPostSalesHeader."VAT Bus. Posting Group" := Cust2."VAT Bus. Posting Group";
            rPostSalesHeader."VAT Country/Region Code" := Cust2."Country/Region Code";
            rPostSalesHeader."VAT Registration No." := Cust2."VAT Registration No.";
            rPostSalesHeader."Gen. Bus. Posting Group" := Cust2."Gen. Bus. Posting Group";
            rPostSalesHeader."Customer Posting Group" := Cust2."Customer Posting Group";
            rPostSalesHeader."Currency Code" := Cust2."Currency Code";
            rPostSalesHeader."Customer Price Group" := Cust2."Customer Price Group";
            rPostSalesHeader."Prices Including VAT" := Cust2."Prices Including VAT";
            rPostSalesHeader."Price Calculation Method" := Cust2.GetPriceCalculationMethod();
            rPostSalesHeader."Allow Line Disc." := Cust2."Allow Line Disc.";
            rPostSalesHeader."Invoice Disc. Code" := Cust2."Invoice Disc. Code";
            rPostSalesHeader."Customer Disc. Group" := Cust2."Customer Disc. Group";
            rPostSalesHeader."Language Code" := Cust2."Language Code";
            rPostSalesHeader."Tax Area Code" := Cust2."Tax Area Code";
            rPostSalesHeader."Tax Liable" := Cust2."Tax Liable";
            rPostSalesHeader."Cust. Bank Acc. Code" := Cust2."Preferred Bank Account Code";
            rPostSalesHeader.Modify();
            // rGlEntry.SETCURRENTKEY("Document No.","Posting Date");
            rGlEntry.SETRANGE("Document No.", rPostSalesHeader."No.");
            rGlEntry.SETRANGE(rGlEntry."Source No.", OldCli);

            //rGlEntry.SETRANGE("Posting Date" ,rPostSalesHeader."Posting Date");
            IF rGlEntry.FINDFIRST THEN BEGIN
                // rGlEntry2.SETCURRENTKEY(rGlEntry2."Transaction No.");
                // rGlEntry2.SETRANGE(rGlEntry2."Transaction No.",rGlEntry."Transaction No.");
                CambiaClienteContabilidad(rGlEntry, Cust2."No.", Cust."No.", Cust2."VAT Registration No.");
            END;
            rPostSalesHeader.MODIFY;
            MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
            MovProducto.SETRANGE("Document No.", wDocFilter);
            MovProducto.SETRANGE("Posting Date", rPostSalesHeader."Posting Date");
            MovProducto.SetRange("Source No.", OldCli);
            MovProducto.Modifyall("Source No.", Cliente);



            ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
            ValueEntry.SETRANGE("Document No.", wDocFilter);
            ValueEntry.SETRANGE("Posting Date", rPostSalesHeader."Posting Date");
            ValueEntry.SetRange("Source No.", OldCli);
            ValueEntry.Modifyall("Source No.", Cliente);


        END;
    end;

    Procedure CambiarClienteAbonoVenta(No: Code[20]; Cliente: Code[20])
    var
        rPostSalesLine: Record 115;
        Cust: Record Customer;
        Cust2: Record Customer;
        OldCli: Code[20];
        MovProducto: Record 32;
        ValueEntry: Record 5802;
        rPostSalesHeader: Record 114;
        MovRecurso: Record "Res. Ledger Entry";
    begin
        //AnularFacturaVenta
        Cust.Get(Cliente);
        rPostSalesHeader.Get(No);
        wDocFilter := No;
        OldCli := rPostSalesHeader."Bill-to Customer No.";
        If Cust."Bill-to Customer No." = '' Then Cust."Bill-to Customer No." := Cust."No.";
        Cust2.Get(Cust."Bill-to Customer No.");
        rPostSalesHeader.SETFILTER("No.", wDocFilter);
        IF rPostSalesHeader.FIND('-') THEN BEGIN

            JobEntry.SETCURRENTKEY(JobEntry."Document No.", JobEntry."Posting Date", JobEntry.Type);
            JobEntry.SETRANGE(JobEntry."Document No.", rPostSalesHeader."No.");
            JobEntry.SETRANGE(JobEntry."Posting Date", rPostSalesHeader."Posting Date");
            JobEntry.SetRange("Entry Type", JobEntry."Entry Type"::Sale);
            rPostSalesLine.SetRange("Document No.", rPostSalesHeader."No.");
            If rPostSalesLine.FindFirst() Then
                repeat
                    If Job.Get(rPostSalesLine."Job No.") Then begin
                        If Job."Bill-to Customer No." <> Cust2."No." Then begin
                            Job."Bill-to Customer No." := Cust2."No.";
                            //
                            Cust2.TestField("Customer Posting Group");
                            Job."Bill-to Name" := Cust2.Name;
                            Job."Bill-to Name 2" := Cust2."Name 2";
                            Job."Bill-to Address" := Cust2.Address;
                            Job."Bill-to Address 2" := Cust2."Address 2";
                            Job."Bill-to City" := Cust2.City;
                            Job."Bill-to Post Code" := Cust2."Post Code";
                            Job."Bill-to Country/Region Code" := Cust2."Country/Region Code";
                            Job."Customer Disc. Group" := Cust2."Customer Disc. Group";
                            Job."Customer Price Group" := Cust2."Customer Price Group";
                            Job."Language Code" := Cust2."Language Code";
                            Job."Bill-to County" := Cust2.County;
                            Job.Reserve := Cust.Reserve;
                            Job.UpdateBillToContact(Job."Bill-to Customer No.");
                            Job.CopyDefaultDimensionsFromCustomer();
                            //
                            Job.Modify();
                        End;
                    end;
                    rPostSalesLine."Sell-to Customer No." := Cust."No.";
                    rPostSalesLine."Bill-to Customer No." := Cust2."No.";
                    rPostSalesLine.Modify();
                Until rPostSalesLine.Next() = 0;
            rPostSalesHeader."Sell-to Customer No." := Cust."No.";
            rPostSalesHeader."Bill-to Customer No." := Cust2."No.";
            rPostSalesHeader."Sell-to Customer Name" := Cust.Name;
            rPostSalesHeader."Sell-to Customer Name 2" := Cust."Name 2";
            rPostSalesHeader."Sell-to Phone No." := Cust."Phone No.";
            rPostSalesHeader."Sell-to E-Mail" := Cust."E-Mail";
            rPostSalesHeader."Sell-to Address" := Cust.Address;
            rPostSalesHeader."Sell-to Address 2" := Cust."Address 2";
            rPostSalesHeader."Sell-to City" := Cust.City;
            rPostSalesHeader."Sell-to Post Code" := Cust."Post Code";
            rPostSalesHeader."Sell-to County" := Cust.County;
            rPostSalesHeader."Sell-to Country/Region Code" := Cust."Country/Region Code";
            rPostSalesHeader."Sell-to Contact" := Cust.Contact;
            rPostSalesHeader."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
            rPostSalesHeader."VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            rPostSalesHeader."Tax Area Code" := Cust."Tax Area Code";
            rPostSalesHeader."Tax Liable" := Cust."Tax Liable";
            rPostSalesHeader."VAT Registration No." := Cust."VAT Registration No.";
            rPostSalesHeader."VAT Country/Region Code" := Cust."Country/Region Code";
            rPostSalesHeader."Bill-to Name" := Cust2.Name;
            rPostSalesHeader."Bill-to Name 2" := Cust2."Name 2";
            rPostSalesHeader."Bill-to Address" := Cust2.Address;
            rPostSalesHeader."Bill-to Address 2" := Cust2."Address 2";
            rPostSalesHeader."Bill-to City" := Cust2.City;
            rPostSalesHeader."Bill-to Post Code" := Cust2."Post Code";
            rPostSalesHeader."Bill-to County" := Cust2.County;
            rPostSalesHeader."Bill-to Country/Region Code" := Cust2."Country/Region Code";
            rPostSalesHeader."Bill-to Contact" := Cust2.Contact;
            rPostSalesHeader."Payment Terms Code" := Cust2."Payment Terms Code";
            rPostSalesHeader."Payment Method Code" := Cust2."Payment Method Code";
            rPostSalesHeader."VAT Bus. Posting Group" := Cust2."VAT Bus. Posting Group";
            rPostSalesHeader."VAT Country/Region Code" := Cust2."Country/Region Code";
            rPostSalesHeader."VAT Registration No." := Cust2."VAT Registration No.";
            rPostSalesHeader."Gen. Bus. Posting Group" := Cust2."Gen. Bus. Posting Group";
            rPostSalesHeader."Customer Posting Group" := Cust2."Customer Posting Group";
            rPostSalesHeader."Currency Code" := Cust2."Currency Code";
            rPostSalesHeader."Customer Price Group" := Cust2."Customer Price Group";
            rPostSalesHeader."Prices Including VAT" := Cust2."Prices Including VAT";
            rPostSalesHeader."Price Calculation Method" := Cust2.GetPriceCalculationMethod();
            rPostSalesHeader."Allow Line Disc." := Cust2."Allow Line Disc.";
            rPostSalesHeader."Invoice Disc. Code" := Cust2."Invoice Disc. Code";
            rPostSalesHeader."Customer Disc. Group" := Cust2."Customer Disc. Group";
            rPostSalesHeader."Language Code" := Cust2."Language Code";
            rPostSalesHeader."Tax Area Code" := Cust2."Tax Area Code";
            rPostSalesHeader."Tax Liable" := Cust2."Tax Liable";
            rPostSalesHeader."Cust. Bank Acc. Code" := Cust2."Preferred Bank Account Code";
            rPostSalesHeader.Modify();
            // rGlEntry.SETCURRENTKEY("Document No.","Posting Date");
            rGlEntry.SETRANGE("Document No.", rPostSalesHeader."No.");
            rGlEntry.SETRANGE(rGlEntry."Source No.", OldCli);

            //rGlEntry.SETRANGE("Posting Date" ,rPostSalesHeader."Posting Date");
            IF rGlEntry.FINDFIRST THEN BEGIN
                // rGlEntry2.SETCURRENTKEY(rGlEntry2."Transaction No.");
                // rGlEntry2.SETRANGE(rGlEntry2."Transaction No.",rGlEntry."Transaction No.");
                CambiaClienteContabilidad(rGlEntry, Cust2."No.", Cust."No.", Cust2."VAT Registration No.");
            END;
            rPostSalesHeader.MODIFY;
            MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
            MovProducto.SETRANGE("Document No.", wDocFilter);
            MovProducto.SETRANGE("Posting Date", rPostSalesHeader."Posting Date");
            MovProducto.SetRange("Source No.", OldCli);
            MovProducto.Modifyall("Source No.", Cliente);



            ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
            ValueEntry.SETRANGE("Document No.", wDocFilter);
            ValueEntry.SETRANGE("Posting Date", rPostSalesHeader."Posting Date");
            ValueEntry.SetRange("Source No.", OldCli);
            ValueEntry.Modifyall("Source No.", Cliente);


        END;
    end;

    PROCEDURE AnulaMovProv(NoMov: Integer);
    VAR
        DetMovProveedor: Record 380;
    BEGIN
        IF MovProveedor.GET(NoMov) THEN BEGIN
            // MovProveedorAnulado.INIT;
            // MovProveedorAnulado.TRANSFERFIELDS(MovProveedor);
            DetMovProveedor.RESET;
            DetMovProveedor.SETCURRENTKEY("Vendor Ledger Entry No.", "Posting Date");
            DetMovProveedor.SETRANGE("Vendor Ledger Entry No.", MovProveedor."Entry No.");
            // $001-
            //DetMovProveedor.SETRANGE(DetMovProveedor."Posting Date",MovProveedor."Posting Date");
            // $001+
            IF DetMovProveedor.FIND('-') THEN
                REPEAT
                    IF NOT (DetMovProveedor."Entry Type" IN [DetMovProveedor."Entry Type"::Application,
                    DetMovProveedor."Entry Type"::"Appln. Rounding", DetMovProveedor."Entry Type"::"Correction of Remaining Amount"]) THEN BEGIN
                        //           MovProveedorAnulado.Amount := MovProveedorAnulado.Amount + DetMovProveedor.Amount;
                        //           MovProveedorAnulado."Amount (LCY)" := MovProveedorAnulado."Amount (LCY)" + DetMovProveedor."Amount (LCY)";
                        //           MovProveedorAnulado."Debit Amount" := MovProveedorAnulado."Debit Amount" + DetMovProveedor."Debit Amount";
                        //           MovProveedorAnulado."Credit Amount" := MovProveedorAnulado."Credit Amount" + DetMovProveedor."Credit Amount";
                        //           MovProveedorAnulado."Debit Amount (LCY)" := MovProveedorAnulado."Debit Amount (LCY)" + DetMovProveedor.
                        //   "Debit Amount (LCY)";
                        //           MovProveedorAnulado."Credit Amount (LCY)" := MovProveedorAnulado."Credit Amount (LCY)" + DetMovProveedor.
                        //   "Credit Amount (LCY)";
                    END;
                    IF DetMovProveedor."Entry Type" IN [DetMovProveedor."Entry Type"::"Initial Entry", DetMovProveedor."Entry Type"::Expenses]
                    THEN BEGIN
                        //   MovProveedorAnulado."Original Amount" := MovProveedorAnulado."Original Amount" + DetMovProveedor.Amount;
                        //   MovProveedorAnulado."Original Amount (LCY)" := MovProveedorAnulado."Original Amount (LCY)" +
                        // DetMovProveedor."Amount (LCY)";
                    END;
                    DetMovProveedor.DELETE;
                UNTIL DetMovProveedor.NEXT = 0;
            // MovProveedorAnulado."Entry No." := NoMovAnulado;
            // MovProveedorAnulado.Open :=FALSE;
            // MovProveedorAnulado.INSERT;
            // MovDimensiones.SETRANGE(MovDimensiones."Table ID");
            // MovDimensiones.SETRANGE(MovDimensiones."Entry No.");
            // MovDimensiones.SETRANGE(MovDimensiones."Table ID",DATABASE::"Vendor Ledger Entry");
            // MovDimensiones.SETRANGE(MovDimensiones."Entry No.",MovProveedor."Entry No.");
            // IF MovDimensiones.FIND('-') THEN
            //   MovDimensiones.DELETEALL;
            MovProveedor.DELETE;
        END;
    END;

    PROCEDURE AnulaMovIVA(NoMov: Integer);
    VAR
        MovIVA: Record 254;
    BEGIN
        IF MovIVA.GET(NoMov) THEN BEGIN
            // MovIVAAnulado.INIT;
            // MovIVAAnulado.TRANSFERFIELDS(MovIVA);
            // NoMovIVAAnulado := NoMovIVAAnulado + 1;
            // MovIVAAnulado."Entry No." := NoMovIVAAnulado;
            // MovIVAAnulado.INSERT;
            MovIVA.DELETE;
        END;
    END;

    PROCEDURE AnulaMovBanco(NoMov: Integer);
    VAR
        MovBanco: Record 271;
    BEGIN
        IF MovBanco.GET(NoMov) THEN BEGIN
            // MovBancoAnulado.INIT;
            // MovBancoAnulado.TRANSFERFIELDS(MovBanco);
            // MovBancoAnulado."Entry No." := NoMovAnulado;
            // MovBancoAnulado.INSERT;
            // MovDimensiones.SETRANGE(MovDimensiones."Table ID");
            // MovDimensiones.SETRANGE(MovDimensiones."Entry No.");
            // MovDimensiones.SETRANGE(MovDimensiones."Table ID",DATABASE::"Bank Account Ledger Entry");
            // MovDimensiones.SETRANGE(MovDimensiones."Entry No.",NoMovAnulado);
            // IF MovDimensiones.FIND('-') THEN
            //   MovDimensiones.DELETEALL;
            MovBanco.DELETE;
        END;
    END;

    PROCEDURE AnulaMovRecurso();
    VAR
        RegMovRecurso: Record 240;
        NoMovRecurso: Integer;
    BEGIN
        //   MovRecursoAnulado.LOCKTABLE;
        //   RegMovRecursoAnulado.LOCKTABLE;

        //   IF RegMovRecursoAnulado.FIND('+') THEN
        //     NoAsientoAnulado := RegMovRecursoAnulado."No." + 1
        //   ELSE
        NoAsientoAnulado := 1;

        //   RegMovRecursoAnulado.INIT;

        //   IF MovRecursoAnulado.FIND('+') THEN
        //     NoMovRecurso := MovRecursoAnulado."Entry No."
        //   ELSE
        NoMovRecurso := 0;

        //   RegMovRecursoAnulado."From Entry No." := NoMovRecurso + 1;

        REPEAT
            // MovRecursoAnulado.INIT;
            // MovRecursoAnulado.TRANSFERFIELDS(MovRecurso);
            NoMovRecurso := NoMovRecurso + 1;
        // MovRecursoAnulado."Entry No." := NoMovRecurso;
        // MovRecursoAnulado.INSERT;
        UNTIL MovRecurso.NEXT = 0;

        //   RegMovRecursoAnulado."To Entry No." := NoMovRecurso;

        RegMovRecurso.SETFILTER("From Entry No.", '<=%1', MovRecurso."Entry No.");
        RegMovRecurso.SETFILTER("To Entry No.", '>=%1', MovRecurso."Entry No.");
        RegMovRecurso.FIND('-');
        //   RegMovRecursoAnulado."No." := NoAsientoAnulado;
        //   RegMovRecursoAnulado."Creation Date" := RegMovRecurso."Creation Date";
        //   RegMovRecursoAnulado."Source Code" := RegMovRecurso."Source Code";
        //   RegMovRecursoAnulado."Journal Batch Name" := RegMovRecurso."Journal Batch Name";
        RegMovRecurso.DELETE;
        //   RegMovRecursoAnulado.INSERT;

        MovRecurso.DELETEALL;
    END;

    PROCEDURE AnulaMovProyecto();
    VAR
        RegMovProyecto: Record 241;
        NoMovProyecto: Integer;
    BEGIN
        //   MovProyectoAnulado.LOCKTABLE;
        //   RegMovProyectoAnulado.LOCKTABLE;

        //   IF RegMovProyectoAnulado.FIND('+') THEN
        //     NoAsientoAnulado := RegMovProyectoAnulado."No." + 1
        //   ELSE
        NoAsientoAnulado := 1;

        //   RegMovProyectoAnulado.INIT;

        //   IF MovProyectoAnulado.FIND('+') THEN
        //     NoMovProyecto := MovProyectoAnulado."Entry No."
        //   ELSE
        NoMovProyecto := 0;

        //   RegMovProyectoAnulado."From Entry No." := NoMovProyecto + 1;

        REPEAT
            // MovProyectoAnulado.INIT;
            // MovProyectoAnulado.TRANSFERFIELDS(MovProyecto);
            NoMovProyecto := NoMovProyecto + 1;
        // MovProyectoAnulado."Entry No." := NoMovProyecto;
        // MovProyectoAnulado.INSERT;
        //     MovDimensiones.SETRANGE(MovDimensiones."Table ID");
        //     MovDimensiones.SETRANGE(MovDimensiones."Entry No.");
        //     MovDimensiones.SETRANGE(MovDimensiones."Table ID",DATABASE::"Job Ledger Entry");
        //     MovDimensiones.SETRANGE(MovDimensiones."Entry No.",MovProyecto."Entry No.");
        //     IF MovDimensiones.FIND('-') THEN
        //       MovDimensiones.DELETEALL;
        UNTIL MovProyecto.NEXT = 0;

        //   RegMovProyectoAnulado."To Entry No." := NoMovProyecto;

        RegMovProyecto.SETFILTER("From Entry No.", '<=%1', MovProyecto."Entry No.");
        RegMovProyecto.SETFILTER("To Entry No.", '>=%1', MovProyecto."Entry No.");
        RegMovProyecto.FIND('-');
        //   RegMovProyectoAnulado."No." := NoAsientoAnulado;
        //   RegMovProyectoAnulado."Creation Date" := RegMovProyecto."Creation Date";
        //   RegMovProyectoAnulado."Source Code" := RegMovProyecto."Source Code";
        //   RegMovProyectoAnulado."Journal Batch Name" := RegMovProyecto."Journal Batch Name";
        //   RegMovProyectoAnulado."User ID" := USERID;
        RegMovProyecto.DELETE;
        //   RegMovProyectoAnulado.INSERT;

        MovProyecto.DELETEALL;
    END;

    PROCEDURE AnulaEfecto(Tipo: Option Receivable,Payable; NoMov: Integer);
    VAR
        NoVersion: Code[20];
    BEGIN
        IF Doc.GET(Tipo, NoMov) THEN BEGIN

            // LIS: MODIFICADO PARA QUE SE PUEDA ANULAR DOS VECES LA MISMA FACTURA CON EFECTOS
            // CabFactVtaAnulado.SETFILTER("No.",'>%1&<%2',STRSUBSTNO('%1/',Doc."Document No."),STRSUBSTNO('%1/',INCSTR(Doc."Document No.")));
            // IF CabFactVtaAnulado.FIND('+') THEN
            //   NoVersion := INCSTR(CabFactVtaAnulado."No.")
            // ELSE
            //NoVersion := "No." + '/1';                //FCL-05/10/04. Da error si son más de 10 anulaciones.
            NoVersion := Doc."Document No." + '/01';               //FCL-05/10/04.
                                                                   // FIN LIS

            // DocCerradoAnulado.INIT;
            // DocCerradoAnulado.TRANSFERFIELDS(Doc);
            // DocCerradoAnulado."Entry No." := NoMovAnulado;
            // DocCerradoAnulado."Document No." := NoVersion;  // LIS
            // DocCerradoAnulado.INSERT;
            Doc.DELETE;
        END;
    END;

    /// <summary>
    /// UpdatePurchline3.
    /// </summary>
    /// <param name="PurchLine">Record "Purchase Line".</param>
    /// <param name="UndoQty">Decimal.</param>
    /// <param name="UndoQtyBase">Decimal.</param>
    /// <param name="QtyFac">Decimal.</param>
    /// <param name="QtyFacBase">Decimal.</param>
    procedure UpdatePurchline3(PurchLine: Record "Purchase Line"; UndoQty: Decimal; UndoQtyBase: Decimal; QtyFac: Decimal; QtyFacBase: Decimal)
    var
        xPurchLine: Record "Purchase Line";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
    begin


        xPurchLine := PurchLine;
        CASE PurchLine."Document Type" OF
            PurchLine."Document Type"::"Return Order":
                BEGIN
                    PurchLine."Return Qty. Shipped" := UndoQty;
                    PurchLine."Return Qty. Shipped (Base)" := UndoQtyBase;
                    PurchLine.InitOutstanding;
                    PurchLine.InitQtyToShip;
                END;
            PurchLine."Document Type"::Order:
                BEGIN
                    IF PurchLine."Qty. per Unit of Measure" = 1 THEN BEGIN
                        QtyFacBase := QtyFac;
                        UndoQtyBase := UndoQty;
                    END;
                    PurchLine."Quantity Received" := UndoQty;
                    PurchLine."Qty. Received (Base)" := UndoQtyBase;
                    PurchLine."Qty. Rcd. Not Invoiced" := PurchLine."Quantity Received" - QtyFac;
                    PurchLine."Quantity Invoiced" := QtyFac;
                    PurchLine."Qty. Invoiced (Base)" := QtyFacBase;
                    PurchLine."Qty. Rcd. Not Invoiced (Base)" := PurchLine."Qty. Received (Base)" - QtyFacBase;
                    PurchLine."Qty. to Invoice" := PurchLine."Quantity Received" - QtyFac;
                    PurchLine."Qty. to Invoice (Base)" := PurchLine."Qty. Received (Base)" - QtyFacBase;
                    PurchLine.InitOutstanding;
                    PurchLine.InitQtyToReceive;
                END;
            ELSE
                PurchLine.FIELDERROR("Document Type");
        END;
        PurchLine.MODIFY;
        // END;

    end;
    // BEGIN
    // {
    //   $001 MNC 20/07/09 Se quita este filtro porque si no, no se eliminan todos los mov detalle necesarios (cliente y proveedor)
    //   $002 FCL 29/10/10 Modifico la lectura de reg.mov.contabilidad. Si se trata de una liquidación que no ha generado asiento
    //                     contable, el standard graba nº mov.desde incorrecto y al anular no lo encuentra.
    // }
    // END.
    /// <summary>
    /// AnularFacturaVenta.
    /// </summary>
    /// <param name="Var Rec">Record "Sales Invoice Header".</param>
    procedure AnularFacturaVenta(Var Rec: Record "Sales Invoice Header")
    var

        Text90000: Label '¿Confirma que desea anular la factura ?';
        Text90001: Label '¿Generar nueva factura?';
        Text90025: Label '¿Quiere conservar el número?';
        Text90026: Label '¿Usar fecha envio?';
        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas.';
        Text90003: Label 'No se puede anular una factura con efectos liquidados o pagos.';
        Text90004: Label 'No se puede anular una factura con documentos en remesa.';
        Text90005: Label 'No se puede anular una factura con documentos registrados.';
        Text90006: Label 'No se puede anular una factura con documentos cerrados.';
        Text90007: Label 'No se puede anular una factura con IVA liquidado.';
        Text90008: Label 'No se puede anular una factura anterior a un cierre.';
        Text90009: Label 'Compresión de datos previa efectuada para esa fecha.';
        Text90010: Label 'Necesita definir una serie de anulación de ventas';
        Text50000: Label 'Esta factura ha sido ajustada y no se puede anular.';
        CrearFactura: Boolean;
        ConfUsuario: Record "User Setup";
        FechaDesde: Date;
        CabVenta: Record 36;
        NoVersion: Integer;
        FechaHasta: Date;
        ConfContabilidad: Record 98;
        MCImporte: Decimal;
        MCImporteDL: Decimal;
        MCImportPen: Decimal;
        MCImportPenDL: Decimal;
        DocRegistrado: Record "Posted Cartera Doc.";
        PeriodoContable: Record "Accounting Period";
        CabVenta2: Record 36;
        MovProducto: Record 32;
        ValueEntry: Record "Value Entry";
        DocNo: Code[20];
        AnulaMovs: Codeunit "Cancel Entries";
        CopiarDocVenta: Report "Copy Sales Document";
        NewFromDocType: Enum "Sales Document Type From";
        ConfVentas: Record "Sales & Receivables Setup";
        LinComentVenta: Record 44;
        LinComentVenta2: Record 44;
        LinFactVenta: Record 113;
        LinAlbVenta: Record 111;
        AlbVente: Record 110;
        ConservarPostNo: Boolean;
        UsarFachaEnvio: Boolean;
    begin
        CrearFactura := CONFIRM(Text90001);
        IF NOT CONFIRM(Text90000, FALSE) THEN
            EXIT;
        ConservarPostNo := true;// CONFIRM(Text90025, true);
        //UsarFachaEnvio := CONFIRM(Text90026, false);
        If Rec.FindSet() Then
            repeat
                //with Rec Do Begin
                //001





                // Check that user can post to date
                IF USERID <> '' THEN
                    IF ConfUsuario.GET(USERID) THEN BEGIN
                        FechaDesde := ConfUsuario."Allow Posting From";
                        FechaHasta := ConfUsuario."Allow Posting To";
                    END;
                IF (FechaDesde = 0D) AND (FechaHasta = 0D) THEN BEGIN
                    ConfContabilidad.GET;
                    FechaDesde := ConfContabilidad."Allow Posting From";
                    FechaHasta := ConfContabilidad."Allow Posting To";
                END;
                IF FechaHasta = 0D THEN
                    FechaHasta := 99991231D;
                IF (Rec."Posting Date" < FechaDesde) OR (Rec."Posting Date" > FechaHasta) THEN
                    ERROR(Text90002);

                // Check payments and cartera
                MovCliente.RESET;
                MovCliente.SETCURRENTKEY("Document No.", "Document Type", "Customer No.");
                MovCliente.SETRANGE("Document No.", Rec."No.");
                MovCliente.SETRANGE("Customer No.", Rec."Bill-to Customer No.");
                MovCliente.SETRANGE("Document Type", MovCliente."Document Type"::Invoice);

                IF MovCliente.FIND('-') THEN BEGIN
                    MovCliente.CALCFIELDS(Amount, "Amount (LCY)");
                    MCImporte := MovCliente.Amount;
                    MCImporteDL := MovCliente."Amount (LCY)";
                    REPEAT
                        MovCliente.SETFILTER("Document Type", '%1|%2', MovCliente."Document Type"::Invoice, MovCliente."Document Type"::Bill);
                        MovCliente.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
                        MCImportPen := MCImportPen + MovCliente."Remaining Amount";
                        MCImportPenDL := MCImportPenDL + MovCliente."Remaining Amt. (LCY)";
                    UNTIL MovCliente.NEXT = 0;

                    IF (MCImporte <> MCImportPen) OR
                        (MCImporteDL <> MCImportPenDL) THEN
                        ERROR(Text90003)
                    ELSE BEGIN
                        //Frg 201005 añadimos clave
                        Doc.SETCURRENTKEY(Type, "Bill Gr./Pmt. Order No.", "Collection Agent", "Due Date",
                                        "Global Dimension 1 Code", "Global Dimension 2 Code",
                                        "Category Code", "Posting Date", "Document No.", Accepted, "Currency Code", "Document Type");

                        //Frg 201005
                        Doc.SETRANGE(Type, Doc.Type::Receivable);
                        Doc.SETRANGE("Document No.", Rec."No.");
                        Doc.SETFILTER("Bill Gr./Pmt. Order No.", '<>%1', '');
                        IF Doc.FIND('-') THEN
                            ERROR(Text90004);
                        //Frg 201005 añadimos clave
                        DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                        //Fin Frg 201005
                        DocRegistrado.SETRANGE(Type, DocRegistrado.Type::Receivable);
                        DocRegistrado.SETRANGE("Document No.", Rec."No.");
                        IF DocRegistrado.FIND('-') THEN
                            ERROR(Text90005);
                        //Frg 201005 añadimos clave
                        DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                        //Fin Frg 201005
                        DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
                        DocCerrado.SETRANGE("Document No.", Rec."No.");
                        IF DocCerrado.FIND('-') THEN
                            ERROR(Text90006);
                    END;
                END;

                // Check that VAT has not been applied
                // 001 Rendimiento en anular movimientos
                MovIVA.SETCURRENTKEY("Document No.", "Posting Date");

                MovIVA.SETRANGE("Document No.", Rec."No.");
                MovIVA.SETRANGE("Posting Date", Rec."Posting Date");
                MovIVA.SETRANGE(Closed, TRUE);
                IF MovIVA.FIND('-') THEN
                    ERROR(Text90007);

                // Check that there are not a closing date later posting date
                PeriodoContable.SETFILTER("Starting Date", '>=%1', Rec."Posting Date");
                PeriodoContable.SETRANGE(Closed, TRUE);
                IF PeriodoContable.FIND('-') THEN
                    ERROR(Text90008);

                // Check that ther are not a date compression to date
                // HistCompFechas.SETFILTER("Ending Date",'>=%1',"Posting Date");
                // IF HistCompFechas.FIND('-') THEN
                // ERROR(Text90009);

                // Create new invoice header
                // FCL-17/03/04. Esta opción da error, para que funcione hay que configurar aviso crédito=ninguno.
                IF CrearFactura THEN BEGIN
                    CabVenta2.INIT;
                    CabVenta2."Document Type" := CabVenta2."Document Type"::Invoice;

                    CabVenta2."No." := Rec."Pre-Assigned No.";
                    CabVenta2.INSERT(TRUE);
                    CabVenta2."Posting No." := '';               //FCL-30/03/04
                    CabVenta2.MODIFY;
                    CopiarDocVenta.SetSalesHeader(CabVenta2);
                    CopiarDocVenta.SetParameters(NewFromDocType::"Posted Invoice", Rec."No.", TRUE, FALSE);
                    CopiarDocVenta.USEREQUESTPage(FALSE);
                    CopiarDocVenta.RUN;
                    CabVenta2.GET(CabVenta2."Document Type", CabVenta2."No.");
                    If ConservarPostNo Then
                        CabVenta2."Posting No." := Rec."No.";
                    CabVenta2."Posting Description" := Rec."Posting Description";   // MNC 06-2-07
                    // if UsarFachaEnvio Then CabVenta2."Posting Date" := Rec."Shipment Date";
                    // if UsarFachaEnvio Then CabVenta2."Document Date" := Rec."Shipment Date";                     //$004
                    CabVenta2.MODIFY;
                    // CopiarLinsComent(LinComentVenta."Document Type"::"Posted Invoice",      //FCL-25/05/05
                    //                 LinComentVenta."Document Type"::Invoice,"No.",CabVenta2."No.");

                    LinComentVenta.SETRANGE("Document Type", LinComentVenta."Document Type"::"Posted Invoice");
                    LinComentVenta.SETRANGE("No.", Rec."No.");
                    IF LinComentVenta.FIND('-') THEN
                        REPEAT
                            LinComentVenta2 := LinComentVenta;
                            LinComentVenta2."Document Type" := LinComentVenta."Document Type"::Invoice;
                            LinComentVenta2."No." := CabVenta2."No.";
                            LinComentVenta2.INSERT;
                        UNTIL LinComentVenta.NEXT = 0;
                    LinComentVenta.DELETEALL;
                END;

                // Create a corrective Credit memo
                // ConfVentas.GET;
                // IF ConfVentas."Nº serie anulaciones" = '' THEN
                // ERROR(Text90010);

                // CabVenta.INIT;
                // CabVenta."Document Type" := CabVenta."Document Type"::"Credit Memo";
                // CabVenta."Obviar SII":=TRUE;
                // CabVenta.INSERT(TRUE);
                // CopiarDocVenta.SetSalesHeader(CabVenta);
                // CopiarDocVenta.SetParameters(7,"No.",TRUE,FALSE,TRUE);
                // CopiarDocVenta.USEREQUESTPage(FALSE);
                // CopiarDocVenta.RUN;

                // CabVenta.GET(CabVenta."Document Type",CabVenta."No.");
                // CabVenta."Payment Method Code" := '';
                // CabVenta."Posting No. Series" := ConfVentas."Nº serie anulaciones";
                // CabVenta.Correction := TRUE;
                // CabVenta.Anulación := TRUE;                            //FCL-17/03/04
                // CabVenta."Posting Description" := "Posting Description";   // MNC 06-2-07
                // CabVenta."Tipo factura rectificativa":='S';
                // CabVenta.MODIFY;

                // RegisVtas.RUN(CabVenta);

                // $002 -  LIS: ELIMINAMOS DOC. CARTERA CERRADO
                DocCerrado.RESET;
                //Frg 201005 Añadimos clave
                DocCerrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
                DocCerrado.SETRANGE("Document No.", Rec."No.");
                IF DocCerrado.FIND('-') THEN
                    DocCerrado.DELETE;

                // ELIMINAR VALORES DIMENSION
                // AnulaDimensiones.DeleteCarCerradoDimesions(DocDim.Type::Receivable,"No.");

                // $002 +


                // CabAbonoVentas.SETCURRENTKEY("Pre-Assigned No.");
                // CabAbonoVentas.SETRANGE("Pre-Assigned No.",CabVenta."No.");
                // CabAbonoVentas.FIND('-');

                // // Cancel Sales Invoice
                // CabFactVtaAnulado.SETFILTER("No.",'>%1&<%2',STRSUBSTNO('%1/',"No."),STRSUBSTNO('%1/',INCSTR("No.")));
                // IF CabFactVtaAnulado.FIND('+') THEN
                // NoVersion := INCSTR(CabFactVtaAnulado."No.")
                // ELSE
                // //NoVersion := "No." + '/1';                //FCL-05/10/04. Da error si son más de 10 anulaciones.
                // NoVersion := "No." + '/01';               //FCL-05/10/04.

                // CabFactVtaAnulado.INIT;
                // CabFactVtaAnulado.TRANSFERFIELDS(Rec);
                // CabFactVtaAnulado."No." := NoVersion;
                // CabFactVtaAnulado."Cancel by credit memo" := CabAbonoVentas."No.";
                // //CabFactVtaAnulado."Obviar SII":=TRUE;
                // CabFactVtaAnulado.INSERT;

                // LinFactVenta.SETRANGE("Document No.","No.");
                // IF LinFactVenta.FIND('-') THEN
                // REPEAT
                //     LinFactVentaAnulado.INIT;
                //     LinFactVentaAnulado.TRANSFERFIELDS(LinFactVenta);
                //     LinFactVentaAnulado."Document No." := NoVersion;
                //     LinFactVentaAnulado.INSERT;
                // UNTIL LinFactVenta.NEXT = 0;

                //Parche 240700
                // IF Comment THEN BEGIN
                // CopiarLinsComent(
                //     LinComentVenta."Document Type"::"Posted Invoice",
                //     LinComentVenta."Document Type"::Invoice,
                //     "No.",
                //     CabFactVtaAnulado."No.");
                // END;
                //Fin

                // AnulaDimensiones.DeleteDocDimensions("No.");
                // AnulaDimensiones.DeleteDimensions("No.","Posting Date");
                // AnulaDimensiones.DeleteCarDimesions(DocDim.Type::Receivable,"No.");

                // $002 -
                // AnulaDimensiones.DeleteDocDimensions(CabAbonoVentas."No.");
                // AnulaDimensiones.DeleteDimensions(CabAbonoVentas."No.",CabAbonoVentas."Posting Date");
                // $002 +
                LinFactVenta.SETRANGE("Document No.", Rec."No.");
                LinAlbVenta.SETRANGE("Document No.", Rec."No.");
                DocNo := Rec."No.";
                Rec.DELETE;
                If AlbVente.Get(DocNo) Then AlbVente.Delete();
                LinFactVenta.DELETEALL;
                LinAlbVenta.DELETEALL;

                // Cancel Credit memo note
                // CabAbonoVtaAnulado.INIT;
                // CabAbonoVtaAnulado.TRANSFERFIELDS(CabAbonoVentas);
                // CabAbonoVtaAnulado."No." := CabAbonoVentas."No.";

                // LinAbonoVentas.SETRANGE("Document No.",CabAbonoVentas."No.");
                // IF LinAbonoVentas.FIND('-') THEN
                // REPEAT
                //     LinAbonoVtaAnulado.INIT;
                //     LinAbonoVtaAnulado.TRANSFERFIELDS(LinAbonoVentas);
                //     LinAbonoVtaAnulado."Document No." := CabAbonoVentas."No.";
                //     LinAbonoVtaAnulado.INSERT;
                // UNTIL LinAbonoVentas.NEXT = 0;
                // //CabAbonoVtaAnulado."Obviar SII":=TRUE;
                // CabAbonoVtaAnulado.INSERT;
                // AnulaDimensiones.DeleteDocDimensions(CabAbonoVtaAnulado."No.");

                // CabAbonoVentas.DELETE;
                // LinAbonoVentas.DELETEALL;

                // Cancel invoice ledger entries
                MovContabilidad.SETCURRENTKEY("Document No.", "Posting Date");
                MovContabilidad.SETRANGE("Document No.", Rec."No.");

                MovContabilidad.SETRANGE("Posting Date", Rec."Posting Date");
                WHILE MovContabilidad.FIND('-') DO
                    AnulaMovs.RUN(MovContabilidad);

                // Cancel credit memo note ledg. entries
                // MovContabilidad.SETRANGE("Document No.",CabAbonoVentas."No.");
                // MovContabilidad.SETRANGE("Posting Date", CabAbonoVentas."Posting Date");
                // WHILE MovContabilidad.FIND('-') DO
                // AnulaMovs.RUN(MovContabilidad);

                //Cancel item ledger entries
                MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
                MovProducto.SETRANGE("Document No.", Rec."No.");
                MovProducto.SETRANGE("Posting Date", Rec."Posting Date");
                WHILE MovProducto.FIND('-') DO
                    MovProducto.MODIFYALL(MovProducto."Document No.", Rec."No.");


                ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
                ValueEntry.SETRANGE("Document No.", DocNo);
                ValueEntry.SETRANGE("Posting Date", Rec."Posting Date");
                WHILE ValueEntry.FIND('-') DO
                    ValueEntry.MODIFYALL("Document No.", Rec."No.");

            // // $002 -
            // {
            // //Frg 201005 añadimos clave
            // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
            // //Fin 201005
            // DetCustLedgEntry.SETRANGE("Document No.",CabAbonoVentas."No.");
            // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
            // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
            // DetCustLedgEntry.DELETEALL;

            // //Frg 201005 añadimos clave
            // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
            // //Fin 201005
            // DetCustLedgEntry.SETRANGE("Document No.",DocNo);
            // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
            // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
            // DetCustLedgEntry.DELETEALL;
            // }
            // $002 +
            until Rec.Next() = 0;
    end;

    /// <summary>
    /// AnularFacturaVentaGrupo.
    /// </summary>
    /// <param name="Var Rec">Record "Sales Invoice Header".</param>
    /// <param name="CrearFactura">Boolean.</param>
    /// <param name="ConservarPostNo">Boolean.</param>
    /// <param name="UsarFachaEnvio">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure AnularFacturaVentaGrupo(Var Rec: Record "Sales Invoice Header"; CrearFactura: Boolean;
    ConservarPostNo: Boolean;
        UsarFachaEnvio: Boolean): Boolean
    var

        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas.';
        Text90003: Label 'No se puede anular una factura con efectos liquidados o pagos.';
        Text90004: Label 'No se puede anular una factura con documentos en remesa.';
        Text90005: Label 'No se puede anular una factura con documentos registrados.';
        Text90006: Label 'No se puede anular una factura con documentos cerrados.';
        Text90007: Label 'No se puede anular una factura con IVA liquidado.';
        Text90008: Label 'No se puede anular una factura anterior a un cierre.';
        Text90009: Label 'Compresión de datos previa efectuada para esa fecha.';
        Text90010: Label 'Necesita definir una serie de anulación de ventas';
        Text50000: Label 'Esta factura ha sido ajustada y no se puede anular.';
        ConfUsuario: Record "User Setup";
        FechaDesde: Date;
        CabVenta: Record 36;
        NoVersion: Integer;
        FechaHasta: Date;
        ConfContabilidad: Record 98;
        MCImporte: Decimal;
        MCImporteDL: Decimal;
        MCImportPen: Decimal;
        MCImportPenDL: Decimal;
        DocRegistrado: Record "Posted Cartera Doc.";
        PeriodoContable: Record "Accounting Period";
        CabVenta2: Record 36;
        MovProducto: Record 32;
        ValueEntry: Record "Value Entry";
        DocNo: Code[20];
        AnulaMovs: Codeunit "Cancel Entries";
        CopiarDocVenta: Report "Copy Sales Document";
        NewFromDocType: Enum "Sales Document Type From";
        ConfVentas: Record "Sales & Receivables Setup";
        LinComentVenta: Record 44;
        LinComentVenta2: Record 44;
        LinFactVenta: Record 113;
        LinAlbVenta: Record 111;
        AlbVente: Record 110;

    begin



        // Check that user can post to date
        IF USERID <> '' THEN
            IF ConfUsuario.GET(USERID) THEN BEGIN
                FechaDesde := ConfUsuario."Allow Posting From";
                FechaHasta := ConfUsuario."Allow Posting To";
            END;
        IF (FechaDesde = 0D) AND (FechaHasta = 0D) THEN BEGIN
            ConfContabilidad.GET;
            FechaDesde := ConfContabilidad."Allow Posting From";
            FechaHasta := ConfContabilidad."Allow Posting To";
        END;
        IF FechaHasta = 0D THEN
            FechaHasta := 99991231D;
        IF (Rec."Posting Date" < FechaDesde) OR (Rec."Posting Date" > FechaHasta) THEN
            Exit(false);//Text90002);

        // Check payments and cartera
        MovCliente.RESET;
        MovCliente.SETCURRENTKEY("Document No.", "Document Type", "Customer No.");
        MovCliente.SETRANGE("Document No.", Rec."No.");
        MovCliente.SETRANGE("Customer No.", Rec."Bill-to Customer No.");
        MovCliente.SETRANGE("Document Type", MovCliente."Document Type"::Invoice);

        IF MovCliente.FIND('-') THEN BEGIN
            MovCliente.CALCFIELDS(Amount, "Amount (LCY)");
            MCImporte := MovCliente.Amount;
            MCImporteDL := MovCliente."Amount (LCY)";
            REPEAT
                MovCliente.SETFILTER("Document Type", '%1|%2', MovCliente."Document Type"::Invoice, MovCliente."Document Type"::Bill);
                MovCliente.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
                MCImportPen := MCImportPen + MovCliente."Remaining Amount";
                MCImportPenDL := MCImportPenDL + MovCliente."Remaining Amt. (LCY)";
            UNTIL MovCliente.NEXT = 0;

            IF (MCImporte <> MCImportPen) OR
                (MCImporteDL <> MCImportPenDL) THEN
                Exit(false)//ERROR(Text90003)
            ELSE BEGIN
                //Frg 201005 añadimos clave
                Doc.SETCURRENTKEY(Type, "Bill Gr./Pmt. Order No.", "Collection Agent", "Due Date",
                                "Global Dimension 1 Code", "Global Dimension 2 Code",
                                "Category Code", "Posting Date", "Document No.", Accepted, "Currency Code", "Document Type");

                //Frg 201005
                Doc.SETRANGE(Type, Doc.Type::Receivable);
                Doc.SETRANGE("Document No.", Rec."No.");
                Doc.SETFILTER("Bill Gr./Pmt. Order No.", '<>%1', '');
                IF Doc.FIND('-') THEN
                    Exit(false);//ERROR(Text90004);
                                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocRegistrado.SETRANGE(Type, DocRegistrado.Type::Receivable);
                DocRegistrado.SETRANGE("Document No.", Rec."No.");
                IF DocRegistrado.FIND('-') THEN
                    Exit(false);//ERROR(Text90005);
                                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
                DocCerrado.SETRANGE("Document No.", Rec."No.");
                IF DocCerrado.FIND('-') THEN
                    Exit(false);//ERROR(Text90006);
            END;
        END;

        // Check that VAT has not been applied
        // 001 Rendimiento en anular movimientos
        MovIVA.SETCURRENTKEY("Document No.", "Posting Date");

        MovIVA.SETRANGE("Document No.", Rec."No.");
        MovIVA.SETRANGE("Posting Date", Rec."Posting Date");
        MovIVA.SETRANGE(Closed, TRUE);
        IF MovIVA.FIND('-') THEN
            Exit(false);//ERROR(Text90007);

        // Check that there are not a closing date later posting date
        PeriodoContable.SETFILTER("Starting Date", '>=%1', Rec."Posting Date");
        PeriodoContable.SETRANGE(Closed, TRUE);
        IF PeriodoContable.FIND('-') THEN
            Exit(false);//ERROR(Text90008);

        // Check that ther are not a date compression to date
        // HistCompFechas.SETFILTER("Ending Date",'>=%1',"Posting Date");
        // IF HistCompFechas.FIND('-') THEN
        // ERROR(Text90009);

        // Create new invoice header
        // FCL-17/03/04. Esta opción da error, para que funcione hay que configurar aviso crédito=ninguno.
        IF CrearFactura THEN BEGIN
            CabVenta2.INIT;
            CabVenta2."Document Type" := CabVenta2."Document Type"::Invoice;

            CabVenta2."No." := Rec."Pre-Assigned No.";
            CabVenta2.INSERT(TRUE);
            CabVenta2."Posting No." := '';               //FCL-30/03/04
            CabVenta2.MODIFY;
            CopiarDocVenta.SetSalesHeader(CabVenta2);
            CopiarDocVenta.SetParameters(NewFromDocType::"Posted Invoice", Rec."No.", TRUE, FALSE);
            CopiarDocVenta.USEREQUESTPage(FALSE);
            CopiarDocVenta.RUN;
            CabVenta2.GET(CabVenta2."Document Type", CabVenta2."No.");
            If ConservarPostNo Then
                CabVenta2."Posting No." := Rec."No.";
            CabVenta2."Posting Description" := Rec."Posting Description";   // MNC 06-2-07
            if UsarFachaEnvio Then CabVenta2."Posting Date" := Rec."Shipment Date";
            if UsarFachaEnvio Then CabVenta2."Document Date" := Rec."Shipment Date";                     //$004
            CabVenta2.MODIFY;
            // CopiarLinsComent(LinComentVenta."Document Type"::"Posted Invoice",      //FCL-25/05/05
            //                 LinComentVenta."Document Type"::Invoice,"No.",CabVenta2."No.");

            LinComentVenta.SETRANGE("Document Type", LinComentVenta."Document Type"::"Posted Invoice");
            LinComentVenta.SETRANGE("No.", Rec."No.");
            IF LinComentVenta.FIND('-') THEN
                REPEAT
                    LinComentVenta2 := LinComentVenta;
                    LinComentVenta2."Document Type" := LinComentVenta."Document Type"::Invoice;
                    LinComentVenta2."No." := CabVenta2."No.";
                    LinComentVenta2.INSERT;
                UNTIL LinComentVenta.NEXT = 0;
            LinComentVenta.DELETEALL;
        END;

        // Create a corrective Credit memo
        // ConfVentas.GET;
        // IF ConfVentas."Nº serie anulaciones" = '' THEN
        // ERROR(Text90010);

        // CabVenta.INIT;
        // CabVenta."Document Type" := CabVenta."Document Type"::"Credit Memo";
        // CabVenta."Obviar SII":=TRUE;
        // CabVenta.INSERT(TRUE);
        // CopiarDocVenta.SetSalesHeader(CabVenta);
        // CopiarDocVenta.SetParameters(7,"No.",TRUE,FALSE,TRUE);
        // CopiarDocVenta.USEREQUESTPage(FALSE);
        // CopiarDocVenta.RUN;

        // CabVenta.GET(CabVenta."Document Type",CabVenta."No.");
        // CabVenta."Payment Method Code" := '';
        // CabVenta."Posting No. Series" := ConfVentas."Nº serie anulaciones";
        // CabVenta.Correction := TRUE;
        // CabVenta.Anulación := TRUE;                            //FCL-17/03/04
        // CabVenta."Posting Description" := "Posting Description";   // MNC 06-2-07
        // CabVenta."Tipo factura rectificativa":='S';
        // CabVenta.MODIFY;

        // RegisVtas.RUN(CabVenta);

        // $002 -  LIS: ELIMINAMOS DOC. CARTERA CERRADO
        DocCerrado.RESET;
        //Frg 201005 Añadimos clave
        DocCerrado.SETCURRENTKEY(Type, "Document No.");
        //Fin Frg 201005
        DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
        DocCerrado.SETRANGE("Document No.", Rec."No.");
        IF DocCerrado.FIND('-') THEN
            DocCerrado.DELETE;

        // ELIMINAR VALORES DIMENSION
        // AnulaDimensiones.DeleteCarCerradoDimesions(DocDim.Type::Receivable,"No.");

        // $002 +


        // CabAbonoVentas.SETCURRENTKEY("Pre-Assigned No.");
        // CabAbonoVentas.SETRANGE("Pre-Assigned No.",CabVenta."No.");
        // CabAbonoVentas.FIND('-');

        // // Cancel Sales Invoice
        // CabFactVtaAnulado.SETFILTER("No.",'>%1&<%2',STRSUBSTNO('%1/',"No."),STRSUBSTNO('%1/',INCSTR("No.")));
        // IF CabFactVtaAnulado.FIND('+') THEN
        // NoVersion := INCSTR(CabFactVtaAnulado."No.")
        // ELSE
        // //NoVersion := "No." + '/1';                //FCL-05/10/04. Da error si son más de 10 anulaciones.
        // NoVersion := "No." + '/01';               //FCL-05/10/04.

        // CabFactVtaAnulado.INIT;
        // CabFactVtaAnulado.TRANSFERFIELDS(Rec);
        // CabFactVtaAnulado."No." := NoVersion;
        // CabFactVtaAnulado."Cancel by credit memo" := CabAbonoVentas."No.";
        // //CabFactVtaAnulado."Obviar SII":=TRUE;
        // CabFactVtaAnulado.INSERT;

        // LinFactVenta.SETRANGE("Document No.","No.");
        // IF LinFactVenta.FIND('-') THEN
        // REPEAT
        //     LinFactVentaAnulado.INIT;
        //     LinFactVentaAnulado.TRANSFERFIELDS(LinFactVenta);
        //     LinFactVentaAnulado."Document No." := NoVersion;
        //     LinFactVentaAnulado.INSERT;
        // UNTIL LinFactVenta.NEXT = 0;

        //Parche 240700
        // IF Comment THEN BEGIN
        // CopiarLinsComent(
        //     LinComentVenta."Document Type"::"Posted Invoice",
        //     LinComentVenta."Document Type"::Invoice,
        //     "No.",
        //     CabFactVtaAnulado."No.");
        // END;
        //Fin

        // AnulaDimensiones.DeleteDocDimensions("No.");
        // AnulaDimensiones.DeleteDimensions("No.","Posting Date");
        // AnulaDimensiones.DeleteCarDimesions(DocDim.Type::Receivable,"No.");

        // $002 -
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVentas."No.");
        // AnulaDimensiones.DeleteDimensions(CabAbonoVentas."No.",CabAbonoVentas."Posting Date");
        // $002 +
        LinFactVenta.SETRANGE("Document No.", Rec."No.");
        LinAlbVenta.SETRANGE("Document No.", Rec."No.");
        DocNo := Rec."No.";
        Rec.DELETE;
        If AlbVente.Get(DocNo) Then AlbVente.Delete();
        LinFactVenta.DELETEALL;
        LinAlbVenta.DELETEALL;

        // Cancel Credit memo note
        // CabAbonoVtaAnulado.INIT;
        // CabAbonoVtaAnulado.TRANSFERFIELDS(CabAbonoVentas);
        // CabAbonoVtaAnulado."No." := CabAbonoVentas."No.";

        // LinAbonoVentas.SETRANGE("Document No.",CabAbonoVentas."No.");
        // IF LinAbonoVentas.FIND('-') THEN
        // REPEAT
        //     LinAbonoVtaAnulado.INIT;
        //     LinAbonoVtaAnulado.TRANSFERFIELDS(LinAbonoVentas);
        //     LinAbonoVtaAnulado."Document No." := CabAbonoVentas."No.";
        //     LinAbonoVtaAnulado.INSERT;
        // UNTIL LinAbonoVentas.NEXT = 0;
        // //CabAbonoVtaAnulado."Obviar SII":=TRUE;
        // CabAbonoVtaAnulado.INSERT;
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVtaAnulado."No.");

        // CabAbonoVentas.DELETE;
        // LinAbonoVentas.DELETEALL;

        // Cancel invoice ledger entries
        MovContabilidad.SETCURRENTKEY("Document No.", "Posting Date");
        MovContabilidad.SETRANGE("Document No.", Rec."No.");

        MovContabilidad.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovContabilidad.FIND('-') DO
            AnulaMovs.RUN(MovContabilidad);

        // Cancel credit memo note ledg. entries
        // MovContabilidad.SETRANGE("Document No.",CabAbonoVentas."No.");
        // MovContabilidad.SETRANGE("Posting Date", CabAbonoVentas."Posting Date");
        // WHILE MovContabilidad.FIND('-') DO
        // AnulaMovs.RUN(MovContabilidad);

        //Cancel item ledger entries
        MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
        MovProducto.SETRANGE("Document No.", Rec."No.");
        MovProducto.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovProducto.FIND('-') DO
            MovProducto.MODIFYALL(MovProducto."Document No.", Rec."No.");


        ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
        ValueEntry.SETRANGE("Document No.", DocNo);
        ValueEntry.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE ValueEntry.FIND('-') DO
            ValueEntry.MODIFYALL("Document No.", Rec."No.");

        // // $002 -
        // {
        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",CabAbonoVentas."No.");
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;

        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",DocNo);
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;
        // }
        // $002 +
        exit(true);
        //end;
    end;

    /// <summary>
    /// AnularAbonoVenta.
    /// </summary>
    /// <param name="Var Rec">Record "Sales Cr.Memo Header".</param>
    procedure AnularAbonoVenta(Var Rec: Record "Sales Cr.Memo Header")
    var

        Text90000: Label '¿Confirma que desea anular la abono ?';
        Text90001: Label '¿Generar nuevo abono?';
        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas.';
        Text90003: Label 'No se puede anular una abono con efectos liquidados o pagos.';
        Text90004: Label 'No se puede anular una abono con documentos en remesa.';
        Text90005: Label 'No se puede anular una abono con documentos registrados.';
        Text90006: Label 'No se puede anular una abono con documentos cerrados.';
        Text90007: Label 'No se puede anular una abono con IVA liquidado.';
        Text90008: Label 'No se puede anular una abono anterior a un cierre.';
        Text90009: Label 'Compresión de datos previa efectuada para esa fecha.';
        Text90010: Label 'Necesita definir una serie de anulación de ventas';
        Text50000: Label 'Esta abono ha sido ajustada y no se puede anular.';
        CrearFactura: Boolean;
        ConfUsuario: Record "User Setup";
        FechaDesde: Date;
        CabVenta: Record 36;
        NoVersion: Integer;
        FechaHasta: Date;
        ConfContabilidad: Record 98;
        MCImporte: Decimal;
        MCImporteDL: Decimal;
        MCImportPen: Decimal;
        MCImportPenDL: Decimal;
        DocRegistrado: Record "Posted Cartera Doc.";
        PeriodoContable: Record "Accounting Period";
        CabVenta2: Record 36;
        MovProducto: Record 32;
        ValueEntry: Record "Value Entry";
        DocNo: Code[20];
        AnulaMovs: Codeunit "Cancel Entries";
        CopiarDocVenta: Report "Copy Sales Document";
        NewFromDocType: Enum "Sales Document Type From";
        ConfVentas: Record "Sales & Receivables Setup";
        LinComentVenta: Record 44;
        LinComentVenta2: Record 44;
        LinFactVenta: Record 115;
    begin
        //with Rec Do Begin
        //001
        IF NOT CONFIRM(Text90000, FALSE) THEN
            EXIT;

        CrearFactura := CONFIRM(Text90001);

        // Check that user can post to date
        IF USERID <> '' THEN
            IF ConfUsuario.GET(USERID) THEN BEGIN
                FechaDesde := ConfUsuario."Allow Posting From";
                FechaHasta := ConfUsuario."Allow Posting To";
            END;
        IF (FechaDesde = 0D) AND (FechaHasta = 0D) THEN BEGIN
            ConfContabilidad.GET;
            FechaDesde := ConfContabilidad."Allow Posting From";
            FechaHasta := ConfContabilidad."Allow Posting To";
        END;
        IF FechaHasta = 0D THEN
            FechaHasta := 99991231D;
        IF (Rec."Posting Date" < FechaDesde) OR (Rec."Posting Date" > FechaHasta) THEN
            ERROR(Text90002);

        // Check payments and cartera
        MovCliente.RESET;
        MovCliente.SETCURRENTKEY("Document No.", "Document Type", "Customer No.");
        MovCliente.SETRANGE("Document No.", Rec."No.");
        MovCliente.SETRANGE("Customer No.", Rec."Bill-to Customer No.");
        MovCliente.SETRANGE("Document Type", MovCliente."Document Type"::"Credit Memo");

        IF MovCliente.FIND('-') THEN BEGIN
            MovCliente.CALCFIELDS(Amount, "Amount (LCY)");
            MCImporte := MovCliente.Amount;
            MCImporteDL := MovCliente."Amount (LCY)";
            REPEAT
                MovCliente.SETRANGE("Document Type", MovCliente."Document Type"::"Credit Memo");
                MovCliente.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
                MCImportPen := MCImportPen + MovCliente."Remaining Amount";
                MCImportPenDL := MCImportPenDL + MovCliente."Remaining Amt. (LCY)";
            UNTIL MovCliente.NEXT = 0;

            IF (MCImporte <> MCImportPen) OR
                (MCImporteDL <> MCImportPenDL) THEN
                ERROR(Text90003)
            ELSE BEGIN
                //Frg 201005 añadimos clave
                Doc.SETCURRENTKEY(Type, "Bill Gr./Pmt. Order No.", "Collection Agent", "Due Date",
                                "Global Dimension 1 Code", "Global Dimension 2 Code",
                                "Category Code", "Posting Date", "Document No.", Accepted, "Currency Code", "Document Type");

                //Frg 201005
                Doc.SETRANGE(Type, Doc.Type::Receivable);
                Doc.SETRANGE("Document No.", Rec."No.");
                Doc.SETFILTER("Bill Gr./Pmt. Order No.", '<>%1', '');
                IF Doc.FIND('-') THEN
                    ERROR(Text90004);
                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocRegistrado.SETRANGE(Type, DocRegistrado.Type::Receivable);
                DocRegistrado.SETRANGE("Document No.", Rec."No.");
                IF DocRegistrado.FIND('-') THEN
                    ERROR(Text90005);
                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
                DocCerrado.SETRANGE("Document No.", Rec."No.");
                IF DocCerrado.FIND('-') THEN
                    ERROR(Text90006);
            END;
        END;

        // Check that VAT has not been applied
        // 001 Rendimiento en anular movimientos
        MovIVA.SETCURRENTKEY("Document No.", "Posting Date");

        MovIVA.SETRANGE("Document No.", Rec."No.");
        MovIVA.SETRANGE("Posting Date", Rec."Posting Date");
        MovIVA.SETRANGE(Closed, TRUE);
        IF MovIVA.FIND('-') THEN
            ERROR(Text90007);

        // Check that there are not a closing date later posting date
        PeriodoContable.SETFILTER("Starting Date", '>=%1', Rec."Posting Date");
        PeriodoContable.SETRANGE(Closed, TRUE);
        IF PeriodoContable.FIND('-') THEN
            ERROR(Text90008);

        // Check that ther are not a date compression to date
        // HistCompFechas.SETFILTER("Ending Date",'>=%1',"Posting Date");
        // IF HistCompFechas.FIND('-') THEN
        // ERROR(Text90009);

        // Create new invoice header
        // FCL-17/03/04. Esta opción da error, para que funcione hay que configurar aviso crédito=ninguno.
        IF CrearFactura THEN BEGIN
            CabVenta2.INIT;
            CabVenta2."Document Type" := CabVenta2."Document Type"::"Credit Memo";
            CabVenta2."No." := Rec."Pre-Assigned No.";
            CabVenta2.INSERT(TRUE);
            CabVenta2."Posting No." := '';               //FCL-30/03/04
            CabVenta2.MODIFY;
            CopiarDocVenta.SetSalesHeader(CabVenta2);
            CopiarDocVenta.SetParameters(NewFromDocType::"Posted Credit Memo", Rec."No.", TRUE, FALSE);
            CopiarDocVenta.USEREQUESTPage(FALSE);
            CopiarDocVenta.RUN;
            CabVenta2.GET(CabVenta2."Document Type", CabVenta2."No.");
            CabVenta2."Posting No." := Rec."No.";
            CabVenta2."Posting Description" := Rec."Posting Description";   // MNC 06-2-07
            CabVenta2.MODIFY;
            // CopiarLinsComent(LinComentVenta."Document Type"::"Posted Invoice",      //FCL-25/05/05
            //                 LinComentVenta."Document Type"::Invoice,"No.",CabVenta2."No.");

            LinComentVenta.SETRANGE("Document Type", LinComentVenta."Document Type"::"Posted Credit Memo");
            LinComentVenta.SETRANGE("No.", Rec."No.");
            IF LinComentVenta.FIND('-') THEN
                REPEAT
                    LinComentVenta2 := LinComentVenta;
                    LinComentVenta2."Document Type" := LinComentVenta."Document Type"::"Credit Memo";
                    LinComentVenta2."No." := CabVenta2."No.";
                    LinComentVenta2.INSERT;
                UNTIL LinComentVenta.NEXT = 0;
            LinComentVenta.DELETEALL;
        END;

        // Create a corrective Credit memo
        // ConfVentas.GET;
        // IF ConfVentas."Nº serie anulaciones" = '' THEN
        // ERROR(Text90010);

        // CabVenta.INIT;
        // CabVenta."Document Type" := CabVenta."Document Type"::"Credit Memo";
        // CabVenta."Obviar SII":=TRUE;
        // CabVenta.INSERT(TRUE);
        // CopiarDocVenta.SetSalesHeader(CabVenta);
        // CopiarDocVenta.SetParameters(7,"No.",TRUE,FALSE,TRUE);
        // CopiarDocVenta.USEREQUESTPage(FALSE);
        // CopiarDocVenta.RUN;

        // CabVenta.GET(CabVenta."Document Type",CabVenta."No.");
        // CabVenta."Payment Method Code" := '';
        // CabVenta."Posting No. Series" := ConfVentas."Nº serie anulaciones";
        // CabVenta.Correction := TRUE;
        // CabVenta.Anulación := TRUE;                            //FCL-17/03/04
        // CabVenta."Posting Description" := "Posting Description";   // MNC 06-2-07
        // CabVenta."Tipo factura rectificativa":='S';
        // CabVenta.MODIFY;

        // RegisVtas.RUN(CabVenta);

        // $002 -  LIS: ELIMINAMOS DOC. CARTERA CERRADO
        DocCerrado.RESET;
        //Frg 201005 Añadimos clave
        DocCerrado.SETCURRENTKEY(Type, "Document No.");
        //Fin Frg 201005
        DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
        DocCerrado.SETRANGE("Document No.", Rec."No.");
        IF DocCerrado.FIND('-') THEN
            DocCerrado.DELETE;

        // ELIMINAR VALORES DIMENSION
        // AnulaDimensiones.DeleteCarCerradoDimesions(DocDim.Type::Receivable,"No.");

        // $002 +


        // CabAbonoVentas.SETCURRENTKEY("Pre-Assigned No.");
        // CabAbonoVentas.SETRANGE("Pre-Assigned No.",CabVenta."No.");
        // CabAbonoVentas.FIND('-');

        // // Cancel Sales Invoice
        // CabFactVtaAnulado.SETFILTER("No.",'>%1&<%2',STRSUBSTNO('%1/',"No."),STRSUBSTNO('%1/',INCSTR("No.")));
        // IF CabFactVtaAnulado.FIND('+') THEN
        // NoVersion := INCSTR(CabFactVtaAnulado."No.")
        // ELSE
        // //NoVersion := "No." + '/1';                //FCL-05/10/04. Da error si son más de 10 anulaciones.
        // NoVersion := "No." + '/01';               //FCL-05/10/04.

        // CabFactVtaAnulado.INIT;
        // CabFactVtaAnulado.TRANSFERFIELDS(Rec);
        // CabFactVtaAnulado."No." := NoVersion;
        // CabFactVtaAnulado."Cancel by credit memo" := CabAbonoVentas."No.";
        // //CabFactVtaAnulado."Obviar SII":=TRUE;
        // CabFactVtaAnulado.INSERT;

        // LinFactVenta.SETRANGE("Document No.","No.");
        // IF LinFactVenta.FIND('-') THEN
        // REPEAT
        //     LinFactVentaAnulado.INIT;
        //     LinFactVentaAnulado.TRANSFERFIELDS(LinFactVenta);
        //     LinFactVentaAnulado."Document No." := NoVersion;
        //     LinFactVentaAnulado.INSERT;
        // UNTIL LinFactVenta.NEXT = 0;

        //Parche 240700
        // IF Comment THEN BEGIN
        // CopiarLinsComent(
        //     LinComentVenta."Document Type"::"Posted Invoice",
        //     LinComentVenta."Document Type"::Invoice,
        //     "No.",
        //     CabFactVtaAnulado."No.");
        // END;
        //Fin

        // AnulaDimensiones.DeleteDocDimensions("No.");
        // AnulaDimensiones.DeleteDimensions("No.","Posting Date");
        // AnulaDimensiones.DeleteCarDimesions(DocDim.Type::Receivable,"No.");

        // $002 -
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVentas."No.");
        // AnulaDimensiones.DeleteDimensions(CabAbonoVentas."No.",CabAbonoVentas."Posting Date");
        // $002 +
        LinFactVenta.SETRANGE("Document No.", Rec."No.");
        DocNo := Rec."No.";
        Rec.DELETE;
        LinFactVenta.DELETEALL;

        // Cancel Credit memo note
        // CabAbonoVtaAnulado.INIT;
        // CabAbonoVtaAnulado.TRANSFERFIELDS(CabAbonoVentas);
        // CabAbonoVtaAnulado."No." := CabAbonoVentas."No.";

        // LinAbonoVentas.SETRANGE("Document No.",CabAbonoVentas."No.");
        // IF LinAbonoVentas.FIND('-') THEN
        // REPEAT
        //     LinAbonoVtaAnulado.INIT;
        //     LinAbonoVtaAnulado.TRANSFERFIELDS(LinAbonoVentas);
        //     LinAbonoVtaAnulado."Document No." := CabAbonoVentas."No.";
        //     LinAbonoVtaAnulado.INSERT;
        // UNTIL LinAbonoVentas.NEXT = 0;
        // //CabAbonoVtaAnulado."Obviar SII":=TRUE;
        // CabAbonoVtaAnulado.INSERT;
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVtaAnulado."No.");

        // CabAbonoVentas.DELETE;
        // LinAbonoVentas.DELETEALL;

        // Cancel invoice ledger entries
        MovContabilidad.SETCURRENTKEY("Document No.", "Posting Date");
        MovContabilidad.SETRANGE("Document No.", Rec."No.");

        MovContabilidad.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovContabilidad.FIND('-') DO
            AnulaMovs.RUN(MovContabilidad);

        // Cancel credit memo note ledg. entries
        // MovContabilidad.SETRANGE("Document No.",CabAbonoVentas."No.");
        // MovContabilidad.SETRANGE("Posting Date", CabAbonoVentas."Posting Date");
        // WHILE MovContabilidad.FIND('-') DO
        // AnulaMovs.RUN(MovContabilidad);

        //Cancel item ledger entries
        MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
        MovProducto.SETRANGE("Document No.", Rec."No.");
        MovProducto.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovProducto.FIND('-') DO
            MovProducto.MODIFYALL(MovProducto."Document No.", Rec."No.");


        ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
        ValueEntry.SETRANGE("Document No.", DocNo);
        ValueEntry.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE ValueEntry.FIND('-') DO
            ValueEntry.MODIFYALL("Document No.", Rec."No.");

        // // $002 -
        // {
        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",CabAbonoVentas."No.");
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;

        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",DocNo);
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;
        // }
        // $002 +
        //End;
    end;

    /// <summary>
    /// AnularFacturaCompra.
    /// </summary>
    /// <param name="Var Rec">Record 122.</param>
    procedure AnularFacturaCompra(Var Rec: Record 122)
    var

        Text90000: Label '¿Confirma que desea anular la factura ?';
        Text90001: Label '¿Generar nueva factura?';
        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas.';
        Text90003: Label 'No se puede anular una factura con efectos liquidados o pagos.';
        Text90004: Label 'No se puede anular una factura con documentos en remesa.';
        Text90005: Label 'No se puede anular una factura con documentos registrados.';
        Text90006: Label 'No se puede anular una factura con documentos cerrados.';
        Text90007: Label 'No se puede anular una factura con IVA liquidado.';
        Text90008: Label 'No se puede anular una factura anterior a un cierre.';
        Text90011: Label 'No se puede anular una factura con activos.';
        Text90009: Label 'Compresión de datos previa efectuada para esa fecha.';
        Text90010: Label 'Necesita definir una serie de anulación de ventas';
        Text50000: Label 'Esta factura ha sido ajustada y no se puede anular.';
        CrearFactura: Boolean;
        ConfUsuario: Record "User Setup";
        FechaDesde: Date;
        CabVenta: Record 38;
        NoVersion: Integer;
        FechaHasta: Date;
        ConfContabilidad: Record 98;
        MCImporte: Decimal;
        MCImporteDL: Decimal;
        MCImportPen: Decimal;
        MCImportPenDL: Decimal;
        DocRegistrado: Record "Posted Cartera Doc.";
        PeriodoContable: Record "Accounting Period";
        CabVenta2: Record 38;
        MovProducto: Record 32;
        ValueEntry: Record "Value Entry";
        DocNo: Code[20];
        AnulaMovs: Codeunit "Cancel Entries";
        CopiarDocVenta: Report "Copy Purchase Document";
        NewFromDocType: Enum "Sales Document Type From";
        ConfVentas: Record 311;
        LinComentVenta: Record "Purch. Comment Line";
        LinComentVenta2: Record "Purch. Comment Line";
        LinFactVenta: Record 123;
    begin
        // with Rec Do Begin
        //001
        // IF Ajustada THEN
        //     ERROR(Text50000);
        LinFactVenta.SETRANGE("Document No.", Rec."No.");
        LinFactVenta.SetRange(Type, LinFactVenta.Type::"Fixed Asset");
        IF LinFactVenta.FIND('-') THEN
            ERROR(Text90011);
        LinFactVenta.Reset;
        IF NOT CONFIRM(Text90000, FALSE) THEN
            EXIT;

        CrearFactura := CONFIRM(Text90001);

        // Check that user can post to date
        IF USERID <> '' THEN
            IF ConfUsuario.GET(USERID) THEN BEGIN
                FechaDesde := ConfUsuario."Allow Posting From";
                FechaHasta := ConfUsuario."Allow Posting To";
            END;
        IF (FechaDesde = 0D) AND (FechaHasta = 0D) THEN BEGIN
            ConfContabilidad.GET;
            FechaDesde := ConfContabilidad."Allow Posting From";
            FechaHasta := ConfContabilidad."Allow Posting To";
        END;
        IF FechaHasta = 0D THEN
            FechaHasta := 99991231D;
        IF (Rec."Posting Date" < FechaDesde) OR (Rec."Posting Date" > FechaHasta) THEN
            ERROR(Text90002);

        // Check payments and cartera
        MovProveedor.RESET;
        MovProveedor.SETCURRENTKEY("Document No.", "Document Type", "Vendor No.");
        MovProveedor.SETRANGE("Document No.", Rec."No.");
        MovProveedor.SETRANGE("Vendor No.", Rec."Pay-to Vendor No.");
        MovProveedor.SETRANGE("Document Type", MovProveedor."Document Type"::Invoice);

        IF MovProveedor.FIND('-') THEN BEGIN
            MovProveedor.CALCFIELDS(Amount, "Amount (LCY)");
            MCImporte := MovProveedor.Amount;
            MCImporteDL := MovProveedor."Amount (LCY)";
            REPEAT
                MovProveedor.SETFILTER("Document Type", '%1|%2', MovProveedor."Document Type"::Invoice, MovProveedor."Document Type"::Bill);
                MovProveedor.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
                MCImportPen := MCImportPen + MovProveedor."Remaining Amount";
                MCImportPenDL := MCImportPenDL + MovProveedor."Remaining Amt. (LCY)";
            UNTIL MovProveedor.NEXT = 0;

            IF (MCImporte <> MCImportPen) OR
                (MCImporteDL <> MCImportPenDL) THEN
                ERROR(Text90003)
            ELSE BEGIN
                //Frg 201005 añadimos clave
                Doc.SETCURRENTKEY(Type, "Bill Gr./Pmt. Order No.", "Collection Agent", "Due Date",
                                "Global Dimension 1 Code", "Global Dimension 2 Code",
                                "Category Code", "Posting Date", "Document No.", Accepted, "Currency Code", "Document Type");

                //Frg 201005
                Doc.SETRANGE(Type, Doc.Type::Payable);
                Doc.SETRANGE("Document No.", Rec."No.");
                Doc.SETFILTER("Bill Gr./Pmt. Order No.", '<>%1', '');
                IF Doc.FIND('-') THEN
                    ERROR(Text90004);
                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocRegistrado.SETRANGE(Type, DocRegistrado.Type::Payable);
                DocRegistrado.SETRANGE("Document No.", Rec."No.");
                IF DocRegistrado.FIND('-') THEN
                    ERROR(Text90005);
                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocCerrado.SETRANGE(Type, DocCerrado.Type::Payable);
                DocCerrado.SETRANGE("Document No.", Rec."No.");
                IF DocCerrado.FIND('-') THEN
                    ERROR(Text90006);
            END;
        END;

        // Check that VAT has not been applied
        // 001 Rendimiento en anular movimientos
        MovIVA.SETCURRENTKEY("Document No.", "Posting Date");

        MovIVA.SETRANGE("Document No.", Rec."No.");
        MovIVA.SETRANGE("Posting Date", Rec."Posting Date");
        MovIVA.SETRANGE(Closed, TRUE);
        IF MovIVA.FIND('-') THEN
            ERROR(Text90007);

        // Check that there are not a closing date later posting date
        PeriodoContable.SETFILTER("Starting Date", '>=%1', Rec."Posting Date");
        PeriodoContable.SETRANGE(Closed, TRUE);
        IF PeriodoContable.FIND('-') THEN
            ERROR(Text90008);

        // Check that ther are not a date compression to date
        // HistCompFechas.SETFILTER("Ending Date",'>=%1',"Posting Date");
        // IF HistCompFechas.FIND('-') THEN
        // ERROR(Text90009);

        // Create new invoice header
        // FCL-17/03/04. Esta opción da error, para que funcione hay que configurar aviso crédito=ninguno.
        IF CrearFactura THEN BEGIN
            CabVenta2.INIT;
            CabVenta2."Document Type" := CabVenta2."Document Type"::Invoice;
            CabVenta2."No." := Rec."Pre-Assigned No.";
            CabVenta2.INSERT(TRUE);
            //CabVenta2."Creado por anulación" := TRUE;
            CabVenta2."Posting No." := '';               //FCL-30/03/04
            CabVenta2.MODIFY;
            CopiarDocVenta.SetPurchHeader(CabVenta2);
            CopiarDocVenta.SetParameters(NewFromDocType::"Posted Invoice", Rec."No.", TRUE, FALSE);
            CopiarDocVenta.USEREQUESTPage(FALSE);
            CopiarDocVenta.RUN;
            CabVenta2.GET(CabVenta2."Document Type", CabVenta2."No.");
            CabVenta2."Posting No." := Rec."No.";
            CabVenta2."Posting Description" := Rec."Posting Description";   // MNC 06-2-07
                                                                            //CabVenta2."Factura prepago" := "Prepayment Invoice";        //$003
                                                                            //CabVenta2."Nº pedido prepago" := "Prepayment Order No.";    //$003
            CabVenta2.MODIFY;
            // CopiarLinsComent(LinComentVenta."Document Type"::"Posted Invoice",      //FCL-25/05/05
            //                 LinComentVenta."Document Type"::Invoice,"No.",CabVenta2."No.");

            LinComentVenta.SETRANGE("Document Type", LinComentVenta."Document Type"::"Posted Invoice");
            LinComentVenta.SETRANGE("No.", Rec."No.");
            IF LinComentVenta.FIND('-') THEN
                REPEAT
                    LinComentVenta2 := LinComentVenta;
                    LinComentVenta2."Document Type" := LinComentVenta."Document Type"::Invoice;
                    LinComentVenta2."No." := CabVenta2."No.";
                    LinComentVenta2.INSERT;
                UNTIL LinComentVenta.NEXT = 0;
            LinComentVenta.DELETEALL;
        END;

        // Create a corrective Credit memo
        // ConfVentas.GET;
        // IF ConfVentas."Nº serie anulaciones" = '' THEN
        // ERROR(Text90010);

        // CabVenta.INIT;
        // CabVenta."Document Type" := CabVenta."Document Type"::"Credit Memo";
        // CabVenta."Obviar SII":=TRUE;
        // CabVenta.INSERT(TRUE);
        // CopiarDocVenta.SetSalesHeader(CabVenta);
        // CopiarDocVenta.SetParameters(7,"No.",TRUE,FALSE,TRUE);
        // CopiarDocVenta.USEREQUESTPage(FALSE);
        // CopiarDocVenta.RUN;

        // CabVenta.GET(CabVenta."Document Type",CabVenta."No.");
        // CabVenta."Payment Method Code" := '';
        // CabVenta."Posting No. Series" := ConfVentas."Nº serie anulaciones";
        // CabVenta.Correction := TRUE;
        // CabVenta.Anulación := TRUE;                            //FCL-17/03/04
        // CabVenta."Posting Description" := "Posting Description";   // MNC 06-2-07
        // CabVenta."Tipo factura rectificativa":='S';
        // CabVenta.MODIFY;

        // RegisVtas.RUN(CabVenta);

        // $002 -  LIS: ELIMINAMOS DOC. CARTERA CERRADO
        DocCerrado.RESET;
        //Frg 201005 Añadimos clave
        DocCerrado.SETCURRENTKEY(Type, "Document No.");
        //Fin Frg 201005
        DocCerrado.SETRANGE(Type, DocCerrado.Type::Payable);
        DocCerrado.SETRANGE("Document No.", Rec."No.");
        IF DocCerrado.FIND('-') THEN
            DocCerrado.DELETE;

        // ELIMINAR VALORES DIMENSION
        // AnulaDimensiones.DeleteCarCerradoDimesions(DocDim.Type::Receivable,"No.");

        // $002 +


        // CabAbonoVentas.SETCURRENTKEY("Pre-Assigned No.");
        // CabAbonoVentas.SETRANGE("Pre-Assigned No.",CabVenta."No.");
        // CabAbonoVentas.FIND('-');

        // // Cancel Sales Invoice
        // CabFactVtaAnulado.SETFILTER("No.",'>%1&<%2',STRSUBSTNO('%1/',"No."),STRSUBSTNO('%1/',INCSTR("No.")));
        // IF CabFactVtaAnulado.FIND('+') THEN
        // NoVersion := INCSTR(CabFactVtaAnulado."No.")
        // ELSE
        // //NoVersion := "No." + '/1';                //FCL-05/10/04. Da error si son más de 10 anulaciones.
        // NoVersion := "No." + '/01';               //FCL-05/10/04.

        // CabFactVtaAnulado.INIT;
        // CabFactVtaAnulado.TRANSFERFIELDS(Rec);
        // CabFactVtaAnulado."No." := NoVersion;
        // CabFactVtaAnulado."Cancel by credit memo" := CabAbonoVentas."No.";
        // //CabFactVtaAnulado."Obviar SII":=TRUE;
        // CabFactVtaAnulado.INSERT;

        // LinFactVenta.SETRANGE("Document No.","No.");
        // IF LinFactVenta.FIND('-') THEN
        // REPEAT
        //     LinFactVentaAnulado.INIT;
        //     LinFactVentaAnulado.TRANSFERFIELDS(LinFactVenta);
        //     LinFactVentaAnulado."Document No." := NoVersion;
        //     LinFactVentaAnulado.INSERT;
        // UNTIL LinFactVenta.NEXT = 0;

        //Parche 240700
        // IF Comment THEN BEGIN
        // CopiarLinsComent(
        //     LinComentVenta."Document Type"::"Posted Invoice",
        //     LinComentVenta."Document Type"::Invoice,
        //     "No.",
        //     CabFactVtaAnulado."No.");
        // END;
        //Fin

        // AnulaDimensiones.DeleteDocDimensions("No.");
        // AnulaDimensiones.DeleteDimensions("No.","Posting Date");
        // AnulaDimensiones.DeleteCarDimesions(DocDim.Type::Receivable,"No.");

        // $002 -
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVentas."No.");
        // AnulaDimensiones.DeleteDimensions(CabAbonoVentas."No.",CabAbonoVentas."Posting Date");
        // $002 +
        LinFactVenta.SETRANGE("Document No.", Rec."No.");
        DocNo := Rec."No.";
        Rec.DELETE;
        LinFactVenta.DELETEALL;

        // Cancel Credit memo note
        // CabAbonoVtaAnulado.INIT;
        // CabAbonoVtaAnulado.TRANSFERFIELDS(CabAbonoVentas);
        // CabAbonoVtaAnulado."No." := CabAbonoVentas."No.";

        // LinAbonoVentas.SETRANGE("Document No.",CabAbonoVentas."No.");
        // IF LinAbonoVentas.FIND('-') THEN
        // REPEAT
        //     LinAbonoVtaAnulado.INIT;
        //     LinAbonoVtaAnulado.TRANSFERFIELDS(LinAbonoVentas);
        //     LinAbonoVtaAnulado."Document No." := CabAbonoVentas."No.";
        //     LinAbonoVtaAnulado.INSERT;
        // UNTIL LinAbonoVentas.NEXT = 0;
        // //CabAbonoVtaAnulado."Obviar SII":=TRUE;
        // CabAbonoVtaAnulado.INSERT;
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVtaAnulado."No.");

        // CabAbonoVentas.DELETE;
        // LinAbonoVentas.DELETEALL;

        // Cancel invoice ledger entries
        MovContabilidad.SETCURRENTKEY("Document No.", "Posting Date");
        MovContabilidad.SETRANGE("Document No.", Rec."No.");

        MovContabilidad.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovContabilidad.FIND('-') DO
            AnulaMovs.RUN(MovContabilidad);

        // Cancel credit memo note ledg. entries
        // MovContabilidad.SETRANGE("Document No.",CabAbonoVentas."No.");
        // MovContabilidad.SETRANGE("Posting Date", CabAbonoVentas."Posting Date");
        // WHILE MovContabilidad.FIND('-') DO
        // AnulaMovs.RUN(MovContabilidad);

        //Cancel item ledger entries
        MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
        MovProducto.SETRANGE("Document No.", Rec."No.");
        MovProducto.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovProducto.FIND('-') DO
            MovProducto.MODIFYALL(MovProducto."Document No.", Rec."No.");


        ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
        ValueEntry.SETRANGE("Document No.", DocNo);
        ValueEntry.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE ValueEntry.FIND('-') DO
            ValueEntry.MODIFYALL("Document No.", Rec."No.");

        // // $002 -
        // {
        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",CabAbonoVentas."No.");
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;

        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",DocNo);
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;
        // }
        // $002 +
        // End;
    end;

    /// <summary>
    /// AnularAbonoCompra.
    /// </summary>
    /// <param name="Var Rec">Record 124.</param>
    procedure AnularAbonoCompra(Var Rec: Record 124)
    var

        Text90000: Label '¿Confirma que desea anular la abono ?';
        Text90001: Label '¿Generar nuevo abono?';
        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas.';
        Text90003: Label 'No se puede anular una abono con efectos liquidados o pagos.';
        Text90004: Label 'No se puede anular una abono con documentos en remesa.';
        Text90005: Label 'No se puede anular una abono con documentos registrados.';
        Text90006: Label 'No se puede anular una abono con documentos cerrados.';
        Text90007: Label 'No se puede anular una abono con IVA liquidado.';
        Text90008: Label 'No se puede anular una abono anterior a un cierre.';
        Text90009: Label 'Compresión de datos previa efectuada para esa fecha.';
        Text90010: Label 'Necesita definir una serie de anulación de ventas';
        Text50000: Label 'Esta abono ha sido ajustada y no se puede anular.';
        CrearFactura: Boolean;
        ConfUsuario: Record "User Setup";
        FechaDesde: Date;
        CabVenta: Record 38;
        NoVersion: Integer;
        FechaHasta: Date;
        ConfContabilidad: Record 98;
        MCImporte: Decimal;
        MCImporteDL: Decimal;
        MCImportPen: Decimal;
        MCImportPenDL: Decimal;
        DocRegistrado: Record "Posted Cartera Doc.";
        PeriodoContable: Record "Accounting Period";
        CabVenta2: Record 38;
        MovProducto: Record 32;
        ValueEntry: Record "Value Entry";
        DocNo: Code[20];
        AnulaMovs: Codeunit "Cancel Entries";
        CopiarDocVenta: Report "Copy Purchase Document";
        NewFromDocType: Enum "Sales Document Type From";
        ConfVentas: Record 312;
        LinComentVenta: Record "Purch. Comment Line";
        LinComentVenta2: Record "Purch. Comment Line";
        LinFactVenta: Record 125;
    begin
        // with Rec Do Begin
        //001
        // IF Ajustada THEN
        //     ERROR(Text50000);

        IF NOT CONFIRM(Text90000, FALSE) THEN
            EXIT;

        CrearFactura := CONFIRM(Text90001);

        // Check that user can post to date
        IF USERID <> '' THEN
            IF ConfUsuario.GET(USERID) THEN BEGIN
                FechaDesde := ConfUsuario."Allow Posting From";
                FechaHasta := ConfUsuario."Allow Posting To";
            END;
        IF (FechaDesde = 0D) AND (FechaHasta = 0D) THEN BEGIN
            ConfContabilidad.GET;
            FechaDesde := ConfContabilidad."Allow Posting From";
            FechaHasta := ConfContabilidad."Allow Posting To";
        END;
        IF FechaHasta = 0D THEN
            FechaHasta := 99991231D;
        IF (Rec."Posting Date" < FechaDesde) OR (Rec."Posting Date" > FechaHasta) THEN
            ERROR(Text90002);

        // Check payments and cartera
        MovProveedor.RESET;
        MovProveedor.SETCURRENTKEY("Document No.", "Document Type", "Vendor No.");
        MovProveedor.SETRANGE("Document No.", Rec."No.");
        MovProveedor.SETRANGE("Vendor No.", Rec."Pay-to Vendor No.");
        MovProveedor.SETRANGE("Document Type", MovProveedor."Document Type"::"Credit Memo");

        IF MovProveedor.FIND('-') THEN BEGIN
            MovProveedor.CALCFIELDS(Amount, "Amount (LCY)");
            MCImporte := MovProveedor.Amount;
            MCImporteDL := MovProveedor."Amount (LCY)";
            REPEAT
                MovProveedor.SETRANGE("Document Type", MovProveedor."Document Type"::"Credit Memo");
                MovProveedor.CALCFIELDS("Remaining Amount", "Remaining Amt. (LCY)");
                MCImportPen := MCImportPen + MovProveedor."Remaining Amount";
                MCImportPenDL := MCImportPenDL + MovProveedor."Remaining Amt. (LCY)";
            UNTIL MovProveedor.NEXT = 0;

            IF (MCImporte <> MCImportPen) OR
                (MCImporteDL <> MCImportPenDL) THEN
                ERROR(Text90003)
            ELSE BEGIN
                //Frg 201005 añadimos clave
                Doc.SETCURRENTKEY(Type, "Bill Gr./Pmt. Order No.", "Collection Agent", "Due Date",
                                "Global Dimension 1 Code", "Global Dimension 2 Code",
                                "Category Code", "Posting Date", "Document No.", Accepted, "Currency Code", "Document Type");

                //Frg 201005
                Doc.SETRANGE(Type, Doc.Type::Payable);
                Doc.SETRANGE("Document No.", Rec."No.");
                Doc.SETFILTER("Bill Gr./Pmt. Order No.", '<>%1', '');
                IF Doc.FIND('-') THEN
                    ERROR(Text90004);
                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocRegistrado.SETRANGE(Type, DocRegistrado.Type::Payable);
                DocRegistrado.SETRANGE("Document No.", Rec."No.");
                IF DocRegistrado.FIND('-') THEN
                    ERROR(Text90005);
                //Frg 201005 añadimos clave
                DocRegistrado.SETCURRENTKEY(Type, "Document No.");
                //Fin Frg 201005
                DocCerrado.SETRANGE(Type, DocCerrado.Type::Payable);
                DocCerrado.SETRANGE("Document No.", Rec."No.");
                IF DocCerrado.FIND('-') THEN
                    ERROR(Text90006);
            END;
        END;

        // Check that VAT has not been applied
        // 001 Rendimiento en anular movimientos
        MovIVA.SETCURRENTKEY("Document No.", "Posting Date");

        MovIVA.SETRANGE("Document No.", Rec."No.");
        MovIVA.SETRANGE("Posting Date", Rec."Posting Date");
        MovIVA.SETRANGE(Closed, TRUE);
        IF MovIVA.FIND('-') THEN
            ERROR(Text90007);

        // Check that there are not a closing date later posting date
        PeriodoContable.SETFILTER("Starting Date", '>=%1', Rec."Posting Date");
        PeriodoContable.SETRANGE(Closed, TRUE);
        IF PeriodoContable.FIND('-') THEN
            ERROR(Text90008);

        // Check that ther are not a date compression to date
        // HistCompFechas.SETFILTER("Ending Date",'>=%1',"Posting Date");
        // IF HistCompFechas.FIND('-') THEN
        // ERROR(Text90009);

        // Create new invoice header
        // FCL-17/03/04. Esta opción da error, para que funcione hay que configurar aviso crédito=ninguno.
        IF CrearFactura THEN BEGIN
            CabVenta2.INIT;
            CabVenta2."Document Type" := CabVenta2."Document Type"::"Credit Memo";
            CabVenta2."No." := Rec."Pre-Assigned No.";
            CabVenta2.INSERT(TRUE);
            CabVenta2."Posting No." := '';               //FCL-30/03/04
            CabVenta2.MODIFY;
            CopiarDocVenta.SetPurchHeader(CabVenta2);
            CopiarDocVenta.SetParameters(NewFromDocType::"Posted Credit Memo", Rec."No.", TRUE, FALSE);
            CopiarDocVenta.USEREQUESTPage(FALSE);
            CopiarDocVenta.RUN;
            CabVenta2.GET(CabVenta2."Document Type", CabVenta2."No.");
            CabVenta2."Posting No." := Rec."No.";
            CabVenta2."Posting Description" := Rec."Posting Description";   // MNC 06-2-07
            CabVenta2.MODIFY;
            // CopiarLinsComent(LinComentVenta."Document Type"::"Posted Invoice",      //FCL-25/05/05
            //                 LinComentVenta."Document Type"::Invoice,"No.",CabVenta2."No.");

            LinComentVenta.SETRANGE("Document Type", LinComentVenta."Document Type"::"Posted Credit Memo");
            LinComentVenta.SETRANGE("No.", Rec."No.");
            IF LinComentVenta.FIND('-') THEN
                REPEAT
                    LinComentVenta2 := LinComentVenta;
                    LinComentVenta2."Document Type" := LinComentVenta."Document Type"::"Credit Memo";
                    LinComentVenta2."No." := CabVenta2."No.";
                    LinComentVenta2.INSERT;
                UNTIL LinComentVenta.NEXT = 0;
            LinComentVenta.DELETEALL;
        END;

        // Create a corrective Credit memo
        // ConfVentas.GET;
        // IF ConfVentas."Nº serie anulaciones" = '' THEN
        // ERROR(Text90010);

        // CabVenta.INIT;
        // CabVenta."Document Type" := CabVenta."Document Type"::"Credit Memo";
        // CabVenta."Obviar SII":=TRUE;
        // CabVenta.INSERT(TRUE);
        // CopiarDocVenta.SetSalesHeader(CabVenta);
        // CopiarDocVenta.SetParameters(7,"No.",TRUE,FALSE,TRUE);
        // CopiarDocVenta.USEREQUESTPage(FALSE);
        // CopiarDocVenta.RUN;

        // CabVenta.GET(CabVenta."Document Type",CabVenta."No.");
        // CabVenta."Payment Method Code" := '';
        // CabVenta."Posting No. Series" := ConfVentas."Nº serie anulaciones";
        // CabVenta.Correction := TRUE;
        // CabVenta.Anulación := TRUE;                            //FCL-17/03/04
        // CabVenta."Posting Description" := "Posting Description";   // MNC 06-2-07
        // CabVenta."Tipo factura rectificativa":='S';
        // CabVenta.MODIFY;

        // RegisVtas.RUN(CabVenta);

        // $002 -  LIS: ELIMINAMOS DOC. CARTERA CERRADO
        DocCerrado.RESET;
        //Frg 201005 Añadimos clave
        DocCerrado.SETCURRENTKEY(Type, "Document No.");
        //Fin Frg 201005
        DocCerrado.SETRANGE(Type, DocCerrado.Type::Receivable);
        DocCerrado.SETRANGE("Document No.", Rec."No.");
        IF DocCerrado.FIND('-') THEN
            DocCerrado.DELETE;

        // ELIMINAR VALORES DIMENSION
        // AnulaDimensiones.DeleteCarCerradoDimesions(DocDim.Type::Receivable,"No.");

        // $002 +


        // CabAbonoVentas.SETCURRENTKEY("Pre-Assigned No.");
        // CabAbonoVentas.SETRANGE("Pre-Assigned No.",CabVenta."No.");
        // CabAbonoVentas.FIND('-');

        // // Cancel Sales Invoice
        // CabFactVtaAnulado.SETFILTER("No.",'>%1&<%2',STRSUBSTNO('%1/',"No."),STRSUBSTNO('%1/',INCSTR("No.")));
        // IF CabFactVtaAnulado.FIND('+') THEN
        // NoVersion := INCSTR(CabFactVtaAnulado."No.")
        // ELSE
        // //NoVersion := "No." + '/1';                //FCL-05/10/04. Da error si son más de 10 anulaciones.
        // NoVersion := "No." + '/01';               //FCL-05/10/04.

        // CabFactVtaAnulado.INIT;
        // CabFactVtaAnulado.TRANSFERFIELDS(Rec);
        // CabFactVtaAnulado."No." := NoVersion;
        // CabFactVtaAnulado."Cancel by credit memo" := CabAbonoVentas."No.";
        // //CabFactVtaAnulado."Obviar SII":=TRUE;
        // CabFactVtaAnulado.INSERT;

        // LinFactVenta.SETRANGE("Document No.","No.");
        // IF LinFactVenta.FIND('-') THEN
        // REPEAT
        //     LinFactVentaAnulado.INIT;
        //     LinFactVentaAnulado.TRANSFERFIELDS(LinFactVenta);
        //     LinFactVentaAnulado."Document No." := NoVersion;
        //     LinFactVentaAnulado.INSERT;
        // UNTIL LinFactVenta.NEXT = 0;

        //Parche 240700
        // IF Comment THEN BEGIN
        // CopiarLinsComent(
        //     LinComentVenta."Document Type"::"Posted Invoice",
        //     LinComentVenta."Document Type"::Invoice,
        //     "No.",
        //     CabFactVtaAnulado."No.");
        // END;
        //Fin

        // AnulaDimensiones.DeleteDocDimensions("No.");
        // AnulaDimensiones.DeleteDimensions("No.","Posting Date");
        // AnulaDimensiones.DeleteCarDimesions(DocDim.Type::Receivable,"No.");

        // $002 -
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVentas."No.");
        // AnulaDimensiones.DeleteDimensions(CabAbonoVentas."No.",CabAbonoVentas."Posting Date");
        // $002 +
        LinFactVenta.SETRANGE("Document No.", Rec."No.");
        DocNo := Rec."No.";
        Rec.DELETE;
        LinFactVenta.DELETEALL;

        // Cancel Credit memo note
        // CabAbonoVtaAnulado.INIT;
        // CabAbonoVtaAnulado.TRANSFERFIELDS(CabAbonoVentas);
        // CabAbonoVtaAnulado."No." := CabAbonoVentas."No.";

        // LinAbonoVentas.SETRANGE("Document No.",CabAbonoVentas."No.");
        // IF LinAbonoVentas.FIND('-') THEN
        // REPEAT
        //     LinAbonoVtaAnulado.INIT;
        //     LinAbonoVtaAnulado.TRANSFERFIELDS(LinAbonoVentas);
        //     LinAbonoVtaAnulado."Document No." := CabAbonoVentas."No.";
        //     LinAbonoVtaAnulado.INSERT;
        // UNTIL LinAbonoVentas.NEXT = 0;
        // //CabAbonoVtaAnulado."Obviar SII":=TRUE;
        // CabAbonoVtaAnulado.INSERT;
        // AnulaDimensiones.DeleteDocDimensions(CabAbonoVtaAnulado."No.");

        // CabAbonoVentas.DELETE;
        // LinAbonoVentas.DELETEALL;

        // Cancel invoice ledger entries
        MovContabilidad.SETCURRENTKEY("Document No.", "Posting Date");
        MovContabilidad.SETRANGE("Document No.", Rec."No.");

        MovContabilidad.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovContabilidad.FIND('-') DO
            AnulaMovs.RUN(MovContabilidad);

        // Cancel credit memo note ledg. entries
        // MovContabilidad.SETRANGE("Document No.",CabAbonoVentas."No.");
        // MovContabilidad.SETRANGE("Posting Date", CabAbonoVentas."Posting Date");
        // WHILE MovContabilidad.FIND('-') DO
        // AnulaMovs.RUN(MovContabilidad);

        //Cancel item ledger entries
        MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
        MovProducto.SETRANGE("Document No.", Rec."No.");
        MovProducto.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE MovProducto.FIND('-') DO
            MovProducto.MODIFYALL(MovProducto."Document No.", Rec."No.");


        ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
        ValueEntry.SETRANGE("Document No.", DocNo);
        ValueEntry.SETRANGE("Posting Date", Rec."Posting Date");
        WHILE ValueEntry.FIND('-') DO
            ValueEntry.MODIFYALL("Document No.", Rec."No.");

        // // $002 -
        // {
        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",CabAbonoVentas."No.");
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;

        // //Frg 201005 añadimos clave
        // DetCustLedgEntry.SETCURRENTKEY("Document No.","Document Type","Posting Date","Customer No.");
        // //Fin 201005
        // DetCustLedgEntry.SETRANGE("Document No.",DocNo);
        // DetCustLedgEntry.SETRANGE("Posting Date",CabAbonoVentas."Posting Date");
        // DetCustLedgEntry.SETRANGE("Customer No.",CabAbonoVentas."Bill-to Customer No.");
        // DetCustLedgEntry.DELETEALL;
        // }
        // $002 +
        // End;
    end;

    Procedure CambiarFechaFacturaCompra(Fecha: Date)
    begin
        //AnularFacturaCompra

        rPostPurchHeader.SETFILTER("No.", wDocFilter);
        IF rPostPurchHeader.FIND('-') THEN BEGIN

            JobEntry.SETCURRENTKEY(JobEntry."Document No.", JobEntry."Posting Date", JobEntry.Type);
            JobEntry.SETRANGE(JobEntry."Document No.", rPostPurchHeader."No.");
            JobEntry.SETRANGE(JobEntry."Posting Date", rPostPurchHeader."Posting Date");
            JobEntry.SETRANGE(JobEntry."Entry Type", JobEntry."Entry Type"::Usage);
            JobEntry.MODIFYALL(JobEntry."Posting Date", Fecha);

            // rGlEntry.SETCURRENTKEY("Document No.","Posting Date");
            rGlEntry.SETRANGE("Document No.", rPostPurchHeader."No.");
            rGlEntry.SETRANGE(rGlEntry."Source No.", rPostPurchHeader."Pay-to Vendor No.");
            //rGlEntry.SETRANGE("Posting Date" ,rPostPurchHeader."Posting Date");
            IF rGlEntry.FINDFIRST THEN BEGIN
                // rGlEntry2.SETCURRENTKEY(rGlEntry2."Transaction No.");
                // rGlEntry2.SETRANGE(rGlEntry2."Transaction No.",rGlEntry."Transaction No.");
                CambiaFechaContabilidad(rGlEntry, Fecha);
            END;
            rPostPurchHeader."Posting Date" := Fecha;
            rPostPurchHeader."Document Date" := Fecha;
            rPostPurchHeader."VAT Reporting Date" := Fecha;
            rPostPurchHeader.MODIFY;


        END;
    end;

    Procedure CambiarProveedorFacturaCompra(Provedor: Code[20]; No: Code[20])
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        OldProv: Code[20];
        rPostSalesLine: Record 123;
        MovProducto: Record 32;
        ValueEntry: Record 5802;
    begin
        //AnularFacturaCompra
        Vendor.Get(Provedor);
        rPostPurchHeader.Get(No);
        wDocFilter := No;
        OldProv := rPostPurchHeader."Pay-to Vendor No.";
        If Vendor."Pay-to Vendor No." = '' Then Vendor."Pay-to Vendor No." := Vendor."No.";
        Vendor2.Get(Vendor."Pay-to Vendor No.");
        rPostPurchHeader.SETFILTER("No.", wDocFilter);
        rPostSalesLine.SetFilter("Document No.", wDocFilter);
        IF rPostPurchHeader.FIND('-') THEN BEGIN
            rPostSalesLine.FindFirst();
            repeat
                rPostSalesLine."Buy-from vendor No." := Vendor."No.";
                rPostSalesLine."Pay-to Vendor No." := Vendor2."No.";
                rPostSalesLine.Modify();
            Until rPostSalesLine.Next() = 0;
            rPostPurchHeader."Buy-from Vendor No." := Vendor."No.";
            rPostPurchHeader."Pay-to Vendor No." := Vendor2."No.";
            rPostPurchHeader."Buy-from Vendor Name" := Vendor.Name;
            rPostPurchHeader."Buy-from Vendor Name 2" := Vendor."Name 2";
            rPostPurchHeader."Buy-from Address" := Vendor.Address;
            rPostPurchHeader."Buy-from Address 2" := Vendor."Address 2";
            rPostPurchHeader."Buy-from City" := Vendor.City;
            rPostPurchHeader."Buy-from Post Code" := Vendor."Post Code";
            rPostPurchHeader."Buy-from County" := Vendor.County;
            rPostPurchHeader."Buy-from Country/Region Code" := Vendor."Country/Region Code";
            rPostPurchHeader."Buy-from Contact" := Vendor.Contact;
            rPostPurchHeader."Gen. Bus. Posting Group" := Vendor."Gen. Bus. Posting Group";
            rPostPurchHeader."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
            rPostPurchHeader."Tax Area Code" := Vendor."Tax Area Code";
            rPostPurchHeader."Tax Liable" := Vendor."Tax Liable";
            rPostPurchHeader."VAT Registration No." := Vendor."VAT Registration No.";
            rPostPurchHeader."VAT Country/Region Code" := Vendor."Country/Region Code";
            rPostPurchHeader."Pay-to Name" := Vendor2.Name;
            rPostPurchHeader."Pay-to Name 2" := Vendor2."Name 2";
            rPostPurchHeader."Pay-to Address" := Vendor2.Address;
            rPostPurchHeader."Pay-to Address 2" := Vendor2."Address 2";
            rPostPurchHeader."Pay-to City" := Vendor2.City;
            rPostPurchHeader."Pay-to Post Code" := Vendor2."Post Code";
            rPostPurchHeader."Pay-to County" := Vendor2.County;
            rPostPurchHeader."Pay-to Country/Region Code" := Vendor2."Country/Region Code";
            rPostPurchHeader."Pay-to Contact" := Vendor2.Contact;
            rPostPurchHeader."Payment Terms Code" := Vendor2."Payment Terms Code";
            rPostPurchHeader."Payment Method Code" := Vendor2."Payment Method Code";
            rPostPurchHeader."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
            rPostPurchHeader."VAT Country/Region Code" := Vendor2."Country/Region Code";
            rPostPurchHeader."VAT Registration No." := Vendor2."VAT Registration No.";
            rPostPurchHeader."Gen. Bus. Posting Group" := Vendor2."Gen. Bus. Posting Group";
            rPostPurchHeader."Vendor Posting Group" := Vendor2."Vendor Posting Group";
            rPostPurchHeader."Currency Code" := Vendor2."Currency Code";
            rPostPurchHeader."Prices Including VAT" := Vendor2."Prices Including VAT";
            rPostPurchHeader."Price Calculation Method" := Vendor2.GetPriceCalculationMethod();
            rPostPurchHeader."Invoice Disc. Code" := Vendor2."Invoice Disc. Code";
            rPostPurchHeader."Language Code" := Vendor2."Language Code";
            rPostPurchHeader."Tax Area Code" := Vendor2."Tax Area Code";
            rPostPurchHeader."Tax Liable" := Vendor2."Tax Liable";
            rPostPurchHeader."Vendor Bank Acc. Code" := Vendor2."Preferred Bank Account Code";
            rPostPurchHeader.Modify();
            // rGlEntry.SETCURRENTKEY("Document No.","Posting Date");
            rGlEntry.SETRANGE("Document No.", rPostPurchHeader."No.");
            rGlEntry.SETRANGE(rGlEntry."Source No.", OldProv);

            //rGlEntry.SETRANGE("Posting Date" ,rPostPurchHeader."Posting Date");
            IF rGlEntry.FINDFIRST THEN BEGIN
                // rGlEntry2.SETCURRENTKEY(rGlEntry2."Transaction No.");
                // rGlEntry2.SETRANGE(rGlEntry2."Transaction No.",rGlEntry."Transaction No.");
                CambiaProveedorContabilidad(rGlEntry, Vendor2."No.", Vendor."No.", Vendor2."VAT Registration No.");
            END;
            rPostPurchHeader.MODIFY;
            MovProducto.SETCURRENTKEY("Document No.", "Posting Date");
            MovProducto.SETRANGE("Document No.", wDocFilter);
            MovProducto.SETRANGE("Posting Date", rPostPurchHeader."Posting Date");
            MovProducto.SetRange("Source No.", OldProv);
            MovProducto.Modifyall("Source No.", Provedor);



            ValueEntry.SETCURRENTKEY("Document No.", "Posting Date");
            ValueEntry.SETRANGE("Document No.", wDocFilter);
            ValueEntry.SETRANGE("Posting Date", rPostPurchHeader."Posting Date");
            ValueEntry.SetRange("Source No.", OldProv);
            ValueEntry.Modifyall("Source No.", Provedor);
        end;
    end;

    /// <summary>
    /// CambiaFechaContabilidad.
    /// </summary>
    /// <param name="VAR GlEntry">Record "G/L Entry".</param>
    /// <param name="Fecha">Date.</param>
    procedure CambiaFechaContabilidad(VAR GlEntry: Record "G/L Entry"; Fecha: Date)
    begin
        //BorrarContabilidad

        IF GlEntry.FIND('-') THEN
            REPEAT

                CLEAR(c11);
                IF c11.DateNotAllowed(GlEntry."Posting Date") THEN ERROR('La fecha esta en un periodo cerrado');
                CLEAR(c11);
                IF c11.DateNotAllowed(Fecha) THEN ERROR('La fecha esta en un periodo cerrado');


                //Customer
                IF CustEntry.GET(GlEntry."Entry No.") THEN BEGIN
                    CustEntry."Posting Date" := Fecha;
                    CustEntry.MODIFY;
                    DetCustEntry.SETCURRENTKEY("Cust. Ledger Entry No.", "Posting Date");
                    DetCustEntry.SETRANGE("Cust. Ledger Entry No.", CustEntry."Entry No.");
                    DetCustEntry.MODIFYALL(DetCustEntry."Posting Date", Fecha);
                    DocCartera.SETRANGE("Entry No.", CustEntry."Entry No.");
                    DocCartera.MODIFYALL(DocCartera."Posting Date", Fecha);
                    // IF DocCartera.FIND('-') THEN DocCartera.DELETEALL;
                END;

                //Vendor
                IF VendorEntry.GET(GlEntry."Entry No.") THEN BEGIN
                    VendorEntry."Posting Date" := Fecha;
                    VendorEntry.MODIFY;
                    DetVendorEntry.SETCURRENTKEY("Vendor Ledger Entry No.", "Posting Date");
                    DetVendorEntry.SETRANGE("Vendor Ledger Entry No.", VendorEntry."Entry No.");
                    DetVendorEntry.MODIFYALL(DetVendorEntry."Posting Date", Fecha);
                    DocCartera.SETRANGE("Entry No.", VendorEntry."Entry No.");
                    DocCartera.MODIFYALL(DocCartera."Posting Date", Fecha);

                END;

                //Banco
                IF BankEntry.GET(GlEntry."Entry No.") THEN BEGIN
                    BankEntry."Posting Date" := Fecha;
                    BankEntry.MODIFY;
                END;

                //Vat Entry
                VatEntry.SETCURRENTKEY("Transaction No.");
                VatEntry.SETRANGE("Transaction No.", GlEntry."Transaction No.");
                IF VatEntry.FIND('-') THEN
                    REPEAT
                        VatEntry."Posting Date" := Fecha;
                        VatEntry."VAT Reporting Date" := Fecha;
                        VatEntry.MODIFY;
                    UNTIL VatEntry.NEXT = 0;
                GlEntry."Posting Date" := Fecha;
                GlEntry."VAT Reporting Date" := Fecha;
                GlEntry.MODIFY;
                IF r45.GET(GlEntry."Transaction No.") THEN BEGIN
                    r45."Posting Date" := Fecha;
                    r45.MODIFY;
                END;

            UNTIL GlEntry.NEXT = 0;
    end;

    /// <summary>
    /// RepetirFacturaCompra.
    /// </summary>
    /// <param name="Fecha">Date.</param>
    procedure RepetirFacturaCompra(Fecha: Date)
    begin
        //AnularFacturaCompra

        rPostPurchHeader.SETFILTER("No.", wDocFilter);
        IF rPostPurchHeader.FIND('-') THEN BEGIN

            rPurchHeader.INIT;
            rPurchHeader.TRANSFERFIELDS(rPostPurchHeader);
            rPurchHeader."No." := '';
            rPurchHeader."Document Type" := rPurchHeader."Document Type"::Invoice;
            rPurchHeader."Posting Date" := Fecha;
            rPurchHeader.INSERT(TRUE);


            rPostPurchLine.SETRANGE("Document No.", rPostPurchHeader."No.");
            IF rPostPurchLine.FIND('-') THEN
                REPEAT

                    rPurchLine.TRANSFERFIELDS(rPostPurchLine);
                    rPurchLine."Document Type" := rPurchHeader."Document Type"::Invoice;
                    rPurchLine."Document No." := rPurchHeader."No.";
                    IF rPurchLine.Type.AsInteger() <> 0 THEN rPurchLine.VALIDATE(Quantity);
                    rPurchLine.INSERT;

                    rPostPurchLine2 := rPostPurchLine;

                UNTIL rPostPurchLine.NEXT = 0;


        END;
    end;

    /// <summary>
    /// AnulaAsiento.
    /// </summary>
    /// <param name="GlReg">VAR Record "G/L Register".</param>
    /// <param name="CrearAsiento">Boolean.</param>
    procedure AnulaAsiento(var GlReg: Record "G/L Register"; CrearAsiento: Boolean)
    var
        Text90000: Label '¿Confirma que desea anular el asiento ?';
        Text90001: Label '¿Generar un nuevo asiento?';
        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas';
        Text90003: Label 'No se puede anular un asiento anterior a un cierre';
        Text90004: Label 'Compresión de datos previa \';
        Text90005: Label 'efectuada para esa fecha.';
        Text90006: Label 'GENERAL';
        Text90007: Label 'ANULACION';
        Text90008: Label 'Anulaciones';
        Text90009: Label 'Este movimiento está relacionado con un mov. IVA\';
        Text90010: Label 'que se encuentra cerrado.';
        Text90011: Label 'Este movimiento está relacionado con un documento\';
        Text90012: Label 'que está incluido en una remesa.';
        Text90013: Label 'Este movimiento está relacionado con un mov. Cliente\';
        Text90014: Label 'que ya está liquidado.';
        Text90015: Label 'Este movimiento está relacionado con un mov. Proveedor\';
        Text90016: Label 'Este movimiento está relacionado con un mov. IVA.\';
        Text90017: Label 'No puede generarse el nuevo asiento.';
        Text90018: Label 'Este movimiento está relacinado con un mov. Banco\';
        Text90019: Label 'Este movimiento está relacinado con un mov. Cheque\';
        Text90020: Label 'Este movimiento está relacinado con un documento\';
        Text90021: Label 'que se encuentra está liquidado.';
        Text90022: Label 'que se encuentra remesado.';
        Text90023: Label 'Este asiento no se puede anular porque todas sus líneas estan marcadas como "Asiento Automático".';
        Text10001: Label 'No puede anular el asiento, ya que el número de asiento no coincide en el mov %1';
        MovContabilidad: Record "G/L Entry";
        ConfUsuario: Record "User Setup";
        FechaDesde: Date;
        FechaHasta: Date;
        ConfContabilidad: Record 98;
        PeriodoContable: Record "Accounting Period";
        LinInicialDiarioGeneral: Integer;
        LinDiarioGeneral2: Record "Gen. Journal Line";
        SeccionDiarioGeneral: Record "Gen. Journal Batch";
        AstoAutomatico: Boolean;
        i: Integer;
        RegMovContabilidad: Record 45;
        MovCheque: Record "Check Ledger Entry";
        AnularMovs: Codeunit "Cancel Entries";
    Begin
        IF CrearAsiento THEN BEGIN
            LinDiarioGeneral.INIT;
            LinDiarioGeneral.SETCURRENTKEY(LinDiarioGeneral."Journal Template Name",
                                            LinDiarioGeneral."Journal Batch Name",
                                            LinDiarioGeneral."Line No.");
            LinDiarioGeneral.SETRANGE(LinDiarioGeneral."Journal Template Name", Text90006);
            LinDiarioGeneral.SETRANGE(LinDiarioGeneral."Journal Batch Name", Text90007);
            IF LinDiarioGeneral.FIND('+') THEN;
            LinInicialDiarioGeneral := LinDiarioGeneral."Line No." + 10000;

            IF NOT SeccionDiarioGeneral.GET(Text90006, Text90007) THEN BEGIN
                SeccionDiarioGeneral.INIT;
                SeccionDiarioGeneral."Journal Template Name" := Text90006;
                SeccionDiarioGeneral.Name := Text90007;
                SeccionDiarioGeneral.Description := Text90008;
                SeccionDiarioGeneral.INSERT;
            END;
        END;

        AstoAutomatico := TRUE;

        FOR i := GlReg."From VAT Entry No." TO GlReg."To VAT Entry No." DO BEGIN
            IF MovIVA.GET(i) THEN
                IF MovIVA.Closed THEN
                    ERROR(Text90009 +
                            Text90010);
        END;


        MovContabilidad.SETRANGE("Entry No.", GlReg."From Entry No.", GlReg."To Entry No.");
        MovContabilidad.FIND('-');
        REPEAT
            // $001 AstoAutomatico := TRUE;
            IF AstoAutomatico THEN
                AstoAutomatico := MovContabilidad."System-Created Entry";


            IF Doc.GET(MovContabilidad."Entry No.") THEN
                IF Doc."Bill Gr./Pmt. Order No." <> '' THEN
                    ERROR(Text90011 +
                            Text90012);
            IF MovCliente.GET(MovContabilidad."Entry No.") THEN BEGIN             //FCL-06/05/04 (begin)
                MovCliente.CALCFIELDS(Amount, "Remaining Amount", "Amount (LCY)");    //FCL-06/05/04
                IF MovCliente.Amount <> MovCliente."Remaining Amount" THEN
                    ERROR(Text90013 +
                            Text90014);
            END;                                                                  //FCL-06/05/04
            IF MovProveedor.GET(MovContabilidad."Entry No.") THEN BEGIN           //FCL-06/05/04 (begin)
                MovProveedor.CALCFIELDS(Amount, "Remaining Amount", "Amount (LCY)");  //FCL-06/05/04
                IF MovProveedor.Amount <> MovProveedor."Remaining Amount" THEN
                    ERROR(Text90015 +
                            Text90014);
            END;                                                                  //FCL-06/05/04
                                                                                  //*************************************1
                                                                                  // IF MovIVA.GET(MovContabilidad."Nº mov.") THEN BEGIN
            RegMovContabilidad.SETFILTER("From Entry No.", '<=%1', MovContabilidad."Entry No.");
            RegMovContabilidad.SETFILTER("To Entry No.", '>=%1', MovContabilidad."Entry No.");
            RegMovContabilidad.FIND('-');
            IF NOT (RegMovContabilidad."From VAT Entry No." > RegMovContabilidad."To VAT Entry No.") THEN BEGIN
                MovIVA.SETRANGE(MovIVA."Entry No.", RegMovContabilidad."From VAT Entry No.");
                IF MovIVA.FIND('-') THEN BEGIN
                    //*****************1
                    IF MovIVA.Closed THEN
                        ERROR(Text90009 +
                                Text90010);
                    IF CrearAsiento THEN
                        ERROR(Text90016 +
                            Text90017);
                    //************************************2
                END;
            END;
            //*****************2
            IF MovBanco.GET(MovContabilidad."Entry No.") THEN
                IF MovBanco.Amount <> MovBanco."Remaining Amount" THEN
                    ERROR(Text90018 +
                            Text90014);
            IF MovCheque.GET(MovContabilidad."Entry No.") THEN
                IF MovCheque."Statement Status" <> MovCheque."Statement Status"::Open THEN
                    ERROR(Text90019 +
                            Text90014);
            IF Doc.GET(MovContabilidad."Entry No.") THEN BEGIN
                IF Doc."Original Amount" <> Doc."Remaining Amount" THEN
                    ERROR(Text90020 +
                            Text90021);
                IF Doc."Bill Gr./Pmt. Order No." <> '' THEN
                    ERROR(Text90020 +
                            Text90022);
            END;

            IF CrearAsiento THEN CrearLinDiario();

        UNTIL MovContabilidad.NEXT = 0;

        //$001-
        IF AstoAutomatico THEN
            ERROR(Text90023);
        //$001+

        IF CrearAsiento THEN BEGIN
            LinDiarioGeneral.SETRANGE("Line No.", LinInicialDiarioGeneral, LinDiarioGeneral."Line No.");
            LinDiarioGeneral2.COPYFILTERS(LinDiarioGeneral);
            LinDiarioGeneral2.SETRANGE("Gen. Bus. Posting Group", '');
            LinDiarioGeneral2.SETRANGE("Gen. Prod. Posting Group", '');
            IF LinDiarioGeneral.FIND('-') THEN
                REPEAT
                    LinDiarioGeneral2.SETRANGE(Amount, LinDiarioGeneral."VAT Amount");
                    IF LinDiarioGeneral2.FIND('-') THEN
                        LinDiarioGeneral2.DELETE;
                UNTIL LinDiarioGeneral.NEXT() = 0;
        END;

        MovContabilidad.FIND('-');

        AnularMovs.RUN(MovContabilidad);
    end;

    /// <summary>
    /// ImportaTimon.
    /// </summary>
    internal procedure DesMacarAutomatico(Rec: Record "G/L Register")
    var
        GlEntry: Record "G/l Entry";
    begin
        GlEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        GlEntry.ModifyAll("System-Created Entry", false);
    end;

    internal procedure RecargaDatosCliente(var Rec: Record "Sales Invoice Header")
    var
        Cust: Record 18;
        r222: Record 222;
    BEGIN
        Cust.GET(Rec."Sell-to Customer No.");
        Rec."Sell-to Customer Name" := Cust.Name;
        Rec."Sell-to Customer Name 2" := Cust."Name 2";
        Rec."Sell-to Address" := Cust.Address;
        Rec."Sell-to Address 2" := Cust."Address 2";
        Rec."Sell-to City" := Cust.City;
        Rec."Sell-to Post Code" := Cust."Post Code";
        Rec."Sell-to County" := Cust.County;
        Rec."Sell-to Country/Region Code" := Cust."Country/Region Code";
        Rec."Sell-to Contact" := Cust.Contact;
        Rec."VAT Registration No." := Cust."VAT Registration No.";
        IF Rec."Bill-to Customer No." <> '' THEN Cust.GET(Rec."Bill-to Customer No.");
        Rec."Bill-to Name" := Cust.Name;
        Rec."Bill-to Name 2" := Cust."Name 2";
        Rec."Bill-to Address" := Cust.Address;
        Rec."Bill-to Address 2" := Cust."Address 2";
        Rec."Bill-to City" := Cust.City;
        Rec."Bill-to Post Code" := Cust."Post Code";
        Rec."Bill-to County" := Cust.County;
        Rec."Bill-to Country/Region Code" := Cust."Country/Region Code";
        Rec."Bill-to Contact" := Cust.Contact;
        Rec."VAT Registration No." := Cust."VAT Registration No.";
        IF Rec."Ship-to Code" = '' THEN BEGIN
            Rec."Ship-to Name" := Cust.Name;
            Rec."Ship-to Name 2" := Cust."Name 2";
            Rec."Ship-to Address" := Cust.Address;
            Rec."Ship-to Address 2" := Cust."Address 2";
            Rec."Ship-to City" := Cust.City;
            Rec."Ship-to Post Code" := Cust."Post Code";
            Rec."Ship-to County" := Cust.County;
            Rec."Ship-to Country/Region Code" := Cust."Country/Region Code";
            Rec."Ship-to Contact" := Cust.Contact;

        END ELSE BEGIN
            r222.GET(Rec."Sell-to Customer No.", Rec."Ship-to Code");
            Rec."Ship-to Name" := r222.Name;
            Rec."Ship-to Name 2" := r222."Name 2";
            Rec."Ship-to Address" := r222.Address;
            Rec."Ship-to Address 2" := r222."Address 2";
            Rec."Ship-to City" := r222.City;
            Rec."Ship-to Post Code" := r222."Post Code";
            Rec."Ship-to County" := r222.County;
            Rec."Ship-to Country/Region Code" := r222."Country/Region Code";
            Rec."Ship-to Contact" := r222.Contact;

        END;
        Rec.MODIFY;
    end;

    internal procedure RetrocedeRemesa(var Rec: Record "Posted Bill Group")
    var
        GlEntry: Record "G/L Entry";
        DocRs: Record 7000003;
        Docs: Record 7000002;
        MovCli: Record "Cust. Ledger Entry";
        Rem: Record "Bill Group";
    begin
        GlEntry.SetRange("Document No.", Rec."No.");
        GlEntry.SetRange("Posting Date", Rec."Posting Date");
        DocRs.SetRange("Bill Gr./Pmt. Order No.", Rec."No.");
        DocRs.FindSet();
        repeat
            If MovCli.Get(DocRs."Entry No.") Then begin
                MovCli."Document Situation" := MovCli."Document Situation"::"BG/PO";
                MovCli."Document Status" := MovCli."Document Status"::Open;
                MovCli.Modify();
            end;
            Docs.TransferFields(DocRs);
            Docs."Remaining Amount" := DocRs."Original Amount";
            Docs."Remaining Amt. (LCY)" := DocRs."Original Amount";
            Docs.Insert();

        until DocRs.Next() = 0;
        DocRs.DeleteAll();
        Rem.TransferFields(Rec);
        Rem.Insert();
        Rec.Delete();
        GlEntry.DeleteAll();

    end;

    internal procedure CambiarFechaFacturaVenta(No: Code[20]; Fecha: Date)
    var
        C11: Codeunit 11;
        SalesInvoice: Record 112;
        r17: Record 17;
        r254: Record 254;
    begin
        CLEAR(c11);
        IF c11.DateNotAllowed(Fecha) THEN ERROR('La fecha esta en un periodo cerrado');

        SalesInvoice.SetRange("No.", No);
        IF SalesInvoice.FINDFIRST THEN
            REPEAT
                CLEAR(c11);
                IF c11.DateNotAllowed(SalesInvoice."Posting Date") THEN ERROR('La fecha esta en un periodo cerrado');
                r17.SETCURRENTKEY("Document No.", "Posting Date");
                r17.SETRANGE(r17."Document No.", SalesInvoice."No.");
                r17.SETRANGE(r17."Posting Date", SalesInvoice."Posting Date");
                r17.MODIFYALL("Posting Date", Fecha, TRUE);
                r17.ModifyAll("VAT Reporting Date", Fecha);
                r254.SETRANGE(r254."Document No.", SalesInvoice."No.");
                r254.SETRANGE(r254."Posting Date", SalesInvoice."Posting Date");
                r254.MODIFYALL("Posting Date", Fecha);
                r254.Modifyall("VAT Reporting Date", Fecha);
                SalesInvoice."Posting Date" := Fecha;
                SalesInvoice."Document Date" := Fecha;
                SalesInvoice.MODIFY;
            UNTIL SalesInvoice.NEXT = 0;
    end;


    internal procedure CambiarFechaAbonoVenta(No: Code[20]; Fecha: Date)
    var
        r17: Record 17;
        r254: Record 254;
        r21: Record 21;
        r379: Record 379;
        c11: Codeunit 11;
        SalesInvoice: Record 114;
    begin
        SalesInvoice.Get(No);
        CLEAR(c11);
        IF c11.DateNotAllowed(SalesInvoice."Posting Date") THEN ERROR('La fecha esta en un periodo cerrado');
        r17.SETCURRENTKEY("Document No.", "Posting Date");
        r17.SETRANGE(r17."Document No.", SalesInvoice."No.");
        r17.SETRANGE(r17."Posting Date", SalesInvoice."Posting Date");
        r17.MODIFYALL("Posting Date", Fecha, TRUE);
        r17.ModifyAll(r17."VAT Reporting Date", Fecha);
        r21.SETCURRENTKEY("Document No.", "Posting Date");
        r21.SETRANGE(r21."Document No.", SalesInvoice."No.");
        r21.SETRANGE(r21."Posting Date", SalesInvoice."Posting Date");
        r21.SetRange("Customer No.", SalesInvoice."Sell-to Customer No.");
        r21.MODIFYALL("Posting Date", Fecha, TRUE);
        r379.SetRange("Document No.", SalesInvoice."No.");
        r379.SetRange("Customer No.", SalesInvoice."Sell-to Customer No.");
        r379.SetRange("Posting Date", SalesInvoice."Posting Date");
        r379.ModifyAll("Posting Date", Fecha);
        r254.SETRANGE(r254."Document No.", SalesInvoice."No.");
        r254.SETRANGE(r254."Posting Date", SalesInvoice."Posting Date");
        r254.MODIFYALL("Posting Date", Fecha, TRUE);
        r254.ModifyAll(r254."VAT Reporting Date", Fecha);
        SalesInvoice."Posting Date" := Fecha;
        SalesInvoice.MODIFY;

    end;

    internal procedure CambiarFromaPagoAbonoVenta(No: Code[20]; Code: Code[10])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        r21: Record 21;
        r700002: Record 7000002;

    begin
        SalesCrMemoHeader.GET(No);
        SalesCrMemoHeader."Payment Method Code" := Code;
        SalesCrMemoHeader.MODIFY;
        r21.SETCURRENTKEY("Document No.", "Posting Date");
        r21.SetRange("Document Type", r21."Document Type"::"Credit Memo");
        r21.SETRANGE(r21."Document No.", SalesCrMemoHeader."No.");
        r21.SETRANGE(r21."Posting Date", SalesCrMemoHeader."Posting Date");
        r21.MODIFYALL("Payment Method Code", Code);
        r700002.SETRANGE(r700002."Document No.", SalesCrMemoHeader."No.");
        r700002.SETRANGE(type, r700002.type::Receivable);
        r700002.MODIFYALL("Payment Method Code", Code);


    end;
    //lo mismo para factura
    internal procedure CambiarFromaPagoFacturaVenta(No: Code[20]; Code: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        r21: Record 21;
        r700002: Record 7000002;
    begin
        SalesInvoiceHeader.GET(No);
        SalesInvoiceHeader."Payment Method Code" := Code;
        SalesInvoiceHeader.MODIFY;
        r21.SETCURRENTKEY("Document No.", "Posting Date");
        r21.SetRange("Document Type", r21."Document Type"::Invoice);
        r21.SETRANGE(r21."Document No.", SalesInvoiceHeader."No.");
        r21.SETRANGE(r21."Posting Date", SalesInvoiceHeader."Posting Date");
        r21.MODIFYALL("Payment Method Code", Code);
        r700002.SETRANGE(r700002."Document No.", SalesInvoiceHeader."No.");
        r700002.SETRANGE(type, r700002.type::Receivable);
        r700002.MODIFYALL("Payment Method Code", Code);

    end;
    //Lo mismo para compras
    internal procedure CambiarFromaPagoFacturaCompra(No: Code[20]; Code: Code[10])
    var
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        r21: Record 25;
        r700002: Record 7000002;
    begin
        PurchInvoiceHeader.GET(No);
        PurchInvoiceHeader."Payment Method Code" := Code;
        PurchInvoiceHeader.MODIFY;
        r21.SETCURRENTKEY("Document No.", "Posting Date");
        r21.SetRange("Document Type", r21."Document Type"::Invoice);
        r21.SETRANGE(r21."Document No.", PurchInvoiceHeader."No.");
        r21.SETRANGE(r21."Posting Date", PurchInvoiceHeader."Posting Date");
        r21.MODIFYALL("Payment Method Code", Code);
        r700002.SETRANGE(r700002."Document No.", PurchInvoiceHeader."No.");
        r700002.SETRANGE(type, r700002.type::Payable);
        r700002.MODIFYALL("Payment Method Code", Code);

    end;
    //lo mismo para abono compra
    internal procedure CambiarFromaPagoAbonoCompra(No: Code[20]; Code: Code[10])
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        r21: Record 25;
        r700002: Record 7000002;
    begin
        PurchCrMemoHeader.GET(No);
        PurchCrMemoHeader."Payment Method Code" := Code;
        PurchCrMemoHeader.MODIFY;
        r21.SETCURRENTKEY("Document No.", "Posting Date");
        r21.SetRange("Document Type", r21."Document Type"::"Credit Memo");
        r21.SETRANGE(r21."Document No.", PurchCrMemoHeader."No.");
        r21.SETRANGE(r21."Posting Date", PurchCrMemoHeader."Posting Date");
        r21.MODIFYALL("Payment Method Code", Code);
        r700002.SETRANGE(r700002."Document No.", PurchCrMemoHeader."No.");
        r700002.SETRANGE(type, r700002.type::Payable);
        r700002.MODIFYALL("Payment Method Code", Code);

    end;



    //Lo mismo para compras
    internal procedure CambiarFromaPagoPedidoCompra(No: Code[20]; Code: Code[10])
    var
        PurchInvoiceHeader: Record "Purchase Header";
        Alb: Record "Purch. Rcpt. Header";
    begin
        PurchInvoiceHeader.GET(PurchInvoiceHeader."Document Type"::Order, No);
        PurchInvoiceHeader."Payment Method Code" := Code;
        PurchInvoiceHeader.MODIFY;
        Alb.SetRange("Order No.", No);
        Alb.MODIFYALL("Payment Method Code", Code);


    end;
    //lo mismo para devolucion compra
    internal procedure CambiarFromaPagoDevolucionCompra(No: Code[20]; Code: Code[10])
    var
        PurchInvoiceHeader: Record "Purchase Header";
        Alb: Record "Return shipment Header";

    begin
        PurchInvoiceHeader.GET(PurchInvoiceHeader."Document Type"::"Return Order", No);
        PurchInvoiceHeader."Payment Method Code" := Code;
        PurchInvoiceHeader.MODIFY;
        Alb.SetRange("Return Order No.", No);
        Alb.MODIFYALL("Payment Method Code", Code);
    end;


    local procedure CrearLinDiario()
    var
        Text90000: Label '¿Confirma que desea anular el asiento ?';
        Text90001: Label '¿Generar un nuevo asiento?';
        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas';
        Text90003: Label 'No se puede anular un asiento anterior a un cierre';
        Text90004: Label 'Compresión de datos previa \';
        Text90005: Label 'efectuada para esa fecha.';
        Text90006: Label 'GENERAL';
        Text90007: Label 'ANULACION';
        Text90008: Label 'Anulaciones';
        Text90009: Label 'Este movimiento está relacionado con un mov. IVA\';
        Text90010: Label 'que se encuentra cerrado.';
        Text90011: Label 'Este movimiento está relacionado con un documento\';
        Text90012: Label 'que está incluido en una remesa.';
        Text90013: Label 'Este movimiento está relacionado con un mov. Cliente\';
        Text90014: Label 'que ya está liquidado.';
        Text90015: Label 'Este movimiento está relacionado con un mov. Proveedor\';
        Text90016: Label 'Este movimiento está relacionado con un mov. IVA.\';
        Text90017: Label 'No puede generarse el nuevo asiento.';
        Text90018: Label 'Este movimiento está relacinado con un mov. Banco\';
        Text90019: Label 'Este movimiento está relacinado con un mov. Cheque\';
        Text90020: Label 'Este movimiento está relacinado con un documento\';
        Text90021: Label 'que se encuentra está liquidado.';
        Text90022: Label 'que se encuentra remesado.';
        Text90023: Label 'Este asiento no se puede anular porque todas sus líneas estan marcadas como "Asiento Automático".';
        Text10001: Label 'No puede anular el asiento, ya que el número de asiento no coincide en el mov %1';
        FormaPagoTemp: Code[10];
        TermPagoTemp: Code[10];
    begin

        LinDiarioGeneral.INIT;
        LinDiarioGeneral."Journal Batch Name" := Text90007;
        LinDiarioGeneral."Journal Template Name" := Text90006;
        LinDiarioGeneral."Line No." := LinDiarioGeneral."Line No." + 10000;

        IF MovCliente."Entry No." = MovContabilidad."Entry No." THEN BEGIN
            LinDiarioGeneral."Account Type" := LinDiarioGeneral."Account Type"::Customer;
            LinDiarioGeneral."Posting Date" := MovCliente."Posting Date";
            LinDiarioGeneral."Document Type" := MovCliente."Document Type";
            LinDiarioGeneral."Document No." := MovCliente."Document No.";
            //************************************ En la anulación de movimientos se elimina el nº de doc externo
            LinDiarioGeneral."External Document No." := MovCliente."External Document No.";
            //***********************
            LinDiarioGeneral.VALIDATE("Account No.", MovCliente."Customer No.");
            LinDiarioGeneral.Description := MovCliente.Description;
            LinDiarioGeneral."Currency Code" := MovCliente."Currency Code";
            LinDiarioGeneral.VALIDATE(Amount, MovCliente.Amount);
            LinDiarioGeneral.VALIDATE("Debit Amount", MovContabilidad."Debit Amount");
            LinDiarioGeneral.VALIDATE("Credit Amount", MovContabilidad."Credit Amount");
            LinDiarioGeneral.VALIDATE("Amount (LCY)", MovCliente."Amount (LCY)");
            LinDiarioGeneral.VALIDATE("Balance (LCY)", MovCliente."Amount (LCY)");
            IF (MovCliente."Currency Code" <> '') AND (MovCliente.Amount <> 0) THEN
                LinDiarioGeneral."Currency Factor" := 100 * MovCliente."Amount (LCY)" / MovCliente.Amount;
            LinDiarioGeneral."Sales/Purch. (LCY)" := MovCliente."Sales (LCY)";
            LinDiarioGeneral."Profit (LCY)" := MovCliente."Profit (LCY)";
            LinDiarioGeneral."Inv. Discount (LCY)" := MovCliente."Inv. Discount (LCY)";
            LinDiarioGeneral."Bill-to/Pay-to No." := MovCliente."Sell-to Customer No.";
            LinDiarioGeneral."Posting Group" := MovCliente."Customer Posting Group";
            LinDiarioGeneral."Shortcut Dimension 1 Code" := MovCliente."Global Dimension 1 Code";
            LinDiarioGeneral."Shortcut Dimension 2 Code" := MovCliente."Global Dimension 2 Code";
            LinDiarioGeneral."Salespers./Purch. Code" := MovCliente."Salesperson Code";
            LinDiarioGeneral."Source Code" := MovCliente."Source Code";
            LinDiarioGeneral."System-Created Entry" := MovContabilidad."System-Created Entry";
            LinDiarioGeneral."On Hold" := MovCliente."On Hold";
            LinDiarioGeneral."Due Date" := MovCliente."Due Date";
            LinDiarioGeneral."Job No." := MovContabilidad."Job No.";
            LinDiarioGeneral.Quantity := MovContabilidad.Quantity;
            LinDiarioGeneral."Bill No." := MovCliente."Bill No.";
            LinDiarioGeneral."Transaction No." := MovCliente."Transaction No.";
            LinDiarioGeneral."Pmt. Discount Given/Rec. (LCY)" := MovCliente."Pmt. Disc. Given (LCY)";
            LinDiarioGeneral."Pmt. Discount Date" := MovCliente."Pmt. Discount Date";
            LinDiarioGeneral."Document Date" := MovCliente."Document Date";
            LinDiarioGeneral."External Document No." := MovCliente."External Document No.";
            FormaPagoTemp := LinDiarioGeneral."Payment Method Code";
            TermPagoTemp := LinDiarioGeneral."Payment Terms Code";
            LinDiarioGeneral."Dimension Set ID" := MovCliente."Dimension Set ID";

        END ELSE
            IF MovProveedor."Entry No." = MovContabilidad."Entry No." THEN BEGIN
                LinDiarioGeneral."Account Type" := LinDiarioGeneral."Account Type"::Vendor;
                LinDiarioGeneral."Posting Date" := MovProveedor."Posting Date";
                LinDiarioGeneral."Document Type" := MovProveedor."Document Type";
                LinDiarioGeneral."Document No." := MovProveedor."Document No.";
                LinDiarioGeneral.VALIDATE("Account No.", MovProveedor."Vendor No.");
                LinDiarioGeneral.Description := MovProveedor.Description;
                LinDiarioGeneral."Currency Code" := MovProveedor."Currency Code";
                LinDiarioGeneral.VALIDATE(Amount, MovProveedor.Amount);
                LinDiarioGeneral.VALIDATE("Debit Amount", MovContabilidad."Debit Amount");
                LinDiarioGeneral.VALIDATE("Credit Amount", MovContabilidad."Credit Amount");
                LinDiarioGeneral.VALIDATE("Amount (LCY)", MovProveedor."Amount (LCY)");
                LinDiarioGeneral.VALIDATE("Balance (LCY)", MovProveedor."Amount (LCY)");
                IF (MovProveedor."Currency Code" <> '') AND (MovProveedor.Amount <> 0) THEN
                    LinDiarioGeneral."Currency Factor" := 100 * MovProveedor."Amount (LCY)" / MovProveedor.Amount;
                LinDiarioGeneral."Sales/Purch. (LCY)" := MovProveedor."Purchase (LCY)";
                LinDiarioGeneral."Inv. Discount (LCY)" := MovProveedor."Inv. Discount (LCY)";
                LinDiarioGeneral."Bill-to/Pay-to No." := MovProveedor."Buy-from Vendor No.";
                LinDiarioGeneral."Posting Group" := MovProveedor."Vendor Posting Group";
                LinDiarioGeneral."Shortcut Dimension 1 Code" := MovProveedor."Global Dimension 1 Code";
                LinDiarioGeneral."Shortcut Dimension 2 Code" := MovProveedor."Global Dimension 2 Code";
                LinDiarioGeneral."Salespers./Purch. Code" := MovProveedor."Purchaser Code";
                LinDiarioGeneral."Source Code" := MovProveedor."Source Code";
                LinDiarioGeneral."System-Created Entry" := MovContabilidad."System-Created Entry";
                LinDiarioGeneral."On Hold" := MovProveedor."On Hold";
                LinDiarioGeneral."Due Date" := MovProveedor."Due Date";
                LinDiarioGeneral."Job No." := MovContabilidad."Job No.";
                LinDiarioGeneral.Quantity := MovContabilidad.Quantity;
                LinDiarioGeneral."Bill No." := MovProveedor."Bill No.";
                LinDiarioGeneral."Transaction No." := MovProveedor."Transaction No.";
                LinDiarioGeneral."Pmt. Discount Given/Rec. (LCY)" := MovProveedor."Pmt. Disc. Rcd.(LCY)";
                LinDiarioGeneral."Pmt. Discount Date" := MovProveedor."Pmt. Discount Date";
                LinDiarioGeneral."Document Date" := MovProveedor."Document Date";
                LinDiarioGeneral."External Document No." := MovProveedor."External Document No.";
                FormaPagoTemp := LinDiarioGeneral."Payment Method Code";
                TermPagoTemp := LinDiarioGeneral."Payment Terms Code";
                LinDiarioGeneral."Dimension Set ID" := MovProveedor."Dimension Set ID";
            END ELSE
                IF MovBanco."Entry No." = MovContabilidad."Entry No." THEN BEGIN
                    LinDiarioGeneral."Account Type" := LinDiarioGeneral."Account Type"::"Bank Account";
                    LinDiarioGeneral."Posting Date" := MovBanco."Posting Date";
                    LinDiarioGeneral."Document Type" := MovBanco."Document Type";
                    LinDiarioGeneral."Document No." := MovBanco."Document No.";
                    //****************************************************Linea introducida para generar Nº documento externo en los movs de bancos
                    LinDiarioGeneral."External Document No." := MovBanco."External Document No.";
                    //***************************
                    LinDiarioGeneral.VALIDATE("Account No.", MovBanco."Bank Account No.");
                    LinDiarioGeneral.Description := MovBanco.Description;
                    LinDiarioGeneral."Currency Code" := MovBanco."Currency Code";
                    LinDiarioGeneral.VALIDATE(Amount, MovBanco.Amount);
                    LinDiarioGeneral.VALIDATE("Debit Amount", MovContabilidad."Debit Amount");
                    LinDiarioGeneral.VALIDATE("Credit Amount", MovContabilidad."Credit Amount");
                    LinDiarioGeneral.VALIDATE("Amount (LCY)", MovBanco."Amount (LCY)");
                    LinDiarioGeneral.VALIDATE("Balance (LCY)", MovBanco."Amount (LCY)");
                    IF (MovBanco."Currency Code" <> '') AND (MovBanco.Amount <> 0) THEN
                        LinDiarioGeneral."Currency Factor" := 100 * MovBanco."Amount (LCY)" / MovBanco.Amount;
                    LinDiarioGeneral."Posting Group" := MovBanco."Bank Acc. Posting Group";
                    LinDiarioGeneral."Shortcut Dimension 1 Code" := MovBanco."Global Dimension 1 Code";
                    LinDiarioGeneral."Shortcut Dimension 2 Code" := MovBanco."Global Dimension 2 Code";
                    LinDiarioGeneral."Source Code" := MovBanco."Source Code";
                    LinDiarioGeneral."System-Created Entry" := MovContabilidad."System-Created Entry";
                    LinDiarioGeneral.Quantity := MovContabilidad.Quantity;
                    LinDiarioGeneral."Bill No." := MovBanco."Bill No.";
                    LinDiarioGeneral."Transaction No." := MovBanco."Transaction No.";
                    LinDiarioGeneral."Document Date" := MovBanco."Document Date";
                    LinDiarioGeneral."External Document No." := MovBanco."External Document No.";
                    LinDiarioGeneral."Dimension Set ID" := MovBanco."Dimension Set ID";
                END ELSE BEGIN
                    LinDiarioGeneral."Account Type" := LinDiarioGeneral."Account Type"::"G/L Account";
                    LinDiarioGeneral."Posting Date" := MovContabilidad."Posting Date";
                    LinDiarioGeneral."Document Type" := MovContabilidad."Document Type";
                    LinDiarioGeneral."Document No." := MovContabilidad."Document No.";
                    //**************************************Linea para introducir el nº documento externo parche 2 Junio 2000
                    LinDiarioGeneral."External Document No." := MovContabilidad."External Document No.";
                    //***************************
                    LinDiarioGeneral.VALIDATE("Account No.", MovContabilidad."G/L Account No.");
                    LinDiarioGeneral.Description := MovContabilidad.Description;

                    LinDiarioGeneral.VALIDATE(Amount, MovContabilidad.Amount + MovContabilidad."VAT Amount");
                    IF MovContabilidad."Debit Amount" <> 0 THEN
                        LinDiarioGeneral.VALIDATE("Debit Amount", MovContabilidad.Amount + MovContabilidad."VAT Amount")
                    ELSE
                        LinDiarioGeneral.VALIDATE("Credit Amount", -(MovContabilidad.Amount + MovContabilidad."VAT Amount"));
                    LinDiarioGeneral.VALIDATE("Amount (LCY)", MovContabilidad.Amount + MovContabilidad."VAT Amount");
                    LinDiarioGeneral.VALIDATE("Balance (LCY)", MovContabilidad.Amount + MovContabilidad."VAT Amount");

                    LinDiarioGeneral."Shortcut Dimension 1 Code" := MovContabilidad."Global Dimension 1 Code";
                    LinDiarioGeneral."Shortcut Dimension 2 Code" := MovContabilidad."Global Dimension 2 Code";
                    LinDiarioGeneral."Source Code" := MovContabilidad."Source Code";
                    LinDiarioGeneral."System-Created Entry" := MovContabilidad."System-Created Entry";
                    LinDiarioGeneral."Job No." := MovContabilidad."Job No.";
                    LinDiarioGeneral.Quantity := MovContabilidad.Quantity;
                    LinDiarioGeneral."VAT Amount" := MovContabilidad."VAT Amount";
                    LinDiarioGeneral."Bill No." := MovContabilidad."Bill No.";
                    LinDiarioGeneral."Dimension Set ID" := MovContabilidad."Dimension Set ID";

                END;
        IF MovIVA."Entry No." = MovContabilidad."Entry No." THEN BEGIN
            LinDiarioGeneral."Gen. Bus. Posting Group" := MovIVA."Gen. Bus. Posting Group";
            LinDiarioGeneral."Gen. Prod. Posting Group" := MovIVA."Gen. Prod. Posting Group";
            LinDiarioGeneral."VAT Calculation Type" := MovIVA."VAT Calculation Type";
            LinDiarioGeneral."EU 3-Party Trade" := MovIVA."EU 3-Party Trade";
            LinDiarioGeneral."VAT Base Amount" := MovIVA.Base;
            LinDiarioGeneral."VAT Posting" := MovIVA.Type.AsInteger();
            LinDiarioGeneral."VAT %" := ROUND((MovIVA.Amount * 100 / MovIVA.Base), 0.5);
        END;
        IF Doc."Entry No." = MovContabilidad."Entry No." THEN BEGIN
            LinDiarioGeneral."Payment Method Code" := Doc."Payment Method Code";
            LinDiarioGeneral."Due Date" := Doc."Due Date";
            LinDiarioGeneral."Bill No." := Doc."No.";
        END;

        LinDiarioGeneral."Document No." := MovContabilidad."Document No.";
        LinDiarioGeneral."Transaction No." := MovContabilidad."Transaction No.";
        LinDiarioGeneral."Payment Method Code" := FormaPagoTemp;
        LinDiarioGeneral."Payment Terms Code" := TermPagoTemp;

        LinDiarioGeneral.INSERT;
    end;

    internal procedure Desliquida(var Rec: Record "Cust. Ledger Entry")
    Var
        r379: Record 379;

    BEGIN
        r379.SETCURRENTKEY(r379."Cust. Ledger Entry No.");
        r379.SETRANGE(r379."Cust. Ledger Entry No.", Rec."Entry No.");
        r379.SETRANGE(r379."Entry Type", r379."Entry Type"::Application);
        r379.DELETEALL;
        Rec.Open := TRUE;
        Rec.MODIFY;
    end;

    internal procedure Liquida(var Rec: Record "Cust. Ledger Entry")
    Var
        r379: Record 379;
        a: Integer;
    BEGIN
        r379.FINDLAST;
        a := r379."Entry No.";
        r379.SETCURRENTKEY(r379."Cust. Ledger Entry No.");
        r379.SETRANGE(r379."Cust. Ledger Entry No.", Rec."Entry No.");
        r379.FINDFIRST;
        r379."Entry No." := a + 1;
        r379."Entry Type" := r379."Entry Type"::Application;
        r379.Amount := -r379.Amount;
        r379."Amount (LCY)" := -r379."Amount (LCY)";
        if r379."Debit Amount" = 0 THEN BEGIN
            r379."Debit Amount" := r379."Credit Amount";
            r379."Debit Amount (LCY)" := r379."Credit Amount (LCY)";
            r379."Credit Amount" := 0;
            r379."Credit Amount (LCY)" := 0;
        END ELSE BEGIN
            r379."Credit Amount" := r379."Debit Amount";
            r379."Credit Amount (LCY)" := r379."Debit Amount (LCY)";
            r379."Debit Amount (LCY)" := 0;
            r379."Debit Amount" := 0;

        END;
        r379.INSERT;
        Rec.Open := FALSE;
        Rec.MODIFY;
    End;

    internal procedure EnviarACartera(var Rec: Record "Cust. Ledger Entry")
    Var
        rDoc: Record 7000002;
        rCli: Record 18;
    BEGIN
        Rec.CALCFIELDS("Remaining Amount", Amount, "Original Amt. (LCY)", "Remaining Amt. (LCY)", "Amount (LCY)", "Original Amount");
        if Rec."Remaining Amount" <> 0 THEN BEGIN
            rDoc.INIT;
            rDoc.Type := rDoc.Type::Receivable;
            rDoc."Entry No." := Rec."Entry No.";
            rDoc."No." := '1';
            rDoc."Posting Date" := Rec."Posting Date";
            rDoc."Document No." := Rec."Document No.";
            rDoc.Description := Rec.Description;
            rDoc."Remaining Amount" := Rec."Remaining Amount";
            rDoc."Remaining Amt. (LCY)" := Rec."Remaining Amt. (LCY)";
            rDoc."Due Date" := Rec."Due Date";
            rDoc."Payment Method Code" := Rec."Payment Method Code";
            rDoc.Accepted := rDoc.Accepted::"Not Required";
            rDoc.Place := FALSE;
            rDoc."Collection Agent" := rDoc."Collection Agent"::Bank;
            rDoc."Account No." := Rec."Customer No.";
            rDoc."Currency Code" := Rec."Currency Code";
            rCli.GET(Rec."Customer No.");
            rDoc."Cust./Vendor Bank Acc. Code" := rCli."Preferred Bank Account Code";
            // rDoc."Pmt. Address Code" := '';
            rDoc."Global Dimension 1 Code" := Rec."Global Dimension 1 Code";
            rDoc."Global Dimension 2 Code" := Rec."Global Dimension 2 Code";
            rDoc."Original Amount" := Rec."Original Amount";
            rDoc."Original Amount (LCY)" := Rec."Original Amt. (LCY)";
            CASE Rec."Document Type" OF
                Rec."Document Type"::Invoice:
                    rDoc."Document Type" := rDoc."Document Type"::Invoice;
                Rec."Document Type"::" ":
                    rDoc."Document Type" := rDoc."Document Type"::Bill;
                Rec."Document Type"::Bill:
                    rDoc."Document Type" := rDoc."Document Type"::Bill;
            END;
            rDoc.Adjusted := FALSE;
            rDoc."Adjusted Amount" := 0;
            rDoc."From Journal" := FALSE;
            rDoc."On Hold" := FALSE;
            rDoc.INSERT;
        END;
    END;


    // [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeRename', '', false, false)]
    // local procedure OnBeforeRename(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    // begin
    //     IsHandled := true;
    // end;


    internal procedure CambiarProveedorPedidoCompra(Pedido: Code[20]; Proveedor: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseRecptHeader: Record "Purch. Rcpt. Header";
        PurchaseRecptLine: Record "Purch. Rcpt. Line";

    begin
        PurchaseHeader.SETRANGE("No.", Pedido);
        purchaseHeader.SETRANGE("Document Type", purchaseHeader."Document Type"::Order);
        if PurchaseHeader.FINDSET then
            repeat
                PurchaseHeader."Buy-from Vendor No." := Proveedor;
                PurchaseHeader."Pay-to Vendor No." := Proveedor;
                PurchaseHeader.MODIFY;
                PurchaseLine.SETRANGE("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SETRANGE("Document No.", PurchaseHeader."No.");
                if PurchaseLine.FINDSET then
                    repeat
                        PurchaseLine."Buy-from Vendor No." := Proveedor;
                        PurchaseLine.MODIFY;
                    until PurchaseLine.NEXT = 0;
                PurchaseRecptHeader.SETRANGE("Order No.", PurchaseHeader."No.");
                if PurchaseRecptHeader.FINDSET then
                    repeat
                        PurchaseRecptHeader."Buy-from Vendor No." := Proveedor;
                        PurchaserecptHeader."Pay-to Vendor No." := Proveedor;
                        PurchaseRecptHeader.MODIFY;
                        PurchaseRecptLine.SETRANGE("Document No.", PurchaseRecptHeader."No.");
                        if PurchaseRecptLine.FINDSET then
                            repeat
                                PurchaseRecptLine."Buy-from Vendor No." := Proveedor;
                                PurchaseRecptLine.MODIFY;
                            until PurchaseRecptLine.NEXT = 0;
                    until PurchaseRecptHeader.NEXT = 0;
            until PurchaseHeader.NEXT = 0;
    end;

    internal procedure CambiarCuentaPedidoCompra(DocumentNo: Code[20]; LineNo: Integer; No: Code[20])
    var
        PurchRecptLine: Record "Purch. Rcpt. Line";
        PurchLine: Record "Purchase Line";
    begin
        PurchRecptLine.SetRange("Order No.", DocumentNo);
        PurchRecptLine.SetRange("Order Line No.", LineNo);
        if PurchRecptLine.FindSet then
            repeat
                PurchRecptLine."No." := No;
                PurchRecptLine.Modify;
            until PurchRecptLine.Next = 0;
        PurchLine.get(PurchLine."Document Type"::Order, DocumentNo, LineNo);
        PurchLine."No." := No;
        PurchLine.Modify;
    end;

    internal procedure MoverProv2024(Vendor: Record Vendor; Var SameCIFCustomer: Record Vendor; Codigo: Text)
    var
        MovContabilidad: Record "G/L Entry";
        MovProveedor: Record "Vendor Ledger Entry";
        DetalleMovProveedor: Record "Detailed Vendor Ledg. Entry";
        Pedidos: Record "Purchase Header";
        Lineas: Record "Purchase Line";
        LineasAlbaran: Record "Purch. Rcpt. Line";
        Albaranes: Record "Purch. Rcpt. Header";
        Facturas: Record "Purch. Inv. Header";
        LineasFactura: Record "Purch. Inv. Line";
        Abonos: Record "Purch. Cr. Memo Hdr.";
        LineasAbono: Record "Purch. Cr. Memo Line";
        DefaultDim: Record "Default Dimension";
    begin
        SameCIFCustomer.SetFilter("No.", '<>%1', Codigo);
        SameCIFCustomer.FindFirst();
        Vendor.Get(Codigo);
        repeat
            //Contabilidad 2024
            MovContabilidad.SetRange("Source No.", SameCIFCustomer."No.");
            MovContabilidad.SetRange("Source Type", MovContabilidad."Source Type"::"Vendor", MovContabilidad."Source Type"::"Vendor");
            MovContabilidad.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If MovContabilidad.FindSet() then
                repeat
                    MovContabilidad."Source No." := Vendor."No.";
                    If MovProveedor.Get(MovContabilidad."Entry No.") then begin
                        MovProveedor."Vendor No." := Vendor."No.";
                        DetalleMovProveedor.SetRange("Vendor Ledger Entry No.", MovContabilidad."Entry No.");
                        DetalleMovProveedor.ModifyAll("Vendor No.", Vendor."No.");
                        MovProveedor.Modify();
                    end;
                    MovContabilidad.Modify();
                until MovContabilidad.Next() = 0;
            //Pedidos
            Pedidos.SetRange("Buy-from Vendor No.", SameCIFCustomer."No.");
            Pedidos.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If Pedidos.FindSet() then
                repeat
                    Pedidos."Buy-from Vendor No." := Vendor."No.";
                    Pedidos."Pay-to Vendor No." := Vendor."No.";
                    Pedidos.Modify();
                    Lineas.SetRange("Document No.", Pedidos."No.");
                    If Lineas.FindSet() then
                        repeat
                            Lineas."Buy-from Vendor No." := Vendor."No.";
                            Lineas."Pay-to Vendor No." := Vendor."No.";
                            Lineas.Modify();
                            LineasAlbaran.SetRange("Order No.", Pedidos."No.");
                            LineasAlbaran.SetRange("Order Line No.", Lineas."Line No.");
                            LineasAlbaran.ModifyAll("Buy-from Vendor No.", Vendor."No.");
                            LineasAlbaran.ModifyAll("Pay-to Vendor No.", Vendor."No.");
                        until Lineas.Next() = 0;
                    Albaranes.SetRange("Order No.", Pedidos."No.");
                    Albaranes.ModifyAll("Buy-from Vendor No.", Vendor."No.");
                    Albaranes.ModifyAll("Pay-to Vendor No.", Vendor."No.");
                until Pedidos.Next() = 0;
            //Facturas
            Facturas.SetRange("Buy-from Vendor No.", SameCIFCustomer."No.");
            Facturas.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If Facturas.FindSet() then
                repeat
                    Facturas."Buy-from Vendor No." := Vendor."No.";
                    Facturas."Pay-to Vendor No." := Vendor."No.";
                    Facturas.Modify();
                    LineasFactura.SetRange("Document No.", Facturas."No.");
                    If LineasFactura.FindSet() then
                        repeat
                            LineasFactura."Buy-from Vendor No." := Vendor."No.";
                            LineasFactura."Pay-to Vendor No." := Vendor."No.";
                            LineasFactura.Modify();
                        until LineasFactura.Next() = 0;
                until Facturas.Next() = 0;
            //Abonos
            Abonos.SetRange("Buy-from Vendor No.", SameCIFCustomer."No.");
            Abonos.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If Abonos.FindSet() then
                repeat
                    Abonos."Buy-from Vendor No." := Vendor."No.";
                    Abonos."Pay-to Vendor No." := Vendor."No.";
                    Abonos.Modify();
                    LineasAbono.SetRange("Document No.", Abonos."No.");
                    If LineasAbono.FindSet() then
                        repeat
                            LineasAbono."Buy-from Vendor No." := Vendor."No.";
                            LineasAbono."Pay-to Vendor No." := Vendor."No.";
                            LineasAbono.Modify();
                        until LineasAbono.Next() = 0;
                until Abonos.Next() = 0;

        until SameCIFCustomer.Next() = 0;
        DefaultDim.SetRange("Table ID", 23);
        DefaultDim.DeleteAll();
    end;

    internal procedure MoverCli2024(Customer: Record Customer; var SameCIFCustomer: Record Customer; Codigo: Text)
    var
        MovContabilidad: Record "G/L Entry";
        MovCliente: Record "Cust. Ledger Entry";
        DetalleMovCliente: Record "Detailed Cust. Ledg. Entry";
        Pedidos: Record "Sales Header";
        Lineas: Record "Sales Line";
        LineasAlbaran: Record "Sales Shipment Line";
        Albaranes: Record "Sales Shipment Header";
        Facturas: Record "Sales Invoice Header";
        LineasFactura: Record "Sales Invoice Line";
        Abonos: Record "Sales Cr.Memo Header";
        LineasAbono: Record "Sales Cr.Memo Line";
        DefaultDim: Record "Default Dimension";
    begin
        SameCIFCustomer.SetFilter("No.", '<>%1', Codigo);
        SameCIFCustomer.FindFirst();
        Customer.Get(Codigo);
        repeat
            //Contabilidad 2024
            MovContabilidad.SetRange("Source No.", SameCIFCustomer."No.");
            MovContabilidad.SetRange("Source Type", MovContabilidad."Source Type"::"Customer", MovContabilidad."Source Type"::"Customer");
            MovContabilidad.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If MovContabilidad.FindSet() then
                repeat
                    MovContabilidad."Source No." := Customer."No.";
                    If MovCliente.Get(MovContabilidad."Entry No.") then begin
                        MovCliente."Customer No." := Customer."No.";
                        DetalleMovCliente.SetRange("Cust. Ledger Entry No.", MovContabilidad."Entry No.");
                        DetalleMovCliente.ModifyAll("Customer No.", Customer."No.");
                        MovCliente.Modify();
                    end;
                    MovContabilidad.Modify();
                until MovContabilidad.Next() = 0;
            //Pedidos
            Pedidos.SetRange("Sell-to Customer No.", SameCIFCustomer."No.");
            Pedidos.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If Pedidos.FindSet() then
                repeat
                    Pedidos."Sell-to Customer No." := Customer."No.";
                    Pedidos."Bill-to Customer No." := Customer."No.";
                    Pedidos.Modify();
                    Lineas.SetRange("Document No.", Pedidos."No.");
                    If Lineas.FindSet() then
                        repeat
                            Lineas."Sell-to Customer No." := Customer."No.";
                            Lineas."Bill-to Customer No." := Customer."No.";
                            Lineas.Modify();
                            LineasAlbaran.SetRange("Order No.", Pedidos."No.");
                            LineasAlbaran.SetRange("Order Line No.", Lineas."Line No.");
                            LineasAlbaran.ModifyAll("Sell-to Customer No.", Customer."No.");
                            LineasAlbaran.ModifyAll("Bill-to Customer No.", Customer."No.");
                        until Lineas.Next() = 0;
                    Albaranes.SetRange("Order No.", Pedidos."No.");
                    Albaranes.ModifyAll("Sell-to Customer No.", Customer."No.");
                    Albaranes.ModifyAll("Bill-to Customer No.", Customer."No.");
                until Pedidos.Next() = 0;
            //Facturas
            Facturas.SetRange("Sell-to Customer No.", SameCIFCustomer."No.");
            Facturas.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If Facturas.FindSet() then
                repeat
                    Facturas."Sell-to Customer No." := Customer."No.";
                    Facturas."Bill-to Customer No." := Customer."No.";
                    Facturas.Modify();
                    LineasFactura.SetRange("Document No.", Facturas."No.");
                    If LineasFactura.FindSet() then
                        repeat
                            LineasFactura."Sell-to Customer No." := Customer."No.";
                            LineasFactura."Bill-to Customer No." := Customer."No.";
                            LineasFactura.Modify();
                        until LineasFactura.Next() = 0;
                until Facturas.Next() = 0;
            //Abonos
            Abonos.SetRange("Sell-to Customer No.", SameCIFCustomer."No.");
            Abonos.SetRange("Posting Date", Calcdate('<CY+1D-1Y+1D>', Today), 29991231D);
            If Abonos.FindSet() then
                repeat
                    Abonos."Sell-to Customer No." := Customer."No.";
                    Abonos."Bill-to Customer No." := Customer."No.";
                    Abonos.Modify();
                    LineasAbono.SetRange("Document No.", Abonos."No.");
                    If LineasAbono.FindSet() then
                        repeat
                            LineasAbono."Sell-to Customer No." := Customer."No.";
                            LineasAbono."Bill-to Customer No." := Customer."No.";
                            LineasAbono.Modify();
                        until LineasAbono.Next() = 0;
                until Abonos.Next() = 0;
        until SameCIFCustomer.Next() = 0;
        DefaultDim.SetRange("Table ID", 23);
        DefaultDim.DeleteAll();

    end;

    internal procedure AssignProgram(Rec: Record "Payment Order")
    var
        DocCartera: Record "Cartera Doc.";
        MovProveedor: Record "Vendor Ledger Entry";
        Purchasde: Record "Purch. Inv. Line";
    begin
        DocCartera.SETRANGE("Bill Gr./Pmt. Order No.", Rec."No.");
        if DocCartera.FINDFIRST THEN
            REPEAT
                Purchasde.SETRANGE("Document No.", DocCartera."Document No.");
                Purchasde.SetFilter("Shortcut Dimension 2 Code", '<>%1', '');
                if Purchasde.FINDFIRST THEN begin
                    DocCartera."Global Dimension 2 Code" := Purchasde."Shortcut Dimension 2 Code";
                    DocCartera."Dimension Set ID" := Purchasde."Dimension Set ID";
                    DocCartera.MODIFY;
                    If MovProveedor.GET(DocCartera."Entry No.") THEN BEGIN
                        MovProveedor."Global Dimension 2 Code" := Purchasde."Shortcut Dimension 2 Code";
                        MovProveedor."Dimension Set ID" := Purchasde."Dimension Set ID";
                        MovProveedor.MODIFY;
                    END;
                end;
            UNTIL DocCartera.NEXT = 0;
    end;



    procedure RungcGenJnlPostLine(VAR pGenJnlLine: Record "Gen. Journal Line")
    BEGIN
        // RungcGenJnlPostLine
        //

        gcGenJnlPostLine.RunWithCheck(pGenJnlLine);//,TempJnlLineDim);
    END;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnBeforeErrorIfNegativeAmt', '', false, false)]
    local procedure OnBeforeErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
        RaiseError := false;
    end;

    procedure RenombraEfecto(NoMov: Integer; OldDoc: Code[20]; NewDocNo: Code[20]);
    VAR
        MovEfecto: Record "Cartera Doc.";
        ClosedMovEfecto: Record "Closed Cartera Doc.";
        PostedMovEfecto: Record "Posted Cartera Doc.";
    BEGIN
        IF MovEfecto.GET(MovEfecto.Type::Payable, NoMov) THEN BEGIN
            if MovEfecto."Document No." = OldDoc THEN BEGIN
                MovEfecto."Document No." := NewDocNo;
                MovEfecto.MODIFY;
            END;
        END;
        IF ClosedMovEfecto.GET(ClosedMovEfecto.Type::Payable, NoMov) THEN BEGIN
            if ClosedMovEfecto."Document No." = OldDoc THEN BEGIN
                ClosedMovEfecto."Document No." := NewDocNo;
                ClosedMovEfecto.MODIFY;
            END;
        END;
        IF PostedMovEfecto.GET(PostedMovEfecto.Type::Payable, NoMov) THEN BEGIN
            if PostedMovEfecto."Document No." = OldDoc THEN BEGIN
                PostedMovEfecto."Document No." := NewDocNo;
                PostedMovEfecto.MODIFY;
            END;
        END;
    END;

    procedure RenombraMovManco(NoMov: Integer; OldDoc: Code[20]; NewDocNo: Code[20]);
    VAR
        MovBanco: Record 271;
    BEGIN
        IF MovBanco.GET(NoMov) THEN BEGIN

            if MovBanco."Document No." = OldDoc THEN BEGIN
                MovBanco."Document No." := NewDocNo;
                MovBanco.MODIFY;
            END;
        END;
    END;

    PROCEDURE RenombraMovProv(NoMov: Integer; OldDoc: Code[20]; NewDocNo: Code[20]);
    VAR
        DetMovProveedor: Record 380;
    BEGIN
        IF MovProveedor.GET(NoMov) THEN BEGIN
            // MovProveedorAnulado.INIT;
            // MovProveedorAnulado.TRANSFERFIELDS(MovProveedor);
            DetMovProveedor.RESET;
            DetMovProveedor.SETCURRENTKEY("Vendor Ledger Entry No.", "Posting Date");
            DetMovProveedor.SETRANGE("Vendor Ledger Entry No.", MovProveedor."Entry No.");
            // $001-
            //DetMovProveedor.SETRANGE(DetMovProveedor."Posting Date",MovProveedor."Posting Date");
            // $001+
            IF DetMovProveedor.FIND('-') THEN
                REPEAT
                    if DetMovProveedor."Document No." = OldDoc THEN BEGIN
                        DetMovProveedor."Document No." := NewDocNo;
                        DetMovProveedor.MODIFY;
                    END;
                UNTIL DetMovProveedor.NEXT = 0;
            if MovProveedor."Document No." = OldDoc THEN BEGIN
                MovProveedor."Document No." := NewDocNo;
                MovProveedor.MODIFY;
            END;
        END;
    END;

    procedure RenombraEfectoCli(NoMov: Integer; OldDoc: Code[20]; NewDocNo: Code[20]);
    VAR
        MovEfecto: Record "Cartera Doc.";
        ClosedMovEfecto: Record "Closed Cartera Doc.";
        PostedMovEfecto: Record "Posted Cartera Doc.";
    BEGIN
        IF MovEfecto.GET(MovEfecto.Type::Receivable, NoMov) THEN BEGIN
            if MovEfecto."Document No." = OldDoc THEN BEGIN
                MovEfecto."Document No." := NewDocNo;
                MovEfecto.MODIFY;
            END;
        END;
        IF ClosedMovEfecto.GET(ClosedMovEfecto.Type::Receivable, NoMov) THEN BEGIN
            if ClosedMovEfecto."Document No." = OldDoc THEN BEGIN
                ClosedMovEfecto."Document No." := NewDocNo;
                ClosedMovEfecto.MODIFY;
            END;
        END;
        IF PostedMovEfecto.GET(PostedMovEfecto.Type::Receivable, NoMov) THEN BEGIN
            if PostedMovEfecto."Document No." = OldDoc THEN BEGIN
                PostedMovEfecto."Document No." := NewDocNo;
                PostedMovEfecto.MODIFY;
            END;
        END;
    END;

    PROCEDURE RenombraMovCliente(NoMov: Integer; OldDoc: Code[20]; NewDocNo: Code[20]);
    VAR
        DetMovCliente: Record 379;
    BEGIN
        IF MovCliente.GET(NoMov) THEN BEGIN
            // MovClienteAnulado.INIT;
            // MovClienteAnulado.TRANSFERFIELDS(MovCliente);
            DetMovCliente.RESET;
            DetMovCliente.SETCURRENTKEY("Cust. Ledger Entry No.", "Posting Date");
            DetMovCliente.SETRANGE("Cust. Ledger Entry No.", MovCliente."Entry No.");
            // $001-
            //DetMovCliente.SETRANGE(DetMovCliente."Posting Date",MovCliente."Posting Date");
            // $001+
            IF DetMovCliente.FIND('-') THEN
                REPEAT
                    if DetMovCliente."Document No." = OldDoc THEN BEGIN
                        DetMovCliente."Document No." := NewDocNo;
                        DetMovCliente.MODIFY;
                    END;
                UNTIL DetMovCliente.NEXT = 0;
            if MovCliente."Document No." = OldDoc THEN BEGIN
                MovCliente."Document No." := NewDocNo;
                MovCliente.MODIFY;
            END;
        END;
    END;


    Procedure Programa(Empresa: Text[30]): Code[20]
    var
        DimValue: Record "Dimension Value";
    begin
        //Crear las 4 dimensiones
        If Not DimValue.Get('PROGRAMA', 'LOS TILOS') Then begin
            DimValue.INIT;
            DimValue.Validate("Dimension Code", 'PROGRAMA');
            DimValue.VAlidate("Code", 'LOS TILOS');
            DimValue.INSERT(true);
        end;
        If Not DimValue.Get('PROGRAMA', 'PISCIS') Then begin
            DimValue.INIT;
            DimValue.Validate("Dimension Code", 'PROGRAMA');
            DimValue.VAlidate("Code", 'PISCIS');
            DimValue.INSERT(true);
        end;
        If Not DimValue.Get('PROGRAMA', 'SA VINYA') Then begin
            DimValue.INIT;
            DimValue.Validate("Dimension Code", 'PROGRAMA');
            DimValue.VAlidate("Code", 'SA VINYA');
            DimValue.INSERT(true);
        end;
        If Not DimValue.Get('PROGRAMA', 'UAT') Then begin
            DimValue.INIT;
            DimValue.Validate("Dimension Code", 'PROGRAMA');
            DimValue.VAlidate("Code", 'UAT');
            DimValue.INSERT(true);
        end;
        Case Empresa Of
            'Apartamentos los Tilos':
                Exit('LOS TILOS');
            'PISCIS DOS TRES HACHE, S.L.':
                Exit('PISCIS');
            'SA VINYA DELS MOSCATELLS, S.L.':
                Exit('Sa Vinya');
            'UNION AGRICOLA Y TURISTICA, SL':
                Exit('UAT');
            else
                Error('Empresa no encontrada');
        End
    end;








}


/// <summary>
/// Table Nominas Detalle (ID 50218).
/// Detalle de nóminas por empleado
/// </summary>
table 50218 "Nominas Detalle"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(2; Fecha; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Fecha';
        }
        field(3; Empleado; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Empleado';
            TableRelation = Employee."No.";
            trigger OnValidate()
            var
                ProcesosProyectos: Codeunit ProcesosProyectos;
            begin
                Departamento := ProcesosProyectos.GetProgramaNominas(Empleado);
                CopiarDimensionesDesdeEmpleado(Empleado);
            end;
        }
        field(4; Numero; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Número';
            AutoIncrement = true;
        }
        field(5; Departamento; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Departamento';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = CONST('DEPARTAMENTO'));
        }
        field(14; Devengado; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Devengado';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Coste := Devengado + "SS total" - "Enfermedad Accidente";
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(15; "S.S Obrero"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'S.S Obrero';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                RecalcularSSTotal();
                Personal := CalculaPersonal();
                RecalcularCosteYTC1();
                Validate(Personal);
            end;
        }
        field(16; IRPF; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IRPF';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                TC1 := CalculaTc1();
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(17; "SS empresa"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SS empresa';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                RecalcularSSTotal();
                RecalcularCosteYTC1();
                Validate("SS total");
            end;
        }
        field(18; "Enfermedad Accidente"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Enfermedad Accidente';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Coste := Devengado + "SS total" - "Enfermedad Accidente";
                TC1 := CalculaTc1();
                Validate(TC1);
            end;
        }
        field(19; "SS total"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SS total';
            AutoFormatType = 1;
            Editable = false;

            trigger OnValidate()
            begin
                TC1 := CalculaTc1();
                Coste := Devengado + "SS total" - "Enfermedad Accidente";
            end;
        }
        field(20; TC1; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TC1';
            AutoFormatType = 1;
            Editable = false;
        }
        field(21; Coste; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Coste';
            AutoFormatType = 1;
            Editable = false;
        }
        field(22; Banco; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Banco';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                "Difª" := Banco - Personal;
            end;
        }
        field(23; Personal; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Personal';
            AutoFormatType = 1;
            Editable = false;

            trigger OnValidate()
            begin
                "Difª" := Banco - Personal;
            end;
        }
        field(24; "Difª"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Diferencia';
            AutoFormatType = 1;
            Editable = false;
        }
        field(27; "Bonificación"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                RecalcularSSTotal();
                RecalcularCosteYTC1();
            end;
        }
        field(47; "Bonificación Fundae"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación Fundae';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                RecalcularSSTotal();
                RecalcularCosteYTC1();
            end;
        }
        field(28; Kms; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Kms';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(48; "Dto. Especie"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Dto. Especie';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(49; Dieta; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Dieta';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(29; Anticipos; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Anticipos';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(39; Embargos; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Embargos';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Personal := CalculaPersonal();
                Validate(Personal);
            end;
        }
        field(34; "Texto Dep"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Texto Dep';
        }
        field(50; "P.P.Ex"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'P.P.Ex';
            AutoFormatType = 1;
        }
        field(51; "MEJORA V"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'MEJORA V';
            AutoFormatType = 1;
        }
        field(52; COMIDA; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'COMIDA';
            AutoFormatType = 1;
        }
        field(53; "DIETAS"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'DIETAS';
            AutoFormatType = 1;
        }
        field(54; "P.P Vaca"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'P.P Vaca';
            AutoFormatType = 1;
        }
        field(55; "PL. FLEX"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'PL. FLEX';
            AutoFormatType = 1;
        }
        field(56; Indemni; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Indemni.';
            AutoFormatType = 1;
        }
        field(57; "Ant.diet"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Ant.diet';
            AutoFormatType = 1;
        }
        field(58; "Job No."; Code[20])
        {
            Caption = 'Nº Proyecto';
            DataClassification = ToBeClassified;
            TableRelation = Job;

            trigger OnValidate()
            begin
                if "Job No." <> xRec."Job No." then begin
                    Validate("Job Task No.", '');
                    Validate("Job Task No. SS", '');
                end;
            end;
        }
        field(59; "Job Task No."; Code[20])
        {
            Caption = 'Nº Tarea';
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(62; "Job Task No. SS"; Code[20])
        {
            Caption = 'Nº Tarea SS';
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(60; "Job Ledger Entry No."; Integer)
        {
            Caption = 'Nº Movimiento Proyecto';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Job Ledger Entry"."Entry No.";
        }
        field(63; "Job Ledger Entry No. SS"; Integer)
        {
            Caption = 'Nº Mov. Proyecto SS';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Job Ledger Entry"."Entry No.";
        }
        field(61; "Employee Entry No."; Integer)
        {
            Caption = 'Nº Movimiento Empleado';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Employee Ledger Entry"."Entry No.";
        }
        field(64; "Employee Entry No. SS"; Integer)
        {
            Caption = 'Nº Mov. Empleado SS';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Employee Ledger Entry"."Entry No.";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                ActualizarDimensionesEnEmpleado();
            end;
        }
        field(482; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                ActualizarDimensionesEnEmpleado();
            end;
        }
    }

    keys
    {
        key(Key1; Fecha, Departamento, Empleado, Numero)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        NominaCab: Record "Cabecera Nominas";
    begin
        // Actualizar cabecera
        if not NominaCab.Get(Fecha, Departamento) then begin
            NominaCab.Init();
            NominaCab.Fecha := Fecha;
            NominaCab.Departamento := Departamento;
            NominaCab.Insert();
        end;
        ActualizarCabecera();
    end;

    trigger OnModify()
    begin
        ActualizarCabecera();
    end;

    trigger OnDelete()
    var
        NominaCab: Record "Cabecera Nominas";
    begin
        if NominaCab.Get(Fecha, Departamento) then
            if NominaCab.Contabilizado then
                Error('No se puede modificar una nómina contabilizada');

        ActualizarCabecera();
    end;

    local procedure ActualizarCabecera()
    var
        NominaCab: Record "Cabecera Nominas";
        rNom: Record "Nominas Detalle";
    begin
        if not NominaCab.Get(Fecha, Departamento) then
            exit;

        // Recalcular totales desde el detalle
        rNom.Reset();
        rNom.SetRange(Fecha, Fecha);
        rNom.SetRange(Departamento, Departamento);

        NominaCab.Devengado := 0;
        NominaCab."S.S Obrero" := 0;
        NominaCab.IRPF := 0;
        NominaCab."SS empresa" := 0;
        NominaCab."Enfermedad Accidente" := 0;
        NominaCab.Banco := 0;
        NominaCab.Personal := 0;
        NominaCab."Bonificación" := 0;
        NominaCab."Bonificación Fundae" := 0;
        NominaCab.Kms := 0;
        NominaCab."Dto. Especie" := 0;
        NominaCab.Dieta := 0;
        NominaCab.Anticipos := 0;
        NominaCab.Embargos := 0;
        NominaCab."SS total" := 0;
        NominaCab.TC1 := 0;
        NominaCab.Coste := 0;
        NominaCab."Difª" := 0;
        NominaCab."P.P.Ex" := 0;
        NominaCab."MEJORA V" := 0;
        NominaCab.COMIDA := 0;
        NominaCab.DIETAS := 0;
        NominaCab."P.P Vaca" := 0;
        NominaCab."PL. FLEX" := 0;
        NominaCab.Indemni := 0;

        // Procesar todos los registros usando FindSet que garantiza incluir todos
        // Resetear el recordset para asegurar que incluya todos los registros
        if rNom.FindSet(true) then begin
            repeat
                NominaCab.Devengado += rNom.Devengado;
                NominaCab."S.S Obrero" += rNom."S.S Obrero";
                NominaCab.IRPF += rNom.IRPF;
                NominaCab."SS empresa" += rNom."SS empresa";
                NominaCab."Enfermedad Accidente" += rNom."Enfermedad Accidente";
                NominaCab.Banco += rNom.Banco;
                NominaCab.Personal += rNom.Personal;
                NominaCab."Bonificación" += rNom."Bonificación";
                NominaCab."Bonificación Fundae" += rNom."Bonificación Fundae";
                NominaCab.Kms += rNom.Kms;
                NominaCab."Dto. Especie" += rNom."Dto. Especie";
                NominaCab.Dieta += rNom.Dieta;
                NominaCab.Anticipos += rNom.Anticipos;
                NominaCab.Embargos += rNom.Embargos;
                NominaCab."SS total" += rNom."SS total";
                NominaCab.TC1 += rNom.TC1;
                NominaCab.Coste += rNom.Coste;
                NominaCab."Difª" += rNom."Difª";
                NominaCab."P.P.Ex" += rNom."P.P.Ex";
                NominaCab."MEJORA V" += rNom."MEJORA V";
                NominaCab.COMIDA += rNom.COMIDA;
                NominaCab.DIETAS += rNom.DIETAS;
                NominaCab."P.P Vaca" += rNom."P.P Vaca";
                NominaCab."PL. FLEX" += rNom."PL. FLEX";
                NominaCab.Indemni += rNom.Indemni;
            until rNom.Next() = 0;
        end;

        // Recalcular campos calculados
        NominaCab.Personal := NominaCab.Devengado - NominaCab."S.S Obrero" - NominaCab.IRPF - NominaCab.Anticipos - NominaCab.Embargos;
        NominaCab."Difª" := NominaCab.Banco - NominaCab.Personal;
        NominaCab.Modify(true);
    end;

    local procedure CalculaPersonal(): Decimal
    begin
        Exit(Devengado - "S.S Obrero" - IRPF - Embargos - Anticipos - "Ant.diet");
    end;

    local procedure RecalcularSSTotal()
    begin
        "SS total" := "S.S Obrero" + "SS empresa" - "Bonificación" - "Bonificación Fundae";
    end;

    local procedure RecalcularCosteYTC1()
    begin
        TC1 := CalculaTc1();
        Coste := Devengado + "SS total" - "Enfermedad Accidente";
    end;

    local procedure CalculaTc1(): Decimal
    begin
        Exit("SS total" - "Enfermedad Accidente");
    end;

    procedure CopiarDimensionesDesdeEmpleado(EmpleadoNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        GlSetup: Record "General Ledger Setup";
        ShortcutDimCode: array[8] of Code[20];
        DimCodesAccesoDirecto: array[8] of Code[20];
        i: Integer;
    begin
        Clear(ShortcutDimCode);
        Clear("Shortcut Dimension 1 Code");
        Clear("Shortcut Dimension 2 Code");
        "Dimension Set ID" := 0;
        if EmpleadoNo = '' then
            exit;

        ObtenerShortcutDimDesdeEmpleado(EmpleadoNo, ShortcutDimCode);

        for i := 1 to 8 do
            if ShortcutDimCode[i] <> '' then
                ValidateShortcutDimCode(i, ShortcutDimCode[i]);

        GlSetup.Get();
        DimCodesAccesoDirecto[1] := GlSetup."Global Dimension 1 Code";
        DimCodesAccesoDirecto[2] := GlSetup."Global Dimension 2 Code";
        DimCodesAccesoDirecto[3] := GlSetup."Shortcut Dimension 3 Code";
        DimCodesAccesoDirecto[4] := GlSetup."Shortcut Dimension 4 Code";
        DimCodesAccesoDirecto[5] := GlSetup."Shortcut Dimension 5 Code";
        DimCodesAccesoDirecto[6] := GlSetup."Shortcut Dimension 6 Code";
        DimCodesAccesoDirecto[7] := GlSetup."Shortcut Dimension 7 Code";
        DimCodesAccesoDirecto[8] := GlSetup."Shortcut Dimension 8 Code";

        if "Dimension Set ID" <> 0 then
            DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");

        DefaultDimension.SetRange("Table ID", DATABASE::Employee);
        DefaultDimension.SetRange("No.", EmpleadoNo);
        if DefaultDimension.FindSet() then
            repeat
                if not EsCodigoDimensionAccesoDirecto(DefaultDimension."Dimension Code", DimCodesAccesoDirecto) then
                    AgregarDimensionConjuntoTemporal(TempDimSetEntry, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
            until DefaultDimension.Next() = 0;

        if not TempDimSetEntry.IsEmpty() then
            "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);

        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
        "Shortcut Dimension 1 Code" := ShortcutDimCode[1];
        "Shortcut Dimension 2 Code" := ShortcutDimCode[2];
    end;

    local procedure ObtenerShortcutDimDesdeEmpleado(EmpleadoNo: Code[20]; var ShortcutDimCode: array[8] of Code[20])
    var
        Employee: Record Employee;
        DefaultDimension: Record "Default Dimension";
        GlSetup: Record "General Ledger Setup";
        DimCodes: array[8] of Code[20];
        i: Integer;
    begin
        Clear(ShortcutDimCode);
        if not Employee.Get(EmpleadoNo) then
            exit;

        GlSetup.Get();
        DimCodes[1] := GlSetup."Global Dimension 1 Code";
        DimCodes[2] := GlSetup."Global Dimension 2 Code";
        DimCodes[3] := GlSetup."Shortcut Dimension 3 Code";
        DimCodes[4] := GlSetup."Shortcut Dimension 4 Code";
        DimCodes[5] := GlSetup."Shortcut Dimension 5 Code";
        DimCodes[6] := GlSetup."Shortcut Dimension 6 Code";
        DimCodes[7] := GlSetup."Shortcut Dimension 7 Code";
        DimCodes[8] := GlSetup."Shortcut Dimension 8 Code";

        ShortcutDimCode[1] := Employee."Global Dimension 1 Code";
        ShortcutDimCode[2] := Employee."Global Dimension 2 Code";

        DefaultDimension.SetRange("Table ID", DATABASE::Employee);
        DefaultDimension.SetRange("No.", EmpleadoNo);
        if DefaultDimension.FindSet() then
            repeat
                for i := 1 to 8 do
                    if (DimCodes[i] <> '') and (DefaultDimension."Dimension Code" = DimCodes[i]) then
                        ShortcutDimCode[i] := DefaultDimension."Dimension Value Code";
            until DefaultDimension.Next() = 0;
    end;

    local procedure EsCodigoDimensionAccesoDirecto(DimensionCode: Code[20]; DimCodesAccesoDirecto: array[8] of Code[20]): Boolean
    var
        i: Integer;
    begin
        for i := 1 to 8 do
            if DimCodesAccesoDirecto[i] = DimensionCode then
                exit(true);
        exit(false);
    end;

    local procedure AgregarDimensionConjuntoTemporal(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        if (DimensionCode = '') or (DimensionValueCode = '') then
            exit;
        if not DimValue.Get(DimensionCode, DimensionValueCode) then
            exit;

        TempDimSetEntry.Reset();
        TempDimSetEntry.SetRange("Dimension Code", DimensionCode);
        if TempDimSetEntry.FindFirst() then begin
            if TempDimSetEntry."Dimension Value Code" = DimensionValueCode then
                exit;
            TempDimSetEntry."Dimension Value Code" := DimensionValueCode;
            TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
            TempDimSetEntry.Modify();
        end else begin
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Code" := DimensionCode;
            TempDimSetEntry."Dimension Value Code" := DimensionValueCode;
            TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
            TempDimSetEntry.Insert();
        end;
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" :=
            DimMgt.EditDimensionSet(
                Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), Empleado, Fecha),
                "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        ActualizarDimensionesEnEmpleado();
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    local procedure ActualizarDimensionesEnEmpleado()
    var
        Employee: Record Employee;
        DimMgt: Codeunit DimensionManagement;
    begin
        if Empleado = '' then
            exit;
        if not Employee.Get(Empleado) then
            exit;
        if (Employee."Global Dimension 1 Code" = "Shortcut Dimension 1 Code") and
           (Employee."Global Dimension 2 Code" = "Shortcut Dimension 2 Code")
        then
            exit;

        Employee.Validate("Global Dimension 1 Code", "Shortcut Dimension 1 Code");
        Employee.Validate("Global Dimension 2 Code", "Shortcut Dimension 2 Code");
        Employee.Modify(true);

        DimMgt.SaveDefaultDim(DATABASE::Employee, Empleado, 1, "Shortcut Dimension 1 Code");
        DimMgt.SaveDefaultDim(DATABASE::Employee, Empleado, 2, "Shortcut Dimension 2 Code");
    end;
}


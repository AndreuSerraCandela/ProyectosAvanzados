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
                Personal := CalculaPersonal();
                TC1 := CalculaTc1();
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
                "SS total" := "SS empresa" - "Bonificación" - "Bonificación Fundae";
                TC1 := CalculaTc1();
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
                TC1 := CalculaTc1();
            end;
        }
        field(47; "Bonificación Fundae"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación Fundae';
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                TC1 := CalculaTc1();
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
        Exit(Devengado - "S.S Obrero" - IRPF - Embargos - Anticipos);
    end;

    local procedure CalculaTc1(): Decimal
    begin
        Exit("S.S Obrero" + "SS empresa" - "Enfermedad Accidente" - "Bonificación" - "Bonificación Fundae");
    end;
}


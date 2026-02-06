/// <summary>
/// Table Nominas Configuración (ID 50215).
/// Configuración de cuentas contables para la contabilización de nóminas
/// </summary>
table 50215 "Nominas Configuración"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(2; Texto; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Empleado (blanco=todos)';
        }
        field(4; Devengado; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Devengado';
            TableRelation = "G/L Account";
        }
        field(5; "S.S Obrero"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'S.S Obrero';
            TableRelation = "G/L Account";
        }
        field(6; IRPF; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'IRPF';
            TableRelation = "G/L Account";
        }
        field(7; "SS empresa"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'SS empresa';
            TableRelation = "G/L Account";
        }
        field(8; "Enfermedad Accidente"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Enfermedad Accidente';
            TableRelation = "G/L Account";
        }
        field(9; "SS total"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'SS total';
            Editable = true;
            TableRelation = "G/L Account";
        }
        field(10; TC1; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'TC1';
            Editable = true;
            TableRelation = "G/L Account";
        }
        field(11; Coste; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Coste';
            Editable = true;
            TableRelation = "G/L Account";
        }
        field(12; Banco; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Banco';
            TableRelation = "Bank Account";
        }
        field(13; Personal; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Personal';
            Editable = true;
            TableRelation = "G/L Account";
        }
        field(14; "Bonificación Fundae"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación Fundae';
            TableRelation = "G/L Account";
        }
        field(17; "Bonificación"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación';
            TableRelation = "G/L Account";
        }
        field(18; Kms; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Kms';
            TableRelation = "G/L Account";
        }
        field(69; "Especie Debe"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Especie Debe';
            TableRelation = "G/L Account";
        }
        field(66; "Especie Haber"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Especie Haber';
            TableRelation = "G/L Account";
        }
        field(67; "Dieta"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Dieta';
            TableRelation = "G/L Account";
        }
        field(19; Anticipos; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Anticipos';
            TableRelation = "G/L Account";
        }
        field(65; Embargos; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Embargos';
            TableRelation = "G/L Account";
        }
        field(20; "Cuota Sindical"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cuota Sindical';
            TableRelation = "G/L Account";
        }
        field(21; Diferencia; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Diferencia';
            Editable = true;
            TableRelation = "G/L Account";
        }
        field(22; "SS empresa 2"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'SS empresa 2';
            TableRelation = "G/L Account";
        }
        field(23; "Enfermedad Accidente 2"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Enfermedad Accidente 2';
            TableRelation = "G/L Account";
        }
        field(24; "Cobro Nómina"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cobro Nómina';
            TableRelation = "G/L Account";
        }
        field(80; "Ant.diet"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Ant.diet';
            TableRelation = "G/L Account";
        }
        field(25; Alquileres; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Alquileres';
            TableRelation = "G/L Account";
        }
        field(26; "P. Vacaciones"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'P. Vacaciones';
            TableRelation = "G/L Account";
        }
        field(27; "F. Vacaciones"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'F. Vacaciones';
            TableRelation = "G/L Account";
        }
        field(28; "P. Vacaciones2"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'P. Vacaciones2';
            TableRelation = "G/L Account";
        }
        field(29; "F. Vacaciones2"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'F. Vacaciones2';
            TableRelation = "G/L Account";
        }
        field(54; "Programa por defecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Programa por defecto';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(55; "Departamento TMP"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Departamento TMP';
        }
        field(56; "Nominas extra"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Nominas extra';
            TableRelation = "G/L Account";
        }
        field(57; "Pago Nominas"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Pago Nominas';
            TableRelation = "G/L Account";
        }
        field(59; Departamento; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Departamento';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(60; Programa; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Programa';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(61; "Ctrp Nominas extra"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Ctrp Nominas extra';
            TableRelation = "G/L Account";
        }
        field(68; "Recurso Facturación"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Recurso Facturación';
            TableRelation = Resource;
        }
        field(75; "Dígitos Subcuenta"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Dígitos Subcuenta por Defecto';
            MinValue = 0;
            MaxValue = 20;
            ToolTip = 'Especifica el número de dígitos de subcuenta que se añadirán a las cuentas base. Ejemplo: si son 7 dígitos, la cuenta 640 se convertirá en 6400001';
        }
        field(70; "Global Dimension 1 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionClass = '1,2,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(71; "Global Dimension 2 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionClass = '1,2,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(72; "Global Dimension 3 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionClass = '1,2,3';
            Caption = 'Global Dimension 3 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3));
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(3, "Global Dimension 3 Code");
            end;
        }
        field(73; "Global Dimension 4 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionClass = '1,2,4';
            Caption = 'Global Dimension 4 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4));
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(4, "Global Dimension 4 Code");
            end;
        }
        field(74; "Global Dimension 5 Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionClass = '1,2,5';
            Caption = 'Global Dimension 5 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5));
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(5, "Global Dimension 5 Code");
            end;
        }
    }

    keys
    {
        key(Key1; Texto)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit "DimensionManagement";
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Nominas Configuración", Texto, FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    /// <summary>
    /// Construye una cuenta completa añadiendo los dígitos de subcuenta configurados
    /// </summary>
    local procedure ConstruirCuenta(CuentaBase: Code[20]): Code[20]
    var
        Subcuenta: Text;
        i: Integer;
        CuentaCompleta: Code[20];
    begin
        if "Dígitos Subcuenta" > 0 then begin
            // Construir subcuenta con ceros a la izquierda y 1 al final
            Subcuenta := '';
            for i := 1 to "Dígitos Subcuenta" - 1 do
                Subcuenta += '0';
            Subcuenta += '1';
            CuentaCompleta := CopyStr(CuentaBase + Subcuenta, 1, MaxStrLen(CuentaCompleta));
            exit(CuentaCompleta);
        end else
            exit(CuentaBase);
    end;

    /// <summary>
    /// Rellena la configuración con las cuentas habituales del plan general contable español para nóminas
    /// Añade los dígitos de subcuenta configurados si están definidos
    /// </summary>
    procedure RellenarCuentasPorDefecto()
    var
        GLAccount: Record "G/L Account";
        CuentaNoEncontrada: Text;
        CuentaBase: Code[20];
        CuentaCompleta: Code[20];
    begin
        CuentaNoEncontrada := '';

        // Devengado - 640 Sueldos y salarios
        CuentaBase := '640';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Devengado := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Devengado := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (Devengado), ';

        // S.S Obrero - 476 Organismos de la Seguridad Social, acreedores
        CuentaBase := '476';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "S.S Obrero" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "S.S Obrero" := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (S.S Obrero), ';

        // IRPF - 4751 Hacienda Pública, acreedora por retenciones practicadas
        CuentaBase := '4751';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            IRPF := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            IRPF := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (IRPF), ';

        // SS empresa - 642 Seguridad Social a cargo de la empresa
        CuentaBase := '642';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "SS empresa" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "SS empresa" := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (SS empresa), ';

        // SS empresa 2 - 642 Seguridad Social a cargo de la empresa
        CuentaBase := '642';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "SS empresa 2" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "SS empresa 2" := CuentaBase;

        // Enfermedad Accidente - 642 Seguridad Social a cargo de la empresa
        CuentaBase := '642';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "Enfermedad Accidente" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "Enfermedad Accidente" := CuentaBase;

        // Enfermedad Accidente 2 - 630 Gastos de personal
        CuentaBase := '630';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "Enfermedad Accidente 2" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "Enfermedad Accidente 2" := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (Enfermedad Accidente 2), ';

        // Bonificación - 749 Otros ingresos de gestión
        CuentaBase := '749';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Bonificación := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Bonificación := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (Bonificación), ';

        // Bonificación Fundae - 749 Otros ingresos de gestión
        CuentaBase := '749';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "Bonificación Fundae" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "Bonificación Fundae" := CuentaBase;

        // Kms - 624 Transportes
        CuentaBase := '624';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Kms := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Kms := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (Kms), ';

        // Dieta - 625 Primas de seguros o 640 Sueldos y salarios
        CuentaBase := '625';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Dieta := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Dieta := CuentaBase
        else begin
            CuentaBase := '640';
            CuentaCompleta := ConstruirCuenta(CuentaBase);
            if GLAccount.Get(CuentaCompleta) then
                Dieta := CuentaCompleta
            else if GLAccount.Get(CuentaBase) then
                Dieta := CuentaBase
            else
                CuentaNoEncontrada += '625/640 (Dieta), ';
        end;

        // Especie Debe - 640 Sueldos y salarios
        CuentaBase := '640';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "Especie Debe" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "Especie Debe" := CuentaBase;

        // Especie Haber - 640 Sueldos y salarios
        CuentaBase := '640';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "Especie Haber" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "Especie Haber" := CuentaBase;

        // Anticipos - 465 Remuneraciones pendientes de pago
        CuentaBase := '465';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Anticipos := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Anticipos := CuentaBase
        else
            CuentaNoEncontrada += CuentaCompleta + ' (Anticipos), ';

        // Embargos - 465 Remuneraciones pendientes de pago
        CuentaBase := '465';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Embargos := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Embargos := CuentaBase;

        // Personal - 465 Remuneraciones pendientes de pago
        CuentaBase := '465';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            Personal := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            Personal := CuentaBase;

        // Cobro Nómina - 465 Remuneraciones pendientes de pago
        CuentaBase := '465';
        CuentaCompleta := ConstruirCuenta(CuentaBase);
        if GLAccount.Get(CuentaCompleta) then
            "Cobro Nómina" := CuentaCompleta
        else if GLAccount.Get(CuentaBase) then
            "Cobro Nómina" := CuentaBase;

        // Nota: Banco se debe configurar manualmente ya que depende de cada empresa
        // El usuario debe seleccionar la cuenta de banco correspondiente

        Modify();

        // Mostrar advertencia si alguna cuenta no se encontró
        if CuentaNoEncontrada <> '' then
            Message('Las siguientes cuentas no se encontraron en el plan contable y no se asignaron:\ %1\ \Por favor, configúrelas manualmente.', CopyStr(CuentaNoEncontrada, 1, StrLen(CuentaNoEncontrada) - 2));
    end;
}


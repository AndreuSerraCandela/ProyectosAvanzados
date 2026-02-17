/// <summary>
/// Table Cabecera Nominas (ID 50217).
/// Cabecera de nóminas por empresa y fecha
/// </summary>
table 50217 "Cabecera Nominas"
{
    DataClassification = ToBeClassified;
    LookupPageId = "Lista Nominas";
    DrillDownPageId = "Lista Nominas";

    fields
    {
        field(2; Fecha; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Fecha';
        }
        field(3; Contabilizado; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Contabilizado';
            InitValue = false;
        }
        field(4; "Nº Documento"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Nº Documento';
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
        }
        field(15; "S.S Obrero"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'S.S Obrero';
            AutoFormatType = 1;
        }
        field(16; IRPF; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'IRPF';
            AutoFormatType = 1;
        }
        field(17; "SS empresa"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SS empresa';
            AutoFormatType = 1;
        }
        field(19; "SS total"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'SS total';
            AutoFormatType = 1;
        }
        field(20; TC1; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'TC1';
            AutoFormatType = 1;
        }
        field(21; Coste; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Coste';
            AutoFormatType = 1;
        }
        field(24; "Difª"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Diferencia';
            AutoFormatType = 1;
        }
        field(18; "Enfermedad Accidente"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Enfermedad Accidente';
            AutoFormatType = 1;
        }
        field(22; Banco; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Banco';
            AutoFormatType = 1;
        }
        field(23; Personal; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Personal';
            AutoFormatType = 1;
            Editable = false;
        }
        field(27; "Bonificación"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación';
            AutoFormatType = 1;
        }
        field(47; "Bonificación Fundae"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Bonificación Fundae';
            AutoFormatType = 1;
        }
        field(28; Kms; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Kms';
            AutoFormatType = 1;
        }
        field(48; "Dto. Especie"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Dto. Especie';
            AutoFormatType = 1;
        }
        field(49; Dieta; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Dieta';
            AutoFormatType = 1;
        }
        field(29; Anticipos; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Anticipos';
            AutoFormatType = 1;
        }
        field(39; Embargos; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Embargos';
            AutoFormatType = 1;
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
        field(53; DIETAS; Decimal)
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
    }

    keys
    {
        key(Key1; Fecha, Departamento)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        rNom: Record "Nominas Detalle";
    begin
        rNom.SetRange(Fecha, Fecha);
        rNom.SetRange(Departamento, Departamento);
        rNom.DeleteAll();
    end;
}


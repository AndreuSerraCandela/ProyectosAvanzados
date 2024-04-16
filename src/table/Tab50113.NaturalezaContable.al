table 50113 "Naturaleza Contable"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Code; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Code', comment = 'ESP="Caption"';

        }
        field(2; Descripcion; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Cuenta"; Code[20])
        {
            TableRelation = "G/L Account"."No.";
        }
    }

    keys
    {
        key(Key1; code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}
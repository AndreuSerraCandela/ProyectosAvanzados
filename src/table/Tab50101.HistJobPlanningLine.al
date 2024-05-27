table 50101 "Hist. Job Planning Line"
{
    DrillDownPageId = 50112;
    LookupPageId = 50112;
    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(22; "Version Date"; Date)
        {
            Caption = 'Version Date';
            Editable = false;
        }
        field(23; "Version No."; Integer)
        {
            Caption = 'Version No.';
            Editable = false;
        }
        field(5; Type; Enum "Job Planning Line Type")
        {
            Caption = 'Type';
            Editable = false;

        }
        field(7; "No."; Code[20])
        {
            Editable = false;
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const(Item)) Item where(Blocked = const(false))
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Text)) "Standard Text";


        }
        field(8; Description; Text[100])
        {
            Editable = false;
            Caption = 'Description';


        }
        field(2; "Job No."; Code[20])
        {
            Editable = false;
            //Caption = 'Job No.';
            Caption = 'No. Proyecto';
            NotBlank = true;
            TableRelation = Job;
        }
        field(1000; "Job Task No."; Code[20])
        {
            // Caption = 'Job Task No.';
            Caption = 'Proyecto No. Tarea';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(9; Quantity; Decimal)
        {
            Editable = false;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;


        }
        field(11; "Direct Unit Cost (LCY)"; Decimal)
        {
            Editable = false;
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost (LCY)';


        }
        field(12; "Unit Cost (LCY)"; Decimal)
        {
            Editable = false;
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';



        }
        field(13; "Total Cost (LCY)"; Decimal)
        {
            Editable = false;
            AutoFormatType = 1;
            Caption = 'Total Cost (LCY)';

        }
        field(14; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            Editable = false;


        }
        field(15; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(1003; "Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            Editable = false;
        }
        field(1023; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;


        }
        field(1005; "Total Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            Editable = false;
        }
        field(50100; "Cód.Estimacion"; Code[20])
        {
            DataClassification = ToBeClassified;
            //este codigo se rellena en la accion del boton que lo pone el usuario;
        }
    }
    keys
    {
        key(PK; "Line No.", "Job No.", "Job Task No.", "Version No.")
        {
            Clustered = true;
        }

    }
}
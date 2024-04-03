page 50112 "Hist. Job planning line"
{
    PageType = List;
    SourceTable = "Hist. Job Planning Line";
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(Content)
        {
            repeater(Detalle)
            {
                field("Line No."; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }
                field("Version Date"; Rec."Version Date")
                {
                    Caption = 'Version Date';
                    Editable = false;
                }
                field("Version No."; Rec."Version No.")
                {
                    Caption = 'Version No.';
                    Editable = false;
                }
                field(Type; Rec.Type)
                {
                    Caption = 'Type';
                    Editable = false;

                }
                field("No."; Rec."No.")
                {
                    Editable = false;
                    Caption = 'No.';



                }
                field(Description; Rec.Description)
                {
                    Editable = false;
                    Caption = 'Description';


                }
                field("Job No."; Rec."Job No.")
                {
                    Editable = false;
                    Caption = 'Job No.';

                }
                field("Job Task No."; rec."Job Task No.")
                {
                    Editable = false;
                    //Caption = 'Job Task No.';
                    Caption = 'No. tarea proyecto';
                }
                field(Quantity; Rec.Quantity)
                {
                    Editable = false;
                    Caption = 'Quantity';



                }
                field("Direct Unit Cost (LCY)"; Rec."Direct Unit Cost (LCY)")
                {
                    Editable = false;
                    AutoFormatType = 2;
                    Caption = 'Direct Unit Cost (LCY)';


                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    Editable = false;
                    AutoFormatType = 2;
                    Caption = 'Unit Cost (LCY)';



                }
                field("Total Cost (LCY)"; Rec."Total Cost (LCY)")
                {
                    Editable = false;
                    AutoFormatType = 1;
                    Caption = 'Total Cost (LCY)';

                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    AutoFormatType = 2;
                    Caption = 'Unit Price (LCY)';
                    Editable = false;


                }
                field("Total Price (LCY)"; Rec."Total Price (LCY)")
                {
                    AutoFormatType = 1;
                    Caption = 'Total Price (LCY)';
                    Editable = false;
                }
            }
        }
    }
}
table 50202 "Job Status History"
{
    DrillDownPageId = 50113;
    LookupPageId = 50113;
    fields
    {
        field(1; "Job No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Date&Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(4; "User ID"; Code[50])
        {
            DataClassification = CustomerContent;
            TableRelation = User."User Name";
        }
        field(5; "Old Status"; Enum "Estado Proyecto")
        {
            DataClassification = CustomerContent;

        }
        field(6; "New Status"; Enum "Estado Proyecto")
        {
            DataClassification = CustomerContent;
        }

    }
    keys
    {
        key(PK; "Job No.", "Date&Time")
        {
            Clustered = true;
        }
    }
}


tableextension 50105 "CompanyInf" extends "Company Information" //79
{
    fields
    {
        field(50000; "Invoice Legal Text"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Invoice Legal Text';
        }
    }

    var
        myInt: Integer;
}
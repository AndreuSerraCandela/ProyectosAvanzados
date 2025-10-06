tableextension 50113 "Purch. Inv. Header" extends "Purch. Inv. Header" //122
{
    fields
    {
        // Add changes to table fields here
        field(50100; "No. Proyecto"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Proyecto';
            TableRelation = Job."No.";
        }
        field(90200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
    }

    var
        myInt: Integer;
        WorkDescription: Text;

    procedure GetWorkDescription(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo("Work Description"));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;
}
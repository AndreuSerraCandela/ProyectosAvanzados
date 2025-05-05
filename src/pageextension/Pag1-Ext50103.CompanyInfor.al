pageextension 50103 "CompanyInfor" extends "Company Information" //1
{
    layout
    {
        addlast(General)
        {
            field(legalTextTxt; legalTextTxt)
            {
                ApplicationArea = all;

                trigger OnValidate()
                var
                begin
                    Rec."Invoice Legal Text".CreateOutStream(varOutStream);
                    varOutStream.WriteText(legalTextTxt);
                    Rec.Modify();
                end;
            }
        }
    }


    trigger OnOpenPage()
    var

    begin
        Rec.CalcFields("Invoice Legal Text");
        Rec."Invoice Legal Text".CreateInStream(varInStream);
        varInStream.ReadText(legalTextTxt);
    end;

    var
        varInStream: InStream;
        varOutStream: OutStream;
        legalTextTxt: Text;

}
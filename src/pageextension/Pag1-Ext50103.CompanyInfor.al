pageextension 50303 "CompanyInfor" extends "Company Information" //1
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
            field("Url Pdf"; Rec."Url Pdf")
            {
                ApplicationArea = all;
            }

            field("Pdfs Adjunto"; CountPdfs())
            {
                ApplicationArea = all;
                trigger OnAssistEdit()
                begin
                    Page.RunModal(Page::"Adjuntos Informe");
                end;
            }
            field("Cta Contable Estructura"; Rec."Cta Contable Estructura")
            {
                ApplicationArea = all;
            }
            field("Cta Contable Movs."; Rec."Cta Contable Mov")
            {
                ApplicationArea = all;
            }


        }
    }
    actions
    {
        // addlast(processing)
        // {
        //     action(ImportarPdfAdjunto)
        //     {
        //         ApplicationArea = all;
        //         Caption = 'Importar Pdf Adjunto';
        //         trigger OnAction()
        //         var
        //             FileManagement: Codeunit "File Management";
        //             TempBlob: Codeunit "Temp Blob";
        //             varInStream: InStream;
        //             varOutStream: OutStream;
        //             FileName: Text;
        //         begin
        //             If UploadIntoStream('Importar Pdf Adjunto', '', 'PDF (*.PDF)|*.PDF', FileName, varInStream) then begin
        //                 Rec."Pdf Adjunto".ImportStream(varInStream, FileName);
        //                 Rec.Modify();
        //             end;
        //         end;
        //     }
        // }
    }


    trigger OnOpenPage()
    var

    begin
        Rec.CalcFields("Invoice Legal Text");
        Rec."Invoice Legal Text".CreateInStream(varInStream);
        varInStream.ReadText(legalTextTxt);
    end;

    local procedure CountPdfs(): Integer
    var
        AdjuntosInforme: Record "Adjuntos Informe";
    begin
        exit(AdjuntosInforme.Count());
    end;

    var
        varInStream: InStream;
        varOutStream: OutStream;
        legalTextTxt: Text;

}
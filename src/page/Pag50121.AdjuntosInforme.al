page 50123 "Adjuntos Informe"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Adjuntos Informe";
    Caption = 'Adjuntos Informe';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No. Informe"; Rec."No. Informe")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del informe';
                    Lookup = true;
                }
                field("Pdf Adjunto"; Rec."Pdf Adjunto")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el PDF adjunto para este informe';
                }
                field(InformeName; GetInformeName())
                {
                    ApplicationArea = All;
                    Caption = 'Nombre del Informe';
                    ToolTip = 'Muestra el nombre del informe seleccionado';
                    Editable = false;
                }
                field(HasAttachment; Rec."Pdf Adjunto".HasValue())
                {
                    ApplicationArea = All;
                    Caption = 'Tiene Adjunto';
                    ToolTip = 'Indica si el informe tiene un PDF adjunto';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportarPDF)
            {
                ApplicationArea = All;
                Caption = 'Importar PDF';
                ToolTip = 'Importa un archivo PDF para el informe seleccionado';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    varInStream: InStream;
                    varOutStream: OutStream;
                    FileName: Text;
                begin
                    If UploadIntoStream('Importar Pdf Adjunto', '', 'PDF (*.PDF)|*.PDF', FileName, varInStream) then begin
                        Rec."Pdf Adjunto".ImportStream(varInStream, FileName);
                        Rec.Modify();
                    end;
                end;
            }
            action("Exportar PDF")
            {
                ApplicationArea = All;
                Caption = 'Exportar PDF';
                ToolTip = 'Exporta el PDF adjunto del informe seleccionado';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    ExportarPDF();
                end;
            }
            action("Eliminar PDF")
            {
                ApplicationArea = All;
                Caption = 'Eliminar PDF';
                ToolTip = 'Elimina el PDF adjunto del informe seleccionado';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    EliminarPDF();
                end;
            }

        }

    }

    trigger OnAfterGetRecord()
    begin
        // Actualizar información del informe
    end;

    local procedure GetInformeName(): Text
    var
        AllObj: Record AllObj;
    begin
        if Rec."No. Informe" = 0 then
            exit('');

        AllObj.SetRange("Object Type", AllObj."Object Type"::Report);
        AllObj.SetRange("Object ID", Rec."No. Informe");
        if AllObj.FindFirst() then
            exit(AllObj."Object Name")
        else
            exit('Informe no encontrado');
    end;



    local procedure ExportarPDF()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
    begin
        if not Rec."Pdf Adjunto".HasValue() then begin
            Message('No hay PDF adjunto para exportar.');
            exit;
        end;

        FileName := 'Informe_' + Format(Rec."No. Informe") + '.pdf';
        TempBlob.CreateOutStream(OutStream);
        Rec."Pdf Adjunto".ExportStream(OutStream);
        TempBlob.CreateInStream(InStream);

        DownloadFromStream(InStream, 'Exportar PDF', '', '', FileName);
    end;

    local procedure EliminarPDF()
    begin
        if not Rec."Pdf Adjunto".HasValue() then begin
            Message('No hay PDF adjunto para eliminar.');
            exit;
        end;

        if Confirm('¿Está seguro de que desea eliminar el PDF adjunto del informe %1?', false, Rec."No. Informe") then begin
            Clear(Rec."Pdf Adjunto");
            Rec.Modify(true);
            Message('PDF eliminado correctamente.');
        end;
    end;


}

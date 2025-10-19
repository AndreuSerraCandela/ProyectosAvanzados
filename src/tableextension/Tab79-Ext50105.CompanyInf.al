tableextension 50305 "CompanyInf" extends "Company Information" //79
{
    fields
    {
        field(50000; "Invoice Legal Text"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Invoice Legal Text';
        }
        field(50001; "Url Pdf"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Url Pdf';
        }
        field(50002; "Informes con Pdf Adjunto"; Text[1024])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla 50115 "Adjuntos Informe"';
            ObsoleteTag = '50105';
            DataClassification = ToBeClassified;
            Caption = 'Informes con Pdf Adjunto';
            ToolTip = 'Id de informme, separado por ;';
            // trigger OnLookup()
            // var
            //     Informes: Record AllObj;
            // begin
            //     Informes.SetRange("Object Type", Informes."Object Type"::Report);
            //     if Page.RunModal(Page::"All Objects", Informes) = Action::LookupOK then begin
            //         if "Informes con Pdf Adjunto" = '' then
            //             "Informes con Pdf Adjunto" := Format(Informes."Object ID")
            //         else
            //             "Informes con Pdf Adjunto" := "Informes con Pdf Adjunto" + ';' + Format(Informes."Object ID");
            //     end;
            // end;
        }
        field(50003; "Pdf Adjunto"; Media)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Se ha reemplazado por la tabla 50115 "Adjuntos Informe"';
            ObsoleteTag = '50105';
            DataClassification = ToBeClassified;
            Caption = 'Pdf Adjunto';
        }
    }

    var
        myInt: Integer;
}
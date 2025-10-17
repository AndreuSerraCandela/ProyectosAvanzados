table 50115 "Adjuntos Informe"
{
    fields
    {
        field(1; "No. Informe"; Integer)
        {
            Caption = 'No. Informe';
            trigger OnLookup()
            var
                Informe: Record AllObj;
            begin
                Informe.SetRange("Object Type", Informe."Object Type"::Report);
                if Page.RunModal(Page::"All Objects", Informe) = Action::LookupOK then
                    Rec."No. Informe" := Informe."Object ID";
            end;
        }
        field(2; "Pdf Adjunto"; Media)
        {
            Caption = 'Pdf Adjunto';
        }
    }
}
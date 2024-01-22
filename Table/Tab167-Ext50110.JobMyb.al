tableextension 50110 "JobMyb" extends Job //167
{
    fields
    {
        field(50100; "Cód Oferta Job"; Code[20])
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                myInt: Integer;
                LinePlani: Record "Job Planning Line";

            begin
                // if rec."Cód Oferta Job" <> xRec."Cód Oferta Job" then begin
                LinePlani.SetFilter(LinePlani."Job No.", rec."No.");
                LinePlani.SetFilter(LinePlani."Cód Oferta Job", '%1', '');
                if LinePlani.FindSet(true, false) then begin
                    LinePlani.ModifyAll("Cód Oferta Job", rec."Cód Oferta Job");
                end;
                //end;

            end;
        }
    }
    procedure AddOfertaaProyecto()
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        SetupJob: Record "Jobs Setup";
    begin
        SetupJob.Get();
        if rec."Cód Oferta Job" = '' then begin
            SetupJob.TestField("No. serie Ofertas en Proyectos");
            // NoSeriesMgt.TestManual(SetupJob."No. serie Ofertas en Proyectos");
            //    NoSeriesMgt.GetNoSeriesWithCheck(SetupJob."No. serie Ofertas en Proyectos", true, rec."Cód Oferta Job");
            rec.validate("Cód Oferta Job", NoSeriesMgt.DoGetNextNo(SetupJob."No. serie Ofertas en Proyectos", 0D, true, false));
        end;
    end;


    var
        myInt: Integer;


}
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
                if LinePlani.FindSet() then begin
                    LinePlani.ModifyAll("Cód Oferta Job", rec."Cód Oferta Job");
                end;
                //end;

            end;
        }
        field(50300; "Project Status"; Enum "Estado Proyecto")
        {
            //Caption = '';
            Caption = 'Project Status', comment = 'ESP="Estado Proyecto"';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                Hist: Record "Job Status History";
            begin
                case "Project Status" of
                    "Project Status"::"In Quote":
                        begin
                            rec.Validate(Status, Status::Quote);
                        end;
                    "Project Status"::"Awarded in execution":
                        begin
                            Status := Status::Open;

                        end;
                    "Project Status"::"Awarded Finished":
                        begin
                            Status := Status::Completed;

                        end;
                    "Project Status"::"Awarded as a guarantee":
                        begin
                            Status := Status::Open;

                        end;
                    "Project Status"::"Not awarded":
                        begin
                            Status := Status::Completed;

                        end;

                end;
                if Rec.Status <> xRec.Status then
                    Rec.Modify();
                Hist."Job No." := rec."No.";
                Hist."New Status" := rec."Project Status";
                Hist."Old Status" := xRec."Project Status";
                Hist."Date&Time" := CurrentDateTime;
                Hist."User ID" := UserId;
                Hist.Insert();
            end;
        }
        field(50102; "Versión Base"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                HistJobPlanningLine: Record "Hist. Job Planning Line";
                Ver: Integer;
                JobTask: Record "Job Task";
            begin
                HistJobPlanningLine.SetRange("Job No.", Rec."No.");
                if HistJobPlanningLine.FindLast() then
                    Ver := HistJobPlanningLine."Version No.";
                if rec."Versión Base" = 0 then
                    rec."Versión Base" := 1;
                if rec."Versión Base" > Ver then Rec."Versión Base" := Ver;
                JobTask.SetRange("Job No.", rec."No.");
                JobTask.ModifyAll("Versión Base", rec."Versión Base");
            end;
        }
        field(50103; "Cod Almacen de Proyecto"; code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cod.Almacen Proyecto almacen';
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
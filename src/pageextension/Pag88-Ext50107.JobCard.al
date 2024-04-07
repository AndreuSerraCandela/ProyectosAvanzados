pageextension 50107 "JobCard" extends "Job Card" //88
{
    layout
    {
        // Add changes to page layout here
        addafter("Your Reference")
        {

            field("Cód Oferta Job"; Rec."Cód Oferta Job")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Cód Oferta Job field.';
                Visible = false;
            }
            field("Cod Almacen de Proyecto"; Rec."Cod Almacen de Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Nomenglatura Proyecto almacen field.';
                Editable = false;
                DrillDown = true;
            }


        }
        addafter("Sell-to Customer Name")
        {

            field("Project Status"; Rec."Project Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Project Status field.', Comment = 'ESP="Estado Proyecto"';
            }
            field("Versión Base"; rec."Versión Base")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Versión Base field.', Comment = 'ESP="Versión Base"';
            }
        }
    }

    actions
    {

        addlast("&Job")
        {
            // Action("Indentar-")
            // {

            //     ShortCutKey = 'Ctrl+Left';
            //     ToolTipML = ENU = '(Ctrl+Left)',
            //                      ESP = '(Ctrl+Izquierda)';
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedIsBig = true;
            //     Image = CancelIndent;
            //     PromotedOnly = true;
            //     trigger OnAction()
            //     BEGIN
            //         IF Rec.COUNT() = 0 THEN
            //             EXIT;
            //         IF Rec.Indentation > 0 THEN
            //             Rec.Indentation -= 1;
            //         Rec.MODIFY;
            //         CurrPage.UPDATE
            //     END;
            // }
            // action("Indentar+")
            // {

            //     ShortCutKey = 'Ctrl+Right';
            //     ToolTipML = ENU = '(Ctrl+Right)',
            //                         ESP = '(Ctrl+Derecha)';
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedIsBig = true;
            //     Image = Indent;
            //     PromotedOnly = true;
            //     trigger OnAction()
            //     BEGIN
            //         IF Rec.COUNT() = 0 THEN
            //             EXIT;
            //         Rec.Indentation += 1;
            //         Rec.MODIFY;
            //         CurrPage.UPDATE
            //     END;
            // }
            action("Nuevo Capítulo")
            {

                ShortCutKey = 'Shift+Ctrl+N';
                CaptionML = ENU = 'New Chapter',
                        ESP = 'Nuevo capítulo';
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                Image = NewBranch;
                PromotedOnly = true;
                trigger OnAction()
                VAR
                    JobSetup: Record 315;
                    JobTask: Record "Job Task";
                    JobTaskSub: Record "Job Task";
                    ApplyFilter: Text[100];
                    NewOriginType: Integer;
                    NewOriginCode: Code[20];
                    NewCode: Code[20];
                    NewIndent: Integer;
                    TPP001: label '--- Nuevo ---';
                BEGIN
                    JobSetup.GET;
                    CurrPage.JobTaskLines.Page.GetRecord(JobTaskSub);
                    JobTaskSub.SetRange("Job No.", Rec."No.");
                    IF JobTaskSub.COUNT() = 0 THEN BEGIN
                        NewOriginType := 0;
                        NewOriginCode := Rec."No.";
                        NewCode := '1';

                        NewCode := JobSetup."Prefijo Capítulo" + '.' + PADSTR('', JobSetup."Digitos Capítulo" - STRLEN(NewCode), '0') + NewCode;

                        NewIndent := 0;
                        JobTask.INIT;
                        JobTask.VALIDATE("Job No.", NewOriginCode);
                        JobTask.VALIDATE("Job Task No.", NewCode);
                        JobTask.VALIDATE(Description, TPP001);
                        JobTask.VALIDATE("Tipo Partida", JobTaskSub."Tipo Partida"::Capítulo);
                        JobTask."Job Task Type" := JobTaskSub."Job Task Type"::Total;
                        JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
                        JobTask.INSERT;
                        CurrPage.UPDATE;
                        //Rec.GET(NewOriginCode, NewCode);
                        EXIT;
                    END;
                    if JobTaskSub."Job Task No." = '' THEN
                        Error('Situese en una partida para añadir un capítulo');
                    // Estamos en cap tulo y hay que a adir un cap tulo
                    IF JobTaskSub."Tipo Partida" = JobTaskSub."Tipo Partida"::"Capítulo" THEN BEGIN
                        // Le quitamos un d gito, buscamos el  ltimo e intentamos incrementarlo
                        ApplyFilter := COPYSTR(JobTaskSub."Job Task No.", 1, (STRLEN(JobTaskSub."Job Task No.") - 1)) + '?';
                        JobTask.RESET;
                        JobTask.SETRANGE(JobTask."Job No.", Rec."No.");
                        IF ApplyFilter <> '?' THEN
                            JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
                        JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::Capítulo);
                        IF JobTask.FINDLAST THEN BEGIN
                            NewOriginCode := JobTask."Job No.";
                            NewCode := INCSTR(JobTask."Job Task No.");
                            NewIndent := JobTask.Indentation;
                            JobTask.RESET;
                            IF NOT JobTask.GET(NewOriginCode, NewCode) THEN BEGIN
                                JobTask.INIT;
                                JobTask.VALIDATE("Job No.", NewOriginCode);
                                JobTask.VALIDATE("Job Task No.", NewCode);
                                JobTask.VALIDATE(Description, TPP001);
                                JobTask.VALIDATE("Tipo Partida", JobTaskSub."Tipo Partida"::"Capítulo");
                                JobTask.VALIDATE(Indentation, NewIndent);
                                JobTask."Job Task Type" := JobTaskSub."Job Task Type"::Total;
                                JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
                                // JobTask.VALIDATE(JobTask."Created Date Time", CURRENTDATETIME);
                                // JobTask.VALIDATE(JobTask."Created Date", TODAY);
                                JobTask.INSERT;
                                CurrPage.UPDATE;
                                //Rec.GET(NewOriginCode, NewCode);
                            END;
                        END;
                    END;
                END;
            }
            action("Nuevo Subcapítulo")
            {

                ShortCutKey = 'Shift+Ctrl+H';
                CaptionML = ENU = 'New Sub Chapter',
                            ESP = 'Nuevo subcapÍtulo';
                ApplicationArea = ALL;
                Promoted = true;
                PromotedIsBig = true;
                Image = NewBranch;
                PromotedCategory = New;
                PromotedOnly = true;
                trigger OnAction()
                VAR
                    JobSetup: Record 315;
                    JobTask: Record "Job Task";
                    JobTaskSub: Record "Job Task";
                    ApplyFilter: Text[100];
                    NewOriginType: Integer;
                    NewOriginCode: Code[20];
                    NewCode: Code[20];
                    NewIndent: Integer;
                    TPP001: Label '--- Nuevo ---';
                BEGIN
                    JobSetup.GET;
                    CurrPage.JobTaskLines.Page.GetRecord(JobTaskSub);
                    JobTaskSub.SetRange("Job No.", Rec."No.");
                    IF JobTaskSub.COUNT() = 0 THEN
                        EXIT;
                    if JobTaskSub."Job Task No." = '' THEN
                        Error('Situese en una partida para añadir un capítulo');
                    // Estamos en cap tulo y hay que a adir un cap tulo
                    IF JobTaskSub."Tipo Partida" = JobTaskSub."Tipo Partida"::"Capítulo" THEN BEGIN
                        IF STRLEN(JobTaskSub."Job Task No.") + JobSetup."Digitos Subcapítulo" > 20 THEN
                            ERROR('Ancho para códigos de capítulos excedido');

                        ApplyFilter := JobTaskSub."Job Task No." + '?*';
                        JobTask.RESET;
                        JobTask.SETRANGE(JobTask."Job No.", JobTaskSub."Job No.");
                        IF ApplyFilter <> '?*' THEN
                            JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
                        JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::"Subcapítulo");
                        IF JobTask.FINDLAST THEN BEGIN
                            NewOriginCode := JobTask."Job No.";
                            NewCode := INCSTR(JobTask."Job Task No.");
                            NewIndent := JobTask.Indentation;
                        END
                        ELSE BEGIN
                            NewOriginCode := JobTaskSub."Job No.";
                            NewCode := JobTaskSub."Job Task No." + '.' + PADSTR('', JobSetup."Digitos Capítulo" - STRLEN('0'), '0') + '1';
                            NewIndent := JobTaskSub.Indentation + 1;
                        END;
                        JobTask.RESET;
                        IF NOT JobTask.GET(NewOriginCode, NewCode) THEN BEGIN
                            JobTask.INIT;
                            JobTask.VALIDATE("Job No.", NewOriginCode);
                            JobTask.VALIDATE("Job Task No.", NewCode);
                            JobTask.VALIDATE(Description, TPP001);
                            JobTask.VALIDATE("Tipo Partida", JobTaskSub."Tipo Partida"::"Subcapítulo");
                            JobTask.VALIDATE(Indentation, NewIndent);
                            //JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
                            JobTask.INSERT;
                            CurrPage.UPDATE;

                        END;
                    END;
                END;
            }
            //   { 1000000002;2 ;Action    ;
            //                   Name=NewUnit;
            //                   ShortCutKey=Shift+Ctrl+U;
            //                   CaptionML=[ENU=New Unit;
            //                              ESP=Nueva unidad];
            //                   ApplicationArea=#Jobs;
            //                   Promoted=true;
            //                   PromotedIsBig=true;
            //                   Image=NewItem;
            //                   PromotedOnly=true;
            //                   trigger OnAction() VAR
            //                              JobsSetup@1000000008 : Record 315;
            //                              JobTask : Record "Job Task";
            //                              ApplyFilter : Text[100];
            //                              NewOriginType : Integer;
            //                              NewOriginCode : Code[20];
            //                              NewCode : Code[20];
            //                              NewIndent : Integer;
            //                              TPP001: TextConst 'ENU=--- New ---;ESP=--- Nuevo ---';
            //                            BEGIN

            //                               IF COUNT() = 0 THEN
            //                                EXIT;

            //                               // Estamos en cap tulo y hay que a adir una unidad
            //                               IF "Tipo Partida" = "Tipo Partida"::"Capítulo" THEN
            //                                BEGIN
            //                                  // Le quitamos un d gito, buscamos el  ltimo e intentamos incrementarlo
            //                                  ApplyFilter := Code + '*';
            //                                  JobTask.RESET;
            //                              //    JobTask.SETRANGE(JobTask."Origin Type", "Origin Type");
            //                                  JobTask.SETRANGE(JobTask."Job No.", "Job No.");
            //                                  JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
            //                                  JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::Unit);
            //                                  IF JobTask.FINDLAST THEN
            //                                    BEGIN
            //                              //        NewOriginType := JobTask."Origin Type";
            //                                      NewOriginCode := JobTask."Job No.";
            //                                      NewCode := INCSTR(JobTask."Job Task No.");
            //                                      NewIndent := JobTask.Indentation;
            //                                    END
            //                                  ELSE
            //                                    BEGIN
            //                                      JobsSetup.GET;
            //                                      JobsSetup.TESTFIELD(JobsSetup."Work Unit Code Characters");
            //                              //        NewOriginType := "Origin Type";
            //                                      NewOriginCode := "Job No.";
            //                                      IF JobsSetup."Work Unit Code Characters" = 0 THEN
            //                                        NewCode := PADSTR(Code, 9, '0') + '1'
            //                                      ELSE
            //                                        NewCode := PADSTR(Code, JobsSetup."Work Unit Code Characters"-1, '0') + '1';
            //                                      NewIndent := Indentation+1;
            //                                    END;
            //                                  JobTask.RESET;
            //                                  IF NOT JobTask.GET(NewOriginCode, NewCode) THEN
            //                                    BEGIN
            //                                      JobTask.INIT;
            //                              //        JobTask.VALIDATE("Origin Type", NewOriginType);
            //                                      JobTask.VALIDATE("Job No.", NewOriginCode);
            //                                      JobTask.VALIDATE(Code, NewCode);
            //                                      JobTask.VALIDATE(Description, TPP001);
            //                                      JobTask.VALIDATE("Tipo Partida", "Tipo Partida"::Unit);
            //                                      JobTask.VALIDATE(Indentation, NewIndent);
            //                                      JobTask.VALIDATE(JobTask."Created Date Time", CURRENTDATETIME);
            //                                      JobTask.VALIDATE(JobTask."Created Date", TODAY);
            //                                      JobTask.INSERT;
            //                                      CurrPage.UPDATE;
            //                                      Rec.GET(NewOriginCode, NewCode);
            //                                    END
            //                                  END
            //                                ELSE
            //                                BEGIN
            //                                // Estamos en unidad y hay que a adir una unidad
            //                                // Le quitamos dos d gitos, buscamos el  ltimo e intentamos incrementarlo
            //                                ApplyFilter := COPYSTR(Code, 1, STRLEN(Code)-2) + '*';
            //                                JobTask.RESET;
            //                              //  JobTask.SETRANGE(JobTask."Origin Type", "Origin Type");
            //                                JobTask.SETRANGE(JobTask."Job No.", "Job No.");
            //                                JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
            //                                JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::Unit);
            //                                IF JobTask.FINDLAST THEN
            //                                  BEGIN
            //                              //      NewOriginType := JobTask."Origin Type";
            //                                    NewOriginCode := JobTask."Job No.";
            //                                    NewCode := INCSTR(JobTask."Job Task No.");
            //                                    NewIndent := JobTask.Indentation;
            //                                  END
            //                                  ELSE
            //                                  BEGIN
            //                               //        JobsSetup.GET;
            //                               //        JobsSetup.TESTFIELD(JobsSetup."Work Unit Code Characters");
            //                               //        NewOriginType := "Origin Type";
            //                               //        NewOriginCode := "Origin Code";
            //                               //        NewCode := PADSTR(Code, JobsSetup."Work Unit Code Characters"-1, '0') + '1';
            //                               //        NewIndent := Indentation+1;
            //                                  END;
            //                                JobTask.RESET;
            //                                IF NOT JobTask.GET(NewOriginCode, NewCode) THEN
            //                                  BEGIN
            //                                    JobTask.INIT;
            //                              //      JobTask.VALIDATE("Origin Type", NewOriginType);
            //                                    JobTask.VALIDATE("Job No.", NewOriginCode);
            //                                    JobTask.VALIDATE(Code, NewCode);
            //                                    JobTask.VALIDATE(Description, TPP001);
            //                                    JobTask.VALIDATE("Tipo Partida", "Tipo Partida"::Unit);
            //                                    JobTask.VALIDATE(Indentation, NewIndent);
            //                                    JobTask.VALIDATE(JobTask."Created Date Time", CURRENTDATETIME);
            //                                    JobTask.VALIDATE(JobTask."Created Date", TODAY);
            //                                    JobTask.INSERT;
            //                                    CurrPage.UPDATE;
            //                                    Rec.GET(NewOriginCode, NewCode);
            //                                  END;
            //                               END;

            //                            END;
            //                             }


        }


        addlast(processing)
        {
            action("Asignar Oferta")
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    rec.AddOfertaaProyecto();
                end;
            }
            action("Calcular nueva estimación")
            {
                Image = Calculate;
                ApplicationArea = All;
                Caption = 'Calcular nueva estimación';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Calcula la nueva estimación de costes y horas para la línea de planificación de trabajo seleccionada.';
                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Planning Line";
                    HistJobPlanningLine: Record "Hist. Job Planning Line";
                    Job: Record Job;
                    Ver: Integer;
                    MenEstimacionLbl: Label '¿Se ha generado la nueva estimacion %1, a fecha %2?';
                begin
                    Job.Get(Rec."No.");
                    If Job."Versión Base" = 0 Then Job."Versión Base" := 1;
                    JobPlanningLine.SetRange("Job No.", Rec."No.");
                    HistJobPlanningLine.SetRange("Job No.", Rec."No.");
                    if HistJobPlanningLine.FindLast() then
                        Ver := HistJobPlanningLine."Version No." + 1
                    else
                        Ver := 1;
                    if JobPlanningLine.FindSet() then
                        repeat
                            HistJobPlanningLine.TransferFields(JobPlanningLine);
                            HistJobPlanningLine."Version No." := Ver;
                            HistJobPlanningLine.INSERT;
                        until JobPlanningLine.NEXT = 0;

                    if JobPlanningLine.FindSet() then
                        repeat
                            HistJobPlanningLine.SetRange("Version No.", job."Versión Base");
                            HistJobPlanningLine.SETRANGE("Line No.", JobPlanningLine."Line No.");
                            if Not HistJobPlanningLine.FindFirst() Then begin
                                HistJobPlanningLine.TransferFields(JobPlanningLine);
                                HistJobPlanningLine."Version No." := job."Versión Base";
                                HistJobPlanningLine.INSERT;
                                Message(MenEstimacionLbl, Job."Versión Base", Today());
                            end;
                            // JobPlanningLine."Importe Inicial Venta" := HistJobPlanningLine."Total Price";
                            // JobPlanningLine."Importe Inicial Coste" := HistJobPlanningLine."Total Cost";
                            JobPlanningLine."Importe Inicial Venta" := HistJobPlanningLine."Total Price (LCY)";
                            JobPlanningLine."Importe Inicial Coste" := HistJobPlanningLine."Total Cost (LCY)";
                            JobPlanningLine.Modify();
                        until JobPlanningLine.NEXT = 0;

                end;


            }
            action("Ver Estimaciones")
            {
                Image = History;
                ApplicationArea = All;
                Caption = 'Ver Estimaciones';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Muestra las estimaciones de costes y horas para la línea de planificación de trabajo seleccionada.';
                trigger OnAction()
                var
                    HistJobPlanningLine: Record "Hist. Job Planning Line";
                begin
                    HistJobPlanningLine.SETRANGE("Job No.", Rec."No.");
                    Page.RunModal(0, HistJobPlanningLine);
                end;
            }


            action("Crear Almacen de Proyecto")
            {
                Caption = 'Crear Almacen de Proyecto';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    CodProyecto: Codeunit ProcesosProyectos;
                begin
                    CodProyecto.CreateJobLocation(Rec);
                end;
            }
            action("Movimiento de Almacen de proyecto")
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    // Pag92JobLEntries: Page "Job Ledger Entries";
                    MovProyecto: record "Job Ledger Entry";
                begin
                    MovProyecto.SetRange("Location Code", rec."Cod Almacen de Proyecto");
                    page.RunModal(92, MovProyecto);

                end;
            }

        }
        addlast(History)
        {
            action("Historico Estados")
            {
                ApplicationArea = All;
                Image = Status;
                Caption = 'Historico Estados';

                trigger OnAction()
                var
                    HistorioStatus: Record "Job Status History";
                begin
                    HistorioStatus.SetRange("Job No.", Rec."No.");
                    Page.RunModal(50113, HistorioStatus);

                end;
            }
        }
        addlast("&Job")

        {
            action("Order Job")
            {

                ApplicationArea = all;
                // Caption = 'Purchase  Order';
                Caption = 'Pedido Compra';
                Image = Purchase;
                RunObject = Page "purchase order list";
                RunPageLink = "No. Proyecto" = FIELD("No.");


            }
            action("Quote Job")
            {

                ApplicationArea = all;
                // Caption = 'Purchase  Order';
                Caption = 'Oferta Compra';
                Image = Purchase;
                RunObject = Page "Purchase Quotes";
                RunPageLink = "No. Proyecto" = FIELD("No.");


            }
            action("Return Job")
            {

                ApplicationArea = all;
                //Caption = 'Purchase Return Order';
                Caption = 'Ped. Dev.Compra';
                Image = Purchase;
                RunObject = Page "Purchase Return Order List";
                RunPageLink = "No. Proyecto" = FIELD("No.");
                ToolTip = 'Filter purchase order for jobs';
            }
            action("Comparativa Ofertas")
            {
                ApplicationArea = All;
                Caption = 'Comparativa Ofertas';
                Image = Purchase;
                RunObject = Page "Comparativo Ofertas";
                RunPageLink = "No. Proyecto" = FIELD("No.");
                ToolTip = 'Comparativa de ofertas';

            }
        }
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
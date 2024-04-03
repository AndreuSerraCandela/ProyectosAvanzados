/// <summary>
/// PageExtension JobTaskLinesSubformEX (ID 50101) extends Record Job Task Lines Subform.
/// </summary>
pageextension 50101 "JobTaskLinesSubformEX" extends "Job Task Lines Subform" //1001
{
    layout
    {
        modify("Job Task No.")
        {
            StyleExpr = CodeEmphasize;
        }
        modify(Description)
        {
            StyleExpr = DescriptionEmphasize;
        }
        addafter(Description)
        {

            field(Dependencia; Rec.Dependencia)
            {
                ApplicationArea = all;

            }
            field("Tipo Dependencia fecha"; rec."Tipo Dependencia fecha")
            {
                ApplicationArea = all;

            }
            field(Retardo; rec.Retardo)
            {
                ApplicationArea = all;

            }
            field("Status Task"; Rec."Status Task")
            {
                ApplicationArea = all;
            }
            field("Fecha inicio Tarea"; Rec."Fecha inicio Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Fecha inicio Tarea field.';
            }
            field("Dias Tarea"; Rec."Dias Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Dias Tarea field.';
            }
            field("Fecha fin Tarea"; Rec."Fecha fin Tarea")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Fecha fin Tarea field.';
            }
            field("WIP %"; Rec."WIP %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the WIP % field.';
            }
            field("Venta Inicial"; Rec."Venta Inicial")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Venta Inicial field.';
                Editable = false;
            }
            field("Coste Inicial"; Rec."Coste Inicial")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Coste Inicial field.';
                Editable = false;
            }
            field("Pedidos Pendientes"; PedidosPendientes())
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the WIP Amount field.';
                trigger OnDrillDown()
                var
                    PurchLine: Record "Purchase Line";
                begin
                    PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                    PurchLine.SetRange("Job No.", Rec."Job No.");
                    PurchLine.SetRange("Job Task No.", Rec."Job Task No.");
                    PurchLine.SetFilter("Outstanding Amount", '<>%1', 0);
                    Page.RunModal(0, PurchLine);
                end;
            }

        }

    }

    actions
    {
        addlast("&Job")
        {
            Action("Indentar-")
            {

                ShortCutKey = 'Ctrl+Left';
                ToolTipML = ENU = '(Ctrl+Left)',
                                 ESP = '(Ctrl+Izquierda)';
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                Image = CancelIndent;
                PromotedOnly = true;
                trigger OnAction()
                BEGIN
                    IF Rec.COUNT() = 0 THEN
                        EXIT;
                    IF Rec.Indentation > 0 THEN
                        Rec.Indentation -= 1;
                    Rec.MODIFY;
                    CurrPage.UPDATE
                END;
            }
            action("Indentar+")
            {

                ShortCutKey = 'Ctrl+Right';
                ToolTipML = ENU = '(Ctrl+Right)',
                                    ESP = '(Ctrl+Derecha)';
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                Image = Indent;
                PromotedOnly = true;
                trigger OnAction()
                BEGIN
                    IF Rec.COUNT() = 0 THEN
                        EXIT;
                    Rec.Indentation += 1;
                    Rec.MODIFY;
                    CurrPage.UPDATE
                END;
            }
            // action("Nuevo Capítulo")
            // {

            //     ShortCutKey = 'Shift+Ctrl+N';
            //     CaptionML = ENU = 'New Chapter',
            //             ESP = 'Nuevo capítulo';
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedIsBig = true;
            //     Image = NewBranch;
            //     PromotedOnly = true;
            //     trigger OnAction()
            //     VAR
            //         JobSetup: Record 315;
            //         JobTask: Record "Job Task";
            //         ApplyFilter: Text[100];
            //         NewOriginType: Integer;
            //         NewOriginCode: Code[20];
            //         NewCode: Code[20];
            //         NewIndent: Integer;
            //         TPP001: label '=--- Nuevo ---';
            //     BEGIN
            //         JobSetup.GET;

            //         IF Rec.COUNT() = 0 THEN BEGIN
            //             NewOriginType := 0;
            //             NewOriginCode := Rec.GETFILTER("Job No.");
            //             NewCode := '1';

            //             NewCode := JobSetup."Prefijo Capítulo" + '.' + PADSTR('', StrLen(JobSetup."Prefijo Capítulo" + '.') + JobSetup."Digitos Capítulo" - STRLEN(NewCode), '0') + NewCode;

            //             NewIndent := 0;
            //             JobTask.INIT;
            //             JobTask.VALIDATE("Job No.", NewOriginCode);
            //             JobTask.VALIDATE("Job Task No.", NewCode);
            //             JobTask.VALIDATE(Description, TPP001);
            //             JobTask.VALIDATE("Tipo Partida", rec."Tipo Partida"::Capítulo);
            //             JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
            //             JobTask.INSERT;
            //             CurrPage.UPDATE;
            //             Rec.GET(NewOriginCode, NewCode);
            //             EXIT;
            //         END;

            //         // Estamos en cap tulo y hay que a adir un cap tulo
            //         IF Rec."Tipo Partida" = Rec."Tipo Partida"::"Capítulo" THEN BEGIN
            //             // Le quitamos un d gito, buscamos el  ltimo e intentamos incrementarlo
            //             ApplyFilter := COPYSTR(Rec."Job Task No.", 1, (STRLEN(Rec."Job Task No.") - 1)) + '?';
            //             JobTask.RESET;
            //             JobTask.SETRANGE(JobTask."Job No.", Rec."Job No.");
            //             IF ApplyFilter <> '?' THEN
            //                 JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
            //             JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::Capítulo);
            //             IF JobTask.FINDLAST THEN BEGIN
            //                 NewOriginCode := JobTask."Job No.";
            //                 NewCode := INCSTR(JobTask."Job Task No.");
            //                 NewIndent := JobTask.Indentation;
            //                 JobTask.RESET;
            //                 IF NOT JobTask.GET(NewOriginCode, NewCode) THEN BEGIN
            //                     JobTask.INIT;
            //                     JobTask.VALIDATE("Job No.", NewOriginCode);
            //                     JobTask.VALIDATE("Job Task No.", NewCode);
            //                     JobTask.VALIDATE(Description, TPP001);
            //                     JobTask.VALIDATE("Tipo Partida", Rec."Tipo Partida"::"Capítulo");
            //                     JobTask.VALIDATE(Indentation, NewIndent);
            //                     JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
            //                     // JobTask.VALIDATE(JobTask."Created Date Time", CURRENTDATETIME);
            //                     // JobTask.VALIDATE(JobTask."Created Date", TODAY);
            //                     JobTask.INSERT;
            //                     CurrPage.UPDATE;
            //                     Rec.GET(NewOriginCode, NewCode);
            //                 END;
            //             END;
            //         END;
            //     END;
            // }
            // action("Nuevo Subcapítulo")
            // {

            //     ShortCutKey = 'Shift+Ctrl+H';
            //     CaptionML = ENU = 'New Sub Chapter',
            //                 ESP = 'Nuevo subcapÍtulo';
            //     ApplicationArea = ALL;
            //     Promoted = true;
            //     PromotedIsBig = true;
            //     Image = NewBranch;
            //     PromotedCategory = New;
            //     PromotedOnly = true;
            //     trigger OnAction()
            //     VAR
            //         JobSetup: Record 315;
            //         JobTask: Record "Job Task";
            //         ApplyFilter: Text[100];
            //         NewOriginType: Integer;
            //         NewOriginCode: Code[20];
            //         NewCode: Code[20];
            //         NewIndent: Integer;
            //         TPP001: Label '--- Nuevo ---';
            //     BEGIN
            //         JobSetup.GET;

            //         IF Rec.COUNT() = 0 THEN
            //             EXIT;

            //         // Estamos en cap tulo y hay que a adir un cap tulo
            //         IF Rec."Tipo Partida" = Rec."Tipo Partida"::"Capítulo" THEN BEGIN
            //             IF STRLEN(Rec."Job Task No.") >= JobSetup."Digitos Subcapítulo" - JobSetup."Digitos Capítulo" THEN
            //                 ERROR('Ancho para códigos de capítulos excedido');

            //             ApplyFilter := Rec."Job Task No." + '?*';
            //             JobTask.RESET;
            //             JobTask.SETRANGE(JobTask."Job No.", Rec."Job No.");
            //             IF ApplyFilter <> '?*' THEN
            //                 JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
            //             JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::"Capítulo");
            //             IF JobTask.FINDLAST THEN BEGIN
            //                 NewOriginCode := JobTask."Job No.";
            //                 NewCode := INCSTR(JobTask."Job Task No.");
            //                 NewIndent := JobTask.Indentation;
            //             END
            //             ELSE BEGIN
            //                 NewOriginCode := Rec."Job No.";
            //                 NewCode := Rec."Job Task No." + PADSTR('', JobSetup."Digitos Capítulo" - STRLEN('0'), '0') + '1';
            //                 NewIndent := Rec.Indentation + 1;
            //             END;
            //             JobTask.RESET;
            //             IF NOT JobTask.GET(NewOriginCode, NewCode) THEN BEGIN
            //                 JobTask.INIT;
            //                 JobTask.VALIDATE("Job No.", NewOriginCode);
            //                 JobTask.VALIDATE("Job Task No.", NewCode);
            //                 JobTask.VALIDATE(Description, TPP001);
            //                 JobTask.VALIDATE("Tipo Partida", Rec."Tipo Partida"::"Capítulo");
            //                 JobTask.VALIDATE(Indentation, NewIndent);
            //                 JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
            //                 JobTask.INSERT;
            //                 CurrPage.UPDATE;
            //                 Rec.GET(NewOriginCode, NewCode);
            //             END;
            //         END;
            //     END;
            // }
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

    }
    trigger OnAfterGetRecord()
    begin
        CodeEmphasize := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;
        DescriptionEmphasize := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;
        DescriptionIndent := Rec.Indentation;
    end;

    local procedure PedidosPendientes(): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Job No.", Rec."Job No.");
        PurchLine.SetRange("Job Task No.", Rec."Job Task No.");
        PurchLine.CalcSums("Outstanding Amount");
        If PurchLine.FindFirst() then exit(PurchLine."Outstanding Amount");


    end;

    var
        CodeEmphasize: Boolean;
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;
}
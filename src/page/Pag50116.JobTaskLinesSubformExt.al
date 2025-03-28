// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

page 50116 "Job Task Lines Subform Ext"
{
    Caption = 'Job Task Lines Subform';
    DataCaptionFields = "Job No.";
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Job Task";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                ShowAsTree = true;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    //StyleExpr = StyleIsStrong;
                    StyleExpr = CodeEmphasize;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related job task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    //StyleExpr = StyleIsStrong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies a description of the job task. You can enter anything that is meaningful in describing the task. The description is copied and used in descriptions on the job planning line.';
                }
                field(Dependencia; Rec.Dependencia)
                {
                    ApplicationArea = all;
                    Visible = not (Multi);

                }
                field(Dependencia2; Rec.Dependencia2)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dependencia2 field.', Comment = '%';
                    Visible = Multi;
                }

                field("Tipo Dependencia fecha"; rec."Tipo Dependencia fecha")
                {
                    ApplicationArea = all;

                }
                field(Retardo; rec.Retardo)
                {
                    ApplicationArea = all;
                    // Visible = not (Multi);

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

                    trigger OnValidate()
                    begin
                        if ConfProyecto.ProyectoMultiple() then begin
                            rec.RecalcularTarea();
                            CurrPage.Update(true);
                        end;

                    end;
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
                field("Job Task Type"; Rec."Job Task Type")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the purpose of the account. Newly created accounts are automatically assigned the Posting account type, but you can change this. Choose the field to select one of the following five options:';

                    trigger OnValidate()
                    begin
                        StyleIsStrong := Rec."Job Task Type" <> Rec."Job Task Type"::Posting;
                        CurrPage.Update();
                    end;
                }
                field(Totaling; Rec.Totaling)
                {

                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an interval or a list of job task numbers.';
                    Visible = false;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the job posting group of the task.';
                    Visible = false;
                }
                field("WIP-Total"; Rec."WIP-Total")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the job tasks you want to group together when calculating Work In Process (WIP) and Recognition.';
                    Visible = false;
                }
                field("WIP Method"; Rec."WIP Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the Work in Process calculation method that is associated with a job. The value in this field comes from the WIP method specified on the job card.';
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the start date for the job task. The date is based on the date on the related job planning line.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the end date for the job task. The date is based on the date on the related job planning line.';
                }
                field("Schedule (Total Cost)"; Rec."Schedule (Total Cost)")
                {

                    ApplicationArea = Basic, Suite, Jobs;
                    Caption = 'Presupuesto (Coste Total)';
                    ToolTip = 'Specifies, in the local currency, the total budgeted cost for the job task during the time period in the Planning Date Filter field.';
                }
                field("Schedule (Total Price)"; Rec."Schedule (Total Price)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Presupuesto (Precio Total)';
                    ToolTip = 'Specifies, in local currency, the total budgeted price for the job task during the time period in the Planning Date Filter field.';
                    Visible = false;
                }
                field("Usage (Total Cost)"; Rec."Usage (Total Cost)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies, in local currency, the total cost of the usage of items, resources and general ledger expenses posted on the job task during the time period in the Posting Date Filter field.';
                }
                field("Usage (Total Price)"; Rec."Usage (Total Price)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, in the local currency, the total price of the usage of items, resources and general ledger expenses posted on the job task during the time period in the Posting Date Filter field.';
                    Visible = false;
                }
                field("Contract (Total Cost)"; Rec."Contract (Total Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, in local currency, the total billable cost for the job task during the time period in the Planning Date Filter field.';
                    Visible = false;
                }
                field("Contract (Total Price)"; Rec."Contract (Total Price)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable price for the job task during the time period in the Planning Date Filter field.';
                }
                field("Contract (Invoiced Cost)"; Rec."Contract (Invoiced Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, in the local currency, the total billable cost for the job task that has been invoiced during the time period in the Posting Date Filter field.';
                    Visible = false;
                }
                field("Contract (Invoiced Price)"; Rec."Contract (Invoiced Price)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable price for the job task that has been invoiced during the time period in the Posting Date Filter field.';
                }
                field("Remaining (Total Cost)"; Rec."Remaining (Total Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the remaining total cost (LCY) as the sum of costs from job planning lines associated with the job task. The calculation occurs when you have specified that there is a usage link between the job ledger and the job planning lines.';
                    Visible = false;
                }
                field("Remaining (Total Price)"; Rec."Remaining (Total Price)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the remaining total price (LCY) as the sum of prices from job planning lines associated with the job task. The calculation occurs when you have specified that there is a usage link between the job ledger and the job planning lines.';
                    Visible = false;
                }
                field("EAC (Total Cost)"; Rec.CalcEACTotalCost())
                {
                    ApplicationArea = Suite;
                    Caption = 'EAC (Total Cost)';
                    ToolTip = 'Specifies the estimate at completion (EAC) total cost for a job task line. If the Apply Usage Link check box on the job is selected, then the EAC (Total Cost) field is calculated as follows: Usage (Total Cost) + Remaining (Total Cost).';
                    Visible = false;
                }
                field("EAC (Total Price)"; Rec.CalcEACTotalPrice())
                {
                    ApplicationArea = Suite;
                    Caption = 'EAC (Total Price)';
                    ToolTip = 'Specifies the estimate at completion (EAC) total price for a job task line. If the Apply Usage Link check box on the job is selected, then the EAC (Total Price) field is calculated as follows: Usage (Total Price) + Remaining (Total Price).';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Outstanding Orders"; Rec."Outstanding Orders")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the sum of outstanding orders, in local currency, for this job task. The value of the Outstanding Amount (LCY) field is used for entries in the Purchase Line table of document type Order to calculate and update the contents of this field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        PurchLine: Record "Purchase Line";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownOutstandingOrders(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        Rec.ApplyPurchaseLineFilters(PurchLine, Rec."Job No.", Rec."Job Task No.");
                        PurchLine.SetFilter("Outstanding Amount (LCY)", '<> 0');
                        PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                    end;
                }
                field("Amt. Rcd. Not Invoiced"; Rec."Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the sum for items that have been received but have not yet been invoiced. The value in the Amt. Rcd. Not Invoiced (LCY) field is used for entries in the Purchase Line table of document type Order to calculate and update the contents of this field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        PurchLine: Record "Purchase Line";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownAmtRcdNotInvoiced(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        Rec.ApplyPurchaseLineFilters(PurchLine, Rec."Job No.", Rec."Job Task No.");
                        PurchLine.SetFilter("Amt. Rcd. Not Invoiced (LCY)", '<> 0');
                        PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Linea';
                group("&Job")
                {

                    Caption = '&Proyecto';
                    Image = Job;
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
                            If Rec."Job No." = '' THEN
                                if Proyecto = '' THEN
                                    Error('No se ha seleccionado un proyecto, intente crear el capítulo, desde la cabecera');
                            If Rec."Job No." = '' THEN
                                Rec."Job No." := Proyecto;
                            If Proyecto = '' THEN
                                Proyecto := Rec."Job No.";
                            JobTaskSub.SetRange("Job No.", Proyecto);
                            IF JobTaskSub.COUNT() = 0 THEN BEGIN
                                NewOriginType := 0;
                                NewOriginCode := Rec."Job No.";
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
                            if Rec."Job Task No." = '' THEN
                                Error('Situese en una partida para añadir un capítulo');
                            // Estamos en cap tulo y hay que a adir un cap tulo
                            IF Rec."Tipo Partida" = Rec."Tipo Partida"::"Capítulo" THEN BEGIN
                                // Le quitamos un d gito, buscamos el  ltimo e intentamos incrementarlo
                                ApplyFilter := COPYSTR(Rec."Job Task No.", 1, (STRLEN(Rec."Job Task No.") - 1)) + '?';
                                JobTask.RESET;
                                JobTask.SETRANGE(JobTask."Job No.", Rec."Job No.");
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
                                        JobTask.VALIDATE("Tipo Partida", Rec."Tipo Partida"::"Capítulo");
                                        JobTask.VALIDATE(Indentation, NewIndent);
                                        JobTask."Job Task Type" := Rec."Job Task Type"::Total;
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
                            if not JobTaskSub.Get(Rec."Job No.", Rec."Job Task No.")
                             then
                                Error('No se ha encontrado la partida');
                            If Rec."Job No." = '' THEN
                                if Proyecto = '' THEN
                                    Error('No se ha seleccionado un proyecto, intente crear el capítulo, desde la cabecera');
                            If Rec."Job No." = '' THEN
                                Rec."Job No." := Proyecto;
                            If Proyecto = '' THEN
                                Proyecto := Rec."Job No.";

                            if JobTaskSub."Job Task No." = '' THEN
                                Error('Situese en una partida para añadir un sub-capítulo');
                            // Estamos en cap tulo y hay que a adir un cap tulo
                            //   IF JobTaskSub."Tipo Partida" = JobTaskSub."Tipo Partida"::"Capítulo" THEN BEGIN
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
                                NewCode := JobTaskSub."Job Task No." + '.' + PADSTR('', JobSetup."Digitos Subcapítulo" - STRLEN('0'), '0') + '1';
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
                        // END;
                    }

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



                    action(JobPlanningLines)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Líneas &Plannificación';
                        Image = JobLines;
                        Scope = Repeater;
                        ToolTip = 'View all planning lines for the job. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a job (budget) or you can specify what you actually agreed with your customer that he should pay for the job (billable).';

                        trigger OnAction()
                        var
                            JobPlanningLine: Record "Job Planning Line";
                            JobPlanningLines: Page "Job Planning Lines";
                            IsHandled: Boolean;
                        begin
                            IsHandled := false;
                            OnBeforeOnActionJobPlanningLines(Rec, IsHandled);
                            if IsHandled then
                                exit;
                            Rec.TestField("Job No.");
                            JobPlanningLine.FilterGroup(2);
                            JobPlanningLine.SetRange("Job No.", Rec."Job No.");
                            JobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
                            JobPlanningLine.FilterGroup(0);
                            JobPlanningLines.SetTableView(JobPlanningLine);
                            JobPlanningLines.Editable := true;
                            JobPlanningLines.Run();
                        end;
                    }
                }
                group("&Dimensions")
                {
                    Caption = '&Dimensiones';
                    Image = Dimensions;
                    ShowAs = SplitButton;

                    action("Dimensions-&Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensiones-&Individual';
                        Image = Dimensions;
                        RunObject = Page "Job Task Dimensions";
                        RunPageLink = "Job No." = field("Job No."),
                                      "Job Task No." = field("Job Task No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensionws-&Multiples';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            JobTask: Record "Job Task";
                            JobTaskDimensionsMultiple: Page "Job Task Dimensions Multiple";
                        begin
                            CurrPage.SetSelectionFilter(JobTask);
                            JobTaskDimensionsMultiple.SetMultiJobTask(JobTask);
                            JobTaskDimensionsMultiple.RunModal();
                        end;
                    }
                }
                group(Documents)
                {
                    Caption = 'Documentos';
                    Image = Invoice;
                    action("Create &Sales Invoice")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Crear &Factura de Venta';
                        Ellipsis = true;
                        Image = JobSalesInvoice;
                        ToolTip = 'Use a batch job to help you create sales invoices for the involved job tasks.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                            JobTask: Record "Job Task";
                        begin
                            Rec.TestField("Job No.");
                            Job.Get(Rec."Job No.");
                            if Job.Blocked = Job.Blocked::All then
                                Job.TestBlocked();

                            JobTask.SetRange("Job No.", Job."No.");
                            if Rec."Job Task No." <> '' then
                                JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                            REPORT.RunModal(REPORT::"Job Create Sales Invoice", true, false, JobTask);
                        end;
                    }
                    action(SalesInvoicesCreditMemos)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Facturas de &Venta y Abonos';
                        Image = GetSourceDoc;
                        Promoted = true;
                        PromotedCategory = Process;
                        ToolTip = 'View sales invoices or sales credit memos that are related to the selected job task.';

                        trigger OnAction()
                        var
                            JobInvoices: Page "Job Invoices";
                        begin
                            JobInvoices.SetPrJobTask(Rec);
                            JobInvoices.RunModal();
                        end;
                    }
                }
                group(History)
                {
                    Caption = 'Históricos';
                    Image = History;
                    action("Job Ledger E&ntries")
                    {
                        ApplicationArea = Jobs;
                        Caption = '&Movimientos de Proyecto';
                        Image = JobLedger;
                        RunObject = Page "Job Ledger Entries";
                        RunPageLink = "Job No." = field("Job No."),
                                      "Job Task No." = field("Job Task No.");
                        RunPageView = sorting("Job No.", "Job Task No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the job ledger entries.';
                    }
                }
                group("F&unctions")
                {
                    Caption = 'F&unciones';
                    Image = "Action";
                    action("Split &Planning Lines")
                    {
                        ApplicationArea = Jobs;
                        Caption = '&Dividir Líneas de Planificación';
                        Ellipsis = true;
                        Image = Splitlines;
                        Promoted = true;
                        PromotedCategory = Process;
                        ToolTip = 'Split planning lines of type Budget and Billable into two separate planning lines: Budget and Billable.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                            JobTask: Record "Job Task";
                        begin
                            Rec.TestField("Job No.");
                            Job.Get(Rec."Job No.");
                            if Job.Blocked = Job.Blocked::All then
                                Job.TestBlocked();

                            Rec.TestField("Job Task No.");
                            JobTask.SetRange("Job No.", Job."No.");
                            JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                            REPORT.RunModal(REPORT::"Job Split Planning Line", true, false, JobTask);
                        end;
                    }
                    action("Change &Dates")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Cambiar &Fechas';
                        Ellipsis = true;
                        Image = ChangeDate;
                        ToolTip = 'Use a batch job to help you move planning lines on a job from one date interval to another.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                            JobTask: Record "Job Task";
                        begin
                            Rec.TestField("Job No.");
                            Job.Get(Rec."Job No.");
                            if Job.Blocked = Job.Blocked::All then
                                Job.TestBlocked();

                            JobTask.SetRange("Job No.", Job."No.");
                            if Rec."Job Task No." <> '' then
                                JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                            REPORT.RunModal(REPORT::"Change Job Dates", true, false, JobTask);
                        end;
                    }
                    action("<Action7>")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'I&ndentar Tareas';
                        Image = Indent;
                        RunObject = Codeunit "Job Task-Indent";
                        ToolTip = 'Move the selected lines in one position to show that the tasks are subcategories of other tasks. Job tasks that are totaled are the ones that lie between one pair of corresponding Begin-Total and End-Total job tasks.';
                    }
                    group("&Copy")
                    {
                        Caption = '&Copiar';
                        Image = Copy;
                        action("Copy Job Planning Lines &from...")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Copy Job Planning Lines &from...';
                            Ellipsis = true;
                            Image = CopyToTask;
                            Promoted = true;
                            PromotedCategory = Process;
                            ToolTip = 'Use a batch job to help you copy planning lines from one job task to another. You can copy from a job task within the job you are working with or from a job task linked to a different job.';

                            trigger OnAction()
                            var
                                CopyJobPlanningLines: Page "Copy Job Planning Lines";
                            begin
                                Rec.TestField("Job Task Type", Rec."Job Task Type"::Posting);
                                CopyJobPlanningLines.SetToJobTask(Rec);
                                CopyJobPlanningLines.RunModal();
                            end;
                        }
                        action("Copy Job Planning Lines &to...")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Copiar lineas de planificación &a...';
                            Ellipsis = true;
                            Image = CopyFromTask;
                            Promoted = true;
                            PromotedCategory = Process;
                            ToolTip = 'Use a batch job to help you copy planning lines from one job task to another. You can copy from a job task within the job you are working with or from a job task linked to a different job.';

                            trigger OnAction()
                            var
                                CopyJobPlanningLines: Page "Copy Job Planning Lines";
                            begin
                                Rec.TestField("Job Task Type", "Job Task Type"::Posting);
                                CopyJobPlanningLines.SetFromJobTask(Rec);
                                CopyJobPlanningLines.RunModal();
                            end;
                        }
                    }
                    group("<Action13>")
                    {
                        Caption = 'W&IP';
                        Image = WIP;
                        action("<Action48>")
                        {
                            ApplicationArea = Jobs;
                            Caption = '&Calcular WIP';
                            Ellipsis = true;
                            Image = CalculateWIP;
                            ToolTip = 'Run the Job Calculate WIP batch job.';

                            trigger OnAction()
                            var
                                Job: Record Job;
                            begin
                                Rec.TestField("Job No.");
                                Job.Get(Rec."Job No.");
                                Job.SetRange("No.", Job."No.");
                                REPORT.RunModal(REPORT::"Job Calculate WIP", true, false, Job);
                            end;
                        }
                        action("<Action49>")
                        {
                            ApplicationArea = Jobs;
                            Caption = '&Registrar WIP en contabilidad';
                            Ellipsis = true;
                            Image = PostOrder;
                            ShortCutKey = 'F9';
                            ToolTip = 'Run the Job Post WIP to G/L batch job.';

                            trigger OnAction()
                            var
                                Job: Record Job;
                            begin
                                Rec.TestField("Job No.");
                                Job.Get(Rec."Job No.");
                                Job.SetRange("No.", Job."No.");
                                REPORT.RunModal(REPORT::"Job Post WIP to G/L", true, false, Job);
                            end;
                        }
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Multi := ConfProyecto.ProyectoMultiple();
    end;

    trigger OnAfterGetRecord()
    begin
        // DescriptionIndent := Rec.Indentation;
        // StyleIsStrong := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo; //Rec."Job Task Type" <> "Job Task Type"::Posting;
        // CodeEmphasize := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;
        // DescriptionEmphasize := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;
        // DescriptionIndent := Rec.Indentation;



    end;

    // trigger OnModifyRecord(): Boolean
    // begin
    //     if rec."Dias Tarea" <> xRec."Dias Tarea" then
    //         CurrPage.Update();
    // end;


    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.ClearTempDim();
        StyleIsStrong := Rec."Tipo Partida" = Rec."Tipo Partida"::Capítulo;// Rec."Job Task Type" <> "Job Task Type"::Posting;
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
        Proyecto: Code[20];
        StyleIsStrong: Boolean;
        ConfProyecto: Record "Jobs Setup";
        Multi: Boolean;



    procedure cargaProyecto(pProyecto: Code[20])
    begin
        Proyecto := pProyecto;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnActionJobPlanningLines(var JobTask: Record "Job Task"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownOutstandingOrders(var JobTask: Record "Job Task"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownAmtRcdNotInvoiced(var JobTask: Record "Job Task"; var IsHandled: Boolean);
    begin
    end;
}

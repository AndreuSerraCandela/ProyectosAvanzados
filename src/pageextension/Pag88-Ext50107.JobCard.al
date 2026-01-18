pageextension 50307 "JobCard" extends "Job Card" //88
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
                // Visible = false;
            }
            field("Cod Almacen de Proyecto"; Rec."Cod Almacen de Proyecto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Nomenglatura Proyecto almacen field.';
                Editable = false;
                DrillDown = true;
            }
            field("Cód. Presupuesto"; Rec."Cód. Presupuesto")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Cód. Presupuesto field.';
                Editable = true;
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
        modify(JobTaskLines)
        {
            Visible = TareasEstandard;
            Caption = 'Tareas Estándar';
        }
        addafter("JobTaskLines")
        {
            part(JobTaskLines2; "Job Task Lines Subform ext")
            {
                ApplicationArea = Jobs;
                Caption = 'Arbol Tareas';
                SubPageLink = "Job No." = field("No.");
                SubPageView = sorting("Job Task No.")
                              order(Ascending);
                UpdatePropagation = Both;
                Visible = not TareasEstandard;
                Editable = JobTaskLinesEditable2;
                Enabled = JobTaskLinesEditable2;
            }

        }
        addafter("Attached Documents List")
        {
            part(PagosAsociados; "Pagos Asociados Factbox")
            {
                ApplicationArea = Jobs;
                Caption = 'Pagos Asociados';
                SubPageLink = "Job No." = field("No.");
            }
        }
    }

    actions
    {

        addlast("&Job")
        {
            // action("Nuevo Capítulo")
            // {

            //     ShortCutKey = 'Shift+Ctrl+N';
            //     CaptionML = ENU = 'New Chapter',
            //             ESP = 'Nuevo capítulo';
            //     ApplicationArea = All;
            //     Promoted = true;
            //     PromotedCategory = Category10;
            //     PromotedIsBig = true;
            //     Image = NewBranch;
            //     PromotedOnly = true;
            //     trigger OnAction()
            //     VAR
            //         JobSetup: Record 315;
            //         JobTask: Record "Job Task";
            //         JobTaskSub: Record "Job Task";
            //         ApplyFilter: Text[100];
            //         NewOriginType: Integer;
            //         NewOriginCode: Code[20];
            //         NewCode: Code[20];
            //         NewIndent: Integer;
            //         TPP001: label '--- Nuevo ---';
            //     BEGIN
            //         JobSetup.GET;
            //         CurrPage.JobTaskLines2.Page.GetRecord(JobTaskSub);
            //         JobTaskSub.SetRange("Job No.", Rec."No.");
            //         IF JobTaskSub.COUNT() = 0 THEN BEGIN
            //             NewOriginType := 0;
            //             NewOriginCode := Rec."No.";
            //             NewCode := '1';

            //             NewCode := JobSetup."Prefijo Capítulo" + '.' + PADSTR('', JobSetup."Digitos Capítulo" - STRLEN(NewCode), '0') + NewCode;

            //             NewIndent := 0;
            //             JobTask.INIT;
            //             JobTask.VALIDATE("Job No.", NewOriginCode);
            //             JobTask.VALIDATE("Job Task No.", NewCode);
            //             JobTask.VALIDATE(Description, TPP001);
            //             JobTask.VALIDATE("Tipo Partida", JobTaskSub."Tipo Partida"::Capítulo);
            //             JobTask."Job Task Type" := JobTaskSub."Job Task Type"::Total;
            //             JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
            //             JobTask.INSERT;
            //             CurrPage.UPDATE;
            //             //Rec.GET(NewOriginCode, NewCode);
            //             EXIT;
            //         END;
            //         if JobTaskSub."Job Task No." = '' THEN
            //             Error('Situese en una partida para añadir un capítulo');
            //         // Estamos en cap tulo y hay que a adir un cap tulo
            //         IF JobTaskSub."Tipo Partida" = JobTaskSub."Tipo Partida"::"Capítulo" THEN BEGIN
            //             // Le quitamos un d gito, buscamos el  ltimo e intentamos incrementarlo
            //             ApplyFilter := COPYSTR(JobTaskSub."Job Task No.", 1, (STRLEN(JobTaskSub."Job Task No.") - 1)) + '?';
            //             JobTask.RESET;
            //             JobTask.SETRANGE(JobTask."Job No.", Rec."No.");
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
            //                     JobTask.VALIDATE("Tipo Partida", JobTaskSub."Tipo Partida"::"Capítulo");
            //                     JobTask.VALIDATE(Indentation, NewIndent);
            //                     JobTask."Job Task Type" := JobTaskSub."Job Task Type"::Total;
            //                     JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
            //                     // JobTask.VALIDATE(JobTask."Created Date Time", CURRENTDATETIME);
            //                     // JobTask.VALIDATE(JobTask."Created Date", TODAY);
            //                     JobTask.INSERT;
            //                     CurrPage.UPDATE;
            //                     //Rec.GET(NewOriginCode, NewCode);
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
            //     PromotedCategory = Category10;
            //     PromotedOnly = true;
            //     trigger OnAction()
            //     VAR
            //         JobSetup: Record 315;
            //         JobTask: Record "Job Task";
            //         JobTaskSub: Record "Job Task";
            //         ApplyFilter: Text[100];
            //         NewOriginType: Integer;
            //         NewOriginCode: Code[20];
            //         NewCode: Code[20];
            //         NewIndent: Integer;
            //         TPP001: Label '--- Nuevo ---';
            //     BEGIN
            //         JobSetup.GET;
            //         CurrPage.JobTaskLines2.Page.GetRecord(JobTaskSub);
            //         JobTaskSub.SetRange("Job No.", Rec."No.");
            //         IF JobTaskSub.COUNT() = 0 THEN
            //             EXIT;
            //         if JobTaskSub."Job Task No." = '' THEN
            //             Error('Situese en una partida para añadir un capítulo');
            //         // Estamos en cap tulo y hay que a adir un cap tulo
            //         IF JobTaskSub."Tipo Partida" = JobTaskSub."Tipo Partida"::"Capítulo" THEN BEGIN
            //             IF STRLEN(JobTaskSub."Job Task No.") + JobSetup."Digitos Subcapítulo" > 20 THEN
            //                 ERROR('Ancho para códigos de capítulos excedido');

            //             ApplyFilter := JobTaskSub."Job Task No." + '?*';
            //             JobTask.RESET;
            //             JobTask.SETRANGE(JobTask."Job No.", JobTaskSub."Job No.");
            //             IF ApplyFilter <> '?*' THEN
            //                 JobTask.SETFILTER(JobTask."Job Task No.", '%1', ApplyFilter);
            //             JobTask.SETRANGE(JobTask."Tipo Partida", JobTask."Tipo Partida"::"Subcapítulo");
            //             IF JobTask.FINDLAST THEN BEGIN
            //                 NewOriginCode := JobTask."Job No.";
            //                 NewCode := INCSTR(JobTask."Job Task No.");
            //                 NewIndent := JobTask.Indentation;
            //             END
            //             ELSE BEGIN
            //                 NewOriginCode := JobTaskSub."Job No.";
            //                 NewCode := JobTaskSub."Job Task No." + '.' + PADSTR('', JobSetup."Digitos Capítulo" - STRLEN('0'), '0') + '1';
            //                 NewIndent := JobTaskSub.Indentation + 1;
            //             END;
            //             JobTask.RESET;
            //             IF NOT JobTask.GET(NewOriginCode, NewCode) THEN BEGIN
            //                 JobTask.INIT;
            //                 JobTask.VALIDATE("Job No.", NewOriginCode);
            //                 JobTask.VALIDATE("Job Task No.", NewCode);
            //                 JobTask.VALIDATE(Description, TPP001);
            //                 JobTask.VALIDATE("Tipo Partida", JobTaskSub."Tipo Partida"::"Subcapítulo");
            //                 JobTask.VALIDATE(Indentation, NewIndent);
            //                 //JobTask.VALIDATE(Totaling, NewCode + '..' + PADSTR(NewCode, 20 - (STRLEN(NewCode) + 2), '9'));
            //                 JobTask.INSERT;
            //                 CurrPage.UPDATE;

            //             END;
            //         END;
            //     END;
            // }
            action("Tareas estándar")
            {
                ShortCutKey = 'Shift+Ctrl+T';
                CaptionML = ENU = 'Standard Tasks',
                            ESP = 'Tareas estándar';
                ApplicationArea = All;
                // Promoted = true;
                // PromotedCategory = New;
                // PromotedIsBig = true;
                Image = Task;
                // PromotedOnly = true;
                trigger OnAction()
                begin
                    TareasEstandard := not TareasEstandard;
                    CurrPage.JobTaskLines2.Page.cargaProyecto(Rec."No.");
                end;
            }
            action("Crear Presupuesto")
            {
                ApplicationArea = All;
                Caption = 'Crear Presupuesto';
                Image = LedgerBudget;
                trigger OnAction()
                var
                    CodProyecto: Codeunit ProcesosProyectos;
                begin
                    CodProyecto.CrearPresupuesto(Rec);
                end;
            }
            action("Importar desde Excel")
            {
                ApplicationArea = All;
                Caption = 'Importar Tareas desde Excel';
                ToolTip = 'Importa tareas de proyecto desde un archivo Excel';
                Image = ImportExcel;

                trigger OnAction()
                var
                    CodProyecto: Codeunit ProcesosProyectos;
                begin
                    ImportarLineasDesdeExcel();
                    Commit();
                    CodProyecto.ActualizarArbolTareas(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
            action("Importar Movimientos desde Excel")
            {
                ApplicationArea = All;
                Caption = 'Importar Movimientos desde Excel';
                ToolTip = 'Importa movimientos de proyecto (Job Ledger Entries) desde un archivo Excel';
                Image = ImportExcel;

                trigger OnAction()
                var
                    CodProyecto: Codeunit ProcesosProyectos;
                begin
                    CodProyecto.ImportarJobLedgerEntriesDesdeExcel(Rec."No.");
                    Commit();
                    CurrPage.Update(false);
                end;
            }
            action("Pagos Vinculados")
            {
                ApplicationArea = All;
                Caption = 'Pagos Vinculados al Proyecto';
                ToolTip = 'Muestra el estado de los pagos de documentos de compra vinculados a este proyecto';
                Image = Payment;

                trigger OnAction()
                var
                    PagosProyecto: Page "Pagos Proyecto";
                begin
                    PagosProyecto.SetJobFilter(Rec."No.");
                    PagosProyecto.RunModal();
                end;
            }

        }

        addlast(Promoted)
        {
            group(Task)
            {
                Image = Task;
                Caption = 'Tareas';
                actionref(Tareas_ref; "Tareas estándar") { }

            }
            group(Job)
            {
                Image = Job;
                Caption = 'Proyecto';
                actionref(crearalmacen_ref; "Crear Almacen de Proyecto") { }
                actionref(VerEstimaciones; "Ver Estimaciones") { }
                actionref(CrearNuevaEstimacion; "Calcular nueva estimación") { }
                actionref(ImportarDesdeExcel; "Importar desde Excel") { }
                actionref(ImportarMovimientosDesdeExcel; "Importar Movimientos desde Excel") { }
            }

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
                ToolTip = 'Calcula la nueva estimación de costes y horas para la línea de planificación de trabajo seleccionada.';
                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Planning Line";
                    HistJobPlanningLine: Record "Hist. Job Planning Line";
                    Job: Record Job;
                    Ver: Integer;
                    MenEstimacionLbl: Label '¿Se ha generado la nueva estimacion %1, a fecha %2?';
                    CodEstimacion: Code[20];
                    Dialogo: Page DialogoEstimacion;
                    page1007: Page 1007;
                begin
                    if Dialogo.RunModal() = Action::OK then begin
                        //  if Confirm('Desea rellenar el codigo de estimacion %1', false, CodEstimacion) then;
                        CodEstimacion := Dialogo.GetValueCode();
                    end;


                    //Message('Rellene el codigo estimacion %1', CodEstimacion);

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
                            HistJobPlanningLine."Cód.Estimacion" := CodEstimacion;
                            HistJobPlanningLine."Version No." := Ver;
                            HistJobPlanningLine."Version Date" := Today();
                            HistJobPlanningLine.INSERT;
                        until JobPlanningLine.NEXT = 0;

                    if JobPlanningLine.FindSet() then
                        repeat
                            HistJobPlanningLine.SetRange("Version No.", job."Versión Base");
                            HistJobPlanningLine.SETRANGE("Line No.", JobPlanningLine."Line No.");
                            if Not HistJobPlanningLine.FindFirst() Then begin
                                HistJobPlanningLine.TransferFields(JobPlanningLine);
                                HistJobPlanningLine."Version No." := job."Versión Base";
                                HistJobPlanningLine."Cód.Estimacion" := CodEstimacion;
                                HistJobPlanningLine."Version Date" := Today();
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
                // Promoted = true;
                // PromotedCategory = Process;
                // PromotedIsBig = true;

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
    trigger OnAfterGetRecord()
    begin
        JobTaskLinesEditable2 := Rec.CalcJobTaskLinesEditable();
        CurrPage.JobTaskLines2.Page.cargaProyecto(Rec."No.");
        CurrPage.PagosAsociados.Page.SetJobFilter(Rec."No.");
    end;

    trigger OnOpenPage()
    begin
        TareasEstandard := false;

    end;

    var
        TareasEstandard: Boolean;
        myInt: Integer;
        JobTaskLinesEditable2: Boolean;

    local procedure ImportarLineasDesdeExcel()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        JobTask: Record "Job Task";
        InStream: InStream;
        FileName: Text;
        RowNo: Integer;
        CodigoLinea: Text[20];
        Descripcion: Text[100];
        Tipo: Text[20];
        NoCuenta: Code[20];
        DescripcionCuenta: Text[100];
        LargoCodigo: Integer;
        Cantidad: Decimal;
        Cost: Decimal;
        Venta: Decimal;
        TipoLinea: Text[20];
        EsSumatorio: Boolean;
        ImportedTasks: Integer;
        ParentTaskNo: Code[20];
        SheetName: Text;
        DimMgt: Codeunit DimensionManagement;
        JobTaskDim: Record "Job Task Dimension";
        DefaultDim: Record "Default Dimension";
        JobTaskPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        LineNo: Integer;
        CodProyecto: Codeunit ProcesosProyectos;
        JobsSetup: Record "Jobs Setup";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        rInf: Record "Company Information";
        CtaCta: Text[30];
        GenNegPostingGrup: Record "Gen. Business Posting Group";
        GenPostingSetup: Record "General Posting Setup";
    begin
        rInf.Get();
        rInf.TestField("Cta Contable Estructura");

        JobsSetup.Get();
        // Verificar que el proyecto esté abierto
        if Rec.Status <> Rec.Status::Open then begin
            Message('El proyecto debe estar en estado Abierto para importar tareas.');
            exit;
        end;

        // Limpiar buffer temporal
        TempExcelBuffer.DeleteAll();

        // Cargar datos del Excel
        if UploadIntoStream('Seleccionar archivo Excel', '', 'Archivos Excel (*.xlsx)|*.xlsx|Todos los archivos (*.*)|*.*', FileName, InStream) then begin
            SheetName := TempExcelBuffer.SelectSheetsNameStream(InStream);
            TempExcelBuffer.OpenBookStream(InStream, SheetName);
            TempExcelBuffer.ReadSheet();
        end else
            exit;
        JobTaskDim.SetRange("Job No.", Rec."No.");
        JobTaskDim.DeleteAll();
        commit();
        ImportedTasks := 0;
        ParentTaskNo := ''; // Para agrupar sumatorios

        // Procesar cada fila del Excel
        if TempExcelBuffer.FindSet() then
            repeat
                RowNo := TempExcelBuffer."Row No.";

                // Saltar fila de encabezados (asumiendo que está en la fila 1)
                if RowNo = 1 then begin
                    // Saltar esta fila y continuar con la siguiente
                end else begin
                    // Inicializar variables
                    CodigoLinea := '';
                    Descripcion := '';
                    Tipo := '';
                    NoCuenta := '';
                    DescripcionCuenta := '';
                    LargoCodigo := 0;
                    Cantidad := 0;
                    Cost := 0;
                    Venta := 0;
                    TipoLinea := '';
                    EsSumatorio := false;


                    // Buscar datos de esta fila
                    TempExcelBuffer.SetRange("Row No.", RowNo);
                    if TempExcelBuffer.FindSet() then
                        repeat
                            case TempExcelBuffer."Column No." of
                                1: // Columna A - Código de línea
                                    begin
                                        CodigoLinea := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(JobTask."Job Task No."));
                                        // Detectar si es sumatorio por formato (negrita)
                                        EsSumatorio := TempExcelBuffer.Bold;
                                    end;
                                2: // Columna B - Descripción
                                    Descripcion := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(Descripcion));
                                3: // Columna C - Tipo (cuenta, producto, recurso)
                                    Tipo := CopyStr(UpperCase(TempExcelBuffer."Cell Value as Text"), 1, 20);
                                4: // Columna D - Número de cuenta/producto/recurso
                                    NoCuenta := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(NoCuenta));
                                5: // Columna E - Descripción cuenta contable
                                    DescripcionCuenta := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(DescripcionCuenta));
                                6: // Columna F - Largo del código
                                    begin
                                        If Not Evaluate(LargoCodigo, TempExcelBuffer."Cell Value as Text") then LargoCodigo := 0;
                                    end;
                                7: // Columna G - Cantidad
                                    If Not Evaluate(Cantidad, TempExcelBuffer."Cell Value as Text") then
                                        Cantidad := 0;
                                8: // Columna H - Importe Coste
                                    If Not Evaluate(Cost, TempExcelBuffer."Cell Value as Text") then
                                        Cost := 0;
                                9: // Columna I - Importe Venta
                                    If Not Evaluate(Venta, TempExcelBuffer."Cell Value as Text") then
                                        Venta := 0;
                                10: // Columna J - Tipo línea (Planificacion, Uso, Ambos)
                                    TipoLinea := CopyStr(UpperCase(TempExcelBuffer."Cell Value as Text"), 1, 20);
                            end;
                            if TempExcelBuffer.xlColID = rInf."Cta Contable Estructura" Then CtaCta := TempExcelBuffer."Cell Value as Text";
                        until TempExcelBuffer.Next() = 0;

                    // Determinar si es sumatorio basándose en el largo del código (Columna F)
                    // Si el largo del código es menor o igual al especificado en la columna F, es sumatorio
                    //if (LargoCodigo > 0) and (StrLen(CodigoLinea) <= LargoCodigo) then
                    EsSumatorio := false;

                    // Si no hay cuenta y no es sumatorio, marcar como sumatorio
                    if (NoCuenta = '') and not EsSumatorio then
                        EsSumatorio := true;

                    // Crear tarea de proyecto si hay datos válidos
                    if (CodigoLinea <> '') and (Descripcion <> '') then begin
                        if not JobTask.Get(Rec."No.", CodigoLinea) then begin
                            JobTask.Init();
                            JobTask."Job No." := Rec."No.";
                            JobTask."Job Task No." := CodigoLinea;

                            // Si es sumatorio, crear como tarea padre
                            if EsSumatorio then begin
                                JobTask.Description := Descripcion;
                                JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
                                JobTask."WIP-Total" := JobTask."WIP-Total"::Total;
                                ParentTaskNo := JobTask."Job Task No.";
                                JobTask.Totaling := CodigoLinea + '.00' + '..' + CodigoLinea + '.99';
                            end else begin
                                JobTask.Description := Descripcion;
                                JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                                JobTask."WIP-Total" := JobTask."WIP-Total"::" ";
                                JobTask."Tipo Partida" := JobTask."Tipo Partida"::Subcapítulo;
                            end;

                            If JobTask.Insert(true) then begin
                                ImportedTasks += 1;

                                // Si no es sumatorio, crear cuenta/producto/recurso si no existe
                                if not EsSumatorio and (NoCuenta <> '') then begin
                                    case UpperCase(Tipo) of
                                        'CUENTA', 'G/L ACCOUNT', 'GL ACCOUNT':
                                            begin
                                                if not GLAccount.Get(NoCuenta) then begin
                                                    GLAccount.Init();
                                                    GLAccount."No." := NoCuenta;
                                                    GLAccount.Name := CopyStr(DescripcionCuenta, 1, MaxStrLen(GLAccount.Name));
                                                    if DescripcionCuenta = '' then
                                                        GLAccount.Name := Descripcion;
                                                    GLAccount."Account Type" := GLAccount."Account Type"::Posting;
                                                    GLAccount."Direct Posting" := true;
                                                    GLAccount.Insert(true);
                                                end;
                                            end;
                                        'PRODUCTO', 'ITEM':
                                            begin
                                                if not Item.Get(NoCuenta) then begin
                                                    Item.Init();
                                                    Item."No." := NoCuenta;
                                                    Item.Description := CopyStr(Descripcion, 1, MaxStrLen(Item.Description));

                                                    // Si el Item Template está configurado, usarlo
                                                    if (JobsSetup."Item Template" <> '') and ItemTempl.Get(JobsSetup."Item Template") then begin
                                                        // Usar el template para crear el Item
                                                        ItemTemplMgt.InsertItemFromTemplate(Item);
                                                        If Item.Get(NoCuenta) then begin
                                                            //Grear Grupo registro prodducto por producto
                                                            Item."Gen. Prod. Posting Group" := Item."No.";
                                                            If Not GeNProdPostingGroup.Get(Item."Gen. Prod. Posting Group") then begin
                                                                GenProdPostingGroup.Init();
                                                                GenProdPostingGroup."Code" := Item."Gen. Prod. Posting Group";
                                                                GenProdPostingGroup.Description := Item."Gen. Prod. Posting Group";
                                                                GenProdPostingGroup.Insert(true);
                                                                If GenNegPostingGrup.FindFirst Then
                                                                    repeat
                                                                        GenPostingSetup.Init;
                                                                        GenPostingSetup."Gen. Bus. Posting Group" := GenNegPostingGrup.Code;
                                                                        GenPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup.Code;
                                                                        GenPostingSetup."Purch. Account" := CtaCta;
                                                                        GenPostingSetup.Insert();
                                                                    until GenNegPostingGrup.next = 0;
                                                            end;
                                                            Item.Modify(true);
                                                        end;
                                                    end else begin
                                                        // Si no hay template configurado, Error
                                                        Error('No hay template configurado para crear el Producto %1', NoCuenta);
                                                    end;
                                                end;
                                            end;
                                        'RECURSO', 'RESOURCE':
                                            begin
                                                if not Resource.Get(NoCuenta) then begin
                                                    Resource.Init();
                                                    Resource."No." := NoCuenta;
                                                    Resource.Name := CopyStr(Descripcion, 1, MaxStrLen(Resource.Name));
                                                    Resource.Type := Resource.Type::Person;
                                                    Resource.Insert(true);
                                                end;
                                            end;
                                    end;

                                    // Determinar el tipo de Job Planning Line según el Tipo
                                    LineNo := 10000;
                                    if (TipoLinea = 'PLANIFICACION') or (TipoLinea = 'AMBOS') then begin
                                        // Crear Job Planning Line
                                        JobTaskPlanningLine.Init();
                                        JobTaskPlanningLine."Job No." := Rec."No.";
                                        JobTaskPlanningLine."Job Task No." := JobTask."Job Task No.";
                                        JobTaskPlanningLine."Line No." := LineNo;

                                        // Determinar Line Type según TipoLinea
                                        if TipoLinea = 'PLANIFICACION' then
                                            JobTaskPlanningLine."Line Type" := JobTaskPlanningLine."Line Type"::Budget
                                        else if TipoLinea = 'AMBOS' then
                                            JobTaskPlanningLine."Line Type" := JobTaskPlanningLine."Line Type"::"Both Budget and Billable";

                                        // Determinar Type según el Tipo (columna C)
                                        case UpperCase(Tipo) of
                                            'CUENTA', 'G/L ACCOUNT', 'GL ACCOUNT':
                                                begin
                                                    JobTaskPlanningLine."Type" := JobTaskPlanningLine."Type"::"G/L Account";
                                                    JobTaskPlanningLine."No." := NoCuenta;
                                                end;
                                            'PRODUCTO', 'ITEM':
                                                begin
                                                    JobTaskPlanningLine."Type" := JobTaskPlanningLine."Type"::Item;
                                                    JobTaskPlanningLine."No." := NoCuenta;
                                                end;
                                            'RECURSO', 'RESOURCE':
                                                begin
                                                    JobTaskPlanningLine."Type" := JobTaskPlanningLine."Type"::Resource;
                                                    JobTaskPlanningLine."No." := NoCuenta;
                                                end;
                                        end;

                                        JobTaskPlanningLine.Description := Descripcion;
                                        if Cantidad <> 0 then
                                            JobTaskPlanningLine.Quantity := Cantidad
                                        else
                                            JobTaskPlanningLine.Quantity := 1;

                                        if Cost <> 0 then begin
                                            JobTaskPlanningLine."Unit Cost (LCY)" := Cost / JobTaskPlanningLine.Quantity;
                                            JobTaskPlanningLine."Total Cost (LCY)" := Cost;
                                        end;

                                        if Venta <> 0 then begin
                                            JobTaskPlanningLine."Unit Price (LCY)" := Venta / JobTaskPlanningLine.Quantity;
                                            JobTaskPlanningLine."Total Price (LCY)" := Venta;
                                        end;

                                        JobTaskPlanningLine."Usage Link" := true;
                                        JobTaskPlanningLine.INSERT;
                                        LineNo += 10000;
                                    end;

                                    // Crear Job Ledger Entry si es Uso o Ambos
                                    if (TipoLinea = 'USO') or (TipoLinea = 'AMBOS') then begin
                                        CodProyecto.CreaLineaUso(Rec."No.", JobTask."Job Task No.", Tipo, NoCuenta, Descripcion, Cantidad, Cost, Venta);
                                    end;
                                end;
                            end;
                        end;
                    end;

                    // Restaurar filtro para siguiente iteración
                    TempExcelBuffer.SetRange("Row No.");
                end;
            until TempExcelBuffer.Next() = 0;

        Message('Se importaron %1 tareas correctamente.', ImportedTasks);

        // Actualizar la página de tareas
        CurrPage.JobTaskLines2.Page.Update(false);
    end;
}
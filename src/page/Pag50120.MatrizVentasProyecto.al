page 50120 "Matriz Ventas Proyecto"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = Job;
    Caption = 'Matriz de Ventas por Proyecto';

    layout
    {
        area(Content)
        {
            group(Opciones)
            {
                Caption = 'Opciones de filtrado';
                field(FechaInicio; FechaInicio)
                {
                    ApplicationArea = All;
                    Caption = 'Fecha inicio';
                    ToolTip = 'Especifica la fecha de inicio para el análisis';

                    trigger OnValidate()
                    begin
                        SetPeriods();
                        CurrPage.Update(false);
                    end;
                }
                // field(TipoPeriodo; TipoPeriodo)
                // {
                //     ApplicationArea = All;
                //     Caption = 'Tipo de periodo';
                //     ToolTip = 'Especifica el tipo de periodo para el análisis';

                //     trigger OnValidate()
                //     begin
                //         SetPeriods();
                //         CurrPage.Update(false);
                //     end;
                // }
                field(NumeroPeriodos; NumeroPeriodos)
                {
                    ApplicationArea = All;
                    Caption = 'Número de periodos';
                    ToolTip = 'Especifica el número de periodos a mostrar (máximo 31)';
                    MinValue = 1;
                    MaxValue = 31;

                    trigger OnValidate()
                    begin
                        if NumeroPeriodos > 31 then
                            NumeroPeriodos := 31;
                        if NumeroPeriodos < 1 then
                            NumeroPeriodos := 1;

                        SetPeriods();
                        CurrPage.Update(false);
                    end;
                }
                // field(MostrarSoloAbiertos; MostrarSoloAbiertos)
                // {
                //     ApplicationArea = All;
                //     Caption = 'Solo proyectos abiertos';
                //     ToolTip = 'Especifica si se muestran solo proyectos con estado abierto';

                //     trigger OnValidate()
                //     begin
                //         if MostrarSoloAbiertos then
                //             Rec.SetRange(Status, Rec.Status::)
                //         else
                //             Rec.SetRange(Status);

                //         CurrPage.Update(false);
                //     end;
                // }
            }

            repeater(GroupName)
            {
                Caption = 'Proyectos';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del proyecto';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción del proyecto';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el estado del proyecto';
                }
                field("Project Status"; Rec."Project Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el estado detallado del proyecto';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el cliente del proyecto';
                }
                field(ColumnPeriod1; Period1Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 1';
                    CaptionClass = Period1Caption;
                    ToolTip = 'Muestra el importe total no facturado para el primer periodo';
                    BlankZero = true;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(1);
                    end;
                }
                field(ColumnPeriod2; Period2Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 2';
                    CaptionClass = Period2Caption;
                    ToolTip = 'Muestra el importe total no facturado para el segundo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible2;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(2);
                    end;
                }
                field(ColumnPeriod3; Period3Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 3';
                    CaptionClass = Period3Caption;
                    ToolTip = 'Muestra el importe total no facturado para el tercer periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible3;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(3);
                    end;
                }
                field(ColumnPeriod4; Period4Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 4';
                    CaptionClass = Period4Caption;
                    ToolTip = 'Muestra el importe total no facturado para el cuarto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible4;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(4);
                    end;
                }
                field(ColumnPeriod5; Period5Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 5';
                    CaptionClass = Period5Caption;
                    ToolTip = 'Muestra el importe total no facturado para el quinto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible5;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(5);
                    end;
                }
                field(ColumnPeriod6; Period6Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 6';
                    CaptionClass = Period6Caption;
                    ToolTip = 'Muestra el importe total no facturado para el sexto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible6;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(6);
                    end;
                }
                field(ColumnPeriod7; Period7Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 7';
                    CaptionClass = Period7Caption;
                    ToolTip = 'Muestra el importe total no facturado para el séptimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible7;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(7);
                    end;
                }
                field(ColumnPeriod8; Period8Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 8';
                    CaptionClass = Period8Caption;
                    ToolTip = 'Muestra el importe total no facturado para el octavo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible8;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(8);
                    end;
                }
                field(ColumnPeriod9; Period9Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 9';
                    CaptionClass = Period9Caption;
                    ToolTip = 'Muestra el importe total no facturado para el noveno periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible9;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(9);
                    end;
                }
                field(ColumnPeriod10; Period10Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 10';
                    CaptionClass = Period10Caption;
                    ToolTip = 'Muestra el importe total no facturado para el décimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible10;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(10);
                    end;
                }
                field(ColumnPeriod11; Period11Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 11';
                    CaptionClass = Period11Caption;
                    ToolTip = 'Muestra el importe total no facturado para el undécimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible11;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(11);
                    end;
                }
                field(ColumnPeriod12; Period12Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 12';
                    CaptionClass = Period12Caption;
                    ToolTip = 'Muestra el importe total no facturado para el duodécimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible12;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(12);
                    end;
                }
                field(ColumnPeriod13; Period13Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 13';
                    CaptionClass = Period13Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimotercero periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible13;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(13);
                    end;
                }
                field(ColumnPeriod14; Period14Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 14';
                    CaptionClass = Period14Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimocuarto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible14;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(14);
                    end;
                }
                field(ColumnPeriod15; Period15Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 15';
                    CaptionClass = Period15Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimoquinto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible15;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(15);
                    end;
                }
                field(ColumnPeriod16; Period16Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 16';
                    CaptionClass = Period16Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimosexto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible16;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(16);
                    end;
                }
                field(ColumnPeriod17; Period17Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 17';
                    CaptionClass = Period17Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimoséptimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible17;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(17);
                    end;
                }
                field(ColumnPeriod18; Period18Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 18';
                    CaptionClass = Period18Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimoctavo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible18;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(18);
                    end;
                }
                field(ColumnPeriod19; Period19Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 19';
                    CaptionClass = Period19Caption;
                    ToolTip = 'Muestra el importe total no facturado para el decimonoveno periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible19;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(19);
                    end;
                }
                field(ColumnPeriod20; Period20Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 20';
                    CaptionClass = Period20Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible20;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(20);
                    end;
                }
                field(ColumnPeriod21; Period21Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 21';
                    CaptionClass = Period21Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo primer periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible21;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(21);
                    end;
                }
                field(ColumnPeriod22; Period22Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 22';
                    CaptionClass = Period22Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo segundo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible22;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(22);
                    end;
                }
                field(ColumnPeriod23; Period23Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 23';
                    CaptionClass = Period23Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo tercero periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible23;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(23);
                    end;
                }
                field(ColumnPeriod24; Period24Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 24';
                    CaptionClass = Period24Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo cuarto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible24;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(24);
                    end;
                }
                field(ColumnPeriod25; Period25Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 25';
                    CaptionClass = Period25Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo quinto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible25;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(25);
                    end;
                }
                field(ColumnPeriod26; Period26Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 26';
                    CaptionClass = Period26Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo sexto periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible26;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(26);
                    end;
                }
                field(ColumnPeriod27; Period27Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 27';
                    CaptionClass = Period27Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo séptimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible27;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(27);
                    end;
                }
                field(ColumnPeriod28; Period28Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 28';
                    CaptionClass = Period28Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo octavo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible28;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(28);
                    end;
                }
                field(ColumnPeriod29; Period29Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 29';
                    CaptionClass = Period29Caption;
                    ToolTip = 'Muestra el importe total no facturado para el vigésimo noveno periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible29;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(29);
                    end;
                }
                field(ColumnPeriod30; Period30Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 30';
                    CaptionClass = Period30Caption;
                    ToolTip = 'Muestra el importe total no facturado para el trigésimo periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible30;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(30);
                    end;
                }
                field(ColumnPeriod31; Period31Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Periodo 31';
                    CaptionClass = Period31Caption;
                    ToolTip = 'Muestra el importe total no facturado para el trigésimo primer periodo';
                    BlankZero = true;
                    Editable = false;
                    Visible = PeriodVisible31;

                    trigger OnDrillDown()
                    begin
                        DrillDownPeriodoLineas(31);
                    end;
                }

                field(TotalPendingAmount; TotalPendingAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Pendiente';
                    ToolTip = 'Muestra el importe total no facturado para todos los periodos';
                    BlankZero = true;
                    Editable = false;
                    Style = Strong;

                    trigger OnDrillDown()
                    begin
                        DrillDownTotal();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // action(ActualizarPeriodos)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Actualizar Periodos';
            //     ToolTip = 'Actualiza los periodos para la matriz';
            //     Image = Calendar;
            //     Promoted = true;
            //     PromotedCategory = Process;

            //     trigger OnAction()
            //     begin
            //         SetPeriods();
            //         CurrPage.Update(false);
            //     end;
            // }
            action(MostrarDetalle)
            {
                ApplicationArea = All;
                Caption = 'Mostrar Detalle';
                ToolTip = 'Muestra las líneas de proyecto pendientes de facturar';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Planning Line";
                    PendientesFacturar: Page "Pendiente facturar";
                begin
                    JobPlanningLine.SetRange("Job No.", Rec."No.");
                    JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable");
                    JobPlanningLine.SetFilter("Qty. to Invoice", '<>%1', 0);

                    if JobPlanningLine.FindSet() then;
                    PendientesFacturar.SetTableView(JobPlanningLine);
                    PendientesFacturar.RunModal();
                end;
            }
            action(ExportarExcel)
            {
                ApplicationArea = All;
                Caption = 'Exportar a Excel';
                ToolTip = 'Exporta los datos de la matriz a Excel';
                Image = ExportToExcel;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    ExportToExcel();
                end;
            }
        }
        area(Navigation)
        {
            action("Ficha Proyecto")
            {
                ApplicationArea = All;
                Caption = 'Ficha Proyecto';
                ToolTip = 'Abre la ficha del proyecto seleccionado';
                Image = Job;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Job Card";
                RunPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateAmounts();
        UpdateAmountsVariables();
    end;

    trigger OnOpenPage()
    begin
        // Inicializar valores por defecto
        if FechaInicio = 0D then
            FechaInicio := WorkDate();

        if NumeroPeriodos = 0 then
            NumeroPeriodos := 31;

        SetPeriods();
        UpdateVisibilityVariables();

        if MostrarSoloAbiertos then
            Rec.SetRange(Status, Rec.Status::Open);
    end;

    var
        StartDate: array[31] of Date;
        EndDate: array[31] of Date;
        PeriodCaption: array[31] of Text;
        PeriodVisible: array[31] of Boolean;
        ColumnPeriod: array[31] of Decimal;
        TotalPendingAmount: Decimal;
        FechaInicio: Date;
        TipoPeriodo: Option Mes,Trimestre,Año,Día;
        NumeroPeriodos: Integer;
        MostrarSoloAbiertos: Boolean;
        Period1Caption: Text;
        Period2Caption: Text;
        Period3Caption: Text;
        Period4Caption: Text;
        Period5Caption: Text;
        Period6Caption: Text;
        Period7Caption: Text;
        Period8Caption: Text;
        Period9Caption: Text;
        Period10Caption: Text;
        Period11Caption: Text;
        Period12Caption: Text;
        Period13Caption: Text;
        Period14Caption: Text;
        Period15Caption: Text;
        Period16Caption: Text;
        Period17Caption: Text;
        Period18Caption: Text;
        Period19Caption: Text;
        Period20Caption: Text;
        Period21Caption: Text;
        Period22Caption: Text;
        Period23Caption: Text;
        Period24Caption: Text;
        Period25Caption: Text;
        Period26Caption: Text;
        Period27Caption: Text;
        Period28Caption: Text;
        Period29Caption: Text;
        Period30Caption: Text;
        Period31Caption: Text;
        Period1Amount: Decimal;
        Period2Amount: Decimal;
        Period3Amount: Decimal;
        Period4Amount: Decimal;
        Period5Amount: Decimal;
        Period6Amount: Decimal;
        Period7Amount: Decimal;
        Period8Amount: Decimal;
        Period9Amount: Decimal;
        Period10Amount: Decimal;
        Period11Amount: Decimal;
        Period12Amount: Decimal;
        Period13Amount: Decimal;
        Period14Amount: Decimal;
        Period15Amount: Decimal;
        Period16Amount: Decimal;
        Period17Amount: Decimal;
        Period18Amount: Decimal;
        Period19Amount: Decimal;
        Period20Amount: Decimal;
        Period21Amount: Decimal;
        Period22Amount: Decimal;
        Period23Amount: Decimal;
        Period24Amount: Decimal;
        Period25Amount: Decimal;
        Period26Amount: Decimal;
        Period27Amount: Decimal;
        Period28Amount: Decimal;
        Period29Amount: Decimal;
        Period30Amount: Decimal;
        Period31Amount: Decimal;
        PeriodVisible2: Boolean;
        PeriodVisible3: Boolean;
        PeriodVisible4: Boolean;
        PeriodVisible5: Boolean;
        PeriodVisible6: Boolean;
        PeriodVisible7: Boolean;
        PeriodVisible8: Boolean;
        PeriodVisible9: Boolean;
        PeriodVisible10: Boolean;
        PeriodVisible11: Boolean;
        PeriodVisible12: Boolean;
        PeriodVisible13: Boolean;
        PeriodVisible14: Boolean;
        PeriodVisible15: Boolean;
        PeriodVisible16: Boolean;
        PeriodVisible17: Boolean;
        PeriodVisible18: Boolean;
        PeriodVisible19: Boolean;
        PeriodVisible20: Boolean;
        PeriodVisible21: Boolean;
        PeriodVisible22: Boolean;
        PeriodVisible23: Boolean;
        PeriodVisible24: Boolean;
        PeriodVisible25: Boolean;
        PeriodVisible26: Boolean;
        PeriodVisible27: Boolean;
        PeriodVisible28: Boolean;
        PeriodVisible29: Boolean;
        PeriodVisible30: Boolean;
        PeriodVisible31: Boolean;





    local procedure SetPeriods()
    var
        i: Integer;
        TempDate: Date;
    begin
        TempDate := FechaInicio;
        if TempDate = 0D then
            TempDate := WorkDate();
        case TipoPeriodo of
            TipoPeriodo::Mes:
                begin
                    NumeroPeriodos := 12;

                end;
            TipoPeriodo::Trimestre:
                begin
                    NumeroPeriodos := 4;

                end;
            TipoPeriodo::Año:
                begin
                    NumeroPeriodos := 12;

                end;
            TipoPeriodo::Día:
                begin
                    NumeroPeriodos := 31;

                end;
        end;
        // Inicializar visibilidad
        for i := 1 to 31 do
            PeriodVisible[i] := i <= NumeroPeriodos;

        // Definir los periodos según el tipo seleccionado
        for i := 1 to NumeroPeriodos do begin
            case TipoPeriodo of
                TipoPeriodo::Mes:
                    begin
                        if i = 1 then begin
                            StartDate[i] := CalcDate('<-CM>', TempDate);
                            EndDate[i] := CalcDate('<CM>', TempDate);
                        end else begin
                            StartDate[i] := CalcDate('<-CM-' + Format(i - 1) + 'M>', TempDate);
                            EndDate[i] := CalcDate('<CM-' + Format(i - 1) + 'M>', TempDate);
                        end;
                        PeriodCaption[i] := Format(StartDate[i], 0, '<Month Text> <Year>');
                    end;
                TipoPeriodo::Trimestre:
                    begin
                        if i = 1 then begin
                            StartDate[i] := CalcDate('<-CQ>', TempDate);
                            EndDate[i] := CalcDate('<CQ>', TempDate);
                        end else begin
                            StartDate[i] := CalcDate('<-CQ-' + Format(i - 1) + 'Q>', TempDate);
                            EndDate[i] := CalcDate('<CQ-' + Format(i - 1) + 'Q>', TempDate);
                        end;
                        PeriodCaption[i] := 'T' + Format(Date2DMY(StartDate[i], 2) div 3 + 1) + ' ' + Format(Date2DMY(StartDate[i], 3));
                    end;
                TipoPeriodo::Año:
                    begin
                        if i = 1 then begin
                            StartDate[i] := CalcDate('<-CY>', TempDate);
                            EndDate[i] := CalcDate('<CY>', TempDate);
                        end else begin
                            StartDate[i] := CalcDate('<-CY-' + Format(i - 1) + 'Y>', TempDate);
                            EndDate[i] := CalcDate('<CY-' + Format(i - 1) + 'Y>', TempDate);
                        end;
                        PeriodCaption[i] := Format(Date2DMY(StartDate[i], 3));
                    end;
            end;
        end;

        // Guardar captions en variables
        if NumeroPeriodos >= 1 then
            Period1Caption := PeriodCaption[1];
        if NumeroPeriodos >= 2 then
            Period2Caption := PeriodCaption[2];
        if NumeroPeriodos >= 3 then
            Period3Caption := PeriodCaption[3];
        if NumeroPeriodos >= 4 then
            Period4Caption := PeriodCaption[4];
        if NumeroPeriodos >= 5 then
            Period5Caption := PeriodCaption[5];
        if NumeroPeriodos >= 6 then
            Period6Caption := PeriodCaption[6];
        if NumeroPeriodos >= 7 then
            Period7Caption := PeriodCaption[7];
        if NumeroPeriodos >= 8 then
            Period8Caption := PeriodCaption[8];
        if NumeroPeriodos >= 9 then
            Period9Caption := PeriodCaption[9];
        if NumeroPeriodos >= 10 then
            Period10Caption := PeriodCaption[10];
        if NumeroPeriodos >= 11 then
            Period11Caption := PeriodCaption[11];
        if NumeroPeriodos >= 12 then
            Period12Caption := PeriodCaption[12];
        if NumeroPeriodos >= 13 then
            Period13Caption := PeriodCaption[13];
        if NumeroPeriodos >= 14 then
            Period14Caption := PeriodCaption[14];
        if NumeroPeriodos >= 15 then
            Period15Caption := PeriodCaption[15];
        if NumeroPeriodos >= 16 then
            Period16Caption := PeriodCaption[16];
        if NumeroPeriodos >= 17 then
            Period17Caption := PeriodCaption[17];
        if NumeroPeriodos >= 18 then
            Period18Caption := PeriodCaption[18];
        if NumeroPeriodos >= 19 then
            Period19Caption := PeriodCaption[19];
        if NumeroPeriodos >= 20 then
            Period20Caption := PeriodCaption[20];
        if NumeroPeriodos >= 21 then
            Period21Caption := PeriodCaption[21];
        if NumeroPeriodos >= 22 then
            Period22Caption := PeriodCaption[22];
        if NumeroPeriodos >= 23 then
            Period23Caption := PeriodCaption[23];
        if NumeroPeriodos >= 24 then
            Period24Caption := PeriodCaption[24];
        if NumeroPeriodos >= 25 then
            Period25Caption := PeriodCaption[25];
        if NumeroPeriodos >= 26 then
            Period26Caption := PeriodCaption[26];
        if NumeroPeriodos >= 27 then
            Period27Caption := PeriodCaption[27];
        if NumeroPeriodos >= 28 then
            Period28Caption := PeriodCaption[28];
        if NumeroPeriodos >= 29 then
            Period29Caption := PeriodCaption[29];
        if NumeroPeriodos >= 30 then
            Period30Caption := PeriodCaption[30];
        if NumeroPeriodos >= 31 then
            Period31Caption := PeriodCaption[31];

        UpdateVisibilityVariables();
    end;

    local procedure UpdateVisibilityVariables()
    begin
        PeriodVisible2 := PeriodVisible[2];
        PeriodVisible3 := PeriodVisible[3];
        PeriodVisible4 := PeriodVisible[4];
        PeriodVisible5 := PeriodVisible[5];
        PeriodVisible6 := PeriodVisible[6];
        PeriodVisible7 := PeriodVisible[7];
        PeriodVisible8 := PeriodVisible[8];
        PeriodVisible9 := PeriodVisible[9];
        PeriodVisible10 := PeriodVisible[10];
        PeriodVisible11 := PeriodVisible[11];
        PeriodVisible12 := PeriodVisible[12];
        PeriodVisible13 := PeriodVisible[13];
        PeriodVisible14 := PeriodVisible[14];
        PeriodVisible15 := PeriodVisible[15];
        PeriodVisible16 := PeriodVisible[16];
        PeriodVisible17 := PeriodVisible[17];
        PeriodVisible18 := PeriodVisible[18];
        PeriodVisible19 := PeriodVisible[19];
        PeriodVisible20 := PeriodVisible[20];
        PeriodVisible21 := PeriodVisible[21];
        PeriodVisible22 := PeriodVisible[22];
        PeriodVisible23 := PeriodVisible[23];
        PeriodVisible24 := PeriodVisible[24];
        PeriodVisible25 := PeriodVisible[25];
        PeriodVisible26 := PeriodVisible[26];
        PeriodVisible27 := PeriodVisible[27];
        PeriodVisible28 := PeriodVisible[28];
        PeriodVisible29 := PeriodVisible[29];
        PeriodVisible30 := PeriodVisible[30];
        PeriodVisible31 := PeriodVisible[31];




    end;

    local procedure UpdateAmountsVariables()
    begin
        Period1Amount := ColumnPeriod[1];
        Period2Amount := ColumnPeriod[2];
        Period3Amount := ColumnPeriod[3];
        Period4Amount := ColumnPeriod[4];
        Period5Amount := ColumnPeriod[5];
        Period6Amount := ColumnPeriod[6];
        Period7Amount := ColumnPeriod[7];
        Period8Amount := ColumnPeriod[8];
        Period9Amount := ColumnPeriod[9];
        Period10Amount := ColumnPeriod[10];
        Period11Amount := ColumnPeriod[11];
        Period12Amount := ColumnPeriod[12];
        Period13Amount := ColumnPeriod[13];
        Period14Amount := ColumnPeriod[14];
        Period15Amount := ColumnPeriod[15];
        Period16Amount := ColumnPeriod[16];
        Period17Amount := ColumnPeriod[17];
        Period18Amount := ColumnPeriod[18];
        Period19Amount := ColumnPeriod[19];
        Period20Amount := ColumnPeriod[20];
        Period21Amount := ColumnPeriod[21];
        Period22Amount := ColumnPeriod[22];
        Period23Amount := ColumnPeriod[23];
        Period24Amount := ColumnPeriod[24];
        Period25Amount := ColumnPeriod[25];
        Period26Amount := ColumnPeriod[26];
        Period27Amount := ColumnPeriod[27];
        Period28Amount := ColumnPeriod[28];
        Period29Amount := ColumnPeriod[29];
        Period30Amount := ColumnPeriod[30];
        Period31Amount := ColumnPeriod[31];


    end;

    local procedure CalculateAmounts()
    var
        JobPlanningLine: Record "Job Planning Line";
        i: Integer;
    begin
        Clear(ColumnPeriod);
        Clear(TotalPendingAmount);

        for i := 1 to NumeroPeriodos do begin
            JobPlanningLine.Reset();
            JobPlanningLine.SetRange("Job No.", Rec."No.");
            JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable");
            JobPlanningLine.SetFilter("Qty. to Invoice", '<>%1', 0);

            JobPlanningLine.SetRange("Planning Date", StartDate[i], EndDate[i]);

            if JobPlanningLine.FindSet() then
                repeat
                    ColumnPeriod[i] += JobPlanningLine."Total Price (LCY)";
                until JobPlanningLine.Next() = 0;

            TotalPendingAmount += ColumnPeriod[i];
        end;
    end;

    local procedure DrillDownPeriodoLineas(PeriodoNum: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        PendientesFacturar: Page "Pendiente facturar";
    begin
        if (PeriodoNum <= 0) or (PeriodoNum > NumeroPeriodos) then
            exit;

        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Rec."No.");
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.SetFilter("Qty. to Invoice", '<>%1', 0);
        JobPlanningLine.SetRange("Planning Date", StartDate[PeriodoNum], EndDate[PeriodoNum]);

        if JobPlanningLine.FindSet() then;
        PendientesFacturar.Caption := 'Pendientes facturar - ' + PeriodCaption[PeriodoNum];
        PendientesFacturar.SetTableView(JobPlanningLine);
        PendientesFacturar.RunModal();
    end;

    local procedure DrillDownTotal()
    var
        JobPlanningLine: Record "Job Planning Line";
        PendientesFacturar: Page "Pendiente facturar";
    begin
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Rec."No.");
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.SetFilter("Qty. to Invoice", '<>%1', 0);

        if JobPlanningLine.FindSet() then;
        PendientesFacturar.Caption := 'Total Pendientes facturar';
        PendientesFacturar.SetTableView(JobPlanningLine);
        PendientesFacturar.RunModal();
    end;

    local procedure ExportToExcel()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFileName: Text;
        SheetName: Text;
        i: Integer;
    begin
        SheetName := 'Matriz Ventas Proyecto';
        TempExcelBuffer.DeleteAll();

        // Crear cabecera
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(Rec.FieldCaption("No."), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Rec.FieldCaption(Description), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Rec.FieldCaption(Status), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Rec.FieldCaption("Project Status"), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Rec.FieldCaption("Sell-to Customer No."), false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);

        // Crear cabeceras de periodos
        for i := 1 to NumeroPeriodos do
            if PeriodVisible[i] then
                TempExcelBuffer.AddColumn(PeriodCaption[i], false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);

        TempExcelBuffer.AddColumn('Total Pendiente', false, '', true, false, true, '', TempExcelBuffer."Cell Type"::Text);

        // Buscar todos los datos
        if Rec.FindSet() then
            repeat
                TempExcelBuffer.NewRow();
                TempExcelBuffer.AddColumn(Rec."No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(Rec.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(Format(Rec.Status), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(Format(Rec."Project Status"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(Rec."Sell-to Customer No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);

                CalculateAmounts();
                UpdateAmountsVariables();

                for i := 1 to NumeroPeriodos do
                    if PeriodVisible[i] then
                        TempExcelBuffer.AddColumn(ColumnPeriod[i], false, '', false, false, false, '@', TempExcelBuffer."Cell Type"::Number);

                TempExcelBuffer.AddColumn(TotalPendingAmount, false, '', false, false, false, '@', TempExcelBuffer."Cell Type"::Number);

            until Rec.Next() = 0;

        // Exportar
        ExcelFileName := 'Matriz_Ventas_Proyecto_' + Format(Today, 0, '<Year4><Month,2><Day,2>');
        TempExcelBuffer.CreateNewBook(SheetName);
        TempExcelBuffer.WriteSheet(SheetName, CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename(ExcelFileName);
        TempExcelBuffer.OpenExcel();
    end;
}
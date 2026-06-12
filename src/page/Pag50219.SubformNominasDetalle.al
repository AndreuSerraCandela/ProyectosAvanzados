/// <summary>
/// Page Subform Nominas Detalle (ID 50219).
/// Subform para el detalle de nóminas
/// </summary>
page 50219 "Subform Nominas Detalle"
{
    PageType = ListPart;
    SourceTable = "Nominas Detalle";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Empleado; Rec.Empleado)
                {
                    ApplicationArea = All;
                }
                field(Departamento; Rec.Departamento)
                {
                    ApplicationArea = All;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;
                    ToolTip = 'Especifica el código de la dimensión global vinculada al registro.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Identificador del conjunto de dimensiones.';
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Especifica el número del proyecto asociado a la línea de nómina.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Tarea del proyecto para el coste de nómina (devengado y resto de coste sin SS empresa).';
                }
                field("Job Task No. SS"; Rec."Job Task No. SS")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Tarea del proyecto para la imputación de SS empresa (cuenta 642). Vinculada al mov. de empleado Seg. Social.';
                }
                field(Coste; Rec.Coste)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Coste total del empleado (devengado + SS total - enfermedad/accidente). SS total incluye S.S Obrero y SS empresa. Se imputa al proyecto al registrar el diario.';
                }
                field("Employee Entry No."; Rec."Employee Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Movimiento de empleado Nómina (Personal). Enlaza con el mov. de proyecto principal.';
                }
                field("Employee Entry No. SS"; Rec."Employee Entry No. SS")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Movimiento de empleado Seg. Social. Enlaza con el mov. de proyecto SS empresa.';
                }
                field("Job Ledger Entry No."; Rec."Job Ledger Entry No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Movimiento de proyecto principal (coste sin SS empresa).';
                }
                field("Job Ledger Entry No. SS"; Rec."Job Ledger Entry No. SS")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Movimiento de proyecto SS empresa (cuenta 642).';
                }
                field(Devengado; Rec.Devengado)
                {
                    ApplicationArea = All;
                }
                field("S.S Obrero"; Rec."S.S Obrero")
                {
                    ApplicationArea = All;
                }
                field(IRPF; Rec.IRPF)
                {
                    ApplicationArea = All;
                }
                field("SS empresa"; Rec."SS empresa")
                {
                    ApplicationArea = All;
                }
                field("Enfermedad Accidente"; Rec."Enfermedad Accidente")
                {
                    ApplicationArea = All;
                }
                field("Bonificación"; Rec."Bonificación")
                {
                    ApplicationArea = All;
                }
                field("Bonificación Fundae"; Rec."Bonificación Fundae")
                {
                    ApplicationArea = All;
                }
                field(Kms; Rec.Kms)
                {
                    ApplicationArea = All;
                }
                field(Dieta; Rec.Dieta)
                {
                    ApplicationArea = All;
                }
                field("Dto. Especie"; Rec."Dto. Especie")
                {
                    ApplicationArea = All;
                }
                field(Anticipos; Rec.Anticipos)
                {
                    ApplicationArea = All;
                }
                field(Embargos; Rec.Embargos)
                {
                    ApplicationArea = All;
                }
                field(Personal; Rec.Personal)
                {
                    ApplicationArea = All;
                }
                field(Banco; Rec.Banco)
                {
                    ApplicationArea = All;
                }
                field("P.P.Ex"; Rec."P.P.Ex")
                {
                    ApplicationArea = All;
                }
                field("MEJORA V"; Rec."MEJORA V")
                {
                    ApplicationArea = All;
                }
                field(COMIDA; Rec.COMIDA)
                {
                    ApplicationArea = All;
                }
                field(DIETAS; Rec.DIETAS)
                {
                    ApplicationArea = All;
                }
                field("P.P Vaca"; Rec."P.P Vaca")
                {
                    ApplicationArea = All;
                }
                field("PL. FLEX"; Rec."PL. FLEX")
                {
                    ApplicationArea = All;
                }
                field(Indemni; Rec.Indemni)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensiones';
                Image = Dimensions;
                ShortCutKey = 'Shift+Ctrl+D';
                ToolTip = 'Ver o editar las dimensiones de la línea de nómina. Los cambios se actualizan en la ficha del empleado.';

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        ShortcutDimCode: array[8] of Code[20];
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    local procedure SetDimensionsVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;
        if GLSetup.Get() then begin
            DimVisible3 := GLSetup."Shortcut Dimension 3 Code" <> '';
            DimVisible4 := GLSetup."Shortcut Dimension 4 Code" <> '';
            DimVisible5 := GLSetup."Shortcut Dimension 5 Code" <> '';
            DimVisible6 := GLSetup."Shortcut Dimension 6 Code" <> '';
            DimVisible7 := GLSetup."Shortcut Dimension 7 Code" <> '';
            DimVisible8 := GLSetup."Shortcut Dimension 8 Code" <> '';
        end;
    end;
}


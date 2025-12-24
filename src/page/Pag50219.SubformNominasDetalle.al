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
}


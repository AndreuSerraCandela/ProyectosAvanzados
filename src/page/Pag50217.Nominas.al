/// <summary>
/// Page Nominas (ID 50217).
/// Página Card para la cabecera de nóminas
/// </summary>
page 50217 "Nominas"
{
    PageType = Card;
    SourceTable = "Cabecera Nominas";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Fecha; Rec.Fecha)
                {
                    ApplicationArea = All;
                }
                field(Departamento; Rec.Departamento)
                {
                    ApplicationArea = All;
                }
                field(Contabilizado; Rec.Contabilizado)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Nº Documento"; Rec."Nº Documento")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(Totales)
            {
                Caption = 'Totales';
                field(Devengado; Rec.Devengado)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("S.S Obrero"; Rec."S.S Obrero")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(IRPF; Rec.IRPF)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("SS empresa"; Rec."SS empresa")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Enfermedad Accidente"; Rec."Enfermedad Accidente")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Bonificación"; Rec."Bonificación")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Bonificación Fundae"; Rec."Bonificación Fundae")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Personal; Rec.Personal)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Banco; Rec.Banco)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("P.P.Ex"; Rec."P.P.Ex")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("MEJORA V"; Rec."MEJORA V")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(COMIDA; Rec.COMIDA)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(DIETAS; Rec.DIETAS)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("P.P Vaca"; Rec."P.P Vaca")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("PL. FLEX"; Rec."PL. FLEX")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Indemni; Rec.Indemni)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            part(Lineas; "Subform Nominas Detalle")
            {
                ApplicationArea = All;
                SubPageLink = Fecha = FIELD(Fecha),
                              Departamento = FIELD(Departamento);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Contabilizar)
            {
                ApplicationArea = All;
                Image = Register;
                Caption = 'Contabilizar';
                ShortCutKey = 'F9';
                ToolTip = 'Contabiliza las nóminas creando las líneas de diario y movimientos de empleado';

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit 50301;
                    rNomDet: Record "Nominas Detalle";
                    Employee: Record Employee;
                    GenJnlLine: Record "Gen. Journal Line";
                    NoSeriesMgt: Codeunit "No. Series";
                    rOr: Record "Source Code";
                    NoSeries: Record "No. Series";
                    Doc: Code[20];
                    LINEA: Integer;
                    EmpresaNombre: Text[30];
                begin
                    if Rec.Contabilizado then
                        if not Confirm('La nómina ya está contabilizada. ¿Desea volver a contabilizar?', false) then
                            exit;

                    // Verificar que existe el código fuente
                    if not rOr.Get('NOMINAS') then begin
                        rOr.Code := 'NOMINAS';
                        rOr.Description := 'Nóminas';
                        rOr.Insert();
                    end;

                    // Obtener serie de documentos
                    NoSeries.SetRange(Code, 'NOMINAS');
                    if not NoSeries.FindFirst() then
                        Error('No existe la serie de documentos "NOMINAS"');

                    // Obtener última línea del diario
                    GenJnlLine.SetRange("Journal Template Name", 'GENERAL');
                    GenJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
                    if GenJnlLine.FindLast() then
                        LINEA := GenJnlLine."Line No." + 10000
                    else
                        LINEA := 10000;

                    // Generar número de documento
                    Clear(NoSeriesMgt);
                    Doc := NoSeriesMgt.GetNextNo(NoSeries.Code, Rec.Fecha, false);
                    Rec."Nº Documento" := Doc;

                    // Obtener nombre de la empresa actual
                    EmpresaNombre := CompanyName;

                    // Procesar cada empleado
                    rNomDet.SetRange(Fecha, Rec.Fecha);
                    rNomDet.SetRange(Departamento, Rec.Departamento);

                    if rNomDet.FindSet() then
                        repeat
                            if Employee.Get(rNomDet.Empleado) then begin
                                ProcesosProyectos.CrearLineasDiarioNominas(
                                    GenJnlLine, Employee, EmpresaNombre, Rec.Fecha, Doc, LINEA, rOr,
                                    rNomDet.Devengado, rNomDet."S.S Obrero", rNomDet.IRPF, rNomDet."SS empresa",
                                    rNomDet."Enfermedad Accidente", rNomDet."Bonificación", rNomDet."Bonificación Fundae",
                                    rNomDet.Anticipos, rNomDet.Embargos, rNomDet."Dto. Especie", rNomDet.Dieta,
                                    rNomDet.Kms, rNomDet.Banco, rNomDet.Personal, rNomDet."Ant.diet");
                            end;
                        until rNomDet.Next() = 0;

                    Rec.Contabilizado := true;
                    Rec.Modify();
                    Commit();

                    Message('Nómina contabilizada. Documento: %1', Doc);
                end;
            }
            action(Configurar)
            {
                ApplicationArea = All;
                Image = Setup;
                Caption = 'Configurar';
                RunObject = Page "Configuración Nominas";
                ToolTip = 'Abre la configuración de cuentas de nóminas';
            }
        }
    }
}


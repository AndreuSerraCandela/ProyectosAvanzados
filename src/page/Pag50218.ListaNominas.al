/// <summary>
/// Page Lista Nominas (ID 50218).
/// Lista de nóminas
/// </summary>
page 50218 "Lista Nominas"
{
    PageType = List;
    SourceTable = "Cabecera Nominas";
    UsageCategory = Lists;
    ApplicationArea = All;
    CardPageId = "Nominas";

    layout
    {
        area(content)
        {
            repeater(General)
            {
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
                }
                field("Nº Documento"; Rec."Nº Documento")
                {
                    ApplicationArea = All;
                }
                field(Devengado; Rec.Devengado)
                {
                    ApplicationArea = All;
                }
                field(Personal; Rec.Personal)
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
            action(Importar)
            {
                ApplicationArea = All;
                Image = Import;
                Caption = 'Importar desde Excel';
                ToolTip = 'Importa las nóminas desde un archivo Excel';

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit 50301;
                    wFecha: Date;
                    fNom: Page "Date-Time Dialog";
                begin
                    Clear(fNom);
                    if fNom.RunModal() in [Action::Cancel, Action::LookupCancel, Action::No, Action::None] then
                        Error('Proceso Cancelado');
                    wFecha := fNom.GetDate();
                    ProcesosProyectos.ContabilizarNominasDesdeExcel('1', wFecha);
                    CurrPage.Update(false);
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


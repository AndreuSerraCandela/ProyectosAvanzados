/// <summary>
/// Page Lista Configuración Nominas (ID 50216).
/// Lista de configuraciones de nóminas
/// </summary>
page 50216 "Lista Configuración Nominas"
{
    PageType = List;
    SourceTable = "Nominas Configuración";
    UsageCategory = Administration;
    ApplicationArea = All;
    CardPageId = "Configuración Nominas";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Texto; Rec.Texto)
                {
                    Caption = 'Empleado';
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
                field(Banco; Rec.Banco)
                {
                    ApplicationArea = All;
                }
                field(Programa; Rec.Programa)
                {
                    ApplicationArea = All;
                }
                field(Departamento; Rec.Departamento)
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
            action("Nueva Configuración")
            {
                ApplicationArea = All;
                Image = New;
                RunObject = Page "Configuración Nominas";
                RunPageMode = Create;
                ToolTip = 'Crea una nueva configuración de nóminas';
            }
        }
    }
}


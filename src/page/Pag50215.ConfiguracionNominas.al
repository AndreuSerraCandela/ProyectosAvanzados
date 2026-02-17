/// <summary>
/// Page Configuración Nominas (ID 50215).
/// Página para configurar las cuentas contables de nóminas
/// </summary>
page 50215 "Configuración Nominas"
{
    PageType = Card;
    SourceTable = "Nominas Configuración";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(Clave)
            {
                Caption = 'Clave';
                field(Empleado; Rec.Texto)
                {
                    Caption = 'Empleado (blanco=todos)';
                    ApplicationArea = All;
                    ToolTip = 'Especifica el código del empleado. Dejar en blanco para aplicar a todos los empleados.';
                }
                field("Dígitos Subcuenta"; Rec."Dígitos Subcuenta")
                {
                    ApplicationArea = All;
                    Caption = 'Dígitos Subcuenta por Defecto';
                    ToolTip = 'Especifica el número de dígitos de subcuenta que se añadirán a las cuentas base. Ejemplo: si son 7 dígitos, la cuenta 640 se convertirá en 6400001';
                }
            }
            group(General)
            {
                Caption = 'General';
                group(DebeGeneral)
                {
                    Caption = 'Debe';
                    field(Devengado; Rec.Devengado)
                    {
                        ApplicationArea = All;
                        Caption = 'Devengado';
                    }
                    field(Kms; Rec.Kms)
                    {
                        ApplicationArea = All;
                        Caption = 'Kms';
                    }
                    field("Descuento Especie Debe"; Rec."Especie Debe")
                    {
                        Caption = 'Descuento Especie Debe';
                        ApplicationArea = All;
                    }
                    field("Dieta"; Rec."Dieta")
                    {
                        Caption = 'Dieta';
                        ApplicationArea = All;
                    }
                }
                group(HaberGeneral)
                {
                    Caption = 'Haber';
                    field("Descuento Especie Haber"; Rec."Especie Haber")
                    {
                        Caption = 'Descuento Especie Haber';
                        ApplicationArea = All;
                    }
                    field("S.S Obrero"; Rec."S.S Obrero")
                    {
                        ApplicationArea = All;
                        Caption = 'S.S Obrero';
                    }
                    field(IRPF; Rec.IRPF)
                    {
                        ApplicationArea = All;
                        Caption = 'IRPF';
                    }
                    field(Anticipos; Rec.Anticipos)
                    {
                        ApplicationArea = All;
                        Caption = 'Anticipos';
                    }
                    field(Embargos; Rec.Embargos)
                    {
                        ApplicationArea = All;
                        Caption = 'Embargos';
                    }
                    field("Account Type"; Rec."Account Type")
                    {
                        ApplicationArea = All;
                        Caption = 'Ficha Personal/Cuenta';
                        trigger OnValidate()
                        begin
                            Cuenta := Rec."Account Type" = Rec."Account Type"::"G/L Account";
                        end;
                    }
                    field(Personal; Rec.Personal)
                    {
                        ApplicationArea = All;
                        Caption = 'Personal';
                        Editable = Cuenta;
                    }
                }
            }
            group("Seguridad Social")
            {
                Caption = 'Seguridad Social';
                group(DebeSS)
                {
                    Caption = 'Debe';
                    field("SS empresa"; Rec."SS empresa")
                    {
                        ApplicationArea = All;
                        Caption = 'SS empresa';
                    }
                }
                group(HaberSS)
                {
                    Caption = 'Haber';
                    field(Bonificación; Rec.Bonificación)
                    {
                        ApplicationArea = All;
                        Caption = 'Bonificación';
                    }
                    field("Bonificación Fundae"; Rec."Bonificación Fundae")
                    {
                        ApplicationArea = All;
                        Caption = 'Bonificación Fundae';
                    }
                    field("Enfermedad Accidente"; Rec."Enfermedad Accidente")
                    {
                        ApplicationArea = All;
                        Caption = 'Enfermedad Accidente';
                    }
                    field("SS empresa 2"; Rec."SS empresa 2")
                    {
                        ApplicationArea = All;
                        Caption = 'SS empresa 2';
                    }
                }
            }
            group(Facturación)
            {
                Caption = 'Facturación';
                field("Recurso Facturación"; Rec."Recurso Facturación")
                {
                    ApplicationArea = All;
                    Caption = 'Recurso Facturación';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = All;
                }
                field("Global Dimension 3 Code"; Rec."Global Dimension 3 Code")
                {
                    ApplicationArea = All;
                }
                field("Global Dimension 4 Code"; Rec."Global Dimension 4 Code")
                {
                    ApplicationArea = All;
                }
                field("Global Dimension 5 Code"; Rec."Global Dimension 5 Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Cobro)
            {
                Caption = 'Cobro';
                field("Cobro Nómina"; Rec."Cobro Nómina")
                {
                    ApplicationArea = All;
                    Caption = 'Cobro Nómina';
                }
                field(Banco; Rec.Banco)
                {
                    ApplicationArea = All;
                    Caption = 'Banco';
                }
            }
            group(ProgramaGroup)
            {
                Caption = 'Programa';
                field("Programa por defecto"; Rec."Programa por defecto")
                {
                    ApplicationArea = All;
                    Caption = 'Programa por defecto';
                }
                field(ProgramaField; Rec.Programa)
                {
                    ApplicationArea = All;
                    Caption = 'Programa';
                }
                field(Departamento; Rec.Departamento)
                {
                    ApplicationArea = All;
                    Caption = 'Departamento';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Lista Configuraciones")
            {
                ApplicationArea = All;
                Image = List;
                RunObject = Page "Lista Configuración Nominas";
                ToolTip = 'Abre la lista de configuraciones de nóminas';
            }
            action("Rellenar Cuentas por Defecto")
            {
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Rellena automáticamente las cuentas con los valores habituales del plan contable español para nóminas';

                trigger OnAction()
                begin
                    if Confirm('¿Desea rellenar las cuentas con los valores por defecto del plan contable? Se sobrescribirán los valores actuales.', false) then begin
                        Rec.RellenarCuentasPorDefecto();
                        Message('Cuentas rellenadas con los valores por defecto del plan contable español.');
                    end;
                end;
            }
        }
    }
    var
        Cuenta: Boolean;
}


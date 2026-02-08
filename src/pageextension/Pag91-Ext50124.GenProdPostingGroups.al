/// <summary>
/// Extensión de la página Gen. Product Posting Groups: acción para borrar registros seleccionados y sus configuraciones.
/// </summary>
pageextension 50324 "Gen Prod Posting Groups PA" extends "Gen. Product Posting Groups"
{
    actions
    {
        addlast(processing)
        {
            action("Borrar seleccionados y configuraciones")
            {
                ApplicationArea = All;
                Caption = 'Borrar seleccionados y configuraciones';
                ToolTip = 'Borra todos los grupos de registro de producto seleccionados y sus configuraciones en Config. contabilidad general.';
                Image = Delete;
                Visible = PermitirBorrarGrupos;

                trigger OnAction()
                var
                    GenProdPostingGroup: Record "Gen. Product Posting Group";
                    EventosProyectos: Codeunit "Eventos-proyectos";
                    Count: Integer;
                begin
                    CurrPage.SetSelectionFilter(GenProdPostingGroup);
                    if not GenProdPostingGroup.FindFirst() then begin
                        Message(NoSeleccionMsg);
                        exit;
                    end;
                    if not Confirm(ConfirmarBorradoQst, false, GenProdPostingGroup.Count) then
                        exit;
                    Count := EventosProyectos.DeleteSelectedGenProdPostingGroupsWithSetup(GenProdPostingGroup);
                    Message(RegistrosBorradosMsg, Count);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        PermitirBorrarGrupos := GetPermitirBorrarGrupos();
    end;

    local procedure GetPermitirBorrarGrupos(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then
            exit(CompanyInformation."Permitir borrar grupos");
        exit(false);
    end;

    var
        PermitirBorrarGrupos: Boolean;
        NoSeleccionMsg: Label 'No hay ningún registro seleccionado.';
        ConfirmarBorradoQst: Label '¿Borrar %1 grupo(s) de registro de producto y sus configuraciones en Config. contabilidad general?';
        RegistrosBorradosMsg: Label 'Se han borrado %1 registro(s) y sus configuraciones.';
}

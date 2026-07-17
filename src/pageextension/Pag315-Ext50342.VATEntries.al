/// <summary>
/// Extiende Mov. IVA (VAT Entries) con columnas calculadas de tipo de operación y régimen.
/// </summary>
pageextension 50342 "VAT Entries Ext" extends "VAT Entries"
{
    layout
    {
        addlast(Control1)
        {
            field(TipoOperacion; TipoOperacionTxt)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tipo de Operación';
                Editable = false;
                ToolTip = 'Compra = IVA deducible; Venta = IVA Devengado.';
            }
            field(TipoOperacion2; TipoOperacion2Txt)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tipo de Operación2';
                Editable = false;
                ToolTip = 'Régimen: ISP, Operaciones no sujetas por reglas de localización, o Régimen General.';
            }
            field(ClausulaIVA; ClausulaIVATxt)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cláusula IVA';
                Editable = false;
                ToolTip = 'Código de cláusula IVA del documento origen.';
            }
            field(MotivoExencion; MotivoExencionTxt)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Motivo de exención';
                Editable = false;
                ToolTip = 'Código de exención SII de la cláusula IVA (E1, E2, E4...).';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ProcesosProyectos: Codeunit ProcesosProyectos;
    begin
        TipoOperacionTxt := ProcesosProyectos.CalcularTipoOperacion(Rec);
        TipoOperacion2Txt := ProcesosProyectos.CalcularRegimenOperacion(Rec, false);
        ClausulaIVATxt := ProcesosProyectos.ObtenerClausulaIVA(Rec);
        MotivoExencionTxt := ProcesosProyectos.ObtenerMotivoExencion(Rec);
    end;

    var
        TipoOperacionTxt: Text[50];
        TipoOperacion2Txt: Text[100];
        ClausulaIVATxt: Code[20];
        MotivoExencionTxt: Text[30];
}

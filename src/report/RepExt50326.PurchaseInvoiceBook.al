/// <summary>
/// Extiende Libro facturas recibidas (10705).
/// El detalle se imprime en el dataitem "Integer" hijo de VATEntry2;
/// los valores se calculan en OnAfterAfterGetRecord de VATEntry2.
/// </summary>
reportextension 50326 "Purchase Invoice Book Ext" extends "Purchases Invoice Book"
{
    dataset
    {
        modify(VATEntry2)
        {
            trigger OnAfterAfterGetRecord()
            var
                ProcesosProyectos: Codeunit ProcesosProyectos;
            begin
                ClausulaIVA := ProcesosProyectos.ObtenerClausulaIVA(VATEntry2);
                MotivoExencion := ProcesosProyectos.ObtenerMotivoExencion(VATEntry2);
                TipoOperacion2 := ProcesosProyectos.CalcularRegimenOperacion(VATEntry2, true);
            end;
        }

        add("Integer")
        {
            column(Clausula_IVA; ClausulaIVA)
            {
                Caption = 'Cláusula IVA';
            }
            column(Motivo_Exencion; MotivoExencion)
            {
                Caption = 'Motivo de exención';
            }
            column(Tipo_Operacion_2; TipoOperacion2)
            {
                Caption = 'Tipo de Operación2';
            }
        }

        modify("No Taxable Entry")
        {
            trigger OnAfterAfterGetRecord()
            var
                ProcesosProyectos: Codeunit ProcesosProyectos;
                VATEntryAux: Record "VAT Entry";
            begin
                Clear(VATEntryAux);
                VATEntryAux.Type := "No Taxable Entry".Type;
                VATEntryAux."Document No." := "No Taxable Entry"."Document No.";
                VATEntryAux."VAT Bus. Posting Group" := "No Taxable Entry"."VAT Bus. Posting Group";
                VATEntryAux."VAT Prod. Posting Group" := "No Taxable Entry"."VAT Prod. Posting Group";
                VATEntryAux."VAT Calculation Type" := "No Taxable Entry"."VAT Calculation Type";
                VATEntryAux."No Taxable Type" := "No Taxable Entry"."No Taxable Type";
                VATEntryAux."VAT %" := 0;
                VATEntryAux.Amount := 0;
                ClausulaIVANoTax := ProcesosProyectos.ObtenerClausulaIVA(VATEntryAux);
                MotivoExencionNoTax := ProcesosProyectos.ObtenerMotivoExencion(VATEntryAux);
                TipoOperacion2NoTax := ProcesosProyectos.CalcularRegimenOperacion(VATEntryAux, true);
            end;
        }

        add("No Taxable Entry")
        {
            column(Clausula_IVA_NoTax; ClausulaIVANoTax)
            {
                Caption = 'Cláusula IVA';
            }
            column(Motivo_Exencion_NoTax; MotivoExencionNoTax)
            {
                Caption = 'Motivo de exención';
            }
            column(Tipo_Operacion_2_NoTax; TipoOperacion2NoTax)
            {
                Caption = 'Tipo de Operación2';
            }
        }
    }

    var
        ClausulaIVA: Code[20];
        MotivoExencion: Text[30];
        TipoOperacion2: Text[100];
        ClausulaIVANoTax: Code[20];
        MotivoExencionNoTax: Text[30];
        TipoOperacion2NoTax: Text[100];
}

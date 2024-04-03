enum 50300 "Estado Proyecto"
{
    Extensible = true;

    value(0; "In Quote")
    {
        // Caption = 'En oferta';
        Caption = 'In Quote', comment = 'ESP="En oferta"';
    }
    value(1; "Awarded in execution")
    {
        Caption = 'Awarded in execution', comment = 'ESP="Adjudicado en ejecucion"';
    }
    value(2; "Awarded Finished")
    {
        Caption = 'Awarded Finished', comment = 'ESP="Adjudicado finalizado"';
    }
    value(3; "Awarded as a guarantee")
    {
        Caption = 'Awarded as a guarantee', comment = 'ESP="Adjudicado en garantía"';
    }
    value(4; "Not awarded")
    {
        Caption = 'Not awarded', comment = 'ESP="No adjudicado"';
    }
}

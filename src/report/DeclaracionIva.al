reportextension 50324 "Declaracion Iva" extends "VAT Statement"
{
    dataset
    {
        add("VAT Statement Line")
        {
            column(Casilla; "VAT Statement Line".Box)
            {
                IncludeCaption = true;
            }
        }

    }
}
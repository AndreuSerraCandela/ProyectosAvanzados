//Crear tabla de categorías
table 50112 Categorias
{
    LookupPageId = 50114;
    DrillDownPageId = 50114;

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; Description; Text[30])
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
// Crear page de categorías


/// <summary>
/// TableExtension LineasPlanificacion (ID 50100) extends Record Job Planning Line//1003.
/// </summary>
tableextension 50100 "LineasPlanificacion" extends "Job Planning Line"//1003
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Generar Compra"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Generar compras';
            trigger OnValidate()
            begin
                Rec."Usage Link" := true;
            end;
        }
        field(50001; Cod_Proveedor; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Cod_Proveedor';
            TableRelation = Vendor."No.";
            trigger OnValidate()
            var
                rVendedor: Record Vendor;
            begin
                if rVendedor.Get(Cod_Proveedor) then begin
                    rec.Nombre := rVendedor.Name;
                end;
            end;
        }
        field(50002; Nombre; Text[200])
        {
            // CalcFormula = exist(Vendor.Name where ("No."=field(Cod_Proveedor)));
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50007; QB; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }
        field(50003; "Cantidad a tr a Factura Compra"; Decimal)
        {
            Caption = 'Cantidad a tranferir a Factura Compra';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                if ("Cantidad a tr a Factura Compra" + "Cantidad en Factura Compra") > Quantity then
                    Error('solo se pueden tranferir %1 a factura compra', Quantity - "Cantidad en Factura Compra");
            end;
        }
        field(50004; "Cantidad en Pedido Compra"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }
        field(50005; "Cantidad en Factura Compra"; Decimal)
        {
            Editable = false;
            DecimalPlaces = 0 : 5;

        }
        field(50006; "Nº documento Compra"; Code[20])
        { }
        field(50010; "Cód Oferta Job"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(90001; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Cliente Facturación';
            TableRelation = "Customer";
        }
        field(90002; Categorias; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Categorias;
        }
        field(90003; "Importe Inicial Venta"; Decimal)
        {
            DataClassification = ToBeClassified;


        }
        field(90004; "Importe Inicial Coste"; Decimal)
        {
            DataClassification = ToBeClassified;
        }


    }


    var
        myInt: Integer;
}
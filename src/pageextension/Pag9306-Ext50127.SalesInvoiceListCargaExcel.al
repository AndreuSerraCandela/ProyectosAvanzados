/// <summary>
/// PageExtension Sales Invoice List: añade acción para cargar facturas desde Excel.
/// </summary>
pageextension 50328 "Sales Invoice List Carga Excel" extends "Sales Invoice List"
{
    actions
    {
        addfirst(Processing)
        {
            action(CargarFacturasDesdeExcel)
            {
                ApplicationArea = All;
                Caption = 'Cargar facturas desde Excel';
                ToolTip = 'Importa facturas desde un archivo Excel. Columnas: A=Fecha, B=Importe, C=% IVA, D=Importe IVA, E=Total, F=CIF cliente, G=Nombre, H=Texto registro, I=Cuenta contable, J=Nº factura, K=Proyecto';
                Image = ImportExcel;

                trigger OnAction()
                var
                    ProcesosProyectos: Codeunit ProcesosProyectos;
                begin
                    ProcesosProyectos.ImportarFacturasDesdeExcel();
                end;
            }
            // action("REegenerar Job Planing")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Regenerar Job Planing';
            //     ToolTip = 'Importa facturas desde un archivo Excel. Columnas: A=Fecha, B=Importe, C=% IVA, D=Importe IVA, E=Total, F=CIF cliente, G=Nombre, H=Texto registro, I=Cuenta contable, J=Nº factura, K=Proyecto';
            //     Image = ImportExcel;

            //     trigger OnAction()
            //     var
            //         SalesHeader: Record "Sales Header";
            //         SalesLine: Record "Sales Line";
            //         SalesLineTemp: Record "Sales Line" temporary;
            //         JobPlanningLine: Record "Job Planning Line";
            //         ProcesosProyectos: Codeunit ProcesosProyectos;
            //         LineNo: Integer;
            //         CreateInvoice: codeunit "Job Create-Invoice";
            //         ProyectoNo: Code[20];
            //     begin
            //         CurrPage.SetSelectionFilter(SalesHeader);
            //         if SalesHeader.FindFirst() then
            //             repeat
            //                 SalesHeader."Importar desde excel" := true;
            //                 SalesHeader.Modify();
            //                 jobplanningline.SetRange("Document No.", SalesHeader."No.");
            //                 jobplanningline.DeleteAll();
            //                 SalesLine.SetRange("Document No.", SalesHeader."No.");
            //                 if SalesLine.FindFirst() then
            //                     repeat


            //                         //Crear Jobline
            //                         JobPlanningLine.Reset();
            //                         JobPlanningLine.SetRange("Job No.", SalesLine."Job No.");
            //                         JobPlanningLine.SetRange("Job Task No.", SalesLine."Job Task No.");
            //                         If JobPlanningLine.FindLast() then
            //                             LineNo := JobPlanningLine."Line No." + 10000
            //                         else
            //                             LineNo := 10000;
            //                         JobPlanningLine.Init();
            //                         JobPlanningLine."Job No." := SalesLine."Job No.";
            //                         JobPlanningLine."Planning Date" := SalesHeader."Posting Date";
            //                         JobPlanningLine."Job Task No." := SalesLine."Job Task No.";
            //                         JobPlanningLine."Document No." := SalesHeader."No.";
            //                         JobPlanningLine."Line No." := LineNo;
            //                         JobPlanningLine.Description := SalesLine.Description;
            //                         JobPlanningLine.Quantity := 1;
            //                         JobPlanningLine.Type := JobPlanningLine.Type::Item;
            //                         JobPlanningLine."No." := SalesLine."No.";


            //                         JobPlanningLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
            //                         JobPlanningLine.Validate("Unit Price", SalesLine."Unit Price");
            //                         JobPlanningLine."Line Type" := JobPlanningLine."Line Type"::Billable;
            //                         JobPlanningLine."Contract Line" := true;
            //                         JobPlanningLine.Validate("Qty. to Transfer to Invoice", SalesLine.Quantity);
            //                         JobPlanningLine."Qty. to Transfer to Journal" := SalesLine.Quantity;


            //                         JobPlanningLine.Insert();
            //                         ProyectoNo := SalesLine."Job No.";
            //                         SalesLineTemp.TransferFields(SalesLine);
            //                         SalesLineTemp."Line No." := LineNo;
            //                         SalesLineTemp.Insert();
            //                     // OCrear Job Planning Line

            //                     until SalesLine.Next() = 0;
            //                 SalesLine.Deleteall;
            //                 JobPlanningLine.SetRange("Document No.", SalesHeader."No.");
            //                 If JobPlanningLine.FindFirst() then
            //                     repeat
            //                         CreateInvoice.CreateSalesInvoiceLines(ProyectoNo, JobPlanningLine, SalesHeader."No.", false, SalesHeader."Posting Date", SalesHeader."Posting Date", false);
            //                         Commit();
            //                         SalesLine.Reset();
            //                         SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            //                         SalesLine.SetRange("Document No.", SalesHeader."No.");

            //                         SalesLine.FindLast();
            //                         SalesLineTemp.Get(SalesLine."Document Type", SalesLine."Document No.", jobplanningline."Line No.");
            //                         // deberia buscar un grupo registro iva producto que en la configurtacion con el grupo viva negocio del cliente , tenga un PCTIV
            //                         SalesLine.Validate("VAT Prod. Posting Group", SalesLineTemp."VAT Prod. Posting Group");

            //                         SalesLine.Validate("VAT Prod. Posting Group", SalesLineTemp."VAT Prod. Posting Group");
            //                         // Cargar dimensiones: construir Dimension Set ID desde array Dimensiones (columnas L a R) y asignar a la línea
            //                         SalesLine."Gen. Bus. Posting Group" := SalesLineTemp."Gen. Bus. Posting Group";
            //                         SalesLine."Gen. Prod. Posting Group" := SalesLineTemp."Gen. Prod. Posting Group";
            //                         SalesLine.Validate("Dimension Set ID", SalesLineTemp."Dimension Set ID");
            //                         SalesLine."Gen. Bus. Posting Group" := SalesLineTemp."Gen. Bus. Posting Group";
            //                         SalesLine."Gen. Prod. Posting Group" := SalesLineTemp."Gen. Prod. Posting Group";

            //                         SalesLine.Modify();
            //                     until JobPlanningLine.Next() = 0;

            //             until SalesHeader.Next() = 0;
            //     end;
            // }
        }
    }
}

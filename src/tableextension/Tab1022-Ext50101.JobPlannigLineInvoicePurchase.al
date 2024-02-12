tableextension 50101 "JobPlannigLineInvoicePurchase" extends "Job Planning Line Invoice"//1022
{
    fields
    {

    }


    procedure InitFromPurchase(PurchaseHeader: Record "Purchase Header"; PostingDate: Date; LineNo: Integer)
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
            "Document Type" := "Document Type"::Invoice;
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            "Document Type" := "Document Type"::"Credit Memo";
        "Document No." := PurchaseHeader."No.";
        "Line No." := LineNo;
        "Transferred Date" := PostingDate
    end;

    var
        myInt: Integer;
}
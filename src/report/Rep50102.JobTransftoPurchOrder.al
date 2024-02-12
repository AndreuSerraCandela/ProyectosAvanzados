report 50102 "Job Transf.to Purch. Order"
{
    Caption = 'Job Transfer to Purcharse Order';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CreateNewInvoice; NewInvoice)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create New Order';
                        ToolTip = 'Specifies if the batch job creates a new Purcharse Order.';

                        trigger OnValidate()
                        begin
                            if NewInvoice then begin
                                InvoiceNo := '';
                                if PostingDate = 0D then
                                    PostingDate := WorkDate;
                                InvoicePostingDate := 0D;
                            end;
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                NewInvoice := false;
                        end;
                    }
                    field(AppendToPurcharseInvoiceNo; InvoiceNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Append to Purcharse Order No.';
                        ToolTip = 'Specifies the number of the Purcharse Order that you want to append the lines to if you did not select the Create New Purcharse Order field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(PurcharseHeader);
                            PurcharseHeader.FilterGroup := 2;
                            PurcharseHeader.SetRange(PurcharseHeader."Document Type", PurcharseHeader."Document Type"::Order);
                            PurcharseHeader.SetRange(PurcharseHeader."No. Proyecto", Job."No.");
                            //PurcharseHeader.SetRange("Bill-to Customer No.", Job."Bill-to Customer No.");
                            // Message('cambiar provedor');
                            PurcharseHeader.FilterGroup := 0;
                            if PAGE.RunModal(0, PurcharseHeader) = ACTION::LookupOK then
                                InvoiceNo := PurcharseHeader."No.";
                            if InvoiceNo <> '' then begin
                                PurcharseHeader.Get(PurcharseHeader."Document Type"::Order, InvoiceNo);
                                InvoicePostingDate := PurcharseHeader."Posting Date";
                                NewInvoice := false;
                                PostingDate := 0D;
                            end;
                            if InvoiceNo = '' then
                                InitReport;
                        end;

                        trigger OnValidate()
                        begin
                            if InvoiceNo <> '' then begin
                                PurcharseHeader.Get(PurcharseHeader."Document Type"::Order, InvoiceNo);
                                InvoicePostingDate := PurcharseHeader."Posting Date";
                                NewInvoice := false;
                                PostingDate := 0D;
                            end;
                            if InvoiceNo = '' then
                                InitReport;
                        end;
                    }
                    field(InvoicePostingDate; InvoicePostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Order Posting Date';
                        Editable = false;
                        ToolTip = 'Specifies, if you filled in the Append to Purcharse Order No. field, the posting date of the Order.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                NewInvoice := false;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitReport;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Done := false;
    end;

    trigger OnPostReport()
    begin
        Done := true;
    end;

    var
        Job: Record Job;
        PurcharseHeader: Record "Purchase Header";
        NewInvoice: Boolean;
        InvoiceNo: Code[20];
        PostingDate: Date;
        InvoicePostingDate: Date;
        Done: Boolean;

    procedure GetInvoiceNo(var Done2: Boolean; var NewInvoice2: Boolean; var PostingDate2: Date; var InvoiceNo2: Code[20])
    begin
        Done2 := Done;
        NewInvoice2 := NewInvoice;
        PostingDate2 := PostingDate;
        InvoiceNo2 := InvoiceNo;
    end;

    procedure InitReport()
    begin
        PostingDate := WorkDate;
        NewInvoice := true;
        InvoiceNo := '';
        InvoicePostingDate := 0D;
    end;

    procedure SetVendor(JobNo: Code[20])
    begin
        Job.Get(JobNo);
    end;
}


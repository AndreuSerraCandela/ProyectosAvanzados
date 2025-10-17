report 50203 "Job Transf.to Purch. Quote"
{
    Caption = 'Job Transfer to Purcharse Quote';
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
                        Caption = 'Crear Nueva Oferta';
                        //  Caption = 'Create New Quote', comment = 'ESP="Crear Nueva Oferta"';
                        ToolTip = 'Specifies if the batch job creates a new Purcharse Quote.';

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
                        Caption = 'Fecha Registro';
                        //Caption = 'Posting Date', comment = 'ESP="Fecha Registro"';
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
                        Caption = 'Anexar en Oferta Compra';
                        //Caption = 'Append to Purcharse Quote No.', comment = 'ESP="Anexar en Oferta Compra"';
                        ToolTip = 'Specifies the number of the Purcharse Quote that you want to append the lines to if you did not select the Create New Purcharse Quote field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(PurcharseHeader);
                            PurcharseHeader.FilterGroup := 2;
                            PurcharseHeader.SetRange(PurcharseHeader."Document Type", PurcharseHeader."Document Type"::Quote);
                            PurcharseHeader.SetRange(PurcharseHeader."No. Proyecto", Job."No.");
                            //PurcharseHeader.SetRange("Bill-to Customer No.", Job."Bill-to Customer No.");
                            // Message('cambiar provedor');
                            PurcharseHeader.FilterGroup := 0;
                            if PAGE.RunModal(0, PurcharseHeader) = ACTION::LookupOK then
                                InvoiceNo := PurcharseHeader."No.";
                            if InvoiceNo <> '' then begin
                                PurcharseHeader.Get(PurcharseHeader."Document Type"::Quote, InvoiceNo);
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
                                PurcharseHeader.Get(PurcharseHeader."Document Type"::Quote, InvoiceNo);
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
                        Caption = 'Oferta Fecha Registro';
                        //Caption = 'Quote Posting Date', comment = 'ESP="Oferta Fecha Registro"';
                        Editable = false;
                        ToolTip = 'Specifies, if you filled in the Append to Purcharse Quote No. field, the posting date of the Quote.';

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


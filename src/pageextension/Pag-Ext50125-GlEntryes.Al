/// <summary>
/// PageExtension GlEntries (ID 80133) extends Record General Ledger Entries.
/// </summary>
pageextension 50125 GlEntriesUt extends "General Ledger Entries"
{




    actions
    {


        addafter(ReverseTransaction)
        {

            group(Anular)
            {
                Image = Undo;
                action("Anular Asiento")
                {
                    ApplicationArea = all;
                    Scope = Repeater;
                    Image = DeleteRow;
                    trigger OnAction()
                    var
                        Cancel: Codeunit "Cancel Entries";
                        Text90000: Label '¿Confirma que desea anular el asiento ?';
                        Text90001: Label '¿Generar un nuevo asiento?';
                        Text90002: Label 'La fecha de contabilización está fuera del rango de fechas';
                        Text90003: Label 'No se puede anular un asiento anterior a un cierre';
                        Text90004: Label 'Compresión de datos previa \';
                        Text90005: Label 'efectuada para esa fecha.';
                        Text90006: Label 'GENERAL';
                        Text90007: Label 'ANULACION';
                        Text90008: Label 'Anulaciones';
                        Text90009: Label 'Este movimiento está relacionado con un mov. IVA\';
                        Text90010: Label 'que se encuentra cerrado.';
                        Text90011: Label 'Este movimiento está relacionado con un documento\';
                        Text90012: Label 'que está incluido en una remesa.';
                        Text90013: Label 'Este movimiento está relacionado con un mov. Cliente\';
                        Text90014: Label 'que ya está liquidado.';
                        Text90015: Label 'Este movimiento está relacionado con un mov. Proveedor\';
                        Text90016: Label 'Este movimiento está relacionado con un mov. IVA.\';
                        Text90017: Label 'No puede generarse el nuevo asiento.';
                        Text90018: Label 'Este movimiento está relacinado con un mov. Banco\';
                        Text90019: Label 'Este movimiento está relacinado con un mov. Cheque\';
                        Text90020: Label 'Este movimiento está relacinado con un documento\';
                        Text90021: Label 'que se encuentra está liquidado.';
                        Text90022: Label 'que se encuentra remesado.';
                        Text90023: Label 'Este asiento no se puede anular porque todas sus líneas estan marcadas como "Asiento Automático".';
                        Text10001: Label 'No puede anular el asiento, ya que el número de asiento no coincide en el mov %1';
                        MovContabilidad: Record "G/L Entry";
                        ConfUsuario: Record "User Setup";
                        FechaDesde: Date;
                        FechaHasta: Date;
                        CrearAsiento: Boolean;
                        ConfContabilidad: Record 98;
                        PeriodoContable: Record "Accounting Period";
                        Asi: Record 45;
                    begin
                        Asi.GET(Rec."Transaction No.");
                        IF NOT CONFIRM(Text90000, FALSE) THEN
                            EXIT;
                        // Compruebo integridad de datos
                        MovContabilidad.SETRANGE("Entry No.", Asi."From Entry No.", Asi."To Entry No.");
                        MovContabilidad.FINDFIRST;
                        REPEAT
                            IF Asi."No." <> MovContabilidad."Transaction No." THEN
                                ERROR(Text10001, MovContabilidad."Entry No.");
                        UNTIL MovContabilidad.NEXT = 0;
                        CrearAsiento := CONFIRM(Text90001);

                        IF USERID <> '' THEN
                            IF ConfUsuario.GET(USERID) THEN BEGIN
                                FechaDesde := ConfUsuario."Allow Posting From";
                                FechaHasta := ConfUsuario."Allow Posting To";
                            END;
                        IF (FechaDesde = 0D) AND (FechaHasta = 0D) THEN BEGIN
                            ConfContabilidad.GET;
                            FechaDesde := ConfContabilidad."Allow Posting From";
                            FechaHasta := ConfContabilidad."Allow Posting To";
                        END;
                        IF FechaHasta = 0D THEN
                            FechaHasta := 99991231D;

                        IF (Rec."Posting Date" < FechaDesde) OR (Rec."Posting Date" > FechaHasta) THEN
                            ERROR(Text90002);

                        PeriodoContable.SETFILTER("Starting Date", '>=%1', Rec."Posting Date");
                        PeriodoContable.SETRANGE(Closed, TRUE);
                        IF PeriodoContable.FIND THEN ERROR(Text90003);

                        // HistCompFechas.SETFILTER("Ending Date",'>=%1',"Posting Date");
                        // IF HistCompFechas.FIND('-') THEN
                        // ERROR(Text90004+
                        //         Text90005);
                        Cancel.AnulaAsiento(Asi, CrearAsiento);
                    End;

                }
                action("Desmarcar Automático")
                {
                    Image = AddWatch;
                    ApplicationArea = all;
                    Scope = Repeater;
                    trigger OnAction()
                    var
                        C: Codeunit "Cancel Entries";
                        Asi: Record 45;
                    begin
                        Asi.GET(Rec."Transaction No.");
                        C.DesMacarAutomatico(Asi);

                    end;
                }

            }





        }
    }

    VAR
        GLAcc: Record 15;
        Navigate: Page 344;
        Text000: Label 'Cliente,Proveedor';
        FPR: Text;
        DESGLO: Text;
        ExisteMov: Text;
        ImporteCompraStyle: Text;
        VariasEmpresas: Boolean;




}
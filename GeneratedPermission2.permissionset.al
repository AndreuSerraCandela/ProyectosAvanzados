permissionset 50100 GeneratedPermission2
{
    Assignable = true;
    Permissions = tabledata Categorias = RIMD,
        tabledata "Dependecias de Tareas" = RIMD,
        tabledata "Hist. Job Planning Line" = RIMD,
        tabledata "Job Status History" = RIMD,
        tabledata "Naturaleza Contable" = RIMD,
        table Categorias = X,
        table "Dependecias de Tareas" = X,
        table "Hist. Job Planning Line" = X,
        table "Job Status History" = X,
        table "Naturaleza Contable" = X,
        report "Job Transf Credit Memo Purch" = X,
        report "Job Transf.to Purch. Invoice" = X,
        report "Job Transf.to Purch. Order" = X,
        report "Job Transf.to Purch. Quote" = X,
        codeunit "Eventos-proyectos" = X,
        codeunit ProcesosProyectos = X,
        page "Categorías" = X,
        page "Comparativo Ofertas" = X,
        page "Dependencias de Tareas" = X,
        page DialogoEstimacion = X,
        page "Hist. Job planning line" = X,
        page "Job Status History" = X,
        page "Job Task Lines Subform Ext" = X,
        page "Pendiente facturar" = X;

}
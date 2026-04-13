[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Consulta_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Consulta = let
  Origen = SharePoint.Files("https://urbexpress.sharepoint.com/sites/GRANDESCLIENTES", [ApiVersion = 15]),
  Navegación = Origen{[Name = "ESQUELETO OK - MELI hasta feb (4).xlsx", #"Folder Path" = "https://urbexpress.sharepoint.com/sites/GRANDESCLIENTES/Documentos compartidos/ESQUELETO OK MELI MLP/"]}[Content],
  #"Libro de Excel importado" = Excel.Workbook(Navegación, null, true),
  #"Navegación 1" = #"Libro de Excel importado"{[Item = "Hoja1", Kind = "Sheet"]}[Data],
  #"Encabezados promovidos" = Table.PromoteHeaders(#"Navegación 1", [PromoteAllScalars = true]),
  #"Tipo de columna cambiado" = Table.TransformColumnTypes(#"Encabezados promovidos", {{"Mes", type text}, {"Año", Int64.Type}, {"Sucursal", type text}, {"Líder regional", type text}, {"TOTAL Q de paquetes  que pasan por la sucu", Int64.Type}, {"Q de paquetes rodados desde la sucursal", Int64.Type}, {"q sorting", Int64.Type}, {"Q  viajes", Int64.Type}, {"Promedio PQ x Recorrido", type number}, {"Q de MM", Int64.Type}, {"Facturación CARGA/DESCARGA", type number}, {"Facturación RUEDAS", type number}, {"Facturación MEDIA MILLA", type number}, {"Precio CARGA/DESCARGA y SORTING", type number}, {"Precio por RUEDAS", type number}, {"Precio x MEDIA MILLA", type number}, {"TOTAL FAC", type number}, {"Column20", type number}}, "es"),
  #"Elegir columnas" = Table.SelectColumns(#"Tipo de columna cambiado", {"Mes", "Año", "Sucursal", "Líder regional", "TOTAL Q de paquetes  que pasan por la sucu", "Q de paquetes rodados desde la sucursal", "q sorting", "Q  viajes", "Promedio PQ x Recorrido", "Q de MM", "Facturación CARGA/DESCARGA", "Facturación RUEDAS", "Facturación MEDIA MILLA", "Precio CARGA/DESCARGA y SORTING", "Precio por RUEDAS", "Precio x MEDIA MILLA", "TOTAL FAC"}),
  #"Filas filtradas" = Table.SelectRows(#"Elegir columnas", each ([Mes] <> null))
in
  #"Filas filtradas";
shared Consulta_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = null]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "38153748-4605-4aa9-96d5-c848565db7d9"]}[Data],
  TableNavigation = Navigation_2{[Id = "gd_mlp_meli", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;

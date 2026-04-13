[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "br_nexus_treggo_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared br_nexus_treggo = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "br_nexus_treggo", ItemKind = "Table"]}[Data],
  #"Filas filtradas" = Table.SelectRows(#"Navegación 2", each [FECHA] > #date(2026, 1, 1)),
  #"Filas filtradas 1" = Table.SelectRows(#"Filas filtradas", each [Q SHP] >= 1),
  #"Personalizado agregado" = Table.AddColumn(#"Filas filtradas 1", "No Visitados", each [Q SHP] - (Number.Round([#"% Visitados"] * [Q SHP]))),
  #"Tipo de columna cambiado" = Table.TransformColumnTypes(#"Personalizado agregado", {{"No Visitados", Int64.Type}}),
  #"Elegir columnas" = Table.SelectColumns(#"Tipo de columna cambiado", {"FECHA", "SUBCA", "PATENTE", "Location", "TURNO_DESPACHO", "TIPO_VEHICULO", "Q SHP", "Ambulancias", "Delivery Success", "No Visitados"}),
  #"Consultas combinadas" = Table.NestedJoin(#"Elegir columnas", {"PATENTE"}, br_choferes_rrhh, {"patente"}, "br_choferes_rrhh", JoinKind.LeftOuter),
  #"br_choferes_rrhh expandido" = Table.ExpandTableColumn(#"Consultas combinadas", "br_choferes_rrhh", {"legajo_nro", "empresa", "apellido_y_nombre", "descripcion"}, {"legajo_nro", "empresa", "apellido_y_nombre", "descripcion"}),
  #"Consultas combinadas 1" = Table.NestedJoin(#"br_choferes_rrhh expandido", {"SUBCA"}, br_sucursales_carritos, {"SVC"}, "br_sucursales_carritos", JoinKind.LeftOuter),
  #"br_sucursales_carritos expandido" = Table.ExpandTableColumn(#"Consultas combinadas 1", "br_sucursales_carritos", {"SUCURSAL"}, {"SUCURSAL"}),
  #"Personalizado agregado 1" = Table.AddColumn(#"br_sucursales_carritos expandido", "Modalidad", each "CARRITOS"),
  #"Tipo de columna cambiado 1" = Table.TransformColumnTypes(#"Personalizado agregado 1", {{"Modalidad", type text}}),
  #"Personalizado agregado 2" = Table.AddColumn(#"Tipo de columna cambiado 1", "id_presente", each (if[legajo_nro] = null then "SIN LEGAJO" else [legajo_nro]) & "_" &
Date.ToText([FECHA], "yyyyMMdd") & "_CARRITOS_ " & [SUCURSAL]),
  #"Tipo de columna cambiado 2" = Table.TransformColumnTypes(#"Personalizado agregado 2", {{"id_presente", type text}})
in
  #"Tipo de columna cambiado 2";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "br_meli_reporte_operaciones_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared br_meli_reporte_operaciones = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "br_meli_reporte_operaciones", ItemKind = "Table"]}[Data],
  #"Filas filtradas" = Table.SelectRows(#"Navegación 2", each [Fecha] > #date(2026, 1, 1)),
  #"Valor reemplazado" = Table.ReplaceValue(#"Filas filtradas", null, "AM", Replacer.ReplaceValue, {"TURNO_DESPACHO"}),
  #"Consultas combinadas" = Table.NestedJoin(#"Valor reemplazado", {"Patente"}, #"Sucursal por Patente", {"PATENTE"}, "Sucursal por Patente", JoinKind.LeftOuter),
  #"Sucursal por Patente expandido" = Table.ExpandTableColumn(#"Consultas combinadas", "Sucursal por Patente", {"SUCURSAL"}, {"SUCURSAL"}),
  #"Elegir columnas" = Table.SelectColumns(#"Sucursal por Patente expandido", {"Fecha", "Id de la ruta", "Nombre del transportista", "Vehículo", "Patente", "Kilómetros recorridos", "Ciclo", "Envíos despachados", "Envíos entregados", "Entrega exitosa", "No visitado", "ORH _Horas en ruta_", "SPORH _Número de paquetes despachados por hora_", "DPPH _Número de paquetes entregados por hora_", "TURNO_DESPACHO", "AMBULANCIA", "SUCURSAL"}),
  #"Elegir columnas 1" = Table.SelectColumns(#"Elegir columnas", {"Fecha", "Id de la ruta", "Nombre del transportista", "Vehículo", "Patente", "Kilómetros recorridos", "Ciclo", "Envíos despachados", "Envíos entregados", "Entrega exitosa", "No visitado", "TURNO_DESPACHO", "AMBULANCIA", "SUCURSAL"}),
  #"Columna condicional insertada" = Table.AddColumn(#"Elegir columnas 1", "Zona", each if [Kilómetros recorridos] <= 50 then 1 else if [Kilómetros recorridos] <= 100 then 2 else if [Kilómetros recorridos] <= 150 then 3 else if [Kilómetros recorridos] <= 200 then 4 else if [Kilómetros recorridos] <= 250 then 5 else 6),
  #"Tipo de columna cambiado" = Table.TransformColumnTypes(#"Columna condicional insertada", {{"Zona", Int64.Type}}),
  #"Consultas combinadas 1" = Table.NestedJoin(#"Tipo de columna cambiado", {"Patente"}, br_choferes_rrhh, {"patente"}, "br_choferes_rrhh", JoinKind.LeftOuter),
  #"br_choferes_rrhh expandido" = Table.ExpandTableColumn(#"Consultas combinadas 1", "br_choferes_rrhh", {"empresa", "legajo_nro"}, {"empresa", "legajo"}),
  #"Dividir columna por posición" = Table.SplitColumn(#"br_choferes_rrhh expandido", "TURNO_DESPACHO", Splitter.SplitTextByRepeatedLengths(2), {"TURNO_DESPACHO.1", "TURNO_DESPACHO.2"}),
  #"Elegir columnas 2" = Table.SelectColumns(#"Dividir columna por posición", {"Fecha", "Id de la ruta", "Nombre del transportista", "Vehículo", "Patente", "Kilómetros recorridos", "Ciclo", "Envíos despachados", "Envíos entregados", "Entrega exitosa", "No visitado", "TURNO_DESPACHO.1", "AMBULANCIA", "SUCURSAL", "Zona", "empresa", "legajo"}),
  #"Columnas con nombre cambiado" = Table.RenameColumns(#"Elegir columnas 2", {{"TURNO_DESPACHO.1", "TURNO_DESPACHO"}}),
  #"Filas filtradas 1" = Table.SelectRows(#"Columnas con nombre cambiado", each ([Envíos despachados] <> 0)),
  #"Valor reemplazado 1" = Table.ReplaceValue(#"Filas filtradas 1", null, "NORMAL", Replacer.ReplaceValue, {"AMBULANCIA"})
in
  #"Valor reemplazado 1";
shared br_sucursales_carritos = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "br_sucursales_carritos", ItemKind = "Table"]}[Data]
in
  #"Navegación 2";
shared br_choferes_rrhh = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "br_choferes_rrhh", ItemKind = "Table"]}[Data]
in
  #"Navegación 2";
shared #"Sucursal por Patente" = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "br_nexus_treggo", ItemKind = "Table"]}[Data],
  #"Filas filtradas" = Table.SelectRows(#"Navegación 2", each [FECHA] > #date(2026, 1, 1)),
  #"Filas filtradas 1" = Table.SelectRows(#"Filas filtradas", each [Q SHP] >= 1),
  #"Consultas combinadas" = Table.NestedJoin(#"Filas filtradas 1", {"SUBCA"}, br_sucursales_carritos, {"SVC"}, "br_sucursales_carritos", JoinKind.LeftOuter),
  #"br_sucursales_carritos expandido" = Table.ExpandTableColumn(#"Consultas combinadas", "br_sucursales_carritos", {"SUCURSAL"}, {"SUCURSAL"}),
  #"Elegir columnas" = Table.SelectColumns(#"br_sucursales_carritos expandido", {"FECHA", "PATENTE", "SUCURSAL"}),
  #"Duplicados quitados" = Table.Distinct(#"Elegir columnas", {"FECHA", "PATENTE", "SUCURSAL"}),
  #"Filas agrupadas" = Table.Group(#"Duplicados quitados", {"PATENTE", "SUCURSAL"}, {{"Cant", each Table.RowCount(_), Int64.Type}}),
  #"Ordenado" = Table.Sort(#"Filas agrupadas", {{"PATENTE", Order.Ascending}, {"Cant", Order.Descending}}),
  #"Buffer" = Table.Buffer(#"Ordenado"),
  #"Mayor por patente" = Table.Distinct(#"Buffer", {"PATENTE"}),
  #"Duplicados quitados 1" = Table.Distinct(#"Mayor por patente", {"PATENTE"})
in
  #"Duplicados quitados 1";
shared br_nexus_treggo_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = null]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "de58382b-a674-4669-a425-d536299ea5ea"]}[Data],
  TableNavigation = Navigation_2{[Id = "sl_presentes_carritos", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared br_meli_reporte_operaciones_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = null]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "de58382b-a674-4669-a425-d536299ea5ea"]}[Data],
  TableNavigation = Navigation_2{[Id = "sl_meli_reporte_operaciones", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;

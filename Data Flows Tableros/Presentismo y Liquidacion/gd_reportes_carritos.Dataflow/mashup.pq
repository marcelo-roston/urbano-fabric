[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "sl_meli_reporte_operaciones_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared sl_meli_reporte_operaciones = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "de58382b-a674-4669-a425-d536299ea5ea"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "sl_meli_reporte_operaciones", ItemKind = "Table"]}[Data],
  #"Consultas combinadas" = Table.NestedJoin(#"Navegación 2", {"SUCURSAL"}, br_tarifario_carritos, {"Sucursal"}, "br_tarifario_carritos", JoinKind.LeftOuter),
  #"br_tarifario_carritos expandido" = Table.ExpandTableColumn(#"Consultas combinadas", "br_tarifario_carritos", {"Zona", "CORTA", "Vigencia", "Fin", "LARGA", "MOTO", "Turno Despacho", "Chasis 8 Pos_", "Chasis 10 Pos_"}, {"Zona.1", "CORTA", "Vigencia", "Fin", "LARGA", "MOTO", "Turno Despacho", "Chasis 8 Pos_", "Chasis 10 Pos_"}),
  #"Personalizado agregado" = Table.AddColumn(#"br_tarifario_carritos expandido", "ValidaZona", each [Zona.1] = [Zona] or [Zona.1] = 0),
  #"Filas filtradas" = Table.SelectRows(#"Personalizado agregado", each ([ValidaZona] = true)),
  #"Personalizado agregado 1" = Table.AddColumn(#"Filas filtradas", "ValidaFecha", each [Fecha] >= [Vigencia] and 
([Fin] = null or [Fecha] <= [Fin])),
  #"Filas filtradas 1" = Table.SelectRows(#"Personalizado agregado 1", each ([ValidaFecha] = true)),
  #"Personalizado agregado 2" = Table.AddColumn(#"Filas filtradas 1", "ValidaTurno", each [Turno Despacho] = null or [Turno Despacho] = [TURNO_DESPACHO]),
  #"Filas filtradas 2" = Table.SelectRows(#"Personalizado agregado 2", each ([ValidaTurno] = true)),
  #"Personalizado agregado 4" = Table.AddColumn(#"Filas filtradas 2", "Baja Performance", each if [No visitado] = null then 0 else
if [No visitado] > 10 then 1 else 0),
  #"Tipo de columna cambiado 2" = Table.TransformColumnTypes(#"Personalizado agregado 4", {{"Baja Performance", Int64.Type}}),
  #"Personalizado agregado 3" = Table.AddColumn(#"Tipo de columna cambiado 2", "Pagable", each if([AMBULANCIA] = "AMBULANCIA") or 
[Baja Performance] = 1
then "NO" else "SI"),
  #"Tipo de columna cambiado 1" = Table.TransformColumnTypes(#"Personalizado agregado 3", {{"Pagable", type text}}),
  #"Columna condicional insertada" = Table.AddColumn(#"Tipo de columna cambiado 1", "Valida_Tarifa", each if [Pagable] = "NO" then 0 else if [Vehículo] = "FIORINO" then [CORTA] else if [Vehículo] = "MOTO" then [MOTO] else if [Vehículo] = "CHASIS 8" then [Chasis 8 Pos_] else if [Vehículo] = "CHASIS 10" then [Chasis 10 Pos_] else [LARGA]),
  #"Tipo de columna cambiado" = Table.TransformColumnTypes(#"Columna condicional insertada", {{"Valida_Tarifa", type number}}),
  #"Elegir columnas" = Table.SelectColumns(#"Tipo de columna cambiado", {"Fecha", "Id de la ruta", "Nombre del transportista", "Vehículo", "Patente", "Kilómetros recorridos", "Ciclo", "Envíos despachados", "Envíos entregados", "Entrega exitosa", "No visitado", "SUCURSAL", "Zona", "empresa", "AMBULANCIA", "TURNO_DESPACHO", "legajo", "Baja Performance", "Pagable", "Valida_Tarifa"}),
  #"Columnas con nombre cambiado" = Table.RenameColumns(#"Elegir columnas", {{"Nombre del transportista", "Chofer"}, {"TURNO_DESPACHO", "Turno"}, {"SUCURSAL", "Sucursal"}, {"empresa", "Empresa"}, {"Valida_Tarifa", "Importe"}, {"Envíos despachados", "PQ"}, {"Envíos entregados", "Entregas"}}),
  #"Personalizado agregado 5" = Table.AddColumn(#"Columnas con nombre cambiado", "No Visitados", each Number.Round([No visitado] * [PQ] / 100)),
  #"Tipo de columna cambiado 3" = Table.TransformColumnTypes(#"Personalizado agregado 5", {{"No Visitados", Int64.Type}}),
  #"Elegir columnas 1" = Table.SelectColumns(#"Tipo de columna cambiado 3", {"Fecha", "Id de la ruta", "Chofer", "Vehículo", "Patente", "Kilómetros recorridos", "Ciclo", "PQ", "Entregas", "Sucursal", "Zona", "Empresa", "AMBULANCIA", "Turno", "legajo", "Baja Performance", "Pagable", "Importe", "No Visitados"}),
  #"Columnas reordenadas" = Table.ReorderColumns(#"Elegir columnas 1", {"Fecha", "Id de la ruta", "Chofer", "Vehículo", "Patente", "Kilómetros recorridos", "Ciclo", "PQ", "Entregas", "No Visitados", "Sucursal", "Zona", "Empresa", "AMBULANCIA", "Turno", "Baja Performance", "Pagable", "Importe"}),
  #"Duplicados quitados" = Table.Distinct(#"Columnas reordenadas", {"Id de la ruta", "Chofer", "Entregas"})
in
  #"Duplicados quitados";
shared br_tarifario_carritos = let
  Origen = Lakehouse.Contents(null),
  Navegación = Origen{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  #"Navegación 1" = Navegación{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  #"Navegación 2" = #"Navegación 1"{[Id = "br_tarifario_carritos", ItemKind = "Table"]}[Data],
  #"Tipo de columna cambiado" = Table.TransformColumnTypes(#"Navegación 2", {{"Zona", Int64.Type}}),
  #"Columna duplicada" = Table.DuplicateColumn(#"Tipo de columna cambiado", "Sucursal", "Sucursal - Copia"),
  #"Columnas con nombre cambiado 1" = Table.RenameColumns(#"Columna duplicada", {{"Sucursal - Copia", "Turno Despacho"}}),
  #"Texto entre delimitadores extraído" = Table.TransformColumns(#"Columnas con nombre cambiado 1", {{"Turno Despacho", each Text.BetweenDelimiters(_, "(", ")", 0, 0), type text}}),
  #"Texto recortado" = Table.TransformColumns(#"Texto entre delimitadores extraído", {{"Turno Despacho", each Text.Trim(_), type text}}),
  #"Valor reemplazado" = Table.ReplaceValue(#"Texto recortado", "", null, Replacer.ReplaceValue, {"Turno Despacho"}),
  #"Texto recortado 1" = Table.TransformColumns(#"Valor reemplazado", {{"Sucursal", each Text.Trim(_), type nullable text}}),
  #"Primeros caracteres extraídos" = Table.TransformColumns(#"Texto recortado 1", {{"Sucursal", each Text.Start(_, 3), type text}})
in
  #"Primeros caracteres extraídos";
shared sl_meli_reporte_operaciones_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = null]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "38153748-4605-4aa9-96d5-c848565db7d9"]}[Data],
  TableNavigation = Navigation_2{[Id = "gd_carritos_liquidacion", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;

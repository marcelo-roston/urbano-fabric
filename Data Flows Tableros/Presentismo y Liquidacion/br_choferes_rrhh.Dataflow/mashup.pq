[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Choferes_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Choferes = let
  Origen = Odbc.Query("dsn=Informix_REP;Database=Estadistica", "SELECT #(lf)    legajo_nro, #(lf)    empresa, #(lf)    apellido_y_nombre, #(lf)    ref_estado, #(lf)    sucursal, #(lf)    descripcion, #(lf)    patente, #(lf)    fecha_ingreso#(lf)FROM (#(lf)    SELECT #(lf)        l.legajo_nro, #(lf)        l.empresa, #(lf)        l.apellido_y_nombre, #(lf)        l.ref_estado, #(lf)        ll.sucursal, #(lf)        tv.descripcion, #(lf)#(lf)        -- Normalizo patente#(lf)        NULLIF(TRIM(ll.patente), '') AS patente, #(lf)#(lf)        l.fecha_ingreso,#(lf)#(lf)        ROW_NUMBER() OVER(#(lf)            PARTITION BY l.legajo_nro#(lf)            ORDER BY #(lf)                -- 1. Activo primero#(lf)                CASE WHEN l.ref_estado = 'AC' THEN 1 ELSE 2 END,#(lf)#(lf)                -- 2. Que tenga patente#(lf)                CASE #(lf)                    WHEN NULLIF(TRIM(ll.patente), '') IS NOT NULL THEN 1 #(lf)                    ELSE 2 #(lf)                END,#(lf)#(lf)                -- 3. Más nuevo#(lf)                l.id_legajo DESC#(lf)        ) AS rn#(lf)#(lf)    FROM rrhh:legajo l#(lf)    LEFT JOIN rrhh:legajo_laborales ll #(lf)        ON ll.id_legajo = l.id_legajo#(lf)    LEFT JOIN urbano21:tipo_vehiculo tv #(lf)        ON tv.id_tipo_vehiculo = ll.id_vehiculo#(lf)#(lf)    WHERE l.id_legajo NOT IN (109693, 100162)#(lf)) t#(lf)WHERE rn = 1#(lf)AND legajo_nro LIKE 'P%';"),
  #"Texto recortado" = Table.TransformColumns(Origen, {{"patente", each Text.Trim(_), type nullable text}}),
  #"Texto en mayúsculas" = Table.TransformColumns(#"Texto recortado", {{"patente", each Text.Upper(_), type nullable text}}),
  #"Filas filtradas" = Table.SelectRows(#"Texto en mayúsculas", each ([empresa] <> "URBANO"))
in
  #"Filas filtradas";
shared Choferes_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = null]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "5f494725-23eb-48a8-8688-a8040411bb33"]}[Data],
  TableNavigation = Navigation_2{[Id = "br_choferes_rrhh", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;

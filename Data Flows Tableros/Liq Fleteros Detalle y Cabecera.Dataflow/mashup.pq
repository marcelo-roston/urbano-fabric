[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Cabecera_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Cabecera = let
  Origen = Odbc.Query("dsn=Informix_REP;Database=Estadistica", "select #(lf)prov_codigo, fecha_caratula, legajo_nro, apellido_y_nombre, tipo_empleado, empresa, max(tipo_vehiculo) as tipo_vehiculo,#(lf)sum(cant_piezas) as cant_piezas, sum(entregadas) as entregadas, sum(tot_ent) as tot_ent, sum(devueltas) as devueltas, sum(tot_dev)as tot_dev, sum(sin_tramitar)as sin_tramitar, #(lf)sum(cant_paqueteria) as cant_paqueteria, sum(paq_entregado) as paq_entregado, sum(paq_devuelto) as paq_devuelto, sum(paq_ca) as paq_ca, sum(paq_sintramitar) as paq_sintramitar, #(lf)sum(cant_masivo) +sum(cant_valorado) as cant_postal, sum(pos_entregado) as pos_entregado, sum(pos_devuelto) as pos_devuelto, #(lf)sum(pos_ca) as pos_ca, sum(pos_sintramitar) as pos_sintramitar, sum(tot_logi) as tot_logi, sum(tot_post) as tot_post, sum(tot_liqui) as tot_liqui, avg(productividad) as productividad, max(zona_max) as zona_max,#(lf)sum(tot_zona) as tot_zona, sum(peaje) as peaje, sum(tot_pagado) as tot_pagado, max(min_pagar) as min_pagar, max(cal_min) as cal_min, sum(tot_a_pagar) as tot_a_pagar, sum(tot_ba) as tot_ba, sum(fuera_rango_ca) as fuera_rango_ca#(lf)from liq_fletero_cabecera #(lf)where tipo_empleado in ('P10', 'P20') #(lf)and fecha_caratula >='01-11-2025'#(lf)and estado_caratula = 'Cerrada'#(lf)and empresa not in ('COLABORADOR', 'EMPLEADO', 'URBANO', '')#(lf)and prov_codigo not in ('OE2', 'CAP')#(lf)group by prov_codigo, fecha_caratula, legajo_nro, apellido_y_nombre, tipo_empleado, empresa#(lf)having#(lf)(#(lf)#(lf)     max(tipo_vehiculo) NOT LIKE 'CHASIS%'#(lf))#(lf)OR#(lf)(#(lf)     max(tipo_vehiculo) LIKE 'CHASIS%'#(lf)     AND fecha_caratula >= '01-11-2025'#(lf)     AND max(cal_min) = 'SE'#(lf))"),
  #"Personalizado agregado" = Table.AddColumn(Origen, "ID Viaje", each [legajo_nro] & [prov_codigo] & Date.ToText([fecha_caratula], "yyyyMMdd")),
  #"Tipo de columna cambiado" = Table.TransformColumnTypes(#"Personalizado agregado", {{"ID Viaje", type text}})
in

  #"Tipo de columna cambiado";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Detalle_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Detalle = let
    Origen =
        Odbc.Query("dsn=Informix_REP;Database=Estadistica", "    select #(lf)        prov_codigo, nro_caratula, legajo_nro, fecha_caratula, #(lf)        id_producto, id_shipper, farma, codigo_postal, zona, chk_codigo, #(lf)        tarifa_base, peso_utiliza, costo_paq, p_pagado, bultos * peso_utiliza as peso_total#(lf)    from liq_fletero_detalle#(lf)    where tipo_empleado in ('P10', 'P20') #(lf)      and fecha_caratula >= '01-11-2025'#(lf)      and estado_caratula = 'Cerrada'#(lf)      and empresa not in ('COLABORADOR', 'EMPLEADO', 'URBANO', '')#(lf)      and prov_codigo not in ('OE2', 'CAP')#(lf)"),
  #"Personalizado agregado" = Table.AddColumn(Origen, "ID Viaje", each [legajo_nro] & [prov_codigo] & Date.ToText([fecha_caratula], "yyyyMMdd")),
  #"Tipo de columna cambiado 1" = Table.TransformColumnTypes(#"Personalizado agregado", {{"ID Viaje", type text}}),

    #"Merge Cabecera" =
        Table.NestedJoin(#"Tipo de columna cambiado 1", {"ID Viaje"}, Cabecera, {"ID Viaje"}, "Cab", JoinKind.LeftOuter),

    #"Expand Cabecera" =
        Table.ExpandTableColumn(
            #"Merge Cabecera", "Cab",
            {"entregadas", "devueltas", "tot_zona", "tipo_vehiculo", "cal_min", "tot_liqui", "peaje", "tot_pagado", "tot_a_pagar", "productividad"},
            {"entregadas", "devueltas", "tot_zona", "tipo_vehiculo", "cal_min", "tot_liqui", "peaje", "tot_pagado", "tot_a_pagar", "productividad"}
        ),

    #"Piezas" =
        Table.AddColumn(
            #"Expand Cabecera", "Piezas",
            each (if [entregadas] = null then 0 else [entregadas]) +
                 (if [devueltas] = null then 0 else [devueltas]),
            type number
        ),

    #"Proporcional Adicional Zona" =
        Table.AddColumn(
            #"Piezas", "Proporcional Adicional Zona",
            each
                if [chk_codigo] = "DL" or [chk_codigo] = "DV" then
                    if [Piezas] = 0 then 0 else [tot_zona] / [Piezas]
                else 0,
            type number
        ),


    #"Paga Minimo Logica" =
        Table.AddColumn(
            #"Proporcional Adicional Zona", "Paga Minimo",
            each let veh = [tipo_vehiculo]
                 in if veh <> null and veh <> "CAMIONETA GRANDE" and veh <> "CHASIS" then [cal_min]
                    else if veh = "CAMIONETA GRANDE" and [cal_min] = "NO" then "NO"
                    else "SE",
            type text
        ),

    #"Paga Minimo Proporcional" =
        Table.AddColumn(
            #"Paga Minimo Logica", "Proporcional Paga Minimo",
            each
                if [chk_codigo] = "DL" or [chk_codigo] = "DV" then
                    if [Piezas] = 0 then null
                    else if [Paga Minimo] = "NO" then 0
                    else if [Paga Minimo] = "SE" then 0
                    else
                        (
                            (if [tot_a_pagar] = null then 0 else [tot_a_pagar]) -
                            (if [tot_pagado] = null then 0 else [tot_pagado])
                        ) / [Piezas]
                else 0,
            type number
        ),


    #"adic pami" =
        Table.AddColumn(
            #"Paga Minimo Proporcional", "Adic Pami",
            each if [id_shipper] <> null and [id_shipper] = 4290 and [costo_paq] > 0
                 then if [chk_codigo] = "CA" then [costo_paq] * 0.2 else [tarifa_base] * 0.2
                 else 0,
            type number
        ),

    #"adic pq grande" =
        Table.AddColumn(
            #"adic pami", "Adic PQ Grande",
            each if [peso_utiliza] <> null and [peso_utiliza] >= 35 and [costo_paq] > 0
                 then if [chk_codigo] = "CA" then [tarifa_base] * 0.3 * 0.35 else [tarifa_base] * 0.35
                 else 0,
            type number
        ),

    #"adic agencia" =
        Table.AddColumn(
            #"adic pq grande", "Adic Agencia",
            each if [legajo_nro] <> null and Text.StartsWith([legajo_nro], "P1") and [costo_paq] > 0
                 then [costo_paq] * 0.1
                 else 0,
            type number
        ),

    #"adic ca" =
        Table.AddColumn(
            #"adic agencia", "Adic CA",
            each if [chk_codigo] = "CA" and [costo_paq] > 0
                 then if [id_producto] = 148 then [tarifa_base] * 0.3
                 else ([tarifa_base] * 0.8) * 0.3
                 else 0,
            type number
        ),

    #"adic farma" =
        Table.AddColumn(
            #"adic ca", "Adic Farma",
            each if [farma] = "SI" and [costo_paq] > 0
                 then if [chk_codigo] = "CA" then [tarifa_base] * 0.3 * 0.25 else [tarifa_base] * 0.25
                 else 0,
            type number
        ),

    #"Descuento Postal" =
        Table.AddColumn(
            #"adic farma", "Descuento Postal",
            each if [costo_paq] <> null and [costo_paq] > 0 and ([chk_codigo] = "DL" or [chk_codigo] = "DV") and [id_producto] <> 148
                 then -([tarifa_base] * 0.2)
                 else 0,
            type number
        ),

    #"Paga Jornada" =
        Table.TransformColumnTypes(
            Table.AddColumn(
                #"adic farma", "Paga Jornada",
                each
                    let
                        veh = [tipo_vehiculo],
                        esChasis = if veh = null then false else Text.StartsWith(veh, "CHASIS"),
                        totPagado =
                            if esChasis
                            then (if [tot_liqui] = null then 0 else [tot_liqui]) +
                                 (if [peaje] = null then 0 else [peaje]) +
                                 (if [tot_zona] = null then 0 else [tot_zona])
                            else (if [tot_pagado] = null then 0 else [tot_pagado])
                    in
                        if (esChasis or veh = "CAMIONETA GRANDE") and [cal_min] <> "NO"
                        then (if [tot_a_pagar] = null then 0 else [tot_a_pagar]) - totPagado
                        else null
            ),
            {{"Paga Jornada", type number}}
        ),

    #"Proporcional Paga Jornada" =
        Table.AddColumn(
            #"Paga Jornada", "Proporcional Paga Jornada",
            each
                if [chk_codigo] = "DL" or [chk_codigo] = "DV" then
                    if [Piezas] = 0 then null else [Paga Jornada] / [Piezas]
                else 0,
            type number
        ),


    #"Proporcional Productividad" =
        Table.AddColumn(
            #"Proporcional Paga Jornada", "Proporcional Productividad",
            each
                if [chk_codigo] <> "DL" and [chk_codigo] <> "DV" then
                    0
                else
                    let
                        veh = [tipo_vehiculo],
                        esChasis = if veh = null then false else Text.StartsWith(veh, "CHASIS"),
                        calMin = [cal_min],
                        aplicaExclusion =
                            esChasis or (calMin = "SI" and veh <> "CAMIONETA GRANDE"),

                        fec = [fecha_caratula],
                        suc = if [prov_codigo] = null then null else Text.Upper([prov_codigo]),
                        prod_raw = try [productividad] otherwise null,
                        prod_num = try Number.From(prod_raw) otherwise null,
                        prod =
                            if prod_num = null then null
                            else if prod_num > 1 then prod_num / 100
                            else prod_num,

                        piezas = [Piezas],
                        total = if [tot_a_pagar] = null then 0 else [tot_a_pagar],

                        sucEspecial = List.Contains({"CDO","MZA","RSO","MDP"}, suc),
                        desdeNuevaRegla = if fec = null then false else fec >= #date(2025, 11, 1),

                        umbralAlta = if sucEspecial then 0.95 else if desdeNuevaRegla then 0.90 else 0.95,
                        umbralBaja = if sucEspecial then 0.85 else if desdeNuevaRegla then 0.80 else 0.85,

                        valor =
                            if aplicaExclusion then
                                0
                            else if piezas = null or piezas = 0 or prod = null then
                                null
                            else if prod >= umbralAlta then
                                ( ( total * (0.10 / 1.10) ) / piezas )
                            else if prod < umbralBaja then
                                -(( total * (0.10 / 0.90) ) / piezas )
                            else
                                0
                    in
                        valor,
            type number
        ),


    #"Tipo de columna cambiado" =
        Table.TransformColumnTypes(
            #"Proporcional Productividad",
            {
                {"Adic Pami", type number}, {"Adic PQ Grande", type number}, {"Adic Agencia", type number},
                {"Adic CA", type number}, {"Adic Farma", type number}, {"nro_caratula", type text},
                {"id_shipper", type text}, {"productividad", type number}
            }
        ),

    #"Elegir columnas" =
        Table.SelectColumns(#"Tipo de columna cambiado", {"prov_codigo", "nro_caratula", "id_producto", "id_shipper", "farma", "codigo_postal", "zona", "chk_codigo", "tarifa_base", "peso_utiliza", "costo_paq", "p_pagado", "peso_total", "ID Viaje", "tipo_vehiculo", "cal_min", "productividad", "Piezas", "Proporcional Adicional Zona", "Paga Minimo", "Proporcional Paga Minimo", "Adic Pami", "Adic PQ Grande", "Adic Agencia", "Adic CA", "Adic Farma", "Paga Jornada", "Proporcional Paga Jornada", "Proporcional Productividad"}),

    #"BA a DV con costo" =
        Table.TransformColumns(
            #"otros cálculos",
            {
                {
                    "chk_codigo",
                    each if _ = "BA" and [costo_paq] > 0 then "DV" else _,
                    type text
                }
            }
        ),

    #"Columna condicional insertada1" =
        Table.AddColumn(
            #"Elegir columnas", "Tipo PQ",
            each if [id_producto] <> null and [id_producto] <> 148 then "Postal"
                 else if [id_shipper] <> null and [id_shipper] = "4290" then "Pami"
                 else if [farma] <> null and [farma] = "SI" then "Farma"
                 else if [peso_utiliza] <> null and [peso_utiliza] >= 35 then "PQ Grande"
                 else "PQ Chico",
            type text
        ),

    #"Columna condicional insertada" =
    Table.AddColumn(
        #"Columna condicional insertada1", "Envío",
        each 
            if [id_producto] <> null and [id_producto] <> 148 then "Postal"
            else if [id_shipper] <> null and [id_shipper] = "4290" then "Pami"
            else if [id_shipper] <> null and [id_shipper] = "2273" then "Mercado Libre"
            else if [id_shipper] <> null and [id_shipper] = "1039" then "CrossBorder"      
            else if [farma] <> null and [farma] = "SI" then "Salud"   
            else "Logística",
        type text
    )
in
    #"Columna condicional insertada";
shared Cabecera_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "38153748-4605-4aa9-96d5-c848565db7d9"]}[Data],
  TableNavigation = Navigation_2{[Id = "U3_Liq_Fleteros_Cabecera", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared Detalle_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "c1099798-9ed1-461f-b5d2-843e5a67ccfd"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "38153748-4605-4aa9-96d5-c848565db7d9"]}[Data],
  TableNavigation = Navigation_2{[Id = "U3_Liq_Fleteros_Detalle", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;

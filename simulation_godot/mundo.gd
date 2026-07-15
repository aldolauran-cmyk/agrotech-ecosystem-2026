extends Node3D

# --- CONFIGURACIÓN DE CONEXIÓN ---
const API_URL_GET = "http://127.0.0.1:8000/api/v1/parcels/public"
const TIEMPO_ACTUALIZACION = 2.0 

var temporizador: Timer
var http_request: HTTPRequest

# --- VARIABLES DE ESTADO DEL GEMELO DIGITAL ---
var humedad_suelo: float = 50.0
var ph_suelo: float = 7.0
var temperatura_suelo: float = 24.0
var estado_parcela: String = "Monitoreando"

# --- LISTAS DE CONTROL PARA ANIMACIÓN Y MATERIALES ---
var lista_plantas: Array = []
var lista_sensores: Array = []
var lista_circuitos: Array = []
var lista_emisores_agua: Array = []

# --- VARIABLES DEL DRON AUTÓNOMO ---
var nodo_dron: Node3D = null
var tiempo_vuelo: float = 0.0
var radio_orbita: float = 4.0
var velocidad_dron: float = 0.6

# --- NODOS DE INTERFAZ DE USUARIO ---
@onready var suelo: MeshInstance3D = $MeshInstance3D
@onready var texto_titulo: Label = $CanvasLayer/PanelControl/VBoxContainer/TextoTitulo

func _ready() -> void:
	print("--- Inicializando Gemelo Digital Completo Híbrido V4 ---")
	
	# LIMPIEZA TOTAL DE INTRUSOS EN LA INTERFAZ
	if texto_titulo:
		texto_titulo.text = ""
		var contenedor = texto_titulo.get_parent()
		if contenedor:
			for hijo in contenedor.get_children():
				if hijo is Label and hijo != texto_titulo:
					hijo.queue_free()
	
	# 1. Configuración de la Red Asíncrona
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_api_response)
	
	# Configurar el Timer para actualización cíclica
	temporizador = Timer.new()
	temporizador.wait_time = TIEMPO_ACTUALIZACION
	temporizador.autostart = true
	add_child(temporizador)
	temporizador.timeout.connect(solicitar_datos_api)
	
	# 2. Reconstrucción Gráfica Procedimental del Invernadero
	configurar_iluminacion_y_glow()
	generar_cultivos_y_sensores()
	
	# Forzar la primera actualización limpia en pantalla
	actualizar_gemelo_digital(false)
	
	# Primera consulta de datos al arrancar
	solicitar_datos_api()	

func _process(delta: float) -> void:
	# Animación matemática de la órbita del dron sobre la parcela
	if nodo_dron and is_instance_valid(nodo_dron):
		tiempo_vuelo += delta * velocidad_dron
		var drone_x = cos(tiempo_vuelo) * radio_orbita
		var drone_z = sin(tiempo_vuelo) * radio_orbita
		nodo_dron.position = Vector3(drone_x, 1.8, drone_z)
		
		var siguiente_punto = Vector3(cos(tiempo_vuelo + 0.1) * radio_orbita, 1.8, sin(tiempo_vuelo + 0.1) * radio_orbita)
		nodo_dron.look_at(siguiente_punto, Vector3.UP)

func solicitar_datos_api() -> void:
	# Evitar solicitudes simultáneas si una anterior sigue en curso
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return

	var headers = [
		"Accept: application/json",
		"Content-Type: application/json"
	]
	var error = http_request.request(API_URL_GET, headers, HTTPClient.METHOD_GET)
	if error != OK:
		generar_datos_simulados()

func _on_api_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		var parse_err = json.parse(body.get_string_from_utf8())
		if parse_err == OK:
			var datos_recibidos = json.get_data()
			var datos_api: Dictionary = {}
			
			if typeof(datos_recibidos) == TYPE_ARRAY and datos_recibidos.size() > 0:
				datos_api = datos_recibidos[0]
			elif typeof(datos_recibidos) == TYPE_DICTIONARY:
				datos_api = datos_recibidos
			else:
				generar_datos_simulados()
				return
			
			# MAPEO TOLERANTE MULTIDIOMA (moisture mapeado desde la API)
			humedad_suelo = float(datos_api.get("moisture", datos_api.get("humidity", datos_api.get("humedad", 50.0))))
			ph_suelo = float(datos_api.get("ph", 7.0))
			temperatura_suelo = float(datos_api.get("temperature", datos_api.get("temperatura", 24.0)))
			estado_parcela = str(datos_api.get("status", datos_api.get("estado", "Activo")))
			
			_evaluar_reglas_negocio(false)
		else:
			generar_datos_simulados()
	else:
		# Si la API falla o da 401 Unauthorized, entra aquí de forma controlada
		generar_datos_simulados()

func generar_datos_simulados() -> void:
	# Genera fluctuaciones suaves y realistas locales
	humedad_suelo = clamp(humedad_suelo + randf_range(-2.0, 2.0), 15.0, 90.0)
	ph_suelo = clamp(ph_suelo + randf_range(-0.05, 0.05), 5.5, 8.5)
	temperatura_suelo = clamp(temperatura_suelo + randf_range(-0.2, 0.2), 18.0, 33.0)
	_evaluar_reglas_negocio(true)

func _evaluar_reglas_negocio(es_simulado: bool) -> void:
	if humedad_suelo < 30.0:
		estado_parcela = "Estrés Hídrico (Seco)"
	elif humedad_suelo > 70.0:
		estado_parcela = "Suelo Saturado / Inundado"
	else:
		estado_parcela = "Óptimo"
		
	actualizar_gemelo_digital(es_simulado)

# --- SISTEMA DE RENDERIZADO PROCEDIMENTAL ---

func configurar_iluminacion_y_glow() -> void:
	var env_node = $WorldEnvironment
	if env_node and env_node.environment:
		var env = env_node.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.03, 0.04, 0.06)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.08, 0.1, 0.15)
		env.ambient_light_energy = 0.5
		env.glow_enabled = true
		env.glow_intensity = 1.4
		env.glow_strength = 0.9
		env.glow_bloom = 0.25
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN

	if not has_node("LuzLunaSoporte"):
		var luz_luna = DirectionalLight3D.new()
		luz_luna.name = "LuzLunaSoporte"
		luz_luna.light_color = Color(0.5, 0.7, 1.0)
		luz_luna.light_energy = 0.35
		luz_luna.rotation_degrees = Vector3(-50, 40, 0)
		luz_luna.shadow_enabled = true
		add_child(luz_luna)

func generar_cultivos_y_sensores() -> void:
	var posiciones_x = [-4.0, -1.5, 1.5, 4.0]
	lista_plantas.clear()
	lista_sensores.clear()
	lista_circuitos.clear()
	lista_emisores_agua.clear()
	
	# Gateway Central
	var gateway = Node3D.new()
	gateway.position = Vector3(0.0, 0.0, 0.0)
	add_child(gateway)
	
	var base_gate = MeshInstance3D.new()
	var cubo_gate = BoxMesh.new()
	cubo_gate.size = Vector3(0.5, 1.2, 0.5)
	base_gate.mesh = cubo_gate
	base_gate.position.y = 0.6
	gateway.add_child(base_gate)
	
	var mat_gate = StandardMaterial3D.new()
	mat_gate.albedo_color = Color(0.08, 0.1, 0.12)
	mat_gate.metallic = 0.9
	mat_gate.roughness = 0.15
	base_gate.set_surface_override_material(0, mat_gate)
	
	# Tubos de Riego
	var mat_cristal_tubo = StandardMaterial3D.new()
	mat_cristal_tubo.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat_cristal_tubo.albedo_color = Color(0.2, 0.6, 1.0, 0.2)
	mat_cristal_tubo.metallic = 0.4
	mat_cristal_tubo.roughness = 0.1

	var posiciones_tubos_x = [-5.0, 5.0]
	for tx in posiciones_tubos_x:
		var tubo_mesh = MeshInstance3D.new()
		var cilindro_tubo = CylinderMesh.new()
		cilindro_tubo.top_radius = 0.05
		cilindro_tubo.bottom_radius = 0.05
		cilindro_tubo.height = 12.0
		tubo_mesh.mesh = cilindro_tubo
		tubo_mesh.position = Vector3(tx, 0.1, 0.0)
		tubo_mesh.rotation.x = deg_to_rad(90)
		tubo_mesh.set_surface_override_material(0, mat_cristal_tubo)
		add_child(tubo_mesh)
		
		var particulas = GPUParticles3D.new()
		var mt = ParticleProcessMaterial.new()
		mt.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mt.emission_box_extents = Vector3(0.02, 0.02, 5.5)
		mt.direction = Vector3(0, 0.5, 0)
		mt.spread = 15.0
		mt.initial_velocity_min = 1.0
		mt.initial_velocity_max = 2.0
		particulas.process_material = mt
		
		var gota_mesh = SphereMesh.new()
		gota_mesh.radius = 0.01
		gota_mesh.height = 0.02
		var mat_gota = StandardMaterial3D.new()
		mat_gota.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat_gota.albedo_color = Color(0.5, 0.8, 1.0, 0.6)
		mat_gota.emission_enabled = true
		mat_gota.emission = Color(0.2, 0.6, 1.0)
		mat_gota.emission_energy_multiplier = 1.5
		gota_mesh.material = mat_gota
		
		particulas.draw_pass_1 = gota_mesh
		particulas.amount = 300
		particulas.lifetime = 0.6
		particulas.position = Vector3(tx, 0.15, 0.0)
		add_child(particulas)
		lista_emisores_agua.append(particulas)
	
	# Cultivos (Zanahorias) y Postes de Sensores
	for x in posiciones_x:
		for i in range(8):
			var z_pos = -5.0 + (i * 1.5)
			
			var cultivo_completo = Node3D.new()
			cultivo_completo.position = Vector3(x, 0.0, z_pos)
			add_child(cultivo_completo)
			
			var cuerpo_mesh = MeshInstance3D.new()
			var cono = CylinderMesh.new()
			cono.top_radius = 0.12
			cono.bottom_radius = 0.02
			cono.height = 0.3
			cuerpo_mesh.mesh = cono
			cuerpo_mesh.position.y = 0.05
			cultivo_completo.add_child(cuerpo_mesh)
			lista_plantas.append(cuerpo_mesh)
			
			var nodo_hojas = Node3D.new()
			nodo_hojas.position.y = 0.2
			cultivo_completo.add_child(nodo_hojas)
			
			var mat_hojas = StandardMaterial3D.new()
			mat_hojas.albedo_color = Color(0.12, 0.5, 0.18)
			mat_hojas.roughness = 0.6
			
			for h in range(4):
				var rama = MeshInstance3D.new()
				var cono_hoja = CylinderMesh.new()
				cono_hoja.top_radius = 0.005
				cono_hoja.bottom_radius = 0.02
				cono_hoja.height = 0.4
				rama.mesh = cono_hoja
				rama.position.y = 0.15
				rama.rotation.z = deg_to_rad(-20 + (h * 14))
				rama.rotation.x = deg_to_rad(-10 + (h * 6))
				rama.set_surface_override_material(0, mat_hojas)
				nodo_hojas.add_child(rama)
			
			var nodo_sensor = Node3D.new()
			nodo_sensor.position = Vector3(0.35, 0.0, 0.0)
			cultivo_completo.add_child(nodo_sensor)
			
			var poste = MeshInstance3D.new()
			var cilindro_poste = CylinderMesh.new()
			cilindro_poste.top_radius = 0.01
			cilindro_poste.bottom_radius = 0.01
			cilindro_poste.height = 0.3
			poste.mesh = cilindro_poste
			poste.position.y = 0.15
			nodo_sensor.add_child(poste)
			
			var mat_poste = StandardMaterial3D.new()
			mat_poste.albedo_color = Color(0.05, 0.05, 0.06)
			mat_poste.metallic = 1.0
			poste.set_surface_override_material(0, mat_poste)
			
			var pantalla = MeshInstance3D.new()
			var caja_pantalla = BoxMesh.new()
			caja_pantalla.size = Vector3(0.06, 0.06, 0.06)
			pantalla.mesh = caja_pantalla
			pantalla.position.y = 0.3
			nodo_sensor.add_child(pantalla)
			lista_sensores.append(pantalla)
			
			# SOLUCIÓN AL ERROR DE ASIGNACIÓN EN MESH:
			var bus_x = MeshInstance3D.new()
			var box_x = BoxMesh.new()
			box_x.size = Vector3(0.35, 0.002, 0.01)
			bus_x.mesh = box_x # Asignación correcta sobre el MeshInstance3D
			bus_x.position = Vector3(x + 0.175, 0.002, z_pos)
			add_child(bus_x)
			lista_circuitos.append(bus_x)
			
			var bus_z = MeshInstance3D.new()
			var box_z = BoxMesh.new()
			box_z.size = Vector3(0.01, 0.002, abs(z_pos))
			bus_z.mesh = box_z # Asignación correcta sobre el MeshInstance3D
			bus_z.position = Vector3(x, 0.002, z_pos / 2.0)
			add_child(bus_z)
			lista_circuitos.append(bus_z)

	# --- DRON AUTÓNOMO ---
	nodo_dron = Node3D.new()
	add_child(nodo_dron)
	
	var chasis = MeshInstance3D.new()
	var caja_chasis = BoxMesh.new()
	caja_chasis.size = Vector3(0.22, 0.04, 0.22)
	chasis.mesh = caja_chasis
	nodo_dron.add_child(chasis)
	
	var mat_dron = StandardMaterial3D.new()
	mat_dron.albedo_color = Color(0.05, 0.06, 0.08)
	mat_dron.metallic = 0.9
	mat_dron.roughness = 0.1
	chasis.set_surface_override_material(0, mat_dron)

func actualizar_gemelo_digital(es_simulado: bool) -> void:
	if texto_titulo:
		texto_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var texto_limpio = "SISTEMA IOT - PARCELA 1\n"
		texto_limpio += "Humedad: " + str(snapped(humedad_suelo, 0.1)) + "%\n"
		texto_limpio += "pH del Suelo: " + str(snapped(ph_suelo, 0.1)) + "\n"
		texto_limpio += "Temperatura: " + str(snapped(temperatura_suelo, 0.1)) + "°C\n"
		texto_limpio += "Estado: " + estado_parcela
		
		# Evitamos la acumulación infinita añadiéndolo de manera limpia solo una vez
		if es_simulado:
			texto_limpio += "\n[Simulado]"
			
		texto_titulo.text = texto_limpio

	var mat_suelo = StandardMaterial3D.new()
	var tex_tierra = load("res://tierra para gdot.jpg")
	if tex_tierra:
		mat_suelo.albedo_texture = tex_tierra
		mat_suelo.uv1_scale = Vector3(4, 4, 4)
	
	var mat_planta = StandardMaterial3D.new()
	var mat_neon = StandardMaterial3D.new()
	mat_neon.emission_enabled = true
	mat_neon.emission_energy_multiplier = 9.0
	
	if humedad_suelo < 30.0:
		mat_suelo.albedo_color = Color(0.8, 0.1, 0.1) # Rojo (Estrés hídrico)
		mat_suelo.roughness = 0.95
		mat_planta.albedo_color = Color(0.95, 0.35, 0.0)
		mat_planta.roughness = 0.5
		mat_neon.albedo_color = Color(1.0, 0.02, 0.0)
		mat_neon.emission = Color(1.0, 0.02, 0.0)
	elif humedad_suelo > 70.0:
		mat_suelo.albedo_color = Color(0.1, 0.4, 0.8) # Azul (Saturado / Inundado)
		mat_suelo.roughness = 0.2
		mat_planta.albedo_color = Color(0.6, 0.25, 0.0)
		mat_planta.roughness = 0.4
		mat_neon.albedo_color = Color(0.2, 0.2, 1.0)
		mat_neon.emission = Color(0.2, 0.2, 1.0)
	else:
		mat_suelo.albedo_color = Color("2e5a1c") # Verde (Óptimo)
		mat_suelo.roughness = 0.6
		mat_planta.albedo_color = Color(0.9, 0.4, 0.0)
		mat_planta.roughness = 0.4
		mat_neon.albedo_color = Color(0.0, 0.85, 0.1)
		mat_neon.emission = Color(0.0, 0.85, 0.1)

	if suelo:
		suelo.set_surface_override_material(0, mat_suelo)
		
	for planta in lista_plantas:
		if planta is MeshInstance3D:
			planta.set_surface_override_material(0, mat_planta)
			
	for sensor in lista_sensores:
		if sensor is MeshInstance3D:
			sensor.set_surface_override_material(0, mat_neon)
			
	for circuito in lista_circuitos:
		if circuito is MeshInstance3D:
			circuito.set_surface_override_material(0, mat_neon)
			
	for emisor in lista_emisores_agua:
		if emisor is GPUParticles3D:
			emisor.emitting = (humedad_suelo < 30.0)

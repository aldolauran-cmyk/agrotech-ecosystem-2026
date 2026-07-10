extends MeshInstance3D

# Variables públicas con tipado explícito
var parcel_id: int = 0
var current_state: String = "OPTIMO"

# Función pública para actualizar las propiedades y el comportamiento visual del bloque 3D
func update_properties(humidity: float, temperature: float, ph: float, alerta_estado: String) -> void:
	current_state = alerta_estado
	
	# Asegurar que el nodo tenga un material único asignado para poder cambiarle el color
	if material_override == null:
		material_override = StandardMaterial3D.new()
	
	var mat = material_override as StandardMaterial3D
	
	# Evaluar de forma dinámica la alerta de red para cambiar el color del bloque (Albedo)
	match alerta_estado:
		"ESTRES_HIDRICO":
			print("[Parcel3D ID:", parcel_id, "] Modo SECO (Estrés Hídrico) -> Cambiando a Marrón")
			mat.albedo_color = Color.from_string("#8B5A2B", Color.BROWN)
			
		"OPTIMO":
			print("[Parcel3D ID:", parcel_id, "] Modo ÓPTIMO -> Cambiando a Verde")
			mat.albedo_color = Color.from_string("#2E8B57", Color.GREEN)
			
		"SATURADO":
			print("[Parcel3D ID:", parcel_id, "] Modo SATURADO (Hiperhúmedo) -> Cambiando a Azul")
			mat.albedo_color = Color.from_string("#4682B4", Color.BLUE)
			
		_:
			printerr("[Parcel3D ID:", parcel_id, "] Alerta no reconocida: ", alerta_estado)

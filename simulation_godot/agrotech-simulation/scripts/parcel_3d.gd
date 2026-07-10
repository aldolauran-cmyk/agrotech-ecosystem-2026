extends MeshInstance3D

# Variables públicas con tipado explícito
var parcel_id: int = 0
var current_state: String = "OPTIMO"


# Función pública para actualizar las propiedades y el comportamiento visual del bloque 3D
func update_properties(humidity: float, temperature: float, ph: float, alerta_estado: String) -> void:
	# Actualizar el estado interno de la parcela
	current_state = alerta_estado
	
	# Evaluar de forma dinámica la alerta de red para adaptar la lógica gráfica
	match alerta_estado:
		"ESTRES_HIDRICO":
			print("[Parcel3D ID:", parcel_id, "] Cambiando lógica visual a modo SECO (Estrés Hídrico)")
			# TODO: Cambiar el material Albedo del Mesh en la fase estética final
			
		"OPTIMO":
			print("[Parcel3D ID:", parcel_id, "] Cambiando lógica visual a modo ÓPTIMO")
			# TODO: Cambiar el material Albedo del Mesh en la fase estética final
			
		"SATURADO":
			print("[Parcel3D ID:", parcel_id, "] Cambiando lógica visual a modo SATURADO (Hiperhúmedo)")
			# TODO: Cambiar el material Albedo del Mesh en la fase estética final
			
		_:
			printerr("[Parcel3D ID:", parcel_id, "] Alerta de estado no reconocida: ", alerta_estado)

extends Camera3D

# Variables de configuración ajustables desde el inspector
@export var movement_speed: float = 10.0
@export var mouse_sensitivity: float = 0.1


func _process(delta: float) -> void:
	var move_direction = Vector3.ZERO
	
	# Detectar la presión de teclas físicas directas (sin necesidad de configurar Input Map)
	if Input.is_key_pressed(KEY_W):
		move_direction -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		move_direction += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		move_direction -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		move_direction += global_transform.basis.x
		
	# Mover suavemente si se ha ingresado alguna dirección
	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()
		global_position += move_direction * movement_speed * delta


func _input(event: InputEvent) -> void:
	# Rotación libre de cámara al arrastrar con el click derecho del mouse
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Panning (Rotación horizontal en eje Y)
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		# Tilting (Rotación vertical en eje X)
		rotate_object_local(Vector3.RIGHT, deg_to_rad(-event.relative.y * mouse_sensitivity))
		
		# Acotación para evitar que la cámara gire por completo de cabeza
		var rot = rotation
		rot.x = clamp(rot.x, deg_to_rad(-80.0), deg_to_rad(80.0))
		rotation = rot

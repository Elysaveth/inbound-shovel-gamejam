extends RigidBody3D

@export_group("Movement")
@export var rolling_speed := 5
var is_running := false

@export_group("Camera")
@export var look_sensitivity : float = 0.5

@onready var camera : Camera3D = $CameraRig/Camera

func _ready():
	$CameraRig.top_level = true
	$FloorCheck.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	var rolling_force = rolling_speed
	
	# Camera follow
	$CameraRig.global_transform.origin = lerp(
		$CameraRig.global_transform.origin, 
		global_transform.origin,
		0.1
	)
	$CameraRig.global_transform.basis.z = lerp(
		$CameraRig.global_transform.basis.z,
		Vector3(-linear_velocity.x, 0, -linear_velocity.z).normalized(),
		look_sensitivity
	)
	$CameraRig.global_transform.basis.x = lerp(
		$CameraRig.global_transform.basis.x,
		Vector3(linear_velocity.z, 0, -linear_velocity.x).normalized(),
		look_sensitivity
	)
	
	$FloorCheck.global_transform.origin = global_transform.origin
	
	if is_running:
		rolling_force = rolling_force * 1.5
		is_running = false
		
	if Input.is_action_pressed("move_forward"):
		linear_velocity *= 1 + (rolling_force * delta)
	elif Input.is_action_pressed("move_back"):
		linear_velocity /= 1 + (rolling_force * delta)
	if Input.is_action_pressed("move_left"):
		linear_velocity -= rolling_force * delta
	elif Input.is_action_pressed("move_right"):
		linear_velocity += rolling_force * delta
		
		# Mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			

	if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
		apply_impulse(Vector3(), Vector3.UP*1000)
		
	is_running = Input.is_action_pressed("sprint")

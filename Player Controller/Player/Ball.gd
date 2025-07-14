extends RigidBody3D

@export_group("Movement")
@export var rolling_speed := 40
var is_running := false

@export_group("Camera")
@export var look_sensitivity : float = 0.025
var camera_look_input : Vector2

@onready var camera : Camera3D = $CameraRig/Camera

func _ready():
	$CameraRig.top_level = true
	$FloorCheck.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	var rolling_force = rolling_speed
	$CameraRig.global_transform.origin = lerp(
	$CameraRig.global_transform.origin, 
	global_transform.origin, 0.1
	)
	$FloorCheck.global_transform.origin = global_transform.origin
	if is_running:
		rolling_force = rolling_force * 1.5
		is_running = false
	if Input.is_action_pressed("move_forward"):
		angular_velocity.x -= rolling_force*delta
	elif Input.is_action_pressed("move_back"):
		angular_velocity.x += rolling_force*delta
	if Input.is_action_pressed("move_left"):
		angular_velocity.z += rolling_force*delta
	elif Input.is_action_pressed("move_right"):
		angular_velocity.z -= rolling_force*delta
		
		# Mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			

	if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
		apply_impulse(Vector3(), Vector3.UP*1000)
		
	is_running = Input.is_action_pressed("sprint")

	camera.rotate_y((linear_velocity.angle_to(Vector3(camera.rotation.z, linear_velocity.y, camera.rotation.z))) * look_sensitivity)
	camera.rotation.y = clamp(camera.rotation.y, -1.5, 1.5)

	camera_look_input = Vector2.ZERO

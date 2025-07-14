class_name PlayerController
extends RigidBody3D

@export_group("Movement")
@export var max_speed : float = 4.0
@export var acceleration : float = 20.0
@export var braking : float = 20.0
@export var air_acceleration : float = 4.0
@export var jump_force : float = 5.0
@export var gravity_modifier : float = 1.5
@export var max_run_speed : float = 6.0
@export var rolling_force = 40
var is_running : bool = false

@export_group("Camera")
@export var look_sensitivity : float = 0.005
var camera_look_input : Vector2

@onready var camera : Camera3D = get_node("Camera3D")
@onready var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_modifier

func _ready():
	# Lock the mouse
	$FloorCheck.top_level = true
	$Camera3D.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	$FloorCheck.global_transform.origin = global_transform.origin
	if Input.is_action_pressed("move_forward"):
		angular_velocity.x -= rolling_force*delta
	elif Input.is_action_pressed("move_back"):
		angular_velocity.x += rolling_force*delta
	if Input.is_action_pressed("move_left"):
		angular_velocity.z += rolling_force*delta
	elif Input.is_action_pressed("move_right"):
		angular_velocity.z -= rolling_force*delta

	if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
		apply_impulse(Vector3(), Vector3.UP*1000)
	
	is_running = Input.is_action_pressed("sprint")
	
	var target_speed = max_speed
	
	if is_running:
		rolling_force = rolling_force * 2
	
	
	# Camera Look
	rotate_y(-camera_look_input.x * look_sensitivity)	
	camera.rotate_x(-camera_look_input.y * look_sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	camera_look_input = Vector2.ZERO
	
	# Mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		camera_look_input = event.relative

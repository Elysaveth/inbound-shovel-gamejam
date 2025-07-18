extends RigidBody3D

@export_group("Movement")
@export var rolling_speed : float = 40.0
var rolling_force := rolling_speed
var is_running := false

@export_group("Camera")
@export var look_sensitivity : float = 0.01

var fordward_orientation : Vector2
var sideways_orientation : Vector2

var new_angular_v_x : float
var new_angular_v_z : float

var started: bool = false

func _ready():
	$CameraRig.top_level = true
	$FloorCheck.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float):
	# Camera follow
	$CameraRig.global_transform.origin = lerp(
		$CameraRig.global_transform.origin, 
		global_transform.origin,
		0.1
	)
	# Mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
	if not started and not Input.is_action_just_pressed("ui_cancel"):
		if Input.is_anything_pressed():
			started = true
			
	if started:
		rolling_force = rolling_speed
		if is_running:
			rolling_force = rolling_force * 1.5
			is_running = false

		ball_movement(delta)
		camera_movement()
		#game_process(delta)

		$FloorCheck.global_transform.origin = global_transform.origin
		
		if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
			apply_impulse(Vector3(), Vector3.UP*100)

		is_running = Input.is_action_pressed("sprint")


	



func camera_movement() -> void:
	print(linear_velocity.length())
	# Camera turn in movement direction
	if (linear_velocity.length() > 0.5):
		$CameraRig.global_transform.basis.z = lerp(
			$CameraRig.global_transform.basis.z,
			Vector3(-linear_velocity.x, 0, -linear_velocity.z).normalized(),
			look_sensitivity * (clampf(linear_velocity.length(), 0.1, 1.1) - 0.1)
		)
		$CameraRig.global_transform.basis.x = lerp(
			$CameraRig.global_transform.basis.x,
			Vector3(linear_velocity.z, 0, -linear_velocity.x).normalized(),
			look_sensitivity * (clampf(linear_velocity.length(), 0.1, 1.1) - 0.1)
		)
		
	#Camera follow ball
	if ($CameraRig.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z != 0):
		fordward_orientation = Vector2(
			$CameraRig.global_transform.basis.x.x / ($CameraRig.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z),
			$CameraRig.global_transform.basis.x.z / ($CameraRig.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z)
		)
	if ($CameraRig.global_transform.basis.z.x + $CameraRig.global_transform.basis.z.z != 0):
		sideways_orientation = Vector2(
			$CameraRig.global_transform.basis.z.x / ($CameraRig.global_transform.basis.z.x + $CameraRig.global_transform.basis.z.z),
			$CameraRig.global_transform.basis.z.z / ($CameraRig.global_transform.basis.z.x + $CameraRig.global_transform.basis.z.z)
		)


func ball_movement(delta: float) -> void:
	if Input.is_action_pressed("move_forward"):
		new_angular_v_x = angular_velocity.x * (1 + abs(fordward_orientation.x) * rolling_force * delta * sign(fordward_orientation.x))
		angular_velocity.x = new_angular_v_x
		new_angular_v_z = angular_velocity.z * (1 + abs(fordward_orientation.y) * rolling_force * delta * sign(fordward_orientation.y))
		angular_velocity.z = new_angular_v_z
	elif Input.is_action_pressed("move_back"):
		angular_velocity.x = angular_velocity.x * \
			clamp(1 - abs(fordward_orientation.x) * rolling_force / 10 * delta * sign(fordward_orientation.x), 0, 1)
		angular_velocity.x = angular_velocity.z * \
			clamp(1 - abs(fordward_orientation.y) * rolling_force / 10 * delta * sign(fordward_orientation.y), 0, 1)
	if Input.is_action_pressed("move_left"):
		print("Going left")
		print(sideways_orientation)
		print(angular_velocity)
		angular_velocity.x = angular_velocity.x * (1 + abs(sideways_orientation.x) * rolling_force * delta * sign(sideways_orientation.x))
		angular_velocity.z = angular_velocity.z * (1 + abs(sideways_orientation.y) * rolling_force * delta * sign(sideways_orientation.y))
		print(angular_velocity)
	elif Input.is_action_pressed("move_right"):
		angular_velocity.x = angular_velocity.x * (1 + abs(sideways_orientation.x) * rolling_force * delta * sign(sideways_orientation.x))
		angular_velocity.z = angular_velocity.z * (1 + abs(sideways_orientation.y) * rolling_force * delta * sign(sideways_orientation.y))
		
	angular_velocity = angular_velocity.clamp(angular_velocity.normalized() * -20, angular_velocity.normalized() * 20)

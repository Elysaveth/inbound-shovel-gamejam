extends RigidBody3D

@export_group("Movement")
@export var rolling_speed : float = 40.0
var rolling_force := rolling_speed
var is_running := false

@export_group("Camera")
@export var look_sensitivity : float = 0.5

var fordward_orientation : Vector2
var sideways_orientation : Vector2

var new_angular_v_x : float
var new_angular_v_z : float

func _ready():
	$CameraRig.top_level = true
	$FloorCheck.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	rolling_force = rolling_speed
	
	# Camera follow
	$CameraRig.global_transform.origin = lerp(
		$CameraRig.global_transform.origin, 
		global_transform.origin,
		0.1
	)
	#print(linear_velocity.length())
	if (linear_velocity.length() > 0.1):
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
	if ($CameraRig.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z != 0):
		fordward_orientation = Vector2(
			$CameraRig.global_transform.basis.x.x / ($CameraRig.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z),
			$CameraRig.global_transform.basis.x.z / ($CameraRig.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z)
		)
	else:
		fordward_orientation = Vector2(0, 0)
	if ($CameraRig.global_transform.basis.z.x + $CameraRig.global_transform.basis.z.z != 0):
		sideways_orientation = Vector2(
			$CameraRig.global_transform.basis.z.x / ($CameraRig.global_transform.basis.z.x + $CameraRig.global_transform.basis.z.z),
			$CameraRig.global_transform.basis.z.z / ($CameraRig.global_transform.basis.z.x + $CameraRig.global_transform.basis.z.z)
		)
	else:
		fordward_orientation = Vector2(0, 0)
	
	$FloorCheck.global_transform.origin = global_transform.origin
	
	if is_running:
		rolling_force = rolling_force * 1.5
		is_running = false
		
		
	if Input.is_action_pressed("move_forward"):
		#print("Before:")
		#print(linear_velocity)
		#print(angular_velocity)
		#print(fordward_orientation)
		new_angular_v_x = angular_velocity.x * (1 + abs(fordward_orientation.x) * rolling_force * delta * sign(fordward_orientation.x))
		angular_velocity.x = new_angular_v_x
		new_angular_v_z = angular_velocity.z * (1 + abs(fordward_orientation.y) * rolling_force * delta * sign(fordward_orientation.y))
		angular_velocity.z = new_angular_v_z
		#print("After:")
		#print(linear_velocity)
		#print(angular_velocity)
		#print(sideways_orientation)
	elif Input.is_action_pressed("move_back"):
		new_angular_v_x = angular_velocity.x * (1 - abs(fordward_orientation.x) * rolling_force / 10 * delta * sign(fordward_orientation.x))
		angular_velocity.x = new_angular_v_x if sign(angular_velocity.x) == sign(new_angular_v_x) else 0.0
		new_angular_v_z = angular_velocity.z * (1 - abs(fordward_orientation.y) * rolling_force / 10 * delta * sign(fordward_orientation.y))
		angular_velocity.z = new_angular_v_z if sign(angular_velocity.z) == sign(new_angular_v_z) else 0.0
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
	
		# Mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			

	if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
		apply_impulse(Vector3(), Vector3.UP*1000)
		
	is_running = Input.is_action_pressed("sprint")

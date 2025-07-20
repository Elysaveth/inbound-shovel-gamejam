extends RigidBody3D

signal game_over
signal paused

@export var impact_gameover := 1.5

@export_group("Movement")
@export var rolling_speed : float = 20.0
var rolling_force := rolling_speed
var is_running := false

@export_group("Camera")
@export var look_sensitivity : float = 0.01

var fordward_orientation : Vector2
var sideways_orientation : Vector2

var new_angular_v_x : float
var new_angular_v_z : float

var started: bool = false
var pause: bool = false

var beetle_pos: Vector3
var prev_speed: Vector3
var linear_speed: Vector3
var angular_speed: Vector3


func _ready():
	$CameraRig.top_level = true
	$FloorCheck.top_level = true
	beetle_pos = $Escarabajo.global_transform.origin
	$Escarabajo.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	contact_monitor = true
	max_contacts_reported = 500
	

func _physics_process(delta: float):
	prev_speed = linear_velocity
	$FloorCheck.global_transform.origin = global_transform.origin
	
	# Mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			player_freeze()
			paused.emit()
			
	if not started and not Input.is_action_just_pressed("ui_cancel"):
		if Input.is_anything_pressed():
			started = true

	# Camera follow
	$CameraRig.global_transform.origin = lerp(
		$CameraRig.global_transform.origin, 
		global_transform.origin,
		0.1
	)
	if ($CameraRig.global_transform.origin - $".".global_transform.origin).length() > 0.1:
		$CameraRig.look_at($".".global_transform.origin, Vector3.DOWN)
	$CameraRig.global_transform.origin.y = global_transform.origin.y + 0.5


	# Beetle follow
	$Escarabajo.global_transform.origin = Vector3(
		global_transform.origin.x + beetle_pos.x,
		global_transform.origin.y + beetle_pos.y - 1.72,
		global_transform.origin.z + beetle_pos.z
	)
	# Beetle direction
	$Escarabajo.global_basis.z = angular_velocity.normalized().rotated(Vector3.DOWN, -PI / 2)
	$Escarabajo.global_basis.z.y = 0
	$Escarabajo.global_basis.z = $Escarabajo.global_basis.z.normalized() * 0.077
	$Escarabajo.global_basis.x = angular_velocity.normalized().rotated(Vector3.DOWN, -PI) * 0.077
	$Escarabajo.global_basis.x.y = 0
	$Escarabajo.global_basis.x = $Escarabajo.global_basis.x.normalized() * 0.077

			
	# GAMEPLAY
	if started:
		rolling_force = rolling_speed
		
		# Sprint
		if is_running:
			rolling_force = rolling_force * 1.5
			is_running = false

		# Get fordward direction of ball
		var total_plane_size = $CameraRig/Camera3D.global_transform.basis.x.x + $CameraRig.global_transform.basis.x.z
		if (total_plane_size != 0):
			fordward_orientation = Vector2(
				$CameraRig/Camera3D.global_transform.basis.x.x / total_plane_size,
				$CameraRig/Camera3D.global_transform.basis.x.z / total_plane_size
			)

		move_ball(delta)
		#ball_movement(delta)
		#camera_movement()
		#game_process(delta)


func gameover():
	$Ball.free()
	$Collision.free()
	$Escarabajo/AnimationPlayer2.free()
	game_over.emit()
	#queue_free()

func move_ball(delta: float) -> void:
	var oldCameraPos = $CameraRig.global_transform.origin
	var ballPos = global_transform.origin
	var newCameraPos = lerp(oldCameraPos, ballPos, 0.1)
	$CameraRig.global_transform.origin = newCameraPos
	var input_dir = Input.get_vector("move_forward", "move_back", "move_right", "move_left")
	var camera_forward = $CameraRig.global_transform.basis.z.normalized()

	angular_velocity = angular_velocity.lerp((Vector3.UP.cross(camera_forward).normalized() * rolling_force * input_dir.x), delta * 5)
	angular_velocity = angular_velocity.lerp((camera_forward.normalized() * rolling_force * input_dir.y), delta * 5)
	
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

func ball_movement(delta: float) -> void:
	if Input.is_action_pressed("move_forward"):
		new_angular_v_x = angular_velocity.x * (1 + abs(fordward_orientation.x) * rolling_force * delta * sign(fordward_orientation.x))
		angular_velocity.x = new_angular_v_x
		new_angular_v_z = angular_velocity.z * (1 + abs(fordward_orientation.y) * rolling_force * delta * sign(fordward_orientation.y))
		angular_velocity.z = new_angular_v_z

	elif Input.is_action_pressed("move_back"):
		angular_velocity.x = angular_velocity.x * \
			clamp(1 - abs(fordward_orientation.x) * rolling_force / 10 * delta * sign(fordward_orientation.x), 0.8, 1)
		angular_velocity.x = angular_velocity.z * \
			clamp(1 - abs(fordward_orientation.y) * rolling_force / 10 * delta * sign(fordward_orientation.y), 0.8, 1)

	if Input.is_action_pressed("move_left"):
		print("Going left")
		print(sideways_orientation)
		print(angular_velocity)
		angular_velocity.x = angular_velocity.x * \
		(1 + abs(fordward_orientation.y) * rolling_force * delta * -sign(fordward_orientation.y))
		angular_velocity.z = angular_velocity.z * \
		(1 + abs(fordward_orientation.x) * rolling_force * delta * sign(sideways_orientation.x))
		print(angular_velocity)

	elif Input.is_action_pressed("move_right"):
		angular_velocity.x = angular_velocity.x * \
		(1 + abs(fordward_orientation.y) * rolling_force * delta * sign(fordward_orientation.y))
		angular_velocity.z = angular_velocity.z * \
		(1 + abs(fordward_orientation.x) * rolling_force * delta * -sign(fordward_orientation.x))
		
	angular_velocity = angular_velocity.clamp(angular_velocity.normalized() * -20, angular_velocity.normalized() * 20)


func player_freeze() -> void:
	pause = true
	linear_speed = linear_velocity
	linear_velocity = Vector3.ZERO
	angular_speed = angular_velocity
	angular_velocity = Vector3.ZERO
	set_physics_process(false)
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0)
	
	
func player_unfreeze() -> void:
	pause = false
	set_physics_process(true)
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, -490)
	linear_velocity = linear_speed
	angular_velocity = angular_speed

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if not pause:
		print("Collision")
		var impact = prev_speed.length() - linear_velocity.length()
		print(impact)
		if impact > impact_gameover:
			gameover()


func _on_control_resumed() -> void:
	player_unfreeze()

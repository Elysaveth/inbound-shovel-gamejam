@tool
extends MeshInstance3D

const size := 256.0

#@export_group("Parameters")
@export_range(1.0,2.0, 0.01) var slope := 2.0:
	set(new_slope):
		slope = new_slope
		update_mesh()

#@export_group("Tools")
@export var reload := false :
	set(new_reload):
		reload = false
@export_range(4,256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		update_mesh()
@export var noise: FastNoiseLite:
	set(new_noise):
		noise = new_noise
		update_mesh()
		if noise:
			noise.changed.connect(update_mesh)
@export_range(4.0, 128.0, 4.0) var height := 64.0:
	set(new_height):
		height = new_height
		material_override.set_shader_parameter("height", height * 8)
		update_mesh()
		
var pick: Vector3

func _ready() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	create_trimesh_collision()

func get_height(x: float, y: float) -> float:
	var distance: float = Vector2().distance_to(Vector2(x, y)) / slope
	var current_height = noise.get_noise_2d(x, y) * height - distance + 1
	if current_height > pick.y:
		pick = Vector3(x, current_height, y)
	return current_height
	#return 0
	
func get_normal(x: float, y: float) -> Vector3:
	var epsilon := size / resolution
	var normal := Vector3(
		(get_height(x + epsilon, y) - get_height(x - epsilon, y) / (2.0 * epsilon)),
		1.0,
		(get_height(x, y + epsilon) - get_height(x, y - epsilon) / (2.0 * epsilon))
	)
	return normal.normalized()


func update_mesh() -> void:
	pick = Vector3(0.0, 0.0, 0.0)
	var plane := PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size, size)

	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	for i: int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = get_height(vertex.x, vertex.z)
			normal = get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
		

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mesh
	print(pick)

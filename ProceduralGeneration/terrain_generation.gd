class_name TerrainGeneration
extends Node

@export_group("Mesh Config")
@export var size_depth : int = 100
@export var size_width : int = 100
@export var mesh_resolution : int = 2
@export var draw_distance : int = 200
var subdiv = mesh_resolution * min(size_depth, size_width)


@export_group("Noise Config")
@export var noise : FastNoiseLite
@export var noise_modifier : int = 40
#var mesh_generator := MeshGenerator.new()
var world : Array


func _ready():
	pass
	#generate_terrain(Vector3(0,0,0))
	
func generate_terrain(player_position: Vector3) -> void:
	var subdivisions = mesh_resolution * size_depth
	for i: int in (2 * draw_distance / size_width + 1):
		for j: int in (2 * draw_distance / size_depth + 1):
			var index = i * (2 * draw_distance / size_depth + 1) + j
			print(index)
			var x: int = i * size_depth + size_depth / 2
			var z: int = j * size_depth + size_depth / 2
			var mesh : MeshInstance3D =  generate_mesh()
			add_child(mesh)
			mesh.global_transform.origin = Vector3(x, 0, z)
			mesh.global_transform.origin = Vector3()


func generate_mesh() -> MeshInstance3D:
	# Create plane with size and material
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * mesh_resolution
	plane_mesh.subdivide_width = size_width * mesh_resolution
	plane_mesh.material = preload("res://ProceduralGeneration/Materials/TerrainMaterial.tres")
	
	# Create surface
	var surface := SurfaceTool.new()
	var data := MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	var array_plane : ArrayMesh = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	# Set height of each point
	for i: int in range(data.get_vertex_count()):
		var vertex : Vector3 = data.get_vertex(i)
		#vertex.y = no_noise_y(vertex.x, vertex.z)
		vertex.y = noise_y(vertex.x, vertex.z)
		#vertex.y = hill_noise_y(vertex.x, vertex.z)
		data.set_vertex(i, vertex)
		
		array_plane.clear_surfaces()
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()
	
	# Create final mesh with collisions and shadows
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh



func find_center() -> Vector3:
	var center := Vector3(0,0,0)
	return center
	
func noise_y(x: float, z: float) -> float:
	var value := noise.get_noise_2d(x, z)
	return value * noise_modifier

func no_noise_y(_x: float, _z: float) -> float:
	return 0
	
func hill_noise_y(x:float, z: float) -> float:
	var value = noise_y(x, z)
	return value

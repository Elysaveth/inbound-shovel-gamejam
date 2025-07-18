@tool
class_name MeshGenerator
extends MeshInstance3D

@export var reload := false :
	set(new_reload):
		reload = false
		regenerate_mesh()
		
@export_range(1, 32) var subdivisions := 1 :
	set(new_subdivisions):
		subdivisions = new_subdivisions
		regenerate_mesh()
		
@export_group("Mesh Config")
@export var size_depth : int = 100
@export var size_width : int = 100
@export var mesh_resolution : int = 2

@export_group("Noise Config")
@export var noise : FastNoiseLite
@export var noise_modifier : int = 40
		
var array_mesh: ArrayMesh
var godot_mesh : MeshInstance3D

func _ready() -> void:
	pass
	#regenerate_mesh()
	
func regenerate_mesh() -> void:
	if !array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh
	array_mesh.clear_surfaces()
	var surface_array := create_plane(subdivisions, 0, Vector3.UP, Vector3(0,0,0), Vector2(1,1))
	#var surface_array := create_sphere(subdivisions)
	#var surface_array := create_cube(subdivisions)
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
func generate_plane(subdiv: int, index: int, dir: Vector3, center: Vector3, size: Vector2) -> MeshInstance3D:
	if !array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh
	array_mesh.clear_surfaces()
	var surface_array := create_plane(subdiv, index, dir, center, size)
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	self.create_trimesh_collision()
	self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return self
	
func generate_cube(subdiv: int, size: Vector2) -> MeshInstance3D:
	if !array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh
	array_mesh.clear_surfaces()
	var surface_array := create_cube(subdiv, size)
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	print(surface_array[Mesh.ARRAY_INDEX])
	self.create_trimesh_collision()
	self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return self
	
func generate_sphere(subdiv: int, size: Vector2) -> MeshInstance3D:
	if !array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh
	array_mesh.clear_surfaces()
	var surface_array := create_sphere(subdiv, size)
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	self.create_trimesh_collision()
	self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return self
	
	# dubdiv: number of rectangles
	# index: last index used to not override index previous plane
	# dir: normal direction of the plane
	# center: center of the plane
func create_plane(subdiv: int, index: int, dir: Vector3, center: Vector3, size: Vector2) -> Array:
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	dir = dir.normalized()
	var binormal := size.x * Vector3(dir.z, dir.x, dir.y) / subdiv
	var tangent := size.y * binormal.rotated(dir, PI / 2.0) / size.x
	var offset := -subdiv * (binormal + tangent) / 2.0 + center
	
	for x: int in subdiv:
		for y: int in subdiv:
			var vertex_offset := binormal * x + tangent * y + offset + Vector3(0, hill_noise_y(x, y), 0)
			var index_offset := 4 * (x * subdiv + y) + index
			
			positions.append_array([
				vertex_offset,
				vertex_offset + tangent,
				vertex_offset + binormal + tangent,
				vertex_offset + binormal
			])
			
			normals.append_array([
				dir, dir, dir, dir
			])
			
			indices.append_array([
				index_offset, index_offset + 1, index_offset + 2,
				index_offset, index_offset + 2, index_offset + 3
			])
	
	surface_array[Mesh.ARRAY_VERTEX] = positions
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	return surface_array
	
func create_cube(subdiv: int, size: Vector2) -> Array:
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	const directions: PackedVector3Array = [
		Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK
	]
	
	for i: int in directions.size():
		var index := 4 * i * subdiv * subdiv
		var plane := create_plane(subdiv, index, directions[i], directions[i] / 2.0, size)
		positions.append_array(plane[Mesh.ARRAY_VERTEX])
		normals.append_array(plane[Mesh.ARRAY_NORMAL])
		indices.append_array(plane[Mesh.ARRAY_INDEX])
	
	surface_array[Mesh.ARRAY_VERTEX] = positions
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	return surface_array
	
func create_sphere(subdiv: int, size: Vector2) -> Array:
	var surface_array := create_cube(subdiv, size)
	
	for i: int in surface_array[Mesh.ARRAY_VERTEX].size():
		var vertex: Vector3 = surface_array[Mesh.ARRAY_VERTEX][i]
		surface_array[Mesh.ARRAY_VERTEX][i] = vertex.normalized() / 2.0
		surface_array[Mesh.ARRAY_NORMAL][i] = vertex.normalized()
		
	return surface_array
		

func generate_mesh_godot():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = size_depth * mesh_resolution
	plane_mesh.subdivide_width = size_width * mesh_resolution
	plane_mesh.material = preload("res://ProceduralGeneration/Materials/TerrainMaterial.tres")
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		vertex.y = noise_y(vertex.x, vertex.z)
		data.set_vertex(i, vertex)
		
		array_plane.clear_surfaces()
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.generate_normals()
	
	godot_mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	#mesh.add_to_group("NavSource") # (Optional) Used for navigation


func noise_y(x: float, z: float) -> float:
	var value := noise.get_noise_2d(x, z)
	return value * noise_modifier

func no_noise_y(_x: float, _z: float) -> float:
	return 0
	
func hill_noise_y(x:float, z: float) -> float:
	var value = noise_y(x, z)
	
	return value

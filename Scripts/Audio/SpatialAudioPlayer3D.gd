class_name SpatialAudioPlayer3D extends AudioStreamPlayer3D
#Max distance a raycast will travel before stopping
@export var max_raycast_distance:float = 30.0
#Max time before each update
@export var update_frequencey_seconds:float = 0.5
#Max amount of reverb will apply to the Audio
@export var max_reverb_wetness:float = 0.5 
#Lowpass cutout amount if the listener is behind a wall
@export var wall_lowpass_cutoff_amount:int = 600


#tracking parameters
#Will contain all raycasts
var _raycast_array:Array = []
#Updated Distance Array
var _distance_array:Array = [0,0,0,0,0,0,0,0,0,0]
# Time since last spatial update
var _last_update_time:float = 0.0
# should distances be updated
var _update_distances:bool = true
#The current raycast to be updated
var _current_raycast_index:int  = 0

var _audio_bus_idx = null
var _audio_bus_name = ""

#Effects
var _reverb_effect:AudioEffectReverb
var _lowpass_filter:AudioEffectLowPassFilter

#Target Parameters (Will lerp to these values)
var _target_lowpass_cutoff:float = 20000.0
var _target_reverb_room_size:float = 0.0
var _target_reverb_wetness:float = 0.0
var _target_volume_db:float = 0.0


func _ready():
	_audio_bus_idx = AudioServer.bus_count
	_audio_bus_name = "SpatialBus#"+str(_audio_bus_idx)
	AudioServer.add_bus(_audio_bus_idx)
	AudioServer.set_bus_name(_audio_bus_idx,_audio_bus_name)
	AudioServer.set_bus_send(_audio_bus_idx,bus)
	self.bus = _audio_bus_name
	
	#Add effects to the custom audio_bus
	AudioServer.add_bus_effect(_audio_bus_idx,AudioEffectReverb.new(),0)
	_reverb_effect = AudioServer.get_bus_effect(_audio_bus_idx,0)
	AudioServer.add_bus_effect(_audio_bus_idx,AudioEffectLowPassFilter.new(),1)
	_lowpass_filter = AudioServer.get_bus_effect(_audio_bus_idx,1)
	_target_volume_db = volume_db
	volume_db = -60.0
	$RaycastDown.target_position = Vector3(0,-max_raycast_distance,0)
	$RaycastLeft.target_position = Vector3(max_raycast_distance,0,0)
	$RaycastRight.target_position = Vector3(-max_raycast_distance,0,0)
	$RaycastForward.target_position = Vector3(0,0,max_raycast_distance)
	$RaycastForwardLeft.target_position = Vector3(0,0,max_raycast_distance)
	$RaycastForwardRight.target_position = Vector3(0,0,max_raycast_distance)
	$RaycastBackwardRight.target_position = Vector3(0,0,-max_raycast_distance)
	$RaycastBackwardLeft.target_position = Vector3(0,0,-max_raycast_distance)
	$RaycastBackward.target_position = Vector3(0,0,-max_raycast_distance)
	$RaycastUp.target_position = Vector3(0,max_raycast_distance,0)
	
	#Adding them to array to work with them better
	_raycast_array.append($RaycastDown)
	_raycast_array.append($RaycastLeft)
	_raycast_array.append($RaycastRight)
	_raycast_array.append($RaycastForward)
	_raycast_array.append($RaycastForwardLeft)
	_raycast_array.append($RaycastForwardRight)
	_raycast_array.append($RaycastBackwardRight)
	_raycast_array.append($RaycastBackwardLeft)
	_raycast_array.append($RaycastBackward)
	_raycast_array.append($RaycastUp)

func _on_update_raycast_distance(raycast:RayCast3D,raycast_index:int):
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider != null:
		_distance_array[raycast_index] = self.global_position.distance_to(raycast.get_collision_point())
	else:
		_distance_array[raycast_index] = -1
	raycast.enabled = false
#if you want more effects you can make functions and add them here.... looking at you lagula
func _on_update_spatial_audio(player:Node3D):
	_on_update_reverb(player)
	_on_update_lowpass_filter(player)
func _on_update_reverb(_player:Node3D):
	if _reverb_effect != null:
		var room_size = 0.0
		var wetness = 1.0
		for dist in _distance_array:
			if dist >= 0:
				room_size += (dist/ max_raycast_distance)/ (float(_distance_array.size()))
				room_size = min(room_size,1.0)
			else:
				wetness -= 1.0 /float(_distance_array.size())
				wetness = max(wetness,0.0)
		_target_reverb_wetness = wetness
		_target_reverb_room_size = room_size

func _on_update_lowpass_filter(_player:Node3D):
	if _lowpass_filter  != null:
		var query = PhysicsRayQueryParameters3D.create(self.global_position,self.global_position + (_player.global_position - self.global_position).normalized() * max_raycast_distance, $RaycastForward.get_collision_mask())
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		var lowpass_cutoff = 20000 #init to a value where nothing gets cutoff
		if !result.is_empty():
			var ray_distance = self.global_position.distance_to(result["position"])
			var distance_to_player = self.global_position.distance_to(_player.global_position)
			var wall_to_player_ratio = ray_distance / max(distance_to_player,0.001)
			if ray_distance < distance_to_player:
				lowpass_cutoff = wall_lowpass_cutoff_amount * wall_to_player_ratio
		_target_lowpass_cutoff = lowpass_cutoff



func _lerp_parameters(delta):
	volume_db = lerp(volume_db,_target_volume_db,delta)
	_lowpass_filter.cutoff_hz = lerp(_lowpass_filter.cutoff_hz,_target_lowpass_cutoff,delta * 5.0)
	_reverb_effect.wet = lerp(_reverb_effect.wet,_target_reverb_wetness * max_reverb_wetness,delta * 5.0)
	_reverb_effect.room_size = lerp(_reverb_effect.room_size,_target_reverb_room_size,delta * 5.0)




func _physics_process(delta):
	_last_update_time += delta
	if _update_distances:
		_on_update_raycast_distance(_raycast_array[_current_raycast_index],_current_raycast_index)
		_current_raycast_index += 1
		if _current_raycast_index >= _distance_array.size():
			_current_raycast_index = 0
			_update_distances = false
	
	if _last_update_time > update_frequencey_seconds:
		var player_camera = get_viewport().get_camera_3d()
		if player_camera != null:
			_on_update_spatial_audio(player_camera)
		_update_distances = true
		_last_update_time = 0.0
	_lerp_parameters(delta)
	
	
	

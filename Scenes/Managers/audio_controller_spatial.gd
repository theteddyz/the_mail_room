extends Node

# ALERT:THIS SCRIPT SHOULD NOT BE USED ON ITS OWN, STRICTLY CALL ITS FUNCTIONS THROUGH THE AUDIOCONTROLLER NODE

enum SoundModifiers {
	none = 0,
	fade_in = 1,   
	fade_out = 2,
	set_db = 3
}

func play_spatial_resource(sound, pos, modifiers = 0, callback = (func(): {})):
	var p = AudioStreamPlayer3D.new()
	add_child(p)
	# Set Sound Position
	if pos == Vector3.ZERO:
		# Random Position
		
		p.global_position = Vector3.ZERO
		if GameManager.world_reference != null:
			var navmesh = GameManager.world_reference.find_child("NavigationRegion3D")
			if navmesh != null:
				var point = NavigationServer3D.map_get_random_point(navmesh.get_navigation_map(), navmesh.get_navigation_layers(), false)
				point += Vector3(0, 2, 0)
				p.global_position = point
	else:
		# Pre-determined position
		p.global_position = pos
		
	if sound is Resource:
		p.stream = sound
	else:
		print("play_spatial_resource expects a resource... sound not fired!")
		return
	apply_effector(modifiers, p)
	p.finished.connect(callback)
	p.finished.connect(func(): p.queue_free())
	p.playing = true

func apply_effector(modifier, player: AudioStreamPlayer3D):
	var set_db = 0
	if modifier is Array:
		for m in modifier:
			match m:
				SoundModifiers.fade_in:
					var tween = get_tree().create_tween()
					player.volume_db = -35
					tween.tween_property(player, "volume_db", set_db, 4.85).set_ease(Tween.EASE_OUT)
				SoundModifiers.fade_out:
					var tween = get_tree().create_tween()
					tween.tween_property(player, "volume_db", -45, 4.85).set_ease(Tween.EASE_OUT)
					tween.tween_callback(func(): player.playing = false)
					tween.tween_property(player, "volume_db", set_db, 0)
				#SoundModifiers.set_db:
					## Currently just sets the DB to a "loud"-ish value
					#player.volume_db = 13
					#set_db = 13
	else:
		match modifier:
			SoundModifiers.fade_in:
				var tween = get_tree().create_tween()
				player.volume_db = -35
				tween.tween_property(player, "volume_db", set_db, 4.85).set_ease(Tween.EASE_OUT)
			SoundModifiers.fade_out:
				var tween = get_tree().create_tween()
				tween.tween_property(player, "volume_db", -45, 4.85).set_ease(Tween.EASE_OUT)
				tween.tween_callback(func(): player.playing = false)
				tween.tween_property(player, "volume_db", set_db, 0)
			#SoundModifiers.set_db:
				## Currently just sets the DB to a "loud"-ish value
				#player.volume_db = 13
				#set_db = 13

extends Interactable

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_door_close: AudioStreamPlayer3D = $AudioDoorClose
@onready var audio_door_open: AudioStreamPlayer3D = $AudioDoorOpen

var is_open: bool = false

func interact():
	if is_open:
		animation_player.play("door_close")
		is_open = false
		audio_door_close.play()
	else:
		animation_player.play("door_open")
		is_open = true
		audio_door_open.play()

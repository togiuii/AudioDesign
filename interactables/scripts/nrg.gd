extends Interactable

@export var speed_boost_amount: float = 25.0
@export var boost_duration: float = 30.0
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func interact():
	audio_stream_player_3d.play()
	# 1. Oyuncuyu gruptan bul
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# --- YENİ: Oyuncunun audioplayer2 düğümünü bul ve oynat ---
		var player_audio = player.get_node_or_null("audioplayer2")
		if player_audio:
			player_audio.play()
		else:
			# Eğer isim farklıysa veya hiyerarşide değilse burası çalışır
			print("Hata: Oyuncu hiyerarşisinde 'audioplayer2' bulunamadı!")

		# 2. Hız artışını uygula
		apply_speed_boost(player)
		
		# 3. Item'ı dünyadan gizle/kapat
		visible = false 
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)

func apply_speed_boost(player):
	var original_speed = player.SPEED
	player.SPEED += speed_boost_amount
	
	await get_tree().create_timer(boost_duration).timeout
	
	if is_instance_valid(player):
		player.SPEED = original_speed
	
	queue_free()

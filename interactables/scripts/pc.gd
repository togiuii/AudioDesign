extends Interactable

# Sahneyi belleğe yükle
var target_scene =preload("uid://xo0dgtbgwfkn")
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var label_3d: Label3D = $Label3D 
@onready var spot1: SpotLight3D = $"../SpotLight3D2"
@onready var spot2: SpotLight3D = $"../SpotLight3D2/SpotLight3D2"
@onready var spotsound: AudioStreamPlayer3D = $"../SpotLight3D2/spotsound"

@export_group("İçerik Ayarları")
@export var audio_sequence: Array[AudioStream] = []
@export var text_sequence: Array[String] = [] 

var current_index: int = 0
var is_typing: bool = false 


@export var spawn_point: Marker3D

func spawn_at_marker():
	var instance = target_scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = spawn_point.global_position

func interact():
	# Yazma işlemi devam ediyorsa veya ses çalıyorsa yeni etkileşimi engelle
	if is_typing or audio_player.is_playing() or audio_sequence.size() == 0:
		return
	
	# --- YENİ: Sahneyi oluşturma fonksiyonunu burada çağırıyoruz ---
	if current_index == 2:
		spawn_at_marker()
		spot1.visible = true
		spot2.visible = true
		spotsound.play()
	
	# 1. Ses ve Metni Al
	var full_text = ""
	audio_player.stream = audio_sequence[current_index]
	
	if current_index < text_sequence.size():
		full_text = text_sequence[current_index]
	
	# 2. İşlemleri Başlat
	audio_player.play()
	write_text_step_by_step(full_text)
	
	# 3. İndeksi artır
	current_index = (current_index + 1) % audio_sequence.size()

func write_text_step_by_step(full_metin: String):
	is_typing = true
	label_3d.text = "" # Önce yazıyı tamamen temizle
	
	var total_chars = full_metin.length()
	var audio_length = audio_player.stream.get_length()
	
	# Karakter başına bekleme süresi
	var wait_time = audio_length / max(1, total_chars)
	
	# DÖNGÜ: Metni baştan sona harf harf ekleyerek yazdır
	for i in range(1, total_chars + 1):
		# left(i) fonksiyonu metnin solundan i kadar karakteri alır
		label_3d.text = full_metin.left(i)
		
		# Her harf eklendiğinde ses süresine göre bekle
		await get_tree().create_timer(wait_time).timeout
	
	is_typing = false
	
	# Yazı bittikten 3 saniye sonra temizle
	await get_tree().create_timer(3.0).timeout
	if not is_typing: 
		label_3d.text = ""

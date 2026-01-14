extends CharacterBody3D
class_name Player

@export_group("Ayak Sesi Ayarları")
@export var step_distance: float = 2.5 # Ne kadar mesafede bir adım sesi çalacak? (Hızına göre ayarla)
@export var min_pitch: float = 0.85     # En düşük perde
@export var max_pitch: float = 1.15     # En yüksek perde
@export var step_cooldown: float = 0.3 # İki adım sesi arasındaki minimum süre (saniye)

@onready var footstep_player: AudioStreamPlayer3D = $AudioStreamPlayer3D 
var distance_walked: float = 0.0 # Kat edilen mesafeyi tutar
var time_since_last_step: float = 0.0 # Son adımdan beri geçen süre

@onready var SPEED = 5
@onready var JUMP_VELOCITY = 4.5
@onready var SENSITIVITY = 300

@onready var head: Node3D = %Head
@onready var raycast: RayCast3D = %RayCast3D

@onready var GRAVITY = 9.8
var cursor_locked = true
var current_interactable = null


func _ready() -> void:
	#Mouse gizlemek için
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Mouse kullanarak kafayı hareket ettirebilmek
func _input(event: InputEvent) -> void:
	
	if not event is InputEventMouseMotion:
		return
		
	#Kafa rotationu kodu, sondaki "/ SENSITIVITY * PI" kısmını rotate_y ve rotate_x parantezlerinin sonuna da
	#koyabilirdik, fakat ikisinde de aynısı geçerli olacağından dolayı tek bir yerde oluşturduk ve kullanıyoruz
	var MOUSE_MOVEMENT:Vector2 = event.relative / SENSITIVITY * PI
	self.rotate_y(-MOUSE_MOVEMENT.x)
	head.rotate_x(-MOUSE_MOVEMENT.y)
	#Kafamızın yukarı ve aşağı bakabileceği açıları limitliyoruz
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

#Input sistemleri
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("activate"):
		activate()


func _physics_process(delta: float) -> void:
	# Cooldown sayacını her karede ilerlet
	time_since_last_step += delta
	# 1. Yerçekimi Uygula
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# 2. Zıplama Kontrolü
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Hareket Yönünü Hesapla (Sadece physics_process içinde)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Karakterin baktığı yöne göre yönü belirle
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		# Hareket varsa hızı ayarla
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Hareket yoksa hızı yavaşça sıfırla (Kaymayı önlemek için)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. Hareketi Fizik Motoruna Bırak
	# move_and_slide() 'velocity' değişkenini otomatik kullanır ve delta ile çarpmanıza gerek kalmaz.
	move_and_slide()
	
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z).length()
	
	if is_on_floor() and horizontal_velocity > 0.5:
		# Gittiğimiz mesafeyi biriktiriyoruz
		distance_walked += horizontal_velocity * delta
		
		# Belirlediğimiz adım mesafesine ulaştıysak sesi çal
		if distance_walked >= step_distance:
			play_footstep()
			distance_walked = 0.0 # Mesafeyi sıfırla
			time_since_last_step = 0.0  # Zamanlayıcıyı sıfırla
	else:
		# Durduğumuzda veya havada olduğumuzda bir sonraki adım için mesafeyi sıfırlayabiliriz
		# Bu sayede her yürümeye başladığında ilk adım hemen çalar.
		distance_walked = move_toward(distance_walked, step_distance * 0.8, 0.1)
	
	# Etkileşim kontrolü
	check_hover_collision()
#Mouse modunu togglelamak için çağıracağım fonksiyon
func toggle_cursor_mode():
	cursor_locked = !cursor_locked
	if cursor_locked:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

#Interaction sistem scripti
func activate():
	if cursor_locked and raycast.is_colliding(): 
		var hit = raycast.get_collider() 
		if hit is Interactable:
			hit.interact()
			hide_current_interaction()



@onready var interaction_icon: TextureRect = $ui/CenterContainer/TextureRect


func check_hover_collision():
	if raycast.is_colliding():
		var hover_collider = raycast.get_collider()
		
		# Artık sadece "interact" classına bakıyoruz
		if hover_collider is Interactable:
			if current_interactable != hover_collider:
				current_interactable = hover_collider
				show_interaction_ui(true)
		else:
			# Baktığımız şey etkileşimli değilse gizle
			hide_current_interaction()
	else:
		# Hiçbir şeye bakmıyorsak gizle
		hide_current_interaction()

func show_interaction_ui(is_visible: bool):
	if interaction_icon:
		interaction_icon.visible = is_visible

func hide_current_interaction():
	current_interactable = null
	show_interaction_ui(false)



func hide_current_prompt():
	if current_interactable:
		current_interactable.hide_prompt()
		current_interactable = null

func play_footstep():
	if footstep_player:
		# Pitch (perde) ayarını rastgele yapıyoruz
		footstep_player.pitch_scale = randf_range(min_pitch, max_pitch)
		# Sesi oynat
		footstep_player.play()

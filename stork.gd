extends CharacterBody2D

# Vertical motion
@export var gravity: float = 400
@export var flap_impulse: float = 200
@export var max_fall_speed: float = 200
@export var dive_gravity_multiplier: float = 2.0
@export var dive_max_fall_speed: float = 400

# Horizontal motion
@export var air_speed: float = 140
@export var ground_speed: float = 80
@export var air_control: float = 1.0     # <1 = looser control in air
@export var ground_friction: float = 0.2 # slowdown on ground when no input

var input_locked := false
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("glide")
	anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	# --- Horizontal input (custom actions) ---
	var dir := Input.get_action_strength("right") - Input.get_action_strength("left")
	var current_speed := (ground_speed if is_on_floor() else air_speed)
	var target_vx := dir * current_speed
	var control := (air_control if not is_on_floor() else 1.0)
	velocity.x = lerp(velocity.x, target_vx, control)

	if is_on_floor() and dir == 0:
		velocity.x = lerp(velocity.x, 0.0, ground_friction)

	if abs(velocity.x) > 1.0:
		anim.flip_h = velocity.x < 0.0

	# --- Vertical motion (gravity + flap + dive) ---
	var g := gravity
	var fall_cap := max_fall_speed
	var diving := Input.is_action_pressed("dive") and not is_on_floor()
	if diving:
		g *= dive_gravity_multiplier
		fall_cap = dive_max_fall_speed

	velocity.y = min(velocity.y + g * delta, fall_cap)

	if not input_locked and Input.is_action_just_pressed("flap"):
		velocity.y = -flap_impulse
		input_locked = true
		anim.play("flap")
		if $AudioStreamPlayer2D:
			$AudioStreamPlayer2D.play()

	move_and_slide()

	# --- Animation state ---
	if input_locked:
		return

	_update_anim(diving)

func _on_anim_finished() -> void:
	input_locked = false
	_update_anim(Input.is_action_pressed("dive") and not is_on_floor())

func _update_anim(diving: bool) -> void:
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			if anim.animation != "walk" or not anim.is_playing():
				anim.play("walk")
		else:
			if anim.animation != "idle" or not anim.is_playing():
				anim.play("idle")
		return

	# Airborne
	if diving:
		if anim.animation != "dive" or not anim.is_playing():
			anim.play("dive")     # set to Loop in SpriteFrames
	else:
		if anim.animation != "glide" or not anim.is_playing():
			anim.play("glide")    # loop

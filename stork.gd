extends CharacterBody2D

@export var gravity: float = 400
@export var flap_impulse: float = 200
@export var max_fall_speed: float = 200

var input_locked := false

func _ready() -> void:
	$AnimatedSprite2D.play("glide")
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)

	if not input_locked and Input.is_action_just_pressed("flap"):
		velocity.y = -flap_impulse
		input_locked = true
		$AnimatedSprite2D.play("flap")
		$AudioStreamPlayer2D.play()

	move_and_slide()

	# Check floor after moving
	if is_on_floor() and not input_locked:
		$AnimatedSprite2D.play("idle")

func _on_anim_finished() -> void:
	input_locked = false
	# Only go back to glide if we're in the air
	if not is_on_floor():
		$AnimatedSprite2D.play("glide")
	else:
		$AnimatedSprite2D.play("idle")

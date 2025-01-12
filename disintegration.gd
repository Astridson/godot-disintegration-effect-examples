extends GPUParticles2D


func _ready() -> void:
	one_shot = true
	start()


func start() -> void:
	restart()
	emitting = true
	var frac: float = process_material.get_shader_parameter("particle_lifetime_fraction")
	set_progress(0.0)

	var tween := create_tween()
	tween.tween_method(set_progress, 0.0, 1.0, lifetime * (1.0 - frac))
	tween.tween_callback(start).set_delay(lifetime * frac)


func set_progress(value: float):
	process_material.set_shader_parameter("progress", value)

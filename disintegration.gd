extends Particles2D


func _ready() -> void:
	one_shot = true
	start()


func start() -> void:
	restart()
	emitting = true
	var frac: float = process_material.get("shader_param/particle_lifetime_fraction")
	process_material.set("shader_param/progress", 0.0)

	var tween := get_tree().create_tween()
	tween.tween_property(process_material, "shader_param/progress", 1.0, lifetime * (1.0 - frac))
	tween.tween_callback(self, "start").set_delay(lifetime * frac)
	

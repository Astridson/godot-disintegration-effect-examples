# godot-disintegration-effect-examples

Examples of disintegration effects with godot 2d particle shaders

![examples](effects.gif)

## Creating a disintegration effect

The following process can be followed to create a similar effect starting from any particles material. The full source code for this example can be found in [undertale.tres](shaders/undertale.tres).

1. Set up a Particle2D node with the desired parameters and convert the ParticlesMaterial to a ShaderMaterial
2. Set explosiveness to 1 and the particle amount to the number of pixels in the image
3. Add a uniform to pass in the image that will be disintegrated

```glsl
        uniform sampler2D sprite;
```

4. In the vertex function calculate a starting position for each particle from its `base_number`

```glsl
        ivec2 sprite_size = textureSize(sprite, 0);
      	int x = int(base_number) % sprite_size.x;
        int y = (int(base_number) / sprite_size.x) % sprite_size.y;
        ivec2 starting_position = ivec2(x, y);
```

5. In the restart block set the particles position, kept in `TRANSFORM[3]` to the starting position
        
```glsl
        TRANSFORM[3].xy = vec2(starting_position);
```

6. Remove the `color_value` uniform and replace it with a variable that gets the color from the particles starting position in the image, deactivate the particle if it is fully transparent
        
```glsl
        vec4 color_value = texelFetch(sprite, starting_position, 0);
        if (color_value.a == 0.0) { ACTIVE = false; }
```

7. Add a uniform to control the fraction of the lifetime a particle will be displayed, this is needed to compensate for the time the effect takes to complete
        
```glsl
        uniform float particle_lifetime_fraction : hint_range(0.0, 1.0, 0.01);
```

8. The variable `tv` holds the fraction of particle lifetime elapsed, adjust it by `particle_lifetime_fraction`
        
```glsl
        tv = clamp(CUSTOM.y / CUSTOM.w / particle_lifetime_fraction, 0.0, 1.0);
```

9. Add a uniform to control the fraction of the sprite disintegrated
        
```glsl
        uniform float progress : hint_range(0.0, 1.0, 0.01);
```

10. The else block should only run on particles that have disintegrated, ie. particles in the top fraction of the image, replace the else with an else if

```glsl
        } else if (float(starting_position.y) / float(sprite_size.y) < progress) {
```

11. The particle position is by default automatically calculated using the value in `VELOCITY`, to calculate it manually add the `disable_velocity` render mode
        
```glsl
        render_mode disable_velocity;
```
12. In the above else if block manualy calculate the new position

```glsl
        TRANSFORM[3].xyz += VELOCITY * DELTA;
```

13. Add a script to the Particle2D to tween the progress uniform. The tween should take `lifetime * (1 - particle_lifetime_fraction)` to complete so that the last particles will fully fade in `lifetime` seconds

```gdscript
        func start():
            restart()
            emitting = true
            var frac = process_material.get("shader_param/particle_lifetime_fraction")
            process_material.set("shader_param/progress", 0.0)
            var tween = get_tree().create_tween()
            
            tween.tween_property(process_material,
                      "shader_param/progress",
                      1.0,
                      lifetime * (1.0 - frac))
```
	
14. (Optional) The resulting shader potentially contains many lines using unused uniforms which can be removed to improve performance. The cleaned up shader can be found in [undertale_cleaned.tres](shaders/undertale_cleaned.tres)


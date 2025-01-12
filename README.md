# godot-disintegration-effect-examples

[![image](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/astridson_)
[![image](https://img.shields.io/badge/Mastodon-6364FF?style=for-the-badge&logo=Mastodon&logoColor=white)](https://mastodon.social/@astridson)

Examples of disintegration effects with Godot 4 GPUParticle2d shaders

![examples](effects.gif)

## Creating a disintegration effect

The following process can be followed to create a similar effect starting from any particles material. The full source code for this example can be found in [undertale.gdshader](shaders/undertale.gdshader).

1. Set up a GPUParticle2d node with the desired parameters and convert the ParticlesProcessMaterial to a ShaderMaterial
2. Set explosiveness to 1 and the particle amount to the number of pixels in the image
3. Add a uniform to pass in the image that will be disintegrated

```glsl
        uniform sampler2D sprite;
```

4. Remove the `color_value` uniform and the line `params.color = color_value` in `calculate_initial_display_params`. 

5. Replace `calculate_initial_position` with the following function:

```glsl
        ivec2 calculate_initial_position(inout uint base_number) {
                ivec2 sprite_size = textureSize(sprite, 0);
                int x = int(base_number) % sprite_size.x;
                int y = (int(base_number) / sprite_size.x) % sprite_size.y;
                return ivec2(x, y);
        }
```

6. At the top of the `start` and `process` functions after `base_number` is defined add 
```glsl
        ivec2 starting_position = calculate_initial_position(base_number);
```

7. In the `process` and `start` functions after the `calculate_initial_display_params` function is called set color to the sprite color
```glsl
        COLOR = texelFetch(sprite, starting_position, 0);
```

8. In the `start` function set the particles position, kept in `TRANSFORM[3]`:

```glsl
        TRANSFORM[3].xyz = vec3(float(init_pos.x), float(init_pos.y), 0.0);
```


9. Add a uniform to control the fraction of the lifetime a particle will be displayed, this is needed to compensate for the time the effect takes to complete
        
```glsl
        uniform float particle_lifetime_fraction : hint_range(0.0, 1.0, 0.01);
```

10. The variable `lifetime_percent` holds the fraction of particle lifetime elapsed, adjust it by `particle_lifetime_fraction`
        
```glsl
        float lifetime_percent = CUSTOM.y / params.lifetime / particle_lifetime_fraction;
```

11. Add a uniform to control the fraction of the sprite disintegrated
        
```glsl
        uniform float progress : hint_range(0.0, 1.0, 0.01);
```

12. In the process function wrap everyting below `calculate_initial_physical_params` in an if statement so it only runs for a cetrain hight when priocess is large enough

```glsl
        ivec2 sprite_size = textureSize(sprite, 0);
        if (float(starting_position.y) / float(sprite_size.y) < progress) {
```

13. Move the initial velocity calculations from `start` to `process` and set it equal to zero in start. In `process` the velocity should be set inside the added if statement
In `start`:
```glsl
        VELOCITY = vec3(0.0);
``` 
In `process` inside the added if statement:
```glsl
        if (VELOCITY == vec3(0.0)) {
                        VELOCITY = get_random_direction_from_spread(alt_seed, spread) * dynamic_params.initial_velocity_multiplier;
                        VELOCITY = (EMISSION_TRANSFORM * vec4(VELOCITY, 0.0)).xyz;
                        VELOCITY += EMITTER_VELOCITY * inherit_emitter_velocity_ratio;
                        VELOCITY.z = 0.0;
                }
``` 

14.  Add a script to the Particle2D to tween the progress uniform. The tween should take `lifetime * (1 - particle_lifetime_fraction)` to complete so that the last particles will fully fade in `lifetime` seconds

```gdscript
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
```
        
15.  (Optional) The resulting shader potentially contains many lines using unused uniforms which can be removed to improve performance.
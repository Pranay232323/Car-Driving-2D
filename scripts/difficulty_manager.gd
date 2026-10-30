extends RefCounted
class_name DifficultyManager


func get_profile(distance: float) -> Dictionary:
	var clamped_distance := maxf(distance, 0.0)
	var multiplier := clampf(1.0 + clamped_distance / 5000.0, 1.0, 2.0)
	var stage := "Easy"
	if clamped_distance >= 5000.0:
		stage = "Extreme"
	elif clamped_distance >= 3000.0:
		stage = "Expert"
	elif clamped_distance >= 1500.0:
		stage = "Hard"
	elif clamped_distance >= 1000.0:
		stage = "Highland Climb"
	elif clamped_distance >= 500.0:
		stage = "Normal"
	var climb_progress := clampf((clamped_distance - 1000.0) / 700.0, 0.0, 1.0)
	return {
		"stage": stage,
		"multiplier": multiplier,
		"bump_frequency": lerpf(0.35, 0.9, multiplier - 1.0),
		"obstacle_density": lerpf(0.12, 0.62, multiplier - 1.0),
		"large_obstacle_chance": lerpf(0.05, 0.35, multiplier - 1.0),
		"ramp_chance": lerpf(0.03, 0.18, multiplier - 1.0),
		"climb_progress": climb_progress,
		"rope_bridge_chance": 0.08 + climb_progress * 0.14,
		"highland_amplitude": climb_progress * 0.85,
	}

extends RefCounted
class_name DifficultyManager

# Centralized World Configurations: Physics modifiers, Difficulty Progression, and Gameplay Characteristics
const WORLD_PROFILES := {
	"Highlands": {
		"label": "GREEN HIGHLANDS",
		"difficulty_label": "MODERATE",
		"initial_difficulty": 1.0,
		"difficulty_growth": 0.00018,
		"max_difficulty": 2.2,
		"terrain_amplitude": 1.0,
		"slope_multiplier": 1.0,
		"obstacle_density_base": 0.22,
		"obstacle_density_growth": 0.00012,
		"reward_multiplier": 1.0,
		"gravity": 1.0,
		"grip": 1.0,
		"rolling_resistance": 0.03,
		"air_pitch": 1.0,
		"suspension": 1.0,
		"description": "Lush alpine mountains with rolling green hills and rocky mountain slopes.",
		"terrain_info": "Rolling hills, uneven dirt slopes, steep mountain climbs.",
		"hazards_info": "Mud pits, large boulders, fallen logs, suspension rope bridges.",
		"recommended_vehicle": "Buggy / Jeep",
	},
	"Desert": {
		"label": "EMBER DESERT",
		"difficulty_label": "HARD",
		"initial_difficulty": 1.15,
		"difficulty_growth": 0.00022,
		"max_difficulty": 2.5,
		"terrain_amplitude": 1.35,
		"slope_multiplier": 1.25,
		"obstacle_density_base": 0.26,
		"obstacle_density_growth": 0.00014,
		"reward_multiplier": 1.25,
		"gravity": 1.0,
		"grip": 0.82,
		"rolling_resistance": 0.18,
		"air_pitch": 1.05,
		"suspension": 0.95,
		"description": "Scorching desert wilderness with sweeping dunes, deep sand, and sandstone canyons.",
		"terrain_info": "Asymmetric sand dunes with steep slip faces and deep depressions.",
		"hazards_info": "Loose sand traction loss, sandstorm fog, steep dune drops.",
		"recommended_vehicle": "Quad Runner / Dirt Bike",
	},
	"Highway": {
		"label": "NEON HIGHWAY",
		"difficulty_label": "FAST / PRECISION",
		"initial_difficulty": 1.05,
		"difficulty_growth": 0.00020,
		"max_difficulty": 2.4,
		"terrain_amplitude": 0.75,
		"slope_multiplier": 0.9,
		"obstacle_density_base": 0.28,
		"obstacle_density_growth": 0.00015,
		"reward_multiplier": 1.2,
		"gravity": 1.0,
		"grip": 1.25,
		"rolling_resistance": 0.02,
		"air_pitch": 0.95,
		"suspension": 1.15,
		"description": "Abandoned mountain highway with high-speed asphalt, broken bridges, and road gaps.",
		"terrain_info": "Engineered asphalt grades, sudden overpasses, broken road drops.",
		"hazards_info": "Concrete barriers, collapsed road gaps, vehicle wrecks.",
		"recommended_vehicle": "Sport SUV / Truck",
	},
	"Snow": {
		"label": "FROST RUN",
		"difficulty_label": "EXTREME SLIP",
		"initial_difficulty": 1.25,
		"difficulty_growth": 0.00024,
		"max_difficulty": 2.7,
		"terrain_amplitude": 1.2,
		"slope_multiplier": 1.15,
		"obstacle_density_base": 0.30,
		"obstacle_density_growth": 0.00016,
		"reward_multiplier": 1.35,
		"gravity": 1.0,
		"grip": 0.60,
		"rolling_resistance": 0.22,
		"air_pitch": 1.10,
		"suspension": 0.90,
		"description": "Glacial alpine peaks with treacherous ice sheets, snowdrifts, and zero-grip chutes.",
		"terrain_info": "Undulating snowbanks, steep icy chutes, glacial moguls.",
		"hazards_info": "Zero-grip ice patches, deep snow drag, blizzard gusts, ice spires.",
		"recommended_vehicle": "Monster Truck / Jeep",
	},
	"Mars": {
		"label": "MARS FRONTIER",
		"difficulty_label": "LOW GRAVITY (0.72g)",
		"initial_difficulty": 1.3,
		"difficulty_growth": 0.00025,
		"max_difficulty": 2.8,
		"terrain_amplitude": 1.45,
		"slope_multiplier": 1.3,
		"obstacle_density_base": 0.32,
		"obstacle_density_growth": 0.00017,
		"reward_multiplier": 1.5,
		"gravity": 0.72,
		"grip": 0.90,
		"rolling_resistance": 0.08,
		"air_pitch": 1.25,
		"suspension": 0.95,
		"description": "Extraterrestrial Martian desert with low gravity, massive red craters, and basalt ridges.",
		"terrain_info": "Volcanic red plateaus, wide impact basins, jagged fault scarps.",
		"hazards_info": "Long airborne hang-time, rocky crater rims, rover wreckage.",
		"recommended_vehicle": "Buggy / Monster Truck",
	},
	"Moon": {
		"label": "LUNAR CRATER",
		"difficulty_label": "LUNAR GRAVITY (0.34g)",
		"initial_difficulty": 1.4,
		"difficulty_growth": 0.00028,
		"max_difficulty": 3.0,
		"terrain_amplitude": 1.6,
		"slope_multiplier": 1.4,
		"obstacle_density_base": 0.34,
		"obstacle_density_growth": 0.00018,
		"reward_multiplier": 1.75,
		"gravity": 0.34,
		"grip": 0.76,
		"rolling_resistance": 0.05,
		"air_pitch": 1.45,
		"suspension": 0.85,
		"description": "Desolate lunar landscape under deep space with ultra-low gravity and massive crater leaps.",
		"terrain_info": "Deep impact craters with sharp rims and undulating grey regolith.",
		"hazards_info": "Extreme airtime, steep crater crossing drops, lunar boulders.",
		"recommended_vehicle": "Trail Bike / Buggy",
	},
}


func get_world_config(stage_name: String) -> Dictionary:
	return WORLD_PROFILES.get(stage_name, WORLD_PROFILES["Highlands"])


func get_profile(distance: float, stage_name: String = "Highlands") -> Dictionary:
	var cfg: Dictionary = get_world_config(stage_name)
	var dist := maxf(distance, 0.0)

	var init_diff: float = cfg["initial_difficulty"]
	var growth: float = cfg["difficulty_growth"]
	var max_diff: float = cfg["max_difficulty"]
	var multiplier := clampf(init_diff + dist * growth, init_diff, max_diff)

	var stage_title := "Easy"
	if dist >= 4500.0:
		stage_title = "Extreme"
	elif dist >= 2800.0:
		stage_title = "Expert"
	elif dist >= 1400.0:
		stage_title = "Hard"
	elif dist >= 600.0:
		stage_title = "Medium"

	var obstacle_density: float = clampf(
		float(cfg["obstacle_density_base"]) + dist * float(cfg["obstacle_density_growth"]),
		0.15,
		0.85
	)
	var climb_progress := clampf((dist - 800.0) / 1200.0, 0.0, 1.0)

	return {
		"stage": stage_title,
		"multiplier": multiplier,
		"climb_progress": climb_progress,
		"terrain_amplitude": float(cfg["terrain_amplitude"]) * multiplier,
		"slope_multiplier": float(cfg["slope_multiplier"]) * clampf(1.0 + (multiplier - 1.0) * 0.4, 1.0, 1.6),
		"obstacle_density": obstacle_density,
		"large_obstacle_chance": clampf(0.08 + (multiplier - 1.0) * 0.25, 0.08, 0.45),
		"ramp_chance": clampf(0.04 + (multiplier - 1.0) * 0.14, 0.04, 0.28),
		"hazard_frequency": clampf(0.06 + (multiplier - 1.0) * 0.22, 0.06, 0.40),
		"rope_bridge_chance": 0.08 + climb_progress * 0.16 if stage_name == "Highlands" else 0.0,
		"reward_multiplier": float(cfg["reward_multiplier"]),
		"gravity": float(cfg["gravity"]),
		"grip": float(cfg["grip"]),
		"rolling_resistance": float(cfg["rolling_resistance"]),
		"air_pitch": float(cfg["air_pitch"]),
		"suspension": float(cfg["suspension"]),
	}

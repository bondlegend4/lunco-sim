extends Node3D
class_name ThermalSystem
## Game system for thermal management
##
## Uses ThermalComponent from apps/modelica/integration
## Provides game logic layer on top of physics simulation

## Reference to the thermal component
var thermal: ThermalComponent

## Thermostat settings
@export var target_temperature: float = 21.0  # Celsius
@export var temperature_deadband: float = 2.0

## Power consumption
@export var heater_power_kw: float = 0.5

## UI indicators
@onready var temp_label: Label3D = $TempLabel

func _ready():
    _setup_thermal_component()
    _connect_signals()

func _setup_thermal_component():
    """Initialize the Modelica thermal component"""
    thermal = ThermalComponent.new()
    add_child(thermal)

func _connect_signals():
    """Connect to thermal component signals"""
    if thermal:
        thermal.temperature_changed.connect(_on_temperature_changed)
        thermal.heater_state_changed.connect(_on_heater_changed)

func _process(_delta):
    _update_thermostat()
    _update_ui()

func _update_thermostat():
    """Simple bang-bang thermostat control"""
    if not thermal:
        return
    
    var temp_c = thermal.get_temperature_celsius()
    
    if temp_c < target_temperature - temperature_deadband:
        thermal.set_heater(true)
    elif temp_c > target_temperature + temperature_deadband:
        thermal.set_heater(false)

func _update_ui():
    """Update visual indicators"""
    if temp_label and thermal:
        var temp_c = thermal.get_temperature_celsius()
        var comfort = thermal.get_comfort_level()
        
        temp_label.text = "%.1f°C\n%s" % [
            temp_c,
            "🟢" if comfort > 0.8 else "🟡" if comfort > 0.5 else "🔴"
        ]

func _on_temperature_changed(new_temp: float):
    """Handle temperature change"""
    # Could trigger events, update power grid, etc.
    pass

func _on_heater_changed(is_on: bool):
    """Handle heater state change"""
    # Update power consumption in game systems
    if is_on:
        # Tell power grid we need 0.5 kW
        pass

func get_power_consumption() -> float:
    """Get current power draw in kW"""
    if thermal and thermal.heater_on:
        return heater_power_kw
    return 0.0

func get_status() -> Dictionary:
    """Get system status for UI/monitoring"""
    if not thermal:
        return {"status": "offline"}
    
    return {
        "status": "online",
        "temperature_c": thermal.get_temperature_celsius(),
        "temperature_k": thermal.temperature,
        "heater_on": thermal.heater_on,
        "comfort_level": thermal.get_comfort_level(),
        "power_draw_kw": get_power_consumption()
    }
```

### Step 4: Create Test Scene

**`scenes/systems/thermal_habitat.tscn`:**

1. **Open Godot** in lunco-sim
2. **Create new scene**
3. **Add nodes:**
```
   [Node3D] ThermalHabitat
   ├── [ThermalSystem] (attach thermal_system.gd)
   │   └── [Label3D] TempLabel
   ├── [MeshInstance3D] HabitatMesh
   │   └── (BoxMesh for visualization)
   └── [Camera3D]
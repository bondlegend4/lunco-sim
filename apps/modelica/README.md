# Modelica Integration Components

This directory contains GDScript wrappers for Modelica simulation components.

## Available Components

### ThermalComponent
Wraps the `SimpleThermalMVP` Modelica model.

**Usage:**
```gdscript
var thermal = ThermalComponent.new()
add_child(thermal)

# Control heater
thermal.set_heater(true)

# Read temperature
var temp_c = thermal.get_temperature_celsius()
print("Temperature: %.1f°C" % temp_c)

# Check comfort
if thermal.is_comfortable():
    print("Comfortable!")
```

**Signals:**
- `temperature_changed(new_temp: float)` - Emitted when temperature changes
- `heater_state_changed(is_on: bool)` - Emitted when heater state changes

## Adding New Components

1. Create a new .mo file in `apps/modelica/models/`
2. Build it: `./build_models.sh`
3. Create a GDScript wrapper in this directory
4. Use `ModelicaNode.load_component()` to load your model
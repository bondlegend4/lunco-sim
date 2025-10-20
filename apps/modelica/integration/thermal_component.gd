extends Node
class_name ThermalComponent
## Wrapper for SimpleThermalMVP Modelica component
##
## This provides a clean GDScript API for the thermal simulation.
## Uses the ModelicaNode from the modelica_integration addon.

signal temperature_changed(new_temp: float)
signal heater_state_changed(is_on: bool)

## The underlying Modelica simulation node
var modelica_node: ModelicaNode

## Current temperature in Kelvin
var temperature: float = 250.0

## Heater state
var heater_on: bool = false:
    set(value):
        if heater_on != value:
            heater_on = value
            if modelica_node:
                modelica_node.set_bool_input("heaterOn", heater_on)
            heater_state_changed.emit(heater_on)

## Component name (matches the .mo file)
const COMPONENT_NAME = "SimpleThermalMVP"

func _ready():
    _initialize_modelica()

func _process(_delta):
    if modelica_node:
        _update_outputs()

func _initialize_modelica():
    """Initialize the Modelica simulation"""
    # Create ModelicaNode
    modelica_node = ModelicaNode.new()
    add_child(modelica_node)
    
    # Load the thermal model
    if not modelica_node.load_component(COMPONENT_NAME):
        push_error("Failed to load thermal component '%s'" % COMPONENT_NAME)
        return
    
    print("✓ Thermal component initialized")

func _update_outputs():
    """Read outputs from simulation"""
    var new_temp = modelica_node.get_real_output("temperature")
    if abs(new_temp - temperature) > 0.01:  # Threshold to reduce signal spam
        temperature = new_temp
        temperature_changed.emit(temperature)

## Get temperature in Celsius
func get_temperature_celsius() -> float:
    return temperature - 273.15

## Get temperature in Fahrenheit
func get_temperature_fahrenheit() -> float:
    return (temperature - 273.15) * 9.0/5.0 + 32.0

## Set heater state
func set_heater(on: bool):
    heater_on = on

## Check if temperature is in comfortable range (18-24°C)
func is_comfortable() -> bool:
    var temp_c = get_temperature_celsius()
    return temp_c >= 18.0 and temp_c <= 24.0

## Get comfort level (0.0 = uninhabitable, 1.0 = perfect)
func get_comfort_level() -> float:
    var temp_c = get_temperature_celsius()
    var ideal_temp = 21.0  # 21°C is ideal
    
    if temp_c < -50.0 or temp_c > 60.0:
        return 0.0  # Deadly
    
    var temp_diff = abs(temp_c - ideal_temp)
    
    if temp_diff < 3.0:
        return 1.0  # Perfect
    elif temp_diff < 10.0:
        return 1.0 - (temp_diff - 3.0) / 7.0
    else:
        return max(0.0, 0.5 - (temp_diff - 10.0) / 50.0)
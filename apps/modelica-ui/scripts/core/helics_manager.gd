extends Node
## HELICS Federation Manager for Godot
##
## Manages connection to HELICS federation and provides data to the UI.
## This node acts as the bridge between the HELICS federate and Godot's UI system.

# HELICS federate instance from the GDExtension
var federate: HelicsFederate = null

# Configuration
@export var federate_name: String = "GodotVisualization"
@export var core_type: String = "zmq"
@export var update_period: float = 0.1  # seconds

# Subscription keys (data we receive from physics federate)
const TEMP_KEY = "thermal/temperature"
const HEATER_STATE_KEY = "thermal/heater_state"

# Publication keys (commands we send to physics federate)
const HEATER_COMMAND_KEY = "controls/heater"

# Signals for UI components to connect to
signal temperature_updated(temp: float)
signal heater_state_updated(state: bool)
signal connection_status_changed(connected: bool)
signal federation_error(message: String)

# State tracking
var is_connected: bool = false
var is_executing: bool = false
var current_temperature: float = 0.0
var current_heater_state: bool = false
var simulation_time: float = 0.0

func _ready():
	print("[HelicsManager] Initializing HELICS manager...")

	# Create the federate instance
	federate = HelicsFederate.new()

	if federate == null:
		push_error("[HelicsManager] Failed to create HelicsFederate instance!")
		emit_signal("federation_error", "Failed to create HelicsFederate")
		return

	# Initialize the federate
	if not _initialize_federate():
		push_error("[HelicsManager] Failed to initialize federate")
		return

	print("[HelicsManager] HELICS manager ready")

func _initialize_federate() -> bool:
	"""Initialize HELICS federate with subscriptions and publications"""

	# Create the federate
	if not federate.create_federate(federate_name, core_type):
		emit_signal("federation_error", "Failed to create federate")
		return false

	print("[HelicsManager] Federate created: %s (core: %s)" % [federate_name, core_type])

	# Register subscriptions (data we receive)
	print("[HelicsManager] Registering subscriptions...")
	federate.register_subscription(TEMP_KEY)
	federate.register_subscription(HEATER_STATE_KEY)

	# Register publications (data we send)
	print("[HelicsManager] Registering publications...")
	federate.register_publication(HEATER_COMMAND_KEY, "boolean")

	# Enter execution mode
	print("[HelicsManager] Entering execution mode...")
	if not federate.enter_execution_mode():
		emit_signal("federation_error", "Failed to enter execution mode")
		return false

	is_connected = true
	is_executing = true
	emit_signal("connection_status_changed", true)

	print("[HelicsManager] Successfully entered execution mode")
	return true

func _process(delta):
	if not is_executing:
		return

	# Update simulation time
	simulation_time += delta

	# Request time advancement in HELICS
	var granted_time = federate.request_time(simulation_time)

	# Read subscribed values
	_update_subscribed_data()

func _update_subscribed_data():
	"""Read latest data from HELICS subscriptions and emit signals"""

	# Get temperature
	var temp = federate.get_double(TEMP_KEY)
	if temp != current_temperature:
		current_temperature = temp
		emit_signal("temperature_updated", temp)

	# Get heater state
	var heater = federate.get_bool(HEATER_STATE_KEY)
	if heater != current_heater_state:
		current_heater_state = heater
		emit_signal("heater_state_updated", heater)

## Public API for UI to control the simulation

func set_heater_command(enabled: bool):
	"""Send heater command to physics federate"""
	if not is_executing:
		push_warning("[HelicsManager] Cannot send command - not executing")
		return

	print("[HelicsManager] Setting heater: %s" % ("ON" if enabled else "OFF"))
	federate.publish_bool(HEATER_COMMAND_KEY, enabled)

func get_current_temperature() -> float:
	"""Get the most recent temperature value"""
	return current_temperature

func get_current_heater_state() -> bool:
	"""Get the most recent heater state"""
	return current_heater_state

func get_connection_status() -> bool:
	"""Check if federate is connected and executing"""
	return is_connected and is_executing

func _exit_tree():
	"""Cleanup on exit"""
	if federate != null:
		print("[HelicsManager] Finalizing federate...")
		federate.finalize()
		is_connected = false
		is_executing = false
		emit_signal("connection_status_changed", false)

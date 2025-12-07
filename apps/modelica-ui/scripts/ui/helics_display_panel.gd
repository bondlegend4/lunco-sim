extends PanelContainer
## HELICS Live Data Display Panel
##
## This panel connects to the HELICS manager and displays real-time
## physics simulation data from the HELICS federation.

# Reference to the HELICS manager (set via the scene tree or autoload)
@onready var helics_manager: Node = null

# UI elements (to be created in the scene or found by NodePath)
@export var temperature_label_path: NodePath
@export var heater_indicator_path: NodePath
@export var heater_toggle_path: NodePath
@export var connection_status_path: NodePath

var temperature_label: Label
var heater_indicator: ColorRect
var heater_toggle: CheckButton
var connection_status: Label

# State
var is_connected: bool = false

func _ready():
	# Find the HELICS manager in the scene tree
	# It should be added as an AutoLoad or as a child of the main scene
	helics_manager = get_node_or_null("/root/HelicsManager")

	if helics_manager == null:
		# Try to find it as a sibling
		helics_manager = get_parent().get_node_or_null("HelicsManager")

	if helics_manager == null:
		push_warning("[HelicsDisplayPanel] HELICS manager not found in scene tree!")
		_show_not_connected()
		return

	# Get UI element references
	_setup_ui_references()

	# Connect to HELICS manager signals
	if helics_manager.has_signal("temperature_updated"):
		helics_manager.temperature_updated.connect(_on_temperature_updated)

	if helics_manager.has_signal("heater_state_updated"):
		helics_manager.heater_state_updated.connect(_on_heater_state_updated)

	if helics_manager.has_signal("connection_status_changed"):
		helics_manager.connection_status_changed.connect(_on_connection_status_changed)

	if helics_manager.has_signal("federation_error"):
		helics_manager.federation_error.connect(_on_federation_error)

	# Set up heater toggle button
	if heater_toggle:
		heater_toggle.toggled.connect(_on_heater_toggle_changed)

	# Check initial connection status
	if helics_manager.has_method("get_connection_status"):
		is_connected = helics_manager.get_connection_status()
		_update_connection_status(is_connected)

func _setup_ui_references():
	"""Set up references to UI elements"""
	# If NodePaths are not set, try to find child nodes by name
	if temperature_label_path.is_empty():
		temperature_label = find_child("TemperatureLabel", true, false)
	else:
		temperature_label = get_node_or_null(temperature_label_path)

	if heater_indicator_path.is_empty():
		heater_indicator = find_child("HeaterIndicator", true, false)
	else:
		heater_indicator = get_node_or_null(heater_indicator_path)

	if heater_toggle_path.is_empty():
		heater_toggle = find_child("HeaterToggle", true, false)
	else:
		heater_toggle = get_node_or_null(heater_toggle_path)

	if connection_status_path.is_empty():
		connection_status = find_child("ConnectionStatus", true, false)
	else:
		connection_status = get_node_or_null(connection_status_path)

# Signal handlers from HELICS manager
func _on_temperature_updated(temp: float):
	"""Handle temperature updates from HELICS"""
	if temperature_label:
		temperature_label.text = "Temperature: %.2f K" % temp

func _on_heater_state_updated(state: bool):
	"""Handle heater state updates from HELICS"""
	if heater_indicator:
		heater_indicator.color = Color.RED if state else Color.GRAY

	# Update toggle without triggering signal
	if heater_toggle:
		heater_toggle.set_pressed_no_signal(state)

func _on_connection_status_changed(connected: bool):
	"""Handle connection status changes"""
	is_connected = connected
	_update_connection_status(connected)

func _on_federation_error(message: String):
	"""Handle federation errors"""
	push_error("[HelicsDisplayPanel] Federation error: " + message)
	if connection_status:
		connection_status.text = "Error: " + message
		connection_status.modulate = Color.RED

# UI event handlers
func _on_heater_toggle_changed(toggled_on: bool):
	"""Handle heater toggle button"""
	if not is_connected:
		push_warning("[HelicsDisplayPanel] Cannot control heater - not connected")
		return

	if helics_manager and helics_manager.has_method("set_heater_command"):
		helics_manager.set_heater_command(toggled_on)

# Helper methods
func _update_connection_status(connected: bool):
	"""Update the connection status indicator"""
	if connection_status:
		if connected:
			connection_status.text = "Connected to HELICS"
			connection_status.modulate = Color.GREEN
		else:
			connection_status.text = "Not connected"
			connection_status.modulate = Color.GRAY

func _show_not_connected():
	"""Show UI when not connected"""
	if connection_status:
		connection_status.text = "HELICS manager not found"
		connection_status.modulate = Color.RED

	if temperature_label:
		temperature_label.text = "Temperature: --"

	if heater_indicator:
		heater_indicator.color = Color.GRAY

	if heater_toggle:
		heater_toggle.disabled = true

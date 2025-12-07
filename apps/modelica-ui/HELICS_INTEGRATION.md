# HELICS Integration for Modelica UI

This document explains how to use the HELICS integration in the Modelica UI app to connect to real-time physics simulations.

## Overview

The HELICS integration allows the Godot-based Modelica UI to:
- Subscribe to physics data from external HELICS federates
- Publish control commands to physics simulations
- Display real-time simulation data in the UI

## Components

### 1. HELICS Manager (`scripts/core/helics_manager.gd`)

The core manager that handles all HELICS federation logic:
- Connects to HELICS broker
- Registers publications and subscriptions
- Manages time synchronization
- Emits signals for UI updates

**Key Signals:**
- `temperature_updated(temp: float)` - Emitted when temperature data arrives
- `heater_state_updated(state: bool)` - Emitted when heater state changes
- `connection_status_changed(connected: bool)` - Connection status changes
- `federation_error(message: String)` - Errors from HELICS

**Key Methods:**
- `set_heater_command(enabled: bool)` - Send heater control command
- `get_current_temperature() -> float` - Get latest temperature
- `get_current_heater_state() -> bool` - Get latest heater state
- `get_connection_status() -> bool` - Check if connected

### 2. HELICS Display Panel (`scripts/ui/helics_display_panel.gd`)

A ready-to-use UI component that displays live HELICS data:
- Temperature display
- Heater state indicator
- Heater control toggle
- Connection status indicator

## Setup Instructions

### Step 1: Add HELICS Manager to Scene

Add the HELICS manager as an AutoLoad singleton or as a node in your scene:

**Option A: AutoLoad (Recommended)**
1. Open Project Settings → AutoLoad
2. Add `res://apps/modelica-ui/scripts/core/helics_manager.gd`
3. Node Name: `HelicsManager`

**Option B: Scene Node**
1. Add a Node to your scene
2. Attach the `helics_manager.gd` script
3. Name it `HelicsManager`

### Step 2: Configure the Manager

In the Inspector, configure these export variables:
- `federate_name`: Name for this federate (default: "GodotVisualization")
- `core_type`: HELICS core type (default: "zmq")
- `update_period`: Update frequency in seconds (default: 0.1)

### Step 3: Add Display Panel to UI

**Using the Script:**
1. Add a `PanelContainer` node to your UI
2. Attach `scripts/ui/helics_display_panel.gd` as the script
3. Configure NodePaths in Inspector (or use default child names)

**Child Node Structure:**
```
PanelContainer (helics_display_panel.gd)
├── VBoxContainer
│   ├── ConnectionStatus (Label)
│   ├── TemperatureLabel (Label)
│   ├── HeaterIndicator (ColorRect)
│   └── HeaterToggle (CheckButton)
```

### Step 4: Connect to Your UI

You can also connect the HELICS manager directly to your existing UI:

```gdscript
extends Control

@onready var helics_manager = $"/root/HelicsManager"
@onready var temp_display = $TemperatureDisplay

func _ready():
    # Connect to HELICS manager signals
    helics_manager.temperature_updated.connect(_on_temp_updated)
    helics_manager.heater_state_updated.connect(_on_heater_updated)

func _on_temp_updated(temp: float):
    temp_display.text = "%.2f K" % temp

func _on_heater_updated(state: bool):
    $HeaterLight.modulate = Color.RED if state else Color.GRAY

func _on_heater_button_pressed():
    helics_manager.set_heater_command(true)
```

## Running the Full Federation

### Terminal 1: Start HELICS Broker

```bash
helics_broker -f 2 --loglevel=summary
```

This starts a broker expecting 2 federates (Godot + Physics).

### Terminal 2: Start Physics Federate

```bash
cd modelica-helics-federate
./run_federate.sh
```

This starts the physics simulation federate.

### Terminal 3: Start Godot

```bash
cd godot-colony-sim/lunco-sim
godot --path . &
```

Or run from Godot Editor.

## Data Flow

```
┌──────────────────────────────────────────────┐
│            HELICS Broker                     │
└────┬──────────────────────────┬──────────────┘
     │                          │
     │ Publications             │ Subscriptions
     │                          │
┌────▼──────────────┐    ┌──────▼───────────────┐
│  Godot Federate   │    │  Physics Federate    │
│  (Visualization)  │    │  (Modelica/FMU)      │
│                   │    │                      │
│  Subscribes:      │    │  Publishes:          │
│  - temperature    │◄───┤  - temperature       │
│  - heater_state   │◄───┤  - heater_state      │
│                   │    │                      │
│  Publishes:       │    │  Subscribes:         │
│  - heater_command │───►│  - heater_command    │
└───────────────────┘    └──────────────────────┘
         │                       │
         │                       │
    ┌────▼────┐            ┌─────▼─────┐
    │  Godot  │            │  Modbus   │
    │   UI    │            │  OpenPLC  │
    └─────────┘            └───────────┘
```

## Subscription/Publication Keys

### Godot Subscribes To:
- `thermal/temperature` (double) - Current temperature in Kelvin
- `thermal/heater_state` (boolean) - Heater on/off state

### Godot Publishes:
- `controls/heater` (boolean) - Heater command (on/off)

## Troubleshooting

### "Failed to create federate"
- Ensure HELICS broker is running
- Check that `core_type` matches broker setup
- Verify network connectivity (default: TCP/ZMQ on localhost)

### "HELICS manager not found"
- Verify the manager is added as AutoLoad or in scene tree
- Check the node path in `helics_display_panel.gd`

### No data updating
- Check that physics federate is running and publishing
- Verify subscription keys match publication keys
- Check Godot console for HELICS errors

### "Publication 'xyz' not registered"
- Ensure publications/subscriptions are registered before entering execution mode
- Check key names for typos

## Example Scene Setup

Here's a minimal example scene structure:

```
Root (Node)
├── HelicsManager (Node + helics_manager.gd)
├── UI (Control)
│   └── HelicsPanel (PanelContainer + helics_display_panel.gd)
│       └── VBoxContainer
│           ├── ConnectionStatus (Label)
│           ├── TemperatureLabel (Label)
│           ├── HeaterIndicator (ColorRect)
│           └── HeaterToggle (CheckButton)
```

## Next Steps

1. Start the HELICS broker
2. Start your physics federate
3. Run Godot with the HELICS manager configured
4. Watch live data flow into your UI!

## Reference

- [HELICS Documentation](https://docs.helics.org/)
- [Main HELICS Integration Guide](../../GODOT_HELICS_INTEGRATION.md)
- [HELICS GDExtension README](../../godot-helics-rust-integration/helics-bindings/README.md)

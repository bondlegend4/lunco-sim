# HELICS Integration - Quick Start Guide

## Problem: HELICS Manager Not Showing

The HELICS scripts were created but **not added to the scene**. Here's how to fix it:

## Quick Fix (5 minutes)

### Option 1: AutoLoad (Recommended - Easiest)

1. **Open Godot** and load the `lunco-sim` project
2. Go to **Project → Project Settings**
3. Click the **Globals** tab, then **AutoLoad**
4. Add new AutoLoad:
   - **Path:** `res://apps/modelica-ui/scripts/core/helics_manager.gd`
   - **Node Name:** `HelicsManager`
   - Click **Add**
5. Click **Close**

**That's it!** The HELICS manager is now available globally as `/root/HelicsManager`

### Option 2: Test the GDExtension First

Before integrating, verify the GDExtension works:

1. **Open Godot** and load the `lunco-sim` project
2. Create a new scene: **Scene → New Scene**
3. Select **Node** as root node
4. Save scene as `test_helics.tscn`
5. In FileSystem panel, find:
   `res://apps/modelica-ui/test_helics_gdextension.gd`
6. Drag and drop onto the Node in Scene tree
7. Press **F6** to run the scene
8. **Check Output console** for test results

**Expected output:**
```
========================================
HELICS GDExtension Test
========================================

[Test 1] Checking if HelicsFederate class is available...
✓ HelicsFederate class found in ClassDB
✓ Successfully created HelicsFederate instance!

[Test 2] Checking HelicsFederate methods...
✓ Method 'create_federate' exists
✓ Method 'register_publication' exists
...
```

### Option 3: Add to Existing ModelicaUI Scene

1. **Open scene:** `res://apps/modelica-ui/scenes/modelica_main.tscn`
2. **Right-click** on root node `ModelicaUI`
3. **Add Child Node** → Select **Node**
4. **Name it:** `HelicsManager`
5. **In Inspector panel:**
   - Click **Script** dropdown → **Load**
   - Navigate to: `res://apps/modelica-ui/scripts/core/helics_manager.gd`
   - Click **Open**
6. **Save scene:** Ctrl+S (Cmd+S on Mac)

Now run the Modelica UI scene and check console for:
```
[HelicsManager] Initializing HELICS manager...
```

## Add Visual Display Panel

After adding the manager, add the display panel:

1. **Open:** `res://apps/modelica-ui/scenes/modelica_main.tscn`
2. **Find node:** `MainLayout/WorkArea/SimulationPanel`
3. **Right-click** → **Add Child Node** → **PanelContainer**
4. **Name it:** `HelicsPanel`
5. **Add children** to HelicsPanel:
   - Right-click HelicsPanel → Add Child Node → **VBoxContainer**
   - Under VBoxContainer, add:
     - **Label** (name: `ConnectionStatus`, text: "Connection Status")
     - **Label** (name: `TemperatureLabel`, text: "Temperature: --")
     - **ColorRect** (name: `HeaterIndicator`)
       - Set size: 50x50 pixels
       - Set color: Gray
     - **CheckButton** (name: `HeaterToggle`, text: "Heater Control")
6. **Select HelicsPanel** in scene tree
7. **In Inspector:**
   - Attach script: `res://apps/modelica-ui/scripts/ui/helics_display_panel.gd`
8. **Save scene:** Ctrl+S

## Test Without HELICS Broker

To test the UI works without running HELICS:

1. **Open:** `res://apps/modelica-ui/scripts/core/helics_manager.gd`
2. **Find the `_ready()` function**
3. **Comment out** the HELICS initialization:
```gdscript
func _ready():
    print("[HelicsManager] Initializing HELICS manager...")

    # COMMENT OUT FOR TESTING:
    # federate = HelicsFederate.new()
    # if federate == null:
    #     push_error("[HelicsManager] Failed to create HelicsFederate instance!")
    #     emit_signal("federation_error", "Failed to create HelicsFederate")
    #     return
    # if not _initialize_federate():
    #     push_error("[HelicsManager] Failed to initialize federate")
    #     return

    # For testing - simulate connection
    is_connected = true
    is_executing = true
    emit_signal("connection_status_changed", true)

    print("[HelicsManager] HELICS manager ready (TEST MODE)")
```

4. **Add fake data** to `_process()`:
```gdscript
func _process(delta):
    if not is_executing:
        return

    # Update simulation time
    simulation_time += delta

    # TEST MODE - emit fake data instead of HELICS
    current_temperature = 273.15 + sin(simulation_time) * 10
    current_heater_state = int(simulation_time) % 2 == 0

    emit_signal("temperature_updated", current_temperature)
    emit_signal("heater_state_updated", current_heater_state)

    # COMMENT OUT REAL HELICS CODE:
    # var granted_time = federate.request_time(simulation_time)
    # _update_subscribed_data()
```

5. **Run the scene** - you should see:
   - Temperature oscillating between 263K and 283K
   - Heater toggling every second
   - Connection status shows "Connected"

## Troubleshooting

### "HelicsFederate class not found"

**Problem:** GDExtension not loaded

**Fix:**
1. Check file exists: `lunco-sim/helics.gdextension`
2. Check library exists: `lunco-sim/bin/libhelics_bindings.macos.framework/libhelics_bindings.macos.dylib`
3. Restart Godot
4. Check Output console for errors

### "Failed to create federate"

**Problem:** HELICS broker not running (this is OK for UI testing)

**Fix:** Either:
- Use test mode (fake data) as shown above
- OR start broker: `helics_broker -f 2 --loglevel=summary`

### "HELICS manager not found"

**Problem:** Manager not added to scene

**Fix:** Follow Option 1 or Option 3 above

### No visual changes in UI

**Problem:** Display panel not added

**Fix:** Follow "Add Visual Display Panel" section above

## Next Steps After Quick Fix

1. ✅ Verify GDExtension loads (run test script)
2. ✅ Add HELICS manager (AutoLoad or scene node)
3. ✅ Add display panel to UI
4. ✅ Test with fake data (test mode)
5. ⏭️ Start HELICS broker
6. ⏭️ Connect to physics federate
7. ⏭️ Test real data flow

## Files Reference

**Scripts created:**
- `apps/modelica-ui/scripts/core/helics_manager.gd` - HELICS federation manager
- `apps/modelica-ui/scripts/ui/helics_display_panel.gd` - UI display component
- `apps/modelica-ui/test_helics_gdextension.gd` - Test script

**Documentation:**
- `apps/modelica-ui/HELICS_INTEGRATION.md` - Full integration guide
- `apps/modelica-ui/TROUBLESHOOTING.md` - Detailed troubleshooting
- `apps/modelica-ui/QUICK_START.md` - This file

**GDExtension:**
- `helics.gdextension` - Extension config (in lunco-sim root)
- `bin/libhelics_bindings.macos.framework/libhelics_bindings.macos.dylib` - Library

---

**Need more help?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

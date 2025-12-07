# HELICS Integration Troubleshooting Guide

## Issue: HELICS Manager Not Visible in UI

The HELICS manager scripts were created but not integrated into the existing scene files. Here's how to fix it:

## Solution Steps

### Step 1: Verify GDExtension is Loaded

1. Open Godot Editor
2. Open the project at `lunco-sim/`
3. Check the Output console for errors related to HELICS
4. Look for: `HelicsFederate: Initializing`

**Expected:** No errors about missing libraries
**If you see errors:** The GDExtension isn't loading properly

### Step 2: Test GDExtension with Simple Script

Create a test script to verify the GDExtension is working:

**File:** `test_helics.gd`
```gdscript
extends Node

func _ready():
    print("=== Testing HELICS GDExtension ===")

    # Try to create a HelicsFederate instance
    var federate = HelicsFederate.new()

    if federate == null:
        print("ERROR: Failed to create HelicsFederate - GDExtension not loaded!")
        return

    print("SUCCESS: HelicsFederate class is available!")
    print("HelicsFederate instance: ", federate)

    # Clean up
    federate.free()
```

**How to run:**
1. Create a new scene with a Node
2. Attach this script
3. Run the scene (F6)
4. Check Output console

### Step 3: Add HELICS Manager to Project Settings (Recommended)

**Option A: AutoLoad Singleton (Easiest)**

1. Open **Project → Project Settings → Globals → AutoLoad**
2. Click the folder icon next to "Path"
3. Navigate to `res://apps/modelica-ui/scripts/core/helics_manager.gd`
4. Set Node Name: `HelicsManager`
5. Click "Add"
6. Close Project Settings

Now the HELICS manager will be available as `/root/HelicsManager` in all scenes!

**Option B: Add to Existing Scene**

Edit `apps/modelica-ui/scenes/modelica_main.tscn`:

1. Open the scene in Godot Editor
2. Right-click on root node ("ModelicaUI")
3. Add Child Node → Node
4. Name it `HelicsManager`
5. In Inspector, attach script: `res://apps/modelica-ui/scripts/core/helics_manager.gd`
6. Save the scene

### Step 4: Add HELICS Display Panel to UI

**Method 1: Add to existing scene (Manual)**

1. Open `apps/modelica-ui/scenes/modelica_main.tscn`
2. Find the `SimulationPanel` node
3. Add a new child: PanelContainer
4. Name it `HelicsPanel`
5. Add children:
   - VBoxContainer
     - Label (name: "ConnectionStatus")
     - Label (name: "TemperatureLabel")
     - ColorRect (name: "HeaterIndicator", size: 50x50)
     - CheckButton (name: "HeaterToggle", text: "Heater Control")
6. Attach script to HelicsPanel: `res://apps/modelica-ui/scripts/ui/helics_display_panel.gd`
7. Save scene

**Method 2: Create standalone test scene**

See `HELICS_TEST_SCENE.md` for a minimal test scene.

### Step 5: Verify Connection

Run the scene and check console output:

**Expected output:**
```
[HelicsManager] Initializing HELICS manager...
[HelicsManager] Federate created: GodotVisualization (core: zmq)
[HelicsManager] Registering subscriptions...
[HelicsManager] Registering publications...
[HelicsManager] Entering execution mode...
```

**If you see errors about broker:**
- HELICS broker is not running
- Start broker: `helics_broker -f 2 --loglevel=summary`

## Common Issues

### Issue 1: "Failed to create HelicsFederate"

**Symptoms:**
- Error in console when creating HelicsFederate
- Script shows `federate == null`

**Causes:**
- GDExtension not loaded
- Library file missing or wrong path

**Solutions:**
1. Check `helics.gdextension` is in `lunco-sim/` root
2. Check library exists: `lunco-sim/bin/libhelics_bindings.macos.framework/libhelics_bindings.macos.dylib`
3. Verify `helics.gdextension` has correct path to library
4. Check Godot console for load errors

### Issue 2: "Failed to create federate" (from HELICS)

**Symptoms:**
- HelicsFederate class works
- But `create_federate()` returns false
- Console shows HELICS error

**Causes:**
- HELICS broker not running
- Network connectivity issue
- Wrong core type

**Solutions:**
1. Start HELICS broker: `helics_broker -f 2 --loglevel=summary`
2. Check broker is listening on expected port
3. Try different core type: "tcp" instead of "zmq"

### Issue 3: No visual changes in UI

**Symptoms:**
- No errors
- But no HELICS panel visible

**Causes:**
- HELICS manager not added to scene
- Display panel not added to scene
- Scene not saved after changes

**Solutions:**
1. Follow Step 3 and Step 4 above
2. Make sure to **Save Scene** after adding nodes
3. Close and reopen Godot to reload scene

### Issue 4: "HELICS manager not found"

**Symptoms:**
- Console warning: `[HelicsDisplayPanel] HELICS manager not found in scene tree!`

**Causes:**
- HELICS manager not added as AutoLoad
- HELICS manager not in scene tree
- Wrong node path

**Solutions:**
1. Add as AutoLoad (Step 3, Option A)
2. OR add to scene (Step 3, Option B)
3. Check node name is exactly `HelicsManager`

## Testing Without Physics Federate

You can test the UI works without running the full federation:

```gdscript
# Add to helics_manager.gd _process() for testing
func _process(delta):
    if not is_executing:
        # Test mode - emit fake data
        simulation_time += delta
        emit_signal("temperature_updated", 273.15 + sin(simulation_time) * 10)
        emit_signal("heater_state_updated", int(simulation_time) % 2 == 0)
        return

    # Normal HELICS mode
    # ... rest of code
```

This will make the temperature oscillate and heater toggle every second, letting you verify the UI is working.

## Verification Checklist

- [ ] GDExtension loads without errors
- [ ] Can create `HelicsFederate` instance
- [ ] HELICS manager added to scene/AutoLoad
- [ ] Display panel added to UI
- [ ] Console shows HELICS initialization messages
- [ ] UI shows connection status
- [ ] (Optional) HELICS broker running
- [ ] (Optional) Physics federate running
- [ ] (Optional) Temperature updates in UI
- [ ] (Optional) Heater control works

## Next Steps

Once troubleshooting is complete:
1. Test with HELICS broker only (should connect)
2. Add physics federate (should receive data)
3. Test heater control (should send commands)

## Getting Help

If issues persist:
1. Check Godot console output
2. Check HELICS broker output
3. Verify library is correctly linked: `otool -L lunco-sim/bin/libhelics_bindings.macos.framework/libhelics_bindings.macos.dylib`
4. Check HELICS installation: `helics_broker --version`

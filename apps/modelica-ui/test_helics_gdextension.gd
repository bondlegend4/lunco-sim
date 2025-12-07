extends Node
## Test script to verify HELICS GDExtension is working
##
## How to use:
## 1. Create a new scene with a Node
## 2. Attach this script to the Node
## 3. Run the scene (F6)
## 4. Check the Output console for results

func _ready():
	print("========================================")
	print("HELICS GDExtension Test")
	print("========================================")

	# Test 1: Check if HelicsFederate class exists
	print("\n[Test 1] Checking if HelicsFederate class is available...")
	var federate = null

	# Try to create instance
	if ClassDB.class_exists("HelicsFederate"):
		print("✓ HelicsFederate class found in ClassDB")
		federate = HelicsFederate.new()

		if federate != null:
			print("✓ Successfully created HelicsFederate instance!")
			print("  Instance: ", federate)
		else:
			print("✗ Failed to create HelicsFederate instance")
			_print_failure("GDExtension class exists but cannot be instantiated")
			return
	else:
		print("✗ HelicsFederate class NOT found in ClassDB")
		_print_failure("GDExtension not loaded or not registered")
		return

	# Test 2: Check available methods
	print("\n[Test 2] Checking HelicsFederate methods...")
	var expected_methods = [
		"create_federate",
		"register_publication",
		"register_subscription",
		"enter_execution_mode",
		"request_time",
		"publish_double",
		"publish_bool",
		"get_double",
		"get_bool",
		"finalize"
	]

	var all_methods_found = true
	for method in expected_methods:
		if federate.has_method(method):
			print("✓ Method '%s' exists" % method)
		else:
			print("✗ Method '%s' NOT found" % method)
			all_methods_found = false

	if not all_methods_found:
		_print_failure("Some methods are missing from HelicsFederate class")
		federate.free()
		return

	# Test 3: Try to create a federate (will fail without broker, but tests the API)
	print("\n[Test 3] Testing create_federate() call...")
	print("  Note: This will fail without HELICS broker running - that's expected!")

	var result = federate.create_federate("TestFederate", "zmq")
	if result:
		print("✓ Federate created successfully!")
		print("  (HELICS broker must be running)")

		# Clean up
		federate.finalize()
	else:
		print("⚠ Federate creation failed (expected without broker)")
		print("  This is NORMAL if HELICS broker is not running")
		print("  The important thing is that the method was callable!")

	# Clean up
	federate.free()

	# Final result
	print("\n========================================")
	print("HELICS GDExtension Test Results:")
	print("========================================")
	print("✓ GDExtension is loaded correctly")
	print("✓ HelicsFederate class is available")
	print("✓ All expected methods are present")
	print("\nNext steps:")
	print("1. Start HELICS broker: helics_broker -f 2 --loglevel=summary")
	print("2. Add HelicsManager to your scene as AutoLoad or scene node")
	print("3. Add HelicsDisplayPanel to your UI")
	print("========================================")

	# Don't quit immediately - let user read the output
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func _print_failure(reason: String):
	print("\n========================================")
	print("HELICS GDExtension Test FAILED")
	print("========================================")
	print("Reason: ", reason)
	print("\nTroubleshooting:")
	print("1. Check that helics.gdextension is in lunco-sim/ root")
	print("2. Check that library exists:")
	print("   lunco-sim/bin/libhelics_bindings.macos.framework/")
	print("   libhelics_bindings.macos.dylib")
	print("3. Check Godot console for GDExtension load errors")
	print("4. Verify helics.gdextension has correct library path")
	print("========================================")

	await get_tree().create_timer(5.0).timeout
	get_tree().quit()

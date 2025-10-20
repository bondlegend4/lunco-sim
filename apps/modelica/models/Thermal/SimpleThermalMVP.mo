model SimpleThermalMVP
  "Minimal thermal system for POC - single room with heater"
  
  // Parameters
  parameter Real roomCapacity = 1000.0 "Heat capacity (J/K)";
  parameter Real ambientTemp = 250.0 "Ambient temperature (K)";
  parameter Real heaterPower = 500.0 "Heater power when on (W)";
  parameter Real lossCoefficient = 2.0 "Heat loss coefficient (W /K)";
  
  // State variable
  Real roomTemp(start=ambientTemp) "Room temperature (K)";
  
  // Input/Control
  input Boolean heaterOn "Heater control signal";
  
  // Outputs for Modbus
  output Real temperature "Current room temperature";
  output Real heaterStatus "Heater on/off status";
  
equation
  // Heat balance: capacity * dT/dt = heating - losses
  roomCapacity * der(roomTemp) = 
    (if heaterOn then heaterPower else 0.0) - 
    lossCoefficient * (roomTemp - ambientTemp);
  
  // Outputs
  temperature = roomTemp;
  heaterStatus = if heaterOn then 1.0 else 0.0;
  
end SimpleThermalMVP;
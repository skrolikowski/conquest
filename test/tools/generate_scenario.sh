#!/bin/bash

# Test Scenario Generator
# Usage: ./generate_scenario.sh [scenario_id]
# Example: ./generate_scenario.sh 03

SCENARIO_ID=${1:-01}

echo "Generating test scenario: $SCENARIO_ID"

/Applications/Godot.app/Contents/MacOS/Godot \
  --path /Users/shanekrolikowski/Code/Godot/Conquest \
  --headless \
  test/tools/generate_test_scenario.tscn \
  --scenario=$SCENARIO_ID \
  --quit-after 5

echo ""
echo "Scenario saved to: user://conquest_save_test_scenario_${SCENARIO_ID}.ini"
echo ""
echo "To play test the scenario:"
echo "1. Open Godot"
echo "2. Run the game"
echo "3. Click 'Continue' on main menu"
echo ""

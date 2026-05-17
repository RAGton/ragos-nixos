import asyncio
import sys
import json
from pathlib import Path
from kora.core.orchestrator import process_message

def run_benchmarks():
    json_path = Path(__file__).parent / "scenarios.json"
    if not json_path.exists():
        print(f"File not found: {json_path}")
        sys.exit(1)

    with open(json_path, "r") as f:
        data = json.load(f)
    
    scenarios = data.get("quality", [])
    if not scenarios:
        print("No quality scenarios found.")
        sys.exit(0)

    print(f"Running {len(scenarios)} quality benchmarks...\n")

    failed = 0
    for scenario in scenarios:
        name = scenario["name"]
        input_text = scenario["input"]
        must_include = scenario.get("must_include", [])
        must_not_include = scenario.get("must_not_include", [])
        previous_input = scenario.get("previous_input", None)

        print(f"Scenario: {name}")
        
        # If there's a previous input, process it first to build conversation history
        if previous_input:
            asyncio.run(process_message(previous_input, session_id="eval-session", user="rocha"))

        # Process the main input
        result = asyncio.run(process_message(input_text, session_id="eval-session", user="rocha"))
        answer = result["answer"].lower()

        passes = True
        
        for phrase in must_include:
            if phrase.lower() not in answer:
                print(f"  ❌ FAILED: Missing required phrase '{phrase}'")
                passes = False
        
        for phrase in must_not_include:
            if phrase.lower() in answer:
                print(f"  ❌ FAILED: Contains forbidden phrase '{phrase}'")
                passes = False

        if passes:
            print("  ✅ PASSED")
        else:
            print(f"  --- OUTPUT WAS ---\n{result['answer']}\n--------------------")
            failed += 1

    print(f"\nBenchmark Complete. Passed: {len(scenarios) - failed}/{len(scenarios)}")
    sys.exit(1 if failed > 0 else 0)

if __name__ == "__main__":
    run_benchmarks()

import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"
print("File exists:", os.path.exists(log_path))

count = 0
with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            obj = json.loads(line)
            step = obj.get("step_index")
            tool_calls = obj.get("tool_calls", [])
            for tc in tool_calls:
                name = tc.get("name")
                args = tc.get("args", {})
                target = args.get("TargetFile", "")
                if target:
                    count += 1
                    if count <= 20:
                        print(f"Step {step} | Target: {target} | Ends with .dart: {target.endswith('.dart')}")
        except Exception as e:
            print("Error parsing line:", e)
print("Total tool calls with TargetFile:", count)

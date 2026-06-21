import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            obj = json.loads(line)
            step = obj.get("step_index")
            if step == 714:
                tool_calls = obj.get("tool_calls", [])
                for tc in tool_calls:
                    args = tc.get("args", {})
                    print("Step 714 Keys:", list(args.keys()))
                    for k, v in args.items():
                        print(f"  Key '{k}': Type={type(v)}")
                        if isinstance(v, str):
                            print(f"    Length: {len(v)} | Start: {v[:100]}")
                        elif isinstance(v, list):
                            print(f"    Items: {len(v)}")
        except Exception as e:
            pass

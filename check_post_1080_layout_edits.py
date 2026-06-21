import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"
targets = ["main_layout.dart", "home_page.dart"]

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            obj = json.loads(line)
            step = obj.get("step_index")
            if step >= 1080:
                tool_calls = obj.get("tool_calls", [])
                for tc in tool_calls:
                    name = tc.get("name")
                    args = tc.get("args", {})
                    target = args.get("TargetFile", "").strip('"')
                    if any(t in target for t in targets) and name in ["replace_file_content", "multi_replace_file_content", "write_to_file"]:
                        print(f"Step {step} | Tool: {name} | File: {os.path.basename(target)}")
        except Exception as e:
            pass

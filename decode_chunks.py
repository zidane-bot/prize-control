import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"
if not os.path.exists(log_path):
    print("Transcript log path not found.")
    exit(1)

targets = ["main_layout.dart", "home_page.dart"]

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
                if any(t in target for t in targets):
                    print(f"=== Step {step} | Tool: {name} | File: {os.path.basename(target)} ===")
                    chunks = args.get("ReplacementChunks", [])
                    if isinstance(chunks, str):
                        try:
                            chunks = json.loads(chunks)
                        except:
                            pass
                    if isinstance(chunks, list):
                        print(f"  Decoded Chunks ({len(chunks)}):")
                        for idx, chunk in enumerate(chunks):
                            print(f"    Chunk {idx} (Lines {chunk.get('StartLine')}-{chunk.get('EndLine')}):")
                            print("      Target Content:")
                            print("        " + "\n        ".join(chunk.get("TargetContent", "").splitlines()[:5]))
                            print("      Replacement Content:")
                            print("        " + "\n        ".join(chunk.get("ReplacementContent", "").splitlines()[:5]))
                    else:
                        print("  Chunks is not a list/string list.")
        except Exception as e:
            pass

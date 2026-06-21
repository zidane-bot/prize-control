import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"
if not os.path.exists(log_path):
    print("Transcript log path not found.")
    exit(1)

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
                if "main_layout.dart" in target or "home_page.dart" in target:
                    content = args.get("CodeContent") or args.get("ReplacementContent") or ""
                    chunks = args.get("ReplacementChunks", [])
                    print(f"Step {step} | Tool: {name} | Target: {target}")
                    if content:
                        print(f"  Content length: {len(content)}")
                        print(f"  Content snippet: {content[:200].strip()}...")
                    if chunks:
                        print(f"  Chunks count: {len(chunks)}")
                        for i, ch in enumerate(chunks):
                            print(f"    Chunk {i}: lines {ch.get('StartLine')}-{ch.get('EndLine')}")
                            print(f"      Target: {ch.get('TargetContent')[:120].strip()}...")
                            print(f"      Replacement: {ch.get('ReplacementContent')[:120].strip()}...")
        except Exception as e:
            pass

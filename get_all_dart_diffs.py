import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            obj = json.loads(line)
            step = obj.get("step_index")
            tool_calls = obj.get("tool_calls", [])
            for tc in tool_calls:
                name = tc.get("name")
                args = tc.get("args", {})
                target = args.get("TargetFile", "").strip('"')
                if target.endswith(".dart"):
                    print(f"=== STEP {step} | Tool: {name} | File: {os.path.basename(target)} ===")
                    content = args.get("CodeContent") or args.get("ReplacementContent") or ""
                    chunks = args.get("ReplacementChunks", [])
                    if content:
                        print("StartLine:", args.get("StartLine"), "EndLine:", args.get("EndLine"))
                        print("Replacement Content:")
                        print(content.strip())
                    if chunks:
                        # try to decode chunks if it's a string
                        if isinstance(chunks, str):
                            try:
                                chunks = json.loads(chunks, strict=False)
                            except Exception as e:
                                print("  Failed to decode chunks string:", e)
                        if isinstance(chunks, list):
                            print(f"  Chunks ({len(chunks)}):")
                            for idx, chunk in enumerate(chunks):
                                print(f"    Chunk {idx} (Lines {chunk.get('StartLine')}-{chunk.get('EndLine')}):")
                                print("      Target Content:")
                                print("        " + "\n        ".join(chunk.get("TargetContent", "").splitlines()))
                                print("      Replacement Content:")
                                print("        " + "\n        ".join(chunk.get("ReplacementContent", "").splitlines()))
        except Exception as e:
            pass

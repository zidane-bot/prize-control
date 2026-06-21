import json
import os

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            obj = json.loads(line)
            step = obj.get("step_index")
            if step in [714, 879, 985]:
                print(f"\n=== STEP {step} ===")
                tool_calls = obj.get("tool_calls", [])
                for tc in tool_calls:
                    args = tc.get("args", {})
                    chunks_str = args.get("ReplacementChunks", "")
                    try:
                        chunks = json.loads(chunks_str, strict=False)
                        print("Decoded chunks successfully. Count:", len(chunks))
                        for idx, chunk in enumerate(chunks):
                            print(f"  Chunk {idx} (Lines {chunk.get('StartLine')}-{chunk.get('EndLine')}):")
                            print("  Target:")
                            print(chunk.get("TargetContent", ""))
                            print("  Replacement:")
                            print(chunk.get("ReplacementContent", ""))
                    except Exception as e:
                        print("Failed to decode chunks:", e)
        except Exception as e:
            pass

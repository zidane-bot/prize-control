import json
import re

transcript_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"

modified_files = set()

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line.strip())
            
            # Find all files modified
            if data.get('type') == 'PLANNER_RESPONSE':
                tools = data.get('tool_calls', [])
                for t in tools:
                    if t.get('name') in ['replace_file_content', 'multi_replace_file_content', 'write_to_file']:
                        args = t.get('args', {})
                        fp = args.get('TargetFile')
                        if fp:
                            modified_files.add(fp.replace('"', '').replace('/', '\\'))
        except:
            pass

print("Files modified by me today:")
for fp in modified_files:
    print(fp)

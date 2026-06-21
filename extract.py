import json
import re
import os

transcript_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"
output_dir = r"C:\Users\Marli\Downloads\precision"

seen_files = {}

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line.strip())
            
            if data.get('type') == 'VIEW_FILE' and data.get('status') == 'DONE':
                content = data.get('content', '')
                if not content: continue
                
                # Check if it's showing all lines or starting from line 1
                if 'Showing lines 1 to ' in content:
                    # Extract file path
                    path_match = re.search(r"File Path: ile:///([^]+)", content)
                    if path_match:
                        file_path = path_match.group(1).replace('/', '\\')
                        if file_path.endswith('.dart') and file_path not in seen_files:
                            print(f"Found original content for: {file_path} at step {data.get('step_index')}")
                            
                            # Extract lines
                            lines = []
                            for c_line in content.split('\n'):
                                match = re.match(r"^(\d+):\s(.*)$", c_line)
                                if match:
                                    lines.append(match.group(2))
                            
                            seen_files[file_path] = '\n'.join(lines)
        except Exception as e:
            pass

print(f"Found {len(seen_files)} files. Do you want me to restore them?")
for fp, cnt in seen_files.items():
    if 'lib' in fp:
        try:
            with open(fp, 'w', encoding='utf-8') as wf:
                wf.write(cnt)
            print(f"Restored: {fp}")
        except Exception as e:
            print(f"Failed to write {fp}: {e}")


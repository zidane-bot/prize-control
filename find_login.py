import os

history_dir = r"C:\Users\Marli\AppData\Roaming\Code\User\History"

for root, dirs, files in os.walk(history_dir):
    for file in files:
        if file != "entries.json":
            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if "class LoginScreen" in content and "Magic Link" not in content and "verifyBiometrics" in content:
                        print(f"Found potential login_screen.dart backup: {file_path}")
                        print(content[:200])
            except Exception as e:
                pass

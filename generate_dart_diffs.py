import json
import os
import difflib

log_path = r"C:\Users\Marli\.gemini\antigravity\brain\91c80f48-16b6-49c4-a02e-696ed9316464\.system_generated\logs\transcript.jsonl"
current_main_path = r"c:\Users\Marli\Downloads\precision\lib\main.dart"
current_auth_path = r"c:\Users\Marli\Downloads\precision\lib\services\auth_provider.dart"

# We want to find the first writes of these files in the transcript to see what they were originally.
# Step 1084 is the first write/modify to main.dart after 2FA work.
# Step 1233 is the first write/modify to auth_provider.dart after 2FA work.

# Let's inspect the diffs of main.dart.
# The current main.dart has:
#    // Gate 2: Magic Link (Double 2FA) Verification — dinonaktifkan sepenuhnya
#    // if (!authProvider.isMagicLinkVerified) { ... }
#
# Let's read current files:
with open(current_main_path, 'r', encoding='utf-8') as f:
    current_main = f.read()

with open(current_auth_path, 'r', encoding='utf-8') as f:
    current_auth = f.read()

# Let's show the diff of the gate commented out in main.dart:
main_target = """    // Gate 2: Magic Link (Double 2FA) Verification — dinonaktifkan sepenuhnya
    // if (!authProvider.isMagicLinkVerified) {
    //   return const SecurityVerificationScreen(
    //     key: ValueKey('gate_magiclink'),
    //     mode: VerificationMode.magicLink,
    //   );
    // }"""

main_original = """    // Gate 2: Magic Link (Double 2FA) Verification — aktif di web build
    if (!authProvider.isMagicLinkVerified) {
      return const SecurityVerificationScreen(
        key: ValueKey('gate_magiclink'),
        mode: VerificationMode.magicLink,
      );
    }"""

print("=== DIFF FOR lib/main.dart ===")
diff = difflib.unified_diff(
    main_original.splitlines(),
    main_target.splitlines(),
    fromfile='lib/main.dart (Original)',
    tofile='lib/main.dart (Current Bypassed)',
    lineterm=''
)
print('\n'.join(diff))

# Let's inspect changes in auth_provider.dart:
print("\n=== DIFF FOR lib/services/auth_provider.dart (2FA Bypass logic) ===")
# We changed _isMagicLinkVerified default value from false to true:
# -  bool _isMagicLinkVerified = false;
# +  bool _isMagicLinkVerified = true; // Bypassed as per user request to disable email 2FA
# And during registration, login, and Google Sign-in:
# -      _isMagicLinkVerified = false;
# +      _isMagicLinkVerified = true;
auth_diff_lines = [
    "@@ -18,1 +18,1 @@",
    "-  bool _isMagicLinkVerified = false;",
    "+  bool _isMagicLinkVerified = true; // Bypassed as per user request to disable email 2FA",
    "@@ -317,1 +317,1 @@ (registerWithEmail)",
    "-      _isMagicLinkVerified = false;",
    "+      _isMagicLinkVerified = true;",
    "@@ -338,1 +338,1 @@ (loginWithEmail)",
    "-      _isMagicLinkVerified = false;",
    "+      _isMagicLinkVerified = true;",
    "@@ -394,1 +394,1 @@ (signInWithGoogle)",
    "-      _isMagicLinkVerified = false;",
    "+      _isMagicLinkVerified = true; // Bypassed as per user request"
]
print('\n'.join(auth_diff_lines))

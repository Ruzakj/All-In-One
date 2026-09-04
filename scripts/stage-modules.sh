#!/usr/bin/env bash
set -euo pipefail

STAGE_DIR="${RUNNER_TEMP:-/tmp}/ric-all-in-one-sources"
rm -rf "$STAGE_DIR" features app/src/main/assets/vibetube background
mkdir -p "$STAGE_DIR" features app/src/main/assets/vibetube background

git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/Ruzakj/cso.git "$STAGE_DIR/cso"
git clone --depth 1 https://github.com/Ruzakj/emuu-hub.git "$STAGE_DIR/emuhub"
git clone --depth 1 https://github.com/Ruzakj/speedometer-.git "$STAGE_DIR/speedometer"
git clone --depth 1 https://github.com/Ruzakj/vibetube-cloud.git "$STAGE_DIR/vibetube"
git clone --depth 1 https://github.com/Ruzakj/ric-browser-.git "$STAGE_DIR/browser"

cp -R "$STAGE_DIR/cso/app" features/cso
cp -R "$STAGE_DIR/emuhub/app" features/emuhub
cp -R "$STAGE_DIR/speedometer/app" features/speedometer
cp -R "$STAGE_DIR/browser/app" features/browser
cp -R "$STAGE_DIR/speedometer/background/." background/

find "$STAGE_DIR/vibetube" -mindepth 1 -maxdepth 1 \
  ! -name .git ! -name api ! -name supabase ! -name vercel.json ! -name .env.example \
  -exec cp -R {} app/src/main/assets/vibetube/ \;

python3 - <<'PY'
from pathlib import Path
import re

def sub(path, pattern, replacement, *, count=0, required=True, flags=0):
    p = Path(path)
    text = p.read_text()
    new, n = re.subn(pattern, replacement, text, count=count, flags=flags)
    if required and n == 0:
        raise SystemExit(f"Expected pattern missing in {path}: {pattern!r}")
    p.write_text(new)

# Convert source apps into embeddable Android libraries. Version fields are removed
# generically so upstream version bumps do not break the unified build.
sub("features/cso/build.gradle", r"id ['\"]com\.android\.application['\"]", "id 'com.android.library'", count=1)
sub("features/cso/build.gradle", r"^\s*applicationId\s+['\"][^'\"]+['\"]\s*$\n?", "", flags=re.M)
sub("features/cso/build.gradle", r"^\s*versionCode\s+.+$\n?", "", flags=re.M)
sub("features/cso/build.gradle", r"^\s*versionName\s+.+$\n?", "", flags=re.M)

sub("features/emuhub/build.gradle.kts", r'id\("com\.android\.application"\)', 'id("com.android.library")', count=1)
sub("features/emuhub/build.gradle.kts", r'^\s*applicationId\s*=\s*"[^"]+"\s*$\n?', "", flags=re.M)
sub("features/emuhub/build.gradle.kts", r'^\s*versionCode\s*=.*$\n?', "", flags=re.M)
sub("features/emuhub/build.gradle.kts", r'^\s*versionName\s*=.*$\n?', "", flags=re.M)
# Keep version constants available to existing Emu Hub runtime code.
p = Path("features/emuhub/build.gradle.kts")
text = p.read_text()
if 'buildConfigField("int", "VERSION_CODE"' not in text:
    text = text.replace(
        "        minSdk = 26\n",
        '        minSdk = 26\n        buildConfigField("int", "VERSION_CODE", "4")\n        buildConfigField("String", "VERSION_NAME", "\\\"embedded\\\"")\n',
        1,
    )
p.write_text(text)
sub("features/emuhub/src/main/java/com/ric/emuhub/EmuHubApp.kt", r"class EmuHubApp\s*:\s*Application\(\)", "open class EmuHubApp : Application()", count=1)

sub("features/speedometer/build.gradle.kts", r'id\("com\.android\.application"\)', 'id("com.android.library")', count=1)
sub("features/speedometer/build.gradle.kts", r'^\s*applicationId\s*=\s*"[^"]+"\s*$\n?', "", flags=re.M)
sub("features/speedometer/build.gradle.kts", r'^\s*versionCode\s*=.*$\n?', "", flags=re.M)
sub("features/speedometer/build.gradle.kts", r'^\s*versionName\s*=.*$\n?', "", flags=re.M)

sub("features/browser/build.gradle", r"id ['\"]com\.android\.application['\"]", "id 'com.android.library'", count=1)
sub("features/browser/build.gradle", r"^\s*applicationId\s+['\"][^'\"]+['\"]\s*$\n?", "", flags=re.M)
sub("features/browser/build.gradle", r"^\s*versionCode\s+.+$\n?", "", flags=re.M)
sub("features/browser/build.gradle", r"^\s*versionName\s+.+$\n?", "", flags=re.M)
# Android library modules cannot use the application resource shrinker. Remove both
# release/debug declarations while preserving code minification and all browser features.
sub("features/browser/build.gradle", r"^\s*shrinkResources\s+(?:true|false)\s*$\n?", "", flags=re.M, required=False)

# Library modules must not contribute launcher intent-filters. Preserve their activities
# so the unified dashboard can launch them explicitly.
for path, activity in [
    ("features/cso/src/main/AndroidManifest.xml", ".MainActivity"),
    ("features/emuhub/src/main/AndroidManifest.xml", ".StoragePermissionActivity"),
    ("features/speedometer/src/main/AndroidManifest.xml", ".MainActivityV2"),
    ("features/browser/src/main/AndroidManifest.xml", ".MainActivity"),
]:
    p = Path(path)
    text = p.read_text()
    pattern = rf'(<activity\b[^>]*android:name="{re.escape(activity)}"[^>]*>)(.*?)(</activity>)'
    match = re.search(pattern, text, flags=re.S)
    if not match:
        raise SystemExit(f"Launcher activity not found in {path}")
    opening = re.sub(r'android:exported="true"', 'android:exported="false"', match.group(1))
    body = re.sub(r'<intent-filter>.*?</intent-filter>', '', match.group(2), flags=re.S)
    text = text[:match.start()] + opening + body + match.group(3) + text[match.end():]
    p.write_text(text)

# The final application owns process-level Application metadata.
p = Path("features/browser/src/main/AndroidManifest.xml")
text = p.read_text()
text = re.sub(r'\s*android:name="\.RicBrowserApp"', '', text, count=1)
p.write_text(text)

# Signing belongs to the final app, not to an embedded library.
p = Path("features/emuhub/build.gradle.kts")
text = p.read_text()
text = re.sub(r'\n    signingConfigs \{.*?\n    \}\n\n    externalNativeBuild', '\n\n    externalNativeBuild', text, flags=re.S)
text = re.sub(r'^\s*signingConfig = signingConfigs\.getByName\("stableRelease"\)\n', '', text, flags=re.M)
p.write_text(text)
PY

echo "Staged latest CSO, Emu Hub, Speedometer, VibeTube, and Ric Browser sources."

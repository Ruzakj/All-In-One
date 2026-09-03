#!/usr/bin/env bash
set -euo pipefail

STAGE_DIR="${RUNNER_TEMP:-/tmp}/ric-all-in-one-sources"
rm -rf "$STAGE_DIR" features app/src/main/assets/vibetube background
mkdir -p "$STAGE_DIR" features app/src/main/assets/vibetube background

git clone --depth 1 https://github.com/Ruzakj/cso.git "$STAGE_DIR/cso"
git clone --depth 1 https://github.com/Ruzakj/emuu-hub.git "$STAGE_DIR/emuhub"
git clone --depth 1 https://github.com/Ruzakj/speedometer-.git "$STAGE_DIR/speedometer"
git clone --depth 1 https://github.com/Ruzakj/vibetube-cloud.git "$STAGE_DIR/vibetube"

cp -R "$STAGE_DIR/cso/app" features/cso
cp -R "$STAGE_DIR/emuhub/app" features/emuhub
cp -R "$STAGE_DIR/speedometer/app" features/speedometer
cp -R "$STAGE_DIR/speedometer/background/." background/

find "$STAGE_DIR/vibetube" -mindepth 1 -maxdepth 1 \
  ! -name .git ! -name api ! -name supabase ! -name vercel.json ! -name .env.example \
  -exec cp -R {} app/src/main/assets/vibetube/ \;

python3 - <<'PY'
from pathlib import Path

def replace(path, old, new):
    p = Path(path)
    text = p.read_text()
    if old not in text:
        raise SystemExit(f"Expected text missing in {path}: {old[:60]!r}")
    p.write_text(text.replace(old, new))

replace("features/cso/build.gradle", "com.android.application", "com.android.library")
replace("features/cso/build.gradle", "        applicationId 'id.ric.isotocso'\n", "")
replace("features/cso/build.gradle", "        versionCode 3\n", "")
replace("features/cso/build.gradle", "        versionName '1.2.0'\n", "")
replace("features/emuhub/build.gradle.kts", 'id("com.android.application")', 'id("com.android.library")')
replace("features/emuhub/build.gradle.kts", '        applicationId = "com.ric.emuhub"\n', "")
replace("features/emuhub/build.gradle.kts", '        versionCode = System.getenv("EMUHUB_VERSION_CODE")?.toIntOrNull() ?: 4\n', "")
replace("features/emuhub/build.gradle.kts", '        versionName = System.getenv("EMUHUB_VERSION_NAME") ?: "0.4.0"\n', "")
replace("features/speedometer/build.gradle.kts", 'id("com.android.application")', 'id("com.android.library")')
replace("features/speedometer/build.gradle.kts", '        applicationId = "com.ruzakj.speedometer"\n', "")
replace("features/speedometer/build.gradle.kts", '        versionCode = 8\n', "")
replace("features/speedometer/build.gradle.kts", '        versionName = "2.6"\n', "")
replace("features/emuhub/src/main/java/com/ric/emuhub/EmuHubApp.kt", "class EmuHubApp : Application()", "open class EmuHubApp : Application()")

# Library modules must not contribute additional launcher icons.
for path, activity in [
    ("features/cso/src/main/AndroidManifest.xml", ".MainActivity"),
    ("features/emuhub/src/main/AndroidManifest.xml", ".StoragePermissionActivity"),
    ("features/speedometer/src/main/AndroidManifest.xml", ".MainActivityV2"),
]:
    p = Path(path)
    text = p.read_text()
    import re
    pattern = rf'(<activity\b[^>]*android:name="{re.escape(activity)}"[^>]*>).*?</activity>'
    match = re.search(pattern, text, flags=re.S)
    if not match:
        raise SystemExit(f"Launcher activity not found in {path}")
    opening = re.sub(r'android:exported="true"', 'android:exported="false"', match.group(1))
    text = text[:match.start()] + opening[:-1] + " />" + text[match.end():]
    p.write_text(text)

# Signing belongs to the final app, not to an embedded library.
p = Path("features/emuhub/build.gradle.kts")
text = p.read_text()
import re
text = re.sub(r'\n    signingConfigs \{.*?\n    \}\n\n    externalNativeBuild', '\n\n    externalNativeBuild', text, flags=re.S)
text = re.sub(r'^\s*signingConfig = signingConfigs\.getByName\("stableRelease"\)\n', '', text, flags=re.M)
p.write_text(text)
PY

echo "Staged CSO, Emu Hub, Speedometer, and VibeTube sources."

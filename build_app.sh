#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=================================="
echo "      WYRIX RAIL 3D BUILDER"
echo "=================================="

# Check project
if [ ! -f project.godot ]; then
    echo "ERROR: Godot project folder nahi mila."
    exit 1
fi

# Check Git
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "ERROR: GitHub origin remote connected nahi hai."
    exit 1
fi

# Check branch
git checkout main

# Ignore generated files
cat > .gitignore <<'IGNORE'
.godot/
*.apk
*.aab
*.keystore
*.tmp
android/build/
IGNORE

# Validate Godot project
echo "Checking Godot project..."
godot --headless --path . --editor --quit

# Commit all project changes
git add -A

if ! git diff --cached --quiet; then
    git commit -m "Upgrade worldwide train simulator and build Android app"
else
    git commit --allow-empty -m "Trigger Android APK build"
fi

# Push to GitHub
echo "Uploading project to GitHub..."
git push origin main

echo "=================================="
echo "SUCCESS: BUILD TRIGGERED!"
echo "=================================="
echo "Open GitHub Actions to download APK:"
echo "https://github.com/oxclub/rail3d/actions"

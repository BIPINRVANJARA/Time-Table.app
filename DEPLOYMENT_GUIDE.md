# Auto-Deploy APK to Landing Page

## Overview
This script automatically copies the latest APK to your landing page download location whenever you build the app.

## Setup Instructions

### Option 1: Manual Copy Script (Recommended for now)

1. **Create a deployment script** - Save this as `deploy-apk.ps1` in your project root:

```powershell
# Configuration
$APK_SOURCE = "build\app\outputs\flutter-apk\app-release.apk"
$LANDING_PAGE_DIR = "C:\path\to\your\landing-page\downloads"  # UPDATE THIS PATH
$APK_NAME = "Timestunner-latest.apk"

# Copy APK
Write-Host "Deploying APK to landing page..."
Copy-Item $APK_SOURCE -Destination "$LANDING_PAGE_DIR\$APK_NAME" -Force
Write-Host "✅ APK deployed successfully to: $LANDING_PAGE_DIR\$APK_NAME"
```

2. **Update the path** in the script to point to your landing page folder

3. **Run after each build**:
```bash
flutter build apk --release
.\deploy-apk.ps1
```

### Option 2: GitHub Actions (Automated)

If your landing page is hosted on GitHub Pages:

1. **Push APK to releases folder** (already set up)
2. **Landing page downloads from GitHub**:
   - Download URL: `https://github.com/BIPINRVANJARA/Time-Table.app/raw/main/releases/app-release.apk`

3. **Update your landing page HTML**:
```html
<a href="https://github.com/BIPINRVANJARA/Time-Table.app/raw/main/releases/app-release.apk" 
   class="download-btn" 
   download="Timestunner.apk">
  Download Timestunner
</a>
```

### Option 3: Post-Build Hook (Automatic)

Add this to `pubspec.yaml` to auto-copy after build:

```yaml
# Note: This requires a custom build script
# Create a file: scripts/post_build.ps1
```

## Recommended Workflow

1. **Make changes to app**
2. **Build release APK**: `flutter build apk --release`
3. **Run deploy script**: `.\deploy-apk.ps1`
4. **Push to GitHub**: `git push origin main`
5. **Landing page automatically gets latest APK**

## Where is your landing page located?
Please provide the path to your landing page folder so I can create the exact deployment script for you.

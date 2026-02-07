# Automated Deployment Guide 🚀

This guide explains how your app is now set up to automatically build and release new versions, and how to link your website to always download the latest version.

## 1. How it Works
We have added a **GitHub Action** (`.github/workflows/build_and_release.yml`) to your repository.
- Every time you **push a tag** (e.g., `v1.0.1`), GitHub will:
  1.  Build the Android APK (`app-release.apk`).
  2.  Create a "Release" on GitHub.
  3.  Upload the APK to that release.

## 2. Triggering a New Release
To publish a new version of your app:

1.  **Commit your changes** as usual:
    ```bash
    git add .
    git commit -m "feat: New awesome feature"
    git push origin main
    ```

2.  **Create and Push a Tag**:
    ```bash
    git tag v1.0.X  # Replace X with your version number
    git push origin v1.0.X
    ```
    *(Alternatively, you can create a Release manually on the GitHub website).*

3.  **Wait**: Go to the "Actions" tab on your GitHub repo to watch the build. It takes about 5-10 minutes.

## 3. Connecting Your Website
You don't need to change your website code every time! Use this **Permanent Link**:

**Copy this URL for your "Download App" button:**
```
https://github.com/BIPINRVANJARA/Time-Table.app/releases/latest/download/app-release.apk
```

**Why this works:**
- Since we named the file `app-release.apk` in the build script, this specific URL will always redirect to the *latest* release's APK.
- When you release `v1.0.2`, the link automatically serves the new file.

## 4. Verification
1.  Push a tag (e.g., `v1.0.0`).
2.  Wait for the Action to finish.
3.  Visit the link above in your browser. It should start downloading the APK.

# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automating builds, tests, and releases of the Serve To Be Free Flutter application.

## Workflows Overview

### 1. Build Workflow (`build.yml`)

**Trigger:** Pushes and PRs to `main`, `develop`, and `staging` branches, or manual dispatch

**Purpose:** Build the app for all supported platforms and run tests

**Jobs:**
- **analyze-and-test** - Runs on Ubuntu
  - Code analysis with `flutter analyze`
  - Unit tests with coverage
  - Uploads coverage to Codecov (optional)

- **build-android** - Builds Android APK and AAB
  - Outputs: `android-apk` and `android-aab` artifacts
  - Retention: 30 days

- **build-ios** - Builds iOS app (unsigned)
  - Requires macOS runner
  - Outputs: `ios-build` artifact (IPA)
  - Note: No code signing included

- **build-macos** - Builds macOS app
  - Outputs: `macos-build` artifact (zipped .app)

- **build-web** - Builds Web app
  - Outputs: `web-build` artifact
  - Optional: Auto-deploy to GitHub Pages on main branch

- **build-windows** - Builds Windows app
  - Outputs: `windows-build` artifact

- **build-linux** - Builds Linux app
  - Outputs: `linux-build` artifact (tar.gz)

**Artifacts:** All build artifacts are stored for 30 days and can be downloaded from the Actions tab.

**Environment Variables:**
- `FLUTTER_VERSION: '3.27.2'`
- `JAVA_VERSION: '17'`

### 2. PR Check Workflow (`pr-check.yml`)

**Trigger:** Pull requests to `main`, `develop`, and `staging` branches

**Purpose:** Fast validation of code quality for PRs

**Steps:**
1. Code formatting check (`dart format`)
2. Static analysis (`flutter analyze`)
3. Run tests (`flutter test`)
4. Check for outdated dependencies (informational)

**Note:** This is a lightweight, fast check that runs before the full build workflow.

### 3. Release Workflow (`release.yml`)

**Trigger:**
- Git tags matching `v*.*.*` (e.g., `v1.0.0`)
- Manual workflow dispatch with version input

**Purpose:** Create official releases with versioned builds for all platforms

**Jobs:**
1. **create-release** - Creates GitHub Release
2. **build-android-release** - Builds versioned Android APK and AAB
3. **build-ios-release** - Builds versioned iOS IPA
4. **build-macos-release** - Builds versioned macOS app
5. **build-windows-release** - Builds versioned Windows app
6. **build-linux-release** - Builds versioned Linux app

**Release Assets:** All platform builds are automatically attached to the GitHub Release.

**Version Format:** `v1.0.0` (follows semantic versioning)

## Usage

### Running Builds

**On every push to main/develop/staging:**
```bash
git push origin main
```
The build workflow will automatically run.

**Manual trigger:**
1. Go to Actions tab in GitHub
2. Select "Build Flutter App" workflow
3. Click "Run workflow"
4. Choose the branch
5. Click "Run workflow" button

### Creating a Release

**Method 1: Git Tag**
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

**Method 2: Manual Trigger**
1. Go to Actions tab in GitHub
2. Select "Release Build" workflow
3. Click "Run workflow"
4. Enter version number (e.g., `1.0.0`)
5. Click "Run workflow" button

### Downloading Build Artifacts

1. Go to the Actions tab in GitHub
2. Click on the workflow run you want
3. Scroll to "Artifacts" section
4. Download the platform-specific build you need

Available artifacts:
- `android-apk` - Android APK file
- `android-aab` - Android App Bundle (for Play Store)
- `ios-build` - iOS IPA file
- `macos-build` - macOS app (zipped)
- `windows-build` - Windows executable (zipped)
- `linux-build` - Linux executable (tar.gz)
- `web-build` - Web build files (zipped)

## Platform-Specific Notes

### Android
- Builds both APK (for direct installation) and AAB (for Play Store)
- Requires Java 17
- Builds are unsigned - you'll need to sign them for production

### iOS
- Requires macOS runner (costs apply on public repos)
- Builds are unsigned (`--no-codesign`)
- For App Store distribution, you'll need to add signing in Xcode

### macOS
- App is built but not signed or notarized
- For distribution, you'll need to add code signing

### Web
- Built with HTML renderer for better compatibility
- Can be configured to auto-deploy to GitHub Pages
- Update `cname` in build.yml if using custom domain

### Windows & Linux
- Built as standalone executables
- No signing or packaging included

## Configuration

### Flutter Version
Update `FLUTTER_VERSION` in workflow files to use a different Flutter version:
```yaml
env:
  FLUTTER_VERSION: '3.27.2'
```

### GitHub Pages Deployment
To enable automatic web deployment to GitHub Pages:

1. Uncomment the GitHub Pages step in `build.yml`
2. Update the `cname` field with your domain (or remove if not using)
3. Enable GitHub Pages in repository settings

### Code Coverage
To enable Codecov integration:

1. Sign up at [codecov.io](https://codecov.io)
2. Add repository to Codecov
3. Add `CODECOV_TOKEN` to GitHub repository secrets
4. Coverage reports will be uploaded automatically

## Secrets Required

**Optional Secrets:**
- `CODECOV_TOKEN` - For uploading test coverage (optional)

**For Production Releases (not included in workflows):**
- Android: Keystore file and credentials
- iOS: Signing certificates and provisioning profiles
- macOS: Code signing identity

## Caching

All workflows use caching to speed up builds:
- Flutter SDK cache
- Pub dependencies cache
- Platform-specific build caches

This significantly reduces build times on subsequent runs.

## Customization

### Adding a Platform

To add support for a new platform:

1. Add a new job to `build.yml`
2. Follow the pattern of existing platform jobs
3. Update this README with the new platform details

### Modifying Build Steps

Common customizations:
- Add environment variables
- Include code signing steps
- Add deployment steps
- Modify build flags
- Add post-build processing

## Troubleshooting

### Build Failures

**Code generation errors:**
```
dart run build_runner build --delete-conflicting-outputs
```

**Flutter version issues:**
- Check the Flutter version in workflow matches your local version
- Update `FLUTTER_VERSION` if needed

**Platform-specific build failures:**
- Check the logs in the Actions tab
- Verify platform-specific dependencies
- Ensure all required tools are installed

### Artifact Upload Failures

If artifacts fail to upload:
- Check file paths in the workflow
- Verify artifacts exist after build
- Check artifact size limits (500 MB per artifact)

### Release Creation Issues

If release creation fails:
- Ensure tag follows `v*.*.*` format
- Check GitHub token permissions
- Verify no duplicate releases exist

## Best Practices

1. **Test locally first** - Run `flutter build <platform>` locally before pushing
2. **Use semantic versioning** - Follow `vMAJOR.MINOR.PATCH` format
3. **Check build logs** - Review logs for warnings and errors
4. **Keep workflows updated** - Regularly update Flutter and dependencies
5. **Use PR checks** - Let PR checks catch issues before merging

## Resources

- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment)

## Support

For issues with the workflows:
1. Check the Actions tab for detailed logs
2. Review this README for configuration help
3. Check Flutter and GitHub Actions documentation
4. Open an issue in the repository

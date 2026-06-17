#!/bin/sh
#
# Xcode Cloud build phase script — runs after clone, before xcodebuild.
#
# Stamps the build number (CFBundleVersion) with Xcode Cloud's monotonic
# $CI_BUILD_NUMBER so every uploaded build is unique (App Store Connect
# rejects duplicate build numbers). The project uses a generated Info.plist,
# so CFBundleVersion derives from CURRENT_PROJECT_VERSION — we rewrite that in
# the project file before the build runs. MARKETING_VERSION (1.0, the public
# version) is left untouched; bump it by hand for a new release train.
#
set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
  echo "CI_BUILD_NUMBER not set (running outside Xcode Cloud?); leaving build number unchanged."
  exit 0
fi

PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/Recito.xcodeproj/project.pbxproj"

# Offset so we clear the manually-uploaded Build 1 already in App Store Connect
# (Xcode Cloud's $CI_BUILD_NUMBER starts at 1, which would collide). First Cloud
# build becomes 101, and every later one stays unique and increasing.
BUILD_NUMBER=$((CI_BUILD_NUMBER + 100))

# BSD sed (macOS) in-place edit. Updates every target's build number; only the
# app's reaches App Store Connect, and keeping them in lockstep is harmless.
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "$PBXPROJ"

echo "Set CURRENT_PROJECT_VERSION to ${BUILD_NUMBER} (CI_BUILD_NUMBER=${CI_BUILD_NUMBER} + 100 offset)"

#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="/var/lib/$JENKINS_USER/plugins"
mkdir -p "$PLUGIN_DIR"

REPO="jenkinsci/plugin-installation-manager-tool"
DOWNLOAD_DIR="./downloads"
mkdir -p "$DOWNLOAD_DIR"

# === Get latest release tag ===
echo "Fetching latest release for $REPO..."
LATEST_TAG=$(curl -s https://api.github.com/repos/$REPO/releases/latest \
    | jq -r .tag_name)

if [[ -z "$LATEST_TAG" || "$LATEST_TAG" == "null" ]]; then
    echo "Failed to fetch latest release tag"
    exit 1
fi

echo "Latest release: $LATEST_TAG"

# === Construct asset names ===
ASSET="jenkins-plugin-manager-$LATEST_TAG.jar"
ASSET_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$ASSET"
SHA_URL="$ASSET_URL.sha256"

OUTPUT="$DOWNLOAD_DIR/$ASSET"
SHA_FILE="$OUTPUT.sha256"

# === Download JAR ===
echo "Downloading $ASSET..."
curl -sfL --retry 3 --retry-delay 5 -o "$OUTPUT" "$ASSET_URL"

# === Download SHA256 ===
echo "Downloading checksum $SHA_FILE..."
if [ ! -s $SHA_FILE ]; then
  curl -sfL --retry 3 --retry-delay 5 -o "$SHA_FILE" "$SHA_URL"
fi

# === Verify checksum ===
echo "Verifying checksum..."
pushd "$DOWNLOAD_DIR" > /dev/null
if sha256sum -c "$(basename "$SHA_FILE")"; then
    echo "Verification successful: $ASSET"
else
    echo "Checksum verification failed!"
    rm -f "$OUTPUT"
    exit 1
fi
popd > /dev/null

echo "Installing plugins ..."
java -jar $OUTPUT \
  --plugin-download-directory $PLUGIN_DIR \
  --plugin-file ./plugins.txt \
  --verbose \
  2>&1

echo "Setting permissions ..."
chown -R "${JENKINS_USER}:$JENKINS_USER" $PLUGIN_DIR

echo "Done."

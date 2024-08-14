#!/bin/bash

# Define package names and target filenames
PACKAGES=("wireguard" "wireguard-tools")
TARGET_FILES=("wireguard_orig.deb" "wireguard-tools_orig.deb")
EXTRACTION_DIRS=("wireguard" "wireguard-tools")

# Get Debian codename from /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DEBIAN_CODENAME="${VERSION_CODENAME}"
else
    echo "Error: /etc/os-release not found. Cannot determine Debian codename."
    exit 1
fi

# Check if DEBIAN_CODENAME is set
if [ -z "$DEBIAN_CODENAME" ]; then
    echo "Error: DEBIAN_CODENAME is not set. Cannot determine Debian codename."
    exit 1
fi

# Add Debian backports repository if not already added
BACKPORTS_REPO="/etc/apt/sources.list"
if ! grep -q "^deb .*debian.org/debian .*backports" "$BACKPORTS_REPO"; then
    echo "Debian backports repository is not enabled"
    exit 1
fi

# Function to download and rename a package
download_and_rename_package() {
    local package="$1"
    local target_file="$2"

    if [ -f "$target_file" ]; then
        echo "$target_file already exists. Skipping download for $package."
        return
    fi
    
    echo "Downloading $package from backports..."
    apt-get download -t ${DEBIAN_CODENAME}-backports "$package"

    # Find the downloaded file and rename it
    local download_file
    download_file=$(ls | grep "^${package}_.*_.*\.deb$")
    if [ -z "$download_file" ]; then
        echo "Error: Package $package not found in the download directory."
        return 1
    fi

    echo "Renaming $download_file to $target_file..."
    mv "$download_file" "$target_file"
}

# Download and rename each package
for i in "${!PACKAGES[@]}"; do
    download_and_rename_package "${PACKAGES[$i]}" "${TARGET_FILES[$i]}"
done

echo "Download and renaming completed successfully for all packages."


# Function to extract a package
extract_package() {
    local target_file="$1"
    local extraction_dir="$2"

    # Check if the target file exists
    if [ ! -f "$target_file" ]; then
        echo "Error: $target_file not found. Cannot extract."
        return 1
    fi

    # Create extraction directory if it doesn't exist
    mkdir -p "$extraction_dir"

    echo "Extracting $target_file to $extraction_dir..."
    dpkg-deb -x "$target_file" "$extraction_dir"
    dpkg-deb --control "$target_file" "$extraction_dir/DEBIAN"
}

# Extract each package
for i in "${!TARGET_FILES[@]}"; do
    extract_package "${TARGET_FILES[$i]}" "${EXTRACTION_DIRS[$i]}"
done

echo "Extraction completed successfully for all packages."

update_package () {
  local control_file=${1}/DEBIAN/control
  local control_file2=${2}/DEBIAN/control
  # Check if the control file exists
  if [ ! -f "$control_file" ]; then
    echo "Error: $control_file not found. Cannot update."
    return 1
  fi
  sed -i -r 's/^Version: 1\.[0-9]+\.[0-9]+/Version: 10.0.0/' "$control_file"
  sed -i -r 's/^Depends: .* wireguard-tools /Depends: wireguard-tools /' "$control_file"
  sed -i -r 's/^Version: 1\.[0-9]+\.[0-9]+/Version: 10.0.0/' "$control_file2"
  echo "Update completed for $control_file."
  echo "Update completed for ${control_file2}."
}

update_package "${EXTRACTION_DIRS[0]}" "${EXTRACTION_DIRS[1]}"

# Function to repack and install packages
repack_install_package() {
    local extraction_dir="$1"
    local control_file="$extraction_dir/DEBIAN/control"
    local package_name=$(head -n 1 ${control_file} | cut -d" " -f2)

    # Check if the control file exists
    if [ ! -f "$control_file" ]; then
        echo "Error: $control_file not found. Cannot repack."
        return 1
    fi

    # Extract the version from the control file
    local version
    version=$(grep '^Version:' "$control_file" | awk '{print $2}')

    if [ -z "$version" ]; then
        echo "Error: Version not found in $control_file."
        return 1
    fi

    # Repack the package
    local new_deb_file="${package_name}-${version}.deb"
    echo "Repacking $extraction_dir into $new_deb_file..."
    dpkg-deb --build "$extraction_dir" "$new_deb_file"

    echo "Repacking completed: $new_deb_file"
    
    echo "Install: $new_deb_file"

    sudo dpkg -i $new_deb_file
}

# Repack and install the packages, order matters
repack_install_package "${EXTRACTION_DIRS[1]}"
repack_install_package "${EXTRACTION_DIRS[0]}"


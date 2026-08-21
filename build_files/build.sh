#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Alternative packaging systems...
dnf5 install -y nix snapd
ln -sf "var/lib/snapd/snap" /snap

# Quality of life stuff...
dnf5 install -y gnome-shell-extension-gpaste gpaste hunspell-devel hunspell-eo hunspell-es tilix trash-cli wine wineglass winetricks

# Development/shell/system tools...
dnf5 install -y emacs fossil libgccjit libgccjit-devel libtool libvterm libvterm-tools mercurial mosh nodejs rpmconf rpmdeplint rpmlint rubygems setroubleshoot sshuttle tortoisehg

# Creative tools...
dnf5 install -y amsynth darktable drumkv1 gimp inkscape krita lv2-amsynth-plugin padthv1 samplv1 scribus synthv1 vst-amsynth-plugin
# Other music/audio apps? Unlike graphics, these don't need integration with system color management integration,
# and the Flatpaks don't seem very taxing on CPU/GPU, so far...
# ardour lmms musescore

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

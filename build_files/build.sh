#!/bin/bash -xe

# Debug, tests, and queries early in the chroot...
whoami
pwd
uname -a
rpm --query --all kernel
ls -aFhl /
find /ctx/ /etc/ /sysroot/ /usr/ /var/ -type d -name local -o -type d -name usrlocal
# exit 255

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /



# Fix driver for built-in speakers for Galaxy Book4 Pro 360.
# https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes
dnf5 install -y --allowerasing dkms kernel-devel kernel-headers kernel-tools kernel-modules kernel-modules-extra
mkdir -p /usr/src
cd /usr/src/
git clone https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes.git
cd ./samsung-galaxy-book-linux-fixes/

# NOTE: When building in the cloud, `uname -r` may not match the version of the kernel getting installed.
kernel_version_arch=$( rpm --query kernel --qf '%{version}-%{release}.%{arch}' )
sed -E 's|\$\( *uname -r *\)|'"$kernel_version_arch"'|g' --in-place **/install.sh
sed -E 's,dkms (build|install|match|remove|status|unbuild|uninstall) [[:alnum:]/\${}()"._-]+,& -k '"$kernel_version_arch/$( arch )"',g' --in-place **/install.sh
# NOTE: Neither /usr/local nor /var/usrlocal is mounted during setup in this chroot environment.
sed -E 's|/usr/local|/usr|g' --in-place **/install.sh
# NOTE: systemd actions other than enabling/disabling units also not available in chroot.
sed -E 's/^ *systemctl daemon-reload/# &/g' --in-place **/install.sh
sed -E 's/^ *systemctl (stop|(re)?start)/# &/g' --in-place **/install.sh
sed -E 's/(^ *systemctl [[:alnum:].,_-]+) --now/\1/g' --in-place **/install.sh

cd ./speaker-fix/
bash -xe ./install.sh --force
sed -E 's|/usr/local|/usr|g' --in-place /etc/systemd/system/max98390-hda*.service /usr/sbin/max98390-hda*.sh

cd ../mic-fix/
bash -xe ./install.sh --force

cd ../webcam-fix-libcamera/
# # TODO: webcam fix wants to run as regular user with sudo, *not* as root...
# bash -xe ./install.sh --skip-module-check --no-restart

# # Clean up Galaxy Book driver scripts?
# cd /usr/src/
# rm -rf ./samsung-galaxy-book-linux-fixes/



# Remove default Bluefin packages I don't actually want/need...
dnf5 remove -y code malcontent-control

# Alternative packaging systems...
dnf5 install -y nix snapd

# Annoying workarounds to get Snap to work under SELinux...
ln -sf "var/lib/snapd/snap" /snap
semanage fcontext --add --type snappy_var_lib_t /snap
restorecon -v /snap
for type in snappy_cli_t snappy_confine_t snappy_mount_t snappy_t snappy_unconfined_snap_t
do
    semanage permissive --add "$type"
done
systemctl enable snapd.socket snapd.service

# Quality of life stuff...
dnf5 install -y gnome-software gnome-shell-extension-gpaste gpaste hunspell-devel hunspell-eo hunspell-es tilix trash-cli wine wineglass winetricks

# Development/shell/system tools...
dnf5 install -y emacs fossil guile30 libgccjit libgccjit-devel lua luajit luarocks mercurial mosh nodejs-corepack pipx rpmconf rpmdeplint rpmlint rubygems setroubleshoot sshuttle tortoisehg yarnpkg

# Creative tools...
dnf5 install -y amsynth darktable drumkv1 gimp inkscape krita lv2-amsynth-plugin padthv1 samplv1 scribus synthv1 vst-amsynth-plugin
# Other music/audio apps? Unlike graphics, these don't need integration with system color management integration,
# and the Flatpaks don't seem very taxing on CPU/GPU, so far...
# ardour lmms musescore

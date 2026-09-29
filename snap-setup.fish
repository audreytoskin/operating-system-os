#!/usr/bin/fish

# Run with sudo...


# Annoying workarounds to get Snap to work under SELinux...
if test -L /home
then
    mv /home /home.symlink
    mkdir /home
fi
if ! grep -E '^ */var/home +/home +none +bind' /etc/fstab
then
    mount -o bind /var/home /home
    echo '/var/home    /home    none    bind,defaults,nofail' >> /etc/fstab
fi

systemctl restart snapd.socket snapd.service
snap wait system seed.loaded

snap install hello

for snap_bin in snap snapd snap-confine snap-update-ns
    ausearch --raw --comm "$snap_bin" | audit2allow -M my-"$snap_bin" 2> /dev/null
    if test -f ./my-"$snap_bin".pp
        semodule --install my-"$snap_bin".pp
    end
end

restorecon -v /snap
find /var/ -type d -name snapd -execdir restorecon -Rv '{}' ';'
find /var/ -type d -name snap -execdir restorecon -Rv '{}' ';'

systemctl restart snapd.socket snapd.service

set i 1
while not snap install snap-store
    if test "$i" -gt 20
        break
    end

    for snap_bin in snap snapd snap-confine snap-update-ns
        ausearch --raw --comm "$snap_bin" | audit2allow -M my-"$snap_bin"-again-"$i" 2> /dev/null
        if test -f ./my-"$snap_bin"-again-"$i".pp
            semodule --install my-"$snap_bin"-again-"$i".pp
        end
    end

    systemctl stop snapd.socket snapd.service
    umount /tmp/snap.rootfs*
    rm -rf /tmp/snap.rootfs*
    rm -rf /root/snap/
    rm -rf /var/snap/snap-store/
    restorecon -Rv /tmp/ /run/ /var/snap/ /var/lib/snapd/ /var/tmp/
    systemctl start snapd.socket snapd.service
    set i ( math "$i + 1" )
end

echo -e "\n\n*** Reboot, and continue part 2."

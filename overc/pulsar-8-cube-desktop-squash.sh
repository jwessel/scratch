#!/bin/sh

##### This is for Pulsar 8 ONLY. #####

# You can run this as follows

wget https://raw.githubusercontent.com/jwessel/scratch/master/overc/pulsar-8-cube-desktop-squash.sh
sh pulsar-8-cube-desktop-squash.sh


# NOTE: This will destroy you cube desktop and replace it with a copy of dom0
#       with the admin commands removed.
#       A cleaner approach will exist in a future release

##### Start script #####

# Remove existing cube-desktop
cube-ctl del -F cube-desktop

# Remove system recover data for cube-desktop
cd /var/lib/lxc
mkdir t
mount -o subvol=.factory /dev/vda4 t
dir=`btrfs subvol list t |grep cube-desktop |awk '{print $9}'`
btrfs subvol delete t/$dir
umount t
rmdir t


# Must be run from dom0 as root
cd /root
# Copy existing dom0 to tar.bz2 file
time tar -C / -cf ~/cube-desktop.tar --exclude ./root/cube-desktop.tar --exclude ./dev --exclude ./essential --exclude ./var/lib/lxc --exclude ./boot --exclude ./sys --exclude ./sysroot --exclude ./run --exclude ./proc --exclude ./usr_temp --exclude ./host .

# Install copy of dom0 as cube-desktop
cube-ctl add cube-desktop.tar -m dom0
rm cube-desktop.tar
perl -p -i -e 's/wr.start.auto = 0/wr.start.auto = 1/' /var/lib/lxc/cube-desktop/config
perl -p -i -e 's/lxc.start.auto = 1/lxc.start.auto = 0/' /var/lib/lxc/cube-desktop/config
perl -p -i -e 's/lxc.group =.*/lxc.group = peer/' /var/lib/lxc/cube-desktop/config

cat<<EOF>>/var/lib/lxc/cube-desktop/config
overc.screen-getty = 1
overc.network.link = all
overc.network.linkdevs = eth* wl* en*
EOF

# Create some directories
for e in proc sys run dev; do
   mkdir -p /var/lib/lxc/cube-desktop/rootfs/$e
done

# Remove some packages
chroot /var/lib/lxc/cube-desktop/rootfs rpm -e cube-cmd-server
chroot /var/lib/lxc/cube-desktop/rootfs rpm -e dom0-contctl
chroot /var/lib/lxc/cube-desktop/rootfs rpm -e cube-cmd-server-dom0-conf

# Fix up config files
rm -f /essential/var/lib/rpm/puppet_run 
perl -p -i -e 's/$network_prime_device = "all"/$network_prime_device = "e*"/' /essential/etc/puppet/manifests/site.pp
perl -p -i -e 's/^#(\$configure_network)/$1/' /essential/etc/puppet/manifests/site.pp
echo cube-desktop > /var/lib/lxc/cube-desktop/rootfs/etc/hostname

reboot

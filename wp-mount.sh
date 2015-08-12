#!/bin/bash 
wd=`dirname $(readlink -f $0)`

chroot=$wd/wp-jail
# source directory for mounts to be done
mounts=$wd/mounts

# check if mounts exist or perform
if [ "x" = "x$(mount|grep ${chroot}/wordpress)" ]; then
    mkdir -p ${chroot}/wordpress
    mount --bind -o ro ${mounts}/wp-core ${chroot}/wordpress
    mount --bind -o ro ${mounts}/plugins ${chroot}/wordpress/wp-content/plugins
    mount --bind -o ro ${mounts}/themes ${chroot}/wordpress/wp-content/themes
fi


# for unmount...
# for m in $(mount|grep ${chroot}|awk '{ print $3 }'|sort -r); do sudo umount $m; done

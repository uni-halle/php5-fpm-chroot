#!/bin/bash 

### created a simple chroot environment fo use in php5-fpm

wd=`dirname $(readlink -f $0)`

# path to the jail
chroot=$wd/wp-jail
# try to create it
mkdir -p "$chroot"

# we need the mini_sendmail binary
sendmail=$(which mini_sendmail);
# where to place it in jail
sendmailPath=/bin/sendmail

# rudimentary files, binaries and libraries to get php pool to run

dns_req="/etc/resolv.conf"		# required to lookup server-names
mail_req="$sendmail /bin/sh"		# required to call php's mail function
ld_req="/lib64/ld-linux-x86-64.so.2"	# required to load dynamic libraries inside the jail
# requirement to lookup user and group information eg. for sendmail
id_req="/etc/passwd /etc/nsswitch.conf /lib/x86_64-linux-gnu/libnss_nis.so.2 /lib/x86_64-linux-gnu/libnss_compat.so.2"


# put all requirements into a list to gather referenced libs later
links="$dns_req $mail_req $ld_req $id_req"

# if there is a problem or you may want to add some more programs
#links="$links $(which strace)"
#links="$links $(which ls)"

# directories to be copied into the jail
runtimedirs="/usr/share/zoneinfo"
# directories to be created within the jail
envdirs="/var/lib/php5 /bin /tmp"


####
# MAGIC starts here
####

# create required directories and asign rights 
for d in $runtimedirs $envdirs; do
        mkdir -p "${chroot}${d}"
        chown --reference="${d}" "${chroot}${d}"
        chmod --reference="${d}" "${chroot}${d}"
done

# copy the contents of the runtime dirs
for d in $runtimedirs; do
    cp -raL "${d}" "${chroot}${d}"
    #if [ "x" = "x$(mount|grep ${chroot}${d})" ]; then mount --bind -o ro "${d}" "${chroot}${d}"; fi
done

# find all required libraries to be available in jail

# temp-files to keep track of the paths
libList=`mktemp`
libListAll=`mktemp`
countLast=0

# generate the first list by all specified links
ldd ${links}|awk '{print $3}'|egrep '^/'|sort --unique >$libListAll
countNew=$(wc -l <$libListAll)

# some libraries might require other ones, so loop until all were found
while [ $countLast -ne $countNew ]; do
    countLast=$countNew
    cp "${libListAll}" "${libList}"
    # find all libs required currently and append to list
    ldd $(cat "${libListAll}")|awk '{print $3}'|egrep '^/' >>${libList}
    # remove duplicated
    cat ${libList}|sort --unique >${libListAll}
    countNew=$(wc -l <${libListAll})
done

# append required libraries to list of files to be copied
links="${links} $(cat $libListAll)"
# remove temp-files
rm $libList $libListAll

# copy all required files into jail
for l in $links; do
    echo $l
    mkdir -p "${chroot}$(dirname $l)" 2>/dev/null
    #ln -L "${l}" "${chroot}${l}" 2>/dev/null||cp -L "${l}" "${chroot}${l}" 2>/dev/null
    cp -aL "${l}" "${chroot}${l}" 2>/dev/null
done

# last but not least create the sendmail symlink to mini_sendmail
ln -sf $sendmail ${chroot}$sendmailPath



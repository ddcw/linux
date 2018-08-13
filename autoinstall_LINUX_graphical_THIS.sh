#!/bin/bash
#yum_core=`yum groups info core 2> /dev/null | head -53 | tail -48`
#yum_base=`yum groups info base 2> /dev/null | head -30 | tail -25`
cdrom='/mnt'
umount /dev/sr0 2> /dev/null
mount /dev/sr0 /mnt 1> /dev/null && echo "waiting..."
pack=`rpm -qa`
no_pack=`ls ${cdrom} | grep -v Packages`
[ -d ./iso_auto ] || mkdir iso_auto
cd ./iso_auto
[ -d ./Packages ] || mkdir ./Packages
for i in ${pack}
do
	cp -rf ${cdrom}/Packages/${i}.rpm ./Packages
done
for j in ${no_pack}
do
	cp -rf ${cdrom}/${j} .
done
sed -i '/initrd/c\\tappend initrd=initrd.img ks=cdrom:/isolinux/ks.cfg quiet' ./isolinux/isolinux.cfg
sed -i 's/Red Hat Enterprise Linux 7.3/Auto Install Linux by YGS/' ./isolinux/isolinux.cfg
sed -i '/timeout 600/ctimeout 50' ./isolinux/isolinux.cfg
sed -i '/menu default/d' isolinux/isolinux.cfg
sed -i '/label linux/amenu default' isolinux/isolinux.cfg
[ -d isolinux/ks.cfg ] || touch ./isolinux/ks.cfg
ks_value="install\nkeyboard 'us'\nrootpw --plaintext 123456\nlang zh_CN.UTF-8\nfirewall --disabled\nauth  --useshadow  --passalgo=sha512\ncdrom\ngraphical\nfirstboot --enable\nselinux --disabled\nnetwork  --bootproto=dhcp --device=etho\nreboot\ntimezone Asia/Shanghai\nbootloader --location=mbr\nclearpart --all\npart swap --fstype="swap" --size=2048\npart /boot --fstype="ext4" --size=200\npart / --fstype="ext4" --size=10240\n%packages\nchrony\n%end\n%post\nid ygs 2> /dev/null || useradd ygs\necho 123456 | passwd --stdin ygs\ncat >> /etc/yum.repos.d/base.repo << eof\n[base]\nname=baseserver\nbaseurl=file:///mnt/\nenable=1\ngpgcheck=0\neof\n%end"
echo -e ${ks_value} > ./isolinux/ks.cfg
pack_group=`cat /root/anaconda-ks.cfg | grep @`
for k in ${pack_group}
do
	sed -i "/%packages/a${k}" ./isolinux/ks.cfg
done
mkisofs -R -J -T -v -no-emul-boot -boot-load-size 4 -boot-info-table -V RHEL7 -b isolinux/isolinux.bin -c isolinux/boot.cat -o /RH_Graphical_by_ygs.iso .

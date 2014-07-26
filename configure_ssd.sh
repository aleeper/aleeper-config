if [ $# -lt 1 ]; then
  echo "Usage: $0 [BASE_LOCATION]"
  exit 1
fi

function append_to_file() {
  echo "$1" | sudo tee -a $2 > /dev/null
}


BASE_LOCATION=$1
FSTAB=$BASE_LOCATION/fstab
RCLOCAL=$BASE_LOCATION/rc.local
SYSCTL=$BASE_LOCATION/sysctl.conf

if [ ! -f $FSTAB ];   then echo -e "File not found: [$FSTAB]\nAborting!";  exit 1; fi
if [ ! -f $RCLOCAL ]; then echo -e "File not found: [$RCLOCAL\nAborting!"; exit 1; fi
if [ ! -f $SYSCTL ];  then echo -e "File not found: [$SYSCTL]\nAborting!"; exit 1; fi

echo "Backing up files:"
for i in $FSTAB $RCLOCAL $SYSCTL; do
  cp -v $i /tmp/`basename $i`.bak
done


# Add no atime to base partition
original=$(grep -h "errors=remount-ro" $FSTAB)
sudo sed -i 's/errors=remount-ro/noatime,&/g' $FSTAB

# 
# adding shared home
#echo "UUID=ad852fe3-cac5-4653-a38b-e57ff431cad5 /media/home  ext4  defaults,noatime 0 2" | sudo tee -a $FSTAB

append_to_file "# Put temp files in RAM drive"                          $FSTAB
append_to_file "tmpfs /var/log  tmpfs  defaults,noatime              0    0" $FSTAB
append_to_file "tmpfs /tmp      tmpfs  defaults,noatime,mode=1777    0    0" $FSTAB

exit 0

append_to_file "# Sharply reduce swap inclination" $SYSCTL
append_to_file "vm.swappiness=1"                   $SYSCTL
append_to_file "# Improve cache management"        $SYSCTL
append_to_file "vm.vfs_cache_pressure=50"          $SYSCTL

sed -i 's/exit 0//g' $RCLOCAL
append_to_file "fstrim -v /"                                                                                 $RCLOCAL
append_to_file "fstrim -v /media/home"                                                                       $RCLOCAL
append_to_file ""                                                                                            $RCLOCAL
append_to_file "for dir in apparmor apt cups dist-upgrade fsck gdm installer samba unattended-upgrades ; do" $RCLOCAL
append_to_file "  if [ ! -e /var/log/$dir ] ; then"                                                          $RCLOCAL
append_to_file "    mkdir /var/log/$dir"                                                                     $RCLOCAL
append_to_file "  fi"                                                                                        $RCLOCAL
append_to_file "done"                                                                                        $RCLOCAL
append_to_file ""                                                                                            $RCLOCAL
append_to_file "exit 0"                                                                                      $RCLOCAL

echo -e "\n--------------------------------------------------\n"
echo -e "    All done!"
echo -e "\n--------------------------------------------------\n"
echo "Here's the diff:"
for i in $FSTAB $RCLOCAL $SYSCTL; do
  echo -e "\n--------------------------------------------------\n"
  echo "File: $i"
  diff $i /tmp/`basename $i`.bak
done

exit 0


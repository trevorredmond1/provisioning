vboxmanage () { VBoxManage.exe "$@"; }

# Cludge to get the path of the directory where the vbox file is stored. 
# Used to create hard disk file in same directory as vbox file without using 
# absolute paths

# You will need to change the VM name to match one of your VM's
declare vm_name="Redhat"

#create VM
vboxmanage createvm --name $vm_name --register

# vboxmanage showvminfo displays line with the path to the config file -> grep "Config file returns it
declare vm_info="$(VBoxManage.exe showvminfo "$vm_name")"
declare vm_conf_line="$(echo "${vm_info}" | grep "Config file")"

# Windows: the extended regex [[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox matches everything that is a path 
# i.e. C:\ followed by anything not a \ and then repetitions of that ending in a filename with .vbox extension
declare vm_conf_file="$( echo "${vm_conf_line}" | grep -oE '[[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox' )"

# strip leading text and trailing filename from config file line to leave directory of VM
declare vm_directory_win="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\\[^\]\+\.vbox$//')"

# Strip leading text from the config file line and convert from windows path to wsl linux path 
declare vm_directory_linux="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\([[:upper:]]\):/\/mnt\/\L\1/ ; s/\\/\//g')"

# Remove file part of path leaving directory
vm_directory_linux="$(dirname "$vm_directory_linux")"

# WSL commands will use the linux path, whereas Windows native commands (most
# importantly VBoxManage.exe) will use the windows style path.
echo "${vm_directory_linux}"
echo "${vm_directory_win}"

#create virtual hard disk
vboxmanage createhd --filename $vm_directory_win\\$vm_name.vdi \
                    --size 10000 -variant Standard

echo $vm_directory_win\\$vm_name.vdi

#add storage controllers
vboxmanage storagectl $vm_name --name IDE_controller --add ide --bootable on
vboxmanage storagectl $vm_name --name SATA_controller --add sata --bootable on

#attatch an installation iso 
vboxmanage storageattach $vm_name \
            --storagectl IDE_controller \
            --port 0 \
            --device 0 \
            --type dvddrive \
            --medium "C:\\Users\\trevo\\Desktop\\BCIT\\Networking\\Project 1\\acit_4640\\CentOS-7-x86_64-Minimal-1810.iso"

#attatch the vb guest additions iso file 
vboxmanage storageattach $vm_name \
            --storagectl IDE_controller \
            --port 0 \
            --device 1 \
            --type dvddrive \
            --medium "c:\\Program Files\\Oracle\\VirtualBox\\VBoxGuestAdditions.iso"

#attatch a hard disk and specify that its an ssd
vboxmanage storageattach $vm_name \
            --storagectl SATA_controller \
            --port 0 \
            --device 0 \
            --type hdd \
            --nonrotational on \
            --medium "$vm_directory_win\\$vm_name.vdi" \
            --nonrotational on

#configure a vm
            vboxmanage modifyvm $vm_name\
            --groups ""\
            --ostype "RedHat_64"\
            --cpus 1\
            --hwvirtex on\
            --largepages on\
            --firmware bios\
            --nic1 natnetwork\
            --nat-network1 "sys_net_prov"\
            --cableconnected1 on\
            --macaddress1 "020000000001"\
            --boot1 disk\
            --boot2 net\
            --boot3 none\
            --boot4 none\
            --memory "1280"

#ssh and scp
ssh pxe 'sudo chown -R admin:wheel /usr/share/nginx'
scp wp_ks.cfg pxe:/usr/share/nginx/html/
scp -r configs pxe:/usr/share/nginx/html/
ssh pxe 'sudo chown -R nginx:wheel /usr/share/nginx'
ssh pxe 'sudo chown nginx:wheel /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'chmod ugo+r /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'chmod ugo+rx /usr/share/nginx/html/setup'
ssh pxe 'chmod -R ugo+r /usr/share/nginx/html/setup/*'

#start vm
vboxmanage startvm $vm_name --type gui


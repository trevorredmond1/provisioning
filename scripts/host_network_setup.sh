vboxmanage () { VBoxManage.exe "$@"; }

vboxmanage natnetwork add \
            --netname sys_net_prov \
            --network "192.168.254.0/24" \
            --dhcp on 

vboxmanage natnetwork modify \
            --netname sys_net_prov \
            --port-forward-4 "ssh:tcp:[]:50022:[192.168.254.10]:22" \
            --port-forward-4 "http:tcp:[]:50080:[192.168.254.10]:80" \
            --port-forward-4 "https:tcp:[]:50443:[192.168.254.10]:443" \
            --port-forward-4 "pxep:tcp:[]:50222:[192.168.254.5]:22"


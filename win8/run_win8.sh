#!/bin/sh

VM="win8"
CD=/home/definitly/win8_bootable.iso
#CD="/home/definitly/2TB/vm/ISO/ru_windows_7_ultimate_with_sp1_x64_dvd_u_677391.iso"

HD=/ntfs-2TB/vm/$VM/$VM.img


#UEFI=/home/definitly/2TB/vm/win7/BHYVE_UEFI.fd
UEFI=/bhyve/win10/BHYVE_UEFI_UHD630.fd

MEM=8G

IF="tap0"
MAC="mac=00:A0:98:78:32:10"
DPY="w=1918,h=1058"

doas ifconfig $IF up
doas kldload nmdm

# если диск не существует — создать
if [ ! -f "$HD" ]; then
    echo "Disk image not found, creating: $HD"
    doas truncate -s 45G "$HD"
fi


GPU_INTEL="-s 7,passthru,pci0:0:2:0"
GPU_ARGS=""

if [ "$1" = "gpu" ]; then
    echo "GPU passthrough enabled"

    doas devctl clear driver -f pci0:0:2:0
    doas devctl detach pci0:0:2:0
    doas devctl set driver pci0:0:2:0 ppt

    GPU_ARGS="$GPU_INTEL"
fi


CPU="cpus=4,sockets=1,cores=4,threads=1"

USB=""
USB2=""

for arg in "$@"; do
    case "$arg" in
        gpu)
            echo "GPU passthrough enabled"

            doas devctl clear driver -f pci0:0:2:0
            doas devctl detach pci0:0:2:0
            doas devctl set driver pci0:0:2:0 ppt

            GPU_ARGS="$GPU_INTEL"
            ;;
        usb)
            echo "USB passthrough enabled"

            doas devctl detach pci0:0:20:0
            doas devctl set driver pci0:0:20:0 ppt

#            doas devctl detach pci0:0:31:3
#            doas devctl set driver pci0:0:31:3 ppt

            USB="-s 11,passthru,0/20/0"
#            USB2="-s 12,passthru,0/31/3"
            ;;
    esac
done

APP_IMAGE="/bhyve/win10/app8.1.img"



    # Проверяем существует ли ISO
    if [ -f "$CD" ]; then
        echo "ISO found: $CD"
        CD_ARGS="-s 4,ahci-cd,$CD"
        FBUF_ARGS="-s 8,fbuf,tcp=0.0.0.0:5900,$DPY,wait"
    else
        echo "ISO not found, starting without CD"
        CD_ARGS=""
        FBUF_ARGS="-s 8,fbuf,tcp=0.0.0.0:5900,$DPY"
    fi

# 1. Проверяем наличие диска и формируем строку аргумента
if [ -f "${APP_IMAGE}" ]; then

    # Важно: добавляем пробел перед новым аргументом
    _bhyve_args=" -s 4:0,ahci-hd,${APP_IMAGE}"
fi

start_vm () {

    while true
    do
        # 2. Подставляем $_bhyve_args в конец или середину команды
        doas bhyve \
            -c $CPU \
            -s 0,hostbridge \
            -s 3,ahci-hd,$HD,sectorsize=512,bootindex=1 \
            -s 9,hda,play=/dev/dsp,rec=/dev/dsp \
            $CD_ARGS \
            $FBUF_ARGS \
            $GPU_ARGS \
            -s 10,virtio-net,$IF \
            -s 15,virtio-9p,sharename=/home/ \
            $VNC \
            $USB \
            $USB2 \
            -s 31,lpc \
            -l bootrom,$UEFI,fwcfg=qemu \
            -m $MEM  -w -P  -H -S \
            ${_bhyve_args} \
            $VM 
        
        RES=$?
        doas bhyvectl --destroy --vm=$VM
        
        if [ $RES -eq 1 ]
        then
            exit 1
        fi
        
        echo sleeping for 5 sec...
        sleep 5
    done
}



start_vm

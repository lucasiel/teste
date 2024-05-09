#!/bin/bash

cmd="qemu-system-x86_64 -drive file=${SERVER_IMAGE}.qcow2,format=qcow2 -m ${SERVER_MEMORY} -net nic,model=virtio"

if [ "$VNC" -eq 1 ]; then
	cmd+=" -vnc :$((SERVER_PORT - 5900)) -net user,hostfwd=tcp::3000-:3389"
else
	if [ "$SERVER_TYPE" -eq "Linux" ]; then
    		mkdir -p shared
		cmd+=" -virtfs local,path=shared,mount_tag=shared,security_model=none -nographic -net user,hostfwd=tcp::${SERVER_PORT}-:22"
	else 
		cmd+=" -nographic -net user,hostfwd=tcp::${SERVER_PORT}-:3389"
	fi
fi

IFS=','
read -ra port_ranges <<< "${SERVER_APORTS}"
for range in "${port_ranges[@]}"; do
    range=$(echo "$range" | tr -d '[:space:]')
    IFS='-' read -r start_port end_port <<< "$range"
    cmd+=",hostfwd=tcp::${start_port}-:${end_port}"
done

if [ -e "/dev/kvm" ]; then
    cmd+=" -enable-kvm -cpu host -smp $(nproc)"
else
    cmd+=" -cpu max,+avx -smp $(nproc)"
fi

if [ "$UEFI" -eq 1 ]; then
    qemu_cmd+=" -bios /OVMF.fd"
fi

if [ -n "${SERVER_CPU}" ]; then
	cmd+=" -smp ${SERVER_CPU}"
fi

if [ -n "${SERVER_ISO}" ]; then
	cmd+=" -cdrom ${SERVER_ISO}"
fi

echo -e "Starting VM"
if [ "$VNC" -eq 1 ]; then
    echo -e " VNC Active at: ${SERVER_IP}:${SERVER_PORT}"
	eval "$cmd" > /dev/null 2>&1
else
	eval "$cmd"
fi

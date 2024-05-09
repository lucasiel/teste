#!/bin/bash

cmd="qemu-system-x86_64 -drive file=${SERVER_IMAGE}.qcow2,format=qcow2 -virtfs local,path=shared,mount_tag=shared,security_model=none -m ${SERVER_MEMORY} -net nic,model=virtio -nographic -net user,hostfwd=tcp::${SERVER_PORT}-:22"

mkdir -p shared
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

if [ -n "${SERVER_CPU}" ]; then
	cmd+=" -smp ${SERVER_CPU}"
fi

eval "$cmd"

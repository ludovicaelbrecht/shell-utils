#!/bin/bash
#removes specified kernels and their related kernel packages
#usage: ./kernel-rm.sh 4.11.7-200.fc25 4.11.8-200.fc25

for i in "$@" ; 
	do PKGS="$PKGS kernel-devel-${i}.x86_64 kernel-modules-${i}.x86_64 kernel-${i}.x86_64  kernel-core-${i}.x86_64";
done

dnf remove ${PKGS}

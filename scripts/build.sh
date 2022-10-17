#!/bin/bash

# ------------- DEFINE VARIABLES ----------------"
echo $BUILD_ARCH | tr 'a-z' 'A-Z' > build_arch_upper_tmp
export BAUP=$(cat build_arch_upper_tmp)
export BUILD_NUMBER=$(curl -s http://download.proxmox.com/debian/pve/dists/bullseye/pve-no-subscription/binary-amd64/Packages | grep ^Filename  | grep pve-kernel-5 | grep amd64.deb$ | sort -V | grep -oP '5.15.\d+-\d+' | tail -1 | grep -o .$)

# ------------- CLONE SOURCE REPO ----------------"
git clone --depth 1 --branch pve-kernel-5.15 https://git.proxmox.com/git/pve-kernel.git


# ------------- ENTER FOLDER ----------------"
cd pve-kernel


echo "------------- ADD CPU PATCH ----------------"
wget -O patches/kernel/0032-add-uarch.patch https://raw.githubusercontent.com/graysky2/kernel_compiler_patch/master/more-uarches-for-kernel-5.15-5.16.patch


# ------------- CHANGE CONFIGURATION ----------------"
sed -i "s/^.*\bKREL=\b.*$/KREL=$BUILD_NUMBER/g" Makefile
sed -i "s/^.*\bPKGREL=\b.*$/PKGREL=$BUILD_NUMBER/g" Makefile
sed -i "s/\EXTRAVERSION=-\${KREL}-pve/EXTRAVERSION=-\${KREL}-pve-$BUILD_ARCH/g" Makefile
sed -i 's/\-e CONFIG_PAGE_TABLE_ISOLATION/\-e CONFIG_PAGE_TABLE_ISOLATION \\/g' debian/rules
sed -i '/^\-e CONFIG_PAGE_TABLE_ISOLATION.*/a \-d CONFIG_GENERIC_CPU \\\n\-e CONFIG_MARCHITECTURE \\\n\-e CONFIG_X86_INTEL_USERCOPY \\\n\-e CONFIG_X86_USE_PPRO_CHECKSUM \\\n\-e CONFIG_X86_P6_NOP \\\n\-e CONFIG_CC_HAS_RETURN_THUNK \\\n\-e CONFIG_SPECULATION_MITIGATIONS \\\n\-e CONFIG_RETHUNK \\\n\-e CONFIG_CPU_UNRET_ENTRY \\\n\-e CONFIG_CPU_IBPB_ENTRY \\\n\-e CONFIG_CPU_IBRS_ENTRY' debian/rules
sed -i "s/CONFIG_MARCHITECTURE/CONFIG_M$BAUP/g" debian/rules


# ------------- START BUILD ----------------"
yes "" | make PVE_BUILD_CFLAGS="-march=$BUILD_ARCH" deb

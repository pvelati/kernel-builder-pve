#!/bin/bash

set -eau

# ------------- DEFINE BUILD VARIABLES ----------------
export BAUP=$(echo $BUILD_ARCH | tr 'a-z' 'A-Z')
export BUILD_NUMBER=$(curl -s http://download.proxmox.com/debian/pve/dists/bullseye/pve-no-subscription/binary-amd64/Packages | grep ^Filename  | grep pve-kernel-5 | grep amd64.deb$ | sort -V | grep -oP 'kernel-5.15.\d+-\d+' | tail -1 | grep -o .$)
# export PACKAGE_NUMBER=$(curl -s http://download.proxmox.com/debian/pve/dists/bullseye/pve-no-subscription/binary-amd64/Packages | grep ^Filename  | grep pve-kernel-5 | grep amd64.deb$ | sort -V | grep -oP 'pve_5.15.\d+-\d+' | tail -1 | grep -o .$)


# ------------- CLONE SOURCE REPO AND ENTER FOLDER ----------------
git clone --depth 1 --branch pve-kernel-5.15 https://git.proxmox.com/git/pve-kernel.git
cd pve-kernel


# ------------- ADD CPU PATCH ----------------
wget -O patches/kernel/0032-add-uarch.patch https://raw.githubusercontent.com/graysky2/kernel_compiler_patch/master/more-uarches-for-kernel-5.15-5.16.patch


# ------------- CHANGE CONFIGURATION ----------------
sed -i "s/^.*\bKREL=\b.*$/KREL=$BUILD_NUMBER/g" Makefile
# sed -i "s/^.*\bPKGREL=\b.*$/PKGREL=$PACKAGE_NUMBER/g" Makefile
sed -i "s/\EXTRAVERSION=-\${KREL}-pve/EXTRAVERSION=-\${KREL}-pve-$BUILD_ARCH/g" Makefile
sed -i 's/\-e CONFIG_PAGE_TABLE_ISOLATION/\-e CONFIG_PAGE_TABLE_ISOLATION \\/g' debian/rules
sed -i '/^\-e CONFIG_PAGE_TABLE_ISOLATION.*/a \-d CONFIG_GENERIC_CPU \\\n\-e CONFIG_MARCHITECTURE \\\n\-e CONFIG_X86_INTEL_USERCOPY \\\n\-e CONFIG_X86_USE_PPRO_CHECKSUM \\\n\-e CONFIG_X86_P6_NOP \\\n\-e CONFIG_CC_HAS_RETURN_THUNK \\\n\-e CONFIG_SPECULATION_MITIGATIONS \\\n\-e CONFIG_RETHUNK \\\n\-e CONFIG_CPU_UNRET_ENTRY \\\n\-e CONFIG_CPU_IBPB_ENTRY \\\n\-e CONFIG_CPU_IBRS_ENTRY' debian/rules
sed -i "s/CONFIG_MARCHITECTURE/CONFIG_M$BAUP/g" debian/rules


# ------------- START BUILD ----------------
#export BUILD_FLAGS="-mtune=$BUILD_ARCH -march=$BUILD_ARCH -O2 -flto -ftree-vectorize -pipe"
export BUILD_FLAGS="-mtune=$BUILD_ARCH -march=$BUILD_ARCH -O2"
yes "" | make CFLAGS="$BUILD_FLAGS" CXXFLAGS="$BUILD_FLAGS" deb


# ------------- REMOVE UNUSED FILES ----------------
rm -f ../pve-kernel/pve-kernel-libc*.deb


# ------------- DEFINE METAPACKAGE VARIABLES ----------------
echo "KERNEL_VERSION=$(ls pve-headers-*.deb | grep -oP '5.15.\d+-\d+' | head -n 1)" >> $GITHUB_ENV
echo "META_VERSION=$(date -u +%y%m%d%H%M)" >> $GITHUB_ENV


# ------------- RELOAD GLOBAL VARIABLES ----------------
source $GITHUB_ENV


# ------------- START BUILD METAPACKAGE ----------------
cd ../metapackage
cat ns-control-TEMPLATE | envsubst > ns-control
equivs-build ns-control


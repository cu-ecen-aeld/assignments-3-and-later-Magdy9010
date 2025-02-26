#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    #Deep clean the kernel build-tree removing the .config file with any existing configurations
    echo =======    mproper     =======
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper

    echo =======     deconfig    =======
    #Configure for our "virt" arm dev board we'll simulate in qemu
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig

    echo =======    all     =======
    #Build a kernel image for booting with QEMU - build VMlinux
    make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all

    echo =======   modules =======
    #Build any kernel modules
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} modules

    echo =======   dtbs  =======
    #Build device tree
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p "$OUTDIR/rootfs"
cd "$OUTDIR/rootfs"

mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig

    
else
    echo "====== Changing Directory to BusyBox ======"
    cd busybox
fi

# TODO: Make and install busybox
echo "====== Make BusyBox ======"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 

echo "====== Install BusyBox ======"
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "====== Library dependencies ======"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | echo "$(grep "program interpreter")"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | echo "$(grep "Shared library")"

# TODO: Add library dependencies to rootfs
echo "====== Add library dependencies to rootfs ======"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
mkdir -p "${OUTDIR}/rootfs/lib"
mkdir -p "${OUTDIR}/rootfs/lib64"

echo "====== coping ld-linux-aarch64.so.1 ====== "
cp "$SYSROOT/lib/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib/"

echo "====== coping libm.so.6 ======"
cp "$SYSROOT/lib/aarch64-linux-gnu/libm.so.6" "${OUTDIR}/rootfs/lib/"

echo "====== coping libresolv.so.2 ======"
cp "$SYSROOT/lib/aarch64-linux-gnu/libresolv.so.2" "${OUTDIR}/rootfs/lib/"

echo "====== coping libc.so.6 ======"
cp "$SYSROOT/lib/aarch64-linux-gnu/libc.so.6" "${OUTDIR}/rootfs/lib/"

# TODO: Make device nodes
echo "====== Make device nodes ========"
sudo mknod -m 666 "$OUTDIR/rootfs/dev/null" c 1 3
sudo mknod -m 600 "$OUTDIR/rootfs/dev/console" c 5 1


# TODO: Clean and build the writer utility
echo "====== Change Directory to FINDER APP ======"
cd "$FINDER_APP_DIR"

echo "====== Clean and build the writer utility ========"
make clean
make CROSS_COMPILE=$CROSS_COMPILE

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "======= Coping old assignments Scripts ======="
cp finder.sh finder-test.sh autorun-qemu.sh "${OUTDIR}/rootfs/home" 

echo "======= Coping assignment.txt & username.txt ======="     
mkdir "${OUTDIR}/rootfs/home/conf"
CONF_SRC_DIR=/home/ubuntu/advLinux/assignment-1-amhatata/finder-app/conf

#cp conf/assignment.txt conf/username.txt "${OUTDIR}/rootfs/home/conf"
cp "${CONF_SRC_DIR}/assignment.txt" "${OUTDIR}/rootfs/home/conf"
cp "${CONF_SRC_DIR}/username.txt" "${OUTDIR}/rootfs/home/conf"


# TODO: Chown the root directory
echo "======= Chown the root directory ======="
sudo chown -R root:root *
#"${OUTDIR}/rootfs"

cd "$OUTDIR/rootfs"

# TODO: Create initramfs.cpio.gz
echo "======= Create initramfs.cpio.gz ======="
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
echo "======= cpio.gzip ======="
gzip -f -v "${OUTDIR}/initramfs.cpio"

##find . | cpio -H newc -ov --owner root:root | gzip -9 > ${OUTDIR}/initramfs.cpio.gz

echo "======= All done ======="
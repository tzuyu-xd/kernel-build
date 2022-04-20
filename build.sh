#!/usr/bin/env bash

 #
 # Copyright (C) 2022 a tzuyu-xd property
 #

if [ ! -d "$KERNEL_DIR/kernel_ccache" ]; 
    then
    mkdir -p "$KERNEL_DIR/kernel_ccache"
    fi
    export CCACHE_DIR="$KERNEL_DIR/kernel_ccache"
    export CCACHE_EXEC=$(which ccache)
    export USE_CCACHE=1
    ccache -M 2G
    ccache -z

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$KERNEL_DIR/$DEVICE

##----------------------------------------------------------##
# Device Name and Model
MODEL=Xiaomi
DEVICE=Ginkgo

# Kernel Version Code
VERSION=X1

# Kernel Defconfig
DEFCONFIG=vendor/ginkgo-perf_defconfig

# Files
IMAGE=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
DTBO=$KERNEL_DIR/out/arch/arm64/boot/dtbo.img

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME=FanEdition
FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE}-Kernel-${TANGGAL}.zip
	
##------------------------------------------------------##
# Export Variables
function exports() {
        
        # Export ARCH/SUBARCH And PATH
        export ARCH=arm64
        export SUBARCH=arm64
        export SDC_DIR="$KERNEL_DIR/CLANG"
        export GCC_DIR="$KERNEL_DIR/GCC32"
        export GCC64_DIR="$KERNEL_DIR/GCC64"
        export PATH="${SDC_DIR}/bin:${GCC64_DIR}/bin:${GCC_DIR}/bin:/usr/bin:${PATH}"

        # Export Local Version
        export LOCALVERSION="-${VERSION}"
        
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=Ubuntu
        export KBUILD_BUILD_USER="tzuyu-xd"
        
        # CI
        if [ "$CI" ]
           then
               
           if [ "$CIRCLECI" ]
              then
                  export KBUILD_BUILD_VERSION=${CIRCLE_BUILD_NUM}
                  export CI_BRANCH=${CIRCLE_BRANCH}
           elif [ "$DRONE" ]
	      then
		  export KBUILD_BUILD_VERSION=${DRONE_BUILD_NUMBER}
		  export CI_BRANCH=${DRONE_BRANCH}
           fi
		   
        fi
	export PROCS=$(nproc --all)
	export DISTRO=$(source /etc/os-release && echo "${NAME}")
	}
        
##----------------------------------------------------------------##
# Telegram Bot Integration

function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
	}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}
	
##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
	# Push Notification
	post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$PATH</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	
	# Compile
    if [ -d ${KERNEL_DIR}/CLANG ];
	   then
	       make -j$(nproc --all) O=out ARCH=arm64 SUBARCH=arm64 ${DEFCONFIG}
	       make -j$(nproc --all) ARCH=arm64 SUBARCH=arm64 O=out \
	       CC=${SDC_DIR}/bin/clang \
	       NM=${SDC_DIR}/bin/llvm-nm \
	       AR=${SDC_DIR}/bin/llvm-ar \
	       AS=${SDC_DIR}/bin/llvm-as \
	       LD=${SDC_DIR}/bin/ld.lld \
	       OBJCOPY=${SDC_DIR}/bin/llvm-objcopy \
	       OBJDUMP=${SDC_DIR}/bin/llvm-objdump \
	       STRIP=${SDC_DIR}/bin/llvm-strip \
	       CROSS_COMPILE=${SDC_DIR}/bin/aarch64-linux-gnu- \
	       CROSS_COMPILE_ARM32=${SDC_DIR}/bin/arm-linux-gnueabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	fi

    # Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
	       post_msg " Kernel Compilation Finished. Started Zipping "
	fi
	}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	cp $DTBO AnyKernel3
	
	# Zipping and Push Kernel
	cd $AK3_DIR || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${PATH}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
        cd ..
        }
    
##----------------------------------------------------------##

exports
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping

##----------------*****-----------------------------##
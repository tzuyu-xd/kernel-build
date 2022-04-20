#!/usr/bin/env bash

echo "git cloning it now...."
# Kernel Sources
git clone https://github.com/tzuyu-xd/android_kernel_xiaomi_ginkgo -b MiuiQ $KERNEL_DIR/DEVICE
git clone https://github.com/fajar3109/arm-linux-androideabi-4.9 -b main --depth=1 $KERNEL_DIR/GCC32
git clone https://github.com/fajar3109/aarch64-linux-android-4.9 -b main --depth=1 $KERNEL_DIR/GCC64
git clone https://github.com/kdrag0n/proton-clang.git --depth=1 $KERNEL_DIR/CLANG
git clone https://github.com/tyuzu-xd/AnyKernel3.git --depth=1 $KERNEL_DIR/AK3_DIR

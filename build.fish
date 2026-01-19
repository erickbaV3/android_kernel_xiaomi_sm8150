#!/usr/bin/fish

# --- Settings ---
set -x ARCH arm64
set -x DEFCONFIG cepheus_defconfig
set -x OUT_DIR out
set -x ANYKERNEL_DIR AnyKernel

set -x TC_DIR $HOME/toolchains/clang-r547379
set -x PATH $TC_DIR/bin $PATH

set -x KBUILD_BUILD_USER "JleMoHuCHuKeT"
set -x KBUILD_BUILD_HOST "host"

set MAKE_OPTS \
    ARCH=$ARCH \
    O=$OUT_DIR \
    CC="ccache clang" \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    CLANG_TRIPLE=aarch64-linux-gnu \
    AR=llvm-ar \
    LD=ld.lld \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    KCFLAGS="-O3 -march=armv8.2-a+dotprod -mcpu=cortex-a76+crypto" \
    -j(nproc --all)

function build_kernel
    read -l -P "Clean out? [y/N]: " confirm_clean
    if test "$confirm_clean" = "y" -o "$confirm_clean" = "Y"
        echo "cleaning $OUT_DIR..."
        rm -rf $OUT_DIR
    end

    mkdir -p $OUT_DIR
    if not test -f $OUT_DIR/.config
        make $MAKE_OPTS $DEFCONFIG
    end

    read -l -P "open nconfig? [y/N]: " confirm_nconfig
    if test "$confirm_nconfig" = "y" -o "$confirm_nconfig" = "Y"
        make $MAKE_OPTS nconfig
    end
    echo (set_color cyan)"start build..."(set_color normal)
    mkdir -p $OUT_DIR
    
    make $MAKE_OPTS Image-dtb
    
    if test -f $OUT_DIR/arch/arm64/boot/Image-dtb
        echo (set_color green)"Build ended"(set_color normal)
        copy_to_anykernel
    else
        echo (set_color red)"error: kernel not found in out"(set_color normal)
        exit 1
    end
end

function copy_to_anykernel
    set -l ZIP_NAME "openela_ksun_susfs.zip"
    if test -d $ANYKERNEL_DIR
        cp $OUT_DIR/arch/arm64/boot/Image-dtb $ANYKERNEL_DIR/
        pushd $ANYKERNEL_DIR
        zip -r9 ~/$ZIP_NAME ./* 
        popd
        echo (set_color green)"AK3 zip ready at ~/openela_ksun_susfs.zip"(set_color normal)
    else
        echo (set_color red)"error while making zip"(set_color normal)
    end
end

switch "$argv[1]"
    case "clean"
        rm -rf $OUT_DIR
    case "*"
        build_kernel
end

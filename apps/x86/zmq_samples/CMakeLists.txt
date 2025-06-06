#
# Copyright 2018, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.8.2)

project(zmq_samples)

include(ExternalProject)
# Include CAmkES VM helper functions
include(${CAMKES_VM_HELPERS_PATH})
find_package(camkes-vm-linux REQUIRED)
include(${CAMKES_VM_LINUX_HELPERS_PATH})

set(NumberVMs 3)

# CMake foreach RANGE loops are 0..num inclusive....
MATH(EXPR NumberVMsLess1 "${NumberVMs}-1")

# Declare VM component: Init
foreach(i RANGE ${NumberVMsLess1})
    DeclareCAmkESVM("Init${i}")
endforeach()

DeclareCamkesComponent(virtqueueinit)

# Get 32-bit Linux VM files
# GetArchDefaultLinuxKernelFile("32" kernel_file)
# GetArchDefaultLinuxRootfsFile("32" rootfs_file)

set(kernel_file "/host/custom-vm-kernel/linux-stable/arch/x86/boot/bzImage")
set(rootfs_file "/host/custom-vm-kernel/buildroot-2023.11/output/images/rootfs.cpio")

foreach(i RANGE ${NumberVMsLess1})
    AddFileToOverlayDir(
        "interfaces"
        ${CMAKE_CURRENT_SOURCE_DIR}/scripts/network_interface_${i}
        "etc/network"
        overlay_vm${i}
    )
endforeach()

set(SYSROOT "${CMAKE_CURRENT_BINARY_DIR}/sysroot")
include(cross_compiling)
FindCustomPollyToolchain(LINUX_32BIT_TOOLCHAIN "linux-gcc-32bit-pic")

ExternalProject_Add(
    zmq_external
    SOURCE_DIR
    ${LIBZMQ_PATH}
    BINARY_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/zmq_external
    BUILD_ALWAYS
    ON
    EXCLUDE_FROM_ALL
    CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${LINUX_32BIT_TOOLCHAIN}
    -DCMAKE_INSTALL_PREFIX=${SYSROOT}
    -DPOLLER=epoll
    -DWITH_PERF_TOOL=ON
    -DBUILD_TESTS=OFF
)

# ExternalProject_Add(
#     demoapps_external
#     SOURCE_DIR
#     ${CMAKE_CURRENT_SOURCE_DIR}/src/user
#     BINARY_DIR
#     ${CMAKE_CURRENT_BINARY_DIR}/src/user
#     DEPENDS
#     zmq_external
#     BUILD_ALWAYS
#     ON
#     EXCLUDE_FROM_ALL
#     CMAKE_ARGS
#     -DCMAKE_TOOLCHAIN_FILE=${LINUX_32BIT_TOOLCHAIN}
#     -DCMAKE_INSTALL_PREFIX=${SYSROOT}
# )

# include(external-project-helpers)
# DeclareExternalProjObjectFiles(
#     demoapps_external
#     ${SYSROOT}/bin
#     FILES
#     client
#     server
#     sink
#     source
#     worker
#     pub
#     sub
# )
# macro(AddZMQBinary binary_name)
#     foreach(i RANGE ${NumberVMsLess1})
#         AddFileToOverlayDir(
#             "${binary_name}"
#             ${CMAKE_CURRENT_BINARY_DIR}/sysroot/bin/${binary_name}
#             "bin/"
#             overlay_vm${i}
#         )
#     endforeach()
# endmacro()

# AddZMQBinary(client)
# AddZMQBinary(server)
# AddZMQBinary(sink)
# AddZMQBinary(source)
# AddZMQBinary(worker)
# AddZMQBinary(pub)
# AddZMQBinary(sub)

foreach(i RANGE ${NumberVMsLess1})
    
        AddFileToOverlayDir(
            "S91_init"
            ${CMAKE_CURRENT_SOURCE_DIR}/src/user/init_${i}.sh
            "etc/init.d"
            overlay_vm${i}
        )
        # AddFileToOverlayDir(
        #     "name"
        #     ${CMAKE_CURRENT_SOURCE_DIR}/scripts/initname_${i}.sh
        #     "etc/profile.d"
        #     overlay_vm${i}
        # )
    # Add the buildroot overlay to our bare rootfs image
    AddOverlayDirToRootfs(
        overlay_vm${i}
        ${rootfs_file}
        "buildroot"
        "rootfs_install"
        output_rootfs_location_vm${i}
        rootfs_target_vm${i}
    )
    AddToFileServer(
        "vm${i}_rootfs.cpio"
        "${output_rootfs_location_vm${i}}"
        DEPENDS
        rootfs_target_vm${i}
    )
endforeach()

# Decompress Linux Kernel image and add to file server
DecompressLinuxKernel(extract_linux_kernel decompressed_kernel ${kernel_file})
AddToFileServer("bzimage" ${decompressed_kernel} DEPENDS extract_linux_kernel)

# Initialise CAmkES Root Server with addition CPP includes
if(CAKEML_FILTER)
    DeclareCAmkESVMRootServer(zmq_cakeml.camkes)
else()
    DeclareCAmkESVMRootServer(zmq_samples.camkes)
endif()

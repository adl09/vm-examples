#
# Copyright 2023, DornerWorks
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.8.2)

project(minimal_64)

# Include CAmkES VM helper functions
include(${CAMKES_VM_HELPERS_PATH})
find_package(camkes-vm-linux REQUIRED)
include(${CAMKES_VM_LINUX_HELPERS_PATH})

set(CMAKE_BUILD_TYPE:STRING=Debug)
set(KernelDebugBuild:BOOL=ON)

# Declare VM component: Init0
DeclareCAmkESVM(Init0)

# Get Default Linux VM files
GetDefaultLinuxKernelFile(kernel_file)
GetDefaultLinuxRootfsFile(rootfs_file)

# Decompress Linux Kernel image and add to file server
DecompressLinuxKernel(extract_linux_kernel decompressed_kernel ${kernel_file})
AddToFileServer("bzimage" ${decompressed_kernel} DEPENDS extract_linux_kernel)

# Add rootfs images into file server
AddToFileServer("rootfs.cpio" ${rootfs_file})

# Initialise CAmkES Root Server with addition CPP includes
DeclareCAmkESVMRootServer(minimal.camkes)

if(SIMULATION)
    include(simulation)
    GenerateSimulateScript()
endif()

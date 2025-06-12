#
# Copyright 2018, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.8.2)

# Define kernel config options
set(KernelSel4Arch x86_64 CACHE STRING "" FORCE)
set(KernelMaxNumNodes 1 CACHE STRING "" FORCE)

set(SIMULATION OFF CACHE BOOL "Include only simulation compatible tests")
set(RELEASE OFF CACHE BOOL "Performance optimized build")

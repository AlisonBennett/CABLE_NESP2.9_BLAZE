#!/bin/bash

show_help() {
    cat << EOF
Usage: ./$(basename "${0}") [OPTIONS]

Build script wrapper around CMake.

Options:
      --clean   Delete build directory before invoking CMake.
      --mpi     Compile MPI executable.
  -d, --debug   Compile in debug mode.
  -v, --verbose Enable verbose output when building the project.
  -h, --help    Show this screen.

EOF
}

cmake_args=(-DCMAKE_BUILD_TYPE=Release)
cmake_build_args=()

# Argument parsing adapted and stolen from http://mywiki.wooledge.org/BashFAQ/035#Complex_nonstandard_add-on_utilities
while [ $# -gt 0 ]; do
    case $1 in
        --clean)
            rm -r build
            ;;
        --mpi)
            mpi=1
            cmake_args+=(-DCABLE_MPI="ON")
            cmake_args+=(-DCMAKE_Fortran_COMPILER="mpif90")
            ;;
        -d|--debug)
            cmake_args+=(-DCMAKE_BUILD_TYPE=Debug)
            ;;
        -v|--verbose)
            cmake_build_args+=(-v)
            ;;
        -h|--help)
            show_help
            exit
            ;;
        ?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
    esac
    shift
done

if hostname -f | grep gadi.nci.org.au > /dev/null; then
    . /etc/bashrc
    module purge
    module add cmake/3.24.2
    module add intel-compiler/2019.5.281
    module add netcdf/4.6.3
    # This is required so that the netcdf-fortran library is discoverable by
    # pkg-config:
    prepend_path PKG_CONFIG_PATH "${NETCDF_BASE}/lib/Intel/pkgconfig"
    if [[ -n $mpi ]]; then
        module add intel-mpi/2019.5.281
    fi
fi

if hostname -f | grep Seans-MacBook-Pro.local > /dev/null; then
    . /Users/seanbryan/dev_local/spack/share/spack/setup-env.sh
    spack load cmake@3.27.9 netcdf-fortran@4.6.1 openmpi@5.0.2
fi

cmake -S . -B build "${cmake_args[@]}" &&\
cmake --build build -j 4 "${cmake_build_args[@]}" &&\
cmake --install build --prefix .

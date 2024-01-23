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

# Argument parsing adapted and stolen from http://mywiki.wooledge.org/BashFAQ/035#Complex_nonstandard_add-on_utilities
while [ $# -gt 0 ]; do
    case $1 in
        --clean)
            clean=1
            ;;
        --mpi)
            mpi=1
            ;;
        -d|--debug)
            debug=1
            ;;
        -v|--verbose)
            verbose=1
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

if [[ -n $clean ]]; then
    rm -r build
fi

cmake_args=()
if [[ -n $debug ]]; then
    cmake_args+=(-DCMAKE_BUILD_TYPE=Debug)
else
    cmake_args+=(-DCMAKE_BUILD_TYPE=Release)
fi
if [[ -n $mpi ]]; then
    cmake_args+=(-DCABLE_MPI="ON")
    cmake_args+=(-DMPI_Fortran_COMPILER="mpif90")
fi

cmake_build_args=()
if [[ -n $verbose ]]; then
    cmake_build_args+=(-v)
fi

cmake -S . -B build "${cmake_args[@]}" &&\
cmake --build build -j 4 "${cmake_build_args[@]}" &&\
cmake --install build --prefix .

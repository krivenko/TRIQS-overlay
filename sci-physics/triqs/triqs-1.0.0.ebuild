# Copyright 2011-2013 Igor Krivenko
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )
PYTHON_REQ_USE=threads

inherit cmake-utils python-single-r1

if [[ ${PV} == 9999* ]] ; then
        inherit git-2
        EGIT_REPO_URI="https://github.com/TRIQS/triqs.git"
else
        SRC_URI="https://github.com/TRIQS/triqs/archive/${PV}.zip"
fi

DESCRIPTION="Toolbox for Research on Interacting Quantum Systems"
HOMEPAGE="http://ipht.cea.fr/triqs/"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="python doc test"
REQUIRED_USE="
    python? ( ${PYTHON_REQUIRED_USE} )
    doc? ( python )
"

RDEPEND="${PYTHON_DEPS}
    virtual/blas
    virtual/lapack
    virtual/cblas
    || ( 
        >=sys-devel/gcc-4.6.3
        >=sys-devel/clang-3.1
        >=dev-lang/icc-13.0.0
    )
    virtual/mpi
    >=sci-libs/fftw-3.2.0
    >=sci-libs/hdf5-1.8.0
    >=dev-libs/boost-1.49[python,mpi]
    sci-libs/scipy
    dev-python/numpy
    dev-python/h5py
    dev-python/mpi4py
    >=dev-python/matplotlib-0.99
    >=dev-python/cython-0.17
    dev-libs/gmp[cxx]
"
DEPEND="${RDEPEND}
    doc? ( >=dev-python/sphinx-1.0.1[latex] dev-python/pyparsing )
"

pkg_setup() {
    python-single-r1_pkg_setup 

    if use python && has_version dev-python/ipython; then
        einfo "dev-python/ipython is installed."
        einfo "A second script named ipytriqs will be generated along with pytriqs,"
        einfo "where the standard python shell is replaced by the ipython one."
    fi
}

src_configure() {
 
    local mycmakeargs="
        $(cmake-utils_use python PythonSupport)
        $(cmake-utils_use doc Build_Documentation)
        $(cmake-utils_use test Build_Triqs_General_Tools_Test)
    "
    
    if use python; then
        mycmakeargs+=" -DPYTHON_INTERPRETER=$(python_get_PYTHON)"
        mycmakeargs+=" -DPYTHON_LIBRARY=$(python_get_library_path)"
    fi
    
    if use doc && has_version dev-libs/mathjax; then
        mycmakeargs+=" -DMATHJAX_PATH=${EROOT}usr/share/mathjax"
    fi

    cmake-utils_src_configure
}

src_install() {
    cmake-utils_src_install

    # Documentation
    if use doc; then
        doc_src="${ED}/usr/share/doc/triqs"
        doc_dst="${ED}/usr/share/doc/${PF}"
        einfo "Installing documentation ..."
        mv "${doc_src}" "${doc_dst}"
    fi
}

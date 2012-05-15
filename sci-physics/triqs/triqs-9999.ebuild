# Copyright 2011-2012 Igor Krivenko
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit cmake-utils python git-2 multilib

DESCRIPTION="Toolbox for Research on Interacting Quantum Systems"
HOMEPAGE="http://ipht.cea.fr/triqs/"
EGIT_REPO_URI="https://github.com/TRIQS/TRIQS.git"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="+cthyb hubbard1 wien2k pade doc development test"

RDEPEND="virtual/mpi
	>=dev-libs/boost-1.46[python,mpi]
	>=sci-libs/hdf5-1.8.0
	>=sci-libs/fftw-3.2.0
	virtual/blas
	virtual/lapack
	virtual/cblas
	>=dev-libs/blitz-0.9
	dev-python/numpy
	sci-libs/scipy
	dev-python/h5py
	>=dev-python/matplotlib-0.99
	wien2k? ( virtual/fortran )
	pade? ( dev-libs/gmp[cxx] )
"
DEPEND="${RDEPEND}
	doc? ( >=dev-python/sphinx-1.0.1[latex] )"
PYTHON_DEPEND="2:2.6.5"

pkg_setup() {
	python_pkg_setup
	if has_version dev-python/ipython; then
		einfo "dev-python/ipython is installed."
		einfo "A second script named ipytriqs will be generated along with pytriqs,"
		einfo "where the standard python shell is replaced by the ipython one."
	fi
}

src_prepare() {
	epatch "${FILESDIR}/cleanup-environment-for-f2py.patch"
}

src_configure() {
	local mycmakeargs="
		$(cmake-utils_use doc Build_Documentation)
		$(cmake-utils_use cthyb Build_CTHyb)
		$(cmake-utils_use hubbard1 Build_HubbardI)
		$(cmake-utils_use wien2k Build_Wien2k)
		$(cmake-utils_use pade Use_Pade)
		$(cmake-utils_use development Install_dev)
	"

	# Use the existing Blitz installation
	mycmakeargs+=" -DBLITZ_INSTALLED=ON"

	# Boost
	if [[ -z ${BOOST_SOURCE_DIR} ]]; then
		mycmakeargs+=" -DBOOST_INSTALL_ROOT_DIR=${EROOT}usr"
	else
		mycmakeargs+=" -DBOOST_SOURCE_DIR=${BOOST_SOURCE_DIR}"
		einfo "Using Boost sources from ${BOOST_SOURCE_DIR} ..."
	fi

	# Determine BOOST_MODULE_DIR
	# Remove the next 3 lines if the patch to app-admin/eselect-boost approved (see Gentoo
	# bug #404319) to create $(python_get_sitedir)/boost symlink instead of $(python_get_sitedir)/mpi.so
	mpiso_path="$(python_get_sitedir)/mpi.so"
	boost_path=$(dirname $(readlink -f "${mpiso_path}"))
	mycmakeargs+=" -DBOOST_MODULE_DIR=${boost_path}"

	# BLAS/LAPACK libraries
	lapack_libs="libblas libcblas liblapack"
	mycmakeargs+=" -DLAPACK_LIBS="
	for l in $lapack_libs; do
		mycmakeargs+="${EROOT}usr/$(get_libdir)/${l}$(get_modname);"
	done
	if use amd64 || use ppc64; then  mycmakeargs+=" -DLAPACK_64_BIT=ON"; fi

	# Python library path
	python_library_path="${EROOT}$(python_get_library -b)"
	mycmakeargs+=" -DPYTHON_LIBRARY=${python_library_path}"

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	# Documentation
	if use doc; then
		doc_src="${ED}/usr/share/doc/triqs"
		doc_dst="${ED}/usr/share/doc/${PF}"
		mkdir "${doc_dst}"
		einfo "Installing user manual ..."
		mv "${doc_src}/user_manual" "${doc_dst}/user_manual"
		einfo "Installing developer manual ..."
		mv "${doc_src}/developer_manual" "${doc_dst}/developer_manual"

		rmdir "${doc_src}"
	fi
}

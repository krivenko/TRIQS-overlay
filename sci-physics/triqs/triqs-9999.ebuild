# Copyright 2011-2012 Igor Krivenko
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PYTHON_COMPAT=(python2_6 python2_7)
inherit cmake-utils python-r1 git-2 multilib versionator

DESCRIPTION="Toolbox for Research on Interacting Quantum Systems"
HOMEPAGE="http://ipht.cea.fr/triqs/"
EGIT_REPO_URI="https://github.com/TRIQS/TRIQS.git"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="+cthyb hubbard1 wien2k pade doc development test"

RDEPEND="${PYTHON_DEPS}
	|| ( 
		>=sys-devel/gcc-4.6.3
		>=sys-devel/clang-3.1
		>=dev-lang/icc-13.0.0
	)	
    virtual/mpi
	>=dev-libs/boost-1.49-r2[python,mpi]
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

pkg_setup() {
	if has_version dev-python/ipython; then
		einfo "dev-python/ipython is installed."
		einfo "A second script named ipytriqs will be generated along with pytriqs,"
		einfo "where the standard python shell is replaced by the ipython one."
	fi
}

src_prepare() {
	epatch "${FILESDIR}/cleanup-environment-for-f2py.patch"
	epatch "${FILESDIR}/require-multithreaded-boost.patch"
	epatch "${FILESDIR}/boost-symlink-workaround.patch"

	python_export_best

	local python_ver=${EPYTHON:6}
	sed -i \
		-e "s/-lboost_python/-lboost_python-${python_ver}/" \
		-e "s/libboost_python/libboost_python-${python_ver}/" \
		cmake/FindBoost.cmake

	sed -i \
		-e "s/-llapack/$(pkg-config --libs-only-l lapack)/" \
		cmake/FindBuildF2pyModule.cmake
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
	local boost_p="$(best_version dev-libs/boost)"
	local boost_pv="${boost_p:15}"
	local boost_major_v="$(get_version_component_range 1-2 ${boost_pv})"
	local boost_major_pv=$(replace_all_version_separators _ ${boost_major_v})
	local boost_path="$(python_get_sitedir)/boost_${boost_major_pv}"
	mycmakeargs+=" -DBOOST_MODULE_DIR=${boost_path}"

	# BLAS/LAPACK libraries
	if use amd64 || use ppc64; then  mycmakeargs+=" -DLAPACK_64_BIT=ON"; fi

	# Python library path
	python_library_path="${EROOT}usr/$(get_libdir)/lib${EPYTHON}.so"
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

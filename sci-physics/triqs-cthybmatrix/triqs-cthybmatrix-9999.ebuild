# Copyright 2011-2013 Igor Krivenko
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )
PYTHON_REQ_USE=threads

inherit cmake-utils python-single-r1

if [[ ${PV} == 9999* ]] ; then
        inherit git-2
        EGIT_REPO_URI="https://github.com/TRIQS/cthyb_matrix.git"
else
        SRC_URI="https://github.com/TRIQS/cthyb_matrix/archive/${PV}.zip"
fi

DESCRIPTION="The hybridization-expansion matrix solver"
HOMEPAGE="http://ipht.cea.fr/triqs/applications/cthyb_matrix/"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="doc"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
    >=sci-physics/triqs-9999[python,doc?]
"

src_configure() {
 
    local mycmakeargs="
        -DTRIQS_PATH=${EROOT}usr
        $(cmake-utils_use doc BUILD_DOC)
    "
    
    cmake-utils_src_configure
}

src_install() {
    cmake-utils_src_install

    # Documentation
    if use doc; then
        doc_src="${ED}/usr/share/doc/cthyb_matrix"
        doc_dst="${ED}/usr/share/doc/${PF}"
        einfo "Installing documentation ..."
        mv "${doc_src}" "${doc_dst}"
    fi
}

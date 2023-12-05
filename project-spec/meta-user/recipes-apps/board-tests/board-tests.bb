SUMMARY = "Script to test various board peripherals."
SECTION = "PETALINUX/apps"
LICENSE = "CLOSED"

SRC_URI = "file://board-tests.sh"

S = "${WORKDIR}"

do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${S}/board-tests.sh ${D}${bindir}
}

RDEPENDS_${PN} = "libgpiod-tools"
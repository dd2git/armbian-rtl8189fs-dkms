#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

readonly PACKAGE_NAME="rtl8189fs"
readonly PACKAGE_VERSION="5.7.9"
readonly MODULE_NAME="8189fs"
readonly SOURCE_DIR="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"

if [[ ${EUID} -ne 0 ]]; then
    echo "Fehler: Bitte als root ausfuehren: sudo ./uninstall.sh" >&2
    exit 1
fi

if dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" 2>/dev/null | grep -q .; then
    dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all
fi

rm -f "/etc/modules-load.d/${MODULE_NAME}.conf"
rm -f "/etc/modprobe.d/${MODULE_NAME}.conf"
rm -rf "${SOURCE_DIR}"
depmod -a

echo "${PACKAGE_NAME}/${PACKAGE_VERSION} wurde entfernt."
echo "Ein bereits im Kernelpaket enthaltenes Modul bleibt unveraendert erhalten."

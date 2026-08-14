#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

readonly PACKAGE_NAME="rtl8189fs"
readonly PACKAGE_VERSION="5.7.9"
readonly MODULE_NAME="8189fs"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_DIR="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
readonly TOOLCHAIN_NAME="arm-gnu-toolchain-15.3.rel1-aarch64-aarch64-none-linux-gnu"
readonly TOOLCHAIN_ROOT="/usr/local/toolchain/${TOOLCHAIN_NAME}"
readonly TOOLCHAIN_URL="https://github.com/ophub/kernel/releases/download/dev/${TOOLCHAIN_NAME}.tar.xz"
readonly RUNNING_KERNEL="$(uname -r)"

if [[ ${EUID} -ne 0 ]]; then
    echo "Fehler: Bitte als root ausfuehren: sudo ./install.sh" >&2
    exit 1
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
    echo "Fehler: Dieser Treiber ist fuer ARM64/aarch64 vorgesehen." >&2
    exit 1
fi

if [[ ! -d "/lib/modules/${RUNNING_KERNEL}/build" ]]; then
    echo "Fehler: Kernel-Header fuer ${RUNNING_KERNEL} fehlen." >&2
    echo "Installiere zuerst die zu diesem Kernel passenden Header." >&2
    exit 1
fi

missing_packages=()
for package in dkms curl xz-utils ca-certificates make; do
    case "${package}" in
        make) command -v make >/dev/null 2>&1 || missing_packages+=(make) ;;
        *) dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q 'install ok installed' || missing_packages+=("${package}") ;;
    esac
done

if ((${#missing_packages[@]})); then
    apt-get update
    apt-get install -y "${missing_packages[@]}"
fi

if [[ ! -x "${TOOLCHAIN_ROOT}/bin/aarch64-none-linux-gnu-gcc" ]]; then
    archive="$(mktemp --suffix=.tar.xz)"
    trap 'rm -f "${archive:-}"' EXIT
    echo "Lade die zum OPhub-Kernel passende ARM GNU Toolchain 15.3 ..."
    curl --fail --location --retry 3 --output "${archive}" "${TOOLCHAIN_URL}"
    install -d -m 755 /usr/local/toolchain
    tar -xJf "${archive}" -C /usr/local/toolchain
fi

if dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" 2>/dev/null | grep -q .; then
    dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all
fi

rm -rf "${SOURCE_DIR}"
install -d -m 755 "${SOURCE_DIR}"
cp -a "${SCRIPT_DIR}/driver/." "${SOURCE_DIR}/driver/"
install -m 644 "${SCRIPT_DIR}/dkms.conf" "${SOURCE_DIR}/dkms.conf"

dkms add -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${RUNNING_KERNEL}"
dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${RUNNING_KERNEL}" --force

printf '%s\n' "${MODULE_NAME}" > "/etc/modules-load.d/${MODULE_NAME}.conf"
printf '%s\n' "options ${MODULE_NAME} rtw_power_mgnt=0 rtw_enusbss=0" > "/etc/modprobe.d/${MODULE_NAME}.conf"
depmod -a "${RUNNING_KERNEL}"

echo
echo "DKMS-Installation erfolgreich."
dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
echo "Modul fuer den naechsten Start: $(modinfo -n "${MODULE_NAME}")"
echo "Bitte starte das System neu, um das DKMS-Modul zu laden."

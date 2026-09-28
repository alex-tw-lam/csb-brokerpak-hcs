#!/usr/bin/env bash
# Stages the Terraform/OpenTofu release binaries referenced by manifest.yml into ./bin.
#
# This is the ONLY step that requires internet access. Run it on a connected machine,
# then ship ./bin together with this repository: `csb pak build` resolves the
# url_template entries to these local files and runs fully offline.
#
# Each release zip is downloaded, SHA256-verified against the upstream checksum file,
# and unpacked into bin/<name>_<version>_<os>_<arch>/ so that the manifest
# url_template entries point at the unpacked binaries (CSB copies local files verbatim
# into the brokerpak, so they must already be unpacked).
set -euo pipefail

MANIFEST="${MANIFEST:-manifest.yml}"
BIN_DIR="${BIN_DIR:-bin}"
OS="${PAK_OS:-linux}"
ARCH="${PAK_ARCH:-amd64}"

download_url() {
  local name="$1" version="$2"
  case "$name" in
    tofu)
      echo "https://github.com/opentofu/opentofu/releases/download/v${version}/tofu_${version}_${OS}_${ARCH}.zip"
      ;;
    terraform-provider-hcs)
      echo "https://github.com/huaweicloud/${name}/releases/download/v${version}/${name}_${version}_${OS}_${ARCH}.zip"
      ;;
    terraform-provider-random)
      echo "https://releases.hashicorp.com/${name}/${version}/${name}_${version}_${OS}_${ARCH}.zip"
      ;;
    *)
      echo "don't know how to download ${name}" >&2
      return 1
      ;;
  esac
}

checksums_url() {
  local name="$1" version="$2"
  case "$name" in
    tofu)
      echo "https://github.com/opentofu/opentofu/releases/download/v${version}/tofu_${version}_SHA256SUMS"
      ;;
    terraform-provider-hcs)
      echo "https://github.com/huaweicloud/${name}/releases/download/v${version}/${name}_${version}_SHA256SUMS"
      ;;
    terraform-provider-random)
      echo "https://releases.hashicorp.com/${name}/${version}/${name}_${version}_SHA256SUMS"
      ;;
  esac
}

entries=$(awk '/^terraform_binaries:/{f=1;next} f && /^[^ -]/{f=0} f && /- name:/{name=$3} f && /^ +version:/{print name" "$2}' "$MANIFEST")

mkdir -p "$BIN_DIR"

while read -r name version; do
  [[ -z "${name}" ]] && continue
  file="${name}_${version}_${OS}_${ARCH}.zip"
  staged_dir="${BIN_DIR}/${name}_${version}_${OS}_${ARCH}"
  staged_binary="${staged_dir}/${name}_v${version}"
  [[ "${name}" == "tofu" ]] && staged_binary="${staged_dir}/${name}"

  if [[ -f "${staged_binary}" ]]; then
    echo ">> ${staged_binary} already staged, skipping download"
    continue
  fi

  tmp_zip=$(mktemp -u --suffix=".zip")
  trap 'rm -f "${tmp_zip}"' EXIT
  echo ">> downloading $(download_url "${name}" "${version}")"
  curl -fsSL -o "${tmp_zip}" "$(download_url "${name}" "${version}")"

  sums_file=$(mktemp -u)
  curl -fsSL -o "${sums_file}" "$(checksums_url "${name}" "${version}")"
  expected=$(awk -v f="${file}" '$2 == f {print $1}' "${sums_file}")
  rm -f "${sums_file}"
  if [[ -z "${expected}" ]]; then
    echo "!! no checksum entry found for ${file}" >&2
    exit 1
  fi
  actual=$(sha256sum "${tmp_zip}" | awk '{print $1}')
  if [[ "${actual}" != "${expected}" ]]; then
    echo "!! checksum mismatch for ${file}: expected ${expected}, got ${actual}" >&2
    exit 1
  fi
  echo ">> verified ${file}"

  mkdir -p "${staged_dir}"
  unzip -q -o "${tmp_zip}" -d "${staged_dir}"
  rm -f "${tmp_zip}"
  if [[ ! -f "${staged_binary}" ]]; then
    # Hashicorp release zips carry a protocol-version suffix (e.g. ..._v3.9.0_x5); normalize it.
    suffixed=$(find "${staged_dir}" -maxdepth 1 -name "${name}_v${version}_x[0-9]*" | head -1)
    if [[ -n "${suffixed}" ]]; then
      mv "${suffixed}" "${staged_binary}"
    fi
  fi
  if [[ ! -f "${staged_binary}" ]]; then
    echo "!! expected binary ${staged_binary} not found after unpacking" >&2
    exit 1
  fi
  chmod +x "${staged_binary}"
  echo ">> staged ${staged_binary}"
done <<< "${entries}"

echo ">> all binaries staged in ${BIN_DIR}/"

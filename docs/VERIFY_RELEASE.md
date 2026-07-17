<!-- SPDX-License-Identifier: MPL-2.0 -->

# Verify an AnoSecureKit Community Release

Use this procedure only after confirming that the requested GitHub Release and
assets actually exist. A repository tag or workflow definition alone is not
publication evidence.

Set the release version and repository:

```sh
VERSION=X.Y.Z
REPO=anothel/AnoSecureKit-Community
```

Expected release assets include names such as:

```text
anosecurekit-X.Y.Z-source.tar.gz
anosecurekit-X.Y.Z-source.zip
anosecurekit-X.Y.Z-<platform>.zip or .tar.gz
SHA256SUMS.txt
anosecurekit-X.Y.Z-release.spdx.json
```

## Verify Checksums

Download all release assets into one directory and run:

```sh
sha256sum -c SHA256SUMS.txt
```

On PowerShell, compare each expected line with:

```powershell
Get-FileHash .\anosecurekit-X.Y.Z-source.tar.gz -Algorithm SHA256
```

The file name and digest must exactly match `SHA256SUMS.txt`.

## Verify GitHub Artifact Attestations

With the GitHub CLI:

```sh
gh attestation verify SHA256SUMS.txt --repo anothel/AnoSecureKit-Community
gh attestation verify anosecurekit-X.Y.Z-source.tar.gz --repo anothel/AnoSecureKit-Community
```

Repeat for each asset that the release claims is attested.

## Inspect the SPDX SBOM

Open `anosecurekit-X.Y.Z-release.spdx.json` and verify that its package name,
version, download location, checksums, and listed release files match the release
being inspected.

## Source vs Binary Archives

- Source archives must contain the expected source, public headers, CMake files,
  license, security policy, and documentation.
- Binary archives must match the stated platform and configuration.
- Do not substitute an automatically generated GitHub source snapshot for a
  project-generated source release asset without checking the documented asset
  inventory.

## Build a Consumer

After checksum and attestation verification, extract a source archive, configure
and build it, install it into a clean prefix, and build a small consumer using:

```cmake
find_package(anosecurekit CONFIG REQUIRED)
target_link_libraries(app PRIVATE anosecurekit::anosecurekit)
```

Confirm the installed CLI reports the expected version.

## Record the Result

Retain:

- release URL and publication timestamp;
- tag and commit SHA;
- asset names, sizes, and SHA-256 values;
- SBOM file name and digest;
- attestation verification output;
- hosted CI/CodeQL run identity and conclusion;
- consumer platform and toolchain versions.

Update `docs/RELEASE_AND_EVIDENCE_STATUS.md` only from retained evidence.

## What This Does Not Prove

Checksums prove file integrity relative to the published checksum list.
Attestations prove the stated GitHub build provenance when verification succeeds.
An SBOM describes declared release contents. These checks do not prove absence of
vulnerabilities, correctness of cryptography, external audit completion, KCMVP,
FIPS validation, certification, or public-sector approval.

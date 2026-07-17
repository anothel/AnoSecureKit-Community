#!/usr/bin/env bash
set -Eeuo pipefail

repo="anothel/AnoSecureKit-Community"
tag="v0.4.0"
expected_commit="694459ebe497d15ba75ef76a52fa7c36ddd7bcce"
out="${1:-COMM-REL-02-v0.4.0-evidence}"

if [[ -e "$out" ]] && find "$out" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .; then
  echo "output directory already exists and is not empty: $out" >&2
  exit 2
fi
mkdir -p "$out" "$out/downloads" "$out/attestations" "$out/runs" "$out/errors"

for tool in gh jq sha256sum python3; do
  command -v "$tool" >/dev/null || {
    printf 'missing required tool: %s\n' "$tool" | tee "$out/errors/missing-tool.txt" >&2
    exit 2
  }
done

{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  gh --version | head -1
  jq --version
  sha256sum --version | head -1
  python3 --version
} >"$out/tool-versions.txt" 2>&1
cp "$0" "$out/collector.sh"

if ! gh auth status >"$out/gh-auth-status.txt" 2>&1; then
  printf 'DEFERRED_AUTHENTICATION\n' >"$out/collection-state.txt"
  echo "GitHub CLI is not authenticated; see $out/gh-auth-status.txt" >&2
  exit 4
fi

# Run an optional gh api request without aborting the collection.
# Writes the numeric gh exit code alongside the output/error files.
optional_api() {
  local name="$1"
  shift
  local rc=0
  if gh api "$@" >"$out/$name.json" 2>"$out/errors/$name.error.txt"; then
    rc=0
  else
    rc=$?
    printf '[]\n' >"$out/$name.json"
  fi
  printf '%s\n' "$rc" >"$out/errors/$name.exit-code.txt"
  return 0
}

# Identity collection is required and fails closed.
gh api "repos/$repo" >"$out/repository.json"
gh api "repos/$repo/git/ref/heads/main" >"$out/main-ref.json"
gh api "repos/$repo/compare/$tag...main" >"$out/tag-to-main-compare.json"
gh api "repos/$repo/git/ref/tags/$tag" >"$out/tag-ref.json"

tag_object_sha="$(jq -r '.object.sha' "$out/tag-ref.json")"
tag_object_type="$(jq -r '.object.type' "$out/tag-ref.json")"
resolved_commit="$tag_object_sha"
if [[ "$tag_object_type" == "tag" ]]; then
  gh api "repos/$repo/git/tags/$tag_object_sha" >"$out/annotated-tag.json"
  resolved_commit="$(jq -r '.object.sha' "$out/annotated-tag.json")"
fi
printf '%s\n' "$resolved_commit" >"$out/resolved-release-commit.txt"
if [[ "$resolved_commit" != "$expected_commit" ]]; then
  printf 'FAIL_TAG_MISMATCH\n' >"$out/collection-state.txt"
  echo "tag resolved to $resolved_commit, expected $expected_commit" >&2
  exit 3
fi

gh api "repos/$repo/commits/$expected_commit" >"$out/release-commit.json"

# Commit status/check evidence.
optional_api combined-status -H 'Accept: application/vnd.github+json' \
  "repos/$repo/commits/$expected_commit/status"

if gh api --paginate -H 'Accept: application/vnd.github+json' \
    "repos/$repo/commits/$expected_commit/check-runs?per_page=100" \
    --jq '.check_runs[]' | jq -s '.' >"$out/check-runs.json" \
    2>"$out/errors/check-runs.error.txt"; then
  printf '0\n' >"$out/errors/check-runs.exit-code.txt"
else
  rc=$?
  printf '[]\n' >"$out/check-runs.json"
  printf '%s\n' "$rc" >"$out/errors/check-runs.exit-code.txt"
fi

# All workflow runs for the exact release commit, including tag-push runs.
if gh api --paginate "repos/$repo/actions/runs?head_sha=$expected_commit&per_page=100" \
    --jq '.workflow_runs[]' | jq -s '.' >"$out/actions-runs.json" \
    2>"$out/errors/actions-runs.error.txt"; then
  printf '0\n' >"$out/errors/actions-runs.exit-code.txt"
else
  rc=$?
  printf '[]\n' >"$out/actions-runs.json"
  printf '%s\n' "$rc" >"$out/errors/actions-runs.exit-code.txt"
fi

# Fetch every run's jobs, artifacts and human-readable failure context.
while IFS= read -r run_id; do
  [[ -n "$run_id" ]] || continue
  if gh api --paginate "repos/$repo/actions/runs/$run_id/jobs?per_page=100" \
      --jq '.jobs[]' | jq -s '.' >"$out/runs/$run_id-jobs.json" \
      2>"$out/errors/$run_id-jobs.error.txt"; then
    printf '0\n' >"$out/errors/$run_id-jobs.exit-code.txt"
  else
    rc=$?
    printf '[]\n' >"$out/runs/$run_id-jobs.json"
    printf '%s\n' "$rc" >"$out/errors/$run_id-jobs.exit-code.txt"
  fi

  if gh api --paginate "repos/$repo/actions/runs/$run_id/artifacts?per_page=100" \
      --jq '.artifacts[]' | jq -s '.' >"$out/runs/$run_id-artifacts.json" \
      2>"$out/errors/$run_id-artifacts.error.txt"; then
    printf '0\n' >"$out/errors/$run_id-artifacts.exit-code.txt"
  else
    rc=$?
    printf '[]\n' >"$out/runs/$run_id-artifacts.json"
    printf '%s\n' "$rc" >"$out/errors/$run_id-artifacts.exit-code.txt"
  fi

  gh run view "$run_id" --repo "$repo" \
    >"$out/runs/$run_id-view.txt" 2>"$out/errors/$run_id-view.error.txt" || true
  gh run view "$run_id" --repo "$repo" --log-failed \
    >"$out/runs/$run_id-failed.log" 2>"$out/errors/$run_id-failed-log.error.txt" || true
done < <(jq -r '.[].id' "$out/actions-runs.json")

# CodeQL analyses on main, filtered to the exact release commit.
if gh api --paginate "repos/$repo/code-scanning/analyses?ref=refs/heads/main&per_page=100" \
    --jq '.[]' | jq -s '.' >"$out/codeql-main-analyses.json" \
    2>"$out/errors/codeql-main-analyses.error.txt"; then
  printf '0\n' >"$out/errors/codeql-main-analyses.exit-code.txt"
else
  rc=$?
  printf '[]\n' >"$out/codeql-main-analyses.json"
  printf '%s\n' "$rc" >"$out/errors/codeql-main-analyses.exit-code.txt"
fi
jq --arg sha "$expected_commit" '[.[] | select(.commit_sha == $sha)]' \
  "$out/codeql-main-analyses.json" >"$out/codeql-release-commit.json"

# Release REST object. Preserve the actual failure code; do not use `if ! cmd`.
release_rc=0
if gh api -H 'Accept: application/vnd.github+json' \
    "repos/$repo/releases/tags/$tag" >"$out/release.json" \
    2>"$out/errors/release.error.txt"; then
  release_rc=0
  printf 'RELEASE_OBJECT_FOUND\n' >"$out/release-state.txt"
else
  release_rc=$?
  printf '%s\n' "$release_rc" >"$out/errors/release.exit-code.txt"
  if grep -Eq 'HTTP 404|Not Found' "$out/errors/release.error.txt"; then
    printf 'NOT_PUBLISHED\n' >"$out/release-state.txt"
  elif grep -Eq 'HTTP 401|HTTP 403|Unauthorized|Forbidden|Resource not accessible' \
      "$out/errors/release.error.txt"; then
    printf 'DEFERRED_AUTHORIZATION\n' >"$out/release-state.txt"
  else
    printf 'DEFERRED_API_ERROR\n' >"$out/release-state.txt"
  fi
  printf '{}\n' >"$out/release.json"
fi

if [[ "$release_rc" -eq 0 ]]; then
  release_id="$(jq -r '.id' "$out/release.json")"
  if gh api --paginate "repos/$repo/releases/$release_id/assets?per_page=100" \
      --jq '.[]' | jq -s '.' >"$out/release-assets.json" \
      2>"$out/errors/release-assets.error.txt"; then
    printf '0\n' >"$out/errors/release-assets.exit-code.txt"
  else
    rc=$?
    printf '[]\n' >"$out/release-assets.json"
    printf '%s\n' "$rc" >"$out/errors/release-assets.exit-code.txt"
  fi

  jq -r '.[] | [(.id|tostring), .name, (.size|tostring), .content_type,
        (.digest // ""), .state, (.download_count|tostring),
        .created_at, .updated_at, .browser_download_url] | @tsv' \
    "$out/release-assets.json" >"$out/release-assets.tsv"

  if ! gh release download "$tag" --repo "$repo" --dir "$out/downloads" \
      >"$out/release-download.txt" 2>"$out/errors/release-download.error.txt"; then
    printf 'DEFERRED_DOWNLOAD_ERROR\n' >"$out/download-state.txt"
  else
    printf 'DOWNLOAD_COMPLETE\n' >"$out/download-state.txt"
  fi

  (cd "$out/downloads" && find . -maxdepth 1 -type f -printf '%f\t%s\n' | sort) \
    >"$out/downloaded-assets.tsv"
  if find "$out/downloads" -maxdepth 1 -type f -print -quit | grep -q .; then
    (cd "$out/downloads" && sha256sum * | sort) >"$out/downloaded-sha256.txt"
  else
    : >"$out/downloaded-sha256.txt"
  fi

  if [[ -f "$out/downloads/SHA256SUMS.txt" ]]; then
    checksum_rc=0
    if (cd "$out/downloads" && sha256sum -c SHA256SUMS.txt) \
        >"$out/sha256-verification.txt" 2>&1; then
      checksum_rc=0
      printf 'PASS\n' >"$out/sha256-state.txt"
    else
      checksum_rc=$?
      printf 'FAIL\n' >"$out/sha256-state.txt"
    fi
    printf '%s\n' "$checksum_rc" >"$out/sha256-exit-code.txt"
  else
    printf 'UNVERIFIED_MISSING_FILE\n' >"$out/sha256-state.txt"
    : >"$out/sha256-verification.txt"
  fi

  sbom="$out/downloads/anosecurekit-0.4.0-release.spdx.json"
  if [[ -f "$sbom" ]]; then
    jq -r '.packages[] | [.name,
      ([.checksums[]? | select(.algorithm == "SHA256") | .checksumValue][0] // "")] | @tsv' \
      "$sbom" | sort >"$out/sbom-assets.tsv"
  else
    : >"$out/sbom-assets.tsv"
  fi

  if gh attestation verify --help >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
      name="$(basename "$file")"
      attestation_rc=0
      if gh attestation verify "$file" --repo "$repo" \
          >"$out/attestations/$name.txt" 2>&1; then
        attestation_rc=0
      else
        attestation_rc=$?
      fi
      printf '%s\n' "$attestation_rc" >"$out/attestations/$name.exit-code.txt"
    done < <(find "$out/downloads" -maxdepth 1 -type f -print0)
  else
    printf 'DEFERRED_GH_VERSION\n' >"$out/attestations/state.txt"
  fi
else
  printf '[]\n' >"$out/release-assets.json"
  : >"$out/release-assets.tsv"
  : >"$out/downloaded-assets.tsv"
  : >"$out/downloaded-sha256.txt"
  : >"$out/sbom-assets.tsv"
  printf 'NOT_ATTEMPTED\n' >"$out/download-state.txt"
  printf 'UNVERIFIED_NO_RELEASE_OBJECT\n' >"$out/sha256-state.txt"
fi

python3 - "$out" "$repo" "$tag" "$expected_commit" <<'PY'
from __future__ import annotations

from pathlib import Path
import hashlib
import json
import re
import sys
from typing import Any

out = Path(sys.argv[1])
repo, tag, expected_sha = sys.argv[2:]


def read_text(name: str, default: str = "") -> str:
    path = out / name
    return path.read_text(encoding="utf-8", errors="replace").strip() if path.exists() else default


def read_json(name: str, default: Any) -> Any:
    path = out / name
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

release_state = read_text("release-state.txt", "UNVERIFIED")
release = read_json("release.json", {})
assets = read_json("release-assets.json", [])
actions = read_json("actions-runs.json", [])
checks = read_json("check-runs.json", [])
codeql = read_json("codeql-release-commit.json", [])
compare = read_json("tag-to-main-compare.json", {})

downloads = out / "downloads"
downloaded = {p.name: p for p in downloads.iterdir() if p.is_file()} if downloads.exists() else {}
asset_by_name = {a.get("name"): a for a in assets if a.get("name")}

inventory_errors: list[str] = []
for name, asset in asset_by_name.items():
    path = downloaded.get(name)
    if path is None:
        inventory_errors.append(f"missing download: {name}")
    elif path.stat().st_size != int(asset.get("size", -1)):
        inventory_errors.append(
            f"size mismatch: {name}: downloaded={path.stat().st_size} api={asset.get('size')}"
        )
for name in sorted(set(downloaded) - set(asset_by_name)):
    inventory_errors.append(f"unexpected download: {name}")

# Compare GitHub digest fields with downloaded bytes.
digest_results: list[dict[str, Any]] = []
for name, asset in sorted(asset_by_name.items()):
    api_digest = asset.get("digest") or ""
    path = downloaded.get(name)
    actual = sha256(path) if path else ""
    status = "UNVERIFIED"
    if api_digest.startswith("sha256:") and actual:
        status = "PASS" if api_digest.split(":", 1)[1].lower() == actual.lower() else "FAIL"
    elif path and not api_digest:
        status = "NO_GITHUB_DIGEST"
    elif not path:
        status = "MISSING_DOWNLOAD"
    digest_results.append({"name": name, "github_digest": api_digest, "actual_sha256": actual, "status": status})
(out / "github-digest-comparison.json").write_text(json.dumps(digest_results, indent=2) + "\n", encoding="utf-8")
with (out / "github-digest-comparison.tsv").open("w", encoding="utf-8") as f:
    for row in digest_results:
        f.write("\t".join([row["name"], row["github_digest"], row["actual_sha256"], row["status"]]) + "\n")

# Compare SPDX package/checksum inventory with downloaded package assets.
sbom_path = downloads / "anosecurekit-0.4.0-release.spdx.json"
sbom_results: list[dict[str, str]] = []
sbom_state = "UNVERIFIED_MISSING_FILE"
if sbom_path.exists():
    try:
        sbom = json.loads(sbom_path.read_text(encoding="utf-8"))
        sbom_map: dict[str, str] = {}
        for package in sbom.get("packages", []):
            digest = ""
            for checksum in package.get("checksums", []):
                if checksum.get("algorithm") == "SHA256":
                    digest = checksum.get("checksumValue", "")
                    break
            sbom_map[package.get("name", "")] = digest
        expected_names = set(downloaded) - {"SHA256SUMS.txt", sbom_path.name}
        all_names = sorted(expected_names | set(sbom_map))
        for name in all_names:
            actual = sha256(downloaded[name]) if name in downloaded else ""
            recorded = sbom_map.get(name, "")
            if name not in downloaded:
                status = "MISSING_DOWNLOAD"
            elif name not in sbom_map:
                status = "MISSING_SBOM_PACKAGE"
            else:
                status = "PASS" if recorded.lower() == actual.lower() else "FAIL"
            sbom_results.append({"name": name, "sbom_sha256": recorded, "actual_sha256": actual, "status": status})
        sbom_state = "PASS" if sbom_results and all(r["status"] == "PASS" for r in sbom_results) else "FAIL"
    except Exception as exc:
        sbom_state = f"FAIL_PARSE: {exc}"
(out / "sbom-comparison.json").write_text(json.dumps(sbom_results, indent=2) + "\n", encoding="utf-8")
(out / "sbom-state.txt").write_text(sbom_state + "\n", encoding="utf-8")

# Attestation summary.
attestation_rows: list[dict[str, Any]] = []
for path in sorted((out / "attestations").glob("*.exit-code.txt")):
    name = path.name.removesuffix(".exit-code.txt")
    try:
        rc = int(path.read_text().strip())
    except Exception:
        rc = -1
    attestation_rows.append({"name": name, "exit_code": rc, "status": "PASS" if rc == 0 else "FAIL"})
attestation_state = "UNVERIFIED"
if attestation_rows:
    attestation_state = "PASS" if all(r["exit_code"] == 0 for r in attestation_rows) else "FAIL"
elif read_text("attestations/state.txt"):
    attestation_state = read_text("attestations/state.txt")
(out / "attestation-summary.json").write_text(json.dumps(attestation_rows, indent=2) + "\n", encoding="utf-8")

# Flatten run/job evidence and identify platform lanes.
run_rows: list[dict[str, Any]] = []
job_rows: list[dict[str, Any]] = []
for run in actions:
    run_id = str(run.get("id", ""))
    run_rows.append({
        "id": run.get("id"), "name": run.get("name"), "event": run.get("event"),
        "status": run.get("status"), "conclusion": run.get("conclusion"),
        "head_sha": run.get("head_sha"), "head_branch": run.get("head_branch"),
        "run_attempt": run.get("run_attempt"), "created_at": run.get("created_at"),
        "updated_at": run.get("updated_at"), "html_url": run.get("html_url"),
    })
    for job in read_json(f"runs/{run_id}-jobs.json", []):
        job_rows.append({
            "run_id": run.get("id"), "workflow": run.get("name"), "event": run.get("event"),
            "name": job.get("name"), "status": job.get("status"),
            "conclusion": job.get("conclusion"), "started_at": job.get("started_at"),
            "completed_at": job.get("completed_at"), "html_url": job.get("html_url"),
        })
(out / "workflow-run-summary.json").write_text(json.dumps(run_rows, indent=2) + "\n", encoding="utf-8")
(out / "workflow-job-summary.json").write_text(json.dumps(job_rows, indent=2) + "\n", encoding="utf-8")

windows_jobs = [j for j in job_rows if re.search(r"windows|msvc", str(j.get("name")), re.I)]
macos_jobs = [j for j in job_rows if re.search(r"macos|appleclang", str(j.get("name")), re.I)]

def lane_state(rows: list[dict[str, Any]]) -> str:
    if not rows:
        return "UNVERIFIED"
    conclusions = [r.get("conclusion") for r in rows]
    return "PASS" if conclusions and all(c == "success" for c in conclusions) else "FAIL"

platform = {
    "windows": {"status": lane_state(windows_jobs), "jobs": windows_jobs},
    "macos": {"status": lane_state(macos_jobs), "jobs": macos_jobs},
}
(out / "platform-evidence.json").write_text(json.dumps(platform, indent=2) + "\n", encoding="utf-8")

expected_exact = {
    "anosecurekit-0.4.0-source.zip",
    "anosecurekit-0.4.0-source.tar.gz",
    "anosecurekit-0.4.0-release.spdx.json",
    "SHA256SUMS.txt",
}
expected_families = [
    "anosecurekit-ubuntu-latest-gcc-Release-packages",
    "anosecurekit-ubuntu-latest-clang-Release-packages",
    "anosecurekit-ubuntu-latest-gcc-Debug-packages",
    "anosecurekit-windows-latest-msvc-Release-packages",
    "anosecurekit-ubuntu-gcc-release-install-only-packages",
    "anosecurekit-ubuntu-gcc-release-static-packages",
    "anosecurekit-windows-msvc-release-shared-packages",
    "anosecurekit-macos-clang-release-packages",
]
contract_errors: list[str] = []
asset_names = set(asset_by_name)
if release_state == "RELEASE_OBJECT_FOUND":
    for name in sorted(expected_exact - asset_names):
        contract_errors.append(f"missing expected asset: {name}")
    for family in expected_families:
        for suffix in (".zip", ".tar.gz"):
            if not any(name.startswith(family + "-anosecurekit-0.4.0-") and name.endswith(suffix) for name in asset_names):
                contract_errors.append(f"missing expected family/suffix: {family} *{suffix}")
    if len(asset_names) != 20:
        contract_errors.append(f"expected 20 assets, found {len(asset_names)}")

manifest = {
    "repository": repo,
    "tag": tag,
    "expected_release_commit": expected_sha,
    "resolved_release_commit": read_text("resolved-release-commit.txt"),
    "main_sha": read_json("main-ref.json", {}).get("object", {}).get("sha"),
    "compare": {k: compare.get(k) for k in ("status", "ahead_by", "behind_by", "total_commits")},
    "release_api_state": release_state,
    "release": {
        "id": release.get("id"), "name": release.get("name"), "tag_name": release.get("tag_name"),
        "target_commitish": release.get("target_commitish"), "draft": release.get("draft"),
        "prerelease": release.get("prerelease"), "created_at": release.get("created_at"),
        "published_at": release.get("published_at"), "html_url": release.get("html_url"),
        "asset_count": len(assets),
    },
    "inventory_status": "PASS" if assets and not inventory_errors else ("FAIL" if release_state == "RELEASE_OBJECT_FOUND" else "UNVERIFIED"),
    "inventory_errors": inventory_errors,
    "workflow_contract_status": "PASS" if release_state == "RELEASE_OBJECT_FOUND" and not contract_errors else ("FAIL" if release_state == "RELEASE_OBJECT_FOUND" else "UNVERIFIED"),
    "workflow_contract_errors": contract_errors,
    "sha256_status": read_text("sha256-state.txt", "UNVERIFIED"),
    "sbom_status": sbom_state,
    "github_digest_status": (
        "PASS" if digest_results and all(r["status"] in {"PASS", "NO_GITHUB_DIGEST"} for r in digest_results)
        else ("FAIL" if any(r["status"] == "FAIL" for r in digest_results) else "UNVERIFIED")
    ),
    "attestation_status": attestation_state,
    "actions_run_count": len(run_rows),
    "actions_runs": run_rows,
    "job_count": len(job_rows),
    "codeql_exact_commit_count": len(codeql),
    "codeql_exact_commit": codeql,
    "platform_evidence": {"windows": platform["windows"]["status"], "macos": platform["macos"]["status"]},
}
(out / "EVIDENCE_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

lines = [
    "# COMM-REL-02 Authenticated Evidence Collection", "",
    f"- Repository: `{repo}`",
    f"- Tag: `{tag}`",
    f"- Expected commit: `{expected_sha}`",
    f"- Resolved commit: `{manifest['resolved_release_commit']}`",
    f"- Release API state: `{release_state}`", "",
    "## Release", "",
]
if release_state == "RELEASE_OBJECT_FOUND":
    lines += [
        f"- Name: `{release.get('name')}`",
        f"- Published: `{release.get('published_at')}`",
        f"- Draft: `{release.get('draft')}`",
        f"- Prerelease: `{release.get('prerelease')}`",
        f"- Assets: `{len(assets)}`",
        f"- Workflow contract: `{manifest['workflow_contract_status']}`",
        f"- Download inventory: `{manifest['inventory_status']}`",
        f"- SHA256SUMS: `{manifest['sha256_status']}`",
        f"- SPDX SBOM: `{manifest['sbom_status']}`",
        f"- GitHub digest comparison: `{manifest['github_digest_status']}`",
        f"- Attestations: `{manifest['attestation_status']}`",
    ]
else:
    lines += ["Inspect `errors/release.error.txt` before applying the final classification."]
lines += [
    "", "## Hosted Evidence", "",
    f"- Actions runs for exact commit: `{len(run_rows)}`",
    f"- Jobs collected: `{len(job_rows)}`",
    f"- Exact-commit CodeQL analyses: `{len(codeql)}`",
    f"- Windows lanes: `{platform['windows']['status']}`",
    f"- macOS lanes: `{platform['macos']['status']}`",
    "", "See `EVIDENCE_MANIFEST.json` and the detailed JSON/TSV/log files.",
]
(out / "SUMMARY.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

printf 'COLLECTION_COMPLETE\n' >"$out/collection-state.txt"

python3 - "$out" <<'PY'
from pathlib import Path
import hashlib
import sys
import zipfile

root = Path(sys.argv[1]).resolve()
archive = root.with_suffix('.zip')
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(root.rglob('*')):
        if path.is_file():
            zf.write(path, Path(root.name) / path.relative_to(root))
h = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(archive.suffix + '.sha256').write_text(f"{h}  {archive.name}\n", encoding='utf-8')
print(archive)
PY

echo "Evidence written to $out and ${out}.zip"
# A missing Release object is a valid evidence outcome, not a collector failure.
exit 0

#!/usr/bin/env python3
"""
Fetch GitHub repository URLs for PyPI packages.

Queries the PyPI JSON API to extract GitHub URLs from package metadata.
Outputs a mapping CSV for use with the GH Archive pipeline.

Usage:
    python fetch_github_urls.py --input ../data/fin_dataset_treat_control.csv --output ../data/pypi_github_mapping.csv
"""

import argparse
import csv
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional, Tuple

import requests

PYPI_API_URL = "https://pypi.org/pypi/{package}/json"
GITHUB_PATTERN = re.compile(
    r"https?://(?:www\.)?github\.com/([^/]+/[^/#?\s]+)", re.IGNORECASE
)


def extract_github_repo(url: str) -> Optional[str]:
    """Extract owner/repo from a GitHub URL."""
    if not url:
        return None
    match = GITHUB_PATTERN.search(url)
    if match:
        repo = match.group(1)
        repo = re.sub(r"\.git$", "", repo)
        repo = repo.rstrip("/")
        if "/" in repo and len(repo.split("/")) == 2:
            return repo
    return None


def fetch_package_github(package: str) -> Tuple[str, Optional[str], Optional[str]]:
    """
    Fetch PyPI metadata for a package and extract GitHub URL.

    Returns:
        (package_name, github_url, repo_full_name) or (package_name, None, None) if not found
    """
    url = PYPI_API_URL.format(package=package)
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 404:
            return (package, None, None)
        resp.raise_for_status()
        data = resp.json()
    except Exception:
        return (package, None, None)

    info = data.get("info", {})

    github_url = None
    repo_full_name = None

    home_page = info.get("home_page") or ""
    repo = extract_github_repo(home_page)
    if repo:
        github_url = home_page
        repo_full_name = repo

    if not repo_full_name:
        project_urls = info.get("project_urls") or {}
        for _, val in project_urls.items():
            if val:
                repo = extract_github_repo(val)
                if repo:
                    github_url = val
                    repo_full_name = repo
                    break

    if not repo_full_name:
        download_url = info.get("download_url") or ""
        repo = extract_github_repo(download_url)
        if repo:
            github_url = download_url
            repo_full_name = repo

    return (package, github_url, repo_full_name)


def main():
    parser = argparse.ArgumentParser(description="Map PyPI packages to GitHub repos")
    parser.add_argument(
        "--input",
        required=True,
        help="Input CSV with file_project column (e.g., fin_dataset_treat_control.csv)",
    )
    parser.add_argument(
        "--output",
        default="pypi_github_mapping.csv",
        help="Output CSV path",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=20,
        help="Number of parallel workers",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit number of packages to process (for testing)",
    )
    parser.add_argument(
        "--rate-limit-delay",
        type=float,
        default=0.0,
        help="Delay between requests in seconds (0 = no delay)",
    )
    args = parser.parse_args()

    with open(args.input, newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if args.limit:
        rows = rows[: args.limit]

    packages = [(r["file_project"], r.get("treatment", "")) for r in rows]
    treatment_map = {pkg: treat for pkg, treat in packages}
    package_list = [pkg for pkg, _ in packages]

    total = len(package_list)
    found = 0
    results = []

    print(f"Fetching GitHub URLs for {total} packages using {args.workers} workers...")

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(fetch_package_github, pkg): pkg for pkg in package_list
        }

        for i, future in enumerate(as_completed(futures), 1):
            pkg, github_url, repo_full_name = future.result()
            treatment = treatment_map.get(pkg, "")

            results.append(
                {
                    "file_project": pkg,
                    "github_url": github_url or "",
                    "repo_full_name": repo_full_name or "",
                    "treatment": treatment,
                }
            )

            if repo_full_name:
                found += 1

            if i % 500 == 0 or i == total:
                pct_done = 100 * i / total
                pct_found = 100 * found / i
                print(
                    f"Progress: {i}/{total} ({pct_done:.1f}%) | "
                    f"Found: {found} ({pct_found:.1f}%)"
                )

            if args.rate_limit_delay > 0:
                time.sleep(args.rate_limit_delay)

    results.sort(key=lambda r: r["file_project"])

    with open(args.output, "w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["file_project", "github_url", "repo_full_name", "treatment"]
        )
        writer.writeheader()
        writer.writerows(results)

    found_total = sum(1 for r in results if r["repo_full_name"])
    print(f"\nDone. Wrote {len(results)} rows to {args.output}")
    print(f"Packages with GitHub repos: {found_total}/{total} ({100*found_total/total:.1f}%)")


if __name__ == "__main__":
    main()

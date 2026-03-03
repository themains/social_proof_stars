#!/usr/bin/env python3
"""
Aggregate GH Archive event parquet files into repo-month covariates.

Input:
  folder with files like gh_events_2023-01.parquet ... gh_events_2023-12.parquet
Output:
  - repo_month_covariates_2023_long.csv  (repo_full_name, month, metrics...)
  - repo_month_covariates_2023_wide.csv  (optional pivot for easy one-row-per-repo merge)

Requires:
  pip install pandas pyarrow
"""

import argparse
import glob
import os
import re
import pandas as pd


MONTH_RE = re.compile(r"(20\d{2}-\d{2})")  # matches 2023-01 etc.

# Event-type mapping
# Stars: WatchEvent with payload.action == "started"
# PRs: PullRequestEvent action=="opened"
# Issues: IssuesEvent action=="opened"
# Releases: ReleaseEvent action=="published"
# Commits: PushEvent payload.size (integer)

def _extract_month(path: str) -> str:
    m = MONTH_RE.search(os.path.basename(path))
    if not m:
        raise ValueError(f"Could not parse month from filename: {path}")
    return m.group(1)

def _json_scalar(series: pd.Series, key: str) -> pd.Series:
    """
    Extract simple JSON scalar values from a JSON string column using regex.
    This is faster than json.loads row-by-row and works for simple keys like:
      {"action":"opened"}  or {"size":3}
    """
    # matches "key":"value" OR "key":value
    # group(1) captures either quoted string or number/bool/null
    pat = rf'"{re.escape(key)}"\s*:\s*(".*?"|[0-9]+|true|false|null)'
    out = series.str.extract(pat, expand=False)
    # strip quotes if string
    out = out.str.replace(r'^"(.*)"$', r"\1", regex=True)
    return out

def aggregate_one_file(path: str) -> pd.DataFrame:
    month = _extract_month(path)
    df = pd.read_parquet(path)

    # Normalize names
    # Your parquet uses repo_name; treat that as repo_full_name
    if "repo_name" in df.columns:
        df = df.rename(columns={"repo_name": "repo_full_name"})
    if "actor_login" not in df.columns:
        raise ValueError(f"Expected actor_login column in {path}")

    # Ensure created_at is datetime
    df["created_at"] = pd.to_datetime(df["created_at"], utc=True, errors="coerce")
    df["day"] = df["created_at"].dt.date

    # Extract a couple payload fields cheaply
    payload = df["payload"].astype("string")
    action = _json_scalar(payload, "action")
    size = _json_scalar(payload, "size")

    # Cast size safely
    size_num = pd.to_numeric(size, errors="coerce").fillna(0).astype("int64")

    df["action"] = action
    df["push_size"] = size_num

    # Build indicators / components
    is_watch_started = (df["type"] == "WatchEvent") & (df["action"] == "started")
    is_fork = (df["type"] == "ForkEvent")
    is_push = (df["type"] == "PushEvent")
    is_pr_open = (df["type"] == "PullRequestEvent") & (df["action"] == "opened")
    is_issue_open = (df["type"] == "IssuesEvent") & (df["action"] == "opened")
    is_issue_comment = (df["type"] == "IssueCommentEvent")
    is_pr_review_comment = (df["type"] == "PullRequestReviewCommentEvent")
    is_release_published = (df["type"] == "ReleaseEvent") & (df["action"] == "published")

    df["_stars_added"] = is_watch_started.astype("int64")
    df["_forks"] = is_fork.astype("int64")
    df["_push_events"] = is_push.astype("int64")
    df["_commits"] = (is_push.astype("int64") * df["push_size"]).astype("int64")
    df["_prs_opened"] = is_pr_open.astype("int64")
    df["_issues_opened"] = is_issue_open.astype("int64")
    df["_issue_comments"] = is_issue_comment.astype("int64")
    df["_pr_review_comments"] = is_pr_review_comment.astype("int64")
    df["_releases_published"] = is_release_published.astype("int64")

    # Aggregate per repo for this month file
    g = df.groupby("repo_full_name", dropna=False)

    out = pd.DataFrame({
        "repo_full_name": g.size().index,
        "month": month,
        "events_total": g.size().values,
        "stars_added": g["_stars_added"].sum().values,
        "forks": g["_forks"].sum().values,
        "push_events": g["_push_events"].sum().values,
        "commits": g["_commits"].sum().values,
        "prs_opened": g["_prs_opened"].sum().values,
        "issues_opened": g["_issues_opened"].sum().values,
        "issue_comments": g["_issue_comments"].sum().values,
        "pr_review_comments": g["_pr_review_comments"].sum().values,
        "releases_published": g["_releases_published"].sum().values,
        "unique_actors": g["actor_login"].nunique().values,
        "active_days": g["day"].nunique().values,
        "first_event_ts": g["created_at"].min().values,
        "last_event_ts": g["created_at"].max().values,
    })

    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--indir", required=True, help="Folder with gh_events_2023-*.parquet files")
    ap.add_argument("--pattern", default="gh_events_2023-*.parquet", help="Glob pattern within indir")
    ap.add_argument("--out_long", default="repo_month_covariates_2023_long.csv")
    ap.add_argument("--out_wide", default="repo_month_covariates_2023_wide.csv")
    ap.add_argument("--make_wide", action="store_true", help="Also produce wide repo-level file with month suffixes")
    args = ap.parse_args()

    paths = sorted(glob.glob(os.path.join(args.indir, args.pattern)))
    if not paths:
        raise SystemExit(f"No files matched {os.path.join(args.indir, args.pattern)}")

    parts = []
    for p in paths:
        print(f"Aggregating {p} ...")
        parts.append(aggregate_one_file(p))

    long_df = pd.concat(parts, ignore_index=True)

    # Ensure types for merge friendliness
    long_df["repo_full_name"] = long_df["repo_full_name"].astype(str)
    long_df.to_csv(args.out_long, index=False)
    print(f"Wrote long panel: {args.out_long}  rows={len(long_df):,}")

    if args.make_wide:
        # pivot: columns like stars_added_2023-01, commits_2023-02, ...
        metrics = [c for c in long_df.columns if c not in ("repo_full_name", "month")]
        wide = (long_df
                .set_index(["repo_full_name", "month"])[metrics]
                .unstack("month"))
        # flatten columns
        wide.columns = [f"{m}_{mon}" for (m, mon) in wide.columns]
        wide = wide.reset_index()
        wide.to_csv(args.out_wide, index=False)
        print(f"Wrote wide: {args.out_wide}  rows={len(wide):,}")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
import argparse, os, re
from io import StringIO
from datetime import datetime, timezone
from typing import List, Tuple

import pandas as pd
import requests
from google.cloud import bigquery

def read_csv_any(path_or_url: str) -> pd.DataFrame:
    if path_or_url.startswith("http"):
        r = requests.get(path_or_url, timeout=60)
        r.raise_for_status()
        return pd.read_csv(StringIO(r.text))
    return pd.read_csv(path_or_url)

def guess_repo_column(df: pd.DataFrame) -> str:
    for c in ["repo_full_name","full_name","repo","repository","name_with_owner","slug"]:
        if c in df.columns and df[c].astype(str).str.contains(r"^[^/]+/[^/]+$").mean() > 0.5:
            return c
    url_cols = [c for c in df.columns if "url" in c.lower()]
    for c in url_cols:
        extracted = df[c].astype(str).str.extract(r"github\.com/([^/]+/[^/#?]+)")[0]
        if extracted.notna().mean() > 0.5:
            df["repo_full_name"] = extracted
            return "repo_full_name"
    raise ValueError(f"Could not find repo column in: {list(df.columns)}")

def normalize_repos(raw: List[str]) -> List[str]:
    out=[]
    for r in raw:
        r=str(r).strip()
        if not r or r.lower() in {"nan","none"}:
            continue
        r=re.sub(r"\.git$","",r)
        r=r.split("#")[0].split("?")[0]
        out.append(r)
    seen=set(); dedup=[]
    for r in out:
        if r not in seen:
            seen.add(r); dedup.append(r)
    return dedup

def month_windows(year: int) -> List[Tuple[str,str,str,str]]:
    out=[]
    for m in range(1,13):
        label=f"{year}-{m:02d}"
        month_suffix=f"{year}{m:02d}"
        start=datetime(year,m,1,tzinfo=timezone.utc)
        if m==12:
            end_excl=datetime(year+1,1,1,tzinfo=timezone.utc)
        else:
            end_excl=datetime(year,m+1,1,tzinfo=timezone.utc)
        out.append((label, month_suffix, start.isoformat().replace("+00:00","Z"),
                    end_excl.isoformat().replace("+00:00","Z")))
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--project", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--year", type=int, required=True)
    ap.add_argument("--max_repos", type=int, default=None)
    args=ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    df=read_csv_any(args.input)
    repo_col=guess_repo_column(df)
    repos=normalize_repos(df[repo_col].tolist())
    if args.max_repos:
        repos=repos[:args.max_repos]
    if not repos:
        raise ValueError("No repos found after normalization.")

    client=bigquery.Client(project=args.project)

    sql = """
    WITH repo_list AS (
      SELECT repo_full_name FROM UNNEST(@repos) AS repo_full_name
    )
    SELECT
      created_at,
      type,
      public,
      id,
      actor.id    AS actor_id,
      actor.login AS actor_login,
      repo.id     AS repo_id,
      repo.name   AS repo_name,
      repo.url    AS repo_url,
      org.id      AS org_id,
      org.login   AS org_login,
      org.url     AS org_url,
      payload,
      other
    FROM `githubarchive.month.*`
    WHERE _TABLE_SUFFIX = @month_suffix
      AND created_at >= TIMESTAMP(@start_ts)
      AND created_at <  TIMESTAMP(@end_ts)
      AND repo.name IN (SELECT repo_full_name FROM repo_list)
    """

    for label, month_suffix, start_ts, end_ts in month_windows(args.year):
        print(f"[{label}] querying month {month_suffix} for {len(repos)} repos")
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ArrayQueryParameter("repos","STRING",repos),
                bigquery.ScalarQueryParameter("month_suffix","STRING",month_suffix),
                bigquery.ScalarQueryParameter("start_ts","STRING",start_ts),
                bigquery.ScalarQueryParameter("end_ts","STRING",end_ts),
            ]
        )
        job=client.query(sql, job_config=job_config)
        out_df=job.result().to_dataframe(create_bqstorage_client=True)

        out_path=os.path.join(args.outdir, f"gh_events_{label}.parquet")
        out_df.to_parquet(out_path, index=False)
        print(f"[{label}] wrote {len(out_df):,} rows -> {out_path}")

    print("Done.")

if __name__=="__main__":
    main()
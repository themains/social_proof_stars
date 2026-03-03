### Social Proof is in the Pudding: The (Non)-Impact of Social Proof on Software Downloads

Open-source software is widely used in commercial applications. Pair that with the fact that when choosing open-source software for a new problem, developers often use social proof as a cue. These two facts raise concern that bad actors can game social proof metrics to induce the use of malign software. We study the question using two field experiments. On the largest developer platform, GitHub, we buy `stars' for a random set of GitHub repositories of new Python packages and estimate their impact on package downloads. We find no discernible impact. In another field experiment, we manipulate the number of human downloads for Python packages. Again, we find little effect.

### Studies

* [Github Stars Experiment](github_exp/)
* [Python Downloads Experiment + VAR analysis](pydownloads/)

### GitHub Archive Data Pipeline

The `github_exp/gh_archive/` directory contains a two-stage pipeline that extracts repository activity metrics from BigQuery's GitHub Archive dataset and aggregates them into monthly covariates.

**Stage 1: Pull Events from BigQuery**

`gharchive_pull_events_2023.py` queries the `githubarchive.month.*` tables for all events related to a list of repositories for each month of 2023. Outputs one parquet file per month.

```bash
python3 github_exp/gh_archive/gharchive_pull_events_2023.py \
  --input "https://raw.githubusercontent.com/themains/social_proof_stars/refs/heads/main/github_exp/baltest/input/repo_baselines.csv" \
  --project your-gcp-project-id \
  --outdir ./gh_events_2023_parquet
```

**Stage 2: Aggregate to Repo-Month Covariates**

`aggregate_repo_month.py` reads the parquet files and computes per-repo, per-month metrics.

```bash
python3 github_exp/gh_archive/aggregate_repo_month.py \
  --indir ./gh_events_2023_parquet \
  --make_wide
```

**Output:**
- `repo_month_covariates_2023_long.csv`: One row per repo-month
- `repo_month_covariates_2023_wide.csv`: One row per repo, columns for each month (with `--make_wide`)

**Metrics computed:** `events_total`, `stars_added`, `forks`, `push_events`, `commits`, `prs_opened`, `issues_opened`, `issue_comments`, `pr_review_comments`, `releases_published`, `unique_actors`, `active_days`, `first_event_ts`, `last_event_ts`

### MS

* [Manuscript](ms/)

### Authors

Lucas Shen and Gaurav Sood

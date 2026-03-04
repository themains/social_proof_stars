### Social Proof is in the Pudding: The (Non)-Impact of Social Proof on Software Downloads

Open-source software is widely used in commercial applications. Pair that with the fact that when choosing open-source software for a new problem, developers often use social proof as a cue. These two facts raise concern that bad actors can game social proof metrics to induce the use of malign software. We study the question using two field experiments. On the largest developer platform, GitHub, we buy `stars' for a random set of GitHub repositories of new Python packages and estimate their impact on package downloads. We find no discernible impact. In another field experiment, we manipulate the number of human downloads for Python packages. Again, we find little effect.

### Key Findings

- **GitHub Stars Experiment**: Buying stars for repositories had no detectable effect on PyPI downloads
- **PyPI Downloads Experiment**: Boosting downloads had no significant effect on GitHub engagement metrics

### Repository Structure

```
├── github_exp/          # GitHub Stars Experiment
├── pydownloads/         # PyPI Downloads Experiment
└── lit/                 # Literature
```

---

## GitHub Stars Experiment (`github_exp/`)

**Pipeline:**

1. `sample_and_random_assign/` - Sample new PyPI packages, verify GitHub URLs, random treatment assignment
2. `get_baseline_profile/` - Collect baseline repo/user metrics before treatment
3. *[Treatment applied externally - purchasing stars]*
4. `get_metrics/` - Collect post-treatment PyPI download counts
5. `get_stargazers_profile/` - Profile the purchased stargazers
6. `baltest/` - Balance tests between treatment and control
7. `metrics-timeseries/` - Time series analysis of outcomes
8. `gh_archive/` - GitHub Archive data pipeline (details below)

### GH Archive Pipeline (`github_exp/gh_archive/`)

Two-stage pipeline to extract repository activity from BigQuery's GitHub Archive.

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

---

## PyPI Downloads Experiment (`pydownloads/`)

**Pipeline:**

1. `scripts/01_data_gather_and_prep.ipynb` - Query BigQuery for PyPI download data, prepare dataset
2. `scripts/02_var_panel_ols.ipynb` - VAR analysis of pre-treatment download patterns
3. `scripts/03_do_treatment.ipynb` - Apply download treatment to packages
4. `scripts/04_analyze_results.ipynb` - Analyze treatment effects on downloads
5. `scripts/fetch_github_urls.py` - Map PyPI packages to GitHub repositories
6. `scripts/05_github_engagement_analysis.ipynb` - Difference-in-differences analysis of GitHub outcomes

---

### Authors

Lucas Shen and Gaurav Sood

#!/usr/bin/env python3
"""Generate the markdown data dictionary in docs/data_dictionary/ from the
installed Tuva package's model YAML.

Usage (from the repo root, after `dbt deps`):

    python docs/tools/generate_data_dictionary.py
    python docs/tools/generate_data_dictionary.py --tuva-path /path/to/the_tuva_project

Only final (analyst-facing) models of the marts enabled by this project's
vars are documented. Staging/intermediate models are intentionally skipped.
"""

import argparse
import collections
import glob
import os
import re
import sys

import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEFAULT_TUVA_PATH = os.path.join(REPO_ROOT, "dbt_packages", "the_tuva_project")
DEFAULT_OUT_DIR = os.path.join(REPO_ROOT, "docs", "data_dictionary")

# (mart key, models dir relative to the package, title, analyst summary)
MARTS = [
    (
        "core",
        "models/core",
        "Core",
        "The conformed, cleaned data model every other mart is built from. "
        "Claims and clinical data land here in a common shape: `patient`, "
        "`practitioner` and `location` are the shared dimensions; claims, "
        "encounters, conditions, procedures, and clinical events are facts; "
        "`member_months` is the enrollment spine used as the denominator for "
        "PMPM and utilization rates.",
    ),
    (
        "financial_pmpm",
        "models/data_marts/financial_pmpm",
        "Financial PMPM",
        "Paid and allowed spend per member per month, broken out by service "
        "category. Start with `pmpm_prep` for member-level analysis or "
        "`pmpm_payer` / `pmpm_payer_plan` for population trends.",
    ),
    (
        "cms_hcc",
        "models/data_marts/cms_hcc",
        "CMS-HCC Risk Adjustment",
        "CMS-HCC (V24/V28) risk factors and risk scores per member for the "
        "configured payment year (`cms_hcc_payment_year`, 2018 in this demo).",
    ),
    (
        "hcc_suspecting",
        "models/data_marts/hcc_suspecting",
        "HCC Suspecting",
        "Suspected (not yet coded) HCCs per member with the evidence that "
        "triggered the suspicion.",
    ),
    (
        "hcc_recapture",
        "models/data_marts/hcc_recapture",
        "HCC Recapture",
        "Whether previously documented HCCs were recaptured in the payment "
        "year, and recapture rates by payer and month.",
    ),
    (
        "chronic_conditions",
        "models/data_marts/chronic_conditions",
        "Chronic Conditions",
        "Chronic condition flags per member using both the CMS Chronic "
        "Conditions Warehouse definitions and Tuva's own hierarchy, in long "
        "(one row per member-condition) and wide (one row per member) forms.",
    ),
    (
        "ccsr",
        "models/data_marts/ccsr",
        "CCSR",
        "AHRQ Clinical Classifications Software Refined groupings of ICD-10 "
        "diagnosis and procedure codes into clinically meaningful categories.",
    ),
    (
        "ed_classification",
        "models/data_marts/ed_classification",
        "ED Classification",
        "Emergency department visits classified with the NYU/Billings "
        "algorithm (e.g. non-emergent, emergent/primary-care treatable).",
    ),
    (
        "readmissions",
        "models/data_marts/readmissions",
        "Readmissions",
        "Acute inpatient stays augmented with CMS readmission logic "
        "(index admission, planned, 30-day unplanned readmission flags).",
    ),
    (
        "ahrq_measures",
        "models/data_marts/ahrq_measures",
        "AHRQ Prevention Quality Indicators",
        "AHRQ PQI numerators, denominators, exclusions, and rates for "
        "potentially avoidable hospitalizations.",
    ),
    (
        "quality_measures",
        "models/data_marts/quality_measures",
        "Quality Measures",
        "Member-level quality measure results (denominator / numerator / "
        "exclusion) and summary performance rates for the period ending "
        "`quality_measures_period_end` (2018-12-31 in this demo).",
    ),
    (
        "pharmacy",
        "models/data_marts/pharmacy",
        "Pharmacy",
        "Pharmacy claims enriched with RxNorm drug attributes and "
        "brand-to-generic savings opportunities.",
    ),
    (
        "provider_attribution",
        "models/data_marts/provider_attribution",
        "Provider Attribution",
        "Assignment of each member to a primary care provider, yearly and "
        "as of the latest claims date, with the full candidate ranking.",
    ),
]

# Hand-written column descriptions for marts whose final models ship without
# column docs upstream. Sourced from the model SQL and the Tuva mart docs.
SUPPLEMENTAL_DESCRIPTIONS = {
    "provider_attribution": {
        "performance_year": "Calendar year the yearly attribution applies to (Jan-Dec window, 24-month fallback spans Jan of Y-1 to Dec of Y).",
        "as_of_date": "Date the rolling 12/24-month current windows end on (max claim_end_date, or var `provider_attribution_as_of_date`).",
        "provider_id": "Rendering NPI of the attributed / candidate provider.",
        "provider_bucket": "Provider classification from NPPES taxonomy: `pcp`, `npp`, `specialist`, `other_individual`, or `unknown`.",
        "prov_specialty": "Provider specialty from the Medicare taxonomy crosswalk.",
        "assigned_step": "Attribution pass (1-5) that produced the assignment; lower is stronger evidence.",
        "step": "First attribution pass (1-5) the provider qualifies for.",
        "step_description": "Human-readable label for the step, e.g. '12-month PCP/NPP primary-care HCPCS'.",
        "allowed_amount": "Allowed dollars between the member and provider in the step's window (falls back to paid when allowed is missing). Primary ranking criterion.",
        "visits": "Distinct encounters between the member and provider in the step's window. Secondary ranking criterion.",
        "lookback_start_date": "Start of the claims window used for the assigned step.",
        "lookback_end_date": "End of the claims window used for the assigned step.",
        "ranking": "Provider's rank for the member within the scope (1 = assigned provider).",
        "scope": "`current` or `yearly` attribution scope.",
        "attribution_key": "Surrogate key for the member (and year, for yearly scope) attribution record.",
    },
}

SCHEMA_ELSE_RE = re.compile(r"else\s*-?%\}\s*([A-Za-z_][A-Za-z0-9_]*)")
FINAL_SELECT_RE = re.compile(r"^select\b(.*?)^from\b", re.IGNORECASE | re.MULTILINE | re.DOTALL)
MIN_DOCUMENTED_COLUMNS = 3


def clean(text):
    if not text:
        return ""
    return re.sub(r"\s+", " ", str(text)).strip().replace("|", "\\|")


def resolve_schema(raw_schema):
    if not raw_schema:
        return ""
    match = SCHEMA_ELSE_RE.search(raw_schema)
    return match.group(1) if match else clean(raw_schema)


def column_tests(column):
    names = set()
    for test in (column.get("tests") or []) + (column.get("data_tests") or []):
        names.add(test if isinstance(test, str) else next(iter(test)))
    return names


def column_type(column):
    meta = (column.get("config") or {}).get("meta") or column.get("meta") or {}
    return meta.get("data_type") or column.get("data_type") or ""


def model_grain(model):
    for test in (model.get("tests") or []) + (model.get("data_tests") or []):
        if not isinstance(test, dict):
            continue
        name, body = next(iter(test.items()))
        if name.endswith("unique_combination_of_columns") and isinstance(body, dict):
            cols = (body.get("arguments") or body).get("combination_of_columns") or []
            return [re.sub(r"\{\{.*?['\"](\w+)['\"].*?\}\}", r"\1", c) for c in cols]
    for column in model.get("columns") or []:
        if "unique" in column_tests(column):
            return [column["name"]]
    return []


def split_top_level(select_list):
    parts, depth, current = [], 0, []
    for char in select_list:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if char == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
    parts.append("".join(current))
    return parts


def columns_from_sql(sql_path):
    """Best-effort column list from the last top-level select of a model."""
    with open(sql_path) as handle:
        sql = re.sub(r"\{#.*?#\}", "", handle.read(), flags=re.DOTALL)
    matches = FINAL_SELECT_RE.findall(sql)
    if not matches:
        return []
    names = []
    for expression in split_top_level(matches[-1]):
        expression = re.sub(r"--.*", "", expression).strip()
        if not expression or expression == "*":
            continue
        alias = re.search(r"\bas\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", expression, re.IGNORECASE)
        name = alias.group(1) if alias else expression.split(".")[-1].split()[-1]
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) and name not in names:
            names.append(name)
    return names


def load_models(tuva_path):
    sql_paths = {
        os.path.basename(path)[:-4]: path
        for path in glob.glob(os.path.join(tuva_path, "models", "**", "*.sql"), recursive=True)
    }
    glossary = collections.defaultdict(collections.Counter)
    by_mart = collections.OrderedDict((key, []) for key, *_ in MARTS)
    for key, rel_dir, *_ in MARTS:
        for yml_path in sorted(glob.glob(os.path.join(tuva_path, rel_dir, "**", "*.yml"), recursive=True)):
            with open(yml_path) as handle:
                content = yaml.safe_load(handle) or {}
            for model in content.get("models") or []:
                for column in model.get("columns") or []:
                    if column.get("description"):
                        glossary[column["name"]][clean(column["description"])] += 1
                sql_path = sql_paths.get(model["name"], "")
                if f"{os.sep}final{os.sep}" in sql_path:
                    by_mart[key].append((model, sql_path))
    return by_mart, glossary


def build_columns(model, sql_path, glossary, supplemental):
    columns, seen = [], set()
    for column in model.get("columns") or []:
        if column["name"] in seen:
            continue
        seen.add(column["name"])
        columns.append(
            {
                "name": column["name"],
                "type": column_type(column),
                "tests": column_tests(column),
                "description": clean(column.get("description")),
            }
        )
    if len(columns) >= MIN_DOCUMENTED_COLUMNS:
        return columns, False
    documented = {c["name"]: c for c in columns}
    inferred = []
    for name in columns_from_sql(sql_path):
        column = documented.get(name) or {"name": name, "type": "", "tests": set(), "description": ""}
        if not column["description"] and name in supplemental:
            column["description"] = supplemental[name]
        elif not column["description"] and glossary.get(name):
            column["description"] = glossary[name].most_common(1)[0][0] + " *(inferred)*"
        inferred.append(column)
    return (inferred or columns), bool(inferred)


def render_mart(key, title, summary, models, glossary):
    lines = [
        f"# {title} (`{key}`)",
        "",
        summary,
        "",
        "[Back to data dictionary index](README.md) | [ERD](../erd.md)",
        "",
        "## Tables",
        "",
        "| Table | Grain (unique key) | Description |",
        "|---|---|---|",
    ]
    rendered = []
    for model, sql_path in models:
        config = model.get("config") or {}
        schema = resolve_schema(config.get("schema"))
        alias = config.get("alias") or model["name"]
        relation = f"{schema}.{alias}"
        grain = model_grain(model)
        grain_text = ", ".join(f"`{c}`" for c in grain) if grain else "_not declared_"
        anchor = re.sub(r"[^a-z0-9_-]", "", relation.replace(".", "").lower())
        lines.append(f"| [`{relation}`](#{anchor}) | {grain_text} | {clean(model.get('description')) or '_No upstream description._'} |")
        rendered.append((model, sql_path, relation, grain_text))
    lines.append("")

    for model, sql_path, relation, grain_text in rendered:
        columns, from_sql = build_columns(model, sql_path, glossary, SUPPLEMENTAL_DESCRIPTIONS.get(key, {}))
        lines += [
            f"## {relation}",
            "",
            f"- **dbt model:** `{model['name']}`",
            f"- **Grain:** {grain_text}",
            f"- **Materialization:** {(model.get('config') or {}).get('materialized', 'table')}",
        ]
        if model.get("description"):
            lines.append(f"- **Description:** {clean(model['description'])}")
        if from_sql:
            lines.append(
                "- **Note:** columns are not documented upstream; the list below is "
                "derived from the model SQL. Descriptions marked *(inferred)* are "
                "borrowed from same-named columns elsewhere in Tuva; the rest are "
                "hand-written from the model logic."
            )
        lines += ["", "| Column | Type | Key / Tests | Description |", "|---|---|---|---|"]
        for column in columns:
            flags = []
            if "unique" in column["tests"]:
                flags.append("unique")
            if "not_null" in column["tests"]:
                flags.append("not null")
            lines.append(
                f"| `{column['name']}` | {column['type'] or ''} | {', '.join(flags)} | {column['description']} |"
            )
        lines.append("")
    return "\n".join(lines)


def render_index(by_mart, package_version):
    lines = [
        "# Data dictionary",
        "",
        "Analyst-facing tables produced by this project (the Tuva Project "
        f"package, version `{package_version}`). Each mart has its own page listing "
        "every table, its grain, and every column.",
        "",
        "- Schemas below are the defaults for this project (`tuva_schema_prefix` "
        "unset); they are created in your target database.",
        "- Staging (`*__stg_*`) and intermediate (`_int_*`) relations also exist in "
        "these schemas but are implementation details and are not documented here.",
        "- See [`../erd.md`](../erd.md) for how the tables join.",
        "",
        "_This directory is generated by `docs/tools/generate_data_dictionary.py`; "
        "edit that script (or the upstream Tuva YAML), not these files._",
        "",
        "| Mart | Schema | Tables |",
        "|---|---|---|",
    ]
    for key, _, title, _summary in MARTS:
        models = by_mart[key]
        if not models:
            continue
        schemas = sorted({resolve_schema((m.get("config") or {}).get("schema")) for m, _ in models})
        tables = ", ".join(f"`{(m.get('config') or {}).get('alias') or m['name']}`" for m, _ in models)
        lines.append(f"| [{title}]({key}.md) | {', '.join(f'`{s}`' for s in schemas)} | {tables} |")
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--tuva-path", default=DEFAULT_TUVA_PATH)
    parser.add_argument("--out-dir", default=DEFAULT_OUT_DIR)
    args = parser.parse_args()

    project_file = os.path.join(args.tuva_path, "dbt_project.yml")
    if not os.path.exists(project_file):
        sys.exit(f"Tuva package not found at {args.tuva_path}; run `dbt deps` or pass --tuva-path.")
    with open(project_file) as handle:
        package_version = (yaml.safe_load(handle) or {}).get("version", "unknown")

    by_mart, glossary = load_models(args.tuva_path)
    os.makedirs(args.out_dir, exist_ok=True)
    for key, _, title, summary in MARTS:
        if not by_mart[key]:
            continue
        with open(os.path.join(args.out_dir, f"{key}.md"), "w") as handle:
            handle.write(render_mart(key, title, summary, by_mart[key], glossary))
    with open(os.path.join(args.out_dir, "README.md"), "w") as handle:
        handle.write(render_index(by_mart, package_version))
    print(f"Wrote data dictionary for {sum(len(v) for v in by_mart.values())} tables to {args.out_dir}")


if __name__ == "__main__":
    main()

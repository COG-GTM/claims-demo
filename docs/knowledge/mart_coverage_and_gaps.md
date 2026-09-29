# Knowledge note: what each mart answers, and what a claims analytics team still needs

Audience: analysts and analytics engineers deciding whether this project can answer a question today, or whether something still needs to be built.

## Scope and how this was derived

- **"Existing marts" means what `main` builds today.** This repo has no custom marts of its own. `models/` only holds input-layer
  placeholders plus `input_layer__provider_attribution`. Every analytic table comes from the Tuva package pinned in `packages.yml`
  (`>=0.17.0,<0.18.0`, currently resolves to **v0.17.2**).
- A mart counts as enabled if its `enabled` config resolves to true under this project's vars (`claims_enabled: true`,
  `clinical_enabled: true`, `cms_hcc_payment_year: 2018`, `quality_measures_period_end: 2018-12-31`). I read those configs from the
  Tuva v0.17.2 source.
- Several feature branches that add custom marts (for example `ed-utilization-mart`, `claims-by-provider-mart`, `member-months-mart`)
  are **not merged**. They appear only in the gap table as in-flight work that could close a gap.
- `docs/manifest.json` / `docs/catalog.json` were generated in 2023 with dbt 1.3.1 on an older Tuva release. They do **not** match
  the current package, so don't use them as the source of truth for mart names.

### Data caveats that affect every answer

- Clinical input-layer models (`condition`, `encounter`, `medication`, `patient`, `procedure`, `practitioner`, `location`) are empty
  placeholders (`limit 0` / typed nulls). Clinical signal only comes from seeded `lab_result`, `observation`, `immunization`, and
  `appointment`. Conditions, procedures, and encounters used by the marts are therefore **claims-derived**.
- The demo data is ~1,000 synthetic members. Measure periods are pinned to 2018. The data is fine for showing how the marts work,
  but not for benchmarking or for rates that have small denominators.

## Mart → analytics question map (enabled on `main`)

Schema names are Tuva defaults (`tuva_schema_prefix` unset).

| Mart / schema | Key tables | Grain | Analytics question it answers |
|---|---|---|---|
| **Core** (`core`) | `medical_claim`, `pharmacy_claim`, `eligibility`, `member_months`, `encounter`, `condition`, `procedure`, `patient` | claim line / member-month / encounter | "What happened, to whom, when, and what was paid?" This is the single normalized source for ad-hoc claims analysis. `member_months` is the denominator for every PMPM or per-1,000 metric. `medical_claim` carries `service_category_1-3`, `encounter_type`, paid/allowed/charge, member cost share, and `in_network_flag`. |
| **Claims preprocessing** (`claims_preprocessing`, surfaced through core) | `service_category__service_category_grouper`, `*__encounter_grain` (26 encounter types) | claim line → encounter | "What kind of service is this claim?" and "Which claim lines make up one inpatient stay, ED visit, office visit, etc.?" It powers encounter counts and every service-category split. |
| **Financial PMPM** (`financial_pmpm`) | `pmpm_prep`, `pmpm_payer`, `pmpm_payer_plan` | member × month; payer(×plan) × month | "What's our paid/allowed PMPM, and how does it split across service categories (inpatient, outpatient, office visit, ancillary, pharmacy, and ~20 sub-categories)?" It also answers "How does PMPM trend month over month by payer/plan?" `pmpm_prep` carries payer- and custom-attributed provider columns, so PMPM can be cut by attributed provider/practice. |
| **CMS-HCC** (`cms_hcc`) | `patient_risk_factors(_monthly)`, `patient_risk_scores(_monthly, _monthly_by_factor_type)` | member × payment year (and collection month) | "What is each member's CMS-HCC risk score (V24, V28, blended, normalized, payment), and which HCCs and demographic factors drive it?" Payment year is 2018 here. |
| **HCC Suspecting** (`hcc_suspecting`) | `list`, `list_all`, `list_rollup`, `summary` | member × HCC × evidence | "Which members probably have an HCC that hasn't been coded this year, and what's the evidence (prior-year code, lab, medication, comorbidity)?" This is for coding and documentation outreach. |
| **HCC Recapture** (`hcc_recapture`) | `gap_status`, `hcc_status`, `recapture_rates(_monthly, _monthly_ytd)` | member × HCC × payment year; payer × period | "What share of last year's HCCs have been recaptured so far this year, and which gaps are still open?" |
| **Chronic Conditions** (`chronic_conditions`) | `cms_chronic_conditions_long/_wide`, `tuva_chronic_conditions_long/_wide` | member × condition; one row per member | "How prevalent is each chronic condition (CMS CCW definitions or the Tuva hierarchy)?" and "When was each one first and last diagnosed?" This is for cohort building and prevalence counts. |
| **CCSR** (`ccsr`) | `long_condition_category`, `singular_condition_category`, `long_procedure_category`, `procedure_summary` | diagnosis/procedure code → AHRQ CCSR category | "What are the leading clinical categories of diagnoses and procedures?" It gives a clinically meaningful grouping for condition-level and procedure-level analysis. |
| **ED Classification** (`ed_classification`) | `summary` | ED encounter | "How much ED use is non-emergent, primary-care-treatable, or preventable (NYU ED algorithm, Johnston ICD-10 version), and what did it cost?" Each row has facility, patient demographics, and geography for targeting. |
| **Readmissions** (`readmissions`) | `readmission_summary`, `encounter_augmented` | acute inpatient encounter | "What's our 30-day all-cause / unplanned readmission rate (CMS HWR-style index logic), by specialty cohort, facility, and DRG?" `encounter_augmented` explains why encounters were disqualified. |
| **AHRQ PQI** (`ahrq_measures`) | `pqi_rate`, `pqi_summary`, `pqi_num/denom/exclusion_long` | PQI × year; qualifying admission | "How many admissions were potentially avoidable (ambulatory-care-sensitive), at what rate per 100k, and what did they cost?" |
| **Quality Measures** (`quality_measures`) | `summary_long`, `summary_wide`, `summary_counts` | member × measure; measure | "Which members are in the denominator and numerator for each measure, and where are the care gaps?" In-scope measures are medication adherence (diabetes, RAS, statins), statin use in diabetes/CVD, medication documentation, and pain assessment. This is a subset of HEDIS/Stars, not the full set. |
| **Pharmacy** (`pharmacy`) | `pharmacy_claim_expanded`, `brand_generic_opportunity`, `generic_available_list` | Rx claim line | "Which brand fills had a generic available, and how much would generic substitution have saved?" `pharmacy_claim_expanded` adds RxNorm ingredient, brand/generic, and dose form to every fill. |
| **Provider Attribution** (`tuva_provider_attribution`) | `assigned_beneficiaries_yearly`, `assigned_beneficiaries_current`, `provider_ranking` | member × year → provider | "Which primary care provider is each member attributed to (MSSP-style stepwise rules), and who were the runner-up candidates?" |
| **Data Quality / DQI** (`data_quality`, `mart_review`) | `data_quality__summary`, `data_quality__data_quality_detail`, `mart_review__*` | field × check; mart-level review | "Can we trust the input data, and does each mart look reasonable?" Examples: missing fields, invalid codes, claims without enrollment, enrollment changes. Run this before publishing any number. |

### Present in the package but NOT enabled here

| Mart | Why it's off | What it would add |
|---|---|---|
| `semantic_layer` (star schema: `fact_claims`, `fact_member_months`, `fact_encounters`, `dim_member`, …) | needs `semantic_layer_enabled: true` | A BI-ready star schema (Power BI oriented). It would give one join path across cost, risk, quality, and conditions. |
| `benchmarks` (expected values, `predict_member_month`, `predict_inpatient`) | needs `benchmarks_already_created: true` plus externally trained predictions | Expected vs. actual PMPM and inpatient outcomes, i.e. risk-adjusted benchmarking. |
| `fhir_preprocessing`, `normalize` | off by default | FHIR export; clinical code-mapping work queues. These aren't claims analytics. |
| Legacy `data_quality__*` (e.g. `claim_date_trends`, `data_loss`) | `enable_legacy_data_quality: false` | Claim-date trend and data-loss checks, useful for spotting lag and missing months. |

## Gaps a claims analytics team would still need filled

Ordered roughly by how often the question comes up and how blocking it is. "Input change" means the Tuva input layer (and the demo
seeds) have no field that supports the question today.

| # | Question the team will ask | Why the current marts don't answer it | What's needed | In-flight branch |
|---|---|---|---|---|
| 1 | **Utilization per 1,000**: admits, days, ED visits, and office visits per 1,000, by service category and payer/plan | `financial_pmpm` is cost-only. Readmissions, ED, and PQI give counts or rates for narrow cohorts but no general per-1,000 cube over `member_months`. | A `utilization__per_1000` mart: encounter_type/service_category × payer × plan × month, with counts / member_months × 12,000. | `ed-utilization-mart` (ED only) |
| 2 | **Unit cost and trend decomposition**: why PMPM moved, split into utilization, unit cost, and mix | There are no cost-per-encounter / per-admit / per-unit tables and no YoY decomposition. | A unit-cost mart (paid/allowed per encounter, per day, per DRG, per CPT) plus a trend-bridge model built on items 1 and 2. | none |
| 3 | **Claim lifecycle, completion, and IBNR**: how complete recent months are, and how big the lag triangle is | The input layer has `paid_date` but no received/adjudication date, claim status, or adjustment/reversal indicators, so completion factors are approximate. `claim_date_trends` is disabled. | Input change (received date, claim status, adjustment type/original claim id). Then a paid-lag triangle and completion-factor mart. Short term: a service-month × paid-month triangle from `paid_date`. | none |
| 4 | **Denials and payment integrity**: denial rate and reasons, duplicates, E&M upcoding, unbundling, modifier misuse | There are no denial, status, or reason-code fields. No mart looks at E&M level distributions or duplicate lines. | Input change for denials. Payment-integrity marts for E&M distribution by rendering provider, duplicate detection, and NCCI-style edits on existing `hcpcs_code`/modifiers. | none |
| 5 | **Provider / facility performance**: spend, utilization, unit cost, and quality by rendering, billing, or facility provider | Attribution says who owns the member, but no mart rolls cost and utilization up to the provider that delivered the care. `ed_classification` and `readmissions` have `facility_id` only. | A provider-performance mart keyed on `rendering_id`/`billing_id`/`facility_id` × period, with peer-group comparisons. | `claims-by-provider-mart` |
| 6 | **Network leakage / site of service**: out-of-network spend and shiftable site of service (hospital outpatient vs. ASC/office) | `in_network_flag` exists on core claims but nothing aggregates it. Nothing flags services that could move to a cheaper setting. | A leakage mart (in/out-of-network paid by service category and attributed provider) plus a site-of-service opportunity model. | none |
| 7 | **Risk-adjusted cost**: PMPM divided by risk score; actual vs. expected | `financial_pmpm` and `cms_hcc` are separate marts and nothing joins them. `benchmarks` is disabled. | A member-year model joining `pmpm_prep` rollups to `cms_hcc__patient_risk_scores` (risk-adjusted PMPM and O/E). Or enable `benchmarks`. | `risk-adjustment-mart` |
| 8 | **Non-Medicare risk models**: HHS-HCC (ACA), CDPS+Rx (Medicaid), commercial | Only CMS-HCC (Medicare Advantage) ships. | A new risk-model mart for whichever lines of business the team covers. | none |
| 9 | **High-cost claimants / stop-loss**: members over $X, their drivers, and persistence year over year | Member-month spend exists in `pmpm_prep`, but there are no thresholds, rankings, or persistence flags. | A high-cost-claimant mart: member-year spend, top-N, specific-deductible thresholds, dominant conditions (CCSR/chronic), prior-year status. | none |
| 10 | **Cost by condition / episode**: what diabetes (or a CCSR category) costs, and total cost of an episode | Chronic conditions and CCSR give flags and categories but no dollars. There's no episode grouper. | A condition-cost mart allocating claim spend to CCSR/chronic categories, and later an episode grouper (e.g. PROMETHEUS/BPCI-style). | `chronic-conditions` (int model only) |
| 11 | **Membership analytics**: enrollment spans, churn, continuous enrollment, new vs. termed members | `core.member_months` gives the grain. `mart_review__enrollment_change` is a DQ view, not an analytic mart. | An enrollment-spans / member-summary mart with continuous-enrollment flags (these are also denominators for HEDIS-style measures). | `member-months-mart` |
| 12 | **Pharmacy beyond generics**: spend by therapeutic class, specialty drugs, trend, PBM channel, rebates | The `pharmacy` mart only covers generic substitution. There's no drug-class grouper, specialty flag, or rebate data. | A pharmacy spend mart (class, specialty, brand/generic trend). Rebates need an input change. | `pharmacy-spend-mart`, `pbm-drug-category` |
| 13 | **Member cost share / affordability**: OOP by plan, deductible progression | Copay, coinsurance, and deductible are on core claims but not aggregated. | A cost-share mart: member × plan-year OOP accumulation. | none |
| 14 | **Broader quality / Stars coverage** | Only 7 measures ship. Screening, well-child, and utilization HEDIS measures are absent, and the empty clinical inputs limit numerators. | Add measures the team reports on, and populate clinical inputs where available. | none |
| 15 | **One governed BI layer** | Marts are separate schemas with their own grains. The semantic layer is disabled. | Enable `semantic_layer` or build conformed dims (member, provider, date, service category) that the new marts above key into. | `marts-data-dictionary-erd` (docs only) |

## Assumptions

1. "Mart" covers the Tuva data-mart layer plus `core` and claims preprocessing, because analysts query those directly. Staging and
   intermediate models are excluded.
2. "Existing" means built from `main` with the current vars. Unmerged branches are treated as proposals.
3. The target team does payer / value-based-care claims analytics (cost, utilization, risk, quality, provider performance). A
   provider-side revenue-cycle team would weight gaps 3 and 4 higher.
4. Gap priority reflects typical payer analytics demand, not a stakeholder survey.

## Maintenance

Re-check this note when `packages.yml` moves to a new Tuva minor version, when project vars change (especially `*_enabled`), or
when one of the in-flight mart branches merges. Update the gap table's last column when that happens.

{% docs claim_amount_checks %}
## Claim amount checks

Range and distribution checks on the dollar amount columns of `medical_claim` and
`pharmacy_claim`, written with [dbt-expectations](https://github.com/metaplane/dbt-expectations)
tests. Run them on their own with:

```
dbt build --select medical_claim pharmacy_claim      # load seeds, then test
dbt test  --select tag:claim_amount_checks           # tests only
dbt test  --select tag:claim_amount_range            # row-level range checks only
dbt test  --select tag:claim_amount_distribution     # aggregate distribution bands only
```

### What is checked

| Check | Test | Grain | Severity |
|---|---|---|---|
| No negative amounts | `dbt_expectations.expect_column_values_to_be_between` (`min_value: 0`) | row | warn |
| Negative share within tolerance | `dbt_expectations.expression_between` | table | error |
| Line / fill ceiling | `dbt_expectations.expect_column_values_to_be_between` (`max_value`) | row | error |
| Median, mean and p99 within a band | `dbt_expectations.expect_column_median/mean/quantile_values_to_be_between` | table, per claim type | `claim_amount_distribution_severity` (default error) |

Nulls pass every check; completeness is covered by the Tuva input-layer tests.
All checks use dbt-expectations SQL that Fabric does not support (boolean select
expressions, `percentile_cont` without `over`), so they are disabled on Fabric, matching
how the Tuva package gates its own dbt-expectations tests. The Tuva package's
Fabric-compatible wrapper macros depend on package-internal helpers and cannot be
called from this root project.

### Baseline (demo data, `versioned_tuva_synthetic_data/0.15.0`)

| Table | Slice | Column | Non-null rows | Negative | p50 | Mean | p99 | Max |
|---|---|---|---|---|---|---|---|---|
| medical_claim | professional | paid_amount | 133,474 | 0 | 15.02 | 45.84 | 380.43 | 13,782 |
| medical_claim | professional | allowed_amount | 133,474 | 0 | 18.28 | 59.27 | 487.86 | 41,533 |
| medical_claim | professional | charge_amount | 133,474 | 0 | 18.28 | 59.27 | 487.86 | 41,533 |
| medical_claim | institutional | paid_amount | 8,626 | 19 | 99.76 | 807.42 | 12,084 | 136,819 |
| medical_claim | institutional | charge_amount | 34,521 | 0 | 1,901.50 | 11,764 | 136,357 | 426,066 |
| pharmacy_claim | all | paid_amount | 12,019 | 0 | 34.40 | 167.25 | 1,781.76 | 3,581 |
| pharmacy_claim | all | allowed_amount | 12,019 | 0 | 52.17 | 706.25 | 7,821.61 | 241,793 |

Institutional `allowed_amount`, pharmacy `charge_amount`, and all cost-share and
`total_cost_amount` columns are entirely null in the demo data. They still get the
row-level range checks so a real data source mapped into this project is covered.

### Thresholds and why

**Negative values (row, warn).** After adjustment/denial/reversal (ADR) logic is applied,
the Tuva input layer expects no negative amounts. A negative line almost always means an
unmatched reversal or a sign flip. The row-level test warns and lists every offending line
rather than failing, because the demo data ships with 19 negative institutional
`paid_amount` lines (as low as -$100.70, single-line claims with no offsetting positive line).
Those are real findings worth seeing but not worth blocking the demo build on.

**Negative share (table, error): `claim_amount_negative_share_max = 0.001` (0.1%).**
A handful of unmatched reversals is normal; a systemic problem (reversals not netted,
sign convention flipped for a file) shows up as a large share. The demo sits at 0.013%
of non-null medical `paid_amount` (19 / 142,100), so the 0.1% tolerance leaves
roughly 7x headroom before an error while still catching any systemic issue.

**Line / fill ceilings (row, error).** These catch unit and mapping errors (cents loaded as
dollars, a missing implied decimal, a claim-level total repeated on every line) that
produce values no real line can have. They are set well above anything plausible for a
single line so they only fire on errors:

| Var | Value | Applies to | Why |
|---|---|---|---|
| `claim_amount_medical_line_paid_max` | $1,000,000 | medical paid, allowed, total cost | ~7x the largest paid line in the demo ($136,819). Even very high-cost inpatient stays rarely put more than a few hundred thousand dollars of paid on one line. |
| `claim_amount_medical_line_charge_max` | $2,500,000 | medical charge | Billed charges typically run several times allowed; ~6x the largest billed line in the demo ($426,066). |
| `claim_amount_professional_line_paid_max` | $100,000 | professional paid, allowed | A single professional line (one CPT/HCPCS code) paid at $100k+ is implausible; ~7x the demo max ($13,782). Needed because a large professional outlier barely moves the mean of 133k lines. |
| `claim_amount_professional_line_charge_max` | $250,000 | professional charge | Same reasoning for billed charges; ~6x the demo max ($41,533). |
| `claim_amount_pharmacy_fill_max` | $500,000 | pharmacy paid, allowed, charge | ~2x the demo max ($241,793). Covers multi-month fills of high-cost specialty drugs; the highest-cost one-time gene therapies are usually billed on the medical benefit. |
| `claim_amount_member_cost_share_line_max` | $25,000 | coinsurance, copayment, deductible | Above typical individual and family out-of-pocket maximums; a single line with more cost share than this is almost certainly mis-mapped. |

**Distribution bands (table, per claim type).** Claim amounts are heavily right-skewed and
professional and institutional lines differ by 10-100x, so the bands are computed per claim
type using `row_condition`, and they use the median and p99 rather than z-scores (a
3-sigma rule on raw, skewed dollars flags legitimate inpatient claims and misses shifts in
the bulk of the data). Each band is the demo baseline widened by a fixed factor, then
rounded outward to two significant figures:

- Median and mean: baseline ÷2 to ×2. Normal year-over-year drift in unit cost and service
  mix is a few percent to tens of percent, well inside 2x; unit errors (×10, ×100, ÷100),
  mass zeroing, or a bulk shift toward high-cost services fall outside. The mean is
  sensitive to outliers, so large injected values move it out of band even when the median
  does not.
- p99: baseline ÷3 to ×3. The tail is noisier than the centre, so it gets a wider band; it
  catches a heavier or truncated tail (for example, charges capped by a bad cast or a
  loader that drops high-cost lines).

The bands are calibrated to the demo dataset. When pointing this project at other data,
either recompute them from a profile of that data or set
`claim_amount_distribution_severity: warn` until they are recalibrated.
{% enddocs %}

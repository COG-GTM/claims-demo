# Provider Attribution (`provider_attribution`)

Assignment of each member to a primary care provider, yearly and as of the latest claims date, with the full candidate ranking.

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`tuva_provider_attribution.assigned_beneficiaries_yearly`](#tuva_provider_attributionassigned_beneficiaries_yearly) | `attribution_key` | _No upstream description._ |
| [`tuva_provider_attribution.assigned_beneficiaries_current`](#tuva_provider_attributionassigned_beneficiaries_current) | `attribution_key` | _No upstream description._ |
| [`tuva_provider_attribution.provider_ranking`](#tuva_provider_attributionprovider_ranking) | `attribution_key`, `provider_id` | _No upstream description._ |

## tuva_provider_attribution.assigned_beneficiaries_yearly

- **dbt model:** `provider_attribution__assigned_beneficiaries_yearly`
- **Grain:** `attribution_key`
- **Materialization:** table
- **Note:** columns are not documented upstream; the list below is derived from the model SQL. Descriptions marked *(inferred)* are borrowed from same-named columns elsewhere in Tuva; the rest are hand-written from the model logic.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique person_id for each person. *(inferred)* |
| `performance_year` |  |  | Calendar year the yearly attribution applies to (Jan-Dec window, 24-month fallback spans Jan of Y-1 to Dec of Y). |
| `provider_id` |  |  | Rendering NPI of the attributed / candidate provider. |
| `provider_bucket` |  |  | Provider classification from NPPES taxonomy: `pcp`, `npp`, `specialist`, `other_individual`, or `unknown`. |
| `prov_specialty` |  |  | Provider specialty from the Medicare taxonomy crosswalk. |
| `assigned_step` |  |  | Attribution pass (1-5) that produced the assignment; lower is stronger evidence. |
| `step_description` |  |  | Human-readable label for the step, e.g. '12-month PCP/NPP primary-care HCPCS'. |
| `allowed_amount` |  |  | Allowed dollars between the member and provider in the step's window (falls back to paid when allowed is missing). Primary ranking criterion. |
| `visits` |  |  | Distinct encounters between the member and provider in the step's window. Secondary ranking criterion. |
| `lookback_start_date` |  |  | Start of the claims window used for the assigned step. |
| `lookback_end_date` |  |  | End of the claims window used for the assigned step. |
| `attribution_key` |  | unique, not null | Surrogate key for the member (and year, for yearly scope) attribution record. |
| `tuva_last_run` |  |  | The date and timestamp of the dbt run. *(inferred)* |

## tuva_provider_attribution.assigned_beneficiaries_current

- **dbt model:** `provider_attribution__assigned_beneficiaries_current`
- **Grain:** `attribution_key`
- **Materialization:** table
- **Note:** columns are not documented upstream; the list below is derived from the model SQL. Descriptions marked *(inferred)* are borrowed from same-named columns elsewhere in Tuva; the rest are hand-written from the model logic.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique person_id for each person. *(inferred)* |
| `as_of_date` |  |  | Date the rolling 12/24-month current windows end on (max claim_end_date, or var `provider_attribution_as_of_date`). |
| `provider_id` |  |  | Rendering NPI of the attributed / candidate provider. |
| `provider_bucket` |  |  | Provider classification from NPPES taxonomy: `pcp`, `npp`, `specialist`, `other_individual`, or `unknown`. |
| `prov_specialty` |  |  | Provider specialty from the Medicare taxonomy crosswalk. |
| `assigned_step` |  |  | Attribution pass (1-5) that produced the assignment; lower is stronger evidence. |
| `step_description` |  |  | Human-readable label for the step, e.g. '12-month PCP/NPP primary-care HCPCS'. |
| `allowed_amount` |  |  | Allowed dollars between the member and provider in the step's window (falls back to paid when allowed is missing). Primary ranking criterion. |
| `visits` |  |  | Distinct encounters between the member and provider in the step's window. Secondary ranking criterion. |
| `lookback_start_date` |  |  | Start of the claims window used for the assigned step. |
| `lookback_end_date` |  |  | End of the claims window used for the assigned step. |
| `attribution_key` |  | unique, not null | Surrogate key for the member (and year, for yearly scope) attribution record. |
| `tuva_last_run` |  |  | The date and timestamp of the dbt run. *(inferred)* |

## tuva_provider_attribution.provider_ranking

- **dbt model:** `provider_attribution__provider_ranking`
- **Grain:** `attribution_key`, `provider_id`
- **Materialization:** table
- **Note:** columns are not documented upstream; the list below is derived from the model SQL. Descriptions marked *(inferred)* are borrowed from same-named columns elsewhere in Tuva; the rest are hand-written from the model logic.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique person_id for each person. *(inferred)* |
| `performance_year` |  |  | Calendar year the yearly attribution applies to (Jan-Dec window, 24-month fallback spans Jan of Y-1 to Dec of Y). |
| `as_of_date` |  |  | Date the rolling 12/24-month current windows end on (max claim_end_date, or var `provider_attribution_as_of_date`). |
| `provider_id` |  | not null | Rendering NPI of the attributed / candidate provider. |
| `provider_bucket` |  |  | Provider classification from NPPES taxonomy: `pcp`, `npp`, `specialist`, `other_individual`, or `unknown`. |
| `prov_specialty` |  |  | Provider specialty from the Medicare taxonomy crosswalk. |
| `step` |  |  | First attribution pass (1-5) the provider qualifies for. |
| `step_description` |  |  | Human-readable label for the step, e.g. '12-month PCP/NPP primary-care HCPCS'. |
| `allowed_amount` |  |  | Allowed dollars between the member and provider in the step's window (falls back to paid when allowed is missing). Primary ranking criterion. |
| `visits` |  |  | Distinct encounters between the member and provider in the step's window. Secondary ranking criterion. |
| `scope` |  |  | `current` or `yearly` attribution scope. |
| `lookback_start_date` |  |  | Start of the claims window used for the assigned step. |
| `lookback_end_date` |  |  | End of the claims window used for the assigned step. |
| `ranking` |  |  | Provider's rank for the member within the scope (1 = assigned provider). |
| `attribution_key` |  | not null | Surrogate key for the member (and year, for yearly scope) attribution record. |
| `tuva_last_run` |  |  | The date and timestamp of the dbt run. *(inferred)* |

# Quality Measures (`quality_measures`)

Member-level quality measure results (denominator / numerator / exclusion) and summary performance rates for the period ending `quality_measures_period_end` (2018-12-31 in this demo).

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`quality_measures.summary_counts`](#quality_measuressummary_counts) | _not declared_ | Reporting measure counts with performance rates. |
| [`quality_measures.summary_long`](#quality_measuressummary_long) | _not declared_ | Long view of the results for the reporting version of all measures. Each row represents the results a measure per patient. A null for the denominator indicates that the patient was not eligible for that measure. |
| [`quality_measures.summary_wide`](#quality_measuressummary_wide) | _not declared_ | Wide view of the results for the reporting version of all measures. This model pivots measures on the patient level (i.e. one row per patient with flags for each measure. The false flags can be treated as care gaps as exclusions have been included in the pivot logic. |

## quality_measures.summary_counts

- **dbt model:** `quality_measures__summary_counts`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** Reporting measure counts with performance rates.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `measure_id` |  |  | Unique measure identification number. |
| `measure_name` |  |  | Name of the measure. |
| `measure_version` |  |  | Version of the measure. |
| `performance_period_begin` |  |  | Beginning date of the performance or measurement period. |
| `performance_period_end` |  |  | Ending date of the performance or measurement period. |
| `denominator_sum` |  |  | The denominator is associated with a given patient population that may be counted as eligible to meet a measure’s inclusion requirements. |
| `numerator_sum` |  |  | The numerator reflects the subset of patients in the denominator for whom a particular service has been provided or for whom a particular outcome has been achieved with exclusion logic applied. |
| `exclusion_sum` |  |  | Specifications of those characteristics that would cause groups of individuals to be removed from the numerator and/or denominator of a measure although they experience the denominator index event. |
| `performance_rate` |  |  | Calculated performance rate. The numerator sum divided by the denominator sum after exclusion logic applied and multiplied by 100. |
| `tuva_last_run` |  |  | The date and timestamp of the dbt run. |

## quality_measures.summary_long

- **dbt model:** `quality_measures__summary_long`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** Long view of the results for the reporting version of all measures. Each row represents the results a measure per patient. A null for the denominator indicates that the patient was not eligible for that measure.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique person_id for each person. |
| `denominator_flag` |  |  | The denominator is associated with a given patient population that may be counted as eligible to meet a measure’s inclusion requirements. |
| `numerator_flag` |  |  | The numerator reflects the subset of patients in the denominator for whom a particular service has been provided or for whom a particular outcome has been achieved. |
| `exclusion_flag` |  |  | Specifications of those characteristics that would cause groups of individuals to be removed from the numerator and/or denominator of a measure although they experience the denominator index event. |
| `performance_flag` |  |  | Performance flag calculated by using exclusion, numerator, and denominator flags. When excluded from a measure the flag is null. |
| `evidence_date` |  |  | Date of event or service that places patient in the numerator. |
| `evidence_value` |  |  | Observed evidence value for the patients in the numerator. |
| `exclusion_date` |  |  | Date of event or service that excludes patient from the measure. |
| `exclusion_reason` |  |  | Reason (usually the value set concept name) that excludes patient from the measure. |
| `performance_period_begin` |  |  | Beginning date of the performance or measurement period. |
| `performance_period_end` |  |  | Ending date of the performance or measurement period. |
| `measure_id` |  |  | Unique measure identification number. |
| `measure_name` |  |  | Name of the measure. |
| `measure_version` |  |  | Version of the measure. |
| `tuva_last_run` |  |  | The date and timestamp of the dbt run. |

## quality_measures.summary_wide

- **dbt model:** `quality_measures__summary_wide`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** Wide view of the results for the reporting version of all measures. This model pivots measures on the patient level (i.e. one row per patient with flags for each measure. The false flags can be treated as care gaps as exclusions have been included in the pivot logic.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique person_id for each person. |
| `cqm_438` |  |  | Performance flag for CQM438, Statin Therapy for the Prevention and Treatment of Cardiovascular Disease. A null indicates that the measure was not applicable for the patient. |
| `cqm_130` |  |  | Performance flag for CQM130, Documentation of Current Medications in the Medical Record. A null indicates that the measure was not applicable for the patient. |
| `nqf_0420` |  |  | Performance flag for NQF0420, Pain Assessment and Follow-Up. A null indicates that the measure was not applicable for the patient. |
| `adh_diabetes` |  |  | Performance flag for ADH-Diabetes, Medication Adherence for Diabetes Medications. A null indicates that the measure was not applicable for the patient. |
| `adh_ras` |  |  | Performance flag for ADH-RAS, Medication Adherence for Hypertension. A null indicates that the measure was not applicable for the patient. |
| `supd` |  |  | Performance flag for SUPD, Statin Use in Persons with Diabetes. A null indicates that the measure was not applicable for the patient. |
| `adh_statins` |  |  | Performance flag for ADH-Statins, Medication Adherence for Cholesterol. A null indicates that the measure was not applicable for the patient. |
| `tuva_last_run` |  |  | The date and timestamp of the dbt run. |

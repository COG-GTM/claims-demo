# CMS-HCC Risk Adjustment (`cms_hcc`)

CMS-HCC (V24/V28) risk factors and risk scores per member for the configured payment year (`cms_hcc_payment_year`, 2018 in this demo).

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`cms_hcc.patient_risk_factors`](#cms_hccpatient_risk_factors) | _not declared_ | This final model displays the contributing demographic and disease risk factors, interactions, and HCCs for each enrollee in the payment year. |
| [`cms_hcc.patient_risk_factors_monthly`](#cms_hccpatient_risk_factors_monthly) | _not declared_ | This final model displays the contributing demographic and disease risk factors, interactions, and HCCs for each enrollee in the payment year and collection period. |
| [`cms_hcc.patient_risk_scores`](#cms_hccpatient_risk_scores) | `person_id` | This final model calculates the CMS HCC raw risk score, blended risk score, normalized risk score, and payment risk score for each enrollee in the payment year. |
| [`cms_hcc.patient_risk_scores_monthly_by_factor_type`](#cms_hccpatient_risk_scores_monthly_by_factor_type) | `person_id`, `payment_year`, `payer`, `collection_end_date`, `factor_type` | This model calculates the CMS HCC raw risk score, blended risk score, normalized risk score, and payment risk score for each enrollee, factor type, in the payment year and collection period. |
| [`cms_hcc.patient_risk_scores_monthly`](#cms_hccpatient_risk_scores_monthly) | `person_id`, `payment_year`, `payer`, `collection_end_date` | This final model calculates the CMS HCC raw risk score, blended risk score, normalized risk score, and payment risk score for each enrollee in the payment year and collection period. |

## cms_hcc.patient_risk_factors

- **dbt model:** `cms_hcc__patient_risk_factors`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This final model displays the contributing demographic and disease risk factors, interactions, and HCCs for each enrollee in the payment year.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `enrollment_status_default` |  |  | Indicates the input data was missing and a default status was used. |
| `medicaid_dual_status_default` |  |  | Indicates the input data was missing and a default status was used. |
| `orec_default` |  |  | Indicates the input data was missing and a default status was used. |
| `institutional_status_default` |  |  | Indicates the input data was missing and a default status was used. |
| `risk_factor_description` |  |  | Description of the risk factor. |
| `coefficient` |  |  | Relative factor value that correspond to the CMS HCC model's risk indicators. |
| `factor_type` |  |  | Type of risk factor, e.g. Demographic, Disease, etc. |
| `model_version` |  |  | CMS HCC model version. |
| `payment_year` |  |  | The payment year the HCC and risk scores are being calculated for. |
| `tuva_last_run` |  |  | The date the model was run. |

## cms_hcc.patient_risk_factors_monthly

- **dbt model:** `cms_hcc__patient_risk_factors_monthly`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This final model displays the contributing demographic and disease risk factors, interactions, and HCCs for each enrollee in the payment year and collection period.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `enrollment_status_default` |  |  | Indicates the input data was missing and a default status was used. |
| `medicaid_dual_status_default` |  |  | Indicates the input data was missing and a default status was used. |
| `orec_default` |  |  | Indicates the input data was missing and a default status was used. |
| `institutional_status_default` |  |  | Indicates the input data was missing and a default status was used. |
| `risk_factor_description` |  |  | Description of the risk factor. |
| `coefficient` |  |  | Relative factor value that correspond to the CMS HCC model's risk indicators. |
| `factor_type` |  |  | Type of risk factor, e.g. Demographic, Disease, etc. |
| `model_version` |  |  | CMS HCC model version. |
| `payment_year` |  |  | The payment year the HCC and risk scores are being calculated for. |
| `collection_start_date` |  |  | The start date for the collection period the HCC and risk scores are being calculated for. |
| `collection_end_date` |  |  | The end date for the collection period the HCC and risk scores are being calculated for. |
| `tuva_last_run` |  |  | The date the model was run. |

## cms_hcc.patient_risk_scores

- **dbt model:** `cms_hcc__patient_risk_scores`
- **Grain:** `person_id`
- **Materialization:** table
- **Description:** This final model calculates the CMS HCC raw risk score, blended risk score, normalized risk score, and payment risk score for each enrollee in the payment year.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  | unique | Unique ID for the patient. |
| `v24_risk_score` |  |  | The sum of all patient risk factors from model version CMS-HCC-V24. If payment year >= 2024 then the score may be weighted following CMS's transition plan. |
| `v28_risk_score` |  |  | The sum of all patient risk factors from model version CMS-HCC-V28. If payment year >= 2024 then the score may be weighted following CMS's transition plan. |
| `blended_risk_score` |  |  | The sum of the v24_risk_score and v28_risk_score columns. |
| `normalized_risk_score` |  |  | The blended risk score divided by the normalization adjustment factor for the corresponding HCC model version and payment year's rate announcement from CMS. |
| `payment_risk_score` |  |  | The normalized risk score multiplied by the MA coding pattern adjustment factor for the corresponding HCC model version and payment year's rate announcement from CMS. |
| `payment_risk_score_weighted_by_months` |  |  | Payment risk score multiplied by member_months. |
| `member_months` |  |  | Member months derived from the finanicial_pmpm mart utilizing payment year eligibility. |
| `payment_year` |  |  | The payment year the HCC and risk scores are being calculated for. |
| `tuva_last_run` |  |  | The date the model was run. |

## cms_hcc.patient_risk_scores_monthly_by_factor_type

- **dbt model:** `cms_hcc__patient_risk_scores_monthly_by_factor_type`
- **Grain:** `person_id`, `payment_year`, `payer`, `collection_end_date`, `factor_type`
- **Materialization:** table
- **Description:** This model calculates the CMS HCC raw risk score, blended risk score, normalized risk score, and payment risk score for each enrollee, factor type, in the payment year and collection period.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `v24_risk_score` |  |  | The sum of all patient risk factors from model version CMS-HCC-V24. If payment year >= 2024 then the score may be weighted following CMS's transition plan. |
| `v28_risk_score` |  |  | The sum of all patient risk factors from model version CMS-HCC-V28. If payment year >= 2024 then the score may be weighted following CMS's transition plan. |
| `blended_risk_score` |  |  | The sum of the v24_risk_score and v28_risk_score columns. |
| `normalized_risk_score` |  |  | The blended risk score divided by the normalization adjustment factor for the corresponding HCC model version and payment year's rate announcement from CMS. |
| `payment_risk_score` |  |  | The normalized risk score multiplied by the MA coding pattern adjustment factor for the corresponding HCC model version and payment year's rate announcement from CMS. |
| `payment_risk_score_weighted_by_months` |  |  | Payment risk score multiplied by member_months. |
| `member_months` |  |  | Member months derived from the finanicial_pmpm mart utilizing payment year eligibility. |
| `payment_year` |  |  | The payment year the HCC and risk scores are being calculated for. This is 1 year after the collection year or year in which the diagnoses were actually coded. |
| `collection_start_date` |  |  | The start date for the collection period the HCC and risk scores are being calculated for. |
| `collection_end_date` |  |  | The end date for the collection period the HCC and risk scores are being calculated for. |
| `tuva_last_run` |  |  | The date the model was run. |

## cms_hcc.patient_risk_scores_monthly

- **dbt model:** `cms_hcc__patient_risk_scores_monthly`
- **Grain:** `person_id`, `payment_year`, `payer`, `collection_end_date`
- **Materialization:** table
- **Description:** This final model calculates the CMS HCC raw risk score, blended risk score, normalized risk score, and payment risk score for each enrollee in the payment year and collection period.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `v24_risk_score` |  |  | The sum of all patient risk factors from model version CMS-HCC-V24. If payment year >= 2024 then the score may be weighted following CMS's transition plan. |
| `v28_risk_score` |  |  | The sum of all patient risk factors from model version CMS-HCC-V28. If payment year >= 2024 then the score may be weighted following CMS's transition plan. |
| `blended_risk_score` |  |  | The sum of the v24_risk_score and v28_risk_score columns. |
| `normalized_risk_score` |  |  | The blended risk score divided by the normalization adjustment factor for the corresponding HCC model version and payment year's rate announcement from CMS. |
| `payment_risk_score` |  |  | The normalized risk score multiplied by the MA coding pattern adjustment factor for the corresponding HCC model version and payment year's rate announcement from CMS. |
| `payment_risk_score_weighted_by_months` |  |  | Payment risk score multiplied by member_months. |
| `member_months` |  |  | Member months derived from the finanicial_pmpm mart utilizing payment year eligibility. |
| `payment_year` |  |  | The payment year the HCC and risk scores are being calculated for. |
| `collection_start_date` |  |  | The start date for the collection period the HCC and risk scores are being calculated for. |
| `collection_end_date` |  |  | The end date for the collection period the HCC and risk scores are being calculated for. |
| `tuva_last_run` |  |  | The date the model was run. |

# HCC Recapture (`hcc_recapture`)

Whether previously documented HCCs were recaptured in the payment year, and recapture rates by payer and month.

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`hcc_recapture.recapture_rates`](#hcc_recapturerecapture_rates) | `payer`, `payment_year` | HCC recapture rates by payment year. |
| [`hcc_recapture.recapture_rates_monthly`](#hcc_recapturerecapture_rates_monthly) | `payer`, `payment_year`, `payment_year_month` | HCC recapture rates by payment year month. |
| [`hcc_recapture.recapture_rates_monthly_ytd`](#hcc_recapturerecapture_rates_monthly_ytd) | `payer`, `payment_year`, `payment_year_month` | HCC recapture rates by payment month year-to-date. |
| [`hcc_recapture.hcc_status`](#hcc_recapturehcc_status) | `person_id`, `payer`, `data_source`, `payment_year`, `recorded_date`, `claim_id`, `hcc_code`, `rendering_npi`, `model_version`, `hcc_hierarchy_group`, `hcc_hierarchy_group_rank` | Combines claims data with HCC gap status. |
| [`hcc_recapture.gap_status`](#hcc_recapturegap_status) | `person_id`, `hcc_code`, `payer`, `model_version`, `payment_year`, `suspect_hcc_flag` | The gap status for each HCC. |

## hcc_recapture.recapture_rates

- **dbt model:** `hcc_recapture__recapture_rates`
- **Grain:** `payer`, `payment_year`
- **Materialization:** table
- **Description:** HCC recapture rates by payment year.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `payer` |  |  | The name of the person (i.e. beneficiary) insurance provider. |
| `payment_year` |  |  | This is the year that the HCC should be coded. Typically the collection year + 1, but for open HCCs it will be the collection year + 2. To illustrate, if we have an HCC claim in 2023, but not in 2024, that means it is open in 2024. The payment year is 2024 + 1 = 2025. So an open HCC from 2023 will have a payment year = 2025. |
| `closed_hccs` |  |  | The number of HCCs that were closed in the payment year. See the definition of closed HCCs in the gap_status field in the gap_status model. |
| `open_hccs` |  |  | The number of HCCs that are open in the payment year. See the definition of open HCCs in the gap_status field in the gap_status model. |
| `total_hccs` |  |  | The total number of HCCs that were open or closed in the payment year. Excludes new and inappropriate for recapture HCCs. |
| `recapture_rate` |  |  | Closed HCCs divided by Total HCCs in the given payment year. |

## hcc_recapture.recapture_rates_monthly

- **dbt model:** `hcc_recapture__recapture_rates_monthly`
- **Grain:** `payer`, `payment_year`, `payment_year_month`
- **Materialization:** table
- **Description:** HCC recapture rates by payment year month.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `payer` |  |  | The name of the person (i.e. beneficiary) insurance provider. |
| `payment_year` |  |  | This is the year that the HCC should be coded. Typically the collection year + 1, but for open HCCs it will be the collection year + 2. To illustrate, if we have an HCC claim in 2023, but not in 2024, that means it is open in 2024. The payment year is 2024 + 1 = 2025. So an open HCC from 2023 will have a payment year = 2025. |
| `payment_year_month` |  |  | The month in the collection year that the HCC was closed. Collection year month is not used since this differs for open vs closed HCCs, but payment year month will be the same for both open and closed HCCs. |
| `closed_hccs` |  |  | The number of HCCs that were closed the payment month. See the definition of closed HCCs in the gap_status field in the gap_status model. |
| `open_hccs` |  |  | The number of HCCs that are open in the payment month. See the definition of open HCCs in the gap_status field in the gap_status model. |
| `total_hccs` |  |  | The total number of HCCs that were open or closed in the payment month. Excludes new and inappropriate for recapture HCCs. |
| `recapture_rate` |  |  | Closed HCCs divided by Total HCCs in the given payment month. |

## hcc_recapture.recapture_rates_monthly_ytd

- **dbt model:** `hcc_recapture__recapture_rates_monthly_ytd`
- **Grain:** `payer`, `payment_year`, `payment_year_month`
- **Materialization:** table
- **Description:** HCC recapture rates by payment month year-to-date.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `payer` |  |  | The name of the person (i.e. beneficiary) insurance provider. |
| `payment_year` |  |  | This is the year that the HCC should be coded. Typically the collection year + 1, but for open HCCs it will be the collection year + 2. To illustrate, if we have an HCC claim in 2023, but not in 2024, that means it is open in 2024. The payment year is 2024 + 1 = 2025. So an open HCC from 2023 will have a payment year = 2025. |
| `payment_year_month` |  |  | The month in the collection year that the HCC was closed. Collection year month is not used since this differs for open vs closed HCCs, but payment year month will be the same for both open and closed HCCs. |
| `monthly_closed_hccs` |  |  | The number of HCCs that were closed the payment month. See the definition of closed HCCs in the gap_status field in the gap_status model. |
| `monthly_open_hccs` |  |  | The number of HCCs that are open in the payment month. See the definition of open HCCs in the gap_status field in the gap_status model. |
| `monthly_total_hccs` |  |  | The total number of HCCs that were open or closed in the payment month. Excludes new and inappropriate for recapture HCCs. |
| `monthly_recapture_rate` |  |  | Closed HCCs divided by Total HCCs in the given payment month. |
| `ytd_closed_hccs` |  |  | The number of HCCs that were closed the payment month + all prior payment months in the payment year. See the definition of closed HCCs in the gap_status field in the gap_status model. |
| `ytd_open_hccs` |  |  | The number of HCCs that are open in the payment month + all prior payment months in the payment year. See the definition of open HCCs in the gap_status field in the gap_status model. |
| `yearly_total_hccs` |  |  | The number of HCCs open and closed in a payment year. |
| `ytd_recapture_rate` |  |  | The running total of closed HCCs divided by total HCCs in a payment year. |

## hcc_recapture.hcc_status

- **dbt model:** `hcc_recapture__hcc_status`
- **Grain:** `person_id`, `payer`, `data_source`, `payment_year`, `recorded_date`, `claim_id`, `hcc_code`, `rendering_npi`, `model_version`, `hcc_hierarchy_group`, `hcc_hierarchy_group_rank`
- **Materialization:** table
- **Description:** Combines claims data with HCC gap status.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | A unique identifier for a person. |
| `payer` |  |  | The name of the person (i.e. beneficiary) insurance provider. |
| `data_source` |  |  | The name of the data source origin. Filled in by the user in the input layer files. |
| `payment_year` |  |  | This is the year that the HCC should be coded. Typically the collection year + 1, but for open HCCs it will be the collection year + 2. To illustrate, if we have an HCC claim in 2023, but not in 2024, that means it is open in 2024. The payment year is 2024 + 1 = 2025. So an open HCC from 2023 will have a payment year = 2025. - name: payment_year |
| `recorded_date` |  |  | The date the claim was originally recorded. Based on admission date, but if null then filled in by claim start date followed by claim end date. |
| `claim_id` |  |  | A unique identifier for the claim. |
| `rendering_npi` |  |  | The National Provider Identifier (NPI) of the physician who rendered services to the beneficiary. |
| `model_version` |  |  | The CMS Medicare risk model version. This includes models such as v22,v24, and v28 which are documented in the yearly rate announcement (e.g. https://www.cms.gov/files/document/2026-announcement.pdf) and on the CMS risk adjustment website: https://www.cms.gov/medicare/payment/medicare-advantage-rates-statistics/risk-adjustment |
| `hcc_code` |  |  | The hierarchical condition category code. |
| `hcc_description` |  |  | A description of the HCC code. |
| `hcc_hierarchy_group` |  |  | The name of the HCC hierarchy group. Determined based off of the CMS risk adjustment website model software. For example, in 2025, the hierarchies were stored in a file called `V28115H1.txt`. The file will end in an H. |
| `hcc_hierarchy_group_rank` |  |  | The rank within the HCC hierarchy group. The lower the number, the higher the rank. When 2 HCCs within the same group are coded within the same collection year, the HCC with the lower rank will be chosen of the two for a given beneficiary. |
| `risk_model_code` |  |  | There are different coefficients depending on a few factors such as dual eligibility, new enrollee, institutional status, etc... This column provides acronyms based off of the CMS risk adjustment SAS code. For example, these can be found in the `C2824T2N_25.csv` file for the 2025 CMS risk adjustment software. |
| `eligible_claim_indicator` |  |  | Whether the claim is eligible for risk adjustment as determined based on a list of accepted CPT/HCPCs codes from CMS. These are available on the CMS risk adjustment website: https://www.cms.gov/medicare/payment/medicare-advantage-rates-statistics/risk-adjustment |
| `eligible_bene` |  |  | A 1 is indicated for a beneficiary who is in the eligibility files. A 0 is indicated if they are not in the eligibility files. |
| `reason` |  |  | Free text reason for the appointment or service. |
| `gap_status` |  |  | definitions for gap_status: - 'closed using higher coefficient hcc in hierarchy group': An HCC in the same group was closed, but its coefficient is greater than the prior year HCC - 'closed': the specific HCC in question has been observed in a risk adjustable claim during the collection year. - 'closed using lower coefficient hcc in hierarchy group': An HCC in the same group was closed, but its coefficient is less than the prior year HCC - 'new': defined as an hcc that has not been coded in the past 2 years - 'open': for gaps and claims, it's a chronic condition appropriate for recapture that has not been documented in current collection year - 'inappropriate for recapture': the specific HCC in question is “Open” and no related/equivalent HCC has been closed, but it is not appropriate for risk adjustment because it’s not a chronic diagnosis. |
| `recapture_flag` |  |  | Whether or not the HCC is recapturable. Includes the following values: - 'Y': condition is a chronic condition appropriate for recapture and has been documented in the prior 2 years - 'N': condition is not a chronic condition appropriate for recapture or has not been documented in the prior 2 years |

## hcc_recapture.gap_status

- **dbt model:** `hcc_recapture__gap_status`
- **Grain:** `person_id`, `hcc_code`, `payer`, `model_version`, `payment_year`, `suspect_hcc_flag`
- **Materialization:** table
- **Description:** The gap status for each HCC.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | A unique identifier for a person. |
| `payer` |  |  | The name of the person (i.e. beneficiary) insurance provider. |
| `hcc_code` |  |  | The hierarchical condition category code. |
| `risk_model_code` |  |  | There are different coefficients depending on a few factors such as dual eligibility, new enrollee, institutional status, etc... This column provides acronyms based off of the CMS risk adjustment SAS code. For example, these can be found in the `C2824T2N_25.csv` file for the 2025 CMS risk adjustment software. |
| `model_version` |  |  | The CMS Medicare risk model version. This includes models such as v22,v24, and v28 which are documented in the yearly rate announcement (e.g. https://www.cms.gov/files/document/2026-announcement.pdf) and on the CMS risk adjustment website: https://www.cms.gov/medicare/payment/medicare-advantage-rates-statistics/risk-adjustment. |
| `payment_year` |  |  | This is the year that the HCC should be coded. Typically the collection year + 1, but for open HCCs it will be the collection year + 2. To illustrate, if we have an HCC claim in 2023, but not in 2024, that means it is open in 2024. The payment year is 2024 + 1 = 2025. So an open HCC from 2023 will have a payment year = 2025. |
| `recapture_flag` |  |  | Whether or not the HCC is recapturable. Includes the following values: - 'Y': condition is a chronic condition appropriate for recapture and has been documented in the prior 2 years - 'N': condition is not a chronic condition appropriate for recapture or has not been documented in the prior 2 years- name: recapture_flag |
| `gap_status` |  |  |  |

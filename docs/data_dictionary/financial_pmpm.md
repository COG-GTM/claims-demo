# Financial PMPM (`financial_pmpm`)

Paid and allowed spend per member per month, broken out by service category. Start with `pmpm_prep` for member-level analysis or `pmpm_payer` / `pmpm_payer_plan` for population trends.

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`financial_pmpm.pmpm_prep`](#financial_pmpmpmpm_prep) | `person_id`, `member_id`, `year_month`, `payer`, `data_source`, `plan` | Computes all the paid and allowed statistics for every person_id and year_month combination. |
| [`financial_pmpm.pmpm_payer_plan`](#financial_pmpmpmpm_payer_plan) | _not declared_ | Computes per member per month statistics for every service category by aggregating across patients from pmpm_prep. This version of the table computes at the payer and plan grain. |
| [`financial_pmpm.pmpm_payer`](#financial_pmpmpmpm_payer) | _not declared_ | Computes per member per month statistics for every service category by aggregating across patients from pmpm_prep. This version of the table computes at the payer grain. |

## financial_pmpm.pmpm_prep

- **dbt model:** `financial_pmpm__pmpm_prep`
- **Grain:** `person_id`, `member_id`, `year_month`, `payer`, `data_source`, `plan`
- **Materialization:** table
- **Description:** Computes all the paid and allowed statistics for every person_id and year_month combination.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique identifier for each patient in the dataset. |
| `member_id` |  |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `year_month` |  |  | Unique year-month of in the dataset computed from eligibility. |
| `payer` |  |  | Name of the payer (i.e. health insurer) providing coverage. |
| `plan` |  |  | Name of the plan (i.e. sub contract) providing coverage. |
| `data_source` |  |  | User-configured field that indicates the data source (e.g. typically named after the payer and state "BCBS Tennessee"). |
| `payer_attributed_provider` |  |  | Unique identifier for the provider assigned to this patient-year_month by the payer. |
| `payer_attributed_provider_practice` |  |  | Name of the practice for the payer attributed provider. |
| `payer_attributed_provider_organization` |  |  | Name of the organization for the payer attributed provider. |
| `payer_attributed_provider_lob` |  |  | Name of the line of business for the payer attributed provider (e.g. medicare, medicaid, commercial). |
| `custom_attributed_provider` |  |  | Unique identifier for the provider assigned to this patient-year_month by the user. |
| `custom_attributed_provider_practice` |  |  | Name of the practice for the attributed provider assigned by the user. |
| `custom_attributed_provider_organization` |  |  | Name of the organization for the attributed provider assigned by the user. |
| `custom_attributed_provider_lob` |  |  | Name of the line of business for the attributed provider assigned by the user (e.g. medicare, medicaid, commercial). |
| `inpatient_paid` |  |  | Total inpatient paid amount per member per month (PMPM). |
| `outpatient_paid` |  |  | Total outpatient paid amount per member per month (PMPM). |
| `office_visit_paid` |  |  | Total office visit paid amount per member per month (PMPM). |
| `ancillary_paid` |  |  | Total ancillary paid amount per member per month (PMPM). |
| `pharmacy_paid` |  |  | Total pharmacy paid amount per member per month (PMPM). |
| `other_paid` |  |  | Total other paid amount per member per month (PMPM). |
| `acute_inpatient_paid` |  |  | Total acute inpatient paid amount per member per month (PMPM). |
| `ambulance_paid` |  |  | Total ambulance paid amount per member per month (PMPM). |
| `ambulatory_surgery_paid` |  |  | Total ambulatory surgery paid amount per member per month (PMPM). |
| `dialysis_paid` |  |  | Total dialysis paid amount per member per month (PMPM). |
| `durable_medical_equipment_paid` |  |  | Total durable medical equipment paid amount per member per month (PMPM). |
| `emergency_department_paid` |  |  | Total emergency department paid amount per member per month (PMPM). |
| `home_health_paid` |  |  | Total home health paid amount per member per month (PMPM). |
| `hospice_paid` |  |  | Total hospice paid amount per member per month (PMPM). |
| `inpatient_psychiatric_paid` |  |  | Total inpatient psychiatric paid amount per member per month (PMPM). |
| `inpatient_rehabilitation_paid` |  |  | Total inpatient rehabilitation paid amount per member per month (PMPM). |
| `lab_paid` |  |  | Total lab paid amount per member per month (PMPM). |
| `office_visit_paid_2` |  |  | Total office visit paid amount per member per month (PMPM). |
| `outpatient_hospital_or_clinic_paid` |  |  | Total outpatient hospital or clinic paid amount per member per month (PMPM). |
| `outpatient_psychiatric_paid` |  |  | Total outpatient psychiatric paid amount per member per month (PMPM). |
| `outpatient_rehabilitation_paid` |  |  | Total outpatient rehabilitation paid amount per member per month (PMPM). |
| `skilled_nursing_paid` |  |  | Total skilled nursing paid amount per member per month (PMPM). |
| `urgent_care_paid` |  |  | Total urgent care paid amount per member per month (PMPM). |
| `inpatient_allowed` |  |  | Total inpatient allowed amount per member per month (PMPM). |
| `outpatient_allowed` |  |  | Total outpatient allowed amount per member per month (PMPM). |
| `office_visit_allowed` |  |  | Total office visit allowed amount per member per month (PMPM). |
| `ancillary_allowed` |  |  | Total ancillary allowed amount per member per month (PMPM). |
| `pharmacy_allowed` |  |  | Total pharmacy allowed amount per member per month (PMPM). |
| `other_allowed` |  |  | Total other allowed amount per member per month (PMPM). |
| `acute_inpatient_allowed` |  |  | Total acute inpatient allowed amount per member per month (PMPM). |
| `ambulance_allowed` |  |  | Total ambulance allowed amount per member per month (PMPM). |
| `ambulatory_surgery_allowed` |  |  | Total ambulatory surgery allowed amount per member per month (PMPM). |
| `dialysis_allowed` |  |  | Total dialysis allowed amount per member per month (PMPM). |
| `durable_medical_equipment_allowed` |  |  | Total durable medical equipment allowed amount per member per month (PMPM). |
| `emergency_department_allowed` |  |  | Total emergency department allowed amount per member per month (PMPM). |
| `home_health_allowed` |  |  | Total home health allowed amount per member per month (PMPM). |
| `hospice_allowed` |  |  | Total hospice allowed amount per member per month (PMPM). |
| `inpatient_psychiatric_allowed` |  |  | Total inpatient psychiatric allowed amount per member per month (PMPM). |
| `inpatient_rehabilitation_allowed` |  |  | Total inpatient rehabilitation allowed amount per member per month (PMPM). |
| `lab_allowed` |  |  | Total lab allowed amount per member per month (PMPM). |
| `office_visit_allowed_2` |  |  | Total office visit allowed amount per member per month (PMPM). |
| `outpatient_hospital_or_clinic_allowed` |  |  | Total outpatient hospital or clinic allowed amount per member per month (PMPM). |
| `outpatient_psychiatric_allowed` |  |  | Total outpatient psychiatric allowed amount per member per month (PMPM). |
| `outpatient_rehabilitation_allowed` |  |  | Total outpatient rehabilitation allowed amount per member per month (PMPM). |
| `skilled_nursing_allowed` |  |  | Total skilled nursing allowed amount per member per month (PMPM). |
| `urgent_care_allowed` |  |  | Total urgent care allowed amount per member per month (PMPM). |
| `total_paid` |  |  | Total paid amount per member per month (PMPM). |
| `medical_paid` |  |  | Total medical paid amount per member per month (PMPM). |
| `total_allowed` |  |  | Total allowed amount per member per month (PMPM). |
| `medical_allowed` |  |  | Total medical allowed amount per member per month (PMPM). |
| `tuva_last_run` |  |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## financial_pmpm.pmpm_payer_plan

- **dbt model:** `financial_pmpm__pmpm_payer_plan`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** Computes per member per month statistics for every service category by aggregating across patients from pmpm_prep. This version of the table computes at the payer and plan grain.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `year_month` |  |  | Unique year-month of in the dataset computed from eligibility. |
| `payer` |  |  | Name of the payer (i.e. health insurer) providing coverage. |
| `plan` |  |  | Name of the plan (i.e. sub contract) providing coverage. |
| `data_source` |  |  | User-configured field that indicates the data source (e.g. typically named after the payer and state "BCBS Tennessee"). |
| `member_months` |  |  | The sum of member months. |
| `total_paid` |  |  | Total paid amount per member per month (PMPM). |
| `medical_paid` |  |  | Total medical paid amount per member per month (PMPM). |
| `inpatient_paid` |  |  | Total inpatient paid amount per member per month (PMPM). |
| `outpatient_paid` |  |  | Total outpatient paid amount per member per month (PMPM). |
| `office_visit_paid` |  |  | Total office visit paid amount per member per month (PMPM). |
| `ancillary_paid` |  |  | Total ancillary paid amount per member per month (PMPM). |
| `pharmacy_paid` |  |  | Total pharmacy paid amount per member per month (PMPM). |
| `other_paid` |  |  | Total other paid amount per member per month (PMPM). |
| `acute_inpatient_paid` |  |  | Total acute inpatient paid amount per member per month (PMPM). |
| `ambulance_paid` |  |  | Total ambulance paid amount per member per month (PMPM). |
| `ambulatory_surgery_paid` |  |  | Total ambulatory surgery paid amount per member per month (PMPM). |
| `dialysis_paid` |  |  | Total dialysis paid amount per member per month (PMPM). |
| `durable_medical_equipment_paid` |  |  | Total durable medical equipment paid amount per member per month (PMPM). |
| `emergency_department_paid` |  |  | Total emergency department paid amount per member per month (PMPM). |
| `home_health_paid` |  |  | Total home health paid amount per member per month (PMPM). |
| `hospice_paid` |  |  | Total hospice paid amount per member per month (PMPM). |
| `inpatient_psychiatric_paid` |  |  | Total inpatient psychiatric paid amount per member per month (PMPM). |
| `inpatient_rehabilitation_paid` |  |  | Total inpatient rehabilitation paid amount per member per month (PMPM). |
| `lab_paid` |  |  | Total lab paid amount per member per month (PMPM). |
| `office_visit_paid_2` |  |  | Total office visit paid amount per member per month (PMPM). |
| `outpatient_hospital_or_clinic_paid` |  |  | Total outpatient hospital or clinic paid amount per member per month (PMPM). |
| `outpatient_psychiatric_paid` |  |  | Total outpatient psychiatric paid amount per member per month (PMPM). |
| `outpatient_rehabilitation_paid` |  |  | Total outpatient rehabilitation paid amount per member per month (PMPM). |
| `skilled_nursing_paid` |  |  | Total skilled nursing paid amount per member per month (PMPM). |
| `urgent_care_paid` |  |  | Total urgent care paid amount per member per month (PMPM). |
| `total_allowed` |  |  | Total allowed amount per member per month (PMPM). |
| `medical_allowed` |  |  | Total medical allowed amount per member per month (PMPM). |
| `inpatient_allowed` |  |  | Total inpatient allowed amount per member per month (PMPM). |
| `outpatient_allowed` |  |  | Total outpatient allowed amount per member per month (PMPM). |
| `office_visit_allowed` |  |  | Total office visit allowed amount per member per month (PMPM). |
| `ancillary_allowed` |  |  | Total ancillary allowed amount per member per month (PMPM). |
| `pharmacy_allowed` |  |  | Total pharmacy allowed amount per member per month (PMPM). |
| `other_allowed` |  |  | Total other allowed amount per member per month (PMPM). |
| `acute_inpatient_allowed` |  |  | Total acute inpatient allowed amount per member per month (PMPM). |
| `ambulance_allowed` |  |  | Total ambulance allowed amount per member per month (PMPM). |
| `ambulatory_surgery_allowed` |  |  | Total ambulatory surgery allowed amount per member per month (PMPM). |
| `dialysis_allowed` |  |  | Total dialysis allowed amount per member per month (PMPM). |
| `durable_medical_equipment_allowed` |  |  | Total durable medical equipment allowed amount per member per month (PMPM). |
| `emergency_department_allowed` |  |  | Total emergency department allowed amount per member per month (PMPM). |
| `home_health_allowed` |  |  | Total home health allowed amount per member per month (PMPM). |
| `hospice_allowed` |  |  | Total hospice allowed amount per member per month (PMPM). |
| `inpatient_psychiatric_allowed` |  |  | Total inpatient psychiatric allowed amount per member per month (PMPM). |
| `inpatient_rehabilitation_allowed` |  |  | Total inpatient rehabilitation allowed amount per member per month (PMPM). |
| `lab_allowed` |  |  | Total lab allowed amount per member per month (PMPM). |
| `office_visit_allowed_2` |  |  | Total office visit allowed amount per member per month (PMPM). |
| `outpatient_hospital_or_clinic_allowed` |  |  | Total outpatient hospital or clinic allowed amount per member per month (PMPM). |
| `outpatient_psychiatric_allowed` |  |  | Total outpatient psychiatric allowed amount per member per month (PMPM). |
| `outpatient_rehabilitation_allowed` |  |  | Total outpatient rehabilitation allowed amount per member per month (PMPM). |
| `skilled_nursing_allowed` |  |  | Total skilled nursing allowed amount per member per month (PMPM). |
| `urgent_care_allowed` |  |  | Total urgent care allowed amount per member per month (PMPM). |
| `tuva_last_run` |  |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## financial_pmpm.pmpm_payer

- **dbt model:** `financial_pmpm__pmpm_payer`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** Computes per member per month statistics for every service category by aggregating across patients from pmpm_prep. This version of the table computes at the payer grain.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `year_month` |  |  | Unique year-month of in the dataset computed from eligibility. |
| `payer` |  |  | Name of the payer (i.e. health insurer) providing coverage. |
| `data_source` |  |  | User-configured field that indicates the data source (e.g. typically named after the payer and state "BCBS Tennessee"). |
| `member_months` |  |  | The sum of member months. |
| `total_paid` |  |  | Total paid amount per member per month (PMPM). |
| `medical_paid` |  |  | Total medical paid amount per member per month (PMPM). |
| `inpatient_paid` |  |  | Total inpatient paid amount per member per month (PMPM). |
| `outpatient_paid` |  |  | Total outpatient paid amount per member per month (PMPM). |
| `office_visit_paid` |  |  | Total office visit paid amount per member per month (PMPM). |
| `ancillary_paid` |  |  | Total ancillary paid amount per member per month (PMPM). |
| `pharmacy_paid` |  |  | Total pharmacy paid amount per member per month (PMPM). |
| `other_paid` |  |  | Total other paid amount per member per month (PMPM). |
| `acute_inpatient_paid` |  |  | Total acute inpatient paid amount per member per month (PMPM). |
| `ambulance_paid` |  |  | Total ambulance paid amount per member per month (PMPM). |
| `ambulatory_surgery_paid` |  |  | Total ambulatory surgery paid amount per member per month (PMPM). |
| `dialysis_paid` |  |  | Total dialysis paid amount per member per month (PMPM). |
| `durable_medical_equipment_paid` |  |  | Total durable medical equipment paid amount per member per month (PMPM). |
| `emergency_department_paid` |  |  | Total emergency department paid amount per member per month (PMPM). |
| `home_health_paid` |  |  | Total home health paid amount per member per month (PMPM). |
| `hospice_paid` |  |  | Total hospice paid amount per member per month (PMPM). |
| `inpatient_psychiatric_paid` |  |  | Total inpatient psychiatric paid amount per member per month (PMPM). |
| `inpatient_rehabilitation_paid` |  |  | Total inpatient rehabilitation paid amount per member per month (PMPM). |
| `lab_paid` |  |  | Total lab paid amount per member per month (PMPM). |
| `office_visit_paid_2` |  |  | Total office visit paid amount per member per month (PMPM). |
| `outpatient_hospital_or_clinic_paid` |  |  | Total outpatient hospital or clinic paid amount per member per month (PMPM). |
| `outpatient_psychiatric_paid` |  |  | Total outpatient psychiatric paid amount per member per month (PMPM). |
| `outpatient_rehabilitation_paid` |  |  | Total outpatient rehabilitation paid amount per member per month (PMPM). |
| `skilled_nursing_paid` |  |  | Total skilled nursing paid amount per member per month (PMPM). |
| `urgent_care_paid` |  |  | Total urgent care paid amount per member per month (PMPM). |
| `total_allowed` |  |  | Total allowed amount per member per month (PMPM). |
| `medical_allowed` |  |  | Total medical allowed amount per member per month (PMPM). |
| `inpatient_allowed` |  |  | Total inpatient allowed amount per member per month (PMPM). |
| `outpatient_allowed` |  |  | Total outpatient allowed amount per member per month (PMPM). |
| `office_visit_allowed` |  |  | Total office visit allowed amount per member per month (PMPM). |
| `ancillary_allowed` |  |  | Total ancillary allowed amount per member per month (PMPM). |
| `pharmacy_allowed` |  |  | Total pharmacy allowed amount per member per month (PMPM). |
| `other_allowed` |  |  | Total other allowed amount per member per month (PMPM). |
| `acute_inpatient_allowed` |  |  | Total acute inpatient allowed amount per member per month (PMPM). |
| `ambulance_allowed` |  |  | Total ambulance allowed amount per member per month (PMPM). |
| `ambulatory_surgery_allowed` |  |  | Total ambulatory surgery allowed amount per member per month (PMPM). |
| `dialysis_allowed` |  |  | Total dialysis allowed amount per member per month (PMPM). |
| `durable_medical_equipment_allowed` |  |  | Total durable medical equipment allowed amount per member per month (PMPM). |
| `emergency_department_allowed` |  |  | Total emergency department allowed amount per member per month (PMPM). |
| `home_health_allowed` |  |  | Total home health allowed amount per member per month (PMPM). |
| `hospice_allowed` |  |  | Total hospice allowed amount per member per month (PMPM). |
| `inpatient_psychiatric_allowed` |  |  | Total inpatient psychiatric allowed amount per member per month (PMPM). |
| `inpatient_rehabilitation_allowed` |  |  | Total inpatient rehabilitation allowed amount per member per month (PMPM). |
| `lab_allowed` |  |  | Total lab allowed amount per member per month (PMPM). |
| `office_visit_allowed_2` |  |  | Total office visit allowed amount per member per month (PMPM). |
| `outpatient_hospital_or_clinic_allowed` |  |  | Total outpatient hospital or clinic allowed amount per member per month (PMPM). |
| `outpatient_psychiatric_allowed` |  |  | Total outpatient psychiatric allowed amount per member per month (PMPM). |
| `outpatient_rehabilitation_allowed` |  |  | Total outpatient rehabilitation allowed amount per member per month (PMPM). |
| `skilled_nursing_allowed` |  |  | Total skilled nursing allowed amount per member per month (PMPM). |
| `urgent_care_allowed` |  |  | Total urgent care allowed amount per member per month (PMPM). |
| `tuva_last_run` |  |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

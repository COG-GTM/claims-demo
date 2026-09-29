# HCC Suspecting (`hcc_suspecting`)

Suspected (not yet coded) HCCs per member with the evidence that triggered the suspicion.

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`hcc_suspecting.list`](#hcc_suspectinglist) | _not declared_ | This final model displays the list of suspecting conditions per patient, data_source, hcc, and diagnosis code with the reason and contributing factors. It is filtered by current_year_billed. |
| [`hcc_suspecting.list_all`](#hcc_suspectinglist_all) | _not declared_ | This final model displays the list of suspecting conditions per patient, data_source, hcc, and diagnosis code with the reason and contributing factors. |
| [`hcc_suspecting.list_rollup`](#hcc_suspectinglist_rollup) | _not declared_ | This final model displays the list of suspecting conditions per patient and hcc with the latest contributing factor rolled up. |
| [`hcc_suspecting.summary`](#hcc_suspectingsummary) | _not declared_ | This final model displays a rollup of suspecting conditions per patient. |

## hcc_suspecting.list

- **dbt model:** `hcc_suspecting__list`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This final model displays the list of suspecting conditions per patient, data_source, hcc, and diagnosis code with the reason and contributing factors. It is filtered by current_year_billed.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `data_source` |  |  | User-configured field that indicates the data source (e.g. typically named after the payer and state "BCBS Tennessee"). |
| `hcc_code` |  |  | HCC code from the latest CMS HCC model available in the mart. |
| `hcc_description` |  |  | HCC description from the latest CMS HCC model available in the mart. |
| `reason` |  |  | Standardized reason for the suspecting condition. |
| `contributing_factor` |  |  | Description of the contributing factor(s) for the suspecting condition. |
| `suspect_date` |  |  | Date when the suspecting condition, observation, result, etc. was recorded or billed. |
| `tuva_last_run` |  |  | The date the model was run. |

## hcc_suspecting.list_all

- **dbt model:** `hcc_suspecting__list_all`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This final model displays the list of suspecting conditions per patient, data_source, hcc, and diagnosis code with the reason and contributing factors.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `payer` |  |  | Name of the payer. |
| `data_source` |  |  | User-configured field that indicates the data source (e.g. typically named after the payer and state "BCBS Tennessee"). |
| `model_version` |  |  | The CMS model version of the HCC code. |
| `hcc_code` |  |  | HCC code from the latest CMS HCC model available in the mart. |
| `hcc_description` |  |  | HCC description from the latest CMS HCC model available in the mart. |
| `reason` |  |  | Standardized reason for the suspecting condition. |
| `contributing_factor` |  |  | Description of the contributing factor(s) for the suspecting condition. |
| `suspect_date` |  |  | Date when the suspecting condition, observation, result, etc. was recorded or billed. |
| `current_year_billed` |  |  | Flag indicating that the HCC has been billed during the payment year. |
| `tuva_last_run` |  |  | The date the model was run. |

## hcc_suspecting.list_rollup

- **dbt model:** `hcc_suspecting__list_rollup`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This final model displays the list of suspecting conditions per patient and hcc with the latest contributing factor rolled up.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `hcc_code` |  |  | HCC code from the latest CMS HCC model available in the mart. |
| `hcc_description` |  |  | HCC description from the latest CMS HCC model available in the mart. |
| `reason` |  |  | Standardized reason for the suspecting condition. |
| `contributing_factor` |  |  | Description of the contributing factor(s) for the suspecting condition. |
| `latest_suspect_date` |  |  | Latest date when the suspecting condition, observation, result, etc. was recorded or billed. |
| `tuva_last_run` |  |  | The date the model was run. |

## hcc_suspecting.summary

- **dbt model:** `hcc_suspecting__summary`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This final model displays a rollup of suspecting conditions per patient.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | Unique ID for the patient. |
| `patient_sex` |  |  | The gender of the patient. |
| `patient_birth_date` |  |  | The birth date of the patient. |
| `patient_age` |  |  | The patient's current age. |
| `suspecting_gaps` |  |  | Count of suspecting conditions. |
| `tuva_last_run` |  |  | The date the model was run. |

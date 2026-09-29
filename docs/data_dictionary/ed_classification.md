# ED Classification (`ed_classification`)

Emergency department visits classified with the NYU/Billings algorithm (e.g. non-emergent, emergent/primary-care treatable).

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`ed_classification.summary`](#ed_classificationsummary) | _not declared_ | ED Classification as a cube that can be summarized |

## ed_classification.summary

- **dbt model:** `ed_classification__summary`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** ED Classification as a cube that can be summarized

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `encounter_id` |  |  | Unique identifier for the emergency_department encounter. |
| `ed_classification_description` |  |  | ED classification category. |
| `ed_classification_order` |  |  | The order of the classification. |
| `person_id` |  |  | Unique identifier for each patient in the dataset. |
| `encounter_end_date` |  |  | Date when the patient was discharged. |
| `year_month` |  |  | Year and month of the encounter end date. |
| `primary_diagnosis_code` |  |  | Primary diagnosis code for the encounter. If from claims the primary diagnosis code comes from the institutional claim. |
| `primary_diagnosis_description` |  |  | Description of the primary diagnosis code. |
| `paid_amount` |  |  | The total paid amount across all claims for the encounter. |
| `allowed_amount` |  |  | The total allowed amount across all claims for the encounter. |
| `charge_amount` |  |  | The total charge amount across all claims for the encounter. |
| `facility_id` |  |  | The ID for the facility where the encounter occurred. |
| `facility_name` |  |  | The name of the facility. |
| `facility_state` |  |  | The state of the facility. |
| `facility_city` |  |  | The city of the facility. |
| `facility_zip_code` |  |  | The zip code of the facility. |
| `patient_sex` |  |  | The sex of the patient. |
| `patient_age` |  |  | The age of the patient at the time of the encounter. |
| `patient_zip_code` |  |  | The zip code for the patient. |
| `patient_latitude` |  |  | The latitude for the patient. |
| `patient_longitude` |  |  | The longitude for the patient. |
| `patient_race` |  |  | The race of the patient. |

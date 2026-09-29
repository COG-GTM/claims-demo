# Core (`core`)

The conformed, cleaned data model every other mart is built from. Claims and clinical data land here in a common shape: `patient`, `practitioner` and `location` are the shared dimensions; claims, encounters, conditions, procedures, and clinical events are facts; `member_months` is the enrollment spine used as the denominator for PMPM and utilization rates.

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`core.appointment`](#coreappointment) | `appointment_id` | The core appointment table contains information related to appointments at a healthcare facility. This table may include canceled, completed, or scheduled events. |
| [`core.condition`](#corecondition) | `condition_id` | The core condition table contains information related to medical conditions patients have, including problems, admitting diagnosis codes, and billable diagnosis codes. |
| [`core.eligibility`](#coreeligibility) | `eligibility_id`, `data_source` | The eligibility table contains information on patient health plan and supplemental insurance eligibility. |
| [`core.encounter`](#coreencounter) | `encounter_id` | The encounter table contains information about patients visits (i.e. encounters). This includes acute inpatient, emergency department, office visits, SNF stays, etc. |
| [`core.immunization`](#coreimmunization) | `immunization_id` | The immunization table contains information on immunizations administered to patients, including the vaccine code, description, and administration date. |
| [`core.lab_result`](#corelab_result) | `lab_result_id` | The lab result table contains information about lab test results, including the LOINC code and description, units, reference range, and result. |
| [`core.location`](#corelocation) | `location_id` | The location table contains information on practice and facility locations where patients receive medical care. |
| [`core.medical_claim`](#coremedical_claim) | `medical_claim_id` | The medical claim table contains information on services rendered to patients and billed by the provider to the insurer as claims. |
| [`core.medication`](#coremedication) | `medication_id` | The medication table contains information on medications ordered and/or administered during a patient encounter. |
| [`core.member_months`](#coremember_months) | `member_month_key`, `data_source` | The core member months tables has one record per member per month in the eligibility source data. Members without claims are included in this data table. |
| [`core.observation`](#coreobservation) | `observation_id` | The observation table contains information on measurements other than lab tests e.g. blood pressure, height, and weight. |
| [`core.patient`](#corepatient) | `person_id` | The patient table contains demographic and geographic information on patients. |
| [`core.person_id_crosswalk`](#coreperson_id_crosswalk) | `person_id`, `patient_id`, `member_id`, `payer`, `plan`, `data_source` | The person id crosswalk table contains all source patient identifiers from the input layer eligibility (claims) and patient (clinical). |
| [`core.pharmacy_claim`](#corepharmacy_claim) | `pharmacy_claim_id` | The pharmacy claim table contains information on prescription drugs that were filled and billed to the insurer. |
| [`core.practitioner`](#corepractitioner) | `practitioner_id` | The practitioner table contains information on the providers in the dataset e.g. physicians, physicians assistants, etc. |
| [`core.procedure`](#coreprocedure) | `procedure_id` | The procedure table contains information on procedures that were performed on patients in the dataset. |

## core.appointment

- **dbt model:** `core__appointment`
- **Grain:** `appointment_id`
- **Materialization:** table
- **Description:** The core appointment table contains information related to appointments at a healthcare facility. This table may include canceled, completed, or scheduled events.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `appointment_id` | varchar | unique | Unique identifier for the appointment. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `source_appointment_type_code` | varchar |  | Appointment type code from the source. |
| `source_appointment_type_description` | varchar |  | Appointment type description from the source. |
| `normalized_appointment_type_code` | varchar |  | Normalized appointment type code. |
| `normalized_appointment_type_description` | varchar |  | Normalized appointment type description. |
| `start_datetime` | timestamp |  | The start date/time of the appointment or service. |
| `end_datetime` | timestamp |  | The end date/time of the appointment or service. |
| `duration` | number |  | Number of minutes that the appointment or service is to take. |
| `location_id` | varchar |  | Unique identifier for each location. |
| `practitioner_id` | varchar |  | Unique identifier for the practitioner on record (e.g., ordered medication, performed the procedure, etc). |
| `source_status` | varchar |  | Status of the appointment from the source system. |
| `normalized_status` | varchar |  | The normalized status of the appointment. |
| `appointment_specialty` | varchar |  | Specialty of a practitioner that would be required to perform the service requested in this appointment. |
| `reason` | varchar |  | Free text reason for the appointment or service. |
| `source_reason_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_reason_code` | varchar |  | The code in the source system for the appointment reason (e.g., ICD-10 code). |
| `source_reason_description` | varchar |  | Description of the source code for the appointment reason in the source system (e.g., ICD-10 description). |
| `normalized_reason_code_type` | varchar |  | The normalized type of code. |
| `normalized_reason_code` | varchar |  | The normalized code for the appointment reason (e.g., ICD-10 code). |
| `normalized_reason_description` | varchar |  | Normalized description of the code for the appointment reason (e.g., ICD-10 description). |
| `cancellation_reason` | varchar |  | Free text reason why the appointment was cancelled. |
| `source_cancellation_reason_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_cancellation_reason_code` | varchar |  | The code in the source system for the cancellation reason. |
| `source_cancellation_reason_description` | varchar |  | Description of the source code for the cancellation reason in the source system. |
| `normalized_cancellation_reason_code_type` | varchar |  | The normalized type of code. |
| `normalized_cancellation_reason_code` | varchar |  | The normalized code for the cancellation reason. |
| `normalized_cancellation_reason_description` | varchar |  | Normalized description of the code for the cancellation reason. |
| `mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.condition

- **dbt model:** `core__condition`
- **Grain:** `condition_id`
- **Materialization:** table
- **Description:** The core condition table contains information related to medical conditions patients have, including problems, admitting diagnosis codes, and billable diagnosis codes.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `condition_id` | varchar | unique | Unique identifier for each condition in the table. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `claim_id` | varchar |  | Unique identifier for a claim. Each claim represents a distinct healthcare service or set of services provided to a patient. |
| `recorded_date` | date |  | Date when the condition was recorded. |
| `onset_date` | date |  | Date when the condition first occurred. |
| `resolved_date` | date |  | Date when the condition was resolved. |
| `status` | varchar |  | Status of the record (e.g., condition, test, etc). |
| `condition_type` | varchar |  | The type of condition i.e. problem, admitting, or billing. |
| `source_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_code` | varchar |  | The code in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_description` | varchar |  | Description of the source code in the source system. |
| `normalized_code_type` | varchar |  | The normalized type of code. |
| `normalized_code` | varchar |  | The normalized code. |
| `normalized_description` | varchar |  | Normalized description of the code. |
| `mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `condition_rank` | number |  | The numerical ranking of the condition. For conditions derived from medical claims, condition_rank is set from the diagnosis code position on the claim, so diagnosis_code_1 becomes condition_rank = 1, diagnosis_code_2 becomes condition_rank = 2, and so on through diagnosis_code_25. For conditions sourced from the input layer condition table, this field is passed through without transformation from the mapped input value. A condition_rank of 1 indicates a primary diagnosis code, and any condition_rank greater than 1 indicates a secondary diagnosis code. |
| `present_on_admit_code` | varchar |  | The present_on_admit_code related to the condition. |
| `present_on_admit_description` | varchar |  | The description of the present_on_admit_code for the condition. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.eligibility

- **dbt model:** `core__eligibility`
- **Grain:** `eligibility_id`, `data_source`
- **Materialization:** table
- **Description:** The eligibility table contains information on patient health plan and supplemental insurance eligibility.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `eligibility_id` | varchar | not null | Unique identifier for each eligibility row in the table. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `subscriber_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. |
| `birth_date` | date |  | The birth date of the patient. |
| `death_date` | date |  | Date the patient died if there is one. |
| `enrollment_start_date` | date |  | Date the patient's insurance eligibility began. |
| `enrollment_end_date` | date |  | Date the patient's insurance eligibility ended. |
| `payer` | varchar |  | Name of the payer (i.e. health insurer) providing coverage. |
| `payer_type` | varchar |  | Type of payer (e.g. commercial, medicare, medicaid, etc.). |
| `plan` | varchar |  | Name of the plan (i.e. sub contract) providing coverage. |
| `original_reason_entitlement_code` | varchar |  | Original reason for Medicare entitlement code. |
| `dual_status_code` | varchar |  | Indicates whether the patient is dually eligible for Medicare and Medicaid. |
| `medicare_status_code` | varchar |  | Indicates how the patient became eligible for Medicare. |
| `enrollment_status` | varchar |  | Indicates the type of enrollment status for a beneficiary. Used for determining risk score coefficients. If unsure of the enrollment status, leave this field null so Tuva can determine the enrollment status based on the beneficiary information. |
| `fips_state_code` | varchar |  | FIPS code for the state the patient lives in (most recent known address). |
| `normalized_state_name` | varchar |  | State for the patient (most recent known address). |
| `fips_state_abbreviation` | varchar |  | Abbreviated form of the state for the patient (most recient known address). |
| `subscriber_relation` | varchar |  | The patient's relationship to the subscriber (e.g., self, spouse, child). |
| `group_id` | varchar |  | The group id which multiple members are enrolled for health coverage. |
| `group_name` | varchar |  | The group name under which multiple members are enrolled for health coverage. |
| `data_source` | varchar | not null | User-configured field that indicates the data source. |
| `file_date` | timestamp |  | The date associated with the claims file, typically reflecting the reporting period of the claims data. |
| `ingest_datetime` | timestamp |  | The date and time the source file was ingested into the data warehouse or landed in cloud storage. |
| `tuva_last_run` | varchar |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.encounter

- **dbt model:** `core__encounter`
- **Grain:** `encounter_id`
- **Materialization:** table
- **Description:** The encounter table contains information about patients visits (i.e. encounters). This includes acute inpatient, emergency department, office visits, SNF stays, etc.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `_dbt_source_relation` | varchar |  | dbt utils metadata column to indicate the source table from unioning tables together. |
| `encounter_id` | varchar | unique | Unique identifier for each encounter in the dataset. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `patient_data_source_id` |  |  | Identifier for the source system from which patient data originated. |
| `encounter_type` | varchar |  | Indicates the type of encounter e.g. acute inpatient, emergency department, etc. |
| `encounter_group` | varchar |  | Categorization of the encounter into groups based on predefined criteria. |
| `encounter_start_date` | date |  | Date when the encounter started. |
| `encounter_end_date` | date |  | Date when the encounter ended. |
| `length_of_stay` | number |  | Length of the encounter calculated as encounter_end_date - encounter_start_date. |
| `admit_source_code` | varchar |  | Indicates where the patient was before the healthcare encounter (inpatient claims only). |
| `admit_source_description` | varchar |  | Description of the admit_source_code for the encounter. |
| `admit_type_code` | varchar |  | Indicates the type of admission (inpatient claims only). |
| `admit_type_description` | varchar |  | Description of the admit_type_code for the encounter. |
| `discharge_disposition_code` | varchar |  | Indicates the type of setting the patient was discharged to (institutional inpatient claims only). |
| `discharge_disposition_description` | varchar |  | Description of the discharge_disposition_code for the encounter. |
| `attending_provider_id` | varchar |  | ID for the attending provider on the encounter. |
| `attending_provider_name` | varchar |  | Name of the attending provider on the encounter. |
| `facility_id` | varchar |  | Facility ID for the claim (typically represents the facility where services were performed). |
| `facility_name` | varchar |  | Facility name. |
| `facility_type` | varchar |  | The type of facility e.g. acute care hospital. |
| `observation_flag` | number |  | Indicates whether the encounter was marked as an observation stay (1 for yes, 0 for no). |
| `lab_flag` | number |  | Indicates whether lab services were utilized during the encounter (1 for yes, 0 for no). |
| `dme_flag` | number |  | Indicates whether durable medical equipment (DME) was used during the encounter (1 for yes, 0 for no). |
| `ambulance_flag` | number |  | Indicates whether ambulance services were utilized during the encounter (1 for yes, 0 for no). |
| `pharmacy_flag` | number |  | Indicates whether pharmacy services were utilized during the encounter (1 for yes, 0 for no). |
| `ed_flag` | number |  | Indicates whether the encounter involved an emergency department visit (1 for yes, 0 for no). |
| `delivery_flag` | number |  | Indicates whether the encounter involved a delivery (1 for yes, 0 for no). |
| `delivery_type` | varchar |  | Type of delivery that occurred during the encounter, if applicable. |
| `newborn_flag` | number |  | Indicates whether the encounter was for a newborn (1 for yes, 0 for no). |
| `nicu_flag` | number |  | Indicates whether the newborn was admitted to the Neonatal Intensive Care Unit (NICU) during the encounter (1 for yes, 0 for no). |
| `snf_part_b_flag` | number |  | Indicates whether the inpatient medical service for Medicare covers under Part B or not. (1 for yes and 0 for no) |
| `primary_diagnosis_code_type` | varchar |  | The type of condition code reported in the source system e.g. ICD-10-CM. |
| `primary_diagnosis_code` | varchar |  | Primary diagnosis code for the encounter. If from claims the primary diagnosis code comes from the institutional claim. |
| `primary_diagnosis_description` | varchar |  | Description of the primary diagnosis code. |
| `drg_code_type` | varchar |  | The DRG system used for the claim. |
| `drg_code` | varchar |  | The DRG code on the claim. |
| `drg_description` | varchar |  | The description for the DRG code used on the claim. |
| `paid_amount` | number |  | The total amount paid by the insurer. |
| `allowed_amount` | number |  | The total amount allowed (includes amount paid by the insurer and patient). |
| `charge_amount` | number |  | The total amount charged for the services provided, before any adjustments or payments. This is typically in US dollars. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `claim_count` | number |  | The number of claims associated with the encounter or record. |
| `inst_claim_count` | number |  | Number of institutional claims generated from the encounter. |
| `prof_claim_count` | number |  | Number of professional claims generated from the encounter. |
| `source_model` | varchar |  | Indicates the DBT source relation name from which data is derived. |
| `encounter_source_type` | varchar |  | Indicates whether the encounter is from a claims or clinical data source |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.immunization

- **dbt model:** `core__immunization`
- **Grain:** `immunization_id`
- **Materialization:** table
- **Description:** The immunization table contains information on immunizations administered to patients, including the vaccine code, description, and administration date.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `immunization_id` | varchar | unique | Unique identifier for each immunization. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `source_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_code` | varchar |  | The code in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_description` | varchar |  | Description of the source code in the source system. |
| `normalized_code_type` | varchar |  | The normalized type of code. |
| `normalized_code` | varchar |  | The normalized code. |
| `normalized_description` | varchar |  | Normalized description of the code. |
| `mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `status` | varchar |  | Status of the record (e.g., condition, test, etc). |
| `status_reason` | varchar |  | Indicates reason the event was not performed. (e.g., condition, test, immunization etc). |
| `occurrence_date` | date |  | Date the event occured or was to be occured. |
| `source_dose` | varchar |  | The quantity of vaccine product that was administered. |
| `normalized_dose` | varchar |  | Normalized quantity of vaccine product that was administered. |
| `lot_number` | varchar |  | Lot number of the vaccine product. |
| `body_site` | varchar |  | The body site where the vaccine was administered. |
| `route` | varchar |  | The route used to administer the medication and/or vaccine. |
| `location_id` | varchar |  | Unique identifier for each location. |
| `practitioner_id` | varchar |  | Unique identifier for the practitioner on record (e.g., ordered medication, performed the procedure, etc). |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.lab_result

- **dbt model:** `core__lab_result`
- **Grain:** `lab_result_id`
- **Materialization:** table
- **Description:** The lab result table contains information about lab test results, including the LOINC code and description, units, reference range, and result.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `lab_result_id` | varchar | unique | Unique identifier for each lab result. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `accession_number` | varchar |  | The lab order number from the source system. |
| `source_order_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_order_code` | varchar |  | The code in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_order_description` | varchar |  | Description of the source code in the source system. |
| `source_component_type` | varchar |  | The type of code for the component reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_component_code` | varchar |  | The code for the component in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_component_description` | varchar |  | Description of the source code for the component in the source system. |
| `normalized_order_type` | varchar |  | The normalized type of code. |
| `normalized_order_code` | varchar |  | The normalized code. |
| `normalized_order_description` | varchar |  | Normalized description of the code. |
| `mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `normalized_component_type` | varchar |  | The normalized type of code for the component. |
| `normalized_component_code` | varchar |  | The normalized code for the component. |
| `normalized_component_description` | varchar |  | Normalized description of the code for the component. |
| `status` | varchar |  | Status of the record (e.g., condition, test, etc). |
| `result` | varchar |  | The result of the record (e.g., lab test, observation, etc). |
| `result_datetime` | timestamp |  | Datetime of the test result. |
| `collection_datetime` | timestamp |  | Datetime the specimen was collected. |
| `source_units` | varchar |  | Source units of the lab test. |
| `normalized_units` | varchar |  | Normalized units of the lab test. |
| `source_reference_range_low` | varchar |  | The low end of the reference range from the source system. |
| `source_reference_range_high` | varchar |  | The high end of the reference range from the source system. |
| `normalized_reference_range_low` | varchar |  | The normalized low end of the reference range. |
| `normalized_reference_range_high` | varchar |  | The normalized high end of the reference range. |
| `source_abnormal_flag` | varchar |  | Indicates whether the result is abnormal or normal. |
| `normalized_abnormal_flag` | varchar |  | Normalized abnormal flag. |
| `specimen` | varchar |  | The type of specimen e.g. blood, plasma, urine. |
| `ordering_practitioner_id` | varchar |  | Unique identifier for the practitioner who ordered the lab test. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.location

- **dbt model:** `core__location`
- **Grain:** `location_id`
- **Materialization:** table
- **Description:** The location table contains information on practice and facility locations where patients receive medical care.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `location_id` | varchar | unique | Unique identifier for each location. |
| `npi` | varchar |  | The national provider identifier associated with the record e.g. facility_npi, provider_npi |
| `name` | varchar |  | The name of the location. |
| `facility_type` | varchar |  | The type of facility e.g. acute care hospital. |
| `parent_organization` | varchar |  | The parent organization associated with the facility. |
| `address` | varchar |  | The street address of the record (e.g., facility location, patient, etc). |
| `city` | varchar |  | The city of the record (e.g., facility location, patient, etc). |
| `state` | varchar |  | The state of the record (e.g., facility location, patient, etc). |
| `zip_code` | varchar |  | The zip code of the record (e.g., facility location, patient, etc). |
| `latitude` | float |  | The latitude of the record (e.g., facility location, patient, etc). |
| `longitude` | float |  | The longitude of the record (e.g., facility location, patient, etc). |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.medical_claim

- **dbt model:** `core__medical_claim`
- **Grain:** `medical_claim_id`
- **Materialization:** table
- **Description:** The medical claim table contains information on services rendered to patients and billed by the provider to the insurer as claims.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `medical_claim_id` | varchar | unique, not null | Unique identifier for each row in the table. |
| `claim_id` | varchar | not null | Unique identifier for a claim. Each claim represents a distinct healthcare service or set of services provided to a patient. |
| `claim_line_number` | number | not null | Indicates the line number for the particular line of the claim. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `encounter_type` | varchar |  | Indicates the type of encounter e.g. acute inpatient, emergency department, etc. |
| `encounter_group` | varchar |  | Categorization of the encounter into groups based on predefined criteria. |
| `claim_type` | varchar |  | Indicates whether the claim is professional (CMS-1500), institutional (UB-04), dental, or vision. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `payer` | varchar |  | Name of the payer (i.e. health insurer) providing coverage. |
| `plan` | varchar |  | Name of the plan (i.e. sub contract) providing coverage. |
| `claim_start_date` | date |  | The date when the healthcare service was provided. Format: YYYY-MM-DD. |
| `claim_end_date` | date |  | End date for the claim. |
| `claim_line_start_date` | date |  | Start date for the claim line. |
| `claim_line_end_date` | date |  | End date for the claim line. |
| `admission_date` | date |  | Admission date for the claim (inpatient claims only). |
| `discharge_date` | date |  | Discharge date for the claim (inpatient claims only). |
| `service_category_1` | varchar |  | The broader service category this claim belongs to. |
| `service_category_2` | varchar |  | The more specific service category this claim belongs to. |
| `service_category_3` | varchar |  | The most specific service category this claim belongs to. |
| `admit_source_code` | varchar |  | Indicates where the patient was before the healthcare encounter (inpatient claims only). |
| `admit_source_description` | varchar |  | Description of the admit_source_code for the encounter. |
| `admit_type_code` | varchar |  | Indicates the type of admission (inpatient claims only). |
| `admit_type_description` | varchar |  | Description of the admit_type_code for the encounter. |
| `discharge_disposition_code` | varchar |  | Indicates the type of setting the patient was discharged to (institutional inpatient claims only). |
| `discharge_disposition_description` | varchar |  | Description of the discharge_disposition_code for the encounter. |
| `place_of_service_code` | varchar |  | Place of service for the claim (professional claims only). |
| `place_of_service_description` | varchar |  | Place of service description. |
| `bill_type_code` | varchar |  | Bill type code for the claim (institutional claims only). |
| `bill_type_description` | varchar |  | Bill type description. |
| `drg_code_type` | varchar |  | The DRG system used for the claim. |
| `drg_code` | varchar |  | The DRG code on the claim. |
| `drg_description` | varchar |  | The description for the DRG code used on the claim. |
| `revenue_center_code` | varchar |  | Revenue center code for the claim line (institutional only and typically multiple codes per claim). |
| `revenue_center_description` | varchar |  | Revenue center description. |
| `service_unit_quantity` | number |  | The number of units for the particular revenue center code. |
| `hcpcs_code` | varchar |  | The CPT or HCPCS code representing the procedure or service provided. These codes are used to describe medical, surgical, and diagnostic services. |
| `hcpcs_modifier_1` | varchar |  | 1st modifier for HCPCS code. |
| `hcpcs_modifier_2` | varchar |  | 2nd modifier for HCPCS code. |
| `hcpcs_modifier_3` | varchar |  | 3rd modifier for HCPCS code. |
| `hcpcs_modifier_4` | varchar |  | 4th modifier for HCPCS code. |
| `hcpcs_modifier_5` | varchar |  | 5th modifier for HCPCS code. |
| `rendering_id` | varchar |  | Rendering ID for the claim (typically represents the physician or entity providing services). |
| `rendering_tin` | varchar |  | Rendering provider tax identification number (TIN). |
| `rendering_name` | varchar |  | Rendering provider name. |
| `billing_id` | varchar |  | Billing ID for the claim (typically represents organization billing the claim). |
| `billing_tin` | varchar |  | Billing provider tax identification number (TIN). |
| `billing_name` | varchar |  | Billing provider name. |
| `facility_id` | varchar |  | Facility ID for the claim (typically represents the facility where services were performed). |
| `facility_name` | varchar |  | Facility name. |
| `paid_date` | date |  | The date the claim was paid. |
| `paid_amount` | number |  | The total amount paid by the insurer. |
| `allowed_amount` | number |  | The total amount allowed (includes amount paid by the insurer and patient). |
| `charge_amount` | number |  | The total amount charged for the services provided, before any adjustments or payments. This is typically in US dollars. |
| `coinsurance_amount` | number |  | The total coinsurance charged on the claim by the provider. |
| `copayment_amount` | number |  | The total copayment charged on the claim by the provider. |
| `deductible_amount` | number |  | The total deductible charged on the claim by the provider. |
| `total_cost_amount` | number |  | The total amount paid on the claim by different parties. |
| `in_network_flag` | number |  | Flag indicating if the claim was in or out of network. |
| `enrollment_flag` | number |  | Flag indicating if the claim has corresponding enrollment during the same time period the service occurred. |
| `member_month_key` | number |  | The unique combination of person_id, year_month, payer, plan, and data source. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `file_date` | timestamp |  | The date associated with the claims file, typically reflecting the reporting period of the claims data. |
| `ingest_datetime` | timestamp |  | The date and time the source file was ingested into the data warehouse or landed in cloud storage. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.medication

- **dbt model:** `core__medication`
- **Grain:** `medication_id`
- **Materialization:** table
- **Description:** The medication table contains information on medications ordered and/or administered during a patient encounter.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `medication_id` | varchar | unique | Unique identifier for each medication in the table. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `patient_id` |  |  | Identifier that links a patient to a particular clinical source system. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `dispensing_date` | date |  | Date the medication was dispensed. |
| `prescribing_date` | date |  | Date the medication was prescribed. |
| `source_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_code` | varchar |  | The code in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_description` | varchar |  | Description of the source code in the source system. |
| `ndc_code` | varchar |  | National drug code associated with the medication. |
| `ndc_description` | varchar |  | Description for the NDC. |
| `ndc_mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `rxnorm_code` | varchar |  | RxNorm code associated with the medication. |
| `rxnorm_description` | varchar |  | Description for the RxNorm code. |
| `rxnorm_mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `atc_code` | varchar |  | ATC code for the medication. |
| `atc_description` | varchar |  | Description for the ATC code. |
| `atc_mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `route` | varchar |  | The route used to administer the medication and/or vaccine. |
| `strength` | varchar |  | The strength of the medication. |
| `quantity` | number |  | The quantity of the medication. |
| `quantity_unit` | varchar |  | The units for the quantity. |
| `days_supply` | number |  | The number of days supply included. |
| `practitioner_id` | varchar |  | Unique identifier for the practitioner on record (e.g., ordered medication, performed the procedure, etc). |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` |  |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.member_months

- **dbt model:** `core__member_months`
- **Grain:** `member_month_key`, `data_source`
- **Materialization:** table
- **Description:** The core member months tables has one record per member per month in the eligibility source data. Members without claims are included in this data table.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `member_month_key` | number | not null | The unique combination of person_id, year_month, payer, plan, and data source. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `year_month` | varchar |  | Unique year-month of in the dataset computed from eligibility. |
| `payer` | varchar |  | Name of the payer (i.e. health insurer) providing coverage. |
| `plan` | varchar |  | Name of the plan (i.e. sub contract) providing coverage. |
| `data_source` | varchar | not null | User-configured field that indicates the data source. |
| `tuva_last_run` | varchar |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |
| `payer_attributed_provider` |  |  | Unique identifier for the provider assigned to this patient-year_month by the payer. |
| `payer_attributed_provider_practice` |  |  | Name of the practice for the payer attributed provider. |
| `payer_attributed_provider_organization` |  |  | Name of the organization for the payer attributed provider. |
| `payer_attributed_provider_lob` |  |  | Name of the line of business for the payer attributed provider (e.g. medicare, medicaid, commercial). |
| `custom_attributed_provider` |  |  | Unique identifier for the provider assigned to this patient-year_month by the user. |
| `custom_attributed_provider_practice` |  |  | Name of the practice for the attributed provider assigned by the user. |
| `custom_attributed_provider_organization` |  |  | Name of the organization for the attributed provider assigned by the user. |
| `custom_attributed_provider_lob` |  |  | Name of the line of business for the attributed provider assigned by the user (e.g. medicare, medicaid, commercial). |

## core.observation

- **dbt model:** `core__observation`
- **Grain:** `observation_id`
- **Materialization:** table
- **Description:** The observation table contains information on measurements other than lab tests e.g. blood pressure, height, and weight.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `observation_id` | varchar | unique | Unique identifier for each observation in the dataset. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `panel_id` | varchar |  | Unique identifier for the panel. |
| `observation_date` | date |  | Date the observation was recorded. |
| `observation_type` | varchar |  | Type of observation. |
| `source_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_code` | varchar |  | The code in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_description` | varchar |  | Description of the source code in the source system. |
| `normalized_code_type` | varchar |  | The normalized type of code. |
| `normalized_code` | varchar |  | The normalized code. |
| `normalized_description` | varchar |  | Normalized description of the code. |
| `mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `result` | varchar |  | The result of the record (e.g., lab test, observation, etc). |
| `source_units` | varchar |  | Source units of the lab test. |
| `normalized_units` | varchar |  | Normalized units of the lab test. |
| `source_reference_range_low` | varchar |  | The low end of the reference range from the source system. |
| `source_reference_range_high` | varchar |  | The high end of the reference range from the source system. |
| `normalized_reference_range_low` | varchar |  | The normalized low end of the reference range. |
| `normalized_reference_range_high` | varchar |  | The normalized high end of the reference range. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.patient

- **dbt model:** `core__patient`
- **Grain:** `person_id`
- **Materialization:** table
- **Description:** The patient table contains demographic and geographic information on patients.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` | varchar | unique, not null | Unique identifier for each person in the dataset. |
| `sex` | varchar |  | The gender of the patient. |
| `race` | varchar |  | The patient's race. |
| `birth_date` | date |  | The birth date of the patient. |
| `death_date` | date |  | Date the patient died if there is one. |
| `death_flag` | number |  | A flag indicating if the patient has died. |
| `name_suffix` | varchar |  | The name suffixes (e.g., Sr., Jr., III.) |
| `first_name` | varchar |  | The first name of the patient. |
| `middle_name` | varchar |  | The middle name of the patient. |
| `last_name` | varchar |  | The last name of the patient. |
| `social_security_number` | varchar |  | The social security number of the patient. |
| `address` | varchar |  | The street address of the record (e.g., facility location, patient, etc). |
| `city` | varchar |  | The city of the record (e.g., facility location, patient, etc). |
| `state` | varchar |  | The state of the record (e.g., facility location, patient, etc). |
| `zip_code` | varchar |  | The zip code of the record (e.g., facility location, patient, etc). |
| `county` | varchar |  | The county for the patient. |
| `latitude` | float |  | The latitude of the record (e.g., facility location, patient, etc). |
| `longitude` | float |  | The longitude of the record (e.g., facility location, patient, etc). |
| `phone` | varchar |  | The phone number for the patient. |
| `email` | varchar |  | The email for the patient |
| `ethnicity` | varchar |  | The ethnicity of the patient |
| `age` | number |  | The age of the patient calculated based on their date of birth and the last time the tuva project was run. |
| `age_group` | varchar |  | The decade age group the patient falls into based on their calculated age. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.person_id_crosswalk

- **dbt model:** `core__person_id_crosswalk`
- **Grain:** `person_id`, `patient_id`, `member_id`, `payer`, `plan`, `data_source`
- **Materialization:** table
- **Description:** The person id crosswalk table contains all source patient identifiers from the input layer eligibility (claims) and patient (clinical).

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` | varchar |  | Unique identifier for each person in the dataset. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `payer` | varchar |  | Name of the payer (i.e. health insurer) providing coverage. |
| `plan` | varchar |  | Name of the plan (i.e. sub contract) providing coverage. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.pharmacy_claim

- **dbt model:** `core__pharmacy_claim`
- **Grain:** `pharmacy_claim_id`
- **Materialization:** table
- **Description:** The pharmacy claim table contains information on prescription drugs that were filled and billed to the insurer.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `pharmacy_claim_id` | varchar | unique, not null | Unique identifier for each row in the table. |
| `claim_id` | varchar | not null | Unique identifier for a claim. Each claim represents a distinct healthcare service or set of services provided to a patient. |
| `claim_line_number` | number | not null | Indicates the line number for the particular line of the claim. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `payer` | varchar |  | Name of the payer (i.e. health insurer) providing coverage. |
| `plan` | varchar |  | Name of the plan (i.e. sub contract) providing coverage. |
| `prescribing_provider_id` | varchar |  | ID for the provider that wrote the prescription (e.g. priamry care physician). |
| `prescribing_provider_name` | varchar |  | Prescribing provider name. |
| `dispensing_provider_id` | varchar |  | ID for the provider that dispensed the prescription (e.g. pharmacy). |
| `dispensing_provider_name` | varchar |  | Dispensing provider name. |
| `dispensing_date` | date |  | Date the medication was dispensed. |
| `ndc_code` | varchar |  | National drug code associated with the medication. |
| `ndc_description` | varchar |  | Description for the NDC. |
| `quantity` | number |  | The quantity of the medication. |
| `days_supply` | number |  | The number of days supply included. |
| `refills` | number |  | Number of refills for the prescription. |
| `paid_date` | date |  | The date the claim was paid. |
| `paid_amount` | number |  | The total amount paid by the insurer. |
| `allowed_amount` | number |  | The total amount allowed (includes amount paid by the insurer and patient). |
| `charge_amount` | number |  | The total amount charged for the services provided, before any adjustments or payments. This is typically in US dollars. |
| `coinsurance_amount` | number |  | The total coinsurance charged on the claim by the provider. |
| `copayment_amount` | number |  | The total copayment charged on the claim by the provider. |
| `deductible_amount` | number |  | The total deductible charged on the claim by the provider. |
| `in_network_flag` | number |  | Flag indicating if the claim was in or out of network. |
| `enrollment_flag` | number |  | Flag indicating if the claim has corresponding enrollment during the same time period the service occurred. |
| `member_month_key` | number |  | The unique combination of person_id, year_month, payer, plan, and data source. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `file_date` | timestamp |  | The date associated with the claims file, typically reflecting the reporting period of the claims data. |
| `ingest_datetime` | timestamp |  | The date and time the source file was ingested into the data warehouse or landed in cloud storage. |
| `tuva_last_run` | varchar |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.practitioner

- **dbt model:** `core__practitioner`
- **Grain:** `practitioner_id`
- **Materialization:** table
- **Description:** The practitioner table contains information on the providers in the dataset e.g. physicians, physicians assistants, etc.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `practitioner_id` | varchar | unique | Unique identifier for the practitioner on record (e.g., ordered medication, performed the procedure, etc). |
| `npi` | varchar |  | The national provider identifier associated with the record e.g. facility_npi, provider_npi |
| `provider_first_name` | varchar |  | The first name of the healthcare provider. |
| `provider_last_name` | varchar |  | The last name of the healthcare provider. |
| `practice_affiliation` | varchar |  | Practice affiliation of the provider. |
| `specialty` | varchar |  | Specialty of the provider. |
| `sub_specialty` | varchar |  | Sub specialty of the provider. |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## core.procedure

- **dbt model:** `core__procedure`
- **Grain:** `procedure_id`
- **Materialization:** table
- **Description:** The procedure table contains information on procedures that were performed on patients in the dataset.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `procedure_id` | varchar | unique | The unique identifier for the performed procedure. |
| `encounter_id` | varchar |  | Unique identifier for each encounter in the dataset. |
| `claim_id` | varchar |  | Unique identifier for a claim. Each claim represents a distinct healthcare service or set of services provided to a patient. |
| `person_id` | varchar | not null | Unique identifier for each person in the dataset. |
| `member_id` | varchar |  | Identifier that links a patient to a particular insurance product or health plan. A patient can have more than one member_id because they can have more than one insurance product/plan. |
| `patient_id` | varchar |  | Identifier that links a patient to a particular clinical source system. |
| `procedure_date` | varchar |  | Date when the procedure was performed. |
| `source_code_type` | varchar |  | The type of code reported in the source system (e.g., ICD-10 code, NDC, lab, etc) |
| `source_code` | varchar |  | The code in the source system (e.g., the ICD-10 code, NDC, lab, etc) |
| `source_description` | varchar |  | Description of the source code in the source system. |
| `normalized_code_type` | varchar |  | The normalized type of code. |
| `normalized_code` | varchar |  | The normalized code. |
| `normalized_description` | varchar |  | Normalized description of the code. |
| `mapping_method` | varchar |  | mapping method used to populate the normalized codes and descriptions. Can be manual (fields were populated in input layer), automatic (dictionary codes matching the source code were found and was automatically populated) or custom (populated by normalization engine) |
| `modifier_1` | varchar |  | First modifier for the procedure code. |
| `modifier_2` | varchar |  | Second modifier for the procedure code. |
| `modifier_3` | varchar |  | Third modifier for the procedure code. |
| `modifier_4` | varchar |  | Fourth modifier for the procedure code. |
| `modifier_5` | varchar |  | Fifth modifier for the procedure code. |
| `practitioner_id` | varchar |  | Unique identifier for the practitioner on record (e.g., ordered medication, performed the procedure, etc). |
| `data_source` | varchar |  | User-configured field that indicates the data source. |
| `tuva_last_run` | timestamp |  | The last time the data was refreshed. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

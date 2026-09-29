# Chronic Conditions (`chronic_conditions`)

Chronic condition flags per member using both the CMS Chronic Conditions Warehouse definitions and Tuva's own hierarchy, in long (one row per member-condition) and wide (one row per member) forms.

[Back to data dictionary index](README.md) | [ERD](../erd.md)

## Tables

| Table | Grain (unique key) | Description |
|---|---|---|
| [`chronic_conditions.cms_chronic_conditions_wide`](#chronic_conditionscms_chronic_conditions_wide) | `person_id` | This model pivots conditions on the patient level (i.e. one record per patient) with flags for each chronic condition. |
| [`chronic_conditions.cms_chronic_conditions_long`](#chronic_conditionscms_chronic_conditions_long) | `person_id`, `claim_id`, `data_source`, `start_date`, `condition` | This model unions condition flags from the 3 upstream stage models that calculate them. |
| [`chronic_conditions.tuva_chronic_conditions_long`](#chronic_conditionstuva_chronic_conditions_long) | `person_id`, `condition` | This model creates one record per patient per condition using the tuva chronic conditions hierarchy as the grouper. The model pulls in the first and last date of the diagnosis that flagged the patient for this condition group. |
| [`chronic_conditions.tuva_chronic_conditions_wide`](#chronic_conditionstuva_chronic_conditions_wide) | _not declared_ | This model creates one record per patient with flags for all the conditions in the tuva chronic conditions hierarchy. A patient will have a 1 in the column for a certain condition if they have ever been coded with a diagnosis that rolls up to that condition and a 0 if not. |

## chronic_conditions.cms_chronic_conditions_wide

- **dbt model:** `chronic_conditions__cms_chronic_conditions_wide`
- **Grain:** `person_id`
- **Materialization:** table
- **Description:** This model pivots conditions on the patient level (i.e. one record per patient) with flags for each chronic condition.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  | unique, not null | Unique ID for the patient. |
| `acute_myocardial_infarction` | boolean |  | flag indicating if the condition is present |
| `adhd_conduct_disorders_and_hyperkinetic_syndrome` | boolean |  | flag indicating if the condition is present |
| `alcohol_use_disorders` | boolean |  | flag indicating if the condition is present |
| `alzheimers_disease` | boolean |  | flag indicating if the condition is present |
| `anemia` | boolean |  | flag indicating if the condition is present |
| `anxiety_disorders` | boolean |  | flag indicating if the condition is present |
| `asthma` | boolean |  | flag indicating if the condition is present |
| `atrial_fibrillation_and_flutter` | boolean |  | flag indicating if the condition is present |
| `autism_spectrum_disorders` | boolean |  | flag indicating if the condition is present |
| `benign_prostatic_hyperplasia` | boolean |  | flag indicating if the condition is present |
| `bipolar_disorder` | boolean |  | flag indicating if the condition is present |
| `cancer_breast` | boolean |  | flag indicating if the condition is present |
| `cancer_colorectal` | boolean |  | flag indicating if the condition is present |
| `cancer_endometrial` | boolean |  | flag indicating if the condition is present |
| `cancer_lung` | boolean |  | flag indicating if the condition is present |
| `cancer_prostate` | boolean |  | flag indicating if the condition is present |
| `cancer_urologic_kidney_renal_pelvis_and_ureter` | boolean |  | flag indicating if the condition is present |
| `cataract` | boolean |  | flag indicating if the condition is present |
| `cerebral_palsy` | boolean |  | flag indicating if the condition is present |
| `chronic_kidney_disease` | boolean |  | flag indicating if the condition is present |
| `chronic_obstructive_pulmonary_disease` | boolean |  | flag indicating if the condition is present |
| `cystic_fibrosis_and_other_metabolic_developmental_disorders` | boolean |  | flag indicating if the condition is present |
| `depression_bipolar_or_other_depressive_mood_disorders` | boolean |  | flag indicating if the condition is present |
| `depressive_disorders` | boolean |  | flag indicating if the condition is present |
| `diabetes` | boolean |  | flag indicating if the condition is present |
| `drug_use_disorders` | boolean |  | flag indicating if the condition is present |
| `epilepsy` | boolean |  | flag indicating if the condition is present |
| `fibromyalgia_and_chronic_pain_and_fatigue` | boolean |  | flag indicating if the condition is present |
| `glaucoma` | boolean |  | flag indicating if the condition is present |
| `heart_failure_and_non_ischemic_heart_disease` | boolean |  | flag indicating if the condition is present |
| `hepatitis_a` | boolean |  | flag indicating if the condition is present |
| `hepatitis_b_acute_or_unspecified` | boolean |  | flag indicating if the condition is present |
| `hepatitis_b_chronic` | boolean |  | flag indicating if the condition is present |
| `hepatitis_c_acute` | boolean |  | flag indicating if the condition is present |
| `hepatitis_c_chronic` | boolean |  | flag indicating if the condition is present |
| `hepatitis_c_unspecified` | boolean |  | flag indicating if the condition is present |
| `hepatitis_d` | boolean |  | flag indicating if the condition is present |
| `hepatitis_e` | boolean |  | flag indicating if the condition is present |
| `hip_pelvic_fracture` | boolean |  | flag indicating if the condition is present |
| `human_immunodeficiency_virus_and_or_acquired_immunodeficiency_syndrome_hiv_aids` | boolean |  | flag indicating if the condition is present |
| `hyperlipidemia` | boolean |  | flag indicating if the condition is present |
| `hypertension` | boolean |  | flag indicating if the condition is present |
| `hypothyroidism` | boolean |  | flag indicating if the condition is present |
| `intellectual_disabilities_and_related_conditions` | boolean |  | flag indicating if the condition is present |
| `ischemic_heart_disease` | boolean |  | flag indicating if the condition is present |
| `learning_disabilities` | boolean |  | flag indicating if the condition is present |
| `leukemias_and_lymphomas` | boolean |  | flag indicating if the condition is present |
| `liver_disease_cirrhosis_and_other_liver_conditions_except_viral_hepatitis` | boolean |  | flag indicating if the condition is present |
| `migraine_and_chronic_headache` | boolean |  | flag indicating if the condition is present |
| `mobility_impairments` | boolean |  | flag indicating if the condition is present |
| `multiple_sclerosis_and_transverse_myelitis` | boolean |  | flag indicating if the condition is present |
| `muscular_dystrophy` | boolean |  | flag indicating if the condition is present |
| `non_alzheimers_dementia` | boolean |  | flag indicating if the condition is present |
| `obesity` | boolean |  | flag indicating if the condition is present |
| `opioid_use_disorder_oud` | boolean |  | flag indicating if the condition is present |
| `osteoporosis_with_or_without_pathological_fracture` | boolean |  | flag indicating if the condition is present |
| `other_developmental_delays` | boolean |  | flag indicating if the condition is present |
| `parkinsons_disease_and_secondary_parkinsonism` | boolean |  | flag indicating if the condition is present |
| `peripheral_vascular_disease_pvd` | boolean |  | flag indicating if the condition is present |
| `personality_disorders` | boolean |  | flag indicating if the condition is present |
| `pneumonia_all_cause` | boolean |  | flag indicating if the condition is present |
| `post_traumatic_stress_disorder_ptsd` | boolean |  | flag indicating if the condition is present |
| `pressure_and_chronic_ulcers` | boolean |  | flag indicating if the condition is present |
| `rheumatoid_arthritis_osteoarthritis` | boolean |  | flag indicating if the condition is present |
| `schizophrenia` | boolean |  | flag indicating if the condition is present |
| `schizophrenia_and_other_psychotic_disorders` | boolean |  | flag indicating if the condition is present |
| `sensory_blindness_and_visual_impairment` | boolean |  | flag indicating if the condition is present |
| `sensory_deafness_and_hearing_impairment` | boolean |  | flag indicating if the condition is present |
| `sickle_cell_disease` | boolean |  | flag indicating if the condition is present |
| `spina_bifida_and_other_congenital_anomalies_of_the_nervous_system` | boolean |  | flag indicating if the condition is present |
| `spinal_cord_injury` | boolean |  | flag indicating if the condition is present |
| `stroke_transient_ischemic_attack` | boolean |  | flag indicating if the condition is present |
| `tobacco_use` | boolean |  | flag indicating if the condition is present |
| `traumatic_brain_injury_and_nonpsychotic_mental_disorders_due_to_brain_damage` | boolean |  | flag indicating if the condition is present |
| `viral_hepatitis_general` | boolean |  | flag indicating if the condition is present |
| `tuva_last_run` |  |  | The time at which the model was materialized. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## chronic_conditions.cms_chronic_conditions_long

- **dbt model:** `chronic_conditions__cms_chronic_conditions_long`
- **Grain:** `person_id`, `claim_id`, `data_source`, `start_date`, `condition`
- **Materialization:** table
- **Description:** This model unions condition flags from the 3 upstream stage models that calculate them.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  | not null | Unique ID for the patient. |
| `claim_id` |  | not null | Unique identifier for each claim. |
| `start_date` |  |  | Start date of the chronic condition derived from diagnosis, procedure, or medication. |
| `chronic_condition_type` |  |  | The type of chronic condition as defined by CMS. ('Common' or 'Other chronic or potentially disabling conditions') |
| `condition_category` |  |  | The category of the condition (e.g. Cardiovascular Disease). |
| `condition` |  | not null | The name of the chronic condition. |
| `data_source` |  |  | Indicates the name of the source dataset (e.g. Medicare Claims). |
| `tuva_last_run` |  |  | The time at which the model was materialized. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## chronic_conditions.tuva_chronic_conditions_long

- **dbt model:** `chronic_conditions__tuva_chronic_conditions_long`
- **Grain:** `person_id`, `condition`
- **Materialization:** table
- **Description:** This model creates one record per patient per condition using the tuva chronic conditions hierarchy as the grouper. The model pulls in the first and last date of the diagnosis that flagged the patient for this condition group.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | The unique identifier for a patient |
| `condition` |  |  | The name of the condition that each diagnosis code rolls up to |
| `first_diagnosis_date` |  |  | The first date when a diagnosis code that rolls up to this condition was coded to this patient |
| `last_diagnosis_date` |  |  | The last date when a diagnosis code that rolls up to this condition was coded to this patient |
| `tuva_last_run` |  |  | The time at which the model was materialized. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

## chronic_conditions.tuva_chronic_conditions_wide

- **dbt model:** `chronic_conditions__tuva_chronic_conditions_wide`
- **Grain:** _not declared_
- **Materialization:** table
- **Description:** This model creates one record per patient with flags for all the conditions in the tuva chronic conditions hierarchy. A patient will have a 1 in the column for a certain condition if they have ever been coded with a diagnosis that rolls up to that condition and a 0 if not.

| Column | Type | Key / Tests | Description |
|---|---|---|---|
| `person_id` |  |  | ID of the patient |
| `obesity` |  |  | flag indicating if the condition is present |
| `osteoarthritis` |  |  | flag indicating if the condition is present |
| `copd` |  |  | flag indicating if the condition is present |
| `anxiety_disorders` |  |  | flag indicating if the condition is present |
| `ckd` |  |  | flag indicating if the condition is present |
| `t2d` |  |  | flag indicating if the condition is present |
| `cll` |  |  | flag indicating if the condition is present |
| `dysplipidemias` |  |  | flag indicating if the condition is present |
| `hypertension` |  |  | flag indicating if the condition is present |
| `atherosclerosis` |  |  | flag indicating if the condition is present |
| `dementia` |  |  | flag indicating if the condition is present |
| `rheumatoid_arthritis` |  |  | flag indicating if the condition is present |
| `celiac` |  |  | flag indicating if the condition is present |
| `hip_fracture` |  |  | flag indicating if the condition is present |
| `immunodeficiencies_and_white_blood_cell_disorders` |  |  | flag indicating if the condition is present |
| `asthma` |  |  | flag indicating if the condition is present |
| `t1d` |  |  | flag indicating if the condition is present |
| `ulcerative_colitis` |  |  | flag indicating if the condition is present |
| `chrohns` |  |  | flag indicating if the condition is present |
| `holicobacter` |  |  | flag indicating if the condition is present |
| `bipolar` |  |  | flag indicating if the condition is present |
| `heart_failure` |  |  | flag indicating if the condition is present |
| `tabacco` |  |  | flag indicating if the condition is present |
| `lyme` |  |  | flag indicating if the condition is present |
| `breast_cancer` |  |  | flag indicating if the condition is present |
| `osteoporosis` |  |  | flag indicating if the condition is present |
| `pulmonary_embolism` |  |  | flag indicating if the condition is present |
| `schizophrenia` |  |  | flag indicating if the condition is present |
| `atrial_fibrillation` |  |  | flag indicating if the condition is present |
| `colorectal_cancer` |  |  | flag indicating if the condition is present |
| `depression` |  |  | flag indicating if the condition is present |
| `deep_vein_thrombosis` |  |  | flag indicating if the condition is present |
| `alzheimer` |  |  | flag indicating if the condition is present |
| `stroke` |  |  | flag indicating if the condition is present |
| `myocardial_infraction` |  |  | flag indicating if the condition is present |
| `opiod_use_disorder` |  |  | flag indicating if the condition is present |
| `lung_cancer` |  |  | flag indicating if the condition is present |
| `herpes` |  |  | flag indicating if the condition is present |
| `rickettsiosis` |  |  | flag indicating if the condition is present |
| `ms` |  |  | flag indicating if the condition is present |
| `alchohol` |  |  | flag indicating if the condition is present |
| `adhd` |  |  | flag indicating if the condition is present |
| `hiv` |  |  | flag indicating if the condition is present |
| `ptsd` |  |  | flag indicating if the condition is present |
| `lupus` |  |  | flag indicating if the condition is present |
| `tuva_last_run` |  |  | The time at which the model was materialized. Generated by `dbt_utils.pretty_time` as the local time of the `dbt run` environment. Timezone is configurable via the `tuva_last_run` var. |

{% docs int_chronic_conditions %}
One row per member (`person_id`) per chronic condition, built by running every
ICD-10-CM diagnosis in `core__condition` through the Tuva chronic condition grouper
(`chronic_conditions__tuva_chronic_conditions_hierarchy`, Tuva value set version
`tuva_seed_version`, currently `1.0.0`).

The grouper is a flat ICD-10-CM code list that assigns each code to a `condition`,
and each `condition` to a `condition_family`. 41 conditions in 9 families are covered.

### How a member qualifies

A member qualifies for a condition when **all** of the following hold:

1. They have a row in `core__condition` (claims diagnoses and/or clinical problem-list
   conditions) where `normalized_code_type = 'icd-10-cm'`.
2. The row's `normalized_code` **exactly matches** an `icd_10_cm_code` listed for that
   condition in the grouper. Codes are stored without the decimal point (e.g. `E119`,
   not `E11.9`), and only the listed codes count: a code sharing a 3-character category
   with a listed code does not qualify unless it is listed itself.
3. The row has a non-null `recorded_date`.
4. The member has qualifying diagnoses on at least
   `chronic_conditions_min_diagnosis_dates` distinct dates (default `1`, i.e. a single
   qualifying diagnosis on any date, matching the Tuva chronic conditions data mart).
   Raise this var (e.g. `--vars '{chronic_conditions_min_diagnosis_dates: 2}'`) to
   require confirmation on a second date and reduce rule-out/one-off coding noise.

There is no lookback window: diagnoses on any date in the data qualify, and a member
never "un-qualifies". Use `first_diagnosis_date` / `last_diagnosis_date` to apply a
period filter downstream.

Diagnosis position (primary vs. secondary), claim type, place of service and
present-on-admission status are not considered.

### Codes that map to more than one condition

A small number of codes appear under two conditions, so a single diagnosis can qualify
a member for both:

| ICD-10-CM | Description | Conditions |
|---|---|---|
| `I110` | Hypertensive heart disease with heart failure | Heart Failure, Hypertension |
| `I130` | Hypertensive heart and CKD with heart failure, CKD stage 1-4 / unspecified | Heart Failure, Hypertension |
| `I132` | Hypertensive heart and CKD with heart failure, CKD stage 5 / ESRD | Heart Failure, Hypertension |
| `I426` | Alcoholic cardiomyopathy | Heart Failure, Alcohol |
| `G3183` | Dementia with Lewy bodies | Dementia, Parkinson's Disease |

### Qualification criteria by condition

Every condition uses the rule above; what differs is the code list. The table below
summarizes each condition's code list (value set version `1.0.0`). The category column
lists the 3-character ICD-10-CM categories the listed codes fall under. For the exact
codes, query the grouper:

```sql
select icd_10_cm_code, icd_10_cm_description
from chronic_conditions._value_set_tuva_chronic_conditions_hierarchy
where condition = 'Type 2 Diabetes'
order by icd_10_cm_code
```

| Condition family | Condition | Qualifying ICD-10-CM codes | ICD-10-CM categories (first 3 characters) |
|---|---|---|---|
| Autoimmune Disease | Crohn's Disease | 28 | `K50` |
| Autoimmune Disease | Lupus | 16 | `L93`, `M32` |
| Autoimmune Disease | Rheumatoid Arthritis | 386 | `M05`, `M06`, `M08` |
| Autoimmune Disease | Type 1 Diabetes | 72 | `E10` |
| Autoimmune Disease | Ulcerative Colitis | 21 | `K51` |
| Cancer | Breast Cancer | 72 | `C50`, `D05`, `Z17`, `Z19`, `Z85`, `Z86` |
| Cancer | Colorectal Cancer | 21 | `C18`, `C19`, `C20`, `C49`, `D01`, `Z85` |
| Cancer | Lung Cancer | 21 | `C34`, `D02`, `Z85` |
| Cardiovascular Disease | Acute Myocardial Infarction | 26 | `I21`, `I22`, `I23` |
| Cardiovascular Disease | Atherosclerosis | 45 | `I25` |
| Cardiovascular Disease | Atrial Fibrillation | 10 | `I48` |
| Cardiovascular Disease | Heart Failure | 32 | `I11`, `I13`, `I42`, `I43`, `I50` |
| Cardiovascular Disease | Hypertension | 19 | `H35`, `I10`, `I11`, `I12`, `I13`, `I15`, `I67` |
| Cardiovascular Disease | Stroke / Transient Ischemic Attack | 262 | `G45`, `G46`, `G97`, `I60`, `I61`, `I62`, `I63`, `I67`, `I97`, `S06` |
| Mental Health | Anxiety | 29 | `F06`, `F40`, `F41` |
| Mental Health | Attention-Deficit Hyperactivity Disorder (ADHD) | 5 | `F90` |
| Mental Health | Bipolar | 28 | `F31` |
| Mental Health | Depression | 18 | `F32`, `F33` |
| Mental Health | Obsessive-Compulsive Disorder (OCD) | 6 | `F42` |
| Mental Health | Personality Disorder | 19 | `F21`, `F34`, `F60`, `F68`, `F69` |
| Mental Health | Post-Traumatic Stress Disorder (PTSD) | 3 | `F43` |
| Mental Health | Schizophrenia | 12 | `F20`, `F25` |
| Metabolic Disease | Chronic Kidney Disease | 10 | `N18` |
| Metabolic Disease | Hyperlipidemia | 10 | `E78` |
| Metabolic Disease | Metabolic Syndrome | 1 | `E88` |
| Metabolic Disease | Obesity | 21 | `E66`, `Z68` |
| Metabolic Disease | Type 2 Diabetes | 94 | `E11` |
| Neuro-degenerative Disease | Alzheimer’s Disease | 4 | `G30` |
| Neuro-degenerative Disease | Amyotrophic Lateral Sclerosis (ALS) | 7 | `G12` |
| Neuro-degenerative Disease | Dementia | 13 | `F01`, `F02`, `F03`, `F05`, `G13`, `G31` |
| Neuro-degenerative Disease | Multiple Sclerosis | 1 | `G35` |
| Neuro-degenerative Disease | Muscular Dystrophy | 5 | `G71` |
| Neuro-degenerative Disease | Parkinson's Disease | 8 | `G20`, `G21`, `G31` |
| Pulmonary Disease | Asthma | 18 | `J45` |
| Pulmonary Disease | Chronic Obstructive Pulmonary Disease (COPD) | 17 | `J40`, `J41`, `J42`, `J43`, `J44`, `J47`, `J98` |
| Pulmonary Disease | Cystic Fibrosis | 5 | `E84` |
| Substance Use | Alcohol | 90 | `F10`, `G62`, `HZ2`, `HZ3`, `HZ4`, `HZ9`, `I42`, `K29`, `K70`, `P04`, `Q86`, `T51`, `Z71` |
| Substance Use | Cocaine | 45 | `F14` |
| Substance Use | Opioid | 42 | `F11` |
| Substance Use | Tobacco | 41 | `F17`, `G92`, `G94`, `O99`, `T65`, `Z72` |

Notes on the value set:

- The Alcohol list also contains `HZ*` codes, which are ICD-10-PCS (procedure) codes for
  substance-abuse treatment. They never match an ICD-10-CM diagnosis, so in practice
  Alcohol qualification comes from the ICD-10-CM codes in the list.
- Breast, Colorectal and Lung Cancer include personal-history codes (`Z85.*`, and
  `Z86.000` for breast), and Breast Cancer also includes hormone receptor status codes
  (`Z17.*`, `Z19.*`), so members with only a history or status code still qualify.
- Obesity includes adult BMI codes (`Z68.*`) in addition to `E66.*`.
{% enddocs %}

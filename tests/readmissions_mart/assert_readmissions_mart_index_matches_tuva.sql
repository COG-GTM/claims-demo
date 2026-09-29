-- For encounters that pass Tuva's data quality checks, the mart's index
-- admission definition must agree with Tuva's index_admission_flag.
select
      m.encounter_id
    , m.index_admission_flag as mart_index_admission_flag
    , t.index_admission_flag as tuva_index_admission_flag
from {{ ref('readmissions_mart__encounter') }} as m
inner join {{ ref('readmissions__encounter_augmented') }} as t
    on m.encounter_id = t.encounter_id
where m.exclusion_data_quality_flag = 0
  and m.index_admission_flag <> t.index_admission_flag

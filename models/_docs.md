{% docs demo_placeholder_model %}
Zero-row placeholder that satisfies the Tuva input-layer contract for a clinical table the synthetic
demo dataset does not supply. Every column is a typed `null` and the query returns no rows
(`limit 0`, or `top 0` on Fabric), so the relation (a view by default) exists with the correct column names and types but is
always empty. It lets `clinical_enabled: true` compile and run the Tuva clinical marts end to end
without real clinical source data. Replace this model with a mapping from your own source system to
populate it.
{% enddocs %}

{% docs demo_person_id %}
Enterprise-wide identifier for a human being, stable across every payer, plan and clinical source.
This is the key the Tuva Project uses to join a person's claims, eligibility and clinical records, so
one `person_id` can correspond to several `patient_id` and `member_id` values.
{% enddocs %}

{% docs demo_patient_id %}
The person's identifier within a single clinical source system (e.g. an EHR MRN). Scoped to
`data_source`; use `person_id` to link the same person across sources.
{% enddocs %}

{% docs demo_encounter_id %}
Identifier of the clinical visit or stay during which this record was captured. Joins to
`encounter.encounter_id`; null when the record was not captured in the context of an encounter.
{% enddocs %}

{% docs demo_claim_id %}
Identifier of the claim this record was derived from, when the record originates from claims rather
than a medical record. Joins to `medical_claim.claim_id`; null for EHR-sourced records.
{% enddocs %}

{% docs demo_payer %}
Health insurer whose coverage this record was billed or reported under. Used by payer-scoped marts such
as CMS-HCC risk adjustment; null for records with no payer context.
{% enddocs %}

{% docs demo_practitioner_id %}
Identifier of the clinician responsible for this record (e.g. who prescribed the drug or performed the
procedure). Joins to `practitioner.practitioner_id`.
{% enddocs %}

{% docs demo_data_source %}
User-assigned label for the upstream system or feed the row came from (e.g. an EHR instance or payer
feed). Part of the natural key in most Tuva tables, since identifiers are only unique within a source.
{% enddocs %}

{% docs demo_file_name %}
Name of the raw file the row was loaded from, for lineage and debugging back to the source extract.
{% enddocs %}

{% docs demo_ingest_datetime %}
When the source file landed in the warehouse or cloud storage. An audit field for tracing a row back
to a specific delivery; it describes the load, not the clinical event.
{% enddocs %}

{% docs demo_tuva_last_run %}
Timestamp of the dbt run that produced the row, so downstream users can tell how fresh an output is.
Tuva core models stamp it from the `tuva_last_run` var; it is always null in these placeholder models.
{% enddocs %}

{% docs demo_source_code_type %}
Coding system of `source_code` exactly as reported by the source (e.g. `icd-10-cm`, `snomed-ct`).
{% enddocs %}

{% docs demo_source_code %}
The code as it appears in the source system, before any Tuva normalization or mapping.
{% enddocs %}

{% docs demo_source_description %}
The source system's human-readable label for `source_code`.
{% enddocs %}

{% docs demo_normalized_code_type %}
Coding system after mapping the source code to a standard terminology Tuva understands. Populated by
the user's mapping when the source uses a local or non-standard code system.
{% enddocs %}

{% docs demo_normalized_code %}
Standard-terminology code that the Tuva marts group and measure on. Several marts coalesce this with
`source_code`, so it only needs to be populated when the source code is not already standard.
{% enddocs %}

{% docs demo_normalized_description %}
Standard-terminology description of `normalized_code`.
{% enddocs %}

{% docs __overview__ %}
# The Tuva Project Demo

This project loads a 1,000-patient synthetic claims and clinical dataset and runs it through the
[Tuva Project](https://thetuvaproject.com) package. Everything under `the_tuva_project` is package code;
this project only supplies the Tuva input layer.

## What this project provides

**Seeds (loaded from S3 by post-hooks)** — the synthetic source data: `medical_claim`,
`pharmacy_claim`, `eligibility`, `appointment`, `immunization`, `lab_result`, `observation` and
`provider_attribution_source`.

**Placeholder models** — `condition`, `encounter`, `location`, `medication`, `patient`,
`practitioner` and `procedure`. The synthetic dataset has no data for these clinical tables, so each
is a zero-row view with the exact Tuva input-layer columns and types. They exist only so the Tuva
clinical marts compile and run with `clinical_enabled: true`.

**`input_layer__provider_attribution`** — replaces the Tuva package model of the same name (disabled
in `dbt_project.yml`). Grain: one row per `person_id` × `year_month` × `payer` × `plan` ×
`data_source`. It reads the `provider_attribution_source` seed, which has no `member_id`, and fills
`member_id` from the `eligibility` span for the same person, payer and plan that covers the
`year_month` (lowest `member_id` wins when spans overlap; null when no span covers the month). Its
column documentation and tests are inherited from the Tuva input-layer contract, because dbt applies
the package's property file to this model and a model can only be described once.
{% enddocs %}

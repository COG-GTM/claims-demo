# Warehouse documentation

Start here if you want to query the warehouse built by this project without
reading the dbt SQL.

| Document | What it covers |
|---|---|
| [ERD](erd.md) | Mermaid star-schema diagrams of Core and how each mart joins to it, plus conformed keys and common joins. |
| [Data dictionary](data_dictionary/README.md) | Every analyst-facing table: schema, grain, description, and every column with type and tests. |

The other files in this directory (`index.html`, `manifest.json`,
`catalog.json`, `run_results.json`) are the generated dbt docs site. Run
`dbt docs generate` to refresh them.

## Schema names

The docs use Tuva's default schema names (`core`, `cms_hcc`, ...). The
physical schema depends on your dbt target and vars:

- With `tuva_schema_prefix: demo` the schemas become `demo_core`,
  `demo_cms_hcc`, etc. (the committed dbt docs artifacts were generated this
  way).
- Otherwise the schemas are exactly `core`, `cms_hcc`, etc.: this project's
  `macros/generate_schema_name.sql` uses custom schema names verbatim (no
  target-schema prefix), in the database set by your profile.

## Demo-specific settings

From `dbt_project.yml`: claims and clinical data are both enabled, CMS-HCC
scores are for payment year 2018, quality measures use the period ending
2018-12-31, and provider attribution is enabled. All data is synthetic.

## Regenerating the data dictionary

The dictionary is generated from the column docs in the installed Tuva
package, so it stays in sync after upgrades:

```bash
dbt deps
python docs/tools/generate_data_dictionary.py   # needs PyYAML (installed with dbt)
```

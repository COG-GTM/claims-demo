#!/usr/bin/env python3
"""Verify that the incremental input-layer models produce the same rows as a full refresh.

Runs against the DuckDB CI profile (integration_tests/profiles/duckdb) and expects the
demo seeds to already be loaded (`dbt seed`). The source seed tables are modified
during the check and restored from a backup afterwards.

Scenario per model:
  1. "Final" source = original seed with a sample of rows inside the lookback window
     updated (simulating late-arriving corrections).
  2. Baseline = `dbt run --full-refresh` on the final source.
  3. "Earlier" source = original seed without its most recent partitions
     (simulating data that has not arrived yet); `dbt run --full-refresh` on it.
  4. Swap the final source back in and run `dbt run` (incremental). The target must
     equal the baseline.
  5. Run `dbt run` again with no source changes. The target must still equal the
     baseline (idempotency).

Usage:
  DBT_PROFILES_DIR=integration_tests/profiles/duckdb \\
  DBT_MOTHERDUCK_CI_PATH=/path/to/demo.duckdb \\
  python scripts/verify_incremental_parity.py
"""

import argparse
import os
import subprocess
import sys
from dataclasses import dataclass

import duckdb


@dataclass(frozen=True)
class IncrementalModel:
    model: str
    source: str
    partition_column: str
    mutate_sql: str


MODELS = [
    IncrementalModel(
        model="input_layer__medical_claim",
        source="medical_claim",
        partition_column="claim_end_date",
        mutate_sql="paid_amount = coalesce(paid_amount, 0) + 1",
    ),
    IncrementalModel(
        model="input_layer__observation",
        source="observation",
        partition_column="observation_date",
        mutate_sql="result = coalesce(result, '') || ' (corrected)'",
    ),
    IncrementalModel(
        model="input_layer__lab_result",
        source="lab_result",
        partition_column="result_datetime",
        mutate_sql="result = coalesce(result, '') || ' (corrected)'",
    ),
]

SOURCE_SCHEMA = "input_layer"
TARGET_SCHEMA = "input_layer"
WORK_SCHEMA = "incremental_parity"


def sql(db_path: str, statements: list[str]) -> list[tuple]:
    conn = duckdb.connect(db_path)
    try:
        result: list[tuple] = []
        for statement in statements:
            result = conn.execute(statement).fetchall()
        return result
    finally:
        conn.close()


def dbt_run(dbt_bin: str, full_refresh: bool) -> None:
    command = [dbt_bin, "run", "--select", *[m.model for m in MODELS]]
    if full_refresh:
        command.append("--full-refresh")
    print(f"$ {' '.join(command)}", flush=True)
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        print(completed.stdout[-4000:], completed.stderr[-4000:], sep="\n")
        raise SystemExit(f"dbt run failed ({completed.returncode})")


def source_table(m: IncrementalModel) -> str:
    return f"{SOURCE_SCHEMA}.{m.source}"


def work_table(m: IncrementalModel, suffix: str) -> str:
    return f"{WORK_SCHEMA}.{m.source}__{suffix}"


def compare(db_path: str, m: IncrementalModel, label: str) -> bool:
    target = f"{TARGET_SCHEMA}.{m.model}"
    baseline = work_table(m, "full_refresh_result")
    target_rows, baseline_rows, missing, extra = sql(
        db_path,
        [
            f"""
            select
                (select count(*) from {target}),
                (select count(*) from {baseline}),
                (select count(*) from (select * from {baseline} except all select * from {target})),
                (select count(*) from (select * from {target} except all select * from {baseline}))
            """
        ],
    )[0]
    ok = target_rows == baseline_rows and missing == 0 and extra == 0
    print(
        f"  [{'PASS' if ok else 'FAIL'}] {label:<28} {m.model:<28} "
        f"rows={target_rows} full_refresh_rows={baseline_rows} "
        f"missing={missing} extra={extra}"
    )
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--db", default=os.environ.get("DBT_MOTHERDUCK_CI_PATH"), help="DuckDB file used by the dbt profile")
    parser.add_argument("--dbt", default="dbt", help="dbt executable")
    parser.add_argument("--late-days", type=int, default=45, help="Most recent days withheld from the earlier load")
    parser.add_argument(
        "--correction-days",
        type=int,
        default=60,
        help="Corrections are applied to rows this many days before the latest partition (must be within incremental_lookback_days)",
    )
    args = parser.parse_args()
    if not args.db:
        parser.error("--db or DBT_MOTHERDUCK_CI_PATH is required")

    setup = [f"create schema if not exists {WORK_SCHEMA}"]
    for m in MODELS:
        partition_date = f"cast({m.partition_column} as date)"
        setup += [
            f"create or replace table {work_table(m, 'original')} as select * from {source_table(m)}",
            f"create or replace table {work_table(m, 'final')} as select * from {source_table(m)}",
            f"""
            update {work_table(m, "final")} set {m.mutate_sql}
            where {partition_date} between
                (select max({partition_date}) - interval {args.correction_days} day from {work_table(m, "original")})
                and (select max({partition_date}) - interval {args.late_days + 1} day from {work_table(m, "original")})
              and rowid % 10 = 0
            """,
            f"""
            create or replace table {work_table(m, "earlier")} as
            select * from {work_table(m, "original")}
            where {partition_date} <= (select max({partition_date}) - interval {args.late_days} day from {work_table(m, "original")})
            """,
        ]
    sql(args.db, setup)

    def load_source(suffix: str) -> None:
        sql(args.db, [f"create or replace table {source_table(m)} as select * from {work_table(m, suffix)}" for m in MODELS])

    all_ok = True
    try:
        for m in MODELS:
            original, earlier, corrected = sql(
                args.db,
                [
                    f"""
                    select
                        (select count(*) from {work_table(m, "original")}),
                        (select count(*) from {work_table(m, "earlier")}),
                        (select count(*) from (select * from {work_table(m, "final")} except all select * from {work_table(m, "original")}))
                    """
                ],
            )[0]
            print(f"{m.source}: original={original} earlier_load={earlier} late_rows={original - earlier} corrected_rows={corrected}")

        print("1) Full refresh on final source (baseline)")
        load_source("final")
        dbt_run(args.dbt, full_refresh=True)
        sql(
            args.db,
            [f"create or replace table {work_table(m, 'full_refresh_result')} as select * from {TARGET_SCHEMA}.{m.model}" for m in MODELS],
        )

        print("2) Full refresh on earlier source (late rows withheld, no corrections)")
        load_source("earlier")
        dbt_run(args.dbt, full_refresh=True)

        print("3) Incremental run after late rows and corrections arrive")
        load_source("final")
        dbt_run(args.dbt, full_refresh=False)
        for m in MODELS:
            all_ok &= compare(args.db, m, "incremental vs full refresh")

        print("4) Second incremental run with no source changes")
        dbt_run(args.dbt, full_refresh=False)
        for m in MODELS:
            all_ok &= compare(args.db, m, "idempotent re-run")
    finally:
        load_source("original")
        print(
            "Restored original seed tables. Run `dbt run --full-refresh --select "
            + " ".join(m.model for m in MODELS)
            + "` to rebuild the models from them."
        )

    print("RESULT:", "PASS" if all_ok else "FAIL")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())

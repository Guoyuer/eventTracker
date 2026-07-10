# ADR 0003: Rename Events to Activities in Schema v7

## Status

Accepted

## Context

The product, domain model, repositories, and UI describe tracked items as
Activities. The persistent schema still exposes an `events` table and
`records.event_id`, which leaks prototype terminology into generated Drift APIs,
raw SQL, migration tests, and operational tooling.

## Decision

Schema v7 renames the persistent identity consistently:

- `events` becomes `activities`.
- `records.event_id` becomes `records.activity_id`.
- supporting indexes use `activity` terminology.
- Drift exposes `activities` and `activityId`; its generated persistence row is
  explicitly named `ActivityRow` to avoid colliding with the domain `Activity`.

The v6-to-v7 upgrade rebuilds the two tables, copies all IDs and record data,
then recreates the foreign key, checks, and indexes. It does not change product
behavior or discard valid local history.

## Consequences

- New code cannot introduce Event terminology at the persistence boundary.
- Existing v1-v5 migration tests remain historical coverage; v6-to-v7 has a
  structural schema verifier and data-retention test.
- SQLite clients that query this private local database directly must use the
  v7 names after upgrade.

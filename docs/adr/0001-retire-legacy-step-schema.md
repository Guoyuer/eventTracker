# ADR 0001: Retire Legacy Step Schema

## Status

Accepted

## Context

The active product is an activity tracker. Step counting was an inactive prototype:

- the step-count UI has been removed
- fake/debug step data generation has been removed
- no active code writes step data
- the Drift schema still creates `steps` and `step_offset`
- activity record reads still know about legacy `records.event_id = -1` sentinel rows

Keeping those tables and sentinel rules makes normal activity records harder to reason about.

## Decision

Remove the legacy step schema from the active Drift model.

Schema version 3 migrates old local databases by:

- deleting sentinel rows where `records.event_id = -1`
- dropping `steps`
- dropping `step_offset`
- dropping the legacy `step_time` index

Step tracking can return only as a new explicit module with its own product decision and schema.

## Consequences

- Normal activity record queries no longer need a step sentinel filter.
- Existing legacy step prototype data is discarded during migration.
- Migration tests must cover old databases with step tables and sentinel records.

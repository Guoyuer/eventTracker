# ADR 0002: Records Are the Activity Source of Truth

## Status

Accepted

## Context

Events stored `lastRecordId`, `sumTime`, and `sumVal` alongside the Records that produced those values. Every Record mutation therefore had to update two representations atomically. Repair code reduced drift after normal writes but could not prevent stale fields, wrong Activity/Record type combinations, orphan Records, or multiple active Records.

The application is a personal tracker whose local history is small enough to summarize during a single Events-to-Records read. There is no measured performance requirement for persisted summary caches.

## Decision

- Records are the only persisted source of Activity active state, occurrence count, total duration, and total value.
- Schema v4 removes `last_record_id`, `sum_time`, and `sum_val` from Events.
- `ActivityRecordHistory` validates a complete Activity history and produces its summary.
- `ActivitySnapshotStore` reads Events and Records in one join and builds immutable Activity Snapshots from that rule.
- Record writes validate Activity type in `RecordLifecycleStore`.
- SQLite enforces the Event foreign key, valid Record timestamp/value shapes, and at most one active Record per Activity.
- Migration fails on malformed existing history instead of silently guessing a repair.

## Consequences

- Aggregate repair APIs and duplicate incremental/rebuild rules are deleted.
- Activity list reads transfer all Records needed for their summaries. This is the deliberate correctness-first tradeoff for the current data scale.
- A future summary cache requires a measured performance problem, one invalidation owner, migration coverage, and a new ADR.

# Flowm Layered Architecture

This document defines the target architecture for new code. Existing `lib/pages`,
`lib/state`, `lib/db`, `lib/components`, and `lib/utils` code remains supported
while features are migrated incrementally.

## Target layers

- `lib/app/`: app bootstrap, router wiring, theme wiring, and global app concerns.
- `lib/data/`: persistence and remote data sources, including Drift database, DAO
  adapters, DTOs, and data mappers.
- `lib/domain/`: pure Dart business entities, value objects, and use-case input or
  output models. This layer must not import Flutter widgets or UI components.
- `lib/features/<feature>/application/`: feature orchestration, controllers, and
  Riverpod providers that coordinate repositories and use cases.
- `lib/features/<feature>/presentation/`: feature-specific UI entry points and
  view models.
- `lib/shared/`: reusable UI, formatting, and infrastructure utilities shared by
  multiple features.

## Dependency direction

New code should depend in this direction only:

`presentation -> application -> domain -> data`

Temporary adapters may import legacy modules while migration is in progress, but
new domain/data/application code must not depend on page files or component UI
models unless explicitly marked as a migration shim.

## Migration rules

- Keep behavior stable during architecture migration unless a task explicitly asks
  for product changes.
- Prefer small feature slices over broad file moves.
- Do not move Drift schemas, DAOs, routes, or existing pages until their feature
  boundary is ready.
- When extracting page logic, keep validation and user feedback in presentation;
  move persistence orchestration and provider refresh into application.

## Repository migration notes

- Account, cashflow, and net-worth code should prefer query/service classes under
  `lib/data/*` plus feature providers under `lib/features/*/application`.
- Legacy repositories may temporarily delegate to those classes while callers are
  migrated, but new query logic should not be added to legacy repository files.
- Shared finance concepts such as account tree type, cashflow type, and balance
  points live under `lib/domain` instead of UI component files.

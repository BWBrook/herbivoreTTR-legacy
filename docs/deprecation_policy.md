# Deprecation Policy — herbivoreTTR (v1.0)

This policy governs compatibility for all exported R functions and schema-versioned outputs.

## Scope
- Exported functions listed in `NAMESPACE`
- Scenario contract schema (`docs/scenario_contract_v1.md`)
- Output schema (`docs/output_contract_v1.md`)

## Compatibility guarantees
- Patch releases (`x.y.z`): no breaking API or schema changes.
- Minor releases (`x.y.z`): additive changes only; removals require prior deprecation cycle.
- Major releases (`x.y.z` where `x` changes): removals allowed only for previously deprecated interfaces with migration notes.

## Deprecation cycle
1. Soft deprecation:
- Mark interface as deprecated in docs and changelog.
- Emit warning at call-time where practical.
- Provide a replacement and migration example.

2. Hard deprecation:
- Convert warning to error no earlier than the next minor release after soft deprecation.
- Keep migration guidance in docs and changelog.

3. Removal:
- Remove deprecated interface in next major release.
- Record the removal in `CHANGELOG.md` and `docs/decisions.md`.

## Exceptions
- Critical correctness fixes may tighten behavior without a full cycle when required to prevent invalid scientific outputs.
- Such exceptions must be recorded in `docs/decisions.md` with rationale and migration advice.

## Communication requirements
- All deprecations must appear in:
- `CHANGELOG.md`
- `docs/decisions.md`
- `docs/roadmap.md` (if queue scope changes)

## Migration support
- If output schemas change, bump schema version and provide migration helpers/tests.
- Keep at least one prior schema migration path documented for one major release.

# Architecture Decision Records (ADR)

Each ADR captures one frozen architectural or clinical-safety
decision: context, decision, consequences. ADRs are the single source
of truth referenced by every task in `/tasks`. Protected by
`CODEOWNERS` — changes require architect review.

- [ADR-000 — Roles and workflow](ADR-000-roles-and-workflow.md)
- [ADR-001 — Independent applications, shared minimal core](ADR-001-app-independence.md)
- [ADR-002 — Patient Registry as single source of identity](ADR-002-patient-registry.md)
- [ADR-003 — Data Contract design and versioning](ADR-003-data-contract-versioning.md)
- [ADR-004 — Clinical rules classification (data / code / hybrid)](ADR-004-clinical-rules-classification.md)
- [ADR-005 — Provenance: two-level (summary / detailed trace)](ADR-005-provenance-two-level.md)
- [ADR-006 — Immutability of clinical facts + correction events](ADR-006-immutability-and-corrections.md)
- [ADR-007 — Identity matching vs. merge](ADR-007-identity-matching-vs-merge.md)
- [ADR-008 — Clinical knowledge versioning & Core library versioning](ADR-008-clinical-knowledge-versioning.md)

## Planned next

- Domain model: `docs/domain/oncocardio-domain-model-v1.md`
- Data contract: `docs/domain/echostudy-export-v1.md`

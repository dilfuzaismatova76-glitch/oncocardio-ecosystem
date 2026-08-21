#!/usr/bin/env bash
# setup_repo.sh
# Creates the base folder/file structure for the OncoCardio / EchoExpert
# ecosystem repository, including CODEOWNERS, CONTRIBUTING, PR template,
# and a GitHub Actions guardrail for clinically critical paths.
#
# Usage:
#   1. Create and clone an empty repo, e.g.:
#        git clone git@github.com:<you>/oncocardio-ecosystem.git
#        cd oncocardio-ecosystem
#   2. Copy this script into the repo root and run:
#        chmod +x setup_repo.sh
#        ./setup_repo.sh <your-github-username>
#   3. Review, then commit:
#        git add .
#        git commit -m "chore: bootstrap repo structure, CODEOWNERS, guardrails"
#        git push

set -euo pipefail

GH_USER="${1:-}"
if [[ -z "$GH_USER" ]]; then
  echo "Usage: $0 <your-github-username>"
  echo "Example: $0 dilshod2"
  exit 1
fi

echo "==> Bootstrapping repo structure for owner: @${GH_USER}"

# ---------------------------------------------------------------------------
# 1. Directory structure
# ---------------------------------------------------------------------------

DIRS=(
  "docs/architecture"
  "docs/domain"
  "tasks"
  ".github/workflows"

  "medicalcore/identity"
  "medicalcore/contracts"
  "medicalcore/rules"
  "medicalcore/provenance"
  "medicalcore/repository"

  "echoexpert/domain"
  "echoexpert/ui"
  "echoexpert/report"

  "oncocardio/domain"
  "oncocardio/rules"
  "oncocardio/risk"
  "oncocardio/alerts"
  "oncocardio/monitoring"
  "oncocardio/provenance"
  "oncocardio/identity"
  "oncocardio/ui"
  "oncocardio/report"
)

for d in "${DIRS[@]}"; do
  mkdir -p "$d"
  # Keep empty dirs tracked by git via .gitkeep
  if [[ -z "$(ls -A "$d" 2>/dev/null)" ]]; then
    touch "$d/.gitkeep"
  fi
done

echo "==> Created $(printf '%s\n' "${DIRS[@]}" | wc -l) directories"

# ---------------------------------------------------------------------------
# 2. .gitignore
# ---------------------------------------------------------------------------

if [[ ! -f .gitignore ]]; then
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/
.pytest_cache/
.mypy_cache/

# SQLite local dev DBs
*.sqlite
*.sqlite3
*.db

# Build artifacts
build/
dist/
*.spec

# OS / editor
.DS_Store
.vscode/
.idea/

# Env
.env
EOF
fi

# ---------------------------------------------------------------------------
# 3. README.md
# ---------------------------------------------------------------------------

if [[ ! -f README.md ]]; then
cat > README.md << 'EOF'
# OncoCardio / EchoExpert Ecosystem

Cardio-oncology clinical decision support system (CDSS) ecosystem,
built as independent desktop applications sharing a minimal common
platform.

- `EchoExpert.exe` — echocardiography study management
- `OncoCardio.exe` — cardio-oncology clinical decision support

## Start here

- Architecture decisions: [`docs/architecture/`](docs/architecture)
- Domain models & data contracts: [`docs/domain/`](docs/domain)
- Contribution rules & roles: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Roles

This project has a strict separation between architectural/clinical
decisions and implementation. See `CONTRIBUTING.md` before opening
a PR — some paths are protected and require explicit architect
review (see `CODEOWNERS`).
EOF
fi

# ---------------------------------------------------------------------------
# 4. CODEOWNERS
# ---------------------------------------------------------------------------

cat > CODEOWNERS << EOF
# CODEOWNERS
# Changes to these paths require review from the architect/lead
# before merging. This covers clinical thresholds, rule/risk model
# versioning, alert/monitoring control flow, provenance structure,
# and patient identity matching/merge logic.
#
# Implementation assistants (including AI tools) may PROPOSE changes
# here via PR, but merge must not proceed without explicit review.

/docs/architecture/            @${GH_USER}
/docs/domain/                  @${GH_USER}

/medicalcore/identity/         @${GH_USER}
/medicalcore/contracts/        @${GH_USER}
/medicalcore/rules/            @${GH_USER}
/medicalcore/provenance/       @${GH_USER}

/oncocardio/rules/             @${GH_USER}
/oncocardio/risk/              @${GH_USER}
/oncocardio/alerts/            @${GH_USER}
/oncocardio/monitoring/        @${GH_USER}
/oncocardio/provenance/        @${GH_USER}
/oncocardio/identity/          @${GH_USER}
EOF

# ---------------------------------------------------------------------------
# 5. CONTRIBUTING.md
# ---------------------------------------------------------------------------

cat > CONTRIBUTING.md << 'EOF'
# Contributing rules

## Roles

- **Architect / Lead** — owns all architectural and clinical decisions:
  domain model, data contracts, clinical rule classification, versioning
  strategy, provenance structure, patient identity strategy. Final
  arbiter on anything touching clinical correctness or safety.

- **Implementation assistant** (human or AI, e.g. GPT/Claude used for
  code generation) — implements tasks strictly according to the
  specification in `/tasks/*.md` and `/docs/domain/*.md`.
  Does **not** independently:
  - introduce or modify clinical thresholds/formulas,
  - change the structure of RuleVersion / RiskModelVersion / Provenance,
  - change control flow in AlertEngine / MonitoringEngine,
  - make decisions about patient identity matching/merge.

## Process

1. Every change references an ADR (`docs/architecture/ADR-XXX.md`) or a
   Task (`tasks/TASK-XXX.md`). PRs without a reference are not accepted.
2. Changes touching paths listed in `CODEOWNERS` require explicit
   architect review before merge.
3. Any proposed clinical threshold/formula/rule must cite its source
   guideline and version in the PR description and, ideally, in code
   comments / the rule definition itself.
4. Clinical facts (measurements, results) are immutable once recorded.
   Corrections are new events referencing the original record — never
   in-place edits of a recorded clinical value.

## PR checklist

See `.github/pull_request_template.md` — filled in automatically when
opening a PR.
EOF

# ---------------------------------------------------------------------------
# 6. PR template
# ---------------------------------------------------------------------------

cat > .github/pull_request_template.md << 'EOF'
## Reference
<!-- Required: link to ADR (docs/architecture/ADR-XXX.md) or Task (tasks/TASK-XXX.md) -->
-

## Scope
<!-- What this PR does, in a couple of sentences -->

## Clinical content check
- [ ] This PR does not introduce new clinical thresholds/formulas without a cited guideline source
- [ ] This PR does not change the structure of RuleVersion / RiskModelVersion / Provenance
- [ ] This PR does not change control flow in AlertEngine / MonitoringEngine
- [ ] This PR does not affect patient identity matching/merge logic
- [ ] If any box above is unchecked, the PR description contains `APPROVED-BY-ARCHITECT`

## Tests
- [ ] Unit tests added/updated
EOF

# ---------------------------------------------------------------------------
# 7. GitHub Actions guardrail workflow
# ---------------------------------------------------------------------------

cat > .github/workflows/protected-paths.yml << 'EOF'
name: Protected clinical paths check

on:
  pull_request:
    branches: [main]

jobs:
  check-protected-paths:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: List changed files
        id: changed
        run: |
          git diff --name-only origin/${{ github.base_ref }}...HEAD > changed_files.txt
          cat changed_files.txt

      - name: Check protected paths
        env:
          PR_BODY: ${{ github.event.pull_request.body }}
        run: |
          PROTECTED_REGEX='^(oncocardio/(rules|risk|alerts|monitoring|provenance|identity)/|medicalcore/(identity|contracts|rules|provenance)/|docs/(architecture|domain)/)'
          TOUCHED=$(grep -E "$PROTECTED_REGEX" changed_files.txt || true)
          if [ -n "$TOUCHED" ]; then
            echo "Protected files touched:"
            echo "$TOUCHED"
            if [[ "$PR_BODY" != *"APPROVED-BY-ARCHITECT"* ]]; then
              echo "::error::PR touches protected clinical paths but lacks the 'APPROVED-BY-ARCHITECT' marker in the PR description. Do not merge without explicit architect approval."
              exit 1
            fi
          else
            echo "No protected paths touched."
          fi
EOF

# ---------------------------------------------------------------------------
# 8. Placeholder ADR index (content to be filled in next step)
# ---------------------------------------------------------------------------

cat > docs/architecture/README.md << 'EOF'
# Architecture Decision Records (ADR)

Each ADR captures one frozen architectural or clinical-safety decision:
context, decision, consequences. ADRs are the single source of truth
referenced by every task in `/tasks`.

Planned:
- ADR-000 — Roles and workflow
- ADR-001 — Independent applications, shared minimal core
- ADR-002 — Patient Registry as single source of identity
- ADR-003 — Data Contract versioning strategy
- ADR-004 — Clinical rules classification (data / code / hybrid)
- ADR-005 — Provenance: two-level (summary / detailed trace)
- ADR-006 — Immutability of clinical facts + correction events
EOF

cat > docs/domain/README.md << 'EOF'
# Domain models & data contracts

- `oncocardio-domain-model-v1.md` — OncoCardio core entities (planned)
- `echostudy-export-v1.md` — EchoExpert → OncoCardio data contract (planned)
EOF

echo "==> Done."
echo ""
echo "Next steps:"
echo "  1. Review the generated files (especially CODEOWNERS username)."
echo "  2. git add . && git commit -m 'chore: bootstrap repo structure, CODEOWNERS, guardrails'"
echo "  3. git push"
echo "  4. GitHub repo Settings -> Branches -> protect 'main':"
echo "     - Require a pull request before merging"
echo "     - Require status checks to pass -> select 'check-protected-paths'"
echo "     - Require review from Code Owners (if available on your plan)"

---
name: changes-workflow
description: Plan a small change (proposal, specification, technical plan, QA plan, tasks) or build it, one task at a time. Use when starting, planning or building a feature, bug fix or refactoring that is documented in a change folder.
---

# Changes workflow

Each change is planned in its own folder, `changes/<type>-<short-name>/`, with one of these types: `feat` (new functionality), `fix` (bug fix), `refactor` (code restructured, behavior the same), `perf` (faster or lighter), `test` (tests only), `docs` (documentation only) or `chore` (maintenance, such as tooling, templates or workflow). Its documents are written in this order:

1. `proposal.md`: the user story, why the change is needed, and what we would like to have.
2. `spec.md`: functional and non-functional requirements, acceptance criteria, boundaries and constraints, in plain language.
3. `plan.md`: what must exist to meet each functional requirement, in the order to build them, and the technical decisions.

Each repository where the change is built gets `./changes/<type>-<short-name>/` on the change's branch, committed with the code, with:

4. `qa.md`: how the acceptance criteria built in this repository are verified, written before building. The results go in the pull request.
5. `tasks.md`: the tasks for the functional requirement entries built in this repository, built one at a time.

The templates for the first three are in `changes/_templates/`, for the last two in `./changes/_templates/`. Follow them exactly.

- To plan a change, or add its next document, read [planning.md](planning.md).
- To build a change, read [implementing.md](implementing.md).

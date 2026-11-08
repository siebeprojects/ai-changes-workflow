---
name: changes-workflow
description: Plan a small change (proposal, specification, technical plan, QA plan, tasks) or implement one approved task of it. Use when starting, planning or building a feature, bug fix or refactoring that is documented in a change folder.
---

# Changes workflow

Each change has its own folder, `changes/<type>-<short-name>/`, with a type such as `feat`, `fix` or `refactor`. Its documents are written in this order:

1. `proposal.md`: the user story, why the change is needed, and what we would like to have.
2. `spec.md`: functional and non-functional requirements, acceptance criteria, boundaries and constraints, in plain language.
3. `plan.md`: what must exist to meet each functional requirement, and the technical decisions.
4. `qa.md`: how each acceptance criterion is verified, and the results.
5. `tasks/`: one small file per task, numbered in the order to do them.

The templates are in `changes/_templates/`. Follow them exactly.

- To plan a change, or add its next document, read [planning.md](planning.md).
- To implement a task, read [implementing.md](implementing.md).

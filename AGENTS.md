# Engineering Agreement

## Communication and approval
- Before changing implementation code, explain the proposed changes and wait for explicit approval.
- Reading files, inspecting code, and discussing designs do not require approval.
- Ask focused questions when requirements are unclear. Keep communication concise.

## Implementation
- Work in small, independently verifiable increments.
- Follow existing architecture and code conventions; avoid unrelated changes and unnecessary dependencies.
- Add or update tests for behavioral changes; run relevant tests.
- Do not create branches, commit, or push without permission.

## Completion
- Summarize changed files, tests run and their results, and outstanding risks or questions.

<!-- changes-workflow:start -->
## Change documentation
- Keep each independent change (new feature, bug fix, refactoring, or other work) under `changes/<type>-<short-name>/`, with one of these types: `feat` (new functionality), `fix` (bug fix), `refactor` (code restructured, behavior the same), `perf` (faster or lighter), `test` (tests only), `docs` (documentation only) or `chore` (maintenance, such as tooling, templates or workflow). Branches and pull requests use the same type.
- `proposal.md` gives the user story, why the change is needed, and what we would like to have, in plain language.
- `spec.md` defines the functional and non-functional requirements, acceptance criteria, boundaries and constraints, in plain language. How it is built goes in `plan.md`.
- `plan.md` states what must exist to meet each functional requirement, in the order to build them, with no explanations or steps, and records the technical decisions. An agent builds one functional requirement entry at a time.
- `qa.md` defines upfront how the change is verified. The results go in the pull request.
- Use `changes/_templates/` when starting a new change.
- Follow the templates exactly: add no sections or fields, and keep content in the section it belongs to. If something has no place, or the template is wrong, raise it and propose a template change.
- Keep documentation proportional to the size of the change.
- Do not implement a change until its proposal, specification, plan, and QA plan have been reviewed and approved.
- Follow the approved `proposal.md`, `spec.md` and `plan.md`. If a deviation is needed, stop and ask for approval.
- Use the `changes-workflow` skill to plan a change or to build it.
<!-- changes-workflow:end -->

# Implementing a change

## Workflow

1. Read `AGENTS.md` and the change's `proposal.md`, `spec.md`, `plan.md`, and `qa.md`. Ask which functional requirement entry of the plan to build if it is not given; otherwise take the next one in the plan.
2. Confirm that the proposal, specification, technical plan, and QA plan are approved and that material questions are resolved. If approval is unclear, ask before coding.
3. Inspect the relevant existing code, identify reusable functionality, and explain the proposed small change. Wait for explicit approval before modifying code.
4. Build only that functional requirement entry, following the approved technical approach and the coding principles below.
5. Write or update the relevant automated tests, preferably before implementation when practical. Include normal behavior, error cases, and boundaries identified in `qa.md`.
6. Run the relevant tests and checks. Do not claim that a test passed unless it was actually executed.
7. Report changed files, test results, outstanding issues, and any deviations. Update the status of each item in Test Coverage in `qa.md`.
8. Stop and request approval before changing the approved proposal, specification, architecture, or technical approach. Do not commit without permission.

## Coding Principles

### Solving the problem correctly

- What we build works in every case, with no known edge cases. Check each place the feature can be used, such as on its own line, inside a sentence and inside a link, and only propose a solution that works in all of them. When no solution does, say so plainly and ask.
- Build only what was asked. Do not add new functionality while solving a problem; propose it separately.
- Find the root cause before choosing a fix, and fix it where it starts, not where it shows.
- Find out why the existing code is built the way it is, from the code, its comments and its history, before changing it. Ask when the reason is unclear.
- Check how the libraries, frameworks and standards involved intend the problem to be solved, and follow that.
- The same input always gives the same result. Do not add conditions that guess intent from the surroundings; when two different results are needed, give each its own explicit input. For example, a Markdown image that renders as a figure when it is alone in a paragraph and as an image inside a sentence is wrong; an image syntax and a separate figure tag are right.
- A fix that hides the symptom is not a fix: no suppressed errors, special cases or workarounds.
- When the correct solution changes the approved proposal, specification, plan or existing behavior, stop and propose it, instead of building a workaround that fits the plan.

### Readability and simplicity

- Write small, focused methods and functions with one clear responsibility.
- Avoid deep nesting of `if` statements and loops. Prefer guard clauses, early returns, and well-named helper functions where they improve clarity.
- Keep the main execution path easy to follow.
- Use descriptive names for variables, functions, classes, and interfaces.
- Prefer straightforward code over clever shortcuts or unnecessary abstractions.
- Keep parameter lists manageable; introduce a parameter object only when it improves the interface.
- Explain *why* in comments when intent is not apparent; avoid comments that merely restate code.

### Architecture and future changes

- Preserve clear responsibilities and boundaries between components.
- Favor high cohesion and low coupling; avoid leaking implementation details across interfaces.
- Reuse existing code and established patterns rather than duplicating business logic.
- Avoid hardcoded assumptions that would obstruct likely future features.
- Design for reasonable extension without implementing speculative functionality.
- Keep changes localized and preserve existing behavior unless the approved specification requires otherwise.
- Do not optimize only for making the current change work: leave the codebase easy to understand, maintain, and extend for the next change.

### Continuous code quality

- Refactor within the approved scope when needed to keep the implementation clean.
- Do not knowingly introduce avoidable technical debt just to complete the change faster.
- Keep changes small, reviewable, and independently testable.
- Avoid unrelated refactoring and new dependencies unless explicitly approved.
- Prefer clear, testable interfaces and explicit error handling.

### Testing and verification

- Follow the test strategy and test coverage in `qa.md`.
- Prefer testing observable behavior rather than private implementation details.
- Include failure paths and relevant edge cases.
- Run relevant regression tests to protect existing functionality.
- Record what was tested, what passed, what failed, and what could not be run.

## Completion Criteria

A change is complete only when:

- It satisfies the approved `proposal.md`, `spec.md` and `plan.md`.
- It works in every case it can be used in, verified, with no known edge cases.
- Relevant `qa.md` checks have been implemented and executed, or any exceptions are explicitly reported.
- The implementation is readable, maintainable, and does not unnecessarily complicate future features.
- Deviations, risks, and remaining issues have been reported.

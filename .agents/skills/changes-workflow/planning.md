# Planning a change

1. Read `AGENTS.md` and inspect relevant existing code and architecture.
2. Ask for the change type, short name and objective if they are missing.
3. Create `changes/<type>-<short-name>/`. Copy each template from `changes/_templates/` only when you start drafting that document.
4. Draft `proposal.md` in plain language: the user story, why the change is needed, and what we would like to have, at a high level.
5. Ask for review and approval of the proposal.
6. Draft `spec.md` in plain language, with observable requirements and testable acceptance criteria that cover the proposal. Surface important open questions.
7. Ask for review and approval of the specification before treating it as final.
8. Design the correct solution, following "Solving the problem correctly" in [implementing.md](implementing.md): for a bug, find the root cause, why the code is built that way, and how the tools involved intend it. Then draft `plan.md` stating what must exist to meet each functional requirement, with the entries in the order to build them, as plain statements with no explanations or steps. When the change is built in more than one repository, name the repositories under Approach. Record each real choice between options under Decisions.
9. Ask for review and approval of the plan.
10. In each repository where the change is built, on the branch `<type>-<short-name>` (ask before creating it), create `./changes/<type>-<short-name>/` and copy the templates from `./changes/_templates/`:
    - Draft `qa.md` with test coverage for the acceptance criteria and applicable non-functional requirements built in this repository.
    - Draft `tasks.md` with small tasks, in the order to build them, for the functional requirement entries of `plan.md` built in this repository.
    - Name the change as the repository and path of its planning folder, such as `my-changes-store/changes/feat-short-name`, as plain text, not as a link. The planning folder, the branches and the folders in each repository all share the change name.
11. Ask for review and approval of the QA plan and the tasks. Do not implement code.

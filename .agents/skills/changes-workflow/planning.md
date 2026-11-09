# Planning a change

1. Read `AGENTS.md` and inspect relevant existing code and architecture.
2. Ask for the change type, short name and objective if they are missing.
3. Create `changes/<type>-<short-name>/`. Copy each template from `changes/_templates/` only when you start drafting that document.
4. Draft `proposal.md` in plain language: the user story, why the change is needed, and what we would like to have, at a high level.
5. Ask for review and approval of the proposal.
6. Draft `spec.md` in plain language, with observable requirements and testable acceptance criteria that cover the proposal. Surface important open questions.
7. Ask for review and approval of the specification before treating it as final.
8. Draft `plan.md` stating what must exist to meet each functional requirement, with the entries in the order to build them, as plain statements with no explanations or steps. Record each real choice between options under Decisions.
9. Ask for review and approval of the plan.
10. Draft `qa.md` with test coverage for the acceptance criteria and applicable non-functional requirements.
11. Ask for review and approval of the QA plan. Do not implement code.

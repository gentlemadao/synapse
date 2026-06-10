# Project Workflow

## Guiding Principles

1. **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2. **The Tech Stack is Deliberate:** Changes to the tech stack must be documented in `tech-stack.md` *before* implementation
3. **Test-Driven Development:** Write unit tests before implementing functionality
4. **High Code Coverage:** Aim for >80% code coverage for all modules
5. **User Experience First:** Every decision should prioritize user experience
6. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure single execution.

## Task Workflow

All tasks follow a strict lifecycle:

### Standard Task Workflow

1. **Select Task:** Choose the next available task from `plan.md` in sequential order
2. **Mark In Progress:** Before beginning work, edit `plan.md` and change the task from `[ ]` to `[~]`
3. **Write Failing Tests (Red Phase):** Create failing unit tests and confirm failure.
4. **Implement to Pass Tests (Green Phase):** Write application code to make tests pass.
5. **Refactor:** Clean up and verify tests still pass.
6. **Verify Coverage:** Target >80% code coverage.
7. **Document Deviations:** Update `tech-stack.md` if design changes.
8. **Commit Code Changes.**
9. **Attach Task Summary with Git Notes.**
10. **Get and Record Task Commit SHA.**
11. **Commit Plan Update.**

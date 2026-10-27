# Commit style

When a repository does not define another convention, use lowercase
Conventional Commit subjects:

```text
type(scope): description
```

- Prefer a meaningful scope identifying the affected component.
- Omit the scope only for a genuinely repository-wide change without one clear
  owner.
- Use one of `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`,
  `revert`, `style`, or `test`.
- Add `!` before the colon only for a breaking change.
- Keep the subject under 72 characters with a concise, lowercase, imperative
  description and no final period.
- For simple changes, use only the subject.
- For material changes, prefer a concise bullet-list body:
  - use 2-5 - bullets
  - use lowercase sentence fragments, except where casing is semantically
    significant
  - start with an imperative verb when practical
  - describe behavior, rationale, or consequences rather than changed files
  - do not repeat the subject
  - omit final periods for short single-sentence bullets
  - wrap body lines at 72 characters

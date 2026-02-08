# Self-Review Standards

Be direct and honest. When my code or architecture is flawed - explain why without softening. When I'm overcomplicating something - push for simplicity.

Apply the same lens to your own work:
- Question whether your changes actually solve the stated problem
- Verify that refactored components still integrate correctly
- Challenge your own assumptions about requirements

## Implementation vs. Analysis

- **Analysis requests** ("suggest", "how to fix?", "analyze", "review", "investigate"): Provide findings and recommendations only - no code changes
- **Implementation requests** ("fix", "implement", "change", "update"): Make the changes
- **Ambiguous requests**: Ask explicitly before proceeding

When asked to implement a feature, FIRST search for existing implementations or patterns. Report findings before proposing new solutions.

## Code Quality

- Start with the simplest solution that solves the problem
- Add complexity only when explicitly requested or absolutely necessary
- Prefer simple parameter flags over complex configuration objects
- Use straightforward conditional logic over elaborate abstraction layers
- Avoid premature optimization or flexibility not currently needed
- When refactoring APIs, validate consuming code still works
- Never create new files/services without checking if similar ones exist
- Don't add docstrings, comments, or type annotations to code you didn't change
- Simple problems get direct solutions, not lengthy analysis

## Testing

Default: TDD unless specified otherwise for a project.

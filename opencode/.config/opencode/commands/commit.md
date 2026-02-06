---
description: "Review staged changes, create commit message, and commit"
agent: "build"
---

Follow these steps to handle the commit process:

1. **Context Gathering**:
   - Status: !`git status`
   - History: !`git log --oneline -5`
   - Changes: !`git diff --staged`

2. **Analysis**:
   Analyze the changes above. Focus on the **intent** (the 'why') and not just the 'what'. 

3. **Message Generation**:
   Create a **Conventional Commit** message: `<type>(<scope>): <description>`.

4. **User Confirmation**:
   Present the proposed message and your reasoning. 
   **Wait for explicit user confirmation.**

5. **Execution**:
   If confirmed, run: `git commit -m "[PROPOSED MESSAGE]"`

**IMPORTANT**: Do not execute the commit until I say "yes" or "confirm".

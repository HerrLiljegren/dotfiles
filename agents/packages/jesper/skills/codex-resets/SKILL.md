---
name: codex-resets
description: Fetch and render the user's Codex reset credits from the ChatGPT rate-limit reset credits endpoint using ~/.codex/auth.json. Use when the user asks about Codex reset credits, reset credit expiry, available resets, redeemed reset status, or wants a safe Markdown table of Codex reset credits without exposing auth tokens or raw API data.
---

# Codex Resets

Fetch Codex reset credits and render only a sanitized Markdown table.

## Workflow

1. Run the bundled script:

   ```bash
   python /home/jesper/dotfiles/agents/packages/jesper/skills/codex-resets/scripts/fetch_reset_credits.py
   ```

2. Return the script output as-is unless the user asks for a shorter summary.

3. If the script fails, report only the safe error message. Do not inspect or print `~/.codex/auth.json`, tokens, API response bodies, or raw JSON to debug in the user-visible answer.

## Output Rules

- Render a Markdown table with these columns only:
  `Available credits`, `Status`, `Reset`, `Issued date`, `Expiry date`, `Days until expiry`, `Redeemed`.
- Read `credits[].granted_at` as the issued date.
- Read `credits[].expires_at` as the expiry date.
- Read `credits[].title` as the reset type.
- Use `credits[].redeemed_at` and `credits[].redeem_started_at` for redeemed status.
- Treat a credit as available only when it is not redeemed, redemption has not started, and the expiry date has not passed.
- Escape Markdown table control characters in rendered values.

## Safety Rules

- Never expose tokens, auth JSON, account IDs, credit IDs, profile user IDs, image URLs, or raw API responses.
- Never add debug logging that prints request headers, auth file content, response bodies, or full exceptions containing payloads.
- If extra fields are present in the API response, ignore them.
- If an expected field is missing, render an empty safe cell or a generic safe status rather than printing the object.

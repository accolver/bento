<!-- telos-metadata
id: L3:experience:error-recovery
level: 3
title: Error Recovery
parent: L4:purpose
children:
  - L2:contract:service-ai-gateway
  - L2:contract:component-heal-banner
-->

# L3: Error Recovery

## Overview

When a command fails, the AI automatically analyzes the error and offers a
one-tap fix, dramatically reducing the time to resolve common issues like
permission errors, missing packages, or syntax mistakes.

## User Story

As a **user whose command just failed**, I want to **see an automatic fix
suggestion with explanation** so that **I can resolve the error with one tap
instead of googling the solution**.

## Journey Steps

1. **Command Fails**
   - User action: Executes a command that returns non-zero exit code
   - System response: Block shows red "Failed" state with exit code and stderr
   - Success criteria: Error state is visually distinct, stderr visible

2. **AI Analyzes Error**
   - User action: None (automatic)
   - System response: AI processes command + stderr within 500ms, generates fix
   - Success criteria: "Fix Available" banner appears on the block

3. **Review Fix Suggestion**
   - User action: Taps "Fix Available" banner or heal button
   - System response: Shows modal with error explanation and suggested fix
   - Success criteria: Clear explanation + fixed command visible

4. **Understand the Fix**
   - User action: Reads explanation of what went wrong and how fix addresses it
   - System response: Displays fix type (add sudo, install package, fix syntax,
     etc.)
   - Success criteria: User understands why the fix works

5. **Apply Fix**
   - User action: Taps "Apply Fix" button
   - System response: Executes fixed command, creates new block
   - Success criteria: New block shows command running

6. **Verify Success**
   - User action: Reviews new block output
   - System response: Block shows success state, AI logs successful healing
   - Success criteria: Fixed command succeeds, healing recorded for learning

## Common Fix Types

| Fix Type            | Example Error             | Suggested Fix                             |
| ------------------- | ------------------------- | ----------------------------------------- |
| `addSudo`           | EACCES permission denied  | Prepend `sudo` to command                 |
| `installPackage`    | command not found         | `apt install <package>` or `brew install` |
| `fixSyntax`         | syntax error near...      | Corrected command syntax                  |
| `changePermissions` | Permission denied on file | `chmod` command                           |
| `createDirectory`   | No such file or directory | `mkdir -p` for path                       |
| `fixPath`           | File not found            | Corrected file path                       |

## Edge Cases

- **No fix available**: Show "Unable to suggest fix" with option to search
  online
- **Fix requires confirmation**: Dangerous fixes (sudo rm, chmod 777) require
  extra tap
- **Fix fails too**: Offer to try alternative fix or escalate to full AI
  assistance
- **Offline**: Local AI attempts fix; if insufficient, queues for cloud analysis
- **Multiple potential fixes**: Show top suggestion with "See alternatives"
  option

## Privacy Considerations

- **Error healing is local-first**: Stderr may contain sensitive info, process
  on-device
- **No cloud logging of errors**: Error content never sent to analytics
- **Opt-in for cloud healing**: User must explicitly enable cloud-based error
  analysis

## Analytics Events

- `error_detected`: Command failed with non-zero exit code
- `heal_suggestion_generated`: AI successfully generated a fix
- `heal_suggestion_shown`: User viewed the fix suggestion
- `heal_applied`: User applied the suggested fix
- `heal_succeeded`: Applied fix resulted in success
- `heal_failed`: Applied fix still failed
- `heal_dismissed`: User dismissed fix without applying

## Success Metrics

- Fix suggestion rate: > 80% of common errors get suggestions
- Fix success rate: > 70% of applied fixes resolve the issue
- Time to fix suggestion: < 500ms (local AI)
- User adoption: > 50% of shown fixes are applied

## Related Specs

- L2: [To be defined - Error healing contract]
- L2: [To be defined - Block status contract]
- L1: [To be defined - healError function]
- L1: [To be defined - Error pattern matching]

<!-- telos-metadata
id: L3:experience:ai-command-assistance
level: 3
title: AI Command Assistance
parent: L4:purpose
children:
  - L2:contract:service-ai-gateway
  - L2:contract:component-command-ribbon
  - L2:contract:component-ghostwriter-modal
-->

# L3: AI Command Assistance

## Overview

A user who doesn't remember exact CLI syntax describes what they want in natural
language, and the AI Ghostwriter generates the correct command with explanation.

## User Story

As a **developer unfamiliar with complex CLI syntax**, I want to **describe my
intent in plain English and get the correct command** so that **I can execute
tasks without memorizing arcane flags and options**.

## Journey Steps

1. **Invoke AI Ghostwriter**
   - User action: Taps the AI button (🤖) in the command ribbon
   - System response: Opens Ghostwriter modal with text input field
   - Success criteria: Modal appears with focus on input, keyboard ready

2. **Describe Intent**
   - User action: Types "find all log files larger than 100MB modified today"
   - System response: Shows typing indicator while AI processes
   - Success criteria: Input accepted, processing begins within 200ms

3. **Review Suggestion**
   - User action: Views the suggested command
   - System response: Displays
     `find /var/log -name "*.log" -size +100M -mtime 0` with explanation
   - Success criteria: Command shown with confidence indicator and brief
     explanation

4. **Refine if Needed**
   - User action: Taps "Edit" to modify, or "Regenerate" for alternative
   - System response: Allows inline editing or generates new suggestion
   - Success criteria: User can tweak command or get alternatives

5. **Execute Command**
   - User action: Taps "Execute" button
   - System response: Inserts command into terminal, creates new block, runs it
   - Success criteria: Block shows command executing with output

6. **Learn from Result**
   - User action: Reviews output in the block
   - System response: Command saved to history, AI learns from acceptance
   - Success criteria: Future similar requests improve in accuracy

## Edge Cases

- **Ambiguous request**: AI asks clarifying question before generating
- **Dangerous command**: Shows warning for destructive operations (rm -rf, DROP
  TABLE)
- **No network (cloud AI)**: Falls back to local LLM with potentially reduced
  accuracy
- **AI unavailable**: Shows error, offers to search command history instead
- **Multiple interpretations**: Shows top 3 alternatives with explanations

## Privacy Considerations

- **Local-first**: Simple commands processed by on-device LLM
- **Cloud consent**: Complex commands may use cloud AI with explicit user
  consent
- **No sensitive data**: Commands containing passwords/keys processed locally
  only
- **Opt-out available**: User can disable cloud AI entirely in settings

## Analytics Events

- `ghostwriter_opened`: When AI modal is invoked
- `ghostwriter_query_submitted`: Natural language query sent to AI
- `ghostwriter_suggestion_accepted`: User executes suggested command
- `ghostwriter_suggestion_rejected`: User dismisses or regenerates
- `ghostwriter_suggestion_edited`: User modifies before executing
- `ghostwriter_provider_used`: Track local vs cloud AI usage

## Success Metrics

- AI suggestion acceptance rate: > 60%
- Time from query to suggestion: < 2 seconds (local), < 5 seconds (cloud)
- User edits required: < 20% of accepted suggestions
- Repeat queries (same intent): < 10% (indicates learning)

## Related Specs

- L2: [To be defined - AI Gateway contract]
- L2: [To be defined - Ghostwriter UI contract]
- L1: [To be defined - generateCommand function]
- L1: [To be defined - Local LLM inference]

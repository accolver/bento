<!-- telos-metadata
id: L3:experience:incident-response
level: 3
title: Incident Response
parent: L4:purpose
children:
  - L2:contract:service-session
  - L2:contract:service-block
  - L2:contract:component-block-widget
-->

# L3: Incident Response

## Overview

An on-call engineer receives an alert while away from their desk and needs to
quickly diagnose and resolve production issues using only their mobile device.

## User Story

As an **on-call engineer**, I want to **quickly SSH into production servers and
navigate logs during incidents** so that **I can resolve P1 issues as
effectively from my phone as from my laptop**.

## Journey Steps

1. **Receive Alert**
   - User action: Receives PagerDuty/OpsGenie notification on phone
   - System response: N/A (external trigger)
   - Success criteria: User decides to open Bento

2. **Quick Connect**
   - User action: Opens Bento and taps saved "prod-web-01" connection
   - System response: Connects via Mosh within 3 seconds, restores previous
     session context
   - Success criteria: Terminal is ready for input with previous blocks visible

3. **Navigate to Logs**
   - User action: Uses command ribbon to quickly type `tail -f /var/log/app.log`
   - System response: Creates new block, streams log output in real-time
   - Success criteria: Block shows "Running" state with live output

4. **Search for Errors**
   - User action: Taps search icon on block, enters "ERROR" or "Exception"
   - System response: Highlights all matches, shows match count, enables
     navigation
   - Success criteria: User can jump between error occurrences

5. **Execute Runbook Command**
   - User action: Selects saved snippet or uses AI to generate restart command
   - System response: Shows command preview, executes on confirmation
   - Success criteria: Service restarts, block shows success state

6. **Verify Resolution**
   - User action: Checks logs again, runs health check command
   - System response: New blocks show healthy output, AI summarizes "Service
     recovered"
   - Success criteria: User confirms incident resolved

7. **Network Transition**
   - User action: Moves from WiFi to cellular while commuting
   - System response: Mosh maintains session seamlessly, no reconnection needed
   - Success criteria: No interruption to terminal session

## Edge Cases

- **Connection fails**: Show clear error message with retry button and fallback
  to SSH
- **Server unreachable**: Offer to ping host, check Tailscale status, or try
  jump host
- **Session expired**: Prompt to reconnect, restore block history from local
  database
- **High latency**: Show latency indicator, Mosh handles gracefully with local
  echo

## Analytics Events

- `incident_session_started`: When user connects during likely incident
  (time-based heuristic)
- `command_executed_during_incident`: Track commands run in incident sessions
- `incident_resolved`: When user marks incident complete or disconnects after
  success
- `network_transition_survived`: When Mosh maintains session through network
  change

## Success Metrics

- Time from app open to first command: < 5 seconds
- Session survival rate on network change: 99.9%
- Commands executed per incident session: Track average

## Related Specs

- L2: [To be defined - Session connection contract]
- L2: [To be defined - Block management contract]
- L2: [To be defined - Search contract]
- L1: [To be defined - Mosh connection functions]

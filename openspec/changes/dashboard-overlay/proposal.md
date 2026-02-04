# Proposal: Dashboard Overlay

## Why

Traditional TUI apps like htop display ASCII charts that are hard to read on
mobile. The Dashboard Overlay transforms TUI output into native Flutter
widgets - real charts with touch interaction. This makes monitoring data
glanceable and actionable.

## What Changes

- Implement TUI detection for htop, top, nvidia-smi, etc.
- Create ProcessMonitor widget with CPU/memory charts
- Create GPUMonitor widget with utilization/temperature
- Add real-time update streaming
- Implement toggle between dashboard and raw terminal view

## Phase

**Phase 3 - Visualization** (Months 8-10)

## Priority

**P0 - Must Have**

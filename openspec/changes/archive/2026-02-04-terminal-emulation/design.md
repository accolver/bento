# Design: Terminal Emulation

## Context

Bento requires GPU-accelerated terminal emulation to deliver a responsive mobile
terminal experience. The `xterm` Flutter package provides this capability with
60fps rendering, full ANSI support, and efficient memory management.

Current state: The scaffold is complete with Clean Architecture structure,
Riverpod state management, and navigation. We need to add the core terminal
feature that will serve as the foundation for SSH sessions and semantic blocks.

Constraints:

- Must work on both iOS and Android
- Must handle variable screen sizes and orientations
- Must support soft keyboard input with IME
- Must integrate with future SSH connectivity feature

## Goals / Non-Goals

**Goals:**

- Integrate xterm package as the terminal rendering engine
- Support full 256-color ANSI escape sequences
- Handle terminal resize events properly
- Configure appropriate fonts for terminal display
- Create reusable TerminalView widget
- Manage terminal state with Riverpod
- Support text selection and clipboard operations

**Non-Goals:**

- SSH connectivity (separate change: ssh-connectivity)
- Semantic block parsing (separate change: semantic-blocks)
- Multiple sessions/tabs (separate change: session-tabs)
- Custom themes beyond light/dark (separate change: theme-system)

## Decisions

### D1: Use xterm package directly

**Decision:** Use the `xterm` Flutter package (already in pubspec.yaml) as our
terminal emulator.

**Rationale:** xterm is the most mature Flutter terminal emulator with:

- GPU-accelerated rendering at 60fps
- Full VT100/VT220/xterm compatibility
- Active maintenance by terminal.studio (same team as dartssh2)
- Built-in support for text selection, scrollback, and clipboard

**Alternatives considered:**

- Custom terminal implementation: Too complex, would take months
- flutter_pty: Lower level, requires more work to integrate
- Web-based terminal in WebView: Poor performance, not native

### D2: Feature-based module structure

**Decision:** Create terminal feature at `lib/features/terminal/` following
Clean Architecture:

```
lib/features/terminal/
├── domain/
│   ├── entities/
│   │   └── terminal_config.dart
│   └── repositories/
│       └── terminal_repository.dart
├── data/
│   └── repositories/
│       └── terminal_repository_impl.dart
└── presentation/
    ├── providers/
    │   ├── terminal_provider.dart
    │   └── terminal_config_provider.dart
    ├── widgets/
    │   └── terminal_view.dart
    └── screens/
        └── terminal_screen.dart
```

**Rationale:** Follows established project patterns, keeps terminal logic
isolated, allows easy testing and future extension.

### D3: Riverpod for terminal state management

**Decision:** Use Riverpod providers to manage:

- Terminal instance lifecycle
- Terminal configuration (colors, fonts, dimensions)
- Input handling state

**Rationale:** Consistent with project architecture. Riverpod's
`ref.onDispose()` handles cleanup when terminal widgets unmount.

### D4: JetBrains Mono as default font

**Decision:** Bundle JetBrains Mono font for terminal display.

**Rationale:**

- Excellent readability at small sizes (mobile screens)
- Clear distinction between similar characters (0/O, 1/l/I)
- Free and open source (OFL license)
- Ligature support for code readability

**Alternatives considered:**

- Fira Code: Good but JetBrains Mono has better mobile readability
- System monospace: Inconsistent across devices
- Hack: Less distinctive character shapes

### D5: Terminal sizing strategy

**Decision:** Calculate terminal dimensions (cols/rows) based on available
widget size and font metrics. Recalculate on orientation change and keyboard
show/hide.

**Rationale:** Mobile screens vary widely. Fixed dimensions would waste space or
cause overflow. Dynamic sizing ensures optimal use of available space.

Implementation:

```dart
void _calculateDimensions(Size size) {
  final charWidth = _measureCharWidth(fontSize);
  final charHeight = fontSize * lineHeight;
  cols = (size.width / charWidth).floor();
  rows = (size.height / charHeight).floor();
}
```

### D6: Color scheme approach

**Decision:** Define terminal colors in
`lib/core/constants/terminal_colors.dart` with light and dark variants. Use
standard ANSI 256-color palette as base.

**Rationale:** Centralized color definitions allow:

- Easy theme switching
- Consistent colors across the app
- Future custom theme support

## Risks / Trade-offs

### R1: Font bundle size

**Risk:** Bundling JetBrains Mono increases app size (~200KB). **Mitigation:**
Acceptable trade-off for consistent terminal experience. Can subset font to
reduce size if needed.

### R2: Keyboard handling complexity

**Risk:** Soft keyboard on mobile has quirks (IME, autocorrect, key events).
**Mitigation:** xterm package handles most of this. May need platform-specific
fixes discovered during testing.

### R3: Memory usage with large scrollback

**Risk:** Large scrollback buffer (10,000 lines) can consume significant memory.
**Mitigation:** xterm uses efficient ring buffer. Can reduce scrollback on
low-memory devices. Monitor and adjust based on real-world usage.

### R4: Performance on older devices

**Risk:** GPU-accelerated rendering may struggle on very old devices.
**Mitigation:** xterm is optimized for mobile. Test on low-end devices. Can
reduce effects if needed.

## Open Questions

- Q1: Should we support custom fonts from user settings in MVP? **Tentative:**
  No, defer to theme-system change.

- Q2: What should happen when terminal is backgrounded? **Tentative:** Maintain
  state, let SSH change handle connection keepalive.

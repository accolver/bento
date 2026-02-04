<!-- telos-metadata
id: L2:contract:component-modifier-drawer
level: 2
title: Modifier Drawer Component
parent: L3:experience:session-management
children: []
-->

# L2: Modifier Drawer Component

## Overview

The Modifier Drawer provides access to special keys (Ctrl, Alt, Esc, Tab, Arrow
keys) through a gesture-activated panel, eliminating the need for awkward
keyboard combinations on touch devices.

## Interface

### Props

```dart
class ModifierDrawer extends ConsumerWidget {
  const ModifierDrawer({
    required this.isOpen,
    required this.modifierState,
    this.onModifierTap,
    this.onComboTap,
    this.onKeyTap,
    this.onClose,
    super.key,
  });

  /// Whether the drawer is currently open
  final bool isOpen;
  
  /// Current state of modifier keys
  final ModifierState modifierState;
  
  /// Called when a modifier key is tapped (toggles sticky state)
  final void Function(ModifierKey key)? onModifierTap;
  
  /// Called when a combo button is tapped (sends immediately)
  final void Function(String combo)? onComboTap;
  
  /// Called when a regular key is tapped (affected by modifiers)
  final void Function(String key)? onKeyTap;
  
  /// Called when drawer should close
  final VoidCallback? onClose;
}
```

### State Model

```dart
@freezed
class ModifierState with _$ModifierState {
  const factory ModifierState({
    @Default(false) bool ctrlActive,
    @Default(false) bool altActive,
    @Default(false) bool shiftActive,
    @Default(false) bool metaActive,
  }) = _ModifierState;
  
  bool get hasActiveModifier => 
      ctrlActive || altActive || shiftActive || metaActive;
}

enum ModifierKey { ctrl, alt, shift, meta }
```

## Visual Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    MODIFIER DRAWER                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ Esc  │  │ Tab  │  │ Ctrl │  │ Alt  │  │ Meta │          │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘          │
│                                                              │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  ↑   │  │  ↓   │  │  ←   │  │  →   │  │ Home │          │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘          │
│                                                              │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ End  │  │ PgUp │  │ PgDn │  │ Ins  │  │ Del  │          │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘          │
│                                                              │
│  COMBOS: [Ctrl+C] [Ctrl+D] [Ctrl+Z] [Ctrl+L] [Ctrl+R]      │
├─────────────────────────────────────────────────────────────┤
│                    [Drag down to close]                      │
└─────────────────────────────────────────────────────────────┘
```

## Behavior

### Modifier Keys (Sticky)

- Tap to activate (highlighted state)
- Next key press sends modifier + key
- Modifier auto-releases after key press
- Tap again to deactivate without sending

### Combo Buttons (Immediate)

- Single tap sends the combination immediately
- No sticky state needed
- Provides haptic feedback
- Common combos: Ctrl+C, Ctrl+D, Ctrl+Z, Ctrl+L, Ctrl+R, Ctrl+A

### Regular Keys

- Arrow keys, Home, End, PgUp, PgDn, Ins, Del
- Affected by active modifiers
- Esc and Tab send immediately (common use)

### Drawer Activation

| Gesture              | Action                       |
| -------------------- | ---------------------------- |
| Swipe up from bottom | Open drawer                  |
| Swipe down on drawer | Close drawer                 |
| Tap outside drawer   | Close drawer                 |
| Tap key              | Send key (drawer stays open) |
| Double-tap combo     | Send combo and close         |

### Customizable Combos

Users can configure which combos appear in the quick-access row:

- Default: Ctrl+C, Ctrl+D, Ctrl+Z, Ctrl+L, Ctrl+R
- Can add: Ctrl+A, Ctrl+W, Ctrl+K, Ctrl+U, etc.

## Visual Feedback

| State             | Appearance                        |
| ----------------- | --------------------------------- |
| Modifier inactive | Default button style              |
| Modifier active   | Highlighted/pressed, accent color |
| Key pressed       | Brief press animation             |
| Combo sent        | Ripple effect + haptic            |

### Haptic Patterns

```dart
void onModifierTap(ModifierKey key) {
  HapticFeedback.selectionClick();
}

void onComboTap(String combo) {
  HapticFeedback.mediumImpact();
}

void onKeyTap(String key) {
  HapticFeedback.lightImpact();
}
```

## Animations

| Animation       | Duration | Curve        |
| --------------- | -------- | ------------ |
| Drawer open     | 250ms    | easeOutQuart |
| Drawer close    | 200ms    | easeInQuart  |
| Modifier toggle | 100ms    | easeOut      |
| Button press    | 50ms     | linear       |

## Accessibility

- All keys have semantic labels
- VoiceOver announces modifier state
- Minimum tap target: 48x48 points
- High contrast borders for visibility

## Related Specs

- L3: [Session Management](../L3-experience/session-management.md)
- L3: [Incident Response](../L3-experience/incident-response.md)
- L2: [Session Service](service-session.md)
- L1: [To be defined - Key code mapper]
- L1: [To be defined - Haptic feedback patterns]

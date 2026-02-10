# AI FAB Panel - Implementation Tasks

## 1. Project Structure Setup

- [x] 1.1 Create AI feature module directory structure at lib/features/ai/
- [x] 1.2 Create domain entities: AiSuggestion and AiPrivacyMode
- [x] 1.3 Add AI color constants to theme system (aiPrimary, aiSecondary,
      aiGlow)

## 2. Mock AI Service

- [x] 2.1 Create MockAiService class with generateCommand method
- [x] 2.2 Implement keyword-based suggestion matching (list, find, show, delete,
      etc.)
- [x] 2.3 Add configurable delay to simulate AI processing time

## 3. State Management (Providers)

- [x] 3.1 Create aiPanelVisibleProvider for panel open/close state
- [x] 3.2 Create aiInputProvider for natural language input text
- [x] 3.3 Create aiSuggestionProvider that watches input and returns suggestion
- [x] 3.4 Create aiPrivacyModeProvider for local/cloud indicator

## 4. AI FAB Widget

- [x] 4.1 Create AiFab widget with gradient background and chat icon
- [x] 4.2 Implement pulse animation with AnimationController
- [x] 4.3 Add haptic feedback on tap
- [x] 4.4 Implement visibility control based on view mode and TUI mode

## 5. AI Ghostwriter Panel Widget

- [x] 5.1 Create AiGhostwriterPanel widget as bottom sheet content
- [x] 5.2 Implement panel header with title, AI icon, and privacy indicator
- [x] 5.3 Create natural language input field with auto-focus
- [x] 5.4 Add close button and swipe-to-dismiss handling

## 6. AI Command Suggestion Widget

- [x] 6.1 Create AiCommandSuggestion widget for displaying suggestions
- [x] 6.2 Implement command display with monospace font and dark background
- [x] 6.3 Add confidence indicator with color coding (green/yellow/orange)
- [x] 6.4 Add explanation text with AI accent border
- [x] 6.5 Implement loading state with shimmer animation
- [x] 6.6 Implement error state with "Try Again" button

## 7. Panel Actions

- [x] 7.1 Implement Regenerate button that triggers new suggestion
- [x] 7.2 Implement Edit button that copies command to editable input
- [x] 7.3 Implement Copy button with clipboard and toast confirmation
- [x] 7.4 Implement Execute button that sends command to terminal

## 8. Terminal Screen Integration

- [x] 8.1 Add Stack wrapper to TerminalScreen for FAB overlay
- [x] 8.2 Add AiFab to TerminalScreen with proper positioning
- [x] 8.3 Implement showModalBottomSheet trigger from FAB tap
- [x] 8.4 Wire Execute action to terminal command execution
- [x] 8.5 Handle panel dismissal and state cleanup

## 9. Testing

- [x] 9.1 Write widget tests for AiFab visibility logic
- [ ] 9.2 Write widget tests for AiGhostwriterPanel interactions
- [x] 9.3 Write unit tests for MockAiService suggestion generation
- [ ] 9.4 Write integration test for FAB -> Panel -> Execute flow

## 10. Accessibility & Polish

- [x] 10.1 Add semantic labels for screen reader support
- [x] 10.2 Respect MediaQuery.disableAnimations for pulse animation
- [ ] 10.3 Test keyboard interaction on iOS and Android
- [ ] 10.4 Verify 60fps animation performance on mid-range device

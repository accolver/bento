<!-- telos-metadata
id: L1:function:lib/features/terminal/domain/usecases:parseTappableElements
level: 1
title: parseTappableElements
parent: L2:contract:service-block
-->

# L1: parseTappableElements

## Purpose

Parses terminal output to identify interactive elements (IP addresses, file
paths, URLs, JSON, etc.) that can be tapped for contextual actions.

## Signature

```dart
List<TappableElement> parseTappableElements(String output);
```

## Parameters

| Name   | Type   | Description                  |
| ------ | ------ | ---------------------------- |
| output | String | Raw terminal output to parse |

## Returns

| Type                  | Description                                                              |
| --------------------- | ------------------------------------------------------------------------ |
| List<TappableElement> | List of detected tappable elements with positions, sorted by startOffset |

## TDD Scenarios

### Scenario: Detect IPv4 address

```gherkin
Given output contains "Server running at 192.168.1.100:8080"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.ipAddress
And element.value equals "192.168.1.100"
And element.startOffset equals 19
And element.endOffset equals 32
```

### Scenario: Detect multiple IPv4 addresses

```gherkin
Given output contains "Source: 10.0.0.1 -> Destination: 10.0.0.2"
When parseTappableElements is called
Then result contains 2 TappableElements
And both elements have type TappableType.ipAddress
And elements are sorted by startOffset
```

### Scenario: Detect IPv6 address

```gherkin
Given output contains "Listening on ::1 and 2001:db8::1"
When parseTappableElements is called
Then result contains TappableElements for both addresses
And element.type equals TappableType.ipAddress
```

### Scenario: Detect Unix file path

```gherkin
Given output contains "Error in /var/log/nginx/error.log at line 42"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.filePath
And element.value equals "/var/log/nginx/error.log"
```

### Scenario: Detect file path with spaces (quoted)

```gherkin
Given output contains "Reading '/home/user/My Documents/file.txt'"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.filePath
And element.value equals "/home/user/My Documents/file.txt"
```

### Scenario: Detect HTTP URL

```gherkin
Given output contains "Visit https://example.com/api/v1/users for docs"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.url
And element.value equals "https://example.com/api/v1/users"
```

### Scenario: Detect URL with query parameters

```gherkin
Given output contains "Redirect to https://example.com/auth?token=abc&redirect=/home"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.url
And element.value equals "https://example.com/auth?token=abc&redirect=/home"
```

### Scenario: Detect JSON object

```gherkin
Given output contains 'Response: {"status": "ok", "count": 42}'
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.json
And element.value equals '{"status": "ok", "count": 42}'
```

### Scenario: Detect nested JSON

```gherkin
Given output contains '{"user": {"name": "John", "roles": ["admin"]}}'
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.json
And element.value contains the entire nested structure
```

### Scenario: Detect email address

```gherkin
Given output contains "Contact: admin@example.com for support"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.email
And element.value equals "admin@example.com"
```

### Scenario: Detect UUID

```gherkin
Given output contains "Request ID: 550e8400-e29b-41d4-a716-446655440000"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.uuid
And element.value equals "550e8400-e29b-41d4-a716-446655440000"
```

### Scenario: Detect git commit hash

```gherkin
Given output contains "commit a1b2c3d4e5f6789 (HEAD -> main)"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.gitCommit
And element.value equals "a1b2c3d4e5f6789"
```

### Scenario: Detect short git commit hash

```gherkin
Given output contains "Merged a1b2c3d into main"
When parseTappableElements is called
Then result contains a TappableElement
And element.type equals TappableType.gitCommit
And element.value equals "a1b2c3d"
```

### Scenario: No tappable elements

```gherkin
Given output contains "Operation completed successfully"
When parseTappableElements is called
Then result is an empty list
```

### Scenario: Overlapping patterns - priority

```gherkin
Given output contains "http://192.168.1.1/admin"
When parseTappableElements is called
Then result contains one TappableElement
And element.type equals TappableType.url
And the URL takes priority over the embedded IP
```

### Scenario: Large output performance

```gherkin
Given output contains 10000 lines of log data
When parseTappableElements is called
Then result is returned within 100ms
And all valid elements are detected
```

### Scenario: Handle ANSI escape codes

```gherkin
Given output contains "\x1b[32m192.168.1.1\x1b[0m" (colored text)
When parseTappableElements is called
Then result contains a TappableElement
And element.value equals "192.168.1.1" (without ANSI codes)
And element offsets account for visible text position
```

### Scenario: Multiple types in one line

```gherkin
Given output contains "User admin@example.com logged in from 10.0.0.1 - see /var/log/auth.log"
When parseTappableElements is called
Then result contains 3 TappableElements
And elements are sorted by startOffset
And types are [email, ipAddress, filePath]
```

## Implementation Notes

- Strip ANSI escape codes before parsing
- Use compiled RegExp patterns for performance
- Process patterns in priority order (URL > IP to avoid partial matches)
- Return empty list for null/empty input
- Debounce calls when output is streaming (handled by caller)

## Regex Patterns

```dart
final patterns = {
  TappableType.ipAddress: RegExp(
    r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
    r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
  ),
  TappableType.filePath: RegExp(
    r'''(?:^|[\s"'])(/(?:[^/\s"']+/)*[^/\s"']+)'''
  ),
  TappableType.url: RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+'
  ),
  TappableType.json: RegExp(
    r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
  ),
  TappableType.email: RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
  ),
  TappableType.uuid: RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
    caseSensitive: false,
  ),
  TappableType.gitCommit: RegExp(
    r'\b[0-9a-f]{7,40}\b'
  ),
};
```

## Related Specs

- L2: [Block Service](../L2-contract/service-block.md)
- L2: [Block Widget Component](../L2-contract/component-block-widget.md)
- L3: [Incident Response](../L3-experience/incident-response.md)

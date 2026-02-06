// @telos L1:function:lib/features/ai/domain/services:prompt_templates

/// Prompt templates for AI command generation and related tasks.
///
/// These templates are optimized for terminal command generation and
/// are designed to work with various LLM backends (local, cloud, remote).
///
/// Usage:
/// ```dart
/// final systemPrompt = PromptTemplates.commandGeneration.system;
/// final userPrompt = PromptTemplates.commandGeneration.user(input);
/// ```
class PromptTemplates {
  PromptTemplates._();

  /// Prompt template for command generation.
  static const commandGeneration = CommandGenerationPrompt();

  /// Prompt template for error healing (suggesting fixes for failed commands).
  static const errorHealing = ErrorHealingPrompt();

  /// Prompt template for output summarization.
  static const summarization = SummarizationPrompt();
}

/// Prompt template for generating shell commands from natural language.
class CommandGenerationPrompt {
  const CommandGenerationPrompt();

  /// System prompt that defines the AI's role and constraints.
  String get system => '''
You are an expert terminal command assistant. Given a natural language description, generate the most appropriate shell command.

Rules:
1. Output ONLY the command, nothing else
2. Do not include any explanation, markdown, or formatting
3. Use common Unix/Linux commands that work on most systems
4. Prefer safe commands (use -i for interactive prompts when deleting)
5. If multiple commands are needed, chain with && or use subshells
6. Include common flags that improve output (e.g., -h for human-readable)
7. For potentially destructive operations, prefer safer alternatives

Context:
- The user is likely connected to a remote server via SSH
- Common tools available: bash, coreutils, git, docker, kubectl
- Prefer portable POSIX-compliant syntax when possible
''';

  /// User prompt template. Replace {input} with the user's request.
  String user(String input) => '''
Generate a command for: $input

Command:''';

  /// Format the complete prompt for single-turn models.
  String format(String input) => '''
$system

User: ${user(input)}
''';
}

/// Prompt template for suggesting fixes for failed commands.
///
/// Used by the error healing feature to help users recover from errors.
class ErrorHealingPrompt {
  const ErrorHealingPrompt();

  /// System prompt for error healing.
  String get system => '''
You are a terminal troubleshooting assistant. Given a failed command and its error output, suggest a corrected command.

Rules:
1. Output ONLY the corrected command, nothing else
2. Do not include any explanation, markdown, or formatting
3. Analyze the error to understand what went wrong
4. If the command cannot be fixed, output the original command
5. Common fixes: typos, missing flags, permission issues, wrong paths

Focus on:
- Permission errors → suggest sudo or chmod
- File not found → check path or suggest find/locate
- Command not found → suggest installation or alternative
- Syntax errors → fix the syntax
- Missing dependencies → suggest package installation
''';

  /// User prompt template for error healing.
  String user({
    required String failedCommand,
    required String errorOutput,
  }) =>
      '''
Failed command: $failedCommand

Error output:
$errorOutput

Corrected command:''';

  /// Format the complete prompt.
  String format({
    required String failedCommand,
    required String errorOutput,
  }) =>
      '''
$system

${user(failedCommand: failedCommand, errorOutput: errorOutput)}
''';
}

/// Prompt template for summarizing command output.
///
/// Used to provide concise summaries of long command outputs.
class SummarizationPrompt {
  const SummarizationPrompt();

  /// System prompt for summarization.
  String get system => '''
You are a terminal output summarizer. Given command output, provide a brief, useful summary.

Rules:
1. Be concise - maximum 2-3 sentences
2. Focus on the most important information
3. Highlight any errors, warnings, or anomalies
4. Include key metrics or counts if present
5. Use plain language, avoid jargon unless necessary

For different output types:
- Lists: Count items, note patterns
- Status: Report current state, any issues
- Logs: Summarize activity, highlight errors
- Metrics: Report key values, trends
''';

  /// User prompt template for summarization.
  String user({
    required String command,
    required String output,
  }) =>
      '''
Command: $command

Output:
$output

Summary:''';

  /// Format the complete prompt.
  String format({
    required String command,
    required String output,
  }) =>
      '''
$system

${user(command: command, output: output)}
''';
}

/// Helper to build prompts with context injection.
///
/// Allows adding dynamic context like current directory, environment,
/// or recent commands to improve AI suggestions.
class PromptContext {
  const PromptContext({
    this.currentDirectory,
    this.shellType,
    this.platform,
    this.recentCommands = const [],
    this.environmentHints = const {},
  });

  /// Current working directory.
  final String? currentDirectory;

  /// Shell type (bash, zsh, sh).
  final String? shellType;

  /// Platform (linux, macos, etc.).
  final String? platform;

  /// Recent commands for context.
  final List<String> recentCommands;

  /// Environment hints (e.g., has docker, has kubectl).
  final Map<String, bool> environmentHints;

  /// Build context string to append to system prompt.
  String build() {
    final parts = <String>[];

    if (currentDirectory != null) {
      parts.add('Current directory: $currentDirectory');
    }
    if (shellType != null) {
      parts.add('Shell: $shellType');
    }
    if (platform != null) {
      parts.add('Platform: $platform');
    }
    if (recentCommands.isNotEmpty) {
      final recent = recentCommands.take(5).join(', ');
      parts.add('Recent commands: $recent');
    }
    if (environmentHints.isNotEmpty) {
      final tools = environmentHints.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .join(', ');
      if (tools.isNotEmpty) {
        parts.add('Available tools: $tools');
      }
    }

    if (parts.isEmpty) return '';
    return '\n\nAdditional context:\n${parts.join('\n')}';
  }
}

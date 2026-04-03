// @telos L2:contract:service-ai-gateway

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/domain/entities/shell_context.dart';
import '../../domain/entities/command_knowledge.dart';
import 'block_provider.dart';

/// Best-effort shell context for command assistance in a session.
final shellContextProvider = Provider.family<ShellContext, String>((ref, sessionId) {
  final blockState = ref.watch(blockListControllerProvider(sessionId));
  final recentCommands = blockState.blocks
      .reversed
      .map((block) => block.command)
      .where((command) => command.trim().isNotEmpty)
      .take(10)
      .toList();

  return ShellContext(
    // Best-effort defaults until shell/OS probing is implemented.
    shell: 'bash',
    os: 'linux',
    cwd: null,
    availableCommands: const CommandKnowledge().commands.toList(),
    recentCommands: recentCommands,
  );
});

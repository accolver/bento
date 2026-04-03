// @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/complete_command_line.dart';
import 'ai_providers.dart';

/// Provider for the explicit AI line-completion usecase.
final completeCommandLineUseCaseProvider =
    FutureProvider<CompleteCommandLine>((ref) async {
  final service = await ref.watch(aiServiceControllerProvider.future);
  final config = await ref.watch(aiConfigStateProvider.future);
  return CompleteCommandLine(service: service, config: config);
});

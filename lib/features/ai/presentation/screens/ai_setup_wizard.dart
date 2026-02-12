// @telos L2:contract:lib/features/ai/presentation/screens:ai_setup_wizard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_config.dart';
import '../../domain/entities/local_ai_model.dart';
import '../providers/ai_providers.dart';
import '../providers/remote_ai_providers.dart';
import '../widgets/setup_steps/cloud_api_key_step.dart';
import '../widgets/setup_steps/cloud_provider_step.dart';
import '../widgets/setup_steps/complete_step.dart';
import '../widgets/setup_steps/local_download_step.dart';
import '../widgets/setup_steps/local_model_select_step.dart';
import '../widgets/setup_steps/mode_selection_step.dart';
import '../widgets/setup_steps/remote_detect_step.dart';

/// Wizard steps for AI setup.
enum AiSetupStep {
  modeSelection,
  localModelSelect,
  localDownload,
  cloudProvider,
  cloudApiKey,
  remoteDetect,
  complete,
}

/// Entry point for AI setup flow.
///
/// Shows as a full-screen modal or pushed route.
/// Guides users through AI configuration on first use.
class AiSetupWizard extends ConsumerStatefulWidget {
  const AiSetupWizard({
    super.key,
    this.onComplete,
    this.onSkip,
  });

  /// Called when setup completes successfully.
  final VoidCallback? onComplete;

  /// Called when user skips setup.
  final VoidCallback? onSkip;

  /// Shows the wizard as a modal bottom sheet.
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AiSetupWizard(
        onComplete: () => Navigator.of(context).pop(),
        onSkip: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  ConsumerState<AiSetupWizard> createState() => _AiSetupWizardState();
}

class _AiSetupWizardState extends ConsumerState<AiSetupWizard> {
  AiSetupStep _currentStep = AiSetupStep.modeSelection;
  final List<AiSetupStep> _stepHistory = [];

  // Selected values during setup
  LocalAiModel? _selectedLocalModel;
  CloudAiProvider? _selectedCloudProvider;
  String? _downloadedModelPath;
  String? _completeModeDescription;
  bool _remoteAutoDetect = true;

  void _goToStep(AiSetupStep step) {
    setState(() {
      _stepHistory.add(_currentStep);
      _currentStep = step;
    });
  }

  void _goBack() {
    if (_stepHistory.isEmpty) {
      widget.onSkip?.call();
      return;
    }
    setState(() {
      _currentStep = _stepHistory.removeLast();
    });
  }

  void _onModeSelected(AiMode mode) {
    switch (mode) {
      case AiMode.local:
        _goToStep(AiSetupStep.localModelSelect);
      case AiMode.cloud:
        _goToStep(AiSetupStep.cloudProvider);
      case AiMode.remote:
        _goToStep(AiSetupStep.remoteDetect);
      case AiMode.unconfigured:
        widget.onSkip?.call();
    }
  }

  void _onLocalModelSelected(LocalAiModel model) {
    setState(() {
      _selectedLocalModel = model;
    });
    _goToStep(AiSetupStep.localDownload);
  }

  Future<void> _onLocalDownloadComplete(String modelPath) async {
    setState(() {
      _downloadedModelPath = modelPath;
    });

    // Save configuration and wait for it to complete
    await ref.read(aiConfigStateProvider.notifier).setLocal(
          modelId: _selectedLocalModel!.id,
          modelPath: modelPath,
        );

    _completeModeDescription =
        'Local AI running on your device. Data never leaves your phone.';
    _goToStep(AiSetupStep.complete);
  }

  void _onCloudProviderSelected(CloudAiProvider provider) {
    setState(() {
      _selectedCloudProvider = provider;
    });
    _goToStep(AiSetupStep.cloudApiKey);
  }

  Future<void> _onCloudApiKeyComplete(String apiKey) async {
    // Save API key and configuration
    final notifier = ref.read(aiConfigStateProvider.notifier);
    await notifier.saveApiKey(apiKey);
    await notifier.setCloud(_selectedCloudProvider!);

    _completeModeDescription = 'Cloud AI configured. '
        'Tap the AI button to start writing commands.';
    _goToStep(AiSetupStep.complete);
  }

  Future<void> _onRemoteDetectComplete() async {
    await ref.read(aiConfigStateProvider.notifier).setRemote(
          remoteAutoDetect: _remoteAutoDetect,
        );

    // Build a mode-specific description based on what was detected.
    // Try multiple sources to find the active service/detection info.
    final hostId = ref.read(activeRemoteHostIdProvider);
    if (hostId != null) {
      // First try the active service
      var remoteService = ref.read(activeRemoteAiServiceProvider);
      // Fallback: read service controller directly (keepAlive provider)
      remoteService ??= ref.read(remoteAiServiceControllerProvider(hostId));

      if (remoteService != null) {
        _completeModeDescription =
            'Remote AI active via ${remoteService.backend.displayName}. '
            'Data stays on your infrastructure.';
      } else {
        // No service yet, but check detection results
        final detectionResult =
            ref.read(remoteAiDetectionStateProvider(hostId)).valueOrNull;
        if (detectionResult != null && detectionResult.hasAnyProvider) {
          final providerNames = <String>[];
          if (detectionResult.hasOllama) {
            providerNames.add(
              'Ollama (${detectionResult.ollamaModels.first.displayName})',
            );
          }
          if (detectionResult.hasCloudProviders) {
            providerNames.add(detectionResult.bestCloudProvider!.displayName);
          }
          _completeModeDescription = 'Found: ${providerNames.join(", ")}. '
              'Data stays on your infrastructure.';
        } else {
          _completeModeDescription =
              'Remote AI will detect providers when you connect via SSH.';
        }
      }
    } else {
      _completeModeDescription =
          'Remote AI will detect providers when you connect via SSH.';
    }

    // Force the bridge providers to re-evaluate from scratch. Without this,
    // the keepAlive activeRemoteAiServiceProvider may have a cached null
    // value from before the remote service was initialized, and stale
    // dependency tracking prevents it from picking up the new state.
    ref.invalidate(activeRemoteAiServiceProvider);
    ref.invalidate(activeRemoteHostIdProvider);

    // Now invalidate the AI service controller to force a rebuild that
    // picks up the newly configured remote mode with fresh provider values.
    ref.invalidate(aiServiceControllerProvider);

    _goToStep(AiSetupStep.complete);
  }

  void _onSetupComplete() {
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with back button
            if (_currentStep != AiSetupStep.modeSelection &&
                _currentStep != AiSetupStep.complete)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBack,
                      tooltip: 'Back',
                    ),
                  ],
                ),
              ),

            // Step content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      AiSetupStep.modeSelection => ModeSelectionStep(
          key: const ValueKey('mode'),
          onModeSelected: _onModeSelected,
          onSkip: widget.onSkip,
        ),
      AiSetupStep.localModelSelect => LocalModelSelectStep(
          key: const ValueKey('local-model'),
          onModelSelected: _onLocalModelSelected,
        ),
      AiSetupStep.localDownload => LocalDownloadStep(
          key: const ValueKey('local-download'),
          model: _selectedLocalModel!,
          onComplete: _onLocalDownloadComplete,
          onCancel: _goBack,
        ),
      AiSetupStep.cloudProvider => CloudProviderStep(
          key: const ValueKey('cloud-provider'),
          onProviderSelected: _onCloudProviderSelected,
        ),
      AiSetupStep.cloudApiKey => CloudApiKeyStep(
          key: const ValueKey('cloud-apikey'),
          provider: _selectedCloudProvider!,
          onComplete: _onCloudApiKeyComplete,
        ),
      AiSetupStep.remoteDetect => RemoteDetectStep(
          key: const ValueKey('remote-detect'),
          onComplete: _onRemoteDetectComplete,
          onAutoDetectChanged: (value) {
            _remoteAutoDetect = value;
          },
        ),
      AiSetupStep.complete => CompleteStep(
          key: const ValueKey('complete'),
          onComplete: _onSetupComplete,
          modeDescription: _completeModeDescription,
        ),
    };
  }
}

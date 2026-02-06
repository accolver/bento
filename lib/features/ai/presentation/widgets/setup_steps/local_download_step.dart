// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:local_download_step

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/model_download_service.dart';
import '../../../domain/entities/local_ai_model.dart';
import '../../providers/ai_providers.dart';

/// Step showing model download progress.
class LocalDownloadStep extends ConsumerStatefulWidget {
  const LocalDownloadStep({
    super.key,
    required this.model,
    required this.onComplete,
    required this.onCancel,
  });

  final LocalAiModel model;
  final void Function(String modelPath) onComplete;
  final VoidCallback onCancel;

  @override
  ConsumerState<LocalDownloadStep> createState() => _LocalDownloadStepState();
}

class _LocalDownloadStepState extends ConsumerState<LocalDownloadStep> {
  DownloadProgress? _progress;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartDownload();
  }

  /// Check if model is already downloaded, if so skip to complete.
  Future<void> _checkAndStartDownload() async {
    final downloadService = ref.read(modelDownloadServiceProvider);

    // Check if model is already downloaded
    final isDownloaded =
        await downloadService.isModelDownloaded(widget.model.id);
    if (isDownloaded) {
      // Model already exists, skip download
      if (!mounted) return;
      final modelPath = await downloadService.getModelPath(widget.model.id);
      widget.onComplete(modelPath);
      return;
    }

    // Model not downloaded, start download
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _progress = null;
    });

    final downloadService = ref.read(modelDownloadServiceProvider);

    try {
      await for (final progress
          in downloadService.downloadModel(widget.model)) {
        if (!mounted) return;
        setState(() {
          _progress = progress;
        });
      }

      // Download complete - check if we actually finished
      if (!mounted) return;

      // Verify the file exists before calling onComplete
      final isDownloaded =
          await downloadService.isModelDownloaded(widget.model.id);
      if (isDownloaded) {
        final modelPath = await downloadService.getModelPath(widget.model.id);
        widget.onComplete(modelPath);
      } else {
        setState(() {
          _error = 'Download completed but file not found';
          _isDownloading = false;
        });
      }
    } on ModelDownloadException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isDownloading = false;
      });
    } catch (e) {
      // Catch any unexpected errors (including stream errors)
      if (!mounted) return;
      setState(() {
        _error = _formatError(e);
        _isDownloading = false;
      });
    }
  }

  String _formatError(dynamic error) {
    if (error is ModelDownloadException) {
      return error.message;
    }
    final errorStr = error.toString();
    // Make error messages more user-friendly
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    if (errorStr.contains('Connection timed out')) {
      return 'Connection timed out. Please try again.';
    }
    return 'Download failed: $errorStr';
  }

  void _cancelDownload() {
    ref.read(modelDownloadServiceProvider).cancelDownload();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Progress indicator
          if (_error == null) ...[
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progress?.progress,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Text(
                    _progress?.percentageString ?? '0%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Downloading ${widget.model.name}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progress?.formattedProgress ?? 'Starting...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          // Error state
          if (_error != null) ...[
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Download Failed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],

          const Spacer(),

          // Cancel button
          if (_isDownloading)
            TextButton(
              onPressed: _cancelDownload,
              child: const Text('Cancel'),
            ),

          if (_error != null)
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Go Back'),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

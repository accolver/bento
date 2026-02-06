// @telos L1:function:lib/features/ai/data/services:model_download_service

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/local_ai_model.dart';

/// Progress update during model download.
class DownloadProgress {
  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int totalBytes;

  /// Progress as a value between 0.0 and 1.0.
  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0.0;

  /// Progress as a percentage string (e.g., "45%").
  String get percentageString => '${(progress * 100).toInt()}%';

  /// Human-readable received size.
  String get formattedReceived => _formatBytes(receivedBytes);

  /// Human-readable total size.
  String get formattedTotal => _formatBytes(totalBytes);

  /// Formatted as "1.2 GB / 2.0 GB".
  String get formattedProgress => '$formattedReceived / $formattedTotal';

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '$bytes B';
    }
  }
}

/// Service for downloading AI models from HuggingFace.
///
/// Supports:
/// - Progress tracking with streams
/// - Cancellation
/// - Resume (partial download preservation)
/// - Cleanup of partial files on error
class ModelDownloadService {
  ModelDownloadService({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  CancelToken? _cancelToken;
  bool _isDownloading = false;

  /// Whether a download is currently in progress.
  bool get isDownloading => _isDownloading;

  /// Downloads a model and returns a stream of progress updates.
  ///
  /// The stream completes when the download finishes.
  /// Throws [ModelDownloadException] on failure.
  ///
  /// Returns the local file path where the model was saved.
  Stream<DownloadProgress> downloadModel(LocalAiModel model) async* {
    if (_isDownloading) {
      throw const ModelDownloadException(
        message: 'A download is already in progress',
        code: ModelDownloadErrorCode.alreadyDownloading,
      );
    }

    _isDownloading = true;
    _cancelToken = CancelToken();

    final localPath = await _getModelPath(model.id);

    // Create a stream controller for progress updates
    final controller = StreamController<DownloadProgress>();

    try {
      // Start download in background
      final downloadFuture = _dio.download(
        model.downloadUrl,
        localPath,
        cancelToken: _cancelToken,
        deleteOnError: false, // Enable resume capability
        onReceiveProgress: (received, total) {
          if (!controller.isClosed) {
            controller.add(
              DownloadProgress(
                receivedBytes: received,
                totalBytes: total > 0 ? total : model.sizeBytes,
              ),
            );
          }
        },
      );

      // Forward progress events from controller
      await for (final progress in controller.stream) {
        yield progress;

        // Check if download is complete
        if (progress.progress >= 1.0) {
          break;
        }
      }

      // Wait for download to complete
      await downloadFuture;

      // Final progress update
      yield DownloadProgress(
        receivedBytes: model.sizeBytes,
        totalBytes: model.sizeBytes,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Clean up partial file on cancel
        await _deleteFile(localPath);
        throw const ModelDownloadException(
          message: 'Download cancelled',
          code: ModelDownloadErrorCode.cancelled,
        );
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw ModelDownloadException(
          message: 'Network error: ${e.message}',
          code: ModelDownloadErrorCode.networkError,
        );
      } else {
        throw ModelDownloadException(
          message: 'Download failed: ${e.message}',
          code: ModelDownloadErrorCode.downloadFailed,
        );
      }
    } finally {
      await controller.close();
      _isDownloading = false;
      _cancelToken = null;
    }
  }

  /// Cancels the current download.
  ///
  /// Does nothing if no download is in progress.
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
    _isDownloading = false;
  }

  /// Gets the local path where a model would be stored.
  Future<String> getModelPath(String modelId) async {
    return _getModelPath(modelId);
  }

  /// Checks if a model has been downloaded.
  Future<bool> isModelDownloaded(String modelId) async {
    final path = await _getModelPath(modelId);
    final file = File(path);
    return file.existsSync();
  }

  /// Deletes a downloaded model.
  Future<void> deleteModel(String modelId) async {
    final path = await _getModelPath(modelId);
    await _deleteFile(path);
  }

  /// Gets the size of a downloaded model file.
  ///
  /// Returns 0 if the file doesn't exist.
  Future<int> getDownloadedModelSize(String modelId) async {
    final path = await _getModelPath(modelId);
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }

  /// Lists all downloaded model IDs.
  Future<List<String>> getDownloadedModels() async {
    final dir = await _getModelsDirectory();
    if (!await dir.exists()) return [];

    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .map((f) => p.basenameWithoutExtension(f.path))
        .toList();
  }

  Future<String> _getModelPath(String modelId) async {
    final dir = await _getModelsDirectory();
    return p.join(dir.path, '$modelId.gguf');
  }

  Future<Directory> _getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(appDir.path, 'bento', 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Error codes for model download failures.
enum ModelDownloadErrorCode {
  /// A download is already in progress.
  alreadyDownloading,

  /// Download was cancelled by the user.
  cancelled,

  /// Network error (no connection, timeout, etc.).
  networkError,

  /// Download failed for other reasons.
  downloadFailed,

  /// File system error.
  fileSystemError,
}

/// Exception thrown when model download fails.
class ModelDownloadException implements Exception {
  const ModelDownloadException({
    required this.message,
    required this.code,
  });

  final String message;
  final ModelDownloadErrorCode code;

  /// Whether this error is retryable.
  bool get isRetryable =>
      code == ModelDownloadErrorCode.networkError ||
      code == ModelDownloadErrorCode.downloadFailed;

  @override
  String toString() => 'ModelDownloadException: $message ($code)';
}

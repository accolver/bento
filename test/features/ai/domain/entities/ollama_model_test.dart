// @telos-test L1:function:lib/features/ai/domain/entities:ollama_model

import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Shared fixture: a fully-populated model used across multiple groups.
  late OllamaModel fullModel;
  late DateTime fixedDate;

  setUp(() {
    fixedDate = DateTime.utc(2025, 6, 15, 12, 0, 0);
    fullModel = OllamaModel(
      name: 'llama3:8b',
      digest: 'sha256:abc123',
      sizeBytes: 4661224676,
      modifiedAt: fixedDate,
      details: {
        'parameter_size': '8B',
        'quantization_level': 'Q4_0',
        'family': 'llama',
      },
    );
  });

  group('OllamaModel.displayName', () {
    // @telos-scenario L1:...:ollama_model:display-name-standard
    test('capitalizes base name before colon', () {
      expect(fullModel.displayName, 'Llama3');

      final codellama = OllamaModel(
        name: 'codellama:7b',
        modifiedAt: fixedDate,
      );
      expect(codellama.displayName, 'Codellama');

      final mistral = OllamaModel(
        name: 'mistral:latest',
        modifiedAt: fixedDate,
      );
      expect(mistral.displayName, 'Mistral');
    });

    // @telos-scenario L1:...:ollama_model:display-name-no-colon
    test('capitalizes full name when no colon present', () {
      final model = OllamaModel(
        name: 'gemma',
        modifiedAt: fixedDate,
      );
      expect(model.displayName, 'Gemma');
    });

    // @telos-scenario L1:...:ollama_model:display-name-empty
    test('returns name unchanged when name is empty', () {
      final model = OllamaModel(
        name: '',
        modifiedAt: fixedDate,
      );
      // base is empty → returns original name unchanged
      expect(model.displayName, '');
    });

    // @telos-scenario L1:...:ollama_model:display-name-leading-colon
    test('returns original name when name starts with colon', () {
      final model = OllamaModel(
        name: ':tag',
        modifiedAt: fixedDate,
      );
      // base is empty → returns original name unchanged
      expect(model.displayName, ':tag');
    });
  });

  group('OllamaModel.formattedSize', () {
    // @telos-scenario L1:...:ollama_model:formatted-size-standard
    test('converts bytes to GB with one decimal place', () {
      expect(fullModel.formattedSize, '4.7 GB');
    });

    // @telos-scenario L1:...:ollama_model:formatted-size-zero
    test('returns 0.0 GB when sizeBytes is 0', () {
      final model = OllamaModel(
        name: 'tiny',
        modifiedAt: fixedDate,
      );
      expect(model.formattedSize, '0.0 GB');
    });

    // @telos-scenario L1:...:ollama_model:formatted-size-small
    test('formats sub-gigabyte sizes correctly', () {
      final model = OllamaModel(
        name: 'small',
        sizeBytes: 500000000,
        modifiedAt: fixedDate,
      );
      expect(model.formattedSize, '0.5 GB');
    });
  });

  group('OllamaModel.tag', () {
    // @telos-scenario L1:...:ollama_model:tag-standard
    test('extracts tag after colon', () {
      expect(fullModel.tag, '8b');

      final mistral = OllamaModel(
        name: 'mistral:latest',
        modifiedAt: fixedDate,
      );
      expect(mistral.tag, 'latest');
    });

    // @telos-scenario L1:...:ollama_model:tag-no-colon
    test('returns null when no colon in name', () {
      final model = OllamaModel(
        name: 'nocolon',
        modifiedAt: fixedDate,
      );
      expect(model.tag, isNull);
    });

    // @telos-scenario L1:...:ollama_model:tag-multi-colon
    test('preserves everything after first colon for multi-colon names', () {
      final model = OllamaModel(
        name: 'model:tag:subtag',
        modifiedAt: fixedDate,
      );
      expect(model.tag, 'tag:subtag');
    });
  });

  group('OllamaModel.parameterSize', () {
    // @telos-scenario L1:...:ollama_model:parameter-size-present
    test('returns parameter_size from details map', () {
      expect(fullModel.parameterSize, '8B');
    });

    // @telos-scenario L1:...:ollama_model:parameter-size-null-details
    test('returns null when details is null', () {
      final model = OllamaModel(
        name: 'llama3:8b',
        modifiedAt: fixedDate,
      );
      expect(model.parameterSize, isNull);
    });

    // @telos-scenario L1:...:ollama_model:parameter-size-missing-key
    test('returns null when details lacks parameter_size key', () {
      final model = OllamaModel(
        name: 'llama3:8b',
        modifiedAt: fixedDate,
        details: {'family': 'llama'},
      );
      expect(model.parameterSize, isNull);
    });
  });

  group('OllamaModel.quantizationLevel', () {
    // @telos-scenario L1:...:ollama_model:quantization-level-present
    test('returns quantization_level from details map', () {
      expect(fullModel.quantizationLevel, 'Q4_0');
    });

    // @telos-scenario L1:...:ollama_model:quantization-level-null-details
    test('returns null when details is null', () {
      final model = OllamaModel(
        name: 'llama3:8b',
        modifiedAt: fixedDate,
      );
      expect(model.quantizationLevel, isNull);
    });
  });

  group('OllamaModel copyWith (Freezed)', () {
    // @telos-scenario L1:...:ollama_model:copy-with
    test('creates a copy with overridden fields while preserving others', () {
      final copy = fullModel.copyWith(name: 'phi3:mini', sizeBytes: 1000000);

      expect(copy.name, 'phi3:mini');
      expect(copy.sizeBytes, 1000000);
      // Preserved fields
      expect(copy.digest, fullModel.digest);
      expect(copy.modifiedAt, fullModel.modifiedAt);
      expect(copy.details, fullModel.details);
    });

    // @telos-scenario L1:...:ollama_model:copy-with-null-override
    test('can set nullable fields to null', () {
      final copy = fullModel.copyWith(digest: null, details: null);

      expect(copy.digest, isNull);
      expect(copy.details, isNull);
      expect(copy.name, fullModel.name);
    });
  });

  group('OllamaModel equality (Freezed)', () {
    // @telos-scenario L1:...:ollama_model:equality-same-values
    test('two models with identical values are equal', () {
      final a = OllamaModel(
        name: 'llama3:8b',
        digest: 'sha256:abc123',
        sizeBytes: 4661224676,
        modifiedAt: fixedDate,
        details: {'parameter_size': '8B'},
      );
      final b = OllamaModel(
        name: 'llama3:8b',
        digest: 'sha256:abc123',
        sizeBytes: 4661224676,
        modifiedAt: fixedDate,
        details: {'parameter_size': '8B'},
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    // @telos-scenario L1:...:ollama_model:equality-different-values
    test('two models with different values are not equal', () {
      final other = OllamaModel(
        name: 'mistral:latest',
        modifiedAt: fixedDate,
      );

      expect(fullModel, isNot(equals(other)));
    });
  });

  group('OllamaModel.fromJson', () {
    // @telos-scenario L1:...:ollama_model:from-json-round-trip
    test('deserializes from JSON and preserves all fields', () {
      // Uses Ollama API field names: 'size' and 'modified_at' (mapped via @JsonKey)
      final json = {
        'name': 'llama3:8b',
        'digest': 'sha256:abc123def456',
        'size': 4661224676,
        'modified_at': '2025-06-15T12:00:00.000Z',
        'details': {
          'parameter_size': '8B',
          'quantization_level': 'Q4_0',
          'family': 'llama',
        },
      };

      final model = OllamaModel.fromJson(json);

      expect(model.name, 'llama3:8b');
      expect(model.digest, 'sha256:abc123def456');
      expect(model.sizeBytes, 4661224676);
      expect(model.modifiedAt, DateTime.utc(2025, 6, 15, 12, 0, 0));
      expect(model.parameterSize, '8B');
      expect(model.quantizationLevel, 'Q4_0');
      expect(model.details?['family'], 'llama');
    });

    // @telos-scenario L1:...:ollama_model:from-json-minimal
    test('deserializes with only required fields', () {
      // Uses Ollama API field names: 'modified_at' (mapped via @JsonKey)
      final json = {
        'name': 'phi3:mini',
        'modified_at': '2025-01-01T00:00:00.000Z',
      };

      final model = OllamaModel.fromJson(json);

      expect(model.name, 'phi3:mini');
      expect(model.sizeBytes, 0); // default
      expect(model.digest, isNull);
      expect(model.details, isNull);
      expect(model.modifiedAt, DateTime.utc(2025, 1, 1));
    });

    // @telos-scenario L1:...:ollama_model:to-json-round-trip
    test('toJson → fromJson round-trip preserves equality', () {
      final json = fullModel.toJson();
      final restored = OllamaModel.fromJson(json);

      expect(restored, equals(fullModel));
    });
  });

  group('OllamaModel defaults', () {
    // @telos-scenario L1:...:ollama_model:default-size-bytes
    test('sizeBytes defaults to 0', () {
      final model = OllamaModel(
        name: 'test',
        modifiedAt: fixedDate,
      );
      expect(model.sizeBytes, 0);
    });
  });
}

// @telos L1:function:lib/features/credentials/presentation/screens:key_generate_screen

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinenacl/ed25519.dart' as ed;
import 'package:pointycastle/export.dart' as pc;

import '../../data/utils/ssh_key_utils.dart';
import '../../domain/entities/credential.dart';
import '../providers/credential_providers.dart';

/// Screen for generating new SSH key pairs.
class KeyGenerateScreen extends ConsumerStatefulWidget {
  const KeyGenerateScreen({super.key});

  @override
  ConsumerState<KeyGenerateScreen> createState() => _KeyGenerateScreenState();
}

class _KeyGenerateScreenState extends ConsumerState<KeyGenerateScreen> {
  final _keyNameController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();

  CredentialType _keyType = CredentialType.ed25519;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _requiresBiometric = false;
  bool _usePassphrase = false;
  bool _showPassphrase = false;
  String? _errorMessage;

  // Generated key data
  String? _privateKeyPem;
  String? _publicKey;
  String? _fingerprint;

  @override
  void dispose() {
    _keyNameController.dispose();
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  Future<void> _generateKey() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _privateKeyPem = null;
      _publicKey = null;
      _fingerprint = null;
    });

    try {
      // Generate key pair based on selected type
      String privateKeyPem;
      String publicKeyOpenSSH;
      String fingerprint;

      switch (_keyType) {
        case CredentialType.ed25519:
          final result = await compute(_generateEd25519Key, null);
          privateKeyPem = result['privateKey']!;
          publicKeyOpenSSH = result['publicKey']!;
          fingerprint = result['fingerprint']!;
        case CredentialType.rsa:
          // RSA-4096 for maximum security
          final result = await compute(_generateRsaKey, 4096);
          privateKeyPem = result['privateKey']!;
          publicKeyOpenSSH = result['publicKey']!;
          fingerprint = result['fingerprint']!;
        case CredentialType.ecdsa:
        case CredentialType.password:
          throw UnsupportedError('Key type not supported for generation');
      }

      setState(() {
        _privateKeyPem = privateKeyPem;
        _publicKey = publicKeyOpenSSH;
        _fingerprint = fingerprint;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Key generation failed: $e';
      });
    }
  }

  /// Generate Ed25519 key pair (runs in isolate)
  static Map<String, String> _generateEd25519Key(void _) {
    // Use pinenacl for Ed25519 key generation
    final signingKey = ed.SigningKey.generate();
    final verifyKey = signingKey.verifyKey;

    // Get raw bytes
    final privateKeyBytes = Uint8List.fromList(signingKey.seed);
    final publicKeyBytes = Uint8List.fromList(verifyKey);

    // Format as OpenSSH private key
    final privateKeyPem = _formatEd25519PrivateKeyPem(
      privateKeyBytes,
      publicKeyBytes,
    );

    // Format public key in OpenSSH format
    final publicKeyBlob = _encodeEd25519PublicKey(publicKeyBytes);
    final publicKeyOpenSSH = 'ssh-ed25519 ${base64Encode(publicKeyBlob)}';

    // Compute fingerprint
    final fingerprint = sha256
        .convert(publicKeyBlob)
        .bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();

    return {
      'privateKey': privateKeyPem,
      'publicKey': publicKeyOpenSSH,
      'fingerprint': fingerprint,
    };
  }

  /// Generate RSA key pair (runs in isolate)
  static Map<String, String> _generateRsaKey(int keySize) {
    final secureRandom = _getSecureRandom();

    final keyGen = pc.RSAKeyGenerator();
    keyGen.init(pc.ParametersWithRandom(
      pc.RSAKeyGeneratorParameters(BigInt.from(65537), keySize, 64),
      secureRandom,
    ));

    final keyPair = keyGen.generateKeyPair();
    final privateKey = keyPair.privateKey as pc.RSAPrivateKey;
    final publicKey = keyPair.publicKey as pc.RSAPublicKey;

    // Format as PEM
    final privateKeyPem = _formatRsaPrivateKeyPem(privateKey);

    // Format public key in OpenSSH format
    final publicKeyBlob = _encodeRsaPublicKey(publicKey);
    final publicKeyOpenSSH = 'ssh-rsa ${base64Encode(publicKeyBlob)}';

    // Compute fingerprint
    final fingerprint = sha256
        .convert(publicKeyBlob)
        .bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();

    return {
      'privateKey': privateKeyPem,
      'publicKey': publicKeyOpenSSH,
      'fingerprint': fingerprint,
    };
  }

  static pc.SecureRandom _getSecureRandom() {
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    return pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(Uint8List.fromList(seeds)));
  }

  /// Encode Ed25519 public key in OpenSSH format
  static Uint8List _encodeEd25519PublicKey(Uint8List publicKey) {
    final buffer = BytesBuilder();

    // Key type
    final keyType = utf8.encode('ssh-ed25519');
    buffer.add(_encodeUint32(keyType.length));
    buffer.add(keyType);

    // Public key
    buffer.add(_encodeUint32(publicKey.length));
    buffer.add(publicKey);

    return buffer.toBytes();
  }

  /// Encode RSA public key in OpenSSH format
  static Uint8List _encodeRsaPublicKey(pc.RSAPublicKey publicKey) {
    final buffer = BytesBuilder();

    // Key type
    final keyType = utf8.encode('ssh-rsa');
    buffer.add(_encodeUint32(keyType.length));
    buffer.add(keyType);

    // Exponent
    final eBytes = _encodeMpint(publicKey.publicExponent!);
    buffer.add(eBytes);

    // Modulus
    final nBytes = _encodeMpint(publicKey.modulus!);
    buffer.add(nBytes);

    return buffer.toBytes();
  }

  /// Encode a BigInt as SSH mpint
  static Uint8List _encodeMpint(BigInt value) {
    var bytes = _bigIntToBytes(value);

    // Add leading zero if high bit is set (to indicate positive number)
    if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
      bytes = Uint8List.fromList([0, ...bytes]);
    }

    final buffer = BytesBuilder();
    buffer.add(_encodeUint32(bytes.length));
    buffer.add(bytes);
    return buffer.toBytes();
  }

  static Uint8List _bigIntToBytes(BigInt value) {
    final hexStr = value.toRadixString(16);
    final paddedHex = hexStr.length.isOdd ? '0$hexStr' : hexStr;
    final bytes = <int>[];
    for (var i = 0; i < paddedHex.length; i += 2) {
      bytes.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List _encodeUint32(int value) {
    return Uint8List.fromList([
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }

  /// Format Ed25519 private key as OpenSSH PEM
  static String _formatEd25519PrivateKeyPem(
    Uint8List privateKey,
    Uint8List publicKey,
  ) {
    // OpenSSH private key format is complex - use a simplified version
    // In production, you'd use a proper OpenSSH key encoder
    final buffer = BytesBuilder();

    // AUTH_MAGIC
    buffer.add(utf8.encode('openssh-key-v1'));
    buffer.addByte(0);

    // ciphername (none = unencrypted)
    buffer.add(_encodeUint32(4));
    buffer.add(utf8.encode('none'));

    // kdfname (none)
    buffer.add(_encodeUint32(4));
    buffer.add(utf8.encode('none'));

    // kdf options (empty)
    buffer.add(_encodeUint32(0));

    // Number of keys
    buffer.add(_encodeUint32(1));

    // Public key blob
    final pubKeyBlob = _encodeEd25519PublicKey(publicKey);
    buffer.add(_encodeUint32(pubKeyBlob.length));
    buffer.add(pubKeyBlob);

    // Private section
    final privatePart = BytesBuilder();

    // Check integers (random, must match for decryption verification)
    final random = Random.secure();
    final checkInt = random.nextInt(0xFFFFFFFF);
    privatePart.add(_encodeUint32(checkInt));
    privatePart.add(_encodeUint32(checkInt));

    // Key type
    final keyType = utf8.encode('ssh-ed25519');
    privatePart.add(_encodeUint32(keyType.length));
    privatePart.add(keyType);

    // Public key
    privatePart.add(_encodeUint32(publicKey.length));
    privatePart.add(publicKey);

    // Private key (64 bytes = 32 private + 32 public)
    final fullPrivateKey = Uint8List.fromList([...privateKey, ...publicKey]);
    privatePart.add(_encodeUint32(fullPrivateKey.length));
    privatePart.add(fullPrivateKey);

    // Comment (empty)
    privatePart.add(_encodeUint32(0));

    // Padding (1, 2, 3, 4...)
    var padding = 1;
    while (privatePart.length % 8 != 0) {
      privatePart.addByte(padding++);
    }

    final privateBytes = privatePart.toBytes();
    buffer.add(_encodeUint32(privateBytes.length));
    buffer.add(privateBytes);

    // Encode to base64 and format as PEM
    final keyData = base64Encode(buffer.toBytes());
    final lines = <String>[];
    for (var i = 0; i < keyData.length; i += 70) {
      lines.add(keyData.substring(
        i,
        i + 70 > keyData.length ? keyData.length : i + 70,
      ));
    }

    return '-----BEGIN OPENSSH PRIVATE KEY-----\n${lines.join('\n')}\n-----END OPENSSH PRIVATE KEY-----\n';
  }

  /// Format RSA private key as PEM (PKCS#1)
  static String _formatRsaPrivateKeyPem(pc.RSAPrivateKey privateKey) {
    // Use ASN.1 encoding for RSA private key
    final sequence = ASN1Sequence();

    // Version
    sequence.add(ASN1Integer(BigInt.zero));

    // RSA parameters
    sequence.add(ASN1Integer(privateKey.modulus!)); // n
    sequence.add(ASN1Integer(privateKey.publicExponent!)); // e
    sequence.add(ASN1Integer(privateKey.privateExponent!)); // d
    sequence.add(ASN1Integer(privateKey.p!)); // p
    sequence.add(ASN1Integer(privateKey.q!)); // q

    // Calculate dP, dQ, qInv
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    final qInv = privateKey.q!.modInverse(privateKey.p!);

    sequence.add(ASN1Integer(dP)); // d mod (p-1)
    sequence.add(ASN1Integer(dQ)); // d mod (q-1)
    sequence.add(ASN1Integer(qInv)); // q^-1 mod p

    final keyData = base64Encode(sequence.encodedBytes);
    final lines = <String>[];
    for (var i = 0; i < keyData.length; i += 64) {
      lines.add(keyData.substring(
        i,
        i + 64 > keyData.length ? keyData.length : i + 64,
      ));
    }

    return '-----BEGIN RSA PRIVATE KEY-----\n${lines.join('\n')}\n-----END RSA PRIVATE KEY-----\n';
  }

  Future<void> _saveKey() async {
    if (_privateKeyPem == null) return;

    final name = _keyNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a name for this key');
      return;
    }

    // Validate passphrase if enabled
    String? passphrase;
    if (_usePassphrase) {
      passphrase = _passphraseController.text;
      final confirm = _confirmPassphraseController.text;

      if (passphrase.isEmpty) {
        setState(() => _errorMessage = 'Please enter a passphrase');
        return;
      }

      if (passphrase != confirm) {
        setState(() => _errorMessage = 'Passphrases do not match');
        return;
      }

      if (passphrase.length < 8) {
        setState(
            () => _errorMessage = 'Passphrase must be at least 8 characters');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(credentialControllerProvider.notifier);

      final credential = await controller.saveCredential(
        name: name,
        type: _keyType,
        material: _privateKeyPem!,
        fingerprint: _fingerprint,
        passphrase: passphrase,
        requiresBiometric: _requiresBiometric,
      );

      if (credential != null) {
        if (mounted) {
          Navigator.of(context).pop(credential);
        }
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save key';
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error saving key: $e';
      });
    }
  }

  void _copyPublicKey() {
    if (_publicKey == null) return;

    Clipboard.setData(ClipboardData(text: _publicKey!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Public key copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate SSH Key'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_privateKeyPem == null) ...[
              _buildGenerateForm(),
            ] else ...[
              _buildKeyResult(),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Description
        Text(
          'Generate a new SSH key pair',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'The private key will be stored securely on your device.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 24),

        // Key type selection
        Text(
          'Key Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<CredentialType>(
          segments: const [
            ButtonSegment<CredentialType>(
              value: CredentialType.ed25519,
              label: Text('Ed25519'),
              icon: Icon(Icons.bolt),
            ),
            ButtonSegment<CredentialType>(
              value: CredentialType.rsa,
              label: Text('RSA-4096'),
              icon: Icon(Icons.security),
            ),
          ],
          selected: {_keyType},
          onSelectionChanged: (selection) {
            setState(() => _keyType = selection.first);
          },
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _keyType == CredentialType.ed25519
                  ? 'Ed25519 is the recommended choice. It\'s fast, secure, and produces smaller keys.'
                  : 'RSA-4096 offers maximum compatibility with older systems.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Generate button
        FilledButton.icon(
          onPressed: _isGenerating ? null : _generateKey,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.key),
          label: Text(_isGenerating ? 'Generating...' : 'Generate Key'),
        ),
      ],
    );
  }

  Widget _buildKeyResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success message
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Generated Successfully',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        SSHKeyUtils.getKeyTypeString(_keyType),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _privateKeyPem = null;
                      _publicKey = null;
                      _fingerprint = null;
                    });
                  },
                  tooltip: 'Generate New',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Fingerprint
        if (_fingerprint != null) ...[
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  SSHKeyUtils.formatFingerprint(_fingerprint!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Public key
        Text(
          'Public Key',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                _publicKey ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _copyPublicKey,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add this public key to your server\'s ~/.ssh/authorized_keys file.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 24),

        // Save form
        TextFormField(
          controller: _keyNameController,
          decoration: const InputDecoration(
            labelText: 'Key Name',
            hintText: 'e.g., Personal Laptop, Work MacBook',
            prefixIcon: Icon(Icons.label),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Passphrase option
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Encrypt with passphrase'),
                  subtitle: const Text('Add extra protection to your key'),
                  value: _usePassphrase,
                  onChanged: (value) => setState(() => _usePassphrase = value),
                  secondary: const Icon(Icons.lock),
                ),
                if (_usePassphrase) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passphraseController,
                          decoration: InputDecoration(
                            labelText: 'Passphrase',
                            hintText: 'At least 8 characters',
                            prefixIcon: const Icon(Icons.key),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassphrase
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _showPassphrase = !_showPassphrase,
                              ),
                            ),
                          ),
                          obscureText: !_showPassphrase,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassphraseController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Passphrase',
                            prefixIcon: Icon(Icons.key),
                          ),
                          obscureText: !_showPassphrase,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'The passphrase will be stored securely and used when connecting.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Biometric toggle
        SwitchListTile(
          title: const Text('Require biometric unlock'),
          subtitle: const Text('Use Face ID or fingerprint to access this key'),
          value: _requiresBiometric,
          onChanged: (value) => setState(() => _requiresBiometric = value),
          secondary: const Icon(Icons.fingerprint),
        ),
        const SizedBox(height: 24),

        // Save button
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveKey,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving...' : 'Save Key'),
        ),
      ],
    );
  }
}

// @telos L2:contract:component-command-ribbon

/// Built-in knowledge of common command structures for ribbon suggestions.
///
/// Provides a static, in-memory knowledge base of popular CLI tools and their
/// subcommands. Used by the [CommandRibbonController] to offer context-aware
/// completions as the user types.
class CommandKnowledge {
  CommandKnowledge._(); // Prevent instantiation

  /// Top-level subcommands for well-known CLI tools.
  static const Map<String, List<String>> subcommands = {
    'git': [
      'status',
      'add',
      'commit',
      'push',
      'pull',
      'checkout',
      'branch',
      'merge',
      'rebase',
      'log',
      'diff',
      'stash',
      'clone',
      'fetch',
    ],
    'docker': [
      'run',
      'ps',
      'images',
      'build',
      'compose',
      'exec',
      'logs',
      'stop',
      'rm',
      'pull',
      'push',
      'network',
      'volume',
    ],
    'kubectl': [
      'get',
      'apply',
      'delete',
      'describe',
      'logs',
      'exec',
      'port-forward',
      'scale',
      'rollout',
      'config',
    ],
    'npm': [
      'install',
      'run',
      'start',
      'test',
      'build',
      'publish',
      'init',
      'update',
      'audit',
      'ci',
    ],
    'yarn': [
      'add',
      'remove',
      'install',
      'run',
      'build',
      'test',
      'start',
    ],
    'systemctl': [
      'start',
      'stop',
      'restart',
      'status',
      'enable',
      'disable',
      'daemon-reload',
      'list-units',
    ],
    'aws': [
      's3',
      'ec2',
      'ecs',
      'lambda',
      'iam',
      'cloudformation',
      'logs',
      'ssm',
      'rds',
    ],
    'ssh': ['-i', '-p', '-L', '-R', '-D', '-N', '-v'],
    'apt': [
      'install',
      'update',
      'upgrade',
      'remove',
      'search',
      'list',
      'autoremove',
    ],
    'pip': ['install', 'uninstall', 'list', 'freeze', 'show', 'search'],
    'cargo': [
      'build',
      'run',
      'test',
      'check',
      'new',
      'init',
      'add',
      'update',
    ],
    'make': ['all', 'clean', 'install', 'test', 'build'],
    'terraform': [
      'init',
      'plan',
      'apply',
      'destroy',
      'fmt',
      'validate',
      'state',
    ],
  };

  /// Second-level subcommands for tools that have nested command hierarchies.
  static const Map<String, Map<String, List<String>>> nestedSubcommands = {
    'kubectl': {
      'get': [
        'pods',
        'services',
        'deployments',
        'nodes',
        'namespaces',
        'secrets',
        'configmaps',
        'ingress',
        'all',
      ],
      'describe': [
        'pod',
        'service',
        'deployment',
        'node',
        'namespace',
        'secret',
      ],
      'rollout': ['status', 'history', 'undo', 'restart'],
    },
    'docker': {
      'compose': [
        'up',
        'down',
        'ps',
        'logs',
        'build',
        'pull',
        'restart',
        'exec',
      ],
      'network': [
        'ls',
        'create',
        'rm',
        'inspect',
        'connect',
        'disconnect',
      ],
      'volume': ['ls', 'create', 'rm', 'inspect', 'prune'],
    },
    'aws': {
      's3': ['ls', 'cp', 'mv', 'rm', 'sync', 'mb', 'rb'],
      'ec2': [
        'describe-instances',
        'start-instances',
        'stop-instances',
        'run-instances',
      ],
    },
    'git': {
      'stash': ['push', 'pop', 'list', 'show', 'drop', 'apply', 'clear'],
      'remote': ['add', 'remove', 'rename', 'show', '-v'],
    },
  };

  /// Common shell symbols for quick access via the symbol tray.
  static const List<String> symbols = [
    '|',
    '>',
    '<',
    '&',
    ';',
    r'$',
    '~',
    '/',
    r'\',
    '"',
    "'",
    '`',
    '(',
    ')',
    '[',
    ']',
    '{',
    '}',
    '&&',
    '||',
    '>>',
    '2>',
    '2>&1',
  ];

  /// Returns the list of subcommands for [command], or `null` if unknown.
  static List<String>? getSubcommands(String command) {
    return subcommands[command];
  }

  /// Returns nested subcommands for a [command] + [subcommand] pair,
  /// or `null` if no nested knowledge exists.
  static List<String>? getNestedSubcommands(
    String command,
    String subcommand,
  ) {
    return nestedSubcommands[command]?[subcommand];
  }
}

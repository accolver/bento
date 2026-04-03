// @telos L2:contract:service-ai-gateway

/// Shell execution context used to improve AI command assistance.
class ShellContext {
  const ShellContext({
    required this.shell,
    required this.os,
    this.cwd,
    this.availableCommands = const [],
    this.recentCommands = const [],
  });

  final String shell;
  final String os;
  final String? cwd;
  final List<String> availableCommands;
  final List<String> recentCommands;

  @override
  bool operator ==(Object other) {
    return other is ShellContext &&
        other.shell == shell &&
        other.os == os &&
        other.cwd == cwd &&
        _listEquals(other.availableCommands, availableCommands) &&
        _listEquals(other.recentCommands, recentCommands);
  }

  @override
  int get hashCode => Object.hash(
        shell,
        os,
        cwd,
        Object.hashAll(availableCommands),
        Object.hashAll(recentCommands),
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

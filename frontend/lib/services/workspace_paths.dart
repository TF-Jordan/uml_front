import 'dart:io';

import 'package:path/path.dart' as p;

class WorkspacePaths {
  static String? resolveRepoRoot() {
    var current = Directory.current;
    while (true) {
      if (File(p.join(current.path, 'bin', 'uml2code')).existsSync()) {
        return current.path;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }
      current = parent;
    }
  }

  static String resolveWorkspaceRoot() {
    return resolveRepoRoot() ?? Directory.current.path;
  }

  static bool isWithinRoot(String root, String targetPath) {
    final normalizedRoot = p.normalize(p.absolute(root));
    final normalizedTarget = p.normalize(p.absolute(targetPath));
    return p.isWithin(normalizedRoot, normalizedTarget) ||
        normalizedRoot == normalizedTarget;
  }

  static String? relativeToRoot(String root, String targetPath) {
    if (!isWithinRoot(root, targetPath)) {
      return null;
    }
    return p.relative(targetPath, from: root);
  }
}

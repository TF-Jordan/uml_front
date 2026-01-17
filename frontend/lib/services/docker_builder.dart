import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DockerBuildResult {
  const DockerBuildResult(this.success, this.message);

  final bool success;
  final String message;
}

class DockerBuilder {
  static const String _defaultImage = 'blhack/uml2code-cli:latest';
  static Future<DockerBuildResult>? _imageFuture;

  static String resolveImageName() {
    final envName = Platform.environment['UML2CODE_IMAGE']?.trim();
    if (envName != null && envName.isNotEmpty) {
      return envName;
    }
    return _defaultImage;
  }

  static Future<DockerBuildResult> ensureImageAvailable({
    String? image,
    void Function(String line)? onLog,
  }) {
    final existing = _imageFuture;
    if (existing != null) {
      return existing.then((result) {
        if (!result.success) {
          _imageFuture = null;
        }
        return result;
      });
    }

    final future = _ensureImage(
      image: image ?? resolveImageName(),
      onLog: onLog,
    );
    _imageFuture = future;
    return future.then((result) {
      if (!result.success) {
        _imageFuture = null;
      }
      return result;
    });
  }

  static Future<DockerBuildResult> ensureBuilt({
    required String workingDirectory,
    String image = _defaultImage,
    void Function(String line)? onLog,
  }) {
    return ensureImageAvailable(image: image, onLog: onLog);
  }

  static Future<DockerBuildResult> _ensureImage({
    required String image,
    void Function(String line)? onLog,
  }) async {
    final exists = await _checkDockerImage(image);
    if (exists) {
      return const DockerBuildResult(true, '');
    }
    return _runPull(image: image, onLog: onLog);
  }

  static Future<bool> _checkDockerImage(String image) async {
    try {
      final result = await Process.run(
        'docker',
        ['image', 'inspect', image],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<DockerBuildResult> _runPull({
    required String image,
    void Function(String line)? onLog,
  }) async {
    try {
      final process = await Process.start(
        'docker',
        ['pull', image],
        runInShell: true,
      );

      final subscriptions = <StreamSubscription<String>>[];
      if (onLog != null) {
        subscriptions.add(
          process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(onLog),
        );
        subscriptions.add(
          process.stderr
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(onLog),
        );
      }

      final exitCode = await process.exitCode;
      for (final sub in subscriptions) {
        await sub.cancel();
      }

      if (exitCode != 0) {
        return DockerBuildResult(
          false,
          'Le téléchargement Docker a échoué pour $image (code $exitCode).',
        );
      }
      return const DockerBuildResult(true, '');
    } catch (e) {
      return DockerBuildResult(
        false,
        'Impossible de lancer docker pull pour $image: ${e.toString()}',
      );
    }
  }
}

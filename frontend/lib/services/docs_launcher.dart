import 'dart:io';

import 'package:flutter/material.dart';

import 'docker_builder.dart';
class DocsLauncher {
  static const String _url = 'http://127.0.0.1:5555';

  static Future<void> open(BuildContext context) async {
    final ready = await _ensureDocsRunning(context);
    if (!ready) {
      return;
    }
    await _openUrl(context, _url);
  }

  static Future<bool> _ensureDocsRunning(BuildContext context) async {
    final dockerReady = await _checkDockerAvailable();
    if (!dockerReady) {
      _showMessage(context, 'Docker est requis pour ouvrir la documentation.');
      return false;
    }
    final imageName = DockerBuilder.resolveImageName();
    final imageResult = await DockerBuilder.ensureImageAvailable(image: imageName);
    if (!imageResult.success) {
      _showMessage(context, imageResult.message);
      return false;
    }
    final running = await _isDocsContainerRunning();
    if (running) {
      return true;
    }
    final exists = await _docsContainerExists();
    if (exists) {
      await _removeDocsContainer();
    }
    final result = await Process.run(
      'docker',
      [
        'run',
        '-d',
        '--rm',
        '-p',
        '5555:5555',
        '--name',
        'uml2code-docs',
        imageName,
        'docs'
      ],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      final detail = result.stderr.toString().trim();
      if (detail.isNotEmpty) {
        _showMessage(context, 'Docs: $detail');
      } else {
        _showMessage(context, 'Impossible de lancer la documentation.');
      }
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    try {
      if (Platform.isWindows) {
        await Process.start('explorer', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.start('open', [url], runInShell: true);
      } else {
        await Process.start('xdg-open', [url], runInShell: true);
      }
    } catch (_) {
      _showMessage(context, 'Impossible d\'ouvrir la documentation.');
    }
  }

  static Future<bool> _checkDockerAvailable() async {
    try {
      final result =
          await Process.run('docker', ['--version'], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isDocsContainerRunning() async {
    try {
      final result = await Process.run(
        'docker',
        ['ps', '-q', '-f', 'name=uml2code-docs'],
        runInShell: true,
      );
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _docsContainerExists() async {
    try {
      final result = await Process.run(
        'docker',
        ['ps', '-a', '-q', '-f', 'name=uml2code-docs'],
        runInShell: true,
      );
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _removeDocsContainer() async {
    try {
      await Process.run(
        'docker',
        ['rm', '-f', 'uml2code-docs'],
        runInShell: true,
      );
    } catch (_) {}
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

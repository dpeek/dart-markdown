// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:io' show Directory, File, Platform, Process, exitCode;

import 'package:args/args.dart' show ArgParser;
import 'package:path/path.dart' show absolute;
import 'package:yaml/yaml.dart' show loadYaml;

const _dartdocDir = 'dartdoc-dir';
const _markdownBefore = 'before';
const _markdownAfter = 'after';
const _sdk = 'sdk';
const _help = 'help';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addSeparator('Usage: dartdoc-compare.dart [OPTIONS] <dart-package>')
    ..addOption(_dartdocDir, help: 'Directory of the dartdoc package')
    ..addOption(_markdownBefore, help: "Markdown package 'before' ref")
    ..addOption(_markdownAfter,
        defaultsTo: 'HEAD', help: "Markdown package 'after' ref (or 'local')")
    ..addFlag(_sdk,
        defaultsTo: false, negatable: false, help: 'Is the package the SDK?')
    ..addFlag(_help, abbr: 'h', hide: true);

  var options = parser.parse(arguments);
  if (options[_help] as bool) {
    print(parser.usage);
    exitCode = 0;
    return;
  }
  if (options[_dartdocDir] == null || options[_markdownBefore] == null) {
    print(
        'Invalid arguments: Options --$_dartdocDir and --$_markdownBefore must be specified');
    print(parser.usage);
    exitCode = 1;
    return;
  }
  var comparer = DartdocCompare(
      options[_dartdocDir] as String,
      options[_markdownBefore] as String,
      options[_markdownAfter] as String,
      absolute(options[_dartdocDir] as String, 'bin/dartdoc.dart'),
      absolute(options[_dartdocDir] as String, 'pubspec.yaml'),
      options[_sdk] as bool);

  String? path;
  if (comparer.sdk) {
    if (options.rest.isNotEmpty) {
      path = options.rest.single;
    }
  } else {
    path = options.rest.single;
  }

  if (comparer.compare(path)) {
    exitCode = 0;
  } else {
    exitCode = 1;
  }
}

class DartdocCompare {
  final String dartdocDir;
  final String markdownBefore;
  final String markdownAfter;
  final String dartdocBin;
  final String dartdocPubspecPath;
  final bool sdk;
  final String markdownPath = File(Platform.script.path).parent.parent.path;

  DartdocCompare(this.dartdocDir, this.markdownBefore, this.markdownAfter,
      this.dartdocBin, this.dartdocPubspecPath, this.sdk);

  bool compare(String? package) {
    // Generate docs with Markdown "Before".
    var outBefore = _runDartdoc(markdownBefore, package);

    // Generate docs with Markdown "After".
    var outAfter = _runDartdoc(markdownAfter, package);

    // Compare outputs
    var diffOptions = ['-r', '-B', outBefore, outAfter];
    var result = Process.runSync('diff', diffOptions, runInShell: true);
    var nlines = '\n'.allMatches(result.stdout as String).length;
    print('Diff lines: $nlines');
    print('diff ${diffOptions.join(" ")}');
    return result.exitCode == 0;
  }

  String _runDartdoc(String markdownRef, String? path) {
    print('==========================================================');
    print('Running dartdoc for $markdownRef...');
    print('==========================================================');
    _doInPath(dartdocDir, () {
      var returnCode = _updateDartdocPubspec(markdownRef);
      if (returnCode != 0) {
        throw Exception("Could not update dartdoc's pubspec!");
      }
    });
    return _doInPath(path, () {
      if (!sdk) {
        _system('pub', ['upgrade']);
      }
      var out = Directory.systemTemp
          .createTempSync('dartdoc-compare-${markdownRef}__');
      var cmd = 'dart';
      var args = ['$dartdocBin', '--output=${out.path}'];

      if (sdk) {
        args.add('--sdk-docs');
      }

      print('Command: $cmd ${args.join(' ')}');
      var startTime = DateTime.now();
      _system(cmd, args);
      var endTime = DateTime.now();
      var duration = endTime.difference(startTime).inSeconds;
      print('dartdoc generation for $markdownRef took $duration seconds.');
      print('');

      return out.path;
    });
  }

  int _updateDartdocPubspec(String markdownRef) {
    var dartdocPubspec =
        loadYaml(File(dartdocPubspecPath).readAsStringSync()) as Map;
    // make modifiable copy
    dartdocPubspec = jsonDecode(jsonEncode(dartdocPubspec)) as Map;

    if (markdownRef == 'local') {
      (dartdocPubspec['dependencies'] as Map)['markdown'] = {
        'path': markdownPath,
      };
    } else {
      (dartdocPubspec['dependencies'] as Map)['markdown'] = {
        'git': {
          'url': 'git://github.com/dart-lang/markdown.git',
          'ref': markdownRef
        }
      };
    }

    File(dartdocPubspecPath).writeAsStringSync(jsonEncode(dartdocPubspec));
    return _system('pub', ['upgrade']);
  }
}

int _system(String cmd, List<String> args) {
  var result = Process.runSync(cmd, args);
  print(result.stdout);
  print(result.stderr);
  return result.exitCode;
}

T _doInPath<T>(String? path, T Function() f) {
  if (path == null) {
    return f();
  }

  var former = Directory.current.path;
  Directory.current = path;
  try {
    return f();
  } finally {
    Directory.current = former;
  }
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Used by `dataCasesUnder` below to find the current directory.
library markdown.test.util;

import 'dart:mirrors';

import 'package:expected_output/expected_output.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Run tests defined in "*.unit" files inside directory [name].
void testDirectory(
  String name, {
  ExtensionSet extensionSet,
}) {
  for (var dataCase
      in dataCasesUnder(library: #markdown.test.util, subdirectory: name)) {
    var description =
        '${dataCase.directory}/${dataCase.file}.unit ${dataCase.description}';
    validateCore(
      description,
      dataCase.input,
      dataCase.expectedOutput,
      extensionSet: extensionSet,
    );
  }
}

// Locate the "test" directory. Use mirrors so that this works with the test
// package, which loads this suite into an isolate.
String get _testDir =>
    p.dirname(currentMirrorSystem().findLibrary(#markdown.test.util).uri.path);

void testFile(String file,
    {Iterable<BlockSyntax> blockSyntaxes,
    Iterable<InlineSyntax> inlineSyntaxes}) {
  for (var dataCase in dataCasesInFile(path: p.join(_testDir, file))) {
    var description =
        '${dataCase.directory}/${dataCase.file}.unit ${dataCase.description}';
    validateCore(description, dataCase.input, dataCase.expectedOutput,
        blockSyntaxes: blockSyntaxes, inlineSyntaxes: inlineSyntaxes);
  }
}

void validateCore(
  String description,
  String markdown,
  String html, {
  Iterable<BlockSyntax> blockSyntaxes,
  Iterable<InlineSyntax> inlineSyntaxes,
  Resolver linkResolver,
  Resolver imageLinkResolver,
  ExtensionSet extensionSet,
  bool inlineOnly = false,
  bool checkable = false,
}) {
  test(description, () {
    var result = markdownToHtml(markdown,
        blockSyntaxes: blockSyntaxes,
        inlineSyntaxes: inlineSyntaxes,
        extensionSet: extensionSet,
        linkResolver: linkResolver,
        imageLinkResolver: imageLinkResolver,
        inlineOnly: inlineOnly, checkable: checkable);

    markdownPrintOnFailure(markdown, html, result);

    expect(result, html);
  });
}

String whitespaceColor(String input) => input
    .replaceAll(' ', ansi.lightBlue.wrap('·'))
    .replaceAll('\t', ansi.backgroundDarkGray.wrap('\t'));

void markdownPrintOnFailure(String markdown, String expected, String actual) {
  printOnFailure("""
INPUT:
'''r
${whitespaceColor(markdown)}'''            
           
EXPECTED:
'''r
${whitespaceColor(expected)}'''

GOT:
'''r
${whitespaceColor(actual)}'''
""");
}

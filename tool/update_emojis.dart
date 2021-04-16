import 'dart:async';
import 'dart:convert';
import 'dart:io';

// TODO(srawlins): Switch to https://github.com/muan/unicode-emoji-json. This
// is definitely a breaking change; the emoji names are not necessarily the
// same.
final _emojisJsonRawUrl =
    'https://raw.githubusercontent.com/muan/emojilib/v2.4.0/emojis.json';
final _emojisFilePath = 'lib/src/emojis.dart';

Future<void> main() async {
  var client = HttpClient();
  var request = await client.getUrl(Uri.parse(_emojisJsonRawUrl));
  var response = await request.close();
  var rawJson = jsonDecode(
          await response.cast<List<int>>().transform(utf8.decoder).join(''))
      as Map<String, dynamic>;
  var json = rawJson.map((String alias, dynamic info) =>
      MapEntry(alias, (info as Map).cast<String, dynamic>()));
  var emojisContent = StringBuffer('''
// GENERATED FILE. DO NOT EDIT.
//
// This file was generated from emojilib's emoji data file:
// $_emojisJsonRawUrl
// at ${DateTime.now()} by the script, tool/update_emojis.dart.

''');
  emojisContent.writeln('const emojis = <String, String>{');
  var emojiCount = 0;
  var ignored = <String>[];
  json.forEach((String alias, Map<String, dynamic> info) {
    if (info['char'] != null) {
      emojisContent.writeln("  '$alias': '${info['char']}',");
      emojiCount++;
    } else {
      ignored.add(alias);
    }
  });
  emojisContent.writeln('};');
  File(_emojisFilePath).writeAsStringSync(emojisContent.toString());
  print('Wrote data to $_emojisFilePath for $emojiCount emojis, '
      'ignoring ${ignored.length}: ${ignored.join(', ')}.');
  exit(0);
}

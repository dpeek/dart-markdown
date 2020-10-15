// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:markdown/markdown.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  testDirectory('original');

  // Block syntax extensions
  testFile('extensions/fenced_code_blocks.unit',
      blockSyntaxes: [const FencedCodeBlockSyntax()]);
  testFile('extensions/headers_with_ids.unit',
      blockSyntaxes: [const HeaderWithIdSyntax()]);
  testFile('extensions/setext_headers_with_ids.unit',
      blockSyntaxes: [const SetextHeaderWithIdSyntax()]);
  testFile('extensions/tables.unit', blockSyntaxes: [const TableSyntax()]);

  // Inline syntax extensions
  testFile('extensions/emojis.unit', inlineSyntaxes: [EmojiSyntax()]);
  testFile('extensions/inline_html.unit', inlineSyntaxes: [InlineHtmlSyntax()]);
  testFile('extensions/strikethrough.unit',
      inlineSyntaxes: [StrikethroughSyntax()]);

  testDirectory('common_mark');
  testDirectory('gfm', extensionSet: ExtensionSet.gitHubFlavored);

  group('Checklist 1', () {
    validateCore(
        'Checklist',
        '''
First.
* [ ] Item 1
* [x] Item 2
  * [ ]  Item 3
  * [ ] Item 4
    * [ ] Item 5
  * [ ] Item 6
* [ ] Item 7
  * [ ] Item 8
* [x] Item 9

Others
''',
        '''
<p>First.</p>
<ul>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 1</li>
<li class="todo"><input checked="checked" disabled="disabled" class="todo" type="checkbox" /> Item 2
<ul>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" />  Item 3</li>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 4
<ul>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 5</li>
</ul>
</li>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 6</li>
</ul>
</li>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 7
<ul>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 8</li>
</ul>
</li>
<li class="todo"><input checked="checked" disabled="disabled" class="todo" type="checkbox" /> Item 9</li>
</ul>
<p>Others</p>
''');
    });

  group('Checklist 1 with data-line', () {
    validateCore(
        'Checklist',
        '''
First.
* [ ] Item 1
* [x] Item 2
  * [ ]  Item 3
  * [ ] Item 4
    * [ ] Item 5
  * [ ] Item 6
* [ ] Item 7
  * [ ] Item 8
* [x] Item 9

Others
''',
        '''
<p>First.</p>
<ul>
<li class="todo"><input data-line="1" class="todo" type="checkbox" /> Item 1</li>
<li class="todo"><input checked="checked" data-line="2" class="todo" type="checkbox" /> Item 2
<ul>
<li class="todo"><input data-line="3" class="todo" type="checkbox" />  Item 3</li>
<li class="todo"><input data-line="4" class="todo" type="checkbox" /> Item 4
<ul>
<li class="todo"><input data-line="5" class="todo" type="checkbox" /> Item 5</li>
</ul>
</li>
<li class="todo"><input data-line="6" class="todo" type="checkbox" /> Item 6</li>
</ul>
</li>
<li class="todo"><input data-line="7" class="todo" type="checkbox" /> Item 7
<ul>
<li class="todo"><input data-line="8" class="todo" type="checkbox" /> Item 8</li>
</ul>
</li>
<li class="todo"><input checked="checked" data-line="9" class="todo" type="checkbox" /> Item 9</li>
</ul>
<p>Others</p>
''', checkable: true); //data-line will be generated instead
    });

  group('Checklist', () {
    validateCore(
        'Checklist 2',
        '''
First.
1. [ ] Item 1
1. Item 2
    * [ ]  Item 3
    * [ ] Item 4
        * [x] Item 5
    * Item 6
1. [ ] Item 7
    * Item 8
1. Item 9

Others
''',
        '''
<p>First.</p>
<ol>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 1</li>
<li>Item 2
<ul>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" />  Item 3</li>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 4
<ul>
<li class="todo"><input checked="checked" disabled="disabled" class="todo" type="checkbox" /> Item 5</li>
</ul>
</li>
<li>Item 6</li>
</ul>
</li>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> Item 7
<ul>
<li>Item 8</li>
</ul>
</li>
<li>Item 9</li>
</ol>
<p>Others</p>
''');
    });

    validateCore(
        'Checklist 3',
        '''
- [ ] AA [ ] b
- [ ] BB 
- [ ]  
- [ ] 
''',
        '''
<ul>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> AA [ ] b</li>
<li class="todo"><input disabled="disabled" class="todo" type="checkbox" /> BB </li>
<li>[ ]  </li>
<li>[ ] </li>
</ul>
''');

    validateCore(
        'Checklist 4',
        '''
* [ ] Item 1
    * 1.1

* [x] Item 2
''',
        '''
<ul>
<li class="todo">
<p><input disabled="disabled" class="todo" type="checkbox" /> Item 1</p>
<ul>
<li>1.1</li>
</ul>
</li>
<li class="todo">
<p><input checked="checked" disabled="disabled" class="todo" type="checkbox" /> Item 2</p>
</li>
</ul>
''');

  group('Corner cases', () {
    validateCore('Incorrect Links', '''
5 Ethernet ([Music](
''', '''
<p>5 Ethernet ([Music](</p>
''');

    validateCore('Escaping code block language', '''
```"/><a/href="url">arbitrary_html</a>
```
''', '''
<pre><code class="language-&quot;/&gt;&lt;a/href=&quot;url&quot;&gt;arbitrary_html&lt;/a&gt;"></code></pre>
''');

    validateCore('Unicode ellipsis as punctuation', '''
"Connecting dot **A** to **B.**…"
''', '''
<p>"Connecting dot <strong>A</strong> to <strong>B.</strong>…"</p>
''');
  });

  group('Corner cases', () {
    validateCore(
        'Incorrect Links',
        '''
5 Ethernet ([Music](
''',
        '''
<p>5 Ethernet ([Music](</p>
''');
    });

  group('Resolver', () {
    Node nyanResolver(String text, [_]) =>
        text.isEmpty ? null : Text('~=[,,_${text}_,,]:3');
    validateCore(
        'simple link resolver',
        '''
resolve [this] thing
''',
        '''
<p>resolve ~=[,,_this_,,]:3 thing</p>
''',
        linkResolver: nyanResolver);

    validateCore(
        'simple image resolver',
        '''
resolve ![this] thing
''',
        '''
<p>resolve ~=[,,_this_,,]:3 thing</p>
''',
        imageLinkResolver: nyanResolver);

    validateCore(
        'can resolve link containing inline tags',
        '''
resolve [*star* _underline_] thing
''',
        '''
<p>resolve ~=[,,_*star* _underline__,,]:3 thing</p>
''',
        linkResolver: nyanResolver);

    validateCore(
        'link resolver uses un-normalized link label',
        '''
resolve [TH  IS] thing
''',
        '''
<p>resolve ~=[,,_TH  IS_,,]:3 thing</p>
''',
        linkResolver: nyanResolver);

    validateCore(
        'can resolve escaped brackets',
        r'''
resolve [\[\]] thing
''',
        '''
<p>resolve ~=[,,_[]_,,]:3 thing</p>
''',
        linkResolver: nyanResolver);

    validateCore(
        'can choose to _not_ resolve something, like an empty link',
        r'''
resolve [[]] thing
''',
        '''
<p>resolve ~=[,,_[]_,,]:3 thing</p>
''',
        linkResolver: nyanResolver);
  });

  group('Custom inline syntax', () {
    var nyanSyntax = <InlineSyntax>[TextSyntax('nyan', sub: '~=[,,_,,]:3')];
    validateCore(
        'simple inline syntax',
        '''
nyan''',
        '''<p>~=[,,_,,]:3</p>
''',
        inlineSyntaxes: nyanSyntax);

    validateCore('dart custom links', 'links [are<foo>] awesome',
        '<p>links <a>are&lt;foo></a> awesome</p>\n',
        linkResolver: (String text, [_]) =>
            Element.text('a', text.replaceAll('<', '&lt;')));

    // TODO(amouravski): need more tests here for custom syntaxes, as some
    // things are not quite working properly. The regexps are sometime a little
    // too greedy, I think.
  });

  group('Inline only', () {
    validateCore(
        'simple line',
        '''
        This would normally create a paragraph.
        ''',
        '''
        This would normally create a paragraph.
        ''',
        inlineOnly: true);
    validateCore(
        'strong and em',
        '''
        This would _normally_ create a **paragraph**.
        ''',
        '''
        This would <em>normally</em> create a <strong>paragraph</strong>.
        ''',
        inlineOnly: true);
    validateCore(
        'link',
        '''
        This [link](http://www.example.com/) will work normally.
        ''',
        '''
        This <a href="http://www.example.com/">link</a> will work normally.
        ''',
        inlineOnly: true);
    validateCore(
        'references do not work',
        '''
        [This][] shouldn't work, though.
        ''',
        '''
        [This][] shouldn't work, though.
        ''',
        inlineOnly: true);
    validateCore(
        'less than and ampersand are escaped',
        '''
        < &
        ''',
        '''
        &lt; &amp;
        ''',
        inlineOnly: true);
    validateCore(
        'keeps newlines',
        '''
        This paragraph
        continues after a newline.
        ''',
        '''
        This paragraph
        continues after a newline.
        ''',
        inlineOnly: true);
    validateCore(
        'ignores block-level markdown syntax',
        '''
        1. This will not be an <ol>.
        ''',
        '''
        1. This will not be an <ol>.
        ''',
        inlineOnly: true);
  });
}

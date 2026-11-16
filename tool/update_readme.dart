// Regenerates the auto-generated sections of README.md from the code.
//
//   dart tool/update_readme.dart          rewrite README.md if it is stale
//   dart tool/update_readme.dart --check  exit 1 if README.md is stale
//
// A section is everything between `<!-- AUTO:name:START -->` and
// `<!-- AUTO:name:END -->`. Text outside the markers is never touched.
// The pre-commit hook in .githooks/ runs this on every commit.

import 'dart:io';

const _readmePath = 'README.md';

void main(List<String> args) {
  final check = args.contains('--check');

  if (!File('pubspec.yaml').existsSync() || !Directory('lib').existsSync()) {
    stderr.writeln('Run this from the project root (next to pubspec.yaml).');
    exit(2);
  }

  final readme = File(_readmePath);
  final original = readme.readAsStringSync();
  final eol = original.contains('\r\n') ? '\r\n' : '\n';
  var text = original.replaceAll('\r\n', '\n');

  final pubspec = _Pubspec.read();
  final sections = <String, String>{
    'overview': _overview(pubspec),
    'structure': _structure(),
    'inventory': _inventory(),
    'dependencies': _dependencies(pubspec),
    'env': _envVariables(),
    'assets_tests': _assetsAndTests(),
  };

  for (final entry in sections.entries) {
    final start = '<!-- AUTO:${entry.key}:START -->';
    final end = '<!-- AUTO:${entry.key}:END -->';
    final from = text.indexOf(start);
    final to = text.indexOf(end);
    if (from < 0 || to < from) {
      stderr.writeln('README.md is missing the markers for "${entry.key}".');
      exit(2);
    }
    text = '${text.substring(0, from + start.length)}\n'
        '${entry.value.trimRight()}\n'
        '${text.substring(to)}';
  }

  final updated = text.replaceAll('\n', eol);
  if (updated == original) {
    stdout.writeln('README.md is up to date.');
    return;
  }
  if (check) {
    stderr.writeln(
      'README.md is out of date. Run: dart tool/update_readme.dart',
    );
    exit(1);
  }
  readme.writeAsStringSync(updated);
  stdout.writeln('README.md updated.');
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

String _overview(_Pubspec pubspec) {
  final screens = _dartFiles('lib/ui').where(_isScreen).length;
  final blocs = _dartFiles('lib/bloc')
      .where((f) => f.endsWith('_bloc.dart') || f.endsWith('_cubit.dart'))
      .length;
  final rows = [
    ['Package', '`${pubspec.name}`'],
    ['Version', '`${pubspec.version}`'],
    ['Dart SDK', '`${pubspec.sdk}`'],
    ['Screens', '$screens'],
    ['BLoCs / cubits', '$blocs'],
    ['API service files', '${_dartFiles('lib/api').length}'],
    ['Model files', '${_dartFiles('lib/models').length}'],
    ['Service files', '${_dartFiles('lib/services').length}'],
    ['Dart files in `lib/`', '${_dartFiles('lib').length}'],
  ];
  return _table(['', ''], rows);
}

String _structure() {
  final out = StringBuffer('```\nlib/\n');
  final top = _childDirs('lib');
  if (File('lib/main.dart').existsSync()) {
    out.writeln('├── main.dart');
  }
  for (var i = 0; i < top.length; i++) {
    final dir = top[i];
    final lastTop = i == top.length - 1;
    out.writeln(
      '${lastTop ? '└──' : '├──'} ${_name(dir)}/'
      '${_count(_dartFiles(dir).length)}',
    );
    final subs = _childDirs(dir);
    for (var j = 0; j < subs.length; j++) {
      final lastSub = j == subs.length - 1;
      out.writeln(
        '${lastTop ? '    ' : '│   '}${lastSub ? '└──' : '├──'} '
        '${_name(subs[j])}/${_count(_dartFiles(subs[j]).length)}',
      );
    }
  }
  out.writeln('```');
  return out.toString();
}

String _inventory() {
  final out = StringBuffer();

  out.writeln('**Screens** (`lib/ui`)\n');
  out.writeln(
    _groupTable('lib/ui', 'Area', 'Screens', _isScreen, (f) => _base(f)),
  );

  out.writeln('\n**BLoCs / cubits** (`lib/bloc`)\n');
  out.writeln(
    _groupTable(
      'lib/bloc',
      'Area',
      'BLoCs',
      (f) => f.endsWith('_bloc.dart') || f.endsWith('_cubit.dart'),
      (f) => _base(f),
    ),
  );

  out.writeln('\n**API services** (`lib/api`)\n');
  out.writeln(
    _groupTable('lib/api', 'Area', 'Files', (f) => true, (f) => _base(f)),
  );

  out.writeln('\n**Services** (`lib/services`)\n');
  out.writeln(
    _groupTable('lib/services', 'Area', 'Files', (f) => true, (f) => _base(f)),
  );
  return out.toString();
}

String _dependencies(_Pubspec pubspec) {
  final out = StringBuffer();
  out.writeln(_table(['Package', 'Version'], _depRows(pubspec.dependencies)));
  out.writeln('\n**Dev dependencies**\n');
  out.writeln(
    _table(['Package', 'Version'], _depRows(pubspec.devDependencies)),
  );
  return out.toString();
}

String _envVariables() {
  final pattern = RegExp(r'''dotenv\.env\[\s*['"]([A-Z0-9_]+)['"]\s*\]''');
  final usedIn = <String, Set<String>>{};
  for (final file in _dartFiles('lib')) {
    final source = File(file).readAsStringSync();
    for (final match in pattern.allMatches(source)) {
      usedIn.putIfAbsent(match.group(1)!, () => <String>{}).add(file);
    }
  }
  final names = usedIn.keys.toList()..sort();
  final rows = <List<String>>[];
  for (final name in names) {
    final files = usedIn[name]!.toList()..sort();
    final where = files.length <= 2
        ? files.map((f) => '`$f`').join(', ')
        : '`${files.first}` and ${files.length - 1} more files';
    rows.add(['`$name`', where]);
  }
  return _table(['Variable', 'Read in'], rows);
}

String _assetsAndTests() {
  final out = StringBuffer('**Assets**\n\n');
  final assetRows = <List<String>>[];
  for (final dir in _childDirs('assets')) {
    final files = _files(dir);
    assetRows.add(['`$dir/`', '${files.length}']);
  }
  out.writeln(_table(['Folder', 'Files'], assetRows));

  out.writeln('\n**Tests** (`flutter test`)\n');
  final tests = _dartFiles('test');
  if (tests.isEmpty) {
    out.writeln('_No tests yet._');
  } else {
    for (final test in tests) {
      out.writeln('- `$test`');
    }
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _isScreen(String path) {
  final name = _base(path);
  const extra = {'login', 'splash', 'driver_home', 'operator_dashboard'};
  return name.endsWith('_screen') ||
      name.endsWith('_Screen') ||
      name.endsWith('_page') ||
      name == 'scanner_home' ||
      name == 'operator_home' ||
      extra.contains(name);
}

/// One table row per first-level folder under [root], listing matching files.
String _groupTable(
  String root,
  String groupHeader,
  String itemsHeader,
  bool Function(String path) include,
  String Function(String path) label,
) {
  final rows = <List<String>>[];
  for (final dir in _childDirs(root)) {
    final items = _dartFiles(dir).where(include).map(label).toList()..sort();
    if (items.isEmpty) continue;
    rows.add([
      '`${_name(dir)}` (${items.length})',
      items.map((i) => '`$i`').join(', '),
    ]);
  }
  return _table([groupHeader, itemsHeader], rows);
}

List<List<String>> _depRows(Map<String, String> deps) {
  final names = deps.keys.toList()..sort();
  return [
    for (final name in names) ['`$name`', '`${deps[name]}`'],
  ];
}

String _table(List<String> headers, List<List<String>> rows) {
  final out = StringBuffer();
  out.writeln('| ${headers.join(' | ')} |');
  out.writeln('|${headers.map((_) => '---').join('|')}|');
  for (final row in rows) {
    out.writeln('| ${row.join(' | ')} |');
  }
  return out.toString().trimRight();
}

String _count(int dartFiles) =>
    dartFiles == 0 ? '' : '  ($dartFiles ${dartFiles == 1 ? 'file' : 'files'})';

String _norm(String path) => path.replaceAll('\\', '/');

String _name(String path) => path.substring(path.lastIndexOf('/') + 1);

String _base(String path) {
  final name = _name(path);
  return name.endsWith('.dart') ? name.substring(0, name.length - 5) : name;
}

List<String> _childDirs(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => _norm(d.path))
      .where((p) => !_name(p).startsWith('.'))
      .toList()
    ..sort();
}

List<String> _files(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => _norm(f.path))
      .toList()
    ..sort();
}

List<String> _dartFiles(String root) =>
    _files(root).where((f) => f.endsWith('.dart')).toList();

/// The few pubspec.yaml fields the README needs, read without a YAML package
/// so this script runs with plain `dart` and no `pub get`.
class _Pubspec {
  _Pubspec(
    this.name,
    this.version,
    this.sdk,
    this.dependencies,
    this.devDependencies,
  );

  final String name;
  final String version;
  final String sdk;
  final Map<String, String> dependencies;
  final Map<String, String> devDependencies;

  static _Pubspec read() {
    var name = '';
    var version = '';
    var sdk = '';
    final deps = <String, String>{};
    final devDeps = <String, String>{};
    var section = '';

    for (final raw in File('pubspec.yaml').readAsLinesSync()) {
      final line = _stripComment(raw);
      if (line.trim().isEmpty) continue;
      final indent = line.length - line.trimLeft().length;
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final key = line.substring(0, colon).trim();
      final value = _unquote(line.substring(colon + 1).trim());

      if (indent == 0) {
        section = key;
        if (key == 'name') name = value;
        if (key == 'version') version = value;
      } else if (indent == 2) {
        if (section == 'environment' && key == 'sdk') sdk = value;
        if (section == 'dependencies') deps[key] = value;
        if (section == 'dev_dependencies') devDeps[key] = value;
      } else if (indent == 4 && key == 'sdk') {
        // e.g. `flutter:` followed by `sdk: flutter`
        final target = section == 'dependencies'
            ? deps
            : section == 'dev_dependencies'
                ? devDeps
                : null;
        if (target != null && target.isNotEmpty) {
          final last = target.keys.last;
          if (target[last]!.isEmpty) target[last] = 'sdk: $value';
        }
      }
    }
    return _Pubspec(name, version, sdk, deps, devDeps);
  }

  static String _stripComment(String line) {
    final hash = line.indexOf(' #');
    if (line.trimLeft().startsWith('#')) return '';
    return hash < 0 ? line : line.substring(0, hash);
  }

  static String _unquote(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}

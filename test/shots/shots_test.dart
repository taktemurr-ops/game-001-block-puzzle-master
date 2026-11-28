// Oyun testi ekran görüntüleri (yalnız SHOTS=true ile): gerçek yazı tipleriyle
// telefon (393x852) ve tablet (1280x800) boyutunda açılış, birkaç dokunuş
// sonrası ve ipuçlu ilerleme. CI'da pt5-shots dalına eklenir.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/block_view.dart';
import 'package:game_001_block_puzzle_master/game/rules.dart';
import 'package:studio_core/app/studio_ui.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';

const _on = bool.fromEnvironment('SHOTS');

Future<void> _fonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final files = dir.listSync().whereType<File>().toList();
  final roboto = FontLoader('Roboto');
  for (final f in files.where((f) => f.path.contains('Roboto') && f.path.endsWith('.ttf'))) {
    roboto.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
  }
  await roboto.load();
  // Tuvale yazılan metinler (TextPainter, aile belirtilmemiş) test motorunun
  // varsayılan ailesini kullanır: onu da gerçek yazı tipiyle doldur.
  for (final fam in const ['FlutterTest', 'Ahem']) {
    final l = FontLoader(fam);
    for (final f in files.where((f) => f.path.contains('Roboto-Regular') || f.path.contains('Roboto-Bold'))) {
      l.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    }
    await l.load();
  }
  final icons = FontLoader('MaterialIcons');
  for (final f in files.where((f) => f.path.contains('MaterialIcons'))) {
    icons.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
  }
  await icons.load();
  // CJK yüzler (Mahjong karakterleri) için sistemde Noto varsa
  for (final path in const ['/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc', '/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc']) {
    final f = File(path);
    if (f.existsSync()) {
      final cjk = FontLoader('Roboto');
      cjk.addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
      await cjk.load();
    }
  }
}

PlayContext _ctx(GeneratedLevel gl) => PlayContext(
      spec: gl.spec,
      generated: gl,
      resume: const {},
      pieceColors: const [Color(0xFFE05A47), Color(0xFF3E8ED0), Color(0xFF4CAF6A), Color(0xFFF2B33D), Color(0xFF9B5CC4), Color(0xFF2EB8B0)],
      background: const [Color(0xFF1A2E5C), Color(0xFF3A6FC4)],
      colorBlind: false,
      reducedMotion: false,
      leftHanded: false,
      lang: 'tr',
      t: (k, [p = const {}]) => k,
      finish: (_) {},
      saveResume: (_) {},
      requestHint: () async => true,
      requestBooster: () async => true,
      requestContinue: () async => false,
      sfx: (_) {},
    );

final _key = GlobalKey();

Widget _host(Widget child, Color seed) => RepaintBoundary(
      key: _key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: seed, fontFamily: 'Roboto', extensions: [StudioLook.fromSeed(seed)]),
        home: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B2347), Color(0xFF2B3C78)])),
            child: SafeArea(child: child),
          ),
        ),
      ),
    );

Future<void> _snap(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('build/shots/$name.png')..createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

const _games = {
  'blok': (Color(0xFF34558B), false),
  'blok-sudoku': (Color(0xFF8A5A34), true),
};

void main() {
  if (!_on) return;
  for (final e in _games.entries) {
    testWidgets('shots ${e.key}', (t) async {
      await _fonts();
      for (final dev in const [('p', Size(393, 852)), ('t', Size(1280, 800))]) {
        t.view.physicalSize = dev.$2;
        t.view.devicePixelRatio = 1;
        for (final lv in dev.$1 == 't' ? const [10] : const [1, 5, 10]) {
          final rules = BlockRules(sudoku: e.value.$2, id: 'oyun-${e.key}');
          final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);
          final gl = rules.build(planner.spec(lv));
          await t.pumpWidget(_host(BlockView(key: ValueKey('${e.key}$lv${dev.$1}'), ctx: _ctx(gl)), e.value.$1));
          await t.pump(const Duration(milliseconds: 300));
          await _snap(t, '${e.key}_L${lv}_${dev.$1}_0acilis');
          if (dev.$1 == 't') continue;
          final hint = find.byIcon(Icons.lightbulb);
          if (hint.evaluate().isNotEmpty) {
            await t.tap(hint, warnIfMissed: false);
            await t.pump(const Duration(milliseconds: 300));
          }
          await _snap(t, '${e.key}_L${lv}_${dev.$1}_1ipucu');
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 2));
        }
      }
      t.view.reset();
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}

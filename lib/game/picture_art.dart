import 'dart:math' as math;

import 'package:studio_core/core/rng.dart';

/// Blok Macerası resimleri: tahtanın altına gizlenen, satır temizledikçe
/// açılan prosedürel motifler (kalp, yıldız, lale, kilim, hilal, ev, ağaç,
/// balık, güneş, çiçek). Değerler 1..8 renk dizinidir, 0 resim dışı.
const kPictureThemes = 10;


List<int> blockPicture(int size, int difficulty, SeededRandom r) {
  final theme = r.nextInt(kPictureThemes);
  final scale = math.min(0.98, 0.62 + 0.04 * difficulty);
  final c1 = 1 + r.nextInt(8);
  var c2 = 1 + r.nextInt(8);
  if (c2 == c1) c2 = c1 % 8 + 1;
  final c3 = (c2 % 8) + 1 == c1 ? (c1 % 8) + 1 : (c2 % 8) + 1;
  final out = List<int>.filled(size * size, 0);
  final h = (size - 1) / 2;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // -1..1, ölçekli
      final nx = (x - h) / (h * scale + 0.0001), ny = (y - h) / (h * scale + 0.0001);
      if (nx.abs() > 1.05 || ny.abs() > 1.05) continue;
      final d = math.sqrt(nx * nx + ny * ny);
      final a = math.atan2(ny, nx);
      var v = 0;
      switch (theme) {
        case 0: // kalp
          final yy = -ny * 1.1 + 0.25;
          if (math.pow(nx * nx + yy * yy - 0.5, 3) - nx * nx * yy * yy * yy < 0) v = d < 0.35 ? c2 : c1;
        case 1: // yıldız
          final k = math.cos(5 * (a + math.pi / 2)) * 0.35 + 0.65;
          if (d <= k) v = d < 0.35 ? c2 : c1;
        case 2: // lale
          final cup = ny < 0.2 && d < 0.75 && !(ny < -0.45 && nx.abs() < 0.18);
          final stem = nx.abs() < 0.18 && ny >= 0.2;
          if (cup) v = c1;
          if (stem) v = c2;
        case 3: // kilim baklavası
          final m = nx.abs() + ny.abs();
          if (m <= 1.0) v = (m * 3).floor().isEven ? c1 : c2;
        case 4: // hilal ve yıldız
          final inner = math.sqrt((nx - 0.35) * (nx - 0.35) + ny * ny);
          if (d < 0.9 && inner > 0.65) v = c1;
          if (math.sqrt((nx - 0.6) * (nx - 0.6) + ny * ny) < 0.22) v = c3;
        case 5: // ev
          if (ny > 0 && nx.abs() < 0.75) v = (nx.abs() < 0.2 && ny > 0.45) ? c3 : c1;
          if (ny <= 0 && ny > -1 && nx.abs() < (ny + 1)) v = c2;
        case 6: // ağaç
          if (ny < 0.5 && nx.abs() < (ny + 1) * 0.6) v = c1;
          if (ny >= 0.5 && nx.abs() < 0.2) v = c2;
        case 7: // balık
          final body = (nx + 0.2) * (nx + 0.2) / 0.5 + ny * ny / 0.3 < 1;
          final tail = nx > 0.5 && ny.abs() < (nx - 0.5) * 1.1;
          if (body) v = c1;
          if (tail) v = c2;
          if (math.sqrt((nx + 0.6) * (nx + 0.6) + (ny + 0.15) * (ny + 0.15)) < 0.13) v = c3;
        case 8: // güneş
          if (d < 0.55) v = c1;
          if (d >= 0.7 && d < 1.0 && (math.cos(a * 8)) > 0.3) v = c2;
        default: // çiçek
          final petal = 0.55 + 0.4 * math.cos(6 * a).abs();
          if (d <= petal) v = d < 0.3 ? c2 : c1;
      }
      out[y * size + x] = v;
    }
  }
  // En az birkaç hücre olsun.
  if (out.where((v) => v > 0).length < 4) {
    final m = size ~/ 2;
    for (final i in [m * size + m, m * size + m - 1, (m - 1) * size + m, (m - 1) * size + m - 1]) {
      out[i] = c1;
    }
  }
  return out;
}

import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'block_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-001-block-puzzle-master',
  title: const ['Blok Bulmaca Ustası', 'Block Puzzle Master', 'Block Puzzle Meister', 'Maestro de Bloques', 'Maître des Blocs'],
  tagline: const [
    'Blokları yerleştir, satırları patlat!',
    'Place blocks, blast lines!',
    'Blöcke legen, Reihen sprengen!',
    '¡Coloca bloques y rompe líneas!',
    'Placez les blocs, explosez les lignes !',
  ],
  seedColor: const Color(0xFF3F51B5),
  icon: Icons.grid_view_rounded,
  rules: BlockRules(),
  buildPlay: (ctx) => BlockView(ctx: ctx),
  tutorial: const [
    TutorialStep(Icons.pan_tool_alt, [
      'Alttaki parçaları tahtaya sürükle ya da parçaya dokunup sonra kareye dokun.',
      'Drag pieces onto the board, or tap a piece and then a cell.',
      'Ziehe Teile aufs Brett oder tippe Teil und Feld an.',
      'Arrastra las piezas al tablero o toca pieza y casilla.',
      'Glissez les pièces ou touchez une pièce puis une case.',
    ]),
    TutorialStep(Icons.horizontal_rule, [
      'Dolu satır ve sütunlar patlar. Art arda patlatmak kombo verir.',
      'Full rows and columns clear. Consecutive clears build combos.',
      'Volle Reihen/Spalten verschwinden. Serien geben Kombos.',
      'Filas y columnas llenas se borran. Seguidas dan combos.',
      'Lignes et colonnes pleines disparaissent. Enchaînez les combos.',
    ]),
    TutorialStep(Icons.flag, [
      'Bölüm hedefini (skor, satır veya elmas) tamamla. Taş ve buz engellere, bombalara dikkat!',
      'Reach the level goal (score, lines or gems). Watch out for stone, ice and bombs!',
      'Erreiche das Ziel (Punkte, Reihen, Edelsteine). Achtung: Stein, Eis, Bomben!',
      'Cumple el objetivo. ¡Cuidado con piedra, hielo y bombas!',
      'Atteignez l\'objectif. Attention pierre, glace et bombes !',
    ]),
    TutorialStep(Icons.rotate_right, [
      'Parçaya uzun basarak döndür. Çekiç, yenile ve ipucu güçlendiricilerini kullan.',
      'Long-press a piece to rotate. Use hammer, refresh and hint boosters.',
      'Lange drücken zum Drehen. Nutze Hammer, Neu und Tipp.',
      'Mantén pulsado para girar. Usa martillo, renovar y pista.',
      'Appui long pour pivoter. Marteau, renouveler et indice.',
    ]),
  ],
);

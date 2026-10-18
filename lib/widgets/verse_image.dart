import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/rate_prompt.dart';

import '../data/app_theme.dart';
import '../data/models.dart';
import '../l10n/lang.dart';

/// Cartão da mensagem renderizado como IMAGEM (gradiente + texto), pronto para
/// compartilhar/salvar. Quando um [captureKey] é passado, o conteúdo é
/// envolvido num RepaintBoundary para exportar a imagem em alta resolução.
class VerseImageCard extends StatelessWidget {
  const VerseImageCard({
    super.key,
    required this.verse,
    required this.gradient,
    this.captureKey,
    this.borderRadius = 24,
    this.fontSize = 22,
  });

  final Verse verse;
  final List<Color> gradient;
  final GlobalKey? captureKey;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: captureKey,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradient(gradient),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -20,
              child: Icon(Icons.local_florist_rounded,
                  size: 150, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 34, 26, 44),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      verse.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: fontSize,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Text('📸 ${Lang.t('Frases para Fotos', 'Photo Captions', 'Frases para Fotos')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Captura o RepaintBoundary de [key] como PNG em alta.
Future<Uint8List?> captureVerseImage(GlobalKey key) async {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final img = await boundary.toImage(pixelRatio: 3.0);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

/// Exporta e compartilha a imagem do cartão.
Future<void> shareVerseImage(GlobalKey key) async {
  final bytes = await captureVerseImage(key);
  if (bytes == null) return;
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/mensagem_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)]);
  await RatePrompt.registerPositiveAction();
}

/// Salva a imagem do cartão na galeria (HD). Retorna true se salvou.
Future<bool> saveVerseImage(GlobalKey key) async {
  final bytes = await captureVerseImage(key);
  if (bytes == null) return false;
  try {
    await Gal.putImageBytes(bytes, album: Lang.t('Frases para Fotos', 'Photo Captions', 'Frases para Fotos'));
    return true;
  } catch (_) {
    return false;
  }
}

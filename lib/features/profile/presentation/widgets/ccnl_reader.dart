/// Lettore dei contratti CCNL PCM: caricamento e parsing dei testi in
/// `assets/ccnl/`, card di ingresso dal profilo, sheet di lettura e indice
/// degli articoli.
///
/// Estratto da `profile_screen.dart` (2026-07-25): il file era cresciuto oltre
/// le 7000 righe e questo modulo è autonomo — dipende solo da AppStrings, dal
/// tema e dagli asset.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../app/theme/color_schemes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_tappable.dart';
import '../../../../shared/widgets/glass_card.dart';

void showCcnlReader(BuildContext context, bool isDark) {
  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _CcnlReaderSheet(isDark: isDark),
    ),
  );
}

Future<List<_CcnlDoc>>? _ccnlDocsFuture;

Future<List<_CcnlDoc>> _loadCcnlDocs() {
  return _ccnlDocsFuture ??= Future.wait([
    _loadCcnlDoc(
      id: '2019-2021',
      label: AppStrings.ccnlNew,
      title: AppStrings.ccnlNewLabel,
      subtitle: AppStrings.ccnlNewSigned,
      assetPath: 'docs/ccnl/ccnl-pcm-2019-2021.md',
    ),
    _loadCcnlDoc(
      id: '2016-2018',
      label: AppStrings.ccnlPrevious,
      title: AppStrings.ccnlPreviousLabel,
      subtitle: AppStrings.ccnlPreviousSigned,
      assetPath: 'docs/ccnl/ccnl-pcm-2016-2018.md',
    ),
  ]);
}

Future<_CcnlDoc> _loadCcnlDoc({
  required String id,
  required String label,
  required String title,
  required String subtitle,
  required String assetPath,
}) async {
  final raw = await rootBundle.loadString(assetPath);
  final content = raw.replaceAll('\r\n', '\n');
  return _parseCcnlDoc(
    id: id,
    label: label,
    title: title,
    subtitle: subtitle,
    assetPath: assetPath,
    content: content,
  );
}

_CcnlDoc _parseCcnlDoc({
  required String id,
  required String label,
  required String title,
  required String subtitle,
  required String assetPath,
  required String content,
}) {
  final articleMatches = RegExp(
    r'^Art\.\s+(\d+)\s*$',
    multiLine: true,
  ).allMatches(content).toList();

  final preamble = articleMatches.isEmpty
      ? content.trim()
      : content.substring(0, articleMatches.first.start).trim();
  final articles = <_CcnlArticle>[];

  for (var i = 0; i < articleMatches.length; i++) {
    final match = articleMatches[i];
    final number = int.tryParse(match.group(1) ?? '') ?? 0;
    final end = i + 1 < articleMatches.length
        ? articleMatches[i + 1].start
        : content.length;
    final section = content.substring(match.start, end).trim();
    final lines = section.split('\n');
    final titleLines = <String>[];

    for (final rawLine in lines.skip(1)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^\d+\.').hasMatch(line)) break;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (line.startsWith('CCNL ')) continue;
      if (line.startsWith('TITOLO ')) break;
      if (line.startsWith('Capo ')) break;
      titleLines.add(line);
      if (titleLines.length == 3) break;
    }

    articles.add(
      _CcnlArticle(
        number: number,
        title: titleLines.isEmpty
            ? AppStrings.articleFallbackTitle(number)
            : titleLines.join(' '),
        text: section,
      ),
    );
  }

  return _CcnlDoc(
    id: id,
    label: label,
    title: title,
    subtitle: subtitle,
    assetPath: assetPath,
    preamble: preamble,
    articles: articles,
  );
}

/// Pulisce la premessa del CCNL per la lettura: rimuove l'indice con i
/// puntini di riempimento, le righe di firma, il blocco indirizzo ARAN e i
/// numeri di pagina; ricompone le righe spezzate in capoversi.
String cleanCcnlPreamble(String raw) {
  final noise = RegExp(
    r'(\.{4,}|firmato|^_+$|^VIA G\.B\.|^TEL \+|^PEC |^C\.F\.|^Indice$)',
    caseSensitive: false,
  );
  final paras = <String>[];
  var cur = '';
  void flush() {
    if (cur.trim().isNotEmpty) paras.add(cur.trim());
    cur = '';
  }

  for (final r in raw.split('\n')) {
    final l = r.trim();
    if (l.isEmpty) {
      flush();
      continue;
    }
    if (RegExp(r'^\d+$').hasMatch(l)) continue; // numero di pagina
    if (l.startsWith('CCNL COMPARTO')) continue;
    if (l.startsWith('>')) continue; // nota di conversione markdown
    if (l.startsWith('#')) continue; // titolo markdown
    if (noise.hasMatch(l)) continue;
    cur = cur.isEmpty ? l : '$cur $l';
  }
  flush();
  return paras.join('\n\n');
}

/// Pulisce il corpo di un articolo CCNL per la lettura: rimuove l'intestazione
/// "Art. N" + titolo (già mostrati), i numeri di pagina e le intestazioni
/// correnti, e ricompone i capoversi (1. / a) ) unendo le righe spezzate.
String formatCcnlBody(String raw) {
  final lines = raw.split('\n');
  final marker = RegExp(r'^(\d+\.|[a-z](-bis|-ter|-quater)?\))\s');
  // Salta intestazione + titolo: parte dal primo capoverso numerato/lettera.
  var start = 0;
  for (var i = 0; i < lines.length; i++) {
    if (marker.hasMatch('${lines[i].trim()} ')) {
      start = i;
      break;
    }
  }
  final paras = <String>[];
  var cur = '';
  void flush() {
    if (cur.trim().isNotEmpty) paras.add(cur.trim());
    cur = '';
  }

  for (final r in lines.skip(start)) {
    final l = r.trim();
    if (l.isEmpty) continue;
    if (RegExp(r'^\d+$').hasMatch(l)) continue; // numero di pagina
    if (l.startsWith('CCNL ') ||
        l.startsWith('TITOLO ') ||
        l.startsWith('Capo ')) {
      continue;
    }
    if (marker.hasMatch('$l ')) {
      flush();
      cur = l;
    } else {
      cur = cur.isEmpty ? l : '$cur $l';
    }
  }
  flush();
  final body = paras.join('\n\n');
  return body.isEmpty ? raw.trim() : body;
}

// ── Reusable sheet wrapper ───────────────────────────────────────────────

class _CcnlDoc {
  final String id;
  final String label;
  final String title;
  final String subtitle;
  final String assetPath;
  final String preamble;
  final List<_CcnlArticle> articles;

  const _CcnlDoc({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.preamble,
    required this.articles,
  });
}

class _CcnlArticle {
  final int number;
  final String title;
  final String text;
  final GlobalKey key;

  _CcnlArticle({required this.number, required this.title, required this.text})
    : key = GlobalKey(debugLabel: 'ccnl_art_$number');
}

class CcnlProfileCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpen;

  const CcnlProfileCard({
    super.key,
    required this.isDark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue600.withValues(
                    alpha: isDark ? 0.18 : 0.11,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blue600.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 21,
                  color: AppColors.blue600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.ccnlPcmTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.ccnlVersionsHint,
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.openCcnl,
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 19),
                color: AppColors.blue600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CcnlSmallTag(
                label: AppStrings.ccnlNew,
                value: '2019-2021',
                isDark: isDark,
              ),
              _CcnlSmallTag(
                label: AppStrings.ccnlPrevious,
                value: '2016-2018',
                isDark: isDark,
              ),
              _CcnlSmallTag(
                label: AppStrings.indexLabel,
                value: AppStrings.articlesValue,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.025),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 17,
                    color: AppColors.blue600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.readContract,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CcnlSmallTag extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _CcnlSmallTag({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.85),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.58)
                : AppColors.neutral600,
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.neutral900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CcnlReaderSheet extends StatefulWidget {
  final bool isDark;

  const _CcnlReaderSheet({required this.isDark});

  @override
  State<_CcnlReaderSheet> createState() => _CcnlReaderSheetState();
}

class _CcnlReaderSheetState extends State<_CcnlReaderSheet> {
  final _scrollController = ScrollController();
  int _selected = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectDoc(int index) {
    if (_selected == index) return;
    setState(() => _selected = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _openIndex(_CcnlDoc doc) async {
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.74,
        child: _CcnlIndexSheet(
          doc: doc,
          isDark: widget.isDark,
          onSelect: (article) {
            Navigator.pop(context);
            Future<void>.delayed(const Duration(milliseconds: 80), () {
              if (!mounted) return;
              final articleContext = article.key.currentContext;
              if (articleContext == null) return;
              if (!articleContext.mounted) return;
              Scrollable.ensureVisible(
                articleContext,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                alignment: 0.04,
              );
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? const Color(0xFF10102A).withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.98);
    final textMain = widget.isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = widget.isDark
        ? Colors.white.withValues(alpha: 0.52)
        : AppColors.neutral600;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: FutureBuilder<List<_CcnlDoc>>(
            future: _loadCcnlDocs(),
            builder: (context, snap) {
              final docs = snap.data;
              final hasDocs = docs != null && docs.isNotEmpty;
              final selectedIndex = hasDocs
                  ? _selected.clamp(0, docs.length - 1)
                  : 0;
              final doc = hasDocs ? docs[selectedIndex] : null;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.ccnlPcmTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    doc?.subtitle ??
                                        AppStrings.loadingContracts,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: AppStrings.articlesIndex,
                              onPressed: doc == null
                                  ? null
                                  : () => _openIndex(doc),
                              icon: const Icon(
                                Icons.format_list_bulleted_rounded,
                              ),
                              color: AppColors.blue600,
                            ),
                            IconButton(
                              tooltip: AppStrings.close,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: textSub,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasDocs)
                          _CcnlDocSwitch(
                            docs: docs,
                            selected: _selected,
                            isDark: widget.isDark,
                            onSelect: _selectDoc,
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: snap.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : snap.hasError
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                AppStrings.ccnlLoadError,
                                style: TextStyle(color: textSub),
                              ),
                            ),
                          )
                        : doc == null
                        ? Center(
                            child: Text(
                              AppStrings.noContractAvailable,
                              style: TextStyle(color: textSub),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CcnlDocIntro(doc: doc, isDark: widget.isDark),
                                if (doc.preamble.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _CcnlPreambleBlock(
                                    text: doc.preamble,
                                    isDark: widget.isDark,
                                  ),
                                ],
                                const SizedBox(height: 14),
                                ...doc.articles.map(
                                  (article) => _CcnlArticleBlock(
                                    article: article,
                                    isDark: widget.isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CcnlDocSwitch extends StatelessWidget {
  final List<_CcnlDoc> docs;
  final int selected;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _CcnlDocSwitch({
    required this.docs,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(docs.length, (i) {
        final doc = docs[i];
        final active = i == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == docs.length - 1 ? 0 : 8),
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.blue600
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.035)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? AppColors.blue600
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white.withValues(alpha: 0.78)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.52)
                                  : AppColors.neutral600),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      doc.id,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: active
                            ? Colors.white
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.88)
                                  : AppColors.neutral900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CcnlDocIntro extends StatelessWidget {
  final _CcnlDoc doc;
  final bool isDark;

  const _CcnlDocIntro({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 20,
            color: AppColors.blue600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.articlesCount(doc.articles.length),
                  style: TextStyle(fontSize: 11, color: textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CcnlPreambleBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const _CcnlPreambleBlock({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.neutral800;

    final cleaned = cleanCcnlPreamble(text);
    if (cleaned.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SelectableText(
        cleaned,
        style: TextStyle(fontSize: 13, height: 1.55, color: textMain),
      ),
    );
  }
}

class _CcnlArticleBlock extends StatelessWidget {
  final _CcnlArticle article;
  final bool isDark;

  const _CcnlArticleBlock({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : AppColors.neutral900;
    final textBody = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : AppColors.neutral800;

    return Container(
      key: article.key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue600.withValues(
                    alpha: isDark ? 0.18 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppStrings.articleHeading(article.number),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.blue600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Un blocco per capoverso: numero di comma in evidenza, lettere
          // a)/b) indentate — molto più scorrevole del muro di testo.
          ...formatCcnlBody(article.text).split('\n\n').map((p) {
            final comma = RegExp(r'^(\d+)\.\s').firstMatch(p);
            final lettera = RegExp(
              r'^([a-z](?:-bis|-ter|-quater)?\))\s',
            ).firstMatch(p);
            final bodyStyle = TextStyle(
              fontSize: 13,
              height: 1.55,
              color: textBody,
            );
            if (comma != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${comma.group(1)}.  ',
                        style: bodyStyle.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue600,
                        ),
                      ),
                      TextSpan(text: p.substring(comma.end)),
                    ],
                    style: bodyStyle,
                  ),
                ),
              );
            }
            if (lettera != null) {
              return Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 8),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${lettera.group(1)}  ',
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: p.substring(lettera.end)),
                    ],
                    style: bodyStyle,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectableText(p, style: bodyStyle),
            );
          }),
        ],
      ),
    );
  }
}

class _CcnlIndexSheet extends StatefulWidget {
  final _CcnlDoc doc;
  final bool isDark;
  final ValueChanged<_CcnlArticle> onSelect;

  const _CcnlIndexSheet({
    required this.doc,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_CcnlIndexSheet> createState() => _CcnlIndexSheetState();
}

class _CcnlIndexSheetState extends State<_CcnlIndexSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final doc = widget.doc;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? doc.articles
        : doc.articles
              .where(
                (a) =>
                    a.title.toLowerCase().contains(q) ||
                    '${a.number}' == q ||
                    'art. ${a.number}'.contains(q),
              )
              .toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10102A).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.articlesIndex,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doc.title,
                                style: TextStyle(fontSize: 12, color: textSub),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.close,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: textSub,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Ricerca articolo per numero o titolo
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: AppStrings.ccnlSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(fontSize: 13, color: textMain),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 52,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (context, i) {
                    final article = filtered[i];
                    // Riga custom (niente ListTile: il Material trasparente
                    // dello sheet renderebbe invisibili tile e splash).
                    return AppTappable(
                      onTap: () => widget.onSelect(article),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.blue600.withValues(
                                  alpha: isDark ? 0.18 : 0.09,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${article.number}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.blue600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textMain,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: textSub,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

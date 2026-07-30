import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_backdrop.dart';

enum LegalDocument { privacy, terms }

enum LegalLanguage { en, hi }

/// In-app viewer for Privacy Policy / Terms (EN + HI) so users can read
/// offline and Play reviewers can verify disclosure without leaving the app.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    super.key,
    required this.document,
    this.initialLanguage = LegalLanguage.en,
  });

  final LegalDocument document;
  final LegalLanguage initialLanguage;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late LegalLanguage _language;
  late Future<String> _loadFuture;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _loadFuture = _load();
  }

  String get _assetPath {
    switch (widget.document) {
      case LegalDocument.privacy:
        return _language == LegalLanguage.hi
            ? AppConstants.privacyPolicyAssetHi
            : AppConstants.privacyPolicyAssetEn;
      case LegalDocument.terms:
        return _language == LegalLanguage.hi
            ? AppConstants.termsOfServiceAssetHi
            : AppConstants.termsOfServiceAssetEn;
    }
  }

  String get _title {
    final bool hi = _language == LegalLanguage.hi;
    switch (widget.document) {
      case LegalDocument.privacy:
        return hi ? 'गोपनीयता नीति' : 'Privacy policy';
      case LegalDocument.terms:
        return hi ? 'नियम और शर्तें' : 'Terms & Conditions';
    }
  }

  Future<String> _load() => rootBundle.loadString(_assetPath);

  void _setLanguage(LegalLanguage language) {
    if (language == _language) return;
    setState(() {
      _language = language;
      _loadFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<LegalLanguage>(
              segments: const <ButtonSegment<LegalLanguage>>[
                ButtonSegment<LegalLanguage>(
                  value: LegalLanguage.en,
                  label: Text('EN'),
                ),
                ButtonSegment<LegalLanguage>(
                  value: LegalLanguage.hi,
                  label: Text('हिं'),
                ),
              ],
              selected: <LegalLanguage>{_language},
              onSelectionChanged: (Set<LegalLanguage> next) {
                _setLanguage(next.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: AppBackdrop(
        child: FutureBuilder<String>(
          future: _loadFuture,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load document.\n${snapshot.error ?? ''}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Markdown(
              data: snapshot.data!,
              selectable: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                a: TextStyle(
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                ),
                tableBody: Theme.of(context).textTheme.bodySmall,
                tableHead: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}

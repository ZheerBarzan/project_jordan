import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/theme/app_theme.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef EmbeddedArticleBuilder =
    Widget Function(
      BuildContext context,
      Article article,
      VoidCallback onLoadStart,
      VoidCallback onLoadComplete,
      ValueChanged<Object> onError,
      Key contentKey,
    );

class ArticleReaderPage extends StatefulWidget {
  const ArticleReaderPage({
    super.key,
    required this.article,
    this.embeddedArticleBuilder,
    this.initialReaderError,
  });

  final Article article;
  final EmbeddedArticleBuilder? embeddedArticleBuilder;
  final Object? initialReaderError;

  @override
  State<ArticleReaderPage> createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  Object? _readerError;
  bool _isLoading = true;
  int _reloadCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialReaderError != null) {
      _readerError = widget.initialReaderError;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.newsprint,
      appBar: AppBar(
        backgroundColor: AppTheme.newsprint,
        foregroundColor: AppTheme.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.article.source,
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        actions: <Widget>[
          Tooltip(
            message: 'Open in browser',
            child: IconButton(
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool usesFallbackSurface = _readerError != null || kIsWeb;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: usesFallbackSurface
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _ReaderHeader(article: widget.article),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 360,
                            child: _buildReaderSurface(context),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                            sliver: SliverToBoxAdapter(
                              child: _ReaderHeader(article: widget.article),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                            sliver: SliverFillRemaining(
                              hasScrollBody: true,
                              child: _buildReaderSurface(context),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReaderSurface(BuildContext context) {
    if (_readerError != null) {
      return _InlineReaderMessage(
        title: 'Could not load the article',
        message: _readerError.toString(),
        actionLabel: 'Retry',
        onAction: _retry,
        secondaryLabel: 'Open in Browser',
        onSecondaryAction: _openExternally,
      );
    }

    if (kIsWeb) {
      return _InlineReaderMessage(
        title: 'Embedded reading is unavailable on web',
        message:
            'This build cannot render the full article inline. You can still open the original story in a browser.',
        actionLabel: 'Open in Browser',
        onAction: _openExternally,
      );
    }

    final EmbeddedArticleBuilder builder =
        widget.embeddedArticleBuilder ?? _defaultEmbeddedArticleBuilder;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.paperLine),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: builder(
                context,
                widget.article,
                _handleLoadStart,
                _handleLoadComplete,
                _handleLoadError,
                ValueKey<int>(_reloadCount),
              ),
            ),
            if (_isLoading)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleLoadStart() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _readerError = null;
    });
  }

  void _handleLoadComplete() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _handleLoadError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _readerError = error;
      _isLoading = false;
    });
  }

  void _retry() {
    setState(() {
      _reloadCount += 1;
      _readerError = null;
      _isLoading = true;
    });
  }

  Future<void> _openExternally() async {
    final Uri? articleUri = Uri.tryParse(widget.article.url);
    if (articleUri == null) {
      return;
    }

    if (!await launchUrl(articleUri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the article link.')),
      );
    }
  }
}

Widget _defaultEmbeddedArticleBuilder(
  BuildContext context,
  Article article,
  VoidCallback onLoadStart,
  VoidCallback onLoadComplete,
  ValueChanged<Object> onError,
  Key contentKey,
) {
  return _EmbeddedArticleWebView(
    key: contentKey,
    article: article,
    onLoadStart: onLoadStart,
    onLoadComplete: onLoadComplete,
    onError: onError,
  );
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _ReaderHeroImage(imageUrl: article.urlToImage),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    article.source.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.accentRed,
                    ),
                  ),
                ),
                Text(
                  DateFormat(
                    'EEEE, MMM d • h:mm a',
                  ).format(article.publishedAt.toLocal()),
                  style: theme.textTheme.bodySmall,
                ),
                if ((article.author ?? '').trim().isNotEmpty)
                  Text(
                    'By ${article.author!.trim()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.nbaBlue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              article.title,
              style: GoogleFonts.newsreader(
                fontSize: 34,
                height: 1.12,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            if (article.description.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              SelectableText(
                article.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.84),
                  height: 1.55,
                ),
              ),
            ],
            if ((article.content ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              SelectableText(
                article.content!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReaderHeroImage extends StatelessWidget {
  const _ReaderHeroImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String image = imageUrl ?? '';
    if (image.isEmpty) {
      return const _ReaderImageFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: image,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, _, _) => const _ReaderImageFallback(),
      ),
    );
  }
}

class _ReaderImageFallback extends StatelessWidget {
  const _ReaderImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppTheme.courtBlue, AppTheme.nbaBlue],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _InlineReaderMessage extends StatelessWidget {
  const _InlineReaderMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('article-reader-inline-message'),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.chrome_reader_mode_rounded, color: AppTheme.accentRed),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
                if (secondaryLabel != null && onSecondaryAction != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedArticleWebView extends StatefulWidget {
  const _EmbeddedArticleWebView({
    super.key,
    required this.article,
    required this.onLoadStart,
    required this.onLoadComplete,
    required this.onError,
  });

  final Article article;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadComplete;
  final ValueChanged<Object> onError;

  @override
  State<_EmbeddedArticleWebView> createState() =>
      _EmbeddedArticleWebViewState();
}

class _EmbeddedArticleWebViewState extends State<_EmbeddedArticleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    widget.onLoadStart();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onLoadStart(),
          onPageFinished: (_) => widget.onLoadComplete(),
          onWebResourceError: (WebResourceError error) {
            widget.onError(Exception(error.description));
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

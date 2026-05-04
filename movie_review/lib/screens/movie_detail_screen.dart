// ============================================================
// screens/movie_detail_screen.dart — Movie detail + review form
// ============================================================
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../widgets/star_rating.dart';
import '../services/storage_service.dart';

/// Returns a web-safe network image.
/// On Chrome, Image.network avoids the CachedNetworkImage canvas crash.
/// On mobile it uses CachedNetworkImage for caching benefits.
Widget _webSafeImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (kIsWeb) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, prog) =>
          prog == null ? child : Container(color: const Color(0xFF1A1A2E)),
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (_, __) => Container(color: const Color(0xFF1A1A2E)),
    errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
  );
}

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with TickerProviderStateMixin {
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSaved = false;
  bool _saving = false;
  bool _overviewExpanded = false;
  bool _isFavorite = false;

  late AnimationController _reviewPanelController;
  late Animation<Offset> _reviewPanelSlide;
  late Animation<double> _reviewPanelFade;

  @override
  void initState() {
    super.initState();
    _reviewPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _reviewPanelSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _reviewPanelController,
        curve: Curves.easeOutCubic,
      ),
    );
    _reviewPanelFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _reviewPanelController, curve: Curves.easeOut),
    );
    _loadSavedReview();
    _checkFavorite();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _reviewPanelController.forward();
    });
  }

  Future<void> _checkFavorite() async {
    final isFav = await StorageService.isFavorite(widget.movie.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  @override
  void dispose() {
    _reviewPanelController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedReview() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('review_${widget.movie.id}');
    if (data != null && mounted) {
      try {
        final reviewObj = jsonDecode(data);
        setState(() {
          _userRating = reviewObj['rating'] ?? 0;
          _commentController.text = reviewObj['comment'] ?? '';
          _isSaved = true;
        });
      } catch (_) {}
    } else {
      // Legacy fallback
      final savedRating = prefs.getDouble('rating_${widget.movie.id}');
      final savedComment = prefs.getString('comment_${widget.movie.id}');
      if (savedRating != null && mounted) {
        setState(() {
          _userRating = savedRating;
          _commentController.text = savedComment ?? '';
          _isSaved = true;
        });
      }
    }
  }

  Future<void> _saveReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text('Please give a star rating first'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    final reviewData = {
      'rating': _userRating,
      'comment': _commentController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'movieTitle': widget.movie.title,
      'posterPath': widget.movie.posterPath,
    };
    await prefs.setString('review_${widget.movie.id}', jsonEncode(reviewData));
    if (mounted) {
      setState(() {
        _isSaved = true;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Review saved! 🎬'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('review_${widget.movie.id}');
    // Remove legacy
    await prefs.remove('rating_${widget.movie.id}');
    await prefs.remove('comment_${widget.movie.id}');
    if (mounted) {
      setState(() {
        _userRating = 0;
        _commentController.clear();
        _isSaved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050714),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMovieHeader(),
                  const SizedBox(height: 20),
                  _buildOverview(),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _reviewPanelSlide,
                    child: FadeTransition(
                      opacity: _reviewPanelFade,
                      child: _buildReviewSection(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: const Color(0xFF050714),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: IconButton(
            key: ValueKey<bool>(_isFavorite),
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.pinkAccent : Colors.white,
              size: 28,
            ),
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () async {
              final isFav = await StorageService.toggleFavorite(widget.movie);
              if (mounted) setState(() => _isFavorite = isFav);
            },
          ),
        ),
        if (_isSaved)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              tooltip: 'Delete review',
              onPressed: _deleteReview,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop
            widget.movie.backdropUrl.isNotEmpty
                ? _webSafeImage(widget.movie.backdropUrl, fit: BoxFit.cover)
                : Container(color: const Color(0xFF1A1A2E)),
            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x88000000),
                    Color(0xFF050714),
                  ],
                  stops: [0.4, 0.75, 1.0],
                ),
              ),
            ),
            // Poster + title at bottom
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Poster with hero
                  Hero(
                    tag: 'poster_${widget.movie.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.movie.posterUrl.isNotEmpty
                          ? _webSafeImage(
                              widget.movie.posterUrl,
                              width: 90,
                              height: 135,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 90,
                              height: 135,
                              color: const Color(0xFF1A1A2E),
                              child: const Icon(Icons.movie, color: Colors.white24),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              widget.movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (widget.movie.year.isNotEmpty) ...[
                              const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white54, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                widget.movie.year,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.movie.genreText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _LanguageBadge(language: widget.movie.originalLanguage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieHeader() {
    return Row(
      children: [
        if (_isSaved) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_rounded, color: Colors.black, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Reviewed • $_userRating ★',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverview() {
    if (widget.movie.overview.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(
            widget.movie.overview,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.movie.overview,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
          crossFadeState: _overviewExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _overviewExpanded = !_overviewExpanded),
          child: Text(
            _overviewExpanded ? 'Show less' : 'Read more',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded,
                  color: Color(0xFFFFD700), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Your Review',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_isSaved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '✓ Saved',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Star rating
          const Text(
            'Your Rating',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          StarRating(
            rating: _userRating,
            onRatingChanged: (r) => setState(() => _userRating = r),
            size: 40,
          ),
          const SizedBox(height: 8),
          if (_userRating > 0)
            Text(
              _ratingLabel(_userRating),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 20),
          // Comment field
          const Text(
            'Your Comment',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Share your thoughts about this movie...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSaved
                                  ? Icons.update_rounded
                                  : Icons.save_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSaved ? 'Update Review' : 'Save Review',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating == 5) return '🌟 Masterpiece!';
    if (rating == 4) return '😊 Really Good';
    if (rating == 3) return '👍 Decent Watch';
    if (rating == 2) return '😐 Could Be Better';
    return '👎 Not for Me';
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;

  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    final label = language == 'ml'
        ? '🌴 Malayalam'
        : language == 'en'
            ? '🎬 English'
            : language.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

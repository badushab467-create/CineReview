// ============================================================
// screens/home_screen.dart — Main tabbed movie browser
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'reviews_screen.dart';
import '../widgets/hover_effect.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Movie> _englishMovies = [];
  List<Movie> _malayalamMovies = [];
  List<Movie> _tamilMovies = [];
  List<Movie> _hindiMovies = [];

  int _pageEnglish = 1;
  int _pageMalayalam = 1;
  int _pageTamil = 1;
  int _pageHindi = 1;

  bool _loadingEnglish = true;
  bool _loadingMalayalam = true;
  bool _loadingTamil = true;
  bool _loadingHindi = true;

  String? _errorEnglish;
  String? _errorMalayalam;
  String? _errorTamil;
  String? _errorHindi;

  final TextEditingController _searchController = TextEditingController();
  List<Movie> _searchResults = [];
  bool _isSearching = false;
  bool _searchLoading = false;
  bool _showSearchBar = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMovies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    _loadEnglish();
    _loadMalayalam();
    _loadTamil();
    _loadHindi();
  }

  Future<void> _loadEnglish({bool loadMore = false}) async {
    if (loadMore) { _pageEnglish++; } else { _pageEnglish = 1; }
    try {
      setState(() {
        _loadingEnglish = true;
        if (!loadMore) _errorEnglish = null;
      });
      final movies = await TmdbService.fetchEnglishMovies(page: _pageEnglish);
      if (mounted) {
        setState(() {
          if (loadMore) { _englishMovies.addAll(movies); } else { _englishMovies = movies; }
          _loadingEnglish = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          if (!loadMore) _errorEnglish = e.toString(); 
          _loadingEnglish = false; 
        });
      }
    }
  }

  Future<void> _loadMalayalam({bool loadMore = false}) async {
    if (loadMore) { _pageMalayalam++; } else { _pageMalayalam = 1; }
    try {
      setState(() {
        _loadingMalayalam = true;
        if (!loadMore) _errorMalayalam = null;
      });
      final movies = await TmdbService.fetchMalayalamMovies(page: _pageMalayalam);
      if (mounted) {
        setState(() {
          if (loadMore) { _malayalamMovies.addAll(movies); } else { _malayalamMovies = movies; }
          _loadingMalayalam = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          if (!loadMore) _errorMalayalam = e.toString(); 
          _loadingMalayalam = false; 
        });
      }
    }
  }

  Future<void> _loadTamil({bool loadMore = false}) async {
    if (loadMore) { _pageTamil++; } else { _pageTamil = 1; }
    try {
      setState(() {
        _loadingTamil = true;
        if (!loadMore) _errorTamil = null;
      });
      final movies = await TmdbService.fetchTamilMovies(page: _pageTamil);
      if (mounted) {
        setState(() {
          if (loadMore) { _tamilMovies.addAll(movies); } else { _tamilMovies = movies; }
          _loadingTamil = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          if (!loadMore) _errorTamil = e.toString(); 
          _loadingTamil = false; 
        });
      }
    }
  }

  Future<void> _loadHindi({bool loadMore = false}) async {
    if (loadMore) { _pageHindi++; } else { _pageHindi = 1; }
    try {
      setState(() {
        _loadingHindi = true;
        if (!loadMore) _errorHindi = null;
      });
      final movies = await TmdbService.fetchHindiMovies(page: _pageHindi);
      if (mounted) {
        setState(() {
          if (loadMore) { _hindiMovies.addAll(movies); } else { _hindiMovies = movies; }
          _loadingHindi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          if (!loadMore) _errorHindi = e.toString(); 
          _loadingHindi = false; 
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchLoading = true;
    });
    try {
      final results = await TmdbService.searchMovies(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchLoading = false);
      }
    }
  }

  void _openMovie(Movie movie) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MovieDetailScreen(movie: movie),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(themeProvider),
          const FavoritesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: themeProvider.backgroundColor,
        selectedItemColor: themeProvider.themeColor,
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent(ThemeProvider themeProvider) {
    return NestedScrollView(
        headerSliverBuilder: (_, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: _showSearchBar ? 186 : 130,
            floating: true,
            pinned: true,
            snap: false,
            backgroundColor: const Color(0xFF050714),
            elevation: 0,
            actions: [
              HoverEffect(
                child: IconButton(
                  icon: Icon(_showSearchBar ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) {
                        _searchController.clear();
                        _performSearch('');
                      }
                    });
                  },
                  tooltip: 'Search Movies',
                ),
              ),
              HoverEffect(
                child: IconButton(
                  icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()));
                  },
                  tooltip: 'My Reviews',
                ),
              ),
              HoverEffect(
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700)),
                  onPressed: _loadMovies,
                  tooltip: 'Refresh Movies',
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  const Icon(
                    Icons.movie_filter_rounded,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFF8DC)],
                    ).createShader(bounds),
                    child: const Text(
                      'CineReview',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D0D1F),
                      Color(0xFF050714),
                    ],
                  ),
                ),
              ),
            ),
            bottom: _showSearchBar
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: _buildSearchBar(),
                  )
                : null,
          ),
        ],
        body: _isSearching
            ? _buildSearchResults()
            : Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMovieGrid(_malayalamMovies, _loadingMalayalam, _errorMalayalam, _loadMalayalam, () => _loadMalayalam(loadMore: true)),
                        _buildMovieGrid(_tamilMovies, _loadingTamil, _errorTamil, _loadTamil, () => _loadTamil(loadMore: true)),
                        _buildMovieGrid(_englishMovies, _loadingEnglish, _errorEnglish, _loadEnglish, () => _loadEnglish(loadMore: true)),
                        _buildMovieGrid(_hindiMovies, _loadingHindi, _errorHindi, _loadHindi, () => _loadHindi(loadMore: true)),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search movies...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF050714),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFFFFD700),
        indicatorWeight: 3,
        labelColor: const Color(0xFFFFD700),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(text: 'Malayalam'),
          Tab(text: 'Tamil'),
          Tab(text: 'English'),
          Tab(text: 'Hindi'),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(
    List<Movie> movies,
    bool loading,
    String? error,
    VoidCallback onRetry,
    VoidCallback onLoadMore,
  ) {
    if (loading && movies.isEmpty) return _buildShimmerGrid();
    if (error != null) return _buildError(error, onRetry);
    if (movies.isEmpty) {
      return const Center(
        child: Text(
          'No movies found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1A1A2E),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!loading && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 300) {
            onLoadMore();
          }
          return false;
        },
        child: AnimationLimiter(
          child: GridView.builder(
            primary: false,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.60,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
            ),
            itemCount: movies.length + (loading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == movies.length) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                );
              }
              return AnimationConfiguration.staggeredGrid(
                position: i,
                columnCount: 5,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: MovieCard(
                      movie: movies[i],
                      onTap: () => _openMovie(movies[i]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) return _buildShimmerGrid();
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 12),
            const Text(
              'No results found',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.60,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (ctx, i) {
          return AnimationConfiguration.staggeredGrid(
            position: i,
            columnCount: 2,
            duration: const Duration(milliseconds: 400),
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: MovieCard(
                  movie: _searchResults[i],
                  onTap: () => _openMovie(_searchResults[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.60,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemCount: 15,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A2E),
        highlightColor: const Color(0xFF2D2D4E),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    final isApiKeyError = error.contains('401') || error.contains('Invalid API key');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApiKeyError ? Icons.key_off_rounded : Icons.wifi_off_rounded,
              color: Colors.white24,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isApiKeyError
                  ? '⚠️ TMDB API Key Missing'
                  : 'Connection Error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isApiKeyError
                  ? 'Please add your TMDB API key in lib/services/tmdb_service.dart'
                  : 'Failed to load movies. Please check your connection.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            if (isApiKeyError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '1. Go to themoviedb.org\n2. Sign up → Settings → API\n3. Copy API Key (v3 auth)\n4. Paste in tmdb_service.dart',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

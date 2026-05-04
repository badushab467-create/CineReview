import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class TmdbService {
  // ──────────────────────────────────────────────────────────────
  // 🔑 TMDB API KEY
  static const String _apiKey = '';
  // ──────────────────────────────────────────────────────────────

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static String _buildUrl(String path, Map<String, String> params) {
    final queryParams = {'api_key': _apiKey, ...params};
    final query = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_baseUrl$path?$query';
  }

  static Future<List<Movie>> _fetchMultiPage(String path, Map<String, String> params, String cachePrefix, String langCode, int pageIndex) async {
    List<Movie> allResults = [];
    final int startPage = (pageIndex - 1) * 10 + 1;
    
    // We fetch 10 pages to get 200 movies (20 results per page)
    for (int i = 0; i < 10; i++) {
      final int currentPage = startPage + i;
      final url = _buildUrl(path, {...params, 'page': '$currentPage'});
      final results = await _fetchWithCache(Uri.parse(url), '${cachePrefix}_$currentPage', langCode: langCode);
      
      if (_apiKey.isEmpty) return results; // Mock logic already returns 200
      allResults.addAll(results);
    }
    
    final uniqueIds = <int>{};
    return allResults.where((m) => uniqueIds.add(m.id)).toList();
  }

  static Future<List<Movie>> fetchEnglishMovies({int page = 1}) async {
    return _fetchMultiPage('/discover/movie', {
      'language': 'en-US',
      'sort_by': 'primary_release_date.desc',
      'with_original_language': 'en',
      'vote_count.gte': '10',
      'include_adult': 'false',
    }, 'cache_english', 'en', page);
  }

  static Future<List<Movie>> fetchMalayalamMovies({int page = 1}) async {
    return _fetchMultiPage('/discover/movie', {
      'language': 'ml-IN',
      'sort_by': 'primary_release_date.desc',
      'with_original_language': 'ml',
      'vote_count.gte': '5',
      'include_adult': 'false',
    }, 'cache_malayalam', 'ml', page);
  }

  static Future<List<Movie>> fetchTamilMovies({int page = 1}) async {
    return _fetchMultiPage('/discover/movie', {
      'language': 'ta-IN',
      'sort_by': 'primary_release_date.desc',
      'with_original_language': 'ta',
      'vote_count.gte': '5',
      'include_adult': 'false',
    }, 'cache_tamil', 'ta', page);
  }

  static Future<List<Movie>> fetchHindiMovies({int page = 1}) async {
    return _fetchMultiPage('/discover/movie', {
      'language': 'hi-IN',
      'sort_by': 'primary_release_date.desc',
      'with_original_language': 'hi',
      'vote_count.gte': '5',
      'include_adult': 'false',
    }, 'cache_hindi', 'hi', page);
  }

  static Future<List<Movie>> searchMovies(String query) async {
    final url = _buildUrl('/search/movie', {
      'language': 'en-US',
      'query': Uri.encodeComponent(query),
      'include_adult': 'false',
    });
    try {
      if (_apiKey.isEmpty) {
        final lowerQuery = query.toLowerCase();
        return _getMockMovies('all').where((m) => m.title.toLowerCase().contains(lowerQuery)).toList();
      }
      return await _fetchWithCache(Uri.parse(url), 'cache_search_$query', langCode: 'all');
    } catch (e) {
      // If offline and search fails, try searching the local cache
      return _localSearchFallback(query);
    }
  }

  static Future<List<Movie>> _fetchWithCache(Uri uri, String cacheKey, {String langCode = 'en'}) async {
    // If API key is reset/empty, immediately return mock data to avoid using stale cache
    if (_apiKey.isEmpty) {
      return _getMockMovies(langCode);
    }

    final prefs = await SharedPreferences.getInstance();

    try {
      // Try to fetch from the network (without custom headers to avoid Web CORS preflight)
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        // Save to cache for offline use
        await prefs.setString(cacheKey, response.body);
        
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results.map((j) => Movie.fromJson(j as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key (401).');
      } else {
        throw Exception('TMDB API error ${response.statusCode}');
      }
    } catch (e) {
      // If network fails (no internet, timeout, etc.), try to load from cache
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final data = json.decode(cachedData) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results.map((j) => Movie.fromJson(j as Map<String, dynamic>)).toList();
      }
      // If no cache exists, fallback to mock data to keep the app running smoothly
      return _getMockMovies(langCode);
    }
  }

  static Future<List<Movie>> _localSearchFallback(String query) async {
    // Collect all possible cached movies across the main pages to search locally
    final allMovies = <Movie>[];
    
    try {
      allMovies.addAll(await fetchEnglishMovies());
      allMovies.addAll(await fetchMalayalamMovies());
      allMovies.addAll(await fetchTamilMovies());
      allMovies.addAll(await fetchHindiMovies());
    } catch (_) {
      // Ignore if cache is completely empty
    }

    final lowerQuery = query.toLowerCase();
    // Return unique local matches
    final matches = allMovies.where((m) => m.title.toLowerCase().contains(lowerQuery)).toList();
    final uniqueIds = <int>{};
    return matches.where((m) => uniqueIds.add(m.id)).toList();
  }

  static List<Movie> _getMockMovies(String langCode) {
    List<Movie> english = [
      Movie(id: 1, title: 'Inception', overview: 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.', posterPath: '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', backdropPath: '/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg', voteAverage: 8.8, releaseDate: '2010-07-15', genreIds: [28, 878, 12], originalLanguage: 'en'),
      Movie(id: 2, title: 'Interstellar', overview: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.', posterPath: '/gEU2QlsUUHXjNpeVDcbewA5hB6K.jpg', backdropPath: '/pbrkL804c8yAv3zBZR4QPEafpAR.jpg', voteAverage: 8.6, releaseDate: '2014-11-05', genreIds: [12, 18, 878], originalLanguage: 'en'),
      Movie(id: 3, title: 'The Dark Knight', overview: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.', posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg', backdropPath: '/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg', voteAverage: 9.0, releaseDate: '2008-07-16', genreIds: [18, 28, 80, 53], originalLanguage: 'en'),
      Movie(id: 4, title: 'Dune: Part Two', overview: 'Paul Atreides unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.', posterPath: '/1pdfLvkbY9ohJlCjQH2TFjj71Fp.jpg', backdropPath: '/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg', voteAverage: 8.3, releaseDate: '2024-02-27', genreIds: [878, 12], originalLanguage: 'en'),
      Movie(id: 5, title: 'Oppenheimer', overview: 'The story of J. Robert Oppenheimer\'s role in the development of the atomic bomb during World War II.', posterPath: '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', backdropPath: '/fm6KqXn30O7IGeWSnVAXzeA85.jpg', voteAverage: 8.1, releaseDate: '2023-07-19', genreIds: [18, 36], originalLanguage: 'en'),
      Movie(id: 6, title: 'Spider-Man: Across the Spider-Verse', overview: 'Miles Morales catapults across the Multiverse, where he encounters a team of Spider-People charged with protecting its very existence.', posterPath: '/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg', backdropPath: '/4HodYYKEIsGOdinkGi2Ucz6X9i0.jpg', voteAverage: 8.4, releaseDate: '2023-05-31', genreIds: [16, 28, 12], originalLanguage: 'en'),
      Movie(id: 7, title: 'John Wick: Chapter 4', overview: 'With the price on his head ever increasing, John Wick uncovers a path to defeating The High Table.', posterPath: '/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg', backdropPath: '/7I6VUdPj6tQECNHdviJkUHD2u89.jpg', voteAverage: 7.8, releaseDate: '2023-03-22', genreIds: [28, 53, 80], originalLanguage: 'en'),
      Movie(id: 8, title: 'The Batman', overview: 'In his second year of fighting crime, Batman uncovers corruption in Gotham City that connects to his own family while facing a serial killer known as the Riddler.', posterPath: '/74xTEgt7R36Fpooo50r9T25onhq.jpg', backdropPath: '/b0PlSFdSmKm71eHk10B0zX2H0Z0.jpg', voteAverage: 7.7, releaseDate: '2022-03-01', genreIds: [80, 9648, 53], originalLanguage: 'en'),
    ];

    List<Movie> malayalam = [
      Movie(id: 101, title: 'Manjummel Boys', overview: 'A group of friends get into a perilous situation when they explore the Guna Caves in Kodaikanal.', posterPath: '/qA1FwzX1H7rTqAOKJj1rP1gQZgX.jpg', backdropPath: '/bWIIWhnGeXy3R57RzLzD3XQ1k5l.jpg', voteAverage: 8.4, releaseDate: '2024-02-22', genreIds: [12, 53, 18], originalLanguage: 'ml'),
      Movie(id: 102, title: 'Premalu', overview: 'Sachin pursues romance but finds himself caught between two potential partners.', posterPath: '/2v9o6591U4UaD10r1ZgA7O6Ff2Y.jpg', backdropPath: '/8sZJ0KzXF3n2X2Z5h2Q9a4K2Z6U.jpg', voteAverage: 8.1, releaseDate: '2024-02-09', genreIds: [35, 10749], originalLanguage: 'ml'),
      Movie(id: 103, title: 'Aavesham', overview: 'Three teens come to Bangalore for their engineering education and get involved in a fight. They find a local gangster to help them.', posterPath: '/tSgbRk9r7L2W6n0R0l3uE8kK0sT.jpg', backdropPath: '/yQ3X2V5Q9Y1v6H6J8B2Y4Q7A3B1.jpg', voteAverage: 8.5, releaseDate: '2024-04-11', genreIds: [28, 35], originalLanguage: 'ml'),
      Movie(id: 104, title: 'Lucifer', overview: 'A political Godfather dies and a lot of thieves dressed up as politicians took over the rule.', posterPath: '/8aV2L3NlXgX4G8A6n0p0a3z2v9B.jpg', backdropPath: '/r1V9H5pE7T4k4O3hY4aO3v3z2v9B.jpg', voteAverage: 7.9, releaseDate: '2019-03-28', genreIds: [28, 80, 53], originalLanguage: 'ml'),
      Movie(id: 105, title: 'Bramayugam', overview: 'A young singer who escapes from slavery finds himself trapped in a mysterious mansion owned by an enigmatic figure.', posterPath: '/aR8Bv1f4ZzQ2hA9bZ1lV2vV0Q9Y.jpg', backdropPath: '/yZ1lV2vV0Q9YaR8Bv1f4ZzQ2hA9.jpg', voteAverage: 8.2, releaseDate: '2024-02-15', genreIds: [27, 53, 9648], originalLanguage: 'ml'),
      Movie(id: 106, title: 'Minnal Murali', overview: 'A tailor gains special powers after being struck by lightning, but must take down an unexpected foe if he is to become the superhero his hometown needs.', posterPath: '/3xOWeA9bZ1lV2vV0Q9YaR8Bv1f4.jpg', backdropPath: '/1f4ZzQ2hA9bZ1lV2vV0Q9YaR8Bv.jpg', voteAverage: 7.9, releaseDate: '2021-12-24', genreIds: [28, 35, 14], originalLanguage: 'ml'),
      Movie(id: 107, title: 'Kumbalangi Nights', overview: 'Four brothers share a love-hate relationship with each other. Their relationship progresses to another level when Saji, Boney, and Franky decide to help Bobby stand by his love.', posterPath: '/Q9YaR8Bv1f4ZzQ2hA9bZ1lV2vV0.jpg', backdropPath: '/bZ1lV2vV0Q9YaR8Bv1f4ZzQ2hA9.jpg', voteAverage: 8.5, releaseDate: '2019-02-07', genreIds: [18, 35], originalLanguage: 'ml'),
      Movie(id: 108, title: 'Drishyam 2', overview: 'A gripping tale of an investigation and a family which is threatened by it. Will Georgekutty be able to protect his family this time?', posterPath: '/vV0Q9YaR8Bv1f4ZzQ2hA9bZ1lV2.jpg', backdropPath: '/A9bZ1lV2vV0Q9YaR8Bv1f4ZzQ2h.jpg', voteAverage: 8.3, releaseDate: '2021-02-19', genreIds: [53, 18, 80], originalLanguage: 'ml'),
    ];

    List<Movie> tamil = [
      Movie(id: 201, title: 'Leo', overview: 'Parthiban is a mild-mannered cafe owner in Kashmir, who fends off a gang of murderous thugs and gains attention from a drug cartel claiming he was once a part of them.', posterPath: '/pD6sL4vvnU0nV1dQaE1A4A0uN.jpg', backdropPath: '/aA1Y1q1yQ3E9B4xQ2u6l4D1nO.jpg', voteAverage: 7.8, releaseDate: '2023-10-19', genreIds: [28, 80, 53], originalLanguage: 'ta'),
      Movie(id: 202, title: 'Vikram', overview: 'A special agent investigates a murder committed by a masked group of serial killers.', posterPath: '/9G5N0H7yB9qQ2uO4m1x6N3C4A.jpg', backdropPath: '/pB1A9n4zP3b0W9oO0z4aH6b1wY.jpg', voteAverage: 8.3, releaseDate: '2022-06-03', genreIds: [28, 80, 53], originalLanguage: 'ta'),
      Movie(id: 203, title: 'Jailer', overview: 'A retired jailer goes on a manhunt to find his son\'s killers. But the road leads him to a familiar, albeit a bit darker place.', posterPath: '/r1M4N2b2aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/m1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 7.5, releaseDate: '2023-08-10', genreIds: [28, 35, 80], originalLanguage: 'ta'),
      Movie(id: 204, title: 'Master', overview: 'An alcoholic professor is sent to a juvenile school, where he clashes with a gangster who uses the school children for criminal activities.', posterPath: '/v0P8N2b2aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/b1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 7.4, releaseDate: '2021-01-13', genreIds: [28, 80, 53], originalLanguage: 'ta'),
      Movie(id: 205, title: 'Ponniyin Selvan: Part I', overview: 'Vandiyathevan sets out to cross the Chola land to deliver a message from the Crown Prince Aditha Karikalan.', posterPath: '/1A4A0uNqaE1A4A0uNqaE1A4A0uN.jpg', backdropPath: '/O0z4aH6b1wYO0z4aH6b1wYO0z4a.jpg', voteAverage: 7.6, releaseDate: '2022-09-30', genreIds: [28, 18, 36], originalLanguage: 'ta'),
      Movie(id: 206, title: 'Kaithi', overview: 'A recently released prisoner becomes involved in a chase with criminals as he races against time to drive poisoned cops to a hospital in exchange for meeting his daughter.', posterPath: '/b4X9v8Y0V3c7Bb4X9v8Y0V3c7B.jpg', backdropPath: '/H2p3aH6V3b4X9v8Y0V3c7BH2p3a.jpg', voteAverage: 8.5, releaseDate: '2019-10-25', genreIds: [28, 53, 80], originalLanguage: 'ta'),
      Movie(id: 207, title: 'Asuran', overview: 'The teenage son of a farmer from an underprivileged caste kills a rich, upper caste landlord. Will the farmer, a loving father and a pacifist by heart, be able to save his son?', posterPath: '/9v8Y0V3c7Bb4X9v8Y0V3c7Bb4X9.jpg', backdropPath: '/aH6V3b4X9v8Y0V3c7BaH6V3b4X9.jpg', voteAverage: 8.4, releaseDate: '2019-10-04', genreIds: [28, 18], originalLanguage: 'ta'),
      Movie(id: 208, title: '96', overview: 'Two high school sweethearts meet at a reunion after 22 years and reminisce about their past over the course of an evening.', posterPath: '/Y0V3c7Bb4X9v8Y0V3c7Bb4X9v8Y.jpg', backdropPath: '/V3b4X9v8Y0V3c7BaH6V3b4X9v8Y.jpg', voteAverage: 8.1, releaseDate: '2018-10-04', genreIds: [10749, 18], originalLanguage: 'ta'),
    ];

    List<Movie> hindi = [
      Movie(id: 301, title: 'Jawan', overview: 'A high-octane action thriller which outlines the emotional journey of a man who is set to rectify the wrongs in the society.', posterPath: '/jIhL6pbTeb11VXkpGWqB5hdvgUy.jpg', backdropPath: '/8tjB3L0z4A3H5W2y2Y4z2W4A3H.jpg', voteAverage: 7.6, releaseDate: '2023-09-07', genreIds: [28, 53], originalLanguage: 'hi'),
      Movie(id: 302, title: 'Pathaan', overview: 'An Indian spy takes on the leader of a group of mercenaries who have nefarious plans to target his homeland.', posterPath: '/m1p4A2v2aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/k1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 7.2, releaseDate: '2023-01-25', genreIds: [28, 53, 80], originalLanguage: 'hi'),
      Movie(id: 303, title: 'Animal', overview: 'A son undergoes a remarkable transformation as the bond with his father begins to fracture, and he becomes consumed by a quest for vengeance.', posterPath: '/A1P4H2p3aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/w1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 7.8, releaseDate: '2023-12-01', genreIds: [28, 80, 18], originalLanguage: 'hi'),
      Movie(id: 304, title: 'Dangal', overview: 'Former wrestler Mahavir Singh Phogat and his two wrestler daughters struggle towards glory at the Commonwealth Games.', posterPath: '/c1P4H2p3aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/t1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 8.0, releaseDate: '2016-12-21', genreIds: [28, 18, 36], originalLanguage: 'hi'),
      Movie(id: 305, title: '3 Idiots', overview: 'Two friends are searching for their long lost companion. They revisit their college days and recall the memories of their friend who inspired them to think differently.', posterPath: '/qIhL6pbTeb11VXkpGWqB5hdvgUy.jpg', backdropPath: '/6tjB3L0z4A3H5W2y2Y4z2W4A3H.jpg', voteAverage: 8.4, releaseDate: '2009-12-23', genreIds: [35, 18], originalLanguage: 'hi'),
      Movie(id: 306, title: 'Sholay', overview: 'After his family is murdered by a notorious and ruthless bandit, a former police officer enlists the services of two outlaws to capture the bandit.', posterPath: '/w1p4A2v2aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/h1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 8.2, releaseDate: '1975-08-15', genreIds: [28, 12, 35], originalLanguage: 'hi'),
      Movie(id: 307, title: 'PK', overview: 'An alien on Earth loses the only device he can use to communicate with his spaceship. His innocent nature and child-like questions force the country to evaluate the impact of religion on its people.', posterPath: '/B1P4H2p3aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/x1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 8.0, releaseDate: '2014-12-18', genreIds: [35, 18, 878], originalLanguage: 'hi'),
      Movie(id: 308, title: 'Bajrangi Bhaijaan', overview: 'A young mute girl from Pakistan loses herself in India with no way to head back. A devoted man with a magnanimous spirit undertakes the task to get her back to her motherland and unite her with her family.', posterPath: '/d1P4H2p3aH6V3b4X9v8Y0V3c7B.jpg', backdropPath: '/s1V4H2p3aH6V3b4X9v8Y0V3c7B.jpg', voteAverage: 8.1, releaseDate: '2015-07-17', genreIds: [28, 35, 18], originalLanguage: 'hi'),
    ];

    List<Movie> getListWith200(List<Movie> source) {
      List<Movie> extended = [];
      while (extended.length < 200) {
        extended.addAll(source.map((m) => Movie(
              id: m.id * 1000 + extended.length, // Ensure unique IDs
              title: m.title,
              overview: m.overview,
              posterPath: m.posterPath,
              backdropPath: m.backdropPath,
              voteAverage: m.voteAverage,
              releaseDate: m.releaseDate,
              genreIds: m.genreIds,
              originalLanguage: m.originalLanguage,
            )));
      }
      extended.shuffle();
      return extended;
    }

    if (langCode == 'ml') return getListWith200(malayalam);
    if (langCode == 'ta') return getListWith200(tamil);
    if (langCode == 'hi') return getListWith200(hindi);
    if (langCode == 'en') return getListWith200(english);
    
    // For 'all' or search, combine them
    final all = [...english, ...malayalam, ...tamil, ...hindi];
    all.shuffle();
    return all;
  }
}
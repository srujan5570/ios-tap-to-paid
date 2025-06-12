import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for better user experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for better appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unity Ads Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;
  int _coins = 0;
  String _ipAddress = '';
  String _country = '';
  String _gpsCoordinates = '';
  String _gpsAddress = '';
  bool _isUnityAdsInitialized = false;
  bool _isLoadingLocation = false;
  String _currentGameId = '';
  int _interstitialAdsWatched = 0;
  int _rewardedAdsWatched = 0;
  bool _isChangingGameId = false;

  // List of game IDs
  final List<String> _gameIds = [
    '5861330',
    '5859176',
    '5861328',
    '5861332',
    '5861335',
    '5861337',
    '5861339',
    '5861345',
    '5861347',
    '5861349',
    '5861350',
    '5861360',
    '5861362',
    '5861367',
    '5861368',
    '5861370',
    '5861300',
    '5861372',
    '5861458',
    '5861376',
    '5861378',
    '5861380',
    '5861383',
    '5861384',
    '5861386',
    '5861389',
    '5861391',
    '5861395',
    '5861396',
    '5861439',
    '5861440',
    '5861443',
    '5861444',
    '5861446',
    '5861448',
    '5861450',
    '5861452',
    '5861455',
    '5861457',
    '5861437',
    '5861462',
    '5861434',
    '5861432',
    '5861466',
    '5861306',
    '5861430',
    '5861428',
    '5861427',
    '5861425',
    '5861423',
    '5861421',
    '5861418',
    '5861415',
    '5861412',
    '5861410',
    '5861409',
    '5861406',
    '5861403',
  ];

  // Random number generator
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize everything asynchronously for faster app start
    Future.microtask(() {
      _selectRandomGameId();
      _getIpLocation();
      _checkGpsPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_ipAddress.isEmpty) {
        _getIpLocation();
      }

      // Reset Unity Ads when app comes back to foreground for better performance
      if (_isUnityAdsInitialized &&
          !_isInterstitialLoaded &&
          !_isRewardedLoaded) {
        _resetUnityAds();
      }
    }
  }

  void _selectRandomGameId() {
    final newGameId = _gameIds[_random.nextInt(_gameIds.length)];
    print('Selected new Game ID: $newGameId (previous: $_currentGameId)');
    setState(() {
      _currentGameId = newGameId;
    });
  }

  Future<void> _getIpLocation() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://ipapi.co/json/'),
            headers: {'User-Agent': 'Unity-Ads-Demo/1.0'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _ipAddress = data['ip'] ?? '';
            _country = data['country_name'] ?? '';
          });
        }
      } else {
        print('Failed to load IP: ${response.statusCode}');
        _retryGetIpLocation();
      }
    } catch (e) {
      print('Error getting IP location: $e');
      _retryGetIpLocation();
    }
  }

  void _retryGetIpLocation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _ipAddress.isEmpty) {
        _getIpLocation();
      }
    });
  }

  Future<void> _checkGpsPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsCoordinates = 'Permission denied';
            _gpsAddress = 'Permission denied';
          });
        }
      }
    } catch (e) {
      print('Error checking GPS permission: $e');
    }
  }

  Future<bool> _initUnityAds() async {
    if (_isChangingGameId) {
      print('Game ID change in progress, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      return false;
    }

    if (_isUnityAdsInitialized) {
      print('Unity Ads already initialized with Game ID: $_currentGameId');
      return true;
    }

    print('Initializing Unity Ads with Game ID: $_currentGameId');

    try {
      bool initSuccess = false;
      setState(() => _isChangingGameId = true);

      await UnityAds.init(
        gameId: _currentGameId,
        testMode: false,
        onComplete: () {
          print(
            'Unity Ads initialization complete with Game ID: $_currentGameId',
          );
          if (mounted) {
            setState(() {
              _isUnityAdsInitialized = true;
              _isChangingGameId = false;
            });
          }
          initSuccess = true;
        },
        onFailed: (error, message) {
          print('Unity Ads initialization failed: $message');
          if (mounted) {
            setState(() {
              _isUnityAdsInitialized = false;
              _isChangingGameId = false;
            });
          }
          initSuccess = false;
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Unity Ads initialization timed out');
          if (mounted) {
            setState(() {
              _isUnityAdsInitialized = false;
              _isChangingGameId = false;
            });
          }
          return;
        },
      );

      // Ensure we return the correct status
      return initSuccess;
    } catch (e) {
      print('Error initializing Unity Ads: $e');
      if (mounted) {
        setState(() {
          _isUnityAdsInitialized = false;
          _isChangingGameId = false;
        });
      }
      return false;
    }
  }

  Future<void> _resetUnityAds() async {
    print('Resetting Unity Ads...');
    if (_isChangingGameId) {
      print('Game ID change already in progress, waiting...');
      return;
    }

    if (mounted) {
      setState(() {
        _isInterstitialLoaded = false;
        _isRewardedLoaded = false;
        _isUnityAdsInitialized = false;
        _isChangingGameId = true;
      });
    }

    // Force a small delay to ensure cleanup
    await Future.delayed(const Duration(milliseconds: 300));

    _selectRandomGameId();

    if (mounted) {
      setState(() {
        _isChangingGameId = false;
      });
    }

    print('Unity Ads reset complete. New Game ID: $_currentGameId');
  }

  Future<void> _loadInterstitialAd() async {
    setState(() {
      _isLoadingInterstitial = true;
    });

    // Make sure Unity Ads is initialized with the current game ID
    bool initialized = await _initUnityAds();
    if (!initialized) {
      print('Failed to initialize Unity Ads');
      if (mounted) {
        setState(() {
          _isLoadingInterstitial = false;
        });
      }
      return;
    }

    try {
      print('Loading interstitial ad with Game ID: $_currentGameId');
      UnityAds.load(
        placementId: 'Interstitial_iOS',
        onComplete: (placementId) {
          print('Interstitial ad loaded successfully');
          if (mounted) {
            setState(() {
              _isInterstitialLoaded = true;
              _isLoadingInterstitial = false;
            });
          }
        },
        onFailed: (placementId, error, message) {
          print('Interstitial ad load failed: $message');
          if (mounted) {
            setState(() {
              _isInterstitialLoaded = false;
              _isLoadingInterstitial = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      if (mounted) {
        setState(() {
          _isInterstitialLoaded = false;
          _isLoadingInterstitial = false;
        });
      }
    }
  }

  void _showInterstitialAd() async {
    if (_isInterstitialLoaded) {
      try {
        print('Showing interstitial ad with Game ID: $_currentGameId');
        UnityAds.showVideoAd(
          placementId: 'Interstitial_iOS',
          onComplete: (placementId) async {
            print('Interstitial ad completed successfully');
            if (mounted) {
              setState(() {
                _isInterstitialLoaded = false;
                _interstitialAdsWatched++;
                _coins += 5;
              });
            }

            // Reset Unity Ads with new game ID after showing the ad
            await _resetUnityAds();
          },
          onFailed: (placementId, error, message) async {
            print('Show interstitial ad failed: $message');
            if (mounted) {
              setState(() => _isInterstitialLoaded = false);
            }

            // Reset Unity Ads even on failure
            await _resetUnityAds();
          },
          onStart: (placementId) => print('Interstitial ad started'),
          onClick: (placementId) => print('Interstitial ad clicked'),
        );
      } catch (e) {
        print('Error showing interstitial ad: $e');
        if (mounted) {
          setState(() => _isInterstitialLoaded = false);
        }
        _resetUnityAds();
      }
    } else {
      print('Interstitial ad not loaded yet');
    }
  }

  Future<void> _loadRewardedAd() async {
    setState(() {
      _isLoadingRewarded = true;
    });

    // Make sure Unity Ads is initialized with the current game ID
    bool initialized = await _initUnityAds();
    if (!initialized) {
      print('Failed to initialize Unity Ads');
      if (mounted) {
        setState(() {
          _isLoadingRewarded = false;
        });
      }
      return;
    }

    try {
      print('Loading rewarded ad with Game ID: $_currentGameId');
      UnityAds.load(
        placementId: 'Rewarded_iOS',
        onComplete: (placementId) {
          print('Rewarded ad loaded successfully');
          if (mounted) {
            setState(() {
              _isRewardedLoaded = true;
              _isLoadingRewarded = false;
            });
          }
        },
        onFailed: (placementId, error, message) {
          print('Rewarded ad load failed: $message');
          if (mounted) {
            setState(() {
              _isRewardedLoaded = false;
              _isLoadingRewarded = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      if (mounted) {
        setState(() {
          _isRewardedLoaded = false;
          _isLoadingRewarded = false;
        });
      }
    }
  }

  void _showRewardedAd() async {
    if (_isRewardedLoaded) {
      try {
        print('Showing rewarded ad with Game ID: $_currentGameId');
        UnityAds.showVideoAd(
          placementId: 'Rewarded_iOS',
          onComplete: (placementId) async {
            print('Rewarded ad completed successfully');
            if (mounted) {
              setState(() {
                _isRewardedLoaded = false;
                _coins += 10;
                _rewardedAdsWatched++;
              });
            }

            // Reset Unity Ads with new game ID after showing the ad
            await _resetUnityAds();
          },
          onFailed: (placementId, error, message) async {
            print('Show rewarded ad failed: $message');
            if (mounted) {
              setState(() => _isRewardedLoaded = false);
            }

            // Reset Unity Ads even on failure
            await _resetUnityAds();
          },
          onStart: (placementId) => print('Rewarded ad started'),
          onClick: (placementId) => print('Rewarded ad clicked'),
        );
      } catch (e) {
        print('Error showing rewarded ad: $e');
        if (mounted) {
          setState(() => _isRewardedLoaded = false);
        }
        _resetUnityAds();
      }
    } else {
      print('Rewarded ad not loaded yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unity Ads Demo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Game ID Card
                _buildInfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Current Game ID: $_currentGameId',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const Divider(thickness: 1),
                      _buildInfoRow('IP Address:', _ipAddress),
                      const SizedBox(height: 8),
                      _buildInfoRow('Country:', _country),
                      const SizedBox(height: 8),
                      _buildInfoRow('GPS:', _gpsCoordinates),
                      const SizedBox(height: 8),
                      _buildInfoRow('Address:', _gpsAddress, isAddress: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Ad Statistics Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ad Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAdStat(
                            'Interstitial Ads',
                            _interstitialAdsWatched,
                            Colors.blue,
                          ),
                          _buildAdStat(
                            'Rewarded Ads',
                            _rewardedAdsWatched,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Coins Counter with Animation
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _coins),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Text(
                      'Coins: $value',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Rewarded Ad Button First
                _buildAdButton(
                  isLoading: _isLoadingRewarded,
                  isLoaded: _isRewardedLoaded,
                  loadAction: _loadRewardedAd,
                  showAction: _showRewardedAd,
                  loadText: 'Load Rewarded Ad',
                  showText: 'Show Rewarded Ad',
                  loadedColor: Colors.green,
                  margin: const EdgeInsets.only(bottom: 20),
                ),
                // Interstitial Ad Button Second
                _buildAdButton(
                  isLoading: _isLoadingInterstitial,
                  isLoaded: _isInterstitialLoaded,
                  loadAction: _loadInterstitialAd,
                  showAction: _showInterstitialAd,
                  loadText: 'Load Interstitial Ad',
                  showText: 'Show Interstitial Ad',
                  loadedColor: Colors.blue,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAddress = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.right,
            overflow: isAddress ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAdStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdButton({
    required bool isLoading,
    required bool isLoaded,
    required VoidCallback loadAction,
    required VoidCallback showAction,
    required String loadText,
    required String showText,
    required Color loadedColor,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: 250,
      margin: margin,
      child: ElevatedButton(
        onPressed: isLoading ? null : (isLoaded ? showAction : loadAction),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLoaded
                  ? loadedColor
                  : (isLoading ? Colors.grey[400] : Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.white,
          elevation: isLoaded ? 5 : 3,
        ),
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Loading Ad...',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                )
                : Text(
                  isLoaded ? showText : loadText,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
      ),
    );
  }
}

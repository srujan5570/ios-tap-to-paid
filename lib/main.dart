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
      if (!_isLoadingInterstitial && !_isLoadingRewarded) {
        _forceResetUnityAds();
      }
    }
  }

  void _selectRandomGameId() {
    setState(() {
      _currentGameId = _gameIds[_random.nextInt(_gameIds.length)];
    });
    print('Selected Game ID: $_currentGameId');
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

  // Method to properly clean up Unity Ads initialization
  Future<void> _cleanupUnityAds() async {
    try {
      // Set all ad loading and loaded flags to false
      if (mounted) {
        setState(() {
          _isInterstitialLoaded = false;
          _isRewardedLoaded = false;
          _isUnityAdsInitialized = false;
        });
      }

      // Wait for any potential pending operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error cleaning up Unity Ads: $e');
    }
  }

  // Method to force reinitialize Unity Ads with new game ID
  Future<void> _forceResetUnityAds() async {
    await _cleanupUnityAds();
    _selectRandomGameId(); // Get a new random game ID
    print('Force reset Unity Ads with new Game ID: $_currentGameId');
  }

  Future<void> _initUnityAds() async {
    if (_isUnityAdsInitialized) return;

    print('Initializing Unity Ads with Game ID: $_currentGameId');

    try {
      await UnityAds.init(
        gameId: _currentGameId,
        testMode: false,
        onComplete: () {
          if (mounted) {
            setState(() => _isUnityAdsInitialized = true);
            print('Initialization Complete with Game ID: $_currentGameId');
          }
        },
        onFailed: (error, message) {
          print('Initialization Failed: $message');
          if (mounted) {
            setState(() => _isUnityAdsInitialized = false);
          }
          // Retry with a different game ID after failure
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _forceResetUnityAds();
            }
          });
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error initializing Unity Ads: $e');
      if (mounted) {
        setState(() => _isUnityAdsInitialized = false);
      }
      // Retry with a different game ID after exception
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _forceResetUnityAds();
        }
      });
    }
  }

  Future<void> _resetUnityAds() async {
    await _cleanupUnityAds();
    _selectRandomGameId();
  }

  void _loadInterstitialAd() {
    setState(() {
      _isLoadingInterstitial = true;
    });

    // Always reinitialize Unity Ads with current game ID before loading
    _cleanupUnityAds().then((_) {
      _initUnityAds().then((_) {
        if (!_isUnityAdsInitialized) {
          print('Unity Ads not initialized yet. Trying to initialize...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isLoadingInterstitial = false;
              });
            }
          });
          return;
        }

        try {
          print('Loading Interstitial Ad with Game ID: $_currentGameId');
          UnityAds.load(
            placementId: 'Interstitial_iOS',
            onComplete: (placementId) {
              if (mounted) {
                setState(() {
                  _isInterstitialLoaded = true;
                  _isLoadingInterstitial = false;
                });
                print('Interstitial Ad loaded with Game ID: $_currentGameId');
              }
            },
            onFailed: (placementId, error, message) {
              print('Load Failed: $message');
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
      });
    });
  }

  void _showInterstitialAd() {
    if (_isInterstitialLoaded) {
      try {
        print('Showing Interstitial Ad with Game ID: $_currentGameId');
        UnityAds.showVideoAd(
          placementId: 'Interstitial_iOS',
          onComplete: (placementId) async {
            print('Interstitial Ad completed with Game ID: $_currentGameId');
            if (mounted) {
              setState(() {
                _isInterstitialLoaded = false;
                _interstitialAdsWatched++;
                _coins += 5;
              });
              await _resetUnityAds();
            }
          },
          onFailed: (placementId, error, message) {
            print('Show Failed: $message');
            if (mounted) {
              setState(() => _isInterstitialLoaded = false);
              _resetUnityAds();
            }
          },
          onStart:
              (placementId) =>
                  print('Ad Started with Game ID: $_currentGameId'),
          onClick:
              (placementId) =>
                  print('Ad Clicked with Game ID: $_currentGameId'),
        );
      } catch (e) {
        print('Error showing interstitial ad: $e');
        if (mounted) {
          setState(() => _isInterstitialLoaded = false);
        }
      }
    }
  }

  void _loadRewardedAd() {
    setState(() {
      _isLoadingRewarded = true;
    });

    // Always reinitialize Unity Ads with current game ID before loading
    _cleanupUnityAds().then((_) {
      _initUnityAds().then((_) {
        if (!_isUnityAdsInitialized) {
          print('Unity Ads not initialized yet. Trying to initialize...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isLoadingRewarded = false;
              });
            }
          });
          return;
        }

        try {
          print('Loading Rewarded Ad with Game ID: $_currentGameId');
          UnityAds.load(
            placementId: 'Rewarded_iOS',
            onComplete: (placementId) {
              if (mounted) {
                setState(() {
                  _isRewardedLoaded = true;
                  _isLoadingRewarded = false;
                });
                print('Rewarded Ad loaded with Game ID: $_currentGameId');
              }
            },
            onFailed: (placementId, error, message) {
              print('Load Failed: $message');
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
      });
    });
  }

  void _showRewardedAd() {
    if (_isRewardedLoaded) {
      try {
        print('Showing Rewarded Ad with Game ID: $_currentGameId');
        UnityAds.showVideoAd(
          placementId: 'Rewarded_iOS',
          onComplete: (placementId) async {
            print('Rewarded Ad completed with Game ID: $_currentGameId');
            if (mounted) {
              setState(() {
                _isRewardedLoaded = false;
                _coins += 10;
                _rewardedAdsWatched++;
              });
              await _resetUnityAds();
            }
          },
          onFailed: (placementId, error, message) {
            print('Show Failed: $message');
            if (mounted) {
              setState(() => _isRewardedLoaded = false);
              _resetUnityAds();
            }
          },
          onStart:
              (placementId) =>
                  print('Ad Started with Game ID: $_currentGameId'),
          onClick:
              (placementId) =>
                  print('Ad Clicked with Game ID: $_currentGameId'),
        );
      } catch (e) {
        print('Error showing rewarded ad: $e');
        if (mounted) {
          setState(() => _isRewardedLoaded = false);
        }
      }
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

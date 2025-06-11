import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unity Ads Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
    _selectRandomGameId();
    _getIpLocation();
    _checkGpsPermission();
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
    }
  }

  void _selectRandomGameId() {
    setState(() {
      _currentGameId = _gameIds[_random.nextInt(_gameIds.length)];
    });
  }

  Future<void> _getIpLocation() async {
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'User-Agent': 'Unity-Ads-Demo/1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ipAddress = data['ip'] ?? '';
          _country = data['country_name'] ?? '';
        });
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
    Future.delayed(const Duration(seconds: 1), () {
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
        setState(() {
          _gpsCoordinates = 'Permission denied forever';
          _gpsAddress = 'Permission denied forever';
        });
      }
    } catch (e) {
      print('Error checking GPS permission: $e');
    }
  }

  Future<void> _initUnityAds() async {
    if (_isUnityAdsInitialized) return;

    try {
      await UnityAds.init(
        gameId: _currentGameId,
        testMode: false,
        onComplete: () {
          setState(() => _isUnityAdsInitialized = true);
          print('Initialization Complete with Game ID: $_currentGameId');
        },
        onFailed: (error, message) {
          print('Initialization Failed: $message');
          setState(() => _isUnityAdsInitialized = false);
        },
      );
    } catch (e) {
      print('Error initializing Unity Ads: $e');
      setState(() => _isUnityAdsInitialized = false);
    }
  }

  Future<void> _resetUnityAds() async {
    setState(() {
      _isInterstitialLoaded = false;
      _isRewardedLoaded = false;
      _isUnityAdsInitialized = false;
    });
    _selectRandomGameId();
  }

  void _loadInterstitialAd() {
    _initUnityAds().then((_) {
      if (!_isUnityAdsInitialized) {
        print('Unity Ads not initialized yet. Trying to initialize...');
        return;
      }

      try {
        UnityAds.load(
          placementId: 'Interstitial_iOS',
          onComplete: (placementId) {
            setState(() => _isInterstitialLoaded = true);
            print('Interstitial Ad loaded with Game ID: $_currentGameId');
          },
          onFailed: (placementId, error, message) {
            print('Load Failed: $message');
            setState(() => _isInterstitialLoaded = false);
          },
        );
      } catch (e) {
        print('Error loading interstitial ad: $e');
        setState(() => _isInterstitialLoaded = false);
      }
    });
  }

  void _showInterstitialAd() {
    if (_isInterstitialLoaded) {
      try {
        UnityAds.showVideoAd(
          placementId: 'Interstitial_iOS',
          onComplete: (placementId) async {
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
          onStart: (placementId) => print('Ad Started'),
          onClick: (placementId) => print('Ad Clicked'),
        );
      } catch (e) {
        print('Error showing interstitial ad: $e');
        setState(() => _isInterstitialLoaded = false);
      }
    }
  }

  void _loadRewardedAd() {
    _initUnityAds().then((_) {
      if (!_isUnityAdsInitialized) {
        print('Unity Ads not initialized yet. Trying to initialize...');
        return;
      }

      try {
        UnityAds.load(
          placementId: 'Rewarded_iOS',
          onComplete: (placementId) {
            setState(() => _isRewardedLoaded = true);
            print('Rewarded Ad loaded with Game ID: $_currentGameId');
          },
          onFailed: (placementId, error, message) {
            print('Load Failed: $message');
            setState(() => _isRewardedLoaded = false);
          },
        );
      } catch (e) {
        print('Error loading rewarded ad: $e');
        setState(() => _isRewardedLoaded = false);
      }
    });
  }

  void _showRewardedAd() {
    if (_isRewardedLoaded) {
      try {
        UnityAds.showVideoAd(
          placementId: 'Rewarded_iOS',
          onComplete: (placementId) async {
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
          onStart: (placementId) => print('Ad Started'),
          onClick: (placementId) => print('Ad Clicked'),
        );
      } catch (e) {
        print('Error showing rewarded ad: $e');
        setState(() => _isRewardedLoaded = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unity Ads Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'IP Address:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_ipAddress, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Country:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_country, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GPS:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _gpsCoordinates,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _gpsAddress,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        Column(
                          children: [
                            const Text(
                              'Interstitial Ads',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_interstitialAdsWatched',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Rewarded Ads',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_rewardedAdsWatched',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Coins: $_coins',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 30),
              // Rewarded Ad Button First
              Container(
                width: 250,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed:
                      !_isRewardedLoaded ? _loadRewardedAd : _showRewardedAd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    backgroundColor:
                        _isRewardedLoaded ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isRewardedLoaded ? 'Show Rewarded Ad' : 'Load Rewarded Ad',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              // Interstitial Ad Button Second
              Container(
                width: 250,
                child: ElevatedButton(
                  onPressed:
                      !_isInterstitialLoaded
                          ? _loadInterstitialAd
                          : _showInterstitialAd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    backgroundColor:
                        _isInterstitialLoaded ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isInterstitialLoaded
                        ? 'Show Interstitial Ad'
                        : 'Load Interstitial Ad',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

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
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    _selectRandomGameId();
    _initUnityAds();
    _getIpLocation();
    _getGpsLocation();
  }

  void _selectRandomGameId() {
    setState(() {
      _currentGameId = _gameIds[_random.nextInt(_gameIds.length)];
    });
  }

  Future<void> _getIpLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ipAddress = data['ip'] ?? 'Unknown';
          _country = data['country_name'] ?? 'Unknown';
        });
      }
    } catch (e) {
      print('Error getting IP location: $e');
    }
  }

  Future<void> _getGpsLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsCoordinates = 'Location permissions denied';
            _gpsAddress = 'Cannot determine address';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsCoordinates = 'Location permissions permanently denied';
          _gpsAddress = 'Cannot determine address';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _gpsCoordinates = '${position.latitude}, ${position.longitude}';
      });

      // Get the address from the coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _gpsAddress =
                '${place.street}, ${place.locality}, ${place.country}';
          });
        }
      } catch (e) {
        print('Error getting address: $e');
        setState(() {
          _gpsAddress = 'Address not available';
        });
      }
    } catch (e) {
      print('Error getting GPS location: $e');
      setState(() {
        _gpsCoordinates = 'Error getting location';
        _gpsAddress = 'Cannot determine address';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _initUnityAds() async {
    await UnityAds.init(
      gameId: _currentGameId,
      testMode: false,
      onComplete: () {
        setState(() => _isUnityAdsInitialized = true);
        print('Initialization Complete with Game ID: $_currentGameId');
      },
      onFailed: (error, message) => print('Initialization Failed: $message'),
    );
  }

  Future<void> _resetUnityAds() async {
    setState(() {
      _isInterstitialLoaded = false;
      _isRewardedLoaded = false;
      _isUnityAdsInitialized = false;
    });
    _selectRandomGameId();
    await _initUnityAds();
  }

  void _loadInterstitialAd() {
    if (!_isUnityAdsInitialized) {
      print('Unity Ads not initialized yet. Current Game ID: $_currentGameId');
      return;
    }

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
  }

  void _showInterstitialAd() {
    if (_isInterstitialLoaded) {
      UnityAds.showVideoAd(
        placementId: 'Interstitial_iOS',
        onComplete: (placementId) async {
          setState(() {
            _isInterstitialLoaded = false;
            _interstitialAdsWatched++;
          });
          await _resetUnityAds();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() => _isInterstitialLoaded = false);
          _selectRandomGameId();
        },
        onStart: (placementId) => print('Ad Started'),
        onClick: (placementId) => print('Ad Clicked'),
      );
    }
  }

  void _loadRewardedAd() {
    if (!_isUnityAdsInitialized) {
      print('Unity Ads not initialized yet. Current Game ID: $_currentGameId');
      return;
    }

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
  }

  void _showRewardedAd() {
    if (_isRewardedLoaded) {
      UnityAds.showVideoAd(
        placementId: 'Rewarded_iOS',
        onComplete: (placementId) async {
          setState(() {
            _isRewardedLoaded = false;
            _coins += 10;
            _rewardedAdsWatched++;
          });
          await _resetUnityAds();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() => _isRewardedLoaded = false);
          _selectRandomGameId();
        },
        onStart: (placementId) => print('Ad Started'),
        onClick: (placementId) => print('Ad Clicked'),
      );
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
                    const Text(
                      'Location Information:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IP Address: $_ipAddress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Country: $_country',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'GPS Information:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coordinates: $_gpsCoordinates',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Address: $_gpsAddress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _isLoadingLocation
                        ? const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : const SizedBox.shrink(),
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
              ElevatedButton(
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
                ),
                child: Text(
                  _isInterstitialLoaded
                      ? 'Show Interstitial Ad'
                      : 'Load Interstitial Ad',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    !_isRewardedLoaded ? _loadRewardedAd : _showRewardedAd,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  backgroundColor:
                      _isRewardedLoaded ? Colors.blue : Colors.grey,
                ),
                child: Text(
                  _isRewardedLoaded ? 'Show Rewarded Ad' : 'Load Rewarded Ad',
                  style: const TextStyle(fontSize: 18),
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

import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
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
      ),
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
  bool _isUnityAdsInitialized = false;
  bool _isAutoPlayEnabled = false;
  String _currentStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initUnityAds();
    _getIpLocation();
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

  Future<void> _initUnityAds() async {
    await UnityAds.init(
      gameId: '5859176',
      testMode: false,
      onComplete: () {
        setState(() {
          _isUnityAdsInitialized = true;
          _currentStatus = 'Unity Ads Initialized';
        });
        _startAdSequence();
      },
      onFailed: (error, message) {
        setState(() => _currentStatus = 'Initialization Failed: $message');
        print('Initialization Failed: $message');
      },
    );
  }

  Future<void> _resetUnityAds() async {
    setState(() {
      _isInterstitialLoaded = false;
      _isRewardedLoaded = false;
      _isUnityAdsInitialized = false;
      _currentStatus = 'Resetting Unity Ads...';
    });
    await _initUnityAds();
  }

  void _startAdSequence() {
    if (!_isUnityAdsInitialized) return;
    _loadNextAd();
  }

  void _loadNextAd() {
    if (!_isUnityAdsInitialized || !_isAutoPlayEnabled) return;

    if (!_isInterstitialLoaded && !_isRewardedLoaded) {
      setState(() => _currentStatus = 'Loading Interstitial Ad...');
      _loadInterstitialAd();
    }
  }

  Future<void> _retryLoadAd(String adType, {int retryCount = 0}) async {
    if (retryCount >= 3 || !_isAutoPlayEnabled) return;

    setState(() => _currentStatus = 'Retrying $adType Ad (Attempt ${retryCount + 1})...');
    await Future.delayed(const Duration(seconds: 1));
    
    if (adType == 'Interstitial') {
      _loadInterstitialAd(retryCount: retryCount + 1);
    } else {
      _loadRewardedAd(retryCount: retryCount + 1);
    }
  }

  void _loadInterstitialAd({int retryCount = 0}) {
    if (!_isUnityAdsInitialized) return;
    
    UnityAds.load(
      placementId: 'Interstitial_iOS',
      onComplete: (placementId) {
        setState(() {
          _isInterstitialLoaded = true;
          _currentStatus = 'Interstitial Ad Loaded';
        });
        if (_isAutoPlayEnabled) {
          _showInterstitialAd();
        }
      },
      onFailed: (placementId, error, message) {
        print('Load Failed: $message');
        setState(() {
          _isInterstitialLoaded = false;
          _currentStatus = 'Interstitial Load Failed: $message';
        });
        if (_isAutoPlayEnabled) {
          if (retryCount < 3) {
            _retryLoadAd('Interstitial', retryCount: retryCount);
          } else {
            _loadRewardedAd(); // Try rewarded ad after 3 retries
          }
        }
      },
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialLoaded) {
      setState(() => _currentStatus = 'Showing Interstitial Ad...');
      UnityAds.showVideoAd(
        placementId: 'Interstitial_iOS',
        onComplete: (placementId) {
          setState(() {
            _isInterstitialLoaded = false;
            _currentStatus = 'Interstitial Ad Completed';
          });
          // Immediately load next ad
          _loadRewardedAd();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() {
            _isInterstitialLoaded = false;
            _currentStatus = 'Interstitial Show Failed: $message';
          });
          // Immediately try next ad
          _loadRewardedAd();
        },
        onStart: (placementId) => setState(() => _currentStatus = 'Interstitial Ad Started'),
        onClick: (placementId) => print('Ad Clicked'),
      );
    }
  }

  void _loadRewardedAd({int retryCount = 0}) {
    if (!_isUnityAdsInitialized) return;
    
    setState(() => _currentStatus = 'Loading Rewarded Ad...');
    UnityAds.load(
      placementId: 'Rewarded_iOS',
      onComplete: (placementId) {
        setState(() {
          _isRewardedLoaded = true;
          _currentStatus = 'Rewarded Ad Loaded';
        });
        if (_isAutoPlayEnabled) {
          _showRewardedAd();
        }
      },
      onFailed: (placementId, error, message) {
        print('Load Failed: $message');
        setState(() {
          _isRewardedLoaded = false;
          _currentStatus = 'Rewarded Load Failed: $message';
        });
        if (_isAutoPlayEnabled) {
          if (retryCount < 3) {
            _retryLoadAd('Rewarded', retryCount: retryCount);
          } else {
            _loadInterstitialAd(); // Try interstitial ad after 3 retries
          }
        }
      },
    );
  }

  void _showRewardedAd() {
    if (_isRewardedLoaded) {
      setState(() => _currentStatus = 'Showing Rewarded Ad...');
      UnityAds.showVideoAd(
        placementId: 'Rewarded_iOS',
        onComplete: (placementId) {
          setState(() {
            _isRewardedLoaded = false;
            _coins += 10;
            _currentStatus = 'Rewarded Ad Completed';
          });
          // Immediately load next ad
          _loadInterstitialAd();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() {
            _isRewardedLoaded = false;
            _currentStatus = 'Rewarded Show Failed: $message';
          });
          // Immediately try next ad
          _loadInterstitialAd();
        },
        onStart: (placementId) => setState(() => _currentStatus = 'Rewarded Ad Started'),
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
      body: Center(
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
                children: [
                  Text(
                    'IP Address: $_ipAddress',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Country: $_country',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Coins: $_coins',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentStatus,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAutoPlayEnabled = !_isAutoPlayEnabled;
                  if (_isAutoPlayEnabled) {
                    _startAdSequence();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isAutoPlayEnabled ? Colors.green : Colors.red,
              ),
              child: Text(
                _isAutoPlayEnabled ? 'Stop Auto Play' : 'Start Auto Play',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

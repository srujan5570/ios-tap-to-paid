import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/castar_service.dart';

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
  bool _isCastarInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    if (_isCastarInitialized) {
      CastarService.stop();
    }
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Initialize CastarSDK
    _isCastarInitialized = await CastarService.initialize();
    if (_isCastarInitialized) {
      await CastarService.start();
    }

    // Initialize Unity Ads
    await _initUnityAds();
    
    // Get IP Location
    await _getIpLocation();
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
        setState(() => _isUnityAdsInitialized = true);
        print('Initialization Complete');
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
    await _initUnityAds();
  }

  void _loadInterstitialAd() {
    if (!_isUnityAdsInitialized) return;
    
    UnityAds.load(
      placementId: 'Interstitial_iOS',
      onComplete: (placementId) {
        setState(() => _isInterstitialLoaded = true);
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
          setState(() => _isInterstitialLoaded = false);
          await _resetUnityAds();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() => _isInterstitialLoaded = false);
        },
        onStart: (placementId) => print('Ad Started'),
        onClick: (placementId) => print('Ad Clicked'),
      );
    }
  }

  void _loadRewardedAd() {
    if (!_isUnityAdsInitialized) return;
    
    UnityAds.load(
      placementId: 'Rewarded_iOS',
      onComplete: (placementId) {
        setState(() => _isRewardedLoaded = true);
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
          });
          await _resetUnityAds();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() => _isRewardedLoaded = false);
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: !_isInterstitialLoaded ? _loadInterstitialAd : _showInterstitialAd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isInterstitialLoaded ? Colors.blue : Colors.grey,
              ),
              child: Text(
                _isInterstitialLoaded ? 'Show Interstitial Ad' : 'Load Interstitial Ad',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: !_isRewardedLoaded ? _loadRewardedAd : _showRewardedAd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isRewardedLoaded ? Colors.blue : Colors.grey,
              ),
              child: Text(
                _isRewardedLoaded ? 'Show Rewarded Ad' : 'Load Rewarded Ad',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

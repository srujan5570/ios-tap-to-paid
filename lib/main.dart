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
  String _ipInfo = 'Loading location...';
  bool _isUnityAdsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initUnityAds();
    _loadIpInfo();
  }

  Future<void> _loadIpInfo() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ipInfo = '${data['ip']} - ${data['country_name']}';
        });
      }
    } catch (e) {
      setState(() {
        _ipInfo = 'Failed to load location';
      });
    }
  }

  Future<void> _initUnityAds() async {
    await UnityAds.init(
      gameId: '5859176',
      testMode: false,
      onComplete: () {
        print('Initialization Complete');
        setState(() => _isUnityAdsInitialized = true);
      },
      onFailed: (error, message) {
        print('Initialization Failed: $message');
        setState(() => _isUnityAdsInitialized = false);
      },
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ipInfo,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Coins: $_coins',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: !_isInterstitialLoaded ? _loadInterstitialAd : _showInterstitialAd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: _isInterstitialLoaded ? Colors.blue : Colors.grey,
                  ),
                  child: Text(
                    _isInterstitialLoaded ? 'Show Interstitial' : 'Load Interstitial',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: !_isRewardedLoaded ? _loadRewardedAd : _showRewardedAd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: _isRewardedLoaded ? Colors.green : Colors.grey,
                  ),
                  child: Text(
                    _isRewardedLoaded ? 'Show Rewarded' : 'Load Rewarded',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

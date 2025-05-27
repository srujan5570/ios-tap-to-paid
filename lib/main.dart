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
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  int _coins = 0;
  bool _isInitialized = false;
  String _ipAddress = '';
  String _country = '';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initUnityAds();
    _fetchIPLocation();
  }

  Future<void> _fetchIPLocation() async {
    try {
      setState(() => _isLoadingLocation = true);
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ipAddress = data['ip'] ?? 'Unknown';
          _country = data['country_name'] ?? 'Unknown';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _ipAddress = 'Error';
          _country = 'Error';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _ipAddress = 'Error';
        _country = 'Error';
        _isLoadingLocation = false;
      });
      print('Error fetching IP location: $e');
    }
  }

  Future<void> _initUnityAds() async {
    setState(() => _isInitialized = false);
    await UnityAds.init(
      gameId: '5859176',
      testMode: false,
      onComplete: () {
        setState(() => _isInitialized = true);
        print('Unity Ads Initialization Complete');
      },
      onFailed: (error, message) {
        setState(() => _isInitialized = false);
        print('Unity Ads Initialization Failed: $message');
      },
    );
  }

  void _loadInterstitialAd() {
    if (!_isInitialized || _isInterstitialLoading) return;

    setState(() => _isInterstitialLoading = true);
    UnityAds.load(
      placementId: 'Interstitial_iOS',
      onComplete: (placementId) {
        setState(() {
          _isInterstitialLoaded = true;
          _isInterstitialLoading = false;
        });
        print('Interstitial Ad Loaded');
      },
      onFailed: (placementId, error, message) {
        setState(() {
          _isInterstitialLoaded = false;
          _isInterstitialLoading = false;
        });
        print('Interstitial Load Failed: $message');
      },
    );
  }

  Future<void> _showInterstitialAd() async {
    if (!_isInterstitialLoaded) return;

    UnityAds.showVideoAd(
      placementId: 'Interstitial_iOS',
      onComplete: (placementId) async {
        setState(() => _isInterstitialLoaded = false);
        print('Interstitial Ad Completed');
        // Reset SDK after ad completion
        await _initUnityAds();
      },
      onFailed: (placementId, error, message) {
        setState(() => _isInterstitialLoaded = false);
        print('Interstitial Show Failed: $message');
      },
      onStart: (placementId) => print('Interstitial Ad Started'),
      onClick: (placementId) => print('Interstitial Ad Clicked'),
    );
  }

  void _loadRewardedAd() {
    if (!_isInitialized || _isRewardedLoading) return;

    setState(() => _isRewardedLoading = true);
    UnityAds.load(
      placementId: 'Rewarded_iOS',
      onComplete: (placementId) {
        setState(() {
          _isRewardedLoaded = true;
          _isRewardedLoading = false;
        });
        print('Rewarded Ad Loaded');
      },
      onFailed: (placementId, error, message) {
        setState(() {
          _isRewardedLoaded = false;
          _isRewardedLoading = false;
        });
        print('Rewarded Load Failed: $message');
      },
    );
  }

  Future<void> _showRewardedAd() async {
    if (!_isRewardedLoaded) return;

    UnityAds.showVideoAd(
      placementId: 'Rewarded_iOS',
      onComplete: (placementId) async {
        setState(() {
          _isRewardedLoaded = false;
          _coins += 10;
        });
        print('Rewarded Ad Completed');
        // Reset SDK after ad completion
        await _initUnityAds();
      },
      onFailed: (placementId, error, message) {
        setState(() => _isRewardedLoaded = false);
        print('Rewarded Show Failed: $message');
      },
      onStart: (placementId) => print('Rewarded Ad Started'),
      onClick: (placementId) => print('Rewarded Ad Clicked'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unity Ads Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _isLoadingLocation
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Coins: $_coins',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 30),
                  if (!_isInitialized)
                    const Text(
                      'Initializing Unity Ads...',
                      style: TextStyle(color: Colors.grey),
                    )
                  else ...[
                    ElevatedButton(
                      onPressed: _isInterstitialLoading || _isInterstitialLoaded
                          ? null
                          : _loadInterstitialAd,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: _isInterstitialLoaded ? Colors.blue : Colors.grey,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        _isInterstitialLoading
                            ? 'Loading Interstitial Ad...'
                            : _isInterstitialLoaded
                                ? 'Show Interstitial Ad'
                                : 'Load Interstitial Ad',
                        style: TextStyle(
                          fontSize: 18,
                          color: _isInterstitialLoaded ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isRewardedLoading || _isRewardedLoaded
                          ? null
                          : _loadRewardedAd,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: _isRewardedLoaded ? Colors.blue : Colors.grey,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        _isRewardedLoading
                            ? 'Loading Rewarded Ad...'
                            : _isRewardedLoaded
                                ? 'Show Rewarded Ad'
                                : 'Load Rewarded Ad',
                        style: TextStyle(
                          fontSize: 18,
                          color: _isRewardedLoaded ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

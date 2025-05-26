import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

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

  @override
  void initState() {
    super.initState();
    _initUnityAds();
  }

  Future<void> _initUnityAds() async {
    await UnityAds.init(
      gameId: '5859176',
      testMode: false,
      onComplete: () {
        print('Initialization Complete');
        _loadInterstitialAd();
        _loadRewardedAd();
      },
      onFailed: (error, message) => print('Initialization Failed: $message'),
    );
  }

  void _loadInterstitialAd() {
    UnityAds.load(
      placementId: 'Interstitial_iOS',
      onComplete: (placementId) {
        setState(() => _isInterstitialLoaded = true);
        print('Interstitial Ad Loaded');
      },
      onFailed: (placementId, error, message) {
        print('Interstitial Load Failed: $message');
        setState(() => _isInterstitialLoaded = false);
      },
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialLoaded) {
      UnityAds.showVideoAd(
        placementId: 'Interstitial_iOS',
        onComplete: (placementId) {
          setState(() => _isInterstitialLoaded = false);
          _loadInterstitialAd();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() => _isInterstitialLoaded = false);
          _loadInterstitialAd();
        },
        onStart: (placementId) => print('Ad Started'),
        onClick: (placementId) => print('Ad Clicked'),
      );
    }
  }

  void _loadRewardedAd() {
    UnityAds.load(
      placementId: 'Rewarded_iOS',
      onComplete: (placementId) {
        setState(() => _isRewardedLoaded = true);
        print('Rewarded Ad Loaded');
      },
      onFailed: (placementId, error, message) {
        print('Rewarded Load Failed: $message');
        setState(() => _isRewardedLoaded = false);
      },
    );
  }

  void _showRewardedAd() {
    if (_isRewardedLoaded) {
      UnityAds.showVideoAd(
        placementId: 'Rewarded_iOS',
        onComplete: (placementId) {
          setState(() {
            _isRewardedLoaded = false;
            _coins += 10;
          });
          _loadRewardedAd();
        },
        onFailed: (placementId, error, message) {
          print('Show Failed: $message');
          setState(() => _isRewardedLoaded = false);
          _loadRewardedAd();
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
            Text(
              'Coins: $_coins',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isInterstitialLoaded ? _showInterstitialAd : _loadInterstitialAd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isInterstitialLoaded ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isInterstitialLoaded ? 'Show Interstitial Ad' : 'Load Interstitial Ad',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRewardedLoaded ? _showRewardedAd : _loadRewardedAd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: _isRewardedLoaded ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
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

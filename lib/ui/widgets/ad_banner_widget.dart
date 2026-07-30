import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';

/// Map-screen banner ad (Goods Puzzle style bottom strip).
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(context.read<AdService>());
  }

  Future<void> _load(AdService ads) async {
    if (!ads.bannerEnabled) return;
    final banner = await ads.createBanner();
    if (!mounted || banner == null) return;
    await banner.load();
    if (!mounted) {
      banner.dispose();
      return;
    }
    setState(() {
      _ad = banner;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final removeAds = context.watch<ProgressProvider>().progress.removeAds;
    if (removeAds || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

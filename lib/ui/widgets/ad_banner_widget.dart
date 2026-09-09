import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';

/// One on-screen banner placement. Collapses on no-fill / offline / remove-ads.
class AdBannerWidget extends StatefulWidget {
  final String placement;

  const AdBannerWidget({
    super.key,
    this.placement = 'home',
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  AdService? _ads;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ads = context.read<AdService>();
    if (!identical(_ads, ads)) {
      _ads?.removeListener(_onAdsChanged);
      _ads = ads;
      _ads!.addListener(_onAdsChanged);
      _tryLoad();
    }
  }

  void _onAdsChanged() {
    if (!mounted) return;
    final ads = _ads;
    if (ads == null) return;
    if (!ads.adsUiEnabled || !ads.bannerEnabled) {
      _disposeAd();
      setState(() {});
      return;
    }
    if (_ad == null && !_loading) {
      _tryLoad();
    }
  }

  Future<void> _tryLoad() async {
    final ads = _ads;
    if (ads == null || _loading || _ad != null) return;
    if (!ads.adsUiEnabled || !ads.bannerEnabled) return;

    final removeAds = context.read<ProgressProvider>().progress.removeAds;
    if (removeAds) return;

    _loading = true;
    final ad = await ads.loadBanner(placement: widget.placement);
    if (!mounted) {
      ad?.dispose();
      _loading = false;
      return;
    }
    _loading = false;
    if (ad == null) {
      setState(() {
        _loaded = false;
        _ad = null;
      });
      return;
    }
    setState(() {
      _ad = ad;
      _loaded = true;
    });
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _ads?.removeListener(_onAdsChanged);
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final removeAds = context.watch<ProgressProvider>().progress.removeAds;
    final ads = context.watch<AdService>();
    final ad = _ad;
    if (removeAds || !ads.adsUiEnabled || !_loaded || ad == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

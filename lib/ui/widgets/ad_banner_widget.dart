import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';

/// Map-screen banner ad (Goods Puzzle style bottom strip).
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late final _AdBannerCubit _bannerCubit;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bannerCubit = _AdBannerCubit();
  }

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
    _bannerCubit.show(banner);
  }

  @override
  void dispose() {
    _bannerCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bannerCubit,
      child: BlocBuilder<_AdBannerCubit, BannerAd?>(
        builder: (context, ad) {
          final removeAds = context.watch<ProgressProvider>().progress.removeAds;
          if (removeAds || ad == null) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          );
        },
      ),
    );
  }
}

class _AdBannerCubit extends Cubit<BannerAd?> {
  _AdBannerCubit() : super(null);

  void show(BannerAd ad) {
    state?.dispose();
    emit(ad);
  }

  @override
  Future<void> close() {
    state?.dispose();
    return super.close();
  }
}

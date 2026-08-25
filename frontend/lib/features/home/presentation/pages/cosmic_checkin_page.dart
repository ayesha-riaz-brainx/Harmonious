import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/astrology/cosmic_checkin.dart';
import 'package:slot_1_tasks/core/astrology/zodiac_sign.dart';
import 'package:slot_1_tasks/core/services/cosmic_checkin_service.dart';
import 'package:slot_1_tasks/core/services/profile_service.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/cosmic_checkin_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class CosmicCheckInPage extends StatefulWidget {
  const CosmicCheckInPage({super.key});

  @override
  State<CosmicCheckInPage> createState() => _CosmicCheckInPageState();
}

class _CosmicCheckInPageState extends State<CosmicCheckInPage> {
  final _cosmic = CosmicCheckInService();
  final _profiles = ProfileService();

  CosmicCheckIn? _checkIn;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _profiles.fetchCurrentProfile();
      final sign = ZodiacSign.fromId(profile?.zodiacSign) ??
          (profile?.birthday != null
              ? ZodiacSign.fromBirthday(profile!.birthday!)
              : null);
      final checkIn = await _cosmic.forSign(sign);
      if (!mounted) return;
      setState(() {
        _checkIn = checkIn;
        _loading = false;
        if (checkIn == null) {
          _error =
              'Set your birthday or zodiac sign in profile setup to unlock today’s cosmic check-in.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Cosmic check-in'),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    HarmoniousSpacing.screenHorizontal,
                    8,
                    HarmoniousSpacing.screenHorizontal,
                    32,
                  ),
                  children: [
                    if (_checkIn != null)
                      CosmicCheckInCard(checkIn: _checkIn!)
                    else
                      HarmoniousCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error ?? 'Cosmic check-in unavailable.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.45),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

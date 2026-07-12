import 'dart:async';



import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';



import '../../../../core/config/app_config.dart';

import '../../../../core/qr/qr_token_service.dart';

import '../../../../core/storage/secure_storage.dart';

import '../../../../l10n/app_localizations.dart';



class QrPage extends StatefulWidget {

  const QrPage({super.key});



  @override

  State<QrPage> createState() => _QrPageState();

}



class _QrPageState extends State<QrPage> {

  static final _totalSeconds = AppConfig.qrValidityDuration.inSeconds;



  final _qrService = QrTokenService();

  final _secureStorage = SecureStorage();



  int _secondsLeft = _totalSeconds;

  Timer? _timer;

  String? _qrPayload;

  String? _error;



  @override

  void initState() {

    super.initState();

    _generateQr();

  }



  Future<void> _generateQr() async {

    _timer?.cancel();

    setState(() {

      _error = null;

      _secondsLeft = _totalSeconds;

    });



    final userId = await _secureStorage.getUserId();

    if (userId == null || userId.isEmpty) {

      if (!mounted) return;

      setState(() {

        _error = 'Сначала выполните вход';

        _qrPayload = null;

      });

      return;

    }



    final token = await _qrService.generateToken(

      userId: userId,

      ttlSeconds: _totalSeconds,

    );



    if (token == null) {

      if (!mounted) return;

      setState(() {

        _error = 'Нет deviceSecret — войдите заново';

        _qrPayload = null;

      });

      return;

    }



    if (!mounted) return;

    setState(() => _qrPayload = token);



    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {

      if (_secondsLeft <= 1) {

        _generateQr();

      } else {

        setState(() => _secondsLeft--);

      }

    });

  }



  @override

  void dispose() {

    _timer?.cancel();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;



    return Scaffold(

      appBar: AppBar(title: Text(l10n.qrCode)),

      body: Center(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              if (_qrPayload != null)

                QrImageView(

                  data: _qrPayload!,

                  version: QrVersions.auto,

                  size: 220,

                )

              else

                const CircularProgressIndicator(),

              const SizedBox(height: 24),

              Text(

                l10n.qrExpiresIn(_secondsLeft),

                style: Theme.of(context).textTheme.titleMedium,

              ),

              if (_error != null) ...[

                const SizedBox(height: 8),

                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),

              ],

              const SizedBox(height: 16),

              FilledButton.icon(

                onPressed: _generateQr,

                icon: const Icon(Icons.refresh),

                label: Text(l10n.refreshQr),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



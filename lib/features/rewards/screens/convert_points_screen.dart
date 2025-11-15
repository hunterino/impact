import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/rewards_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';

class ConvertPointsScreen extends StatefulWidget {
  const ConvertPointsScreen({super.key});

  @override
  State<ConvertPointsScreen> createState() => _ConvertPointsScreenState();
}

class _ConvertPointsScreenState extends State<ConvertPointsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  double _servDRAmount = 0.0;
  bool _isConverting = false;
  String? _errorMessage;
  bool _conversionComplete = false;

  // Conversion rate
  static const double _conversionRate = 0.01; // 100 points = 1 SERV DR
  static const int _minConversion = 1000; // Minimum 1000 points

  @override
  void initState() {
    super.initState();
    _pointsController.addListener(_updateServDRAmount);
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  void _updateServDRAmount() {
    setState(() {
      final pointsText = _pointsController.text.trim();
      final points = int.tryParse(pointsText) ?? 0;
      _servDRAmount = points * _conversionRate;
    });
  }

  Future<void> _convertPoints() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConverting = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);

      if (authProvider.user == null) {
        throw Exception('User not authenticated');
      }

      final pointsText = _pointsController.text.trim();
      final points = int.parse(pointsText);

      final success = await rewardsProvider.convertPointsToServDR(
        authProvider.user!.id,
        points,
      );

      if (success) {
        setState(() {
          _isConverting = false;
          _conversionComplete = true;
        });
      } else {
        setState(() {
          _isConverting = false;
          _errorMessage = rewardsProvider.errorMessage ?? 'Conversion failed';
        });
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convert Points'),
      ),
      body: Consumer<RewardsProvider>(
        builder: (context, rewardsProvider, child) {
          final wallet = rewardsProvider.wallet;

          if (wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_conversionComplete) {
            return _buildSuccessScreen();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDarkColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryDarkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${wallet.stbfPointsBalance} Points',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withAlpha(7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.infoColor,
                        width: 1,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About SERV DR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.infoColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SERV Digital Rewards (SERV DR) are stored on the STBF blockchain and can be redeemed for exclusive rewards from our partners. Once converted, points cannot be converted back.',
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Conversion rate: 100 Points = 1 SERV DR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Minimum conversion: 1,000 Points',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withAlpha(7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),

                  // Conversion form
                  const Text(
                    'Points to Convert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _pointsController,
                    decoration: const InputDecoration(
                      hintText: 'Enter points amount',
                      suffixText: 'Points',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter points amount';
                      }

                      final points = int.tryParse(value);
                      if (points == null) {
                        return 'Please enter a valid number';
                      }

                      if (points < _minConversion) {
                        return 'Minimum conversion is $_minConversion points';
                      }

                      if (points > wallet.stbfPointsBalance) {
                        return 'You don\'t have enough points';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // SERV DR amount
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'You will receive',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryDarkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_servDRAmount.toStringAsFixed(2)} SERV DR',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Convert Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConverting ? null : _convertPoints,
                      child: _isConverting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Convert Points'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Conversion Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You have successfully converted ${_pointsController.text} Points to ${_servDRAmount.toStringAsFixed(2)} SERV DR',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'The SERV DR tokens have been added to your wallet and can be used to redeem rewards in the marketplace.',
              style: TextStyle(
                color: AppTheme.textSecondaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RewardDetailScreen extends StatelessWidget {
  final String? rewardId;

  const RewardDetailScreen({super.key, this.rewardId});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('RewardDetailScreen'),
      ),
      body: Center(
        child: Text('RewardDetailScreen'),
      ),
    );
  }
}

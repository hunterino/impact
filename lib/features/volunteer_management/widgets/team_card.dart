import 'package:flutter/material.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/team_model.dart';

class TeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback onTap;
  
  const TeamCard({
    Key? key,
    required this.team,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team Image
              CircleAvatar(
                radius: 32,
                backgroundImage: team.imageUrl != null
                    ? NetworkImage(team.imageUrl!)
                    : null,
                backgroundColor: AppTheme.primaryColor,
                child: team.imageUrl == null
                    ? Text(
                        team.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (team.description != null)
                      Text(
                        team.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryDarkColor,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStat(
                          Icons.people,
                          '${team.memberCount} members',
                          AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          Icons.timer,
                          '${team.totalServiceHours} hours',
                          AppTheme.secondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryDarkColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

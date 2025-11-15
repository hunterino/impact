import 'package:flutter/material.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/team_member_model.dart';

class TeamMemberTile extends StatelessWidget {
  final TeamMemberModel member;
  final bool isLeader;
  
  const TeamMemberTile({
    Key? key,
    required this.member,
    this.isLeader = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Note: In a real implementation, you would need to fetch the user details
    // This is a simplified version showing the structure
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isLeader ? AppTheme.primaryColor : Colors.grey[800],
        child: const Icon(
          Icons.person,
          color: Colors.white,
        ),
      ),
      title: Row(
        children: [
          const Text('Member Name'), // This would come from user details
          if (isLeader)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Leader',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text('${member.contributedHours} hours • ${member.contributedPoints} points'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          // TODO: Implement actions
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'message',
            child: Text('Message'),
          ),
          const PopupMenuItem(
            value: 'profile',
            child: Text('View Profile'),
          ),
        ],
      ),
    );
  }
}

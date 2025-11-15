import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/volunteer_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/team_model.dart';
import 'package:serve_to_be_free/features/volunteer_management/widgets/team_member_tile.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  
  const TeamDetailScreen({
    Key? key,
    required this.teamId,
  }) : super(key: key);

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }
  
  Future<void> _loadTeamDetails() async {
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    await volunteerProvider.fetchTeamDetails(widget.teamId);
  }
  
  Future<void> _refreshData() async {
    await _loadTeamDetails();
  }
  
  Future<void> _leaveTeam() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
              
              if (authProvider.user != null) {
                try {
                  final success = await volunteerProvider.leaveTeam(
                    authProvider.user!.id,
                    widget.teamId,
                  );
                  
                  if (success) {
                    Navigator.of(context).pop(); // Go back to teams list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to leave team'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
  
  void _inviteMembers() {
    // TODO: Implement invite members functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite functionality coming soon'),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<VolunteerProvider>(
      builder: (context, volunteerProvider, child) {
        final team = volunteerProvider.currentTeam;
        final members = volunteerProvider.teamMembers;
        final isLoading = volunteerProvider.isLoading;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(team?.name ?? 'Team Details'),
            actions: [
              if (team != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'leave') {
                      _leaveTeam();
                    } else if (value == 'invite') {
                      _inviteMembers();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'invite',
                      child: Text('Invite Members'),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave Team'),
                    ),
                  ],
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : team == null
                  ? const Center(child: Text('Team not found'))
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Team Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Team Image
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: team.imageUrl != null
                                    ? NetworkImage(team.imageUrl!)
                                    : null,
                                backgroundColor: AppTheme.primaryColor,
                                child: team.imageUrl == null
                                    ? Text(
                                        team.name.substring(0, 1),
                                        style: const TextStyle(
                                          fontSize: 30,
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
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created ${DateFormat.yMMMd().format(team.createdAt)}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryDarkColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (team.description != null && team.description!.isNotEmpty)
                                      Text(team.description!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Team Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Members',
                                  team.memberCount.toString(),
                                  Icons.people,
                                  AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Hours',
                                  team.totalServiceHours.toString(),
                                  Icons.access_time,
                                  AppTheme.secondaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Points',
                                  team.totalPoints.toString(),
                                  Icons.star,
                                  AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Focus Areas
                          if (team.focusAreas != null && team.focusAreas!.isNotEmpty) ...[
                            const Text(
                              'Focus Areas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: team.focusAreas!.map((area) => Chip(
                                label: Text(area),
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Members List
                          const Text(
                            'Team Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (members.isEmpty)
                            const Center(
                              child: Text('No members found'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final isLeader = member.role == 'leader';
                                
                                return TeamMemberTile(
                                  member: member,
                                  isLeader: isLeader,
                                );
                              },
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Invite Button
                          OutlinedButton.icon(
                            onPressed: _inviteMembers,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Invite Members'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

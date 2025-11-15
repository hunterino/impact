import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/volunteer_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/widgets/team_card.dart';
import 'package:serve_to_be_free/features/volunteer_management/screens/team_detail_screen.dart';
import 'package:serve_to_be_free/features/volunteer_management/screens/create_team_screen.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({Key? key}) : super(key: key);

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    _loadTeams();
  }
  
  Future<void> _loadTeams() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await volunteerProvider.fetchUserTeams(authProvider.user!.id);
    }
  }
  
  Future<void> _refreshData() async {
    await _loadTeams();
  }
  
  void _navigateToTeamDetail(String teamId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamDetailScreen(teamId: teamId),
      ),
    );
  }
  
  void _navigateToCreateTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTeamScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
      ),
      body: Consumer<VolunteerProvider>(
        builder: (context, volunteerProvider, child) {
          if (volunteerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (volunteerProvider.userTeams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You haven\'t joined any teams yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateTeam,
                    icon: const Icon(Icons.add),
                    label: const Text('Create a Team'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: volunteerProvider.userTeams.length,
              itemBuilder: (context, index) {
                final team = volunteerProvider.userTeams[index];
                return TeamCard(
                  team: team,
                  onTap: () => _navigateToTeamDetail(team.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTeam,
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }
}

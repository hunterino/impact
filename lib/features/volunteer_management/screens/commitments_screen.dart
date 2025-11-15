import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/volunteer_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/widgets/commitment_card.dart';
import 'package:serve_to_be_free/features/volunteer_management/screens/log_hours_screen.dart';

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({Key? key}) : super(key: key);

  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await volunteerProvider.fetchUpcomingCommitments(authProvider.user!.id);
      await volunteerProvider.fetchPastCommitments(authProvider.user!.id);
    }
  }
  
  Future<void> _refreshData() async {
    await _loadData();
  }
  
  Future<void> _cancelCommitment(String commitmentId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      try {
        final success = await volunteerProvider.cancelCommitment(
          authProvider.user!.id,
          commitmentId,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commitment cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel commitment'),
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
  }
  
  void _navigateToLogHours(String projectId, String? slotId, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogHoursScreen(
          projectId: projectId,
          slotId: slotId,
          serviceDate: date,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Commitments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: Consumer<VolunteerProvider>(
        builder: (context, volunteerProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming Commitments Tab
              RefreshIndicator(
                onRefresh: _refreshData,
                child: volunteerProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : volunteerProvider.upcomingCommitments.isEmpty
                        ? const Center(
                            child: Text('No upcoming commitments found'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: volunteerProvider.upcomingCommitments.length,
                            itemBuilder: (context, index) {
                              final commitment = volunteerProvider.upcomingCommitments[index];
                              return CommitmentCard(
                                commitment: commitment,
                                onCancel: () => _cancelCommitment(commitment.id),
                              );
                            },
                          ),
              ),
              
              // Past Commitments Tab
              RefreshIndicator(
                onRefresh: _refreshData,
                child: volunteerProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : volunteerProvider.pastCommitments.isEmpty
                        ? const Center(
                            child: Text('No past commitments found'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: volunteerProvider.pastCommitments.length,
                            itemBuilder: (context, index) {
                              final commitment = volunteerProvider.pastCommitments[index];
                              return CommitmentCard(
                                commitment: commitment,
                                isPast: true,
                                onLogHours: () => _navigateToLogHours(
                                  commitment.projectId, 
                                  commitment.projectSlotId,
                                  commitment.commitmentDate,
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

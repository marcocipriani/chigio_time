import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../social/presentation/social_preview_widget.dart';
import '../widgets/smart_exit_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ciao, Marco 👋"), // Placeholder nome utente
            Text("Dipendente Pubblico", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text("MC")), // Avatar placeholder
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Widget 1: Orario Uscita 
          SmartExitWidget(),
          
          SizedBox(height: 16),
          
          // Qui andranno gli altri widget (Statistiche, Social, etc.)
          // Text("Widget Grid Area..."),
        ],
      ),
      // Bottom Navigation Bar placeholder per navigare tra Dashboard, Timesheet, Social
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Timesheet'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Social'),
        ],
      ),
    );
  }
}
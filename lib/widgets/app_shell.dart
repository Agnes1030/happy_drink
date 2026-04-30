import 'package:flutter/material.dart';

import '../screens/add_new_sip_screen.dart';
import '../screens/ai_insights_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/drink_history_screen.dart';
import '../screens/photo_parse_screen.dart';
import '../screens/trends_screen.dart';
import '../services/api_client.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.apiClient,
    required this.userId,
  });

  final ApiClient apiClient;
  final String userId;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _refreshSignal = 0;

  void _notifySaved() {
    setState(() {
      _refreshSignal++;
      _index = 0;
    });
  }

  Future<void> _openManualEntry(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddNewSipScreen(
          apiClient: widget.apiClient,
          userId: widget.userId,
          onSaved: _notifySaved,
        ),
      ),
    );
  }

  Future<void> _openPhotoParse(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoParseScreen(
          apiClient: widget.apiClient,
          userId: widget.userId,
          onSaved: _notifySaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        apiClient: widget.apiClient,
        userId: widget.userId,
        onOpenPhotoParse: () => _openPhotoParse(context),
        onOpenManualEntry: () => _openManualEntry(context),
        refreshSignal: _refreshSignal,
      ),
      DrinkHistoryScreen(apiClient: widget.apiClient, userId: widget.userId, refreshSignal: _refreshSignal),
      TrendsScreen(apiClient: widget.apiClient, userId: widget.userId, refreshSignal: _refreshSignal),
      AiInsightsScreen(apiClient: widget.apiClient, userId: widget.userId),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '记录'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '趋势'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'AI'),
        ],
      ),
    );
  }
}

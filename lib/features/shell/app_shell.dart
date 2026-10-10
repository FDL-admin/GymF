import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/workout_session.dart';
import '../../theme/colors.dart';
import '../session/session_providers.dart';
import '../session/session_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_providers.dart';
import '../settings/settings_screen.dart';
import '../tracking/tracking_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _stalePromptShown = false;

  static const List<String> _titles = [
    'Accueil',
    'Bibliothèque',
    'Historique',
    'Suivi',
    'Réglages',
  ];

  static const List<Widget> _screens = [
    HomeScreen(),
    LibraryScreen(),
    HistoryScreen(),
    TrackingScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncReminders();
  }

  Future<void> _syncReminders() async {
    try {
      await ref.read(reminderCoordinatorProvider).resynchronize();
    } catch (_) {
      // Les rappels seront resynchronisés au prochain lancement.
    }
  }

  void _openSession(BuildContext context, WorkoutSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionScreen(sessionId: session.id)),
    );
  }

  Future<void> _promptStaleSession(
    BuildContext context,
    WorkoutSession session,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Séance en cours suspendue'),
        content: Text(
          'La séance « ${session.name} » a commencé il y a plus de 24 h. '
          'Souhaites-tu la reprendre ou l\'abandonner ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('abandon'),
            child: const Text('Abandonner'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('reprendre'),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'reprendre') {
      if (!context.mounted) return;
      _openSession(context, session);
    } else {
      await ref.read(sessionRepositoryProvider).abandon(session.id);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance abandonnée.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<WorkoutSession?>>(
      inProgressSessionProvider,
      (previous, next) {
        final session = next.value;
        if (session == null || session.startedAt.isEmpty) return;
        if (_stalePromptShown) return;
        final started = DateTime.parse(session.startedAt);
        final isStale =
            DateTime.now().difference(started).inHours > 24;
        if (!isStale) return;
        _stalePromptShown = true;
        final currentContext = context;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentContext.mounted) {
            _promptStaleSession(currentContext, session);
          }
        });
      },
    );

    final inProgress = ref.watch(inProgressSessionProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inProgress != null)
            _SessionBanner(
              session: inProgress,
              onTap: () => _openSession(context, inProgress),
            ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Bibliothèque',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Historique',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart_outlined),
                activeIcon: Icon(Icons.show_chart),
                label: 'Suivi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Réglages',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionBanner extends StatelessWidget {
  const _SessionBanner({required this.session, required this.onTap});

  final WorkoutSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Séance en cours : ${session.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Reprendre',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
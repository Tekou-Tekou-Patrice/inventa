import 'dart:async';

import 'package:flutter/material.dart';

import 'data/offline_operation_store.dart';
import 'data/plantation_api.dart';
import 'data/push_notifications.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/auth/director_registration_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/fields/fields_screen.dart';
import 'features/payroll/payroll_screen.dart';
import 'features/report/field_report_screen.dart';
import 'features/stock/stock_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/workers/workers_screen.dart';
import 'features/shared/widgets.dart';
import 'models/plantation_models.dart';
import 'state/plantation_state.dart';
import 'state/role_permissions.dart';
import 'theme/app_theme.dart';

class InventaApp extends StatelessWidget {
  const InventaApp({
    this.demoMode = false,
    this.api,
    this.offlineStoreFactory,
    this.networkAvailable,
    super.key,
  });

  final bool demoMode;
  final PlantationApi? api;
  final Future<OfflineOperationStore> Function()? offlineStoreFactory;
  final Future<bool> Function()? networkAvailable;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Inventa',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: _InventaHome(
      demoMode: demoMode,
      api: api,
      offlineStoreFactory: offlineStoreFactory,
      networkAvailable: networkAvailable,
    ),
  );
}

class _InventaHome extends StatefulWidget {
  const _InventaHome({
    required this.demoMode,
    this.api,
    this.offlineStoreFactory,
    this.networkAvailable,
  });

  final bool demoMode;
  final PlantationApi? api;
  final Future<OfflineOperationStore> Function()? offlineStoreFactory;
  final Future<bool> Function()? networkAvailable;

  @override
  State<_InventaHome> createState() => _InventaHomeState();
}

class _InventaHomeState extends State<_InventaHome> {
  late PlantationApi _api;
  PlantationState? _connectedState;
  PlantationState get _state => _connectedState!;
  AppSection _section = AppSection.dashboard;
  bool _showDirectorRegistration = false;
  bool _sessionInitialized = false;
  bool _restoringSession = false;
  String? _sessionRestoreError;

  List<AppSection> get _visibleSections => AppSection.values
      .where(RolePermissions.visibleSections(_state.role).contains)
      .toList();

  List<AppSection> get _mobileSections {
    final visible = _visibleSections;
    if (_state.role == UserRole.fieldManager) {
      return [
        AppSection.dashboard,
        AppSection.attendance,
        AppSection.workers,
        AppSection.stock,
      ].where(visible.contains).toList();
    }
    return visible.take(4).toList();
  }

  bool get _hasMoreMobileSections => _visibleSections.length > 4;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PlantationApi();
    if (widget.demoMode) {
      _connectedState = PlantationState();
      _sessionInitialized = true;
    } else {
      unawaited(_restoreSession());
    }
  }

  @override
  void dispose() {
    _connectedState?.dispose();
    unawaited(_api.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connectedState == null) {
      if (!_sessionInitialized) {
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restauration de votre session…'),
              ],
            ),
          ),
        );
      }
      if (_showDirectorRegistration) {
        return DirectorRegistrationScreen(
          onBack: () => setState(() => _showDirectorRegistration = false),
          onRegister: _registerDirector,
        );
      }
      return LoginScreen(
        onLogin: _login,
        canRegisterDirector: _api.canRegisterDirector,
        onOpenRegistration: () =>
            setState(() => _showDirectorRegistration = true),
        sessionRestoreError: _sessionRestoreError,
        onRetrySessionRestore: _restoreSession,
      );
    }
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 880;
          final isCompact = constraints.maxWidth < 520;
          return Scaffold(
            appBar: _buildAppBar(context, isWide, isCompact),
            body: isWide
                ? Row(
                    children: [
                      _DesktopNavigation(
                        selected: _section,
                        onSelected: _selectSection,
                        demoMode: widget.demoMode,
                        sections: _visibleSections,
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildCurrentScreen()),
                    ],
                  )
                : _buildCurrentScreen(),
            bottomNavigationBar: isWide
                ? null
                : NavigationBar(
                    selectedIndex: _mobileIndex,
                    onDestinationSelected: (index) {
                      if (_hasMoreMobileSections &&
                          index == _mobileSections.length) {
                        _showSections(context);
                      } else {
                        _selectSection(_mobileSections[index]);
                      }
                    },
                    destinations: [
                      for (final section in _mobileSections)
                        NavigationDestination(
                          icon: Icon(_sectionIcon(section)),
                          selectedIcon: Icon(_sectionIcon(section)),
                          label: section.shortLabel,
                        ),
                      if (_hasMoreMobileSections)
                        const NavigationDestination(
                          icon: Icon(Icons.grid_view_outlined),
                          selectedIcon: Icon(Icons.grid_view),
                          label: 'Plus',
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _login(String username, String password) async {
    final identity = await _api.login(username, password);
    await _connect(identity);
  }

  Future<void> _restoreSession() async {
    if (_restoringSession) return;
    _restoringSession = true;
    if (mounted) {
      setState(() {
        _sessionRestoreError = null;
        _sessionInitialized = false;
      });
    }
    try {
      final identity = await _api.restoreSession();
      if (identity != null) await _connect(identity);
    } on Exception catch (error) {
      _api.clearAuthorization();
      if (mounted) {
        setState(() {
          _sessionRestoreError = error is ApiException
              ? error.message
              : 'Impossible de restaurer la session. Vérifiez le réseau puis réessayez.';
        });
      }
    } finally {
      _restoringSession = false;
      if (mounted) setState(() => _sessionInitialized = true);
    }
  }

  Future<void> _connect(Map<String, dynamic> identity) async {
    final role = UserRole.fromApi(identity['role']);
    final fieldId = identity['fieldId']?.toString();
    if (role == UserRole.fieldManager && (fieldId == null || fieldId.isEmpty)) {
      await _api.clearSession();
      throw const ApiException(
        'Ce compte responsable de terrain n’est rattaché à aucun champ. '
        'Demandez au directeur de corriger son affectation.',
      );
    }

    final state = PlantationState(
      api: _api,
      seedDemoData: false,
      offlineStoreFactory: widget.offlineStoreFactory,
      networkAvailable: widget.networkAvailable,
    );
    state.setRole(role);
    state.setAssignedFieldId(fieldId);
    state.setAccountId(_api.authenticatedUsername);
    try {
      await state.refresh();
    } on Exception {
      state.dispose();
      _api.clearAuthorization();
      rethrow;
    }
    if (!mounted) {
      state.dispose();
      return;
    }
    setState(() {
      _connectedState = state;
      _section = AppSection.dashboard;
      _showDirectorRegistration = false;
    });
    try {
      await PushNotifications.registerDevice(_api);
    } on Exception catch (error) {
      debugPrint('Push notification registration failed: $error');
    }
  }

  Future<void> _registerDirector({
    required String username,
    required String password,
    required String phoneNumber,
  }) async {
    await _api.registerDirector(
      username: username,
      password: password,
      phoneNumber: phoneNumber,
    );
    await _login(username, password);
  }

  Future<void> _logout() async {
    final state = _connectedState;
    state?.dispose();
    try {
      await PushNotifications.unregisterDevice(_api);
    } on Exception catch (error) {
      debugPrint('Push notification removal failed during logout: $error');
    }
    await _api.clearSession();
    setState(() {
      _connectedState = null;
      _section = AppSection.dashboard;
    });
  }

  int get _mobileIndex {
    final index = _mobileSections.indexOf(_section);
    return index < 0 ? _mobileSections.length : index;
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isWide,
    bool isCompact,
  ) => AppBar(
    titleSpacing: isWide ? 24 : 18,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 28 : 34,
          height: isCompact ? 28 : 34,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.eco_outlined,
            color: Colors.white,
            size: isCompact ? 18 : 21,
          ),
        ),
        SizedBox(width: isCompact ? 7 : 10),
        Flexible(
          child: Text(
            'inventa',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.forest,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
        ),
        if (isWide) ...[
          const SizedBox(width: 12),
          const Text(
            'GESTION DE PLANTATION',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ],
    ),
    actions: [
      if (!isWide)
        IconButton(
          tooltip: 'Toutes les rubriques',
          onPressed: () => _showSections(context),
          icon: const Icon(Icons.grid_view_outlined),
        ),
      if (widget.demoMode)
        PopupMenuButton<UserRole>(
          tooltip: 'Changer de profil',
          onSelected: _changeRole,
          itemBuilder: (context) => [
            for (final role in UserRole.values)
              PopupMenuItem(
                value: role,
                child: Row(
                  children: [
                    Icon(
                      _roleIcon(role),
                      color: role == _state.role
                          ? AppColors.forest
                          : AppColors.muted,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.demoMode)
                      IconButton(
                        tooltip: 'Se déconnecter',
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                      ),
                  ],
                ),
              ),
          ],
          child: isCompact
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.paleGreen,
                    child: Icon(
                      _roleIcon(_state.role),
                      size: 18,
                      color: AppColors.forest,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Chip(
                    avatar: Icon(
                      _roleIcon(_state.role),
                      size: 17,
                      color: AppColors.forest,
                    ),
                    label: Text(_state.role.shortLabel),
                    backgroundColor: AppColors.paleGreen,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
        ),
      if (_state.role != UserRole.fieldManager)
        PopupMenuButton<String>(
          tooltip: 'Choisir un champ',
          onSelected: (value) =>
              _state.selectField(value == '*' ? null : value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: '*',
              child: Text(
                'Tous les champs',
                style: TextStyle(
                  fontWeight: _state.selectedFieldId == null
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ),
            for (final field in _state.fields)
              PopupMenuItem(
                value: field.id,
                child: Text(
                  field.name,
                  style: TextStyle(
                    fontWeight: _state.selectedFieldId == field.id
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
          child: isCompact
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.landscape_outlined),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Chip(
                    avatar: const Icon(
                      Icons.landscape_outlined,
                      size: 17,
                      color: AppColors.forest,
                    ),
                    label: Text(
                      _state.fields
                              .where(
                                (field) => field.id == _state.selectedFieldId,
                              )
                              .firstOrNull
                              ?.name ??
                          'Tous les champs',
                    ),
                    backgroundColor: AppColors.paleGreen,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
        ),
      if (!widget.demoMode)
        IconButton(
          tooltip: 'Se déconnecter',
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
      const SizedBox(width: 8),
    ],
  );

  Widget _buildCurrentScreen() => SingleChildScrollView(
    child: switch (RolePermissions.visibleSections(
          _state.role,
        ).contains(_section)
        ? _section
        : AppSection.dashboard) {
      AppSection.dashboard => DashboardScreen(
        state: _state,
        onNavigate: _selectSection,
      ),
      AppSection.fields => FieldsScreen(state: _state),
      AppSection.attendance => AttendanceScreen(state: _state),
      AppSection.workers => WorkersScreen(state: _state),
      AppSection.accounts => AccountsScreen(state: _state),
      AppSection.tasks => TasksScreen(state: _state),
      AppSection.report => FieldReportScreen(state: _state),
      AppSection.stock => StockScreen(state: _state),
      AppSection.expenses => ExpensesScreen(state: _state),
      AppSection.payroll => PayrollScreen(state: _state),
    },
  );

  void _selectSection(AppSection section) {
    if (!RolePermissions.visibleSections(_state.role).contains(section)) return;
    if (_section != section) setState(() => _section = section);
    unawaited(_refreshCurrentData());
  }

  Future<void> _refreshCurrentData() async {
    await runApiAction(context, _state.refresh);
  }

  void _changeRole(UserRole role) {
    _state.setRole(role);
    if (!RolePermissions.visibleSections(role).contains(_section)) {
      setState(() => _section = AppSection.dashboard);
    }
  }

  Future<void> _showSections(BuildContext context) async {
    final visibleSections = _visibleSections;
    final selected = await showModalBottomSheet<AppSection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    'Toutes les rubriques',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final section in visibleSections)
                  ListTile(
                    leading: Icon(
                      _sectionIcon(section),
                      color: _section == section
                          ? AppColors.forest
                          : AppColors.muted,
                    ),
                    title: Text(section.label),
                    selected: _section == section,
                    onTap: () => Navigator.pop(context, section),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) _selectSection(selected);
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selected,
    required this.onSelected,
    required this.demoMode,
    required this.sections,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;
  final bool demoMode;
  final List<AppSection> sections;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              'MENU PRINCIPAL',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                selected: selected == section,
                selectedColor: AppColors.forest,
                selectedTileColor: AppColors.paleGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(_sectionIcon(section), size: 20),
                title: Text(
                  section.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => onSelected(section),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _ConnectionHint(demoMode: demoMode),
          ),
        ],
      ),
    ),
  );
}

class _ConnectionHint extends StatelessWidget {
  const _ConnectionHint({required this.demoMode});

  final bool demoMode;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(
          demoMode ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
          size: 18,
          color: AppColors.muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            demoMode
                ? 'Données locales de démonstration'
                : 'Connecté à Inventa',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

IconData _roleIcon(UserRole role) => switch (role) {
  UserRole.director => Icons.admin_panel_settings_outlined,
  UserRole.assistant => Icons.shopping_bag_outlined,
  UserRole.fieldManager => Icons.agriculture_outlined,
};

IconData _sectionIcon(AppSection section) => switch (section) {
  AppSection.dashboard => Icons.space_dashboard_outlined,
  AppSection.fields => Icons.landscape_outlined,
  AppSection.attendance => Icons.fact_check_outlined,
  AppSection.workers => Icons.groups_outlined,
  AppSection.accounts => Icons.manage_accounts_outlined,
  AppSection.tasks => Icons.assignment_outlined,
  AppSection.report => Icons.summarize_outlined,
  AppSection.stock => Icons.inventory_2_outlined,
  AppSection.expenses => Icons.receipt_long_outlined,
  AppSection.payroll => Icons.payments_outlined,
};

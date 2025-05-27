import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/presentation/pages/asesor/asesor_profile_screen.dart';
import 'package:rescatadores_app/presentation/pages/asesor/crear_alumno_screen.dart';
import 'package:rescatadores_app/presentation/pages/asesor/grupo_tracking_form.dart';
import 'package:rescatadores_app/presentation/pages/reportes/reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AsesorHomeScreen extends StatefulWidget {
  const AsesorHomeScreen({super.key});

  @override
  _AsesorHomeScreenState createState() => _AsesorHomeScreenState();
}

class _AsesorHomeScreenState extends State<AsesorHomeScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = true;
  List<String> _currentAsesorGroupIds = [];

  final List<MenuOption> _menuOptions = [
    MenuOption(
      title: 'Mis Grupos',
      icon: Icons.group,
      pageIndex: 0,
      children: [],
    ),
    MenuOption(
      title: 'Registrar Nuevo Discípulo',
      icon: Icons.person_add_outlined,
      pageIndex: 1,
      children: [],
    ),
    MenuOption(
      title: 'Reportes',
      icon: Icons.analytics_outlined,
      pageIndex: 2,
      children: [],
    ),
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadAsesorGroups();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      _currentAsesorGroupIds.isNotEmpty
          ? _GruposSection(
            groupIds: _currentAsesorGroupIds,
            onRefresh: _loadAsesorGroups,
          )
          : _NoGroupsMessage(onRefresh: _loadAsesorGroups),
      _CrearAlumnoSection(),
      const ReportesScreen(isAsesor: true),
    ];
  }

  Future<void> _loadAsesorGroups() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot asesorDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (asesorDoc.exists) {
          List<dynamic> groups = asesorDoc['groups'];
          setState(() {
            _currentAsesorGroupIds = List<String>.from(groups);
            _initializePages(); // Reinitialize pages with updated groups
          });
        }
      }
    } catch (e) {
      print('Error al cargar los grupos del asesor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _menuOptions[_selectedIndex]
              .title, // Muestra el título del menú actual
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Implementar notificaciones
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  // Navegar a pantalla independiente en lugar de cambiar el índice
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AsesorProfileScreen(),
                    ),
                  );
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, isDesktop),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      drawer: isDesktop ? null : _buildSidebar(context, isDesktop),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    return Container(
      width: isDesktop ? (_isCollapsed ? 70 : 240) : 240,
      color: AppTheme.primaryColor.withOpacity(0.9),
      child: Column(
        children: [
          if (!isDesktop)
            DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Asesor',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: IconButton(
                icon: Icon(
                  _isCollapsed ? Icons.menu : Icons.close,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                  });
                },
              ),
            ),
          const Divider(color: Colors.white54),
          Expanded(
            child: ListView.builder(
              itemCount: _menuOptions.length,
              itemBuilder: (context, index) {
                final MenuOption menuOption = _menuOptions[index];

                return ListTile(
                  leading: Icon(
                    menuOption.icon,
                    color:
                        _selectedIndex == index ? Colors.white : Colors.white70,
                  ),
                  title:
                      !_isCollapsed || !isDesktop
                          ? Text(
                            menuOption.title,
                            style: TextStyle(
                              color:
                                  _selectedIndex == index
                                      ? Colors.white
                                      : Colors.white70,
                            ),
                          )
                          : null,
                  selected: _selectedIndex == index,
                  selectedTileColor: AppTheme.primaryColor.withOpacity(0.4),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    if (!isDesktop) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GruposSection extends StatelessWidget {
  final List<String> groupIds;
  final Future<void> Function() onRefresh;

  const _GruposSection({required this.groupIds, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Grupos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Expanded(
            child: ListView.builder(
              itemCount: groupIds.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Grupo ${groupIds[index]}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  GrupoTrackingForm(groupId: groupIds[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGroupsMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _NoGroupsMessage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4),
          Center(
            child: Text(
              'No tienes grupos asignados.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrearAlumnoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const CrearAlumnoScreen();
  }
}

class MenuOption {
  final String title;
  final IconData icon;
  final int pageIndex;
  final List<MenuOption> children;

  MenuOption({
    required this.title,
    required this.icon,
    required this.pageIndex,
    required this.children,
  });
}

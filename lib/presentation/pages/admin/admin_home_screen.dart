import 'package:rescatadores_app/presentation/pages/admin/tracking_questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/presentation/pages/admin/admin_dashboard_screen.dart';
import 'package:rescatadores_app/presentation/pages/admin/admin_profile_screen.dart';
import 'package:rescatadores_app/presentation/pages/admin/groups_management_screen.dart';
import 'package:rescatadores_app/presentation/pages/reportes/reports_screen.dart';
import 'package:rescatadores_app/presentation/pages/admin/user_creation_screen.dart';
import 'package:rescatadores_app/presentation/pages/admin/user_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = true;

  // Mapa para controlar submenús expandidos
  final Map<int, bool> _expandedSubmenus = {};

  // Estructura de menú con submenús
  final List<MenuOption> _menuOptions = [
    MenuOption(
      title: 'Dashboard',
      icon: Icons.dashboard,
      pageIndex: 0,
      children: [],
    ),
    MenuOption(
      title: 'Usuarios',
      icon: Icons.people,
      children: [
        MenuOption(
          title: 'Gestión de Usuarios',
          icon: Icons.manage_accounts,
          pageIndex: 1,
          children: [],
        ),
        MenuOption(
          title: 'Crear Usuario',
          icon: Icons.person_add,
          pageIndex: 2,
          children: [],
        ),
      ],
    ),
    MenuOption(
      title: 'Grupos',
      icon: Icons.group_work,
      pageIndex: 3,
      children: [],
    ),
    MenuOption(
      title: 'Seguimiento',
      icon: Icons.assignment,
      children: [
        MenuOption(
          title: 'Preguntas de Seguimiento',
          icon: Icons.question_answer,
          pageIndex: 4,
          children: [],
        ),
        MenuOption(
          title: 'Reportes',
          icon: Icons.analytics,
          pageIndex: 5,
          children: [],
        ),
      ],
    ),
  ];

  final List<Widget> _pages = [
    const AdminDashboard(),
    const UserManagementScreen(),
    const AdminUserCreationScreen(),
    const GroupsManagementScreen(),
    const TrackingQuestionsScreen(),
    const ReportesScreen(),
  ];

  // Método para obtener el título de la página actual
  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Gestión de Usuarios';
      case 2:
        return 'Crear Usuario';
      case 3:
        return 'Gestión de Grupos';
      case 4:
        return 'Preguntas de Seguimiento';
      case 5:
        return 'Reportes';
      default:
        return 'Panel Administrativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminProfileScreen(),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppTheme.primaryColor),
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

  // Función para construir la barra lateral o el drawer
  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    return Container(
      width: isDesktop ? (_isCollapsed ? 70 : 240) : 240,
      color: AppTheme.primaryColor.withOpacity(0.8),
      child: Column(
        children: [
          if (!isDesktop)
            DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryColor),
              child: const Column(
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
                  SizedBox(height: 10),
                  Text(
                    'Administrador',
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
                    // Cerrar todos los submenús cuando colapsa
                    if (_isCollapsed) {
                      _expandedSubmenus.clear();
                    }
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
                final bool hasChildren = menuOption.children.isNotEmpty;
                final bool isExpanded = _expandedSubmenus[index] ?? false;

                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        menuOption.icon,
                        color:
                            _selectedIndex == (menuOption.pageIndex ?? -1)
                                ? Colors.white
                                : Colors.white70,
                      ),
                      title:
                          !_isCollapsed || !isDesktop
                              ? Text(
                                menuOption.title,
                                style: TextStyle(
                                  color:
                                      _selectedIndex ==
                                              (menuOption.pageIndex ?? -1)
                                          ? Colors.white
                                          : Colors.white70,
                                ),
                              )
                              : null,
                      trailing:
                          hasChildren && (!_isCollapsed || !isDesktop)
                              ? Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white70,
                              )
                              : null,
                      selected: _selectedIndex == (menuOption.pageIndex ?? -1),
                      selectedTileColor: AppTheme.primaryColor.withOpacity(0.4),
                      onTap: () {
                        if (hasChildren) {
                          setState(() {
                            // En desktop con menú colapsado, mostrar submenús
                            if (isDesktop && _isCollapsed) {
                              _isCollapsed = false;
                              _expandedSubmenus[index] = true;
                            } else {
                              // Toggle submenu
                              _expandedSubmenus[index] = !isExpanded;
                            }
                          });
                        } else if (menuOption.pageIndex != null) {
                          setState(() {
                            _selectedIndex = menuOption.pageIndex!;
                          });
                          if (!isDesktop) Navigator.pop(context);
                        }
                      },
                    ),
                    // Submenús
                    if (hasChildren &&
                        isExpanded &&
                        (!_isCollapsed || !isDesktop))
                      ...menuOption.children.map((subOption) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: ListTile(
                            leading: Icon(
                              subOption.icon,
                              color:
                                  _selectedIndex == (subOption.pageIndex ?? -1)
                                      ? Colors.white
                                      : Colors.white70,
                              size: 20,
                            ),
                            title: Text(
                              subOption.title,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _selectedIndex ==
                                            (subOption.pageIndex ?? -1)
                                        ? Colors.white
                                        : Colors.white70,
                              ),
                            ),
                            selected:
                                _selectedIndex == (subOption.pageIndex ?? -1),
                            selectedTileColor: AppTheme.primaryColor
                                .withOpacity(0.2),
                            onTap: () {
                              if (subOption.pageIndex != null) {
                                setState(() {
                                  _selectedIndex = subOption.pageIndex!;
                                });
                                if (!isDesktop) Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para representar opciones de menú
class MenuOption {
  final String title;
  final IconData icon;
  final int? pageIndex;
  final List<MenuOption> children;

  MenuOption({
    required this.title,
    required this.icon,
    this.pageIndex,
    required this.children,
  });
}

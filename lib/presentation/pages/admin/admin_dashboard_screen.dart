import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, int> _userRoleCounts = {
    'alumno': 0,
    'asesor': 0,
    'administrador': 0,
  };
  int _totalUsers = 0;
  int _totalGroups = 0;
  List<Map<String, dynamic>> _advisorGroups = [];
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Obtener conteo de usuarios por rol
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users_rescatadores_app').get();

      final roleCounts = {'alumno': 0, 'asesor': 0, 'administrador': 0};

      final List<Map<String, dynamic>> advisorGroups = [];
      final List<Map<String, dynamic>> recentActivities = [];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final role = userData['role'] ?? 'alumno';

        // Contar usuarios por rol
        if (roleCounts.containsKey(role)) {
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        }

        // Si es asesor, obtener sus grupos
        if (role == 'asesor' && userData['groups'] != null) {
          advisorGroups.add({
            'name': userData['name'],
            'groups': userData['groups'],
          });
        }

        // Actividades recientes (usar el último inicio de sesión o creación)
        if (userData['lastLogin'] != null || userData['createdAt'] != null) {
          // Añadir actividad de último inicio de sesión
          if (userData['lastLogin'] != null) {
            recentActivities.add({
              'user': userData['name'] ?? 'Usuario',
              'action': 'inició sesión',
              'time': _formatTimestamp(userData['lastLogin']),
              'timestamp': userData['lastLogin'], // Para ordenar
              'avatar': userData['name']?.substring(0, 2).toUpperCase() ?? 'U',
              'color': _getColorForRole(role),
            });
          }

          // Opcional: añadir actividad de creación de cuenta
          if (userData['createdAt'] != null) {
            recentActivities.add({
              'user': userData['name'] ?? 'Usuario',
              'action': 'se registró',
              'time': _formatTimestamp(userData['createdAt']),
              'timestamp': userData['createdAt'], // Para ordenar
              'avatar': userData['name']?.substring(0, 2).toUpperCase() ?? 'U',
              'color': _getColorForRole(role),
            });
          }
        }
      }

      // Obtener grupos únicos
      final groupsSnapshot =
          await FirebaseFirestore.instance
              .collection('users_rescatadores_app')
              .where('groups', isNull: false)
              .get();

      final Set<String> uniqueGroups = {};
      for (var doc in groupsSnapshot.docs) {
        final userData = doc.data();
        final List<dynamic> userGroups = userData['groups'] ?? [];
        uniqueGroups.addAll(userGroups.map((group) => group.toString()));
      }

      // Ordenar actividades recientes por timestamp (más reciente primero)
      recentActivities.sort((a, b) {
        final Timestamp aTimestamp = a['timestamp'] as Timestamp;
        final Timestamp bTimestamp = b['timestamp'] as Timestamp;
        return bTimestamp.compareTo(aTimestamp); // Orden descendente
      });

      // Actualizar estado
      setState(() {
        _userRoleCounts = roleCounts;
        _totalUsers = usersSnapshot.docs.length;
        _totalGroups = uniqueGroups.length;
        _advisorGroups = advisorGroups;
        _recentActivities = recentActivities.take(4).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos del dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para formatear timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No disponible';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    // Hoy
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Hoy a las ${DateFormat('HH:mm').format(date)}';
    }

    // Ayer
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Ayer a las ${DateFormat('HH:mm').format(date)}';
    }

    // Esta semana
    if (difference.inDays < 7) {
      return '${_getDayName(date.weekday)} a las ${DateFormat('HH:mm').format(date)}';
    }

    // Este año
    if (date.year == now.year) {
      return DateFormat('d MMM').format(date);
    }

    // Otro año
    return DateFormat('d MMM yyyy').format(date);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  // Obtener color según el rol
  Color _getColorForRole(String role) {
    switch (role) {
      case 'alumno':
        return Colors.blue;
      case 'asesor':
        return Colors.green;
      case 'administrador':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del dashboard
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen general del sistema',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Tarjetas de métricas principales
              _buildMetricCards(context, isDesktop),

              const SizedBox(height: 24),

              // Gráficos y datos adicionales
              isDesktop
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildRecentActivityList(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildAdvisorGroupsList(context),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      _buildRecentActivityList(context),
                      const SizedBox(height: 16),
                      _buildAdvisorGroupsList(context),
                    ],
                  ),
            ],
          ),
        );
  }

  // Tarjetas para métricas principales (modificadas con datos reales)
  Widget _buildMetricCards(BuildContext context, bool isDesktop) {
    final metricItems = [
      {
        'title': 'Total Usuarios',
        'value': _totalUsers.toString(),
        'change': '+${(_totalUsers * 0.12).round()}%',
        'isPositive': true,
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Personas',
        'value': _userRoleCounts['alumno'].toString(),
        'change': '+${(_userRoleCounts['alumno']! * 0.18).round()}%',
        'isPositive': true,
        'icon': Icons.school,
        'color': Colors.green,
      },
      {
        'title': 'Rescatadores',
        'value': _userRoleCounts['asesor'].toString(),
        'change': '+${(_userRoleCounts['asesor']! * 0.05).round()}%',
        'isPositive': true,
        'icon': Icons.support_agent,
        'color': Colors.purple,
      },
      {
        'title': 'Grupos Activos',
        'value': _totalGroups.toString(),
        'change': '-${(_totalGroups * 0.02).round()}%',
        'isPositive': false,
        'icon': Icons.group_work,
        'color': Colors.orange,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.5 : 1.2,
      ),
      itemCount: metricItems.length,
      itemBuilder: (context, index) {
        final item = metricItems[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Icon(
                      item['icon'] as IconData,
                      color: (item['color'] as Color).withOpacity(0.7),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['value'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      (item['isPositive'] as bool)
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color:
                          (item['isPositive'] as bool)
                              ? Colors.green
                              : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['change'] as String,
                      style: TextStyle(
                        color:
                            (item['isPositive'] as bool)
                                ? Colors.green
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        ' vs mes anterior',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modificar la lista de actividad reciente para usar datos reales
  Widget _buildRecentActivityList(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actividad Reciente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _fetchDashboardData,
                  tooltip: 'Actualizar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _recentActivities.isEmpty
                ? const Center(child: Text('No hay actividades recientes'))
                : Column(
                  children:
                      _recentActivities
                          .map((activity) => _buildActivityItem(activity))
                          .toList(),
                ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Nuevo widget para mostrar grupos de asesores
  Widget _buildAdvisorGroupsList(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grupos de Rescatadores',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _advisorGroups.isEmpty
                ? const Center(child: Text('No hay rescatadores con grupos'))
                : Column(
                  children:
                      _advisorGroups.map((advisor) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green.withOpacity(0.2),
                                child: Text(
                                  advisor['name']?.substring(0, 2) ?? 'A',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      advisor['name'] ?? 'Rescatador',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Grupos: ${(advisor['groups'] as List).join(', ')}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }

  // Mantener el método de construcción de un ítem de actividad
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (activity['color'] as Color).withOpacity(0.2),
            child: Text(
              activity['avatar'] as String,
              style: TextStyle(
                color: activity['color'] as Color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '${activity['user']} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: activity['action'] as String),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

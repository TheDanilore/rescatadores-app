import 'dart:convert';

import 'package:rescatadores_app/presentation/pages/admin/user_edit_screen.dart';
import 'package:rescatadores_app/presentation/pages/admin/user_group_assignment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:http/http.dart' as http;

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String? _selectedRoleFilter;
  bool _isLoading = false;

  // Traducciones de roles para la UI
  final Map<String, String> _roleDisplay = {
    'alumno': 'Persona',
    'asesor': 'Rescatador',
    'administrador': 'Coordinador',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o correo',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Filtro de roles
                Row(
                  children: [
                    const Text(
                      'Filtrar por rol: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRoleFilterChip(null, 'Todos'),
                            _buildRoleFilterChip('alumno', 'Personas'),
                            _buildRoleFilterChip('asesor', 'Rescatadores'),
                            _buildRoleFilterChip(
                              'administrador',
                              'Coordinadores',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users_rescatadores_app').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay usuarios disponibles.'),
                  );
                }

                // Filtrar usuarios
                var users =
                    snapshot.data!.docs.where((doc) {
                      var userData = doc.data() as Map<String, dynamic>;
                      String name = (userData['name'] ?? '').toLowerCase();
                      String email = (userData['email'] ?? '').toLowerCase();
                      String role = userData['role'] ?? '';

                      // Aplicar filtro de búsqueda
                      bool matchesSearch =
                          _searchQuery.isEmpty ||
                          name.contains(_searchQuery) ||
                          email.contains(_searchQuery);

                      // Aplicar filtro de rol
                      bool matchesRole =
                          _selectedRoleFilter == null ||
                          role == _selectedRoleFilter;

                      return matchesSearch && matchesRole;
                    }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron usuarios que coincidan con los filtros',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var doc = users[index];
                    var user = doc.data() as Map<String, dynamic>;
                    String role = user['role'] ?? 'alumno';
                    String status = user['status'] ?? 'activo';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(role),
                          child: Text(
                            (user['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'Sin correo'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(_roleDisplay[role] ?? role),
                                  backgroundColor: _getRoleColor(
                                    role,
                                  ).withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _getRoleColor(role),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(_getStatusDisplay(status)),
                                  backgroundColor: _getStatusColor(
                                    status,
                                  ).withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _getStatusColor(status),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.group),
                              tooltip: 'Asignar grupos',
                              onPressed: () {
                                _navigateToGroupAssignment(
                                  context,
                                  doc.id,
                                  user,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar usuario',
                              onPressed: () {
                                _navigateToEditUser(context, doc.id, user);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Eliminar usuario',
                              color: Colors.red,
                              onPressed: () {
                                _confirmDeleteUser(context, doc.id, user);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _navigateToEditUser(context, doc.id, user);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro que desea eliminar a ${userData['name']}? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(userId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.post(
        Uri.parse('https://deleteuserrestrescatadores-gsgjkmd7rq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar usuario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleFilterChip(String? role, String label) {
    bool isSelected = _selectedRoleFilter == role;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRoleFilter = selected ? role : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor:
            role == null
                ? AppTheme.primaryColor.withOpacity(0.2)
                : _getRoleColor(role).withOpacity(0.2),
        checkmarkColor:
            role == null ? AppTheme.primaryColor : _getRoleColor(role),
        labelStyle: TextStyle(
          color:
              isSelected
                  ? (role == null ? AppTheme.primaryColor : _getRoleColor(role))
                  : Colors.black,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'administrador':
        return Colors.purple;
      case 'asesor':
        return AppTheme.primaryColor;
      case 'alumno':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'activo':
        return Colors.green;
      case 'inactivo':
        return Colors.orange;
      case 'suspendido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'suspendido':
        return 'Suspendido';
      default:
        return status;
    }
  }

  void _navigateToEditUser(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Usar 90% de la pantalla
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) => UserEditScreen(userId: userId, userData: userData),
    );
  }

  void _navigateToGroupAssignment(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) =>
              UserGroupAssignmentScreen(userId: userId, userData: userData),
    );
  }
}

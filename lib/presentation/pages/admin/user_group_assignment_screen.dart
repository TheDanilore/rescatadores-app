import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescatadores_app/config/theme.dart';

class UserGroupAssignmentScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserGroupAssignmentScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserGroupAssignmentScreen> createState() => _UserGroupAssignmentScreenState();
}

class _UserGroupAssignmentScreenState extends State<UserGroupAssignmentScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _userGroups = [];
  List<String> _availableGroups = [];
  String? _errorMessage;
  bool get _isAlumno => widget.userData['role'] == 'alumno';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener los grupos actuales del usuario
      _userGroups = List<String>.from(widget.userData['groups'] ?? []);

      // Cargar grupos de otros usuarios administradores
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users_rescatadores_app')
          .where('role', isEqualTo: 'administrador')
          .get();

      // Recoger todos los grupos únicos de los usuarios administradores
      final Set<String> uniqueGroups = {};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> userGroups = data['groups'] ?? [];
        uniqueGroups.addAll(userGroups.map((group) => group.toString()));
      }

      setState(() {
        _availableGroups = uniqueGroups.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar los datos: $e';
      });
    }
  }

  Future<void> _saveGroups() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Actualizar los grupos del usuario en Firestore
      await FirebaseFirestore.instance
          .collection('users_rescatadores_app')
          .doc(widget.userId)
          .update({
            'groups': _userGroups,
          });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupos actualizados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar los grupos: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleGroup(String groupId) {
    setState(() {
      if (_userGroups.contains(groupId)) {
        _userGroups.remove(groupId);
      } else {
        // Si es alumno y ya tiene un grupo seleccionado, reemplazar
        if (_isAlumno) {
          _userGroups = [groupId];
        } else {
          _userGroups.add(groupId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Barra de arrastre
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Título y botón de cierre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Asignar Grupos',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Asignar grupos a: ${widget.userData['name']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rol: ${_getRoleDisplay(widget.userData['role'] ?? 'alumno')}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                
                                // Añadir nota informativa para alumnos
                                if (_isAlumno)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade800),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Los discípulos solo pueden pertenecer a un grupo. Si selecciona otro grupo, se reemplazará el actual.',
                                            style: TextStyle(
                                              color: Colors.amber.shade900,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                if (_errorMessage != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(12),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          Expanded(
                            child: _availableGroups.isEmpty
                                ? const Center(child: Text('No hay grupos disponibles'))
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: _availableGroups.length,
                                    itemBuilder: (context, index) {
                                      final groupId = _availableGroups[index];
                                      final isSelected = _userGroups.contains(groupId);
                                      
                                      // Determinar si este checkbox debe estar habilitado
                                      final bool isEnabled = !_isAlumno || 
                                                            _userGroups.isEmpty || 
                                                            _userGroups.contains(groupId);
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        // Aplicar opacidad reducida si está deshabilitado
                                        color: !isEnabled ? Colors.grey.shade100 : null,
                                        child: CheckboxListTile(
                                          title: Text(
                                            'Grupo $groupId', 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              // Texto más claro si está deshabilitado
                                              color: !isEnabled ? Colors.grey : null,
                                            ),
                                          ),
                                          value: isSelected,
                                          onChanged: isEnabled 
                                              ? (_) => _toggleGroup(groupId) 
                                              : null, // Deshabilitar cuando corresponda
                                          activeColor: AppTheme.primaryColor,
                                          checkColor: Colors.white,
                                          controlAffinity: ListTileControlAffinity.leading,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveGroups,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Guardar Grupos'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'alumno':
        return 'Persona';
      case 'asesor':
        return 'Rescatador';
      case 'administrador':
        return 'Coordinador';
      default:
        return role;
    }
  }
}
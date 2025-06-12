import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescatadores_app/config/theme.dart';

class GroupsManagementScreen extends StatefulWidget {
  const GroupsManagementScreen({super.key});

  @override
  _GroupsManagementScreenState createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends State<GroupsManagementScreen> {
  List<String> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      // Obtener el usuario administrador actual
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener el documento del usuario actual
      final userDoc = await FirebaseFirestore.instance
          .collection('users_rescatadores_app')
          .doc(currentUser.uid)
          .get();

      // Obtener los grupos del administrador actual
      final userData = userDoc.data();
      final List<dynamic> userGroups = userData?['groups'] ?? [];

      setState(() {
        _groups = userGroups.map((group) => group.toString()).toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar grupos: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar grupos');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _createGroup() async {
    final TextEditingController groupController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Grupo'),
        content: TextField(
          controller: groupController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Número de grupo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (groupController.text.isNotEmpty) {
                Navigator.of(context).pop(groupController.text);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Verificar si el grupo ya existe
      if (_groups.contains(result)) {
        _showErrorSnackBar('El grupo ya existe');
        return;
      }

      try {
        // Obtener el usuario administrador actual
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No hay usuario autenticado');
        }

        // Agregar el nuevo grupo a los grupos del administrador
        await FirebaseFirestore.instance
            .collection('users_rescatadores_app')
            .doc(currentUser.uid)
            .update({
          'groups': FieldValue.arrayUnion([result])
        });

        setState(() {
          _groups.add(result);
          _groups.sort();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grupo $result creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Error al crear grupo: $e');
      }
    }
  }

  Future<void> _deleteGroup(String group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: Text('¿Está seguro que desea eliminar el Grupo $group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Obtener el usuario administrador actual
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No hay usuario autenticado');
        }

        // Eliminar grupo de los grupos del administrador
        await FirebaseFirestore.instance
            .collection('users_rescatadores_app')
            .doc(currentUser.uid)
            .update({
          'groups': FieldValue.arrayRemove([group])
        });

        // Buscar y actualizar usuarios con este grupo
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users_rescatadores_app')
            .where('groups', arrayContains: group)
            .get();

        // Batch para actualizar múltiples documentos
        final batch = FirebaseFirestore.instance.batch();

        for (var doc in usersSnapshot.docs) {
          final currentGroups = List<String>.from(doc['groups'] ?? []);
          currentGroups.remove(group);
          
          batch.update(doc.reference, {
            'groups': currentGroups
          });
        }

        // Ejecutar batch
        await batch.commit();

        setState(() {
          _groups.remove(group);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grupo $group eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error al eliminar grupo: $e');
        _showErrorSnackBar('No se pudo eliminar el grupo');
      }
    }
  }

  Future<void> _viewGroupUsers(String group) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users_rescatadores_app')
          .where('groups', arrayContains: group)
          .get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Usuarios en Grupo $group'),
          content: SizedBox(
            width: double.maxFinite,
            child: usersSnapshot.docs.isEmpty
                ? const Center(child: Text('No hay usuarios en este grupo'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: usersSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      final userData = usersSnapshot.docs[index].data();
                      return ListTile(
                        title: Text('${userData['firstName']} ${userData['lastName']}'),
                        subtitle: Text(userData['email']),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error al cargar usuarios del grupo: $e');
      _showErrorSnackBar('No se pudieron cargar los usuarios del grupo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No hay grupos disponibles',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _createGroup,
                        child: const Text('Crear Primer Grupo'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return ListTile(
                      title: Text('Grupo $group'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.people, color: Colors.blue),
                            onPressed: () => _viewGroupUsers(group),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteGroup(group),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroup,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
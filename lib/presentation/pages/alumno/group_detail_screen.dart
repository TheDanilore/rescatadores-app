import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rescatadores_app/config/theme.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<DocumentSnapshot> _groupDetailsFuture;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _groupDetailsFuture = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Grupo'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (currentUser != null) _buildGroupActionMenu(),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _groupDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los detalles del grupo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'El grupo no existe',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;

          return _buildGroupDetails(context, groupData, snapshot.data!.id);
        },
      ),
    );
  }

  Widget _buildGroupActionMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'leave':
            _leaveGroup();
            break;
          case 'invite':
            _inviteMember();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'leave',
          child: Text('Salir del Grupo'),
        ),
        const PopupMenuItem(
          value: 'invite',
          child: Text('Invitar Miembros'),
        ),
      ],
    );
  }

  Widget _buildGroupDetails(
      BuildContext context, Map<String, dynamic> groupData, String groupId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica del grupo
          Text(
            groupData['name'] ?? 'Sin nombre',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            groupData['description'] ?? 'Sin descripción',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Sección de Miembros
          _buildMembersSection(context, groupData, groupId),

          // Sección de Actividades o Recursos
          _buildActivitiesSection(context, groupData),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
      BuildContext context, Map<String, dynamic> groupData, String groupId) {
    final List<dynamic> members = groupData['members'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Miembros (${members.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users_rescatadores_app')
                  .doc(members[index])
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(userData['name'] ?? 'Sin nombre'),
                  subtitle: Text(userData['role'] ?? 'Sin rol'),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivitiesSection(
      BuildContext context, Map<String, dynamic> groupData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Actividades Recientes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingM),
        // TODO: Implementar lista de actividades recientes
        Text(
          'No hay actividades recientes',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _leaveGroup() async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayRemove([currentUser!.uid])
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has salido del grupo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al salir del grupo')),
      );
    }
  }

  void _inviteMember() {
    // TODO: Implementar lógica de invitación de miembros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad próximamente disponible')),
    );
  }
}
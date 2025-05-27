import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importaciones de archivos separados
import 'package:rescatadores_app/presentation/pages/reportes/reportes_controller.dart';
import 'package:rescatadores_app/presentation/pages/reportes/components/empty_state.dart';
import 'package:rescatadores_app/presentation/pages/reportes/components/export_format_dialog.dart';
import 'package:rescatadores_app/presentation/pages/reportes/components/seguimiento_card.dart';
import 'package:rescatadores_app/presentation/pages/reportes/components/filter_dialog.dart';
import 'package:rescatadores_app/presentation/pages/reportes/components/seguimiento_details_dialog.dart';
import 'package:rescatadores_app/config/theme.dart';

class ReportesScreen extends StatefulWidget {
  final bool isAsesor;

  const ReportesScreen({super.key, this.isAsesor = false});

  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReportesController _controller;
  List<Map<String, dynamic>> filteredDisciples = [];
  List<Map<String, dynamic>> filteredGroups = [];
  List<Map<String, dynamic>> selectedSeguimientos = [];

  String _currentFilter =
      'all'; // Valores posibles: 'all', 'week', 'month', 'custom'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = ReportesController(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    _controller.addListener(_refresh);
    _loadData();

    // Inicializar con el filtro "all"
    _currentFilter = 'all';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    await _controller.initializeData();
  }

  // Método para exportar los seguimientos seleccionados
  Future<void> _exportSelectedSeguimientos(String tipo) async {
    final format = await showExportFormatDialog(context);
    if (format != null) {
      await _controller.exportSelectedSeguimientos(
        selectedSeguimientos,
        tipo,
        format,
        onSuccess:
            () => _showSuccessSnackbar('Seguimientos exportados correctamente'),
        onError: (error) => _showErrorSnackbar(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Seguimientos Grupales', icon: Icon(Icons.group)),
                Tab(
                  text: 'Seguimientos Individuales',
                  icon: Icon(Icons.person),
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _controller.isLoading
              ? _buildLoadingIndicator()
              : _controller.hasError
              ? _buildErrorView()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildGrupalReportesTab(),
                  _buildIndividualReportesTab(),
                ],
              ),
      floatingActionButton:
          selectedSeguimientos.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () async {
                  final format = await showExportFormatDialog(context);
                  if (format != null) {
                    await _controller.exportSelectedSeguimientos(
                      selectedSeguimientos,
                      _tabController.index == 0 ? 'grupal' : 'individual',
                      format,
                      onSuccess:
                          () => _showSuccessSnackbar(
                            'Seguimientos exportados correctamente',
                          ),
                      onError: (error) => _showErrorSnackbar(error),
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Exportar'),
                backgroundColor: AppTheme.primaryColor,
              )
              : null,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (selectedSeguimientos.length ==
                        (_tabController.index == 0
                                ? (filteredGroups.isNotEmpty
                                    ? filteredGroups
                                    : _controller.seguimientosGrupales)
                                : (filteredDisciples.isNotEmpty
                                    ? filteredDisciples
                                    : _controller.seguimientosIndividuales))
                            .length) {
                      selectedSeguimientos.clear();
                    } else {
                      selectedSeguimientos = List.from(
                        _tabController.index == 0
                            ? (filteredGroups.isNotEmpty
                                ? filteredGroups
                                : _controller.seguimientosGrupales)
                            : (filteredDisciples.isNotEmpty
                                ? filteredDisciples
                                : _controller.seguimientosIndividuales),
                      );
                    }
                  });
                },
                child: Text(
                  selectedSeguimientos.length ==
                          (_tabController.index == 0
                                  ? (filteredGroups.isNotEmpty
                                      ? filteredGroups
                                      : _controller.seguimientosGrupales)
                                  : (filteredDisciples.isNotEmpty
                                      ? filteredDisciples
                                      : _controller.seguimientosIndividuales))
                              .length
                      ? 'Deseleccionar todos'
                      : 'Seleccionar todos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyQuickFilter(String filterType) {
    setState(() {
      _currentFilter = filterType;

      // Calcula las fechas basadas en el filtro seleccionado
      final now = DateTime.now();

      switch (filterType) {
        case 'week':
          // Última semana
          _controller.applyFilters(
            selectedReportType: _controller.selectedReportType,
            startDate: now.subtract(const Duration(days: 7)),
            endDate: now,
            selectedGroups: _controller.selectedGroups,
          );
          break;

        case 'month':
          // Último mes
          _controller.applyFilters(
            selectedReportType: _controller.selectedReportType,
            startDate: DateTime(now.year, now.month - 1, now.day),
            endDate: now,
            selectedGroups: _controller.selectedGroups,
          );
          break;

        case 'all':
          // Todos los registros (último año)
          _controller.applyFilters(
            selectedReportType: _controller.selectedReportType,
            startDate: DateTime(now.year - 1, now.month, now.day),
            endDate: now,
            selectedGroups: _controller.selectedGroups,
          );
          break;
      }
    });
  }

  void _showDateRangePicker() {
    setState(() {
      _currentFilter = 'custom';
    });
    _showFilterDialog();
  }

  void _showFilterDialog() async {
    final result = await showFilterDialog(
      context: context,
      selectedReportType: _controller.selectedReportType,
      startDate: _controller.startDate,
      endDate: _controller.endDate,
      selectedGroups: _controller.selectedGroups,
      groupsList: _controller.groupsList,
      isAdministrador: _controller.isAdministrador,
    );

    if (result != null) {
      _controller.applyFilters(
        selectedReportType: result['selectedReportType'],
        startDate: result['startDate'],
        endDate: result['endDate'],
        selectedGroups: result['selectedGroups'],
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando datos de reportes...',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar los reportes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar nuevamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrupalReportesTab() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child:
          _controller.isLoadingFilters
              ? _buildFilterLoadingIndicator()
              : _controller.seguimientosGrupales.isEmpty
              ? EmptyState(
                message:
                    'No hay seguimientos grupales para los filtros seleccionados',
                onActionPressed: _showFilterDialog,
                actionLabel: 'Cambiar filtros',
                icon: Icons.group_off,
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Buscar grupo',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Filtrar la lista de grupos según el valor de búsqueda
                          filteredGroups =
                              _controller.seguimientosGrupales.where((
                                seguimiento,
                              ) {
                                return seguimiento['groupName']
                                    .toLowerCase()
                                    .contains(value.toLowerCase());
                              }).toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSeguimientosList(
                      filteredGroups.isNotEmpty
                          ? filteredGroups
                          : _controller.seguimientosGrupales,
                      false,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildIndividualReportesTab() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child:
          _controller.isLoadingFilters
              ? _buildFilterLoadingIndicator()
              : _controller.seguimientosIndividuales.isEmpty
              ? EmptyState(
                message:
                    'No hay seguimientos individuales para los filtros seleccionados',
                onActionPressed: _showFilterDialog,
                actionLabel: 'Cambiar filtros',
                icon: Icons.person_off,
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Buscar discípulo',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Filtrar la lista de discípulos según el valor de búsqueda
                          filteredDisciples =
                              _controller.seguimientosIndividuales.where((
                                seguimiento,
                              ) {
                                return seguimiento['alumnoName']
                                    .toLowerCase()
                                    .contains(value.toLowerCase());
                              }).toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSeguimientosList(
                      filteredDisciples.isNotEmpty
                          ? filteredDisciples
                          : _controller.seguimientosIndividuales,
                      true,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFilterLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Aplicando filtros...',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeguimientosList(
    List<Map<String, dynamic>> seguimientos,
    bool isIndividual,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Icon(
                isIndividual ? Icons.person : Icons.group,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Seguimientos disponibles (${seguimientos.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        _buildQuickFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.loadSeguimientos,
            color: AppTheme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: seguimientos.length,
                itemBuilder: (context, index) {
                  final seguimiento = seguimientos[index];
                  return SeguimientoCard(
                    seguimiento: seguimiento,
                    isIndividual: isIndividual,
                    isSelected: selectedSeguimientos.contains(seguimiento),
                    onSelected: (selected) {
                      setState(() {
                        if (selected == true) {
                          selectedSeguimientos.add(seguimiento);
                        } else {
                          selectedSeguimientos.remove(seguimiento);
                        }
                      });
                    },
                    onTap:
                        () => _showSeguimientoDetails(
                          seguimiento,
                          isIndividual ? 'individual' : 'grupal',
                        ),
                    onExport:
                        () => _exportSingleSeguimiento(
                          seguimiento,
                          isIndividual ? 'individual' : 'grupal',
                        ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton('Todos', 'all'),
            const SizedBox(width: 8),
            _buildFilterButton('Última semana', 'week'),
            const SizedBox(width: 8),
            _buildFilterButton('Último mes', 'month'),
            const SizedBox(width: 8),
            _buildFilterButton(
              'Personalizado',
              'custom',
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String filterType, {IconData? icon}) {
    final bool selected = _currentFilter == filterType;
    return OutlinedButton(
      onPressed: () {
        if (filterType == 'custom') {
          _showDateRangePicker();
        } else {
          _applyQuickFilter(filterType);
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade400,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
            ),
          if (icon != null && !selected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 16, color: Colors.grey.shade700),
            ),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.primaryColor : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSeguimientoDetails(
    Map<String, dynamic> seguimiento,
    String tipo,
  ) async {
    await showSeguimientoDetailsDialog(
      context: context,
      seguimiento: seguimiento,
      tipo: tipo,
      onExport: () {
        Navigator.pop(context);
        _exportSingleSeguimiento(seguimiento, tipo);
      },
    );
  }

  Future<void> _exportSingleSeguimiento(
    Map<String, dynamic> seguimiento,
    String tipo,
  ) async {
    final format = await showExportFormatDialog(context);
    if (format != null) {
      await _controller.exportSingleSeguimiento(
        seguimiento,
        tipo,
        format,
        onSuccess:
            () => _showSuccessSnackbar('Seguimiento exportado correctamente'),
        onError: (error) => _showErrorSnackbar(error),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    String errorDetail = message;
    if (message.contains('Exception:')) {
      errorDetail = message.split('Exception:').last.trim();
    } else if (message.contains('Error:')) {
      errorDetail = message.split('Error:').last.trim();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    errorDetail,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

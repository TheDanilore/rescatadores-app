import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Servicio para exportar datos de seguimientos en diferentes formatos
class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exporta los seguimientos en el formato especificado
  Future<bool> exportSeguimientos(
    List<Map<String, dynamic>> seguimientos,
    String fileName,
    String format, {
    required String tipo,
  }) async {
    try {
      // En función del formato, llamar al método correspondiente
      switch (format.toLowerCase()) {
        case 'csv':
          return await _exportToCsv(seguimientos, fileName, tipo);
        case 'excel':
          return await _exportToExcel(seguimientos, fileName, tipo);
        case 'pdf':
          return await _exportToPdf(seguimientos, fileName, tipo);
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error en exportación: $e');
      return false;
    }
  }

  /// Exportar a formato CSV
  Future<bool> _exportToCsv(
    List<Map<String, dynamic>> seguimientos,
    String fileName,
    String tipo,
  ) async {
    if (seguimientos.isEmpty) return false;

    try {
      // Preparar los datos según el tipo de seguimiento
      final StringBuffer buffer = StringBuffer();

      // Encabezados
      List<String> headers = [];
      if (tipo == 'grupal') {
        headers = ['Grupo', 'Semana', 'Fecha'];
      } else {
        headers = ['Alumno', 'Grupo', 'Semana', 'Fecha'];
      }

      // Añadir encabezados para las preguntas
      Map<String, dynamic> firstSeguimiento = seguimientos.first['data'];
      List<String> questionKeys =
          firstSeguimiento.keys
              .where((key) => key.startsWith('question_'))
              .toList();

      // Obtener los títulos reales de las preguntas desde Firestore
      Map<String, String> questionTitles = await _getQuestionTitles(
        questionKeys,
      );

      // Añadir títulos de preguntas a los encabezados
      for (String key in questionKeys) {
        headers.add(questionTitles[key] ?? 'Pregunta sin título');
      }

      // Escribir encabezados
      buffer.writeln(headers.map((h) => _escapeCSVValue(h)).join(','));

      // Añadir filas de datos
      for (var seguimiento in seguimientos) {
        List<String> row = [];
        Map<String, dynamic> data = seguimiento['data'];

        // Datos básicos
        if (tipo == 'grupal') {
          row.add(_escapeCSVValue(seguimiento['groupName']));
          row.add(_escapeCSVValue(seguimiento['semana']));
          row.add(_escapeCSVValue(_formatTimestamp(seguimiento['timestamp'])));
        } else {
          row.add(_escapeCSVValue(seguimiento['alumnoName']));
          row.add(_escapeCSVValue(seguimiento['groupName']));
          row.add(_escapeCSVValue(seguimiento['semana']));
          row.add(_escapeCSVValue(_formatTimestamp(seguimiento['timestamp'])));
        }

        // Añadir respuestas a las preguntas
        for (String key in questionKeys) {
          String value = data[key]?.toString() ?? '';
          row.add(_escapeCSVValue(value));
        }

        buffer.writeln(row.join(','));
      }

      if (kIsWeb) {
        // Descargar directamente en web con UTF-8
        final csvContent = buffer.toString();
        final blob = html.Blob([
          utf8.encode(csvContent),
        ], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
        return true;
      } else {
        // Preparar el directorio para guardar el archivo
        final directory = await _getDirectoryForExport();
        if (directory == null) return false;

        final String filePath = '${directory.path}/$fileName.csv';
        final File file = File(filePath);

        // Escribir el archivo con UTF-8
        await file.writeAsString(buffer.toString(), encoding: utf8);

        // Compartir el archivo
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Reporte de seguimientos');

        return true;
      }
    } catch (e) {
      debugPrint('Error al exportar a CSV: $e');
      return false;
    }
  }

  /// Exportar a formato Excel
  Future<bool> _exportToExcel(
    List<Map<String, dynamic>> seguimientos,
    String fileName,
    String tipo,
  ) async {
    if (seguimientos.isEmpty) return false;

    try {
      // Crear libro y hoja de Excel
      final Excel excel = Excel.createExcel();
      final String sheetName = 'Seguimientos';

      // Eliminar hojas existentes predeterminadas
      if (excel.sheets.isNotEmpty) {
        excel.delete(excel.sheets.keys.first);
      }

      // Crear o acceder a la hoja
      final Sheet sheet = excel[sheetName];

      // Preparar encabezados
      List<String> headers = [];
      int colIndex = 0;

      if (tipo == 'grupal') {
        headers = ['Grupo', 'Semana', 'Fecha'];
      } else {
        headers = ['Alumno', 'Grupo', 'Semana', 'Fecha'];
      }

      // Añadir encabezados para las preguntas
      Map<String, dynamic> firstSeguimiento = seguimientos.first['data'];
      List<String> questionKeys =
          firstSeguimiento.keys
              .where((key) => key.startsWith('question_'))
              .toList();

      // Obtener los títulos reales de las preguntas desde Firestore
      Map<String, String> questionTitles = await _getQuestionTitles(
        questionKeys,
      );

      for (String key in questionKeys) {
        headers.add(questionTitles[key] ?? 'Pregunta sin título');
      }

      // Escribir encabezados
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // Añadir datos
      for (int rowIndex = 0; rowIndex < seguimientos.length; rowIndex++) {
        var seguimiento = seguimientos[rowIndex];
        Map<String, dynamic> data = seguimiento['data'];
        int colIndex = 0;

        // Datos básicos
        if (tipo == 'grupal') {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(seguimiento['groupName'] ?? '');
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(seguimiento['semana'] ?? '');
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(
            _formatTimestamp(seguimiento['timestamp']),
          );
        } else {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(seguimiento['alumnoName'] ?? '');
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(seguimiento['groupName'] ?? '');
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(seguimiento['semana'] ?? '');
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(
            _formatTimestamp(seguimiento['timestamp']),
          );
        }

        // Añadir respuestas a las preguntas
        for (String key in questionKeys) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex + 1,
                ),
              )
              .value = TextCellValue(data[key]?.toString() ?? '');
        }
      }

      if (kIsWeb) {
        // Descargar directamente en web
        final bytes = excel.encode();
        if (bytes != null) {
          final blob = html.Blob(
            [bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', '$fileName.xlsx')
            ..click();
          html.Url.revokeObjectUrl(url);
          return true;
        }
        return false;
      }

      // Código para móvil/desktop
      final directory = await _getDirectoryForExport();
      if (directory == null) return false;

      final String filePath = '${directory.path}/$fileName.xlsx';
      final File file = File(filePath);

      // Escribir el archivo
      await file.writeAsBytes(excel.encode()!);

      // Compartir el archivo
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Reporte de seguimientos');

      return true;
    } catch (e) {
      debugPrint('Error al exportar a Excel: $e');
      return false;
    }
  }

  /// Exportar a formato PDF
  /// Exportar a formato PDF
  Future<bool> _exportToPdf(
    List<Map<String, dynamic>> seguimientos,
    String fileName,
    String tipo,
  ) async {
    if (seguimientos.isEmpty) return false;

    try {
      // Crear documento PDF
      final pdf = pw.Document();

      // En web, cargar fuente de manera diferente
      pw.Font? ttf;
      try {
        if (kIsWeb) {
          // Para web, usar una fuente genérica
          ttf = pw.Font.helvetica();
        } else {
          final font = await rootBundle.load(
            "assets/fonts/OpenSans-Regular.ttf",
          );
          ttf = pw.Font.ttf(font);
        }
      } catch (e) {
        debugPrint('Error al cargar fuente: $e');
        ttf = pw.Font.helvetica(); // Fallback a fuente genérica
      }

      // Obtener títulos de preguntas
      Map<String, dynamic> firstSeguimiento = seguimientos.first['data'];
      List<String> questionKeys =
          firstSeguimiento.keys
              .where((key) => key.startsWith('question_'))
              .toList();

      Map<String, String> questionTitles = await _getQuestionTitles(
        questionKeys,
      );

      // Dividir seguimientos en lotes para manejar múltiples páginas
      const int batchSize = 10; // Número de seguimientos por página
      for (int i = 0; i < seguimientos.length; i += batchSize) {
        int end =
            (i + batchSize < seguimientos.length)
                ? i + batchSize
                : seguimientos.length;
        List<Map<String, dynamic>> batch = seguimientos.sublist(i, end);

        // Añadir página(s) al PDF
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            header: (context) => _buildPdfHeader(batch, tipo),
            footer: (context) => _buildPdfFooter(context),
            build:
                (context) => [
                  _buildPdfContent(
                    batch,
                    tipo,
                    questionKeys,
                    questionTitles,
                    ttf ?? pw.Font.helvetica(), // Usar fuente genérica si falla
                  ),
                ],
          ),
        );
      }

      // Para web
      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        return true;
      }

      // Para móvil/desktop
      final directory = await _getDirectoryForExport();
      if (directory == null) return false;

      final String filePath = '${directory.path}/$fileName.pdf';
      final File file = File(filePath);

      // Escribir el archivo
      await file.writeAsBytes(await pdf.save());

      // Compartir el archivo
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Reporte de seguimientos');

      return true;
    } catch (e) {
      debugPrint('Error al exportar a PDF: $e');
      return false;
    }
  }

  // Construir cabecera del PDF
  pw.Widget _buildPdfHeader(
    List<Map<String, dynamic>> seguimientos,
    String tipo,
  ) {
    String title = 'Reporte de Seguimientos';
    if (tipo == 'grupal') {
      title += ' Grupales';
    } else {
      title += ' Individuales';
    }

    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.Divider(),
        ],
      ),
    );
  }

  // Construir pie de página del PDF
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Footer(
      trailing: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
      ),
    );
  }

  // Construir contenido principal del PDF
  pw.Widget _buildPdfContent(
    List<Map<String, dynamic>> seguimientos,
    String tipo,
    List<String> questionKeys,
    Map<String, String> questionTitles,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var seguimiento in seguimientos) ...[
          _buildPdfSeguimientoSection(
            seguimiento,
            tipo,
            questionKeys,
            questionTitles,
            font,
          ),
          if (seguimientos.indexOf(seguimiento) < seguimientos.length - 1)
            pw.SizedBox(height: 20),
        ],
      ],
    );
  }

  // Construir sección de un seguimiento en el PDF
  pw.Widget _buildPdfSeguimientoSection(
    Map<String, dynamic> seguimiento,
    String tipo,
    List<String> questionKeys,
    Map<String, String> questionTitles,
    pw.Font font,
  ) {
    String title =
        tipo == 'grupal'
            ? 'Grupo: ${seguimiento['groupName']}'
            : 'Alumno: ${seguimiento['alumnoName']}';

    String subtitle = 'Semana: ${seguimiento['semana']}';
    if (tipo == 'individual' && seguimiento['groupName'] != null) {
      subtitle += ' • Grupo: ${seguimiento['groupName']}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Fecha: ${_formatTimestamp(seguimiento['timestamp'])}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 12),

        // Preguntas y respuestas
        for (int i = 0; i < questionKeys.length; i++) ...[
          pw.Text(
            '${i + 1}. ${questionTitles[questionKeys[i]] ?? 'Pregunta sin título'}',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              seguimiento['data'][questionKeys[i]]?.toString() ??
                  'Sin respuesta',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 16),
        ],
      ],
    );
  }

  // Obtener los títulos de las preguntas desde Firestore
  Future<Map<String, String>> _getQuestionTitles(
    List<String> questionKeys,
  ) async {
    Map<String, String> result = {};

    try {
      // Obtener todas las preguntas para los tipos correspondientes
      QuerySnapshot questionsSnapshot =
          await _firestore
              .collection('tracking_questions')
              .where(
                'type',
                whereIn: ['alumno', 'grupo'],
              ) // Ajustar según el tipo
              .where('isActive', isEqualTo: true)
              .orderBy('number')
              .get();

      // Crear un mapa de preguntas ordenadas
      for (var doc in questionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String questionId = doc.id;

        // Verificar si este questionId está en los questionKeys
        String fullKey = 'question_$questionId';
        if (questionKeys.contains(fullKey)) {
          result[fullKey] = data['hint'] ?? 'Pregunta sin título';
        }
      }
    } catch (e) {
      debugPrint('Error al obtener títulos de preguntas: $e');
    }

    return result;
  }

  // Escapar caracteres especiales para CSV, con soporte para tildes
  String _escapeCSVValue(String value) {
    // Si el valor contiene coma, comillas o salto de línea, envolver en comillas
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      // Escapar comillas internas
      value = value.replaceAll('"', '""');
      // Envolver en comillas externas
      value = '"$value"';
    }
    return value;
  }

  // Formatear timestamp para mostrar
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'Sin fecha';
    }

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Formato de fecha desconocido';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Obtener directorio para exportación según plataforma
  Future<Directory?> _getDirectoryForExport() async {
    if (kIsWeb) {
      // En web, no necesitamos un directorio físico
      return null;
    }

    try {
      // En dispositivos móviles, necesitamos verificar permisos
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (Platform.isAndroid) {
          // En Android 11+ necesitamos permisos especiales
          if (!await Permission.storage.isGranted) {
            var status = await Permission.storage.request();
            if (status != PermissionStatus.granted) {
              return null;
            }
          }
        }
      }

      // En iOS y Android usamos el directorio de documentos
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('Error al obtener directorio: $e');
      return null;
    }
  }
}

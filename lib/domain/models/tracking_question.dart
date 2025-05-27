class TrackingQuestion {
  final String id;
  final String number; // Por ejemplo: "1", "1.1", "2", etc.
  final String title;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final int order; // Para ordenar las preguntas
  final String type; // "grupo" o "alumno"
  final bool isActive; // Para desactivar preguntas sin eliminarlas

  TrackingQuestion({
    required this.id,
    required this.number,
    required this.title,
    required this.hint,
    this.isRequired = false,
    this.maxLines = 3,
    required this.order,
    required this.type,
    this.isActive = true,
  });

  // Factory para crear desde Firestore
  factory TrackingQuestion.fromMap(String id, Map<String, dynamic> data) {
    return TrackingQuestion(
      id: id,
      number: data['number'] ?? '',
      title: data['title'] ?? '',
      hint: data['hint'] ?? '',
      isRequired: data['isRequired'] ?? false,
      maxLines: data['maxLines'] ?? 3,
      order: data['order'] ?? 0,
      type: data['type'] ?? 'grupo', // Por defecto es de grupo
      isActive: data['isActive'] ?? true,
    );
  }

  // Método para convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'title': title,
      'hint': hint,
      'isRequired': isRequired,
      'maxLines': maxLines,
      'order': order,
      'type': type,
      'isActive': isActive,
    };
  }

  // Método para clonar con cambios
  TrackingQuestion copyWith({
    String? number,
    String? title,
    String? hint,
    bool? isRequired,
    int? maxLines,
    int? order,
    String? type,
    bool? isActive,
  }) {
    return TrackingQuestion(
      id: this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      hint: hint ?? this.hint,
      isRequired: isRequired ?? this.isRequired,
      maxLines: maxLines ?? this.maxLines,
      order: order ?? this.order,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}
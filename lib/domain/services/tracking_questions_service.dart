import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rescatadores_app/domain/models/tracking_question.dart';

class TrackingQuestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colección de preguntas de seguimiento
  final String _collection = 'tracking_questions';

  // Obtener todas las preguntas de seguimiento por tipo
  Future<List<TrackingQuestion>> getQuestionsByType(String type) async {
    try {
      print('⚠️ Intentando obtener preguntas de tipo: $type');

      // Consulta simplificada - solo filtra por tipo
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('type', isEqualTo: type)
              .get();

      print(
        '✅ Consulta exitosa: ${snapshot.docs.length} preguntas encontradas',
      );

      // Filtra manualmente
      return snapshot.docs
          .map(
            (doc) => TrackingQuestion.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .where((question) => question.isActive) // Filtra las activas
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)); // Ordena manualmente
    } catch (e) {
      print('❌ ERROR en getQuestionsByType: $e');
      throw e; // Re-lanzar el error para manejarlo arriba
    }
  }

  // Obtener todas las preguntas (incluyendo inactivas) para administración
  Future<List<TrackingQuestion>> getAllQuestions() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .orderBy('type')
              .orderBy('order')
              .get();

      return snapshot.docs
          .map(
            (doc) => TrackingQuestion.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error al obtener todas las preguntas: $e');
      return [];
    }
  }

  // Crear una nueva pregunta
  Future<String?> createQuestion(TrackingQuestion question) async {
    try {
      final DocumentReference ref = await _firestore
          .collection(_collection)
          .add({
            ...question.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': _auth.currentUser?.uid,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': _auth.currentUser?.uid,
          });

      return ref.id;
    } catch (e) {
      print('Error al crear pregunta: $e');
      return null;
    }
  }

  // Actualizar una pregunta existente
  Future<bool> updateQuestion(TrackingQuestion question) async {
    try {
      await _firestore.collection(_collection).doc(question.id).update({
        ...question.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      return true;
    } catch (e) {
      print('Error al actualizar pregunta: $e');
      return false;
    }
  }

  // Desactivar una pregunta (soft delete)
  Future<bool> deactivateQuestion(String questionId) async {
    try {
      await _firestore.collection(_collection).doc(questionId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      return true;
    } catch (e) {
      print('Error al desactivar pregunta: $e');
      return false;
    }
  }

  // Eliminar una pregunta permanentemente
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection(_collection).doc(questionId).delete();

      return true;
    } catch (e) {
      print('Error al eliminar pregunta: $e');
      return false;
    }
  }

  // Reordenar preguntas (actualiza todos los órdenes en una transacción)
  Future<bool> reorderQuestions(List<TrackingQuestion> questions) async {
    try {
      // Usar una transacción para garantizar consistencia
      await _firestore.runTransaction((transaction) async {
        for (var i = 0; i < questions.length; i++) {
          final question = questions[i];
          final docRef = _firestore.collection(_collection).doc(question.id);
          transaction.update(docRef, {
            'order': i,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': _auth.currentUser?.uid,
          });
        }
      });

      return true;
    } catch (e) {
      print('Error al reordenar preguntas: $e');
      return false;
    }
  }

  // Crear preguntas predeterminadas si no existen
  Future<void> createDefaultQuestionsIfNeeded() async {
    try {
      // Verificar si ya existen preguntas
      QuerySnapshot existingQuestions =
          await _firestore.collection(_collection).limit(1).get();

      if (existingQuestions.docs.isNotEmpty) {
        return; // Ya existen preguntas, no crear predeterminadas
      }

      // Lista de preguntas predeterminadas para grupos
      final List<TrackingQuestion> defaultGroupQuestions = [
        TrackingQuestion(
          id: 'temp_1',
          number: '1',
          title: 'INTERCESIÓN',
          hint:
              '¿Se hace intercesión en tu mesa al empezar los grupos pequeños de revisión de vida?',
          maxLines: 3,
          order: 0,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_2',
          number: '2',
          title: 'DINÁMICA DE LA CRUZ',
          hint:
              '¿Seguís la "dinámica de la cruz" para la revisión de vida? ¿Cómo la hacéis?',
          maxLines: 3,
          order: 1,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_3',
          number: '3',
          title: 'PARTICIPACIÓN',
          hint:
              '¿Las intervenciones son equilibradas entre todos los discípulos?',
          maxLines: 3,
          order: 2,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_4',
          number: '4',
          title: 'NUEVOS DISCÍPULOS',
          hint:
              '¿Qué criterio seguís para recibir a un nuevo discípulo? ¿Hacéis presentaciones?',
          maxLines: 3,
          order: 3,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_5',
          number: '5',
          title: 'PETICIONES ESPECIALES',
          hint:
              '¿Qué peticiones especiales hacen los discípulos en relación a expectativas no cumplidas?',
          maxLines: 4,
          order: 4,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_6',
          number: '6',
          title: 'CRECIMIENTO ESPIRITUAL',
          hint:
              '¿Perseguís un crecimiento espiritual en los discípulos? ¿Qué signos identificáis?',
          maxLines: 4,
          order: 5,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_7',
          number: '7',
          title: 'EXPERIENCIAS DE ORACIÓN',
          hint:
              '¿Cómo podríamos conectar a los discípulos con experiencias de oración más profundas?',
          maxLines: 3,
          order: 6,
          type: 'grupo',
        ),
        TrackingQuestion(
          id: 'temp_8',
          number: '8',
          title: 'MINISTERIOS',
          hint:
              '¿Conoces los ministerios que existen actualmente en la parroquia para ofrecérselos?',
          maxLines: 3,
          order: 7,
          type: 'grupo',
        ),
      ];

      // Lista de preguntas predeterminadas para alumnos
      final List<TrackingQuestion> defaultStudentQuestions = [
        TrackingQuestion(
          id: 'temp_a1',
          number: '1',
          title: 'CONVERSACIÓN PERSONAL',
          hint:
              '¿Has tenido ocasión de conversar personalmente con este discípulo? ¿Conoces sus necesidades?',
          maxLines: 5,
          isRequired: true,
          order: 0,
          type: 'alumno',
        ),
        TrackingQuestion(
          id: 'temp_a2',
          number: '2',
          title: 'SACRAMENTOS DE INICIACIÓN',
          hint:
              '¿Ha recibido los sacramentos de iniciación cristiana? ¿Cuáles le faltan?',
          maxLines: 3,
          order: 1,
          type: 'alumno',
        ),
        TrackingQuestion(
          id: 'temp_a3',
          number: '3',
          title: 'ASISTENCIA REGULAR',
          hint:
              '¿Asiste regularmente? En caso negativo, ¿has hablado con él/ella?',
          maxLines: 3,
          order: 2,
          type: 'alumno',
        ),
        TrackingQuestion(
          id: 'temp_a4',
          number: '4',
          title: 'EXPERIENCIA DE FE',
          hint: '¿Ha vivido una experiencia de primer anuncio de la fe? ¿Cuál?',
          maxLines: 3,
          order: 3,
          type: 'alumno',
        ),
        TrackingQuestion(
          id: 'temp_a5',
          number: '5',
          title: 'NECESIDADES ESPECIALES',
          hint:
              '¿Tiene necesidades especiales de sanación, acompañamiento, etc.?',
          maxLines: 4,
          order: 4,
          type: 'alumno',
        ),
        TrackingQuestion(
          id: 'temp_a6',
          number: '6',
          title: 'NIVEL DE MADUREZ',
          hint:
              '¿Qué nivel de madurez espiritual observas? ¿Está listo para servir en algún ministerio?',
          maxLines: 3,
          order: 5,
          type: 'alumno',
        ),
      ];

      // Agregar preguntas predeterminadas
      final batch = _firestore.batch();

      // Agregar preguntas de grupo
      for (var question in defaultGroupQuestions) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          ...question.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid,
        });
      }

      // Agregar preguntas de alumno
      for (var question in defaultStudentQuestions) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          ...question.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al crear preguntas predeterminadas: $e');
    }
  }
}

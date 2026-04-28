import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/ai_concept_models.dart';

class AiConceptService {
  final String _baseUrl; // ✅ DECLARED HERE

  AiConceptService({String? endpointBaseUrl})
      : _baseUrl = endpointBaseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'https://YOUR_CLOUD_ENDPOINT/ai';



  Future<String> requestConceptRenders(ConceptInput input) async {
    final uri = Uri.parse('$_baseUrl/generateConceptRenders');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final docId = (data['docId'] as String?) ?? (data['id'] as String?);
      if (docId == null || docId.isEmpty) {
        throw Exception('Invalid response: missing docId');
      }
      return docId;
    } else {
      throw Exception('AI request failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Stream<AiConceptJob> watchJob(String docId) {
    final ref = FirebaseFirestore.instance.collection('ai_concepts').doc(docId);
    return ref.snapshots().map((snap) => AiConceptJob.fromDoc(snap as DocumentSnapshot<Map<String, dynamic>>));
  }
}

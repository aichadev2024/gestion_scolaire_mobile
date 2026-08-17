import 'user_model.dart';

class EleveModel {
  final int id;
  final String matricule;
  final String statut;
  final String? classeNom;
  final ProfilModel profil;

  EleveModel({
    required this.id,
    required this.matricule,
    required this.statut,
    this.classeNom,
    required this.profil,
  });

  factory EleveModel.fromJson(Map<String, dynamic> json) {
    return EleveModel(
      id: json['id'] ?? 0,
      matricule: json['matricule'] ?? '',
      statut: json['statut'] ?? 'ACTIF',
      classeNom: json['classeNom'],
      profil: ProfilModel.fromJson(json['profil'] ?? {}),
    );
  }
}

class NoteModel {
  final String matiereNom;
  final double valeur;
  final double noteMax;
  final double coefficient;
  final String typeEvaluation;

  NoteModel({
    required this.matiereNom,
    required this.valeur,
    required this.noteMax,
    required this.coefficient,
    required this.typeEvaluation,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      matiereNom: json['matiereNom'] ?? '',
      valeur: (json['valeur'] ?? 0).toDouble(),
      noteMax: (json['noteMax'] ?? 20).toDouble(),
      coefficient: (json['coefficient'] ?? 1.0).toDouble(),
      typeEvaluation: json['typeEvaluation'] ?? 'Devoir',
    );
  }
}

class BulletinModel {
  final String eleveNom;
  final String elevePrenom;
  final String eleveMatricule;
  final String classeNom;
  final String periode;
  final String anneeScolaire;
  final double moyenneGenerale;
  final String appreciationGenerale;
  final bool estVerrouille;
  final int? rang;
  final int? effectifClasse;
  final List<NoteModel> notes;

  BulletinModel({
    required this.eleveNom,
    required this.elevePrenom,
    required this.eleveMatricule,
    required this.classeNom,
    required this.periode,
    required this.anneeScolaire,
    required this.moyenneGenerale,
    required this.appreciationGenerale,
    required this.estVerrouille,
    this.rang,
    this.effectifClasse,
    required this.notes,
  });

  factory BulletinModel.fromJson(Map<String, dynamic> json) {
    var rawNotes = json['lignes'] as List? ?? [];
    List<NoteModel> noteList = [];
    for (var l in rawNotes) {
      var innerNotes = l['notes'] as List? ?? [];
      for (var n in innerNotes) {
        noteList.add(NoteModel(
          matiereNom: l['matiereNom'] ?? '',
          valeur: (n['valeur'] ?? 0).toDouble(),
          noteMax: (n['noteMax'] ?? 20).toDouble(),
          coefficient: (l['coefficient'] ?? 1).toDouble(),
          typeEvaluation: n['typeEvaluation'] ?? 'Devoir',
        ));
      }
    }

    return BulletinModel(
      eleveNom: json['eleveNom'] ?? '',
      elevePrenom: json['elevePrenom'] ?? '',
      eleveMatricule: json['eleveMatricule'] ?? '',
      classeNom: json['classeNom'] ?? '',
      periode: json['periode'] ?? 'TRIMESTRE_1',
      anneeScolaire: json['anneeScolaire'] ?? '2026/2027',
      moyenneGenerale: (json['moyenneGenerale'] ?? 0).toDouble(),
      appreciationGenerale: json['appreciationGenerale'] ?? '',
      estVerrouille: json['estVerrouille'] ?? false,
      rang: json['rang'],
      effectifClasse: json['effectifClasse'],
      notes: noteList,
    );
  }
}

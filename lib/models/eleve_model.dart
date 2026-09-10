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

/// Une matière du bulletin : moyenne de l'élève, coefficient et le détail des
/// notes qui ont servi au calcul (on veut voir le total obtenu avant la moyenne).
class LigneBulletin {
  final String matiereNom;
  final double coefficient;
  final double moyenneEleve;
  final List<NoteModel> notes;

  LigneBulletin({
    required this.matiereNom,
    required this.coefficient,
    required this.moyenneEleve,
    required this.notes,
  });

  /// Somme des notes obtenues (avant conversion en moyenne).
  double get totalObtenu => notes.fold(0.0, (s, n) => s + n.valeur);

  /// Somme des barèmes correspondants.
  double get totalBareme => notes.fold(0.0, (s, n) => s + n.noteMax);

  /// Points de la matière dans la moyenne générale.
  double get points => moyenneEleve * coefficient;

  factory LigneBulletin.fromJson(Map<String, dynamic> l) {
    final inner = l['notes'] as List? ?? [];
    final coef = (l['coefficient'] ?? 1).toDouble();
    return LigneBulletin(
      matiereNom: l['matiereNom'] ?? '',
      coefficient: coef,
      moyenneEleve: (l['moyenneEleve'] ?? 0).toDouble(),
      notes: inner
          .map<NoteModel>((n) => NoteModel(
                matiereNom: l['matiereNom'] ?? '',
                valeur: (n['valeur'] ?? 0).toDouble(),
                noteMax: (n['noteMax'] ?? 20).toDouble(),
                coefficient: coef,
                typeEvaluation: n['typeEvaluation'] ?? 'Devoir',
              ))
          .toList(),
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
  final List<LigneBulletin> lignes;
  final List<NoteModel> notes; // liste à plat, conservée pour compatibilité

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
    required this.lignes,
    required this.notes,
  });

  double get totalCoefficients => lignes.fold(0.0, (s, l) => s + l.coefficient);
  double get totalPoints => lignes.fold(0.0, (s, l) => s + l.points);

  /// Moyenne recalculée à partir des totaux (pour afficher le calcul).
  double get moyenneCalculee =>
      totalCoefficients > 0 ? totalPoints / totalCoefficients : 0;

  factory BulletinModel.fromJson(Map<String, dynamic> json) {
    final rawLignes = json['lignes'] as List? ?? [];
    final lignes = rawLignes
        .map<LigneBulletin>((l) => LigneBulletin.fromJson(Map<String, dynamic>.from(l)))
        .toList();
    final flat = <NoteModel>[for (final l in lignes) ...l.notes];

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
      lignes: lignes,
      notes: flat,
    );
  }
}

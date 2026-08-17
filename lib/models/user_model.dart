class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String prenom;
  final String nom;
  final String? etablissementNom;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.prenom,
    required this.nom,
    this.etablissementNom,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['utilisateurId'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'ELEVE',
      prenom: json['prenom'] ?? '',
      nom: json['nom'] ?? '',
      etablissementNom: json['etablissementNom'],
    );
  }
}

class ProfilModel {
  final String prenom;
  final String nom;
  final String? telephone;
  final String? photoUrl;
  final String? genre;
  final String? dateNaissance;
  final String? adresse;

  ProfilModel({
    required this.prenom,
    required this.nom,
    this.telephone,
    this.photoUrl,
    this.genre,
    this.dateNaissance,
    this.adresse,
  });

  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      prenom: json['prenom'] ?? '',
      nom: json['nom'] ?? '',
      telephone: json['telephone'],
      photoUrl: json['photoUrl'],
      genre: json['genre'],
      dateNaissance: json['dateNaissance'],
      adresse: json['adresse'],
    );
  }
}

# 📱 Netaa École - Application Mobile (iOS & Android) 🇲🇱

Application mobile multi-rôles Flutter dédiée aux **Parents, Élèves et Enseignants** au Mali.

---

## 🛠️ Stack Technique

- **Framework** : Flutter 3.x (Dart)
- **Design System** : Custom Glassmorphic Dark UI + Google Fonts (Outfit)
- **Authentification** : JWT + OTP 2FA + Configuration dynamique d'IP backend local
- **Composants clés** : QR Code Generator (`qr_flutter`), Spinners (`flutter_spinkit`)

---

## 🌟 Fonctionnalités par Rôle

### 👪 Espace Parent / Élève
- **Carte Scolaire Numérique CR80** : Badge d'identité élève avec QR Code dynamique (`NETAA-VERIFY-{matricule}`) pour le contrôle d'accès anti-fraude.
- **Sélecteur Multi-Enfants** : Basculement fluide entre plusieurs enfants inscrits.
- **Bulletins & Notes en Direct** : Consultations des moyennes générales, rangs réels et détail par matière.
- **Règlement Mobile Money 🇲🇱** : Suivi du solde de scolarité et paiement en 1 clic via **Orange Money**, **Moov Africa** et **Wave Mali**.
- **Journal des Présences** : Suivi quotidien des présences, retards et absences justifiées.
- **Emploi du Temps** : Vue hebdomadaire par jour.

### 👨‍🏫 Espace Enseignant
- **Gestion du Cours Actif** : Affichage en temps réel du cours en cours, de la classe et de la salle.
- **Appel & Présences Express** : Prise de présence 1-clic par classe.
- **Saisie & Publication des Notes** : Saisie des évaluations par classe et trimestre.
- **Emploi du Temps Prof** : Planning hebdomadaire complet.

---

## 🚀 Lancement Rapide

1. Récupérez les dépendances :
   ```bash
   flutter pub get
   ```

2. Exécutez l'application sur émulateur ou téléphone physique :
   ```bash
   flutter run
   ```

3. **Connexion au backend local sur téléphone physique** :
   Dans l'écran de connexion de l'application, appuyez sur l'icône ⚙️ en haut à droite pour saisir l'adresse IP Wi-Fi de votre ordinateur (ex: `192.168.1.50`).

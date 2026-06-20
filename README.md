# VELOX Pro — Flutter (Livreur + Taxi VTC, un seul APK)

App Flutter unique qui démarre sur un **écran de choix de rôle** (Livreur / Taxi VTC),
puis ouvre le flux correspondant. Thème **noir + vert** (sombre) / **blanc + vert** (clair).

## Lancer

```bash
flutter create . --project-name velox_pro   # génère android/, ios/, etc. si besoin
flutter pub get
flutter run
```

Si tu pars d'un projet vide : crée le projet avec `flutter create velox_pro`, puis
remplace le dossier `lib/` et le `pubspec.yaml` par ceux-ci.

## Construire l'APK

```bash
flutter build apk --release       # APK
flutter build appbundle           # .aab pour le Play Store
```

(Signature keystore requise pour publier.)

## Structure

```
lib/
  main.dart                     # MaterialApp, thèmes clair/sombre
  theme/velox_theme.dart        # palette VELOX (ThemeExtension)
  role_selection_screen.dart    # 2 boutons : Livreur / Taxi VTC
  livreur/livreur_shell.dart    # flux Livreur (en ligne, commandes, livraison)
  driver/driver_shell.dart      # flux Taxi VTC (mission entrante, course, gains)
```

## Périmètre (à lire)

C'est une **base fonctionnelle qui tourne**, pas un portage 1:1 de tes apps Kotlin :

- Les données (commandes, courses, gains) sont **simulées** en mémoire.
- Pas de Firebase, pas de cartes réelles, pas de FCM, pas de GPS — ce sont les
  points à brancher ensuite.
- L'écran de choix de rôle est un aiguillage d'UI. La vraie séparation des droits
  (un livreur ne touche pas aux courses VTC) doit rester **côté serveur**
  (rôle Firestore + custom claims Firebase + règles).

## Prochaines étapes pour le rendre réel

1. Ajouter `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
   au `pubspec.yaml` + `flutterfire configure`.
2. Brancher l'auth après le choix de rôle (login email/téléphone/Google).
3. Remplacer les listes simulées par des `StreamBuilder` sur Firestore (temps réel).
4. Ajouter une carte (`google_maps_flutter` ou `flutter_map`/osmdroid) pour le suivi.
5. Notifications push (FCM) pour les commandes/courses entrantes.

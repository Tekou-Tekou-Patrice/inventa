# Inventa

Application Flutter de gestion d’une plantation de cacao, connectée au backend Spring Boot du
projet `C:\Users\patri\Desktop\spring boot\Inventa`.

## Démarrage local

1. Configurez et démarrez l’API Spring Boot (voir son `README.md`).
2. Démarrez Chrome localement avec `flutter run -d chrome`; Flutter Web utilise
   `http://localhost:8006` par défaut.
3. Sur un émulateur Android, l’application utilise `http://10.0.2.2:8006`.
4. Pour un téléphone physique, un simulateur iOS ou un serveur distant, indiquez l’URL joignable :

   ```powershell
   flutter run --dart-define=INVENTA_API_URL=http://IP-DE-VOTRE-PC:8006
   ```

   Le téléphone et le PC doivent être sur le même réseau Wi-Fi, et le pare-feu doit autoriser le
   port 8006. Pour un serveur distant, utilisez une URL HTTPS.
5. Connectez-vous avec un des comptes provisionnés côté backend.

Le frontend utilise une authentification HTTP Basic. Les identifiants sont conservés dans le
stockage sécurisé de l’appareil pour restaurer la session après fermeture et sont effacés à la
déconnexion. Tout déploiement hors environnement local doit utiliser HTTPS. L’application
n’affiche plus les données de démonstration par défaut.

## Notifications push Firebase

Les applications Android, iOS et Web sont enregistrées dans le projet Firebase `inventa-5cad4`.
L’application demande l’autorisation de notification lors de la première connexion et rattache le
jeton à l’utilisateur connecté. Les demandes de matériel, décisions de paie, dépenses de l’assistant
et approvisionnements déclenchent des notifications ciblées.

- Android utilise la configuration enregistrée dans `android/app/google-services.json`.
- iOS nécessite une clé APNs configurée pour l’application dans Firebase Console.
- Pour le Web Push, créez un certificat VAPID dans Firebase Console, puis démarrez/construisez avec
  `--dart-define=INVENTA_FIREBASE_WEB_VAPID_KEY=VOTRE_CLE_PUBLIQUE_VAPID`.
- Configurez l’API Spring avec `FIREBASE_PROJECT_ID=inventa-5cad4` et des Google Application
  Default Credentials autorisés à envoyer via Firebase Cloud Messaging. En local, définissez
  `GOOGLE_APPLICATION_CREDENTIALS` vers un fichier de compte de service conservé hors du dépôt; en
  production, utilisez les identifiants de service gérés de l’environnement.
- Déployez le Web via `firebase deploy --only hosting` après `flutter build web`. Les notifications
  Web nécessitent HTTPS et une autorisation explicite du navigateur.

Les options côté client et les fichiers Google Services identifient les applications; ils ne
remplacent pas les identifiants d’envoi serveur, la configuration APNs ni la clé Web Push VAPID.

## Rubriques par rôle

- **DIRECTOR** : accueil, champs, comptes, ouvriers, paie, stocks et dépenses en lecture pour le
  suivi centralisé de tous les sites. Peut définir l’enveloppe globale, y ajouter des fonds sans
  remplacer le montant existant et suivre les allocations et dépenses budgétées; ne peut pas
  effectuer les opérations réservées à l’assistant ou au responsable
  terrain.
- **ASSISTANT** : accueil, ouvriers, stocks/achats, dépenses et paie; peut attribuer des fonds aux
  champs, saisir les dépenses imputées au budget et gérer les prix unitaires des produits. Les
  dépenses hors ligne restent en attente de synchronisation ou de rapprochement; les présences,
  tâches et heures supplémentaires restent inaccessibles.
- **FIELD_MANAGER** : toutes les rubriques sauf les paiements, qui restent réservés à l’assistant
  et à la lecture au directeur. Il voit uniquement le budget de son champ et peut saisir des
  dépenses motivées, déduites du solde qui lui a été attribué.

Dans **Rapport**, le directeur et l’assistant peuvent choisir un mois et consulter le récapitulatif
des présences, tâches, mouvements de stock, alertes, dépenses, paiements, ventes de récolte et
heures supplémentaires, avec les détails en tableaux et les totaux financiers. Le directeur ne voit
que les activités des journées validées par l’assistant; les paiements sont récapitulés séparément.
Pour payer un ouvrier, l’assistant ouvre **Paie**, puis
appuie sur **Payer** à côté de son nom et confirme le versement; le paiement est aussitôt enregistré.

Lors de la préparation d’une demande de matériel, l’assistant peut ajuster la quantité envoyée, même
si elle diffère de la quantité demandée; le prix
unitaire enregistré et le total sont calculés automatiquement et conservés avec la date de l’envoi.

Les rubriques masquées dans Flutter sont également interdites par l’API Spring Boot; le contrôle ne
repose donc pas uniquement sur l’interface.

Pour produire les fichiers Web destinés au déploiement, remplacez l’URL d’exemple par l’adresse
HTTPS publique de l’API :

```powershell
flutter build web `
  --dart-define=INVENTA_API_URL=https://api.votre-domaine.example `
  --dart-define=INVENTA_FIREBASE_WEB_VAPID_KEY=VOTRE_CLE_PUBLIQUE_VAPID
```

Publiez ensuite `build\web` sur Firebase Hosting. Configurez côté API
`INVENTA_CORS_ALLOWED_ORIGINS` avec l’origine HTTPS exacte du site Flutter.

## Vérification

```powershell
flutter analyze
flutter test
flutter build web
```

Le prototype visuel peut être lancé avec `InventaApp(demoMode: true)` dans un harness de test; ce
mode n’est pas activé dans l’application normale.

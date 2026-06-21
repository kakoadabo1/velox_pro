# VELOX — Modèle de données partagé (Firebase / Firestore)

Toutes les apps (Client, Partenaire, Restaurant) utilisent **le même projet
Firebase** et les **mêmes collections**. Elles ne s'appellent jamais entre
elles : elles lisent/écrivent Firestore, qui sert de plaque tournante en
temps réel.

> ⚠️ Prérequis : les 4 apps doivent pointer sur le MÊME projet Firebase
> (`velox-pro-d6030`). Tant qu'elles sont sur des projets différents, elles
> ne partagent rien.

## Collections

### partners/{uid}
Le statut d'un livreur ou chauffeur.
| champ      | type      | écrit par      |
|------------|-----------|----------------|
| role       | string    | Partenaire     | 'livreur' \| 'driver'
| online     | bool      | Partenaire     |
| name       | string    | Partenaire     |
| lat, lng   | number    | Partenaire     | position (étape carte)
| updatedAt  | timestamp | Partenaire     |

### restaurants/{id}
| champ    | type   | écrit par   |
|----------|--------|-------------|
| ownerId  | string | Restaurant  |
| name     | string | Restaurant  |
| open     | bool   | Restaurant  |
| menu     | array  | Restaurant  | [{name, price}]

### orders/{id}  (livraison)
| champ      | type      | écrit par                         |
|------------|-----------|-----------------------------------|
| clientId   | string    | Client (création)                 |
| restaurantId | string  | Client                            |
| items      | array     | Client                            | [{name, price, qty}]
| total      | number    | Client                            |
| address    | string    | Client                            |
| status     | string    | Client→Resto→Partenaire           |
| courierId  | string?   | Partenaire (à l'acceptation)      |
| createdAt  | timestamp | Client                            |

**Cycle `status`** :
`en_attente_resto` → `en_preparation` → `prete` → `assignee` → `recuperee` → `livree`

- Le **Client** crée la commande (`en_attente_resto`).
- Le **Restaurant** passe `en_preparation` puis `prete`.
- L'app **Partenaire** liste les `prete` sans `courierId`, en accepte une
  (`assignee`), puis `recuperee` → `livree`.
- À chaque changement, le **Client** voit la progression en direct.

### rides/{id}  (taxi)
| champ     | type      | écrit par                    |
|-----------|-----------|------------------------------|
| clientId  | string    | Client                       |
| from, to  | string    | Client                       |
| price     | number    | Client                       |
| status    | string    | Client→Partenaire            |
| driverId  | string?   | Partenaire (à l'acceptation) |

**Cycle `status`** : `recherche` → `assignee` → `en_route` → `terminee`

### reviews/{id}
| champ     | type   | écrit par |
|-----------|--------|-----------|
| authorId  | string | Client    |
| targetId  | string | Client    | uid du partenaire noté
| stars     | number | Client    | 1..5
| comment   | string | Client    |
| createdAt | timestamp | Client |

## Comment l'app Partenaire l'utilise (déjà branché)
- `FirestoreService.setPartnerOnline()` écrit `partners/{uid}` quand on passe
  en ligne. (✅ fait)
- `pendingOrders()` / `acceptOrder()` / `setOrderStatus()` pour la livraison.
- `pendingRides()` / `acceptRide()` / `setRideStatus()` pour le taxi.

## Étapes suivantes pour rendre tout réel
1. Brancher les listes (onglets Commandes / Courses) sur les streams ci-dessus
   à la place des données simulées (StreamBuilder).
2. App **Restaurant** : créer/avancer les `orders`.
3. App **Client** : créer `orders` et `rides`, suivre le `status` en direct.
4. Cloud Function de **dispatch** : matcher le partenaire en ligne le plus
   proche + notifications FCM.
5. Carte + position (Google Maps) pour le suivi en direct.

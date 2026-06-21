import 'package:flutter/material.dart';

/// Langue courante (par défaut français). Codes : fr, en, ar, aa, so.
final ValueNotifier<String> localeNotifier = ValueNotifier<String>('fr');

/// L'arabe s'écrit de droite à gauche.
bool get isRTL => localeNotifier.value == 'ar';

const Map<String, String> kLanguageNames = {
  'fr': 'Français',
  'en': 'English',
  'ar': 'العربية',
  'aa': 'Qafar',
  'so': 'Soomaali',
};

/// Traduction. Retombe sur le français si la clé/langue manque.
String tr(String key) {
  final lang = localeNotifier.value;
  final row = _t[key];
  if (row == null) return key;
  return row[lang] ?? row['fr'] ?? key;
}

/// Table de traductions : clé -> { langue -> texte }.
const Map<String, Map<String, String>> _t = {
  // Onglets / titres
  'tab_home': {'fr': 'Accueil', 'en': 'Home', 'ar': 'الرئيسية', 'aa': 'Qux', 'so': 'Guriga'},
  'tab_orders': {'fr': 'Commandes', 'en': 'Orders', 'ar': 'الطلبات', 'aa': 'Amrisa', 'so': 'Dalabyada'},
  'tab_requests': {'fr': 'Demandes', 'en': 'Requests', 'ar': 'الطلبات', 'aa': 'Esserora', 'so': 'Codsiyada'},
  'tab_inflight': {'fr': 'En cours', 'en': 'In progress', 'ar': 'جارٍ', 'aa': 'Taama', 'so': 'Socota'},
  'tab_settings': {'fr': 'Paramètres', 'en': 'Settings', 'ar': 'الإعدادات', 'aa': 'Massakax', 'so': 'Dejinta'},
  'title_livreur': {'fr': 'VELOX Livreur', 'en': 'VELOX Courier', 'ar': 'VELOX موصّل', 'aa': 'VELOX Gee', 'so': 'VELOX Geeye'},
  'title_taxi': {'fr': 'VELOX Taxi', 'en': 'VELOX Taxi', 'ar': 'VELOX تاكسي', 'aa': 'VELOX Taksi', 'so': 'VELOX Taksi'},
  'title_active_delivery': {'fr': 'Livraison en cours', 'en': 'Delivery in progress', 'ar': 'توصيل جارٍ', 'aa': 'Gee taama', 'so': 'Gaarsiin socota'},
  'title_active_ride': {'fr': 'Course en cours', 'en': 'Ride in progress', 'ar': 'رحلة جارية', 'aa': 'Gexso taama', 'so': 'Safar socda'},

  // Bienvenue / rôles
  'welcome': {'fr': 'Bienvenue', 'en': 'Welcome', 'ar': 'مرحباً', 'aa': 'Nagaay', 'so': 'Soo dhawoow'},
  'role_livreur': {'fr': 'Livreur partenaire', 'en': 'Courier partner', 'ar': 'موصّل شريك', 'aa': 'Gee kataysa', 'so': 'Geeye shariik'},
  'role_driver': {'fr': 'Chauffeur VTC', 'en': 'VTC driver', 'ar': 'سائق', 'aa': 'Taksi koroysa', 'so': 'Darawal'},

  // Disponibilité
  'available': {'fr': 'Disponible', 'en': 'Available', 'ar': 'متاح', 'aa': 'Mango', 'so': 'La heli karaa'},
  'unavailable': {'fr': 'Indisponible', 'en': 'Unavailable', 'ar': 'غير متاح', 'aa': 'Mango waan', 'so': 'La heli karo'},
  'sub_on_livreur': {'fr': 'Vous recevez des commandes', 'en': 'You receive orders', 'ar': 'تستقبل الطلبات', 'aa': 'Amrisa tableh', 'so': 'Waxaad helaysaa dalabyo'},
  'sub_off_livreur': {'fr': 'Activez pour recevoir des commandes', 'en': 'Turn on to receive orders', 'ar': 'فعّل لاستقبال الطلبات', 'aa': 'Amrisah daaqis', 'so': 'Shid si aad u hesho dalabyo'},
  'sub_on_driver': {'fr': 'En attente de course', 'en': 'Waiting for a ride', 'ar': 'في انتظار رحلة', 'aa': 'Gexso qambaalak', 'so': 'Sugaya safar'},
  'sub_off_driver': {'fr': 'Activez pour recevoir des courses', 'en': 'Turn on to receive rides', 'ar': 'فعّل لاستقبال الرحلات', 'aa': 'Gexsoh daaqis', 'so': 'Shid si aad u hesho safaro'},

  // Stats / cartes
  'gains_day': {'fr': 'Gains (jour)', 'en': 'Earnings (day)', 'ar': 'الأرباح (اليوم)', 'aa': 'Maaqo (saaku)', 'so': 'Faa\'iido (maanta)'},
  'gains_today': {'fr': "Gains aujourd'hui", 'en': "Today's earnings", 'ar': 'أرباح اليوم', 'aa': 'Asaaku maaqo', 'so': 'Faa\'iidada maanta'},
  'deliveries': {'fr': 'Livraisons', 'en': 'Deliveries', 'ar': 'التوصيلات', 'aa': 'Geyoота', 'so': 'Gaarsiimooyin'},
  'courses_n': {'fr': 'courses', 'en': 'rides', 'ar': 'رحلات', 'aa': 'gexsoota', 'so': 'safaro'},
  'note_avg': {'fr': 'Note moyenne', 'en': 'Average rating', 'ar': 'متوسط التقييم', 'aa': 'Mablaqo', 'so': 'Celcelis qiimeyn'},
  'no_reviews_yet': {'fr': "Pas encore d'avis", 'en': 'No reviews yet', 'ar': 'لا تقييمات بعد', 'aa': 'Mablaqo mali', 'so': 'Weli ma jiraan'},
  'reviews_n': {'fr': 'avis', 'en': 'reviews', 'ar': 'تقييم', 'aa': 'mablaqo', 'so': 'qiimeyn'},
  'see_more': {'fr': 'Voir plus', 'en': 'See more', 'ar': 'المزيد', 'aa': 'Maxagga', 'so': 'Wax dheeraad'},
  'performance_7': {'fr': 'Performance · 7 jours', 'en': 'Performance · 7 days', 'ar': 'الأداء · 7 أيام', 'aa': 'Taama · 7 ayro', 'so': 'Waxqabad · 7 maalmood'},
  'repartition': {'fr': 'Répartition', 'en': 'Breakdown', 'ar': 'التوزيع', 'aa': 'Qoodu', 'so': 'Qaybinta'},
  'no_data': {'fr': 'Pas encore de données', 'en': 'No data yet', 'ar': 'لا بيانات بعد', 'aa': 'Xayyo mali', 'so': 'Weli xog ma jirto'},
  'missions': {'fr': 'missions', 'en': 'missions', 'ar': 'مهام', 'aa': 'taamooma', 'so': 'hawlo'},
  'success': {'fr': 'réussite', 'en': 'success', 'ar': 'نجاح', 'aa': 'maqaane', 'so': 'guul'},

  // Boutons / actions
  'accept': {'fr': 'Accepter', 'en': 'Accept', 'ar': 'قبول', 'aa': 'Oggol', 'so': 'Aqbal'},
  'navigate': {'fr': 'Naviguer', 'en': 'Navigate', 'ar': 'الملاحة', 'aa': 'Gexis', 'so': 'Hagid'},
  'call': {'fr': 'Appeler', 'en': 'Call', 'ar': 'اتصال', 'aa': 'Seeci', 'so': 'Wac'},
  'mark_picked': {'fr': 'Marquer récupérée', 'en': 'Mark picked up', 'ar': 'تم الاستلام', 'aa': 'Beyte', 'so': 'Calaamadee qaadis'},
  'mark_delivered': {'fr': 'Marquer livrée', 'en': 'Mark delivered', 'ar': 'تم التسليم', 'aa': 'Gufte', 'so': 'Calaamadee gaarsiin'},
  'delivery_done': {'fr': 'Livraison terminée ✓', 'en': 'Delivery done ✓', 'ar': 'تم التوصيل ✓', 'aa': 'Gee dammite ✓', 'so': 'Gaarsiin dhammaatay ✓'},
  'start_ride': {'fr': 'Démarrer la course', 'en': 'Start ride', 'ar': 'ابدأ الرحلة', 'aa': 'Gexso qimbis', 'so': 'Bilow safarka'},
  'end_ride': {'fr': 'Terminer la course', 'en': 'End ride', 'ar': 'إنهاء الرحلة', 'aa': 'Gexso dammis', 'so': 'Dhammee safarka'},
  'course_in_progress': {'fr': 'COURSE EN COURS', 'en': 'RIDE IN PROGRESS', 'ar': 'رحلة جارية', 'aa': 'GEXSO TAAMA', 'so': 'SAFAR SOCDA'},

  // États vides
  'all_clear': {'fr': 'Tout est clair', 'en': 'All clear', 'ar': 'كل شيء هادئ', 'aa': 'Inkih saay', 'so': 'Wax walba waa nadiif'},
  'all_clear_sub': {'fr': 'Aucune commande pour le moment.', 'en': 'No orders right now.', 'ar': 'لا طلبات حالياً.', 'aa': 'Amrisa mali.', 'so': 'Hadda dalab ma jiro.'},
  'offline_t': {'fr': 'Hors ligne', 'en': 'Offline', 'ar': 'غير متصل', 'aa': 'Maro maliih', 'so': 'Khadka ka baxsan'},
  'offline_sub': {'fr': 'Activez votre disponibilité depuis l\'accueil.', 'en': 'Enable availability from Home.', 'ar': 'فعّل التوفر من الرئيسية.', 'aa': 'Quxuk daaqis.', 'so': 'Ka shid guriga.'},
  'no_request': {'fr': 'Aucune demande', 'en': 'No requests', 'ar': 'لا طلبات', 'aa': 'Esserora mali', 'so': 'Codsi ma jiro'},
  'no_request_sub': {'fr': 'Les demandes de course apparaîtront ici.', 'en': 'Ride requests will show here.', 'ar': 'ستظهر طلبات الرحلات هنا.', 'aa': 'Gexso esserora tah tableh.', 'so': 'Codsiyada safarka halkan ayay ka muuqan.'},
  'no_delivery': {'fr': 'Aucune livraison', 'en': 'No delivery', 'ar': 'لا توصيل', 'aa': 'Gee mali', 'so': 'Gaarsiin ma jirto'},
  'no_delivery_sub': {'fr': 'Acceptez une commande pour démarrer.', 'en': 'Accept an order to start.', 'ar': 'اقبل طلباً للبدء.', 'aa': 'Amris oggol.', 'so': 'Aqbal dalab si aad u bilowdo.'},
  'no_course': {'fr': 'Aucune course', 'en': 'No ride', 'ar': 'لا رحلة', 'aa': 'Gexso mali', 'so': 'Safar ma jiro'},
  'no_course_sub': {'fr': 'Acceptez une demande pour démarrer.', 'en': 'Accept a request to start.', 'ar': 'اقبل طلباً للبدء.', 'aa': 'Esser oggol.', 'so': 'Aqbal codsi si aad u bilowdo.'},
  'no_reviews': {'fr': 'Aucun avis', 'en': 'No reviews', 'ar': 'لا تقييمات', 'aa': 'Mablaqo mali', 'so': 'Qiimeyn ma jirto'},
  'no_reviews_sub': {'fr': 'Les avis de vos clients apparaîtront ici.', 'en': 'Your clients\' reviews will appear here.', 'ar': 'ستظهر تقييمات عملائك هنا.', 'aa': 'Ku sayyo mablaqo tableh.', 'so': 'Qiimeynta macaamiishaada halkan ayay ka muuqan.'},
  'no_mission': {'fr': 'Aucune mission', 'en': 'No mission', 'ar': 'لا مهام', 'aa': 'Taama mali', 'so': 'Hawl ma jirto'},
  'no_mission_sub': {'fr': 'Vos missions terminées apparaîtront ici.', 'en': 'Your completed missions will appear here.', 'ar': 'ستظهر مهامك المنجزة هنا.', 'aa': 'Dammite taamooma tableh.', 'so': 'Hawlahaaga dhammaaday halkan ayay ka muuqan.'},

  // Paramètres / menu
  'profile': {'fr': 'Profil', 'en': 'Profile', 'ar': 'الملف الشخصي', 'aa': 'Ascawsa', 'so': 'Astaanta'},
  'profile_sub': {'fr': 'Vos informations', 'en': 'Your information', 'ar': 'معلوماتك', 'aa': 'Ku xayyo', 'so': 'Macluumaadkaaga'},
  'my_gains': {'fr': 'Mes gains', 'en': 'My earnings', 'ar': 'أرباحي', 'aa': 'Yi maaqo', 'so': 'Faa\'iidadayda'},
  'my_gains_sub': {'fr': 'Détail des revenus', 'en': 'Income details', 'ar': 'تفاصيل الدخل', 'aa': 'Maaqo balclose', 'so': 'Faahfaahinta dakhliga'},
  'history': {'fr': 'Historique', 'en': 'History', 'ar': 'السجل', 'aa': 'Taariix', 'so': 'Taariikhda'},
  'history_sub': {'fr': 'Vos missions passées', 'en': 'Your past missions', 'ar': 'مهامك السابقة', 'aa': 'Warre taamooma', 'so': 'Hawlahaagii hore'},
  'client_reviews': {'fr': 'Avis clients', 'en': 'Client reviews', 'ar': 'تقييمات العملاء', 'aa': 'Sayyo mablaqo', 'so': 'Qiimeynta macaamiisha'},
  'client_reviews_sub': {'fr': 'Ce que disent les clients', 'en': 'What clients say', 'ar': 'ما يقوله العملاء', 'aa': 'Sayyo iyya', 'so': 'Waxa macaamiishu sheegaan'},
  'settings': {'fr': 'Réglages', 'en': 'Settings', 'ar': 'الإعدادات', 'aa': 'Massakax', 'so': 'Dejinta'},
  'settings_sub': {'fr': 'Thème, notifications, langue', 'en': 'Theme, notifications, language', 'ar': 'المظهر، الإشعارات، اللغة', 'aa': 'Midi, xayyis, afa', 'so': 'Muuqaal, ogeysiis, luqad'},
  'help_support': {'fr': 'Aide & support', 'en': 'Help & support', 'ar': 'المساعدة والدعم', 'aa': 'Cate', 'so': 'Caawimaad & taageero'},
  'help_support_sub': {'fr': 'Nous contacter', 'en': 'Contact us', 'ar': 'تواصل معنا', 'aa': 'Nee seeci', 'so': 'Nala soo xiriir'},

  // Profil
  'change_photo': {'fr': 'Changer la photo', 'en': 'Change photo', 'ar': 'تغيير الصورة', 'aa': 'Foto korsis', 'so': 'Beddel sawirka'},
  'logout': {'fr': 'Se déconnecter', 'en': 'Log out', 'ar': 'تسجيل الخروج', 'aa': 'Awqe', 'so': 'Ka bax'},
  'status_verified': {'fr': 'Partenaire vérifié', 'en': 'Verified partner', 'ar': 'شريك موثّق', 'aa': 'Kataysa numma', 'so': 'Shariik la xaqiijiyay'},
  'email': {'fr': 'Email', 'en': 'Email', 'ar': 'البريد', 'aa': 'Email', 'so': 'Iimayl'},
  'status': {'fr': 'Statut', 'en': 'Status', 'ar': 'الحالة', 'aa': 'Caalo', 'so': 'Xaalad'},
  'note': {'fr': 'Note', 'en': 'Rating', 'ar': 'التقييم', 'aa': 'Mablaqo', 'so': 'Qiimeyn'},

  // Gains
  'today': {'fr': "Aujourd'hui", 'en': 'Today', 'ar': 'اليوم', 'aa': 'Asaaku', 'so': 'Maanta'},
  'this_week': {'fr': 'Cette semaine', 'en': 'This week', 'ar': 'هذا الأسبوع', 'aa': 'A ayrok', 'so': 'Toddobaadkan'},
  'this_month': {'fr': 'Ce mois', 'en': 'This month', 'ar': 'هذا الشهر', 'aa': 'A alsa', 'so': 'Bishan'},
  'gains_update_note': {'fr': 'Les revenus se mettent à jour après chaque mission.', 'en': 'Earnings update after each mission.', 'ar': 'تتحدث الأرباح بعد كل مهمة.', 'aa': 'Maaqo taamak lakal cusbosa.', 'so': 'Faa\'iidadu way cusboonaataa hawl kasta kadib.'},

  // Réglages
  'dark_mode': {'fr': 'Mode sombre', 'en': 'Dark mode', 'ar': 'الوضع الداكن', 'aa': 'Diteh midi', 'so': 'Habka madow'},
  'notifications': {'fr': 'Notifications', 'en': 'Notifications', 'ar': 'الإشعارات', 'aa': 'Xayyis', 'so': 'Ogeysiisyo'},
  'language': {'fr': 'Langue', 'en': 'Language', 'ar': 'اللغة', 'aa': 'Afa', 'so': 'Luqadda'},
  'choose_language': {'fr': 'Choisir la langue', 'en': 'Choose language', 'ar': 'اختر اللغة', 'aa': 'Afa dooris', 'so': 'Dooro luqadda'},

  // Support
  'support_intro': {'fr': "Besoin d'aide ? Contactez l'équipe VELOX.", 'en': 'Need help? Contact the VELOX team.', 'ar': 'تحتاج مساعدة؟ تواصل مع فريق VELOX.', 'aa': 'Cate faxxa? VELOX seeci.', 'so': 'Caawimaad ma u baahan tahay? La xiriir kooxda VELOX.'},
  'phone': {'fr': 'Téléphone', 'en': 'Phone', 'ar': 'الهاتف', 'aa': 'Telefoon', 'so': 'Telefoon'},
  'whatsapp': {'fr': 'WhatsApp', 'en': 'WhatsApp', 'ar': 'واتساب', 'aa': 'WhatsApp', 'so': 'WhatsApp'},
  'hours': {'fr': 'Horaires : 7j/7, de 7h à 23h.', 'en': 'Hours: 7/7, 7am to 11pm.', 'ar': 'المواعيد: 7/7، من 7ص إلى 11م.', 'aa': 'Saacat: 7/7, 7ak 23.', 'so': 'Saacadaha: 7/7, 7 subax ilaa 11 habeen.'},
  'copied': {'fr': 'Copié', 'en': 'Copied', 'ar': 'تم النسخ', 'aa': 'Korsime', 'so': 'La koobiyeeyay'},
  'cant_open': {'fr': 'Impossible d\'ouvrir l\'application', 'en': 'Cannot open the app', 'ar': 'تعذّر فتح التطبيق', 'aa': 'Maleh fakak', 'so': 'Lama furi karo abka'},

  // Astuces / divers
  'tip_on_livreur': {'fr': 'Vous êtes en ligne. Les commandes arrivent dans l\'onglet Commandes.', 'en': 'You are online. Orders arrive in the Orders tab.', 'ar': 'أنت متصل. تصل الطلبات في تبويب الطلبات.', 'aa': 'Maro tan. Amrisa tableh.', 'so': 'Waad online tahay. Dalabyadu waxay yimaadaan tabka Dalabyada.'},
  'tip_off_livreur': {'fr': 'Passez en ligne pour recevoir des commandes.', 'en': 'Go online to receive orders.', 'ar': 'اتصل لاستقبال الطلبات.', 'aa': 'Marot daaqis.', 'so': 'Online noqo si aad u hesho dalabyo.'},
  'tip_on_driver': {'fr': 'Les demandes de course arrivent dans l\'onglet Demandes.', 'en': 'Ride requests arrive in the Requests tab.', 'ar': 'تصل طلبات الرحلات في تبويب الطلبات.', 'aa': 'Gexso esserora tableh.', 'so': 'Codsiyada safarku waxay yimaadaan tabka Codsiyada.'},
  'tip_off_driver': {'fr': 'Passez en ligne pour recevoir des courses.', 'en': 'Go online to receive rides.', 'ar': 'اتصل لاستقبال الرحلات.', 'aa': 'Marot daaqis.', 'so': 'Online noqo si aad u hesho safaro.'},
  'order_accepted': {'fr': 'Commande acceptée — onglet En cours', 'en': 'Order accepted — In progress tab', 'ar': 'تم قبول الطلب — تبويب جارٍ', 'aa': 'Amris oggolime', 'so': 'Dalab la aqbalay — tabka Socota'},
  'ride_accepted': {'fr': 'Course acceptée — onglet En cours', 'en': 'Ride accepted — In progress tab', 'ar': 'تم قبول الرحلة — تبويب جارٍ', 'aa': 'Gexso oggolime', 'so': 'Safar la aqbalay — tabka Socota'},

  // Auth
  'login_welcome': {'fr': 'Bienvenue 👋', 'en': 'Welcome 👋', 'ar': '👋 مرحباً', 'aa': 'Nagaay 👋', 'so': 'Soo dhawoow 👋'},
  'login_sub': {'fr': 'Votre espace pro Livreur & Taxi', 'en': 'Your Courier & Taxi pro space', 'ar': 'مساحتك المهنية للتوصيل والتاكسي', 'aa': 'Ku gee kee taksi pro', 'so': 'Booska xirfadlaha Geeye & Taksi'},
  'email_hint': {'fr': 'Adresse email', 'en': 'Email address', 'ar': 'البريد الإلكتروني', 'aa': 'Email', 'so': 'Cinwaanka iimaylka'},
  'password_hint': {'fr': 'Mot de passe', 'en': 'Password', 'ar': 'كلمة المرور', 'aa': 'Maq saqta', 'so': 'Furaha sirta'},
  'connect_as': {'fr': 'Connectez-vous en tant que', 'en': 'Sign in as', 'ar': 'سجّل الدخول بصفتك', 'aa': ' Kah cul', 'so': 'Gal sidii'},
  'btn_livreur': {'fr': 'LIVREUR', 'en': 'COURIER', 'ar': 'موصّل', 'aa': 'GEE', 'so': 'GEEYE'},
  'btn_taxi': {'fr': 'TAXI VTC', 'en': 'TAXI', 'ar': 'تاكسي', 'aa': 'TAKSI', 'so': 'TAKSI'},

  'step_accepted': {'fr': 'Acceptée', 'en': 'Accepted', 'ar': 'مقبولة', 'aa': 'Oggolime', 'so': 'La aqbalay'},
  'step_picked': {'fr': 'Récupérée', 'en': 'Picked up', 'ar': 'تم الاستلام', 'aa': 'Beyte', 'so': 'La qaaday'},
  'step_delivered': {'fr': 'Livrée', 'en': 'Delivered', 'ar': 'تم التسليم', 'aa': 'Gufte', 'so': 'La gaarsiiyay'},
  'seg_delivered': {'fr': 'Livrées', 'en': 'Delivered', 'ar': 'موصّلة', 'aa': 'Geyte', 'so': 'Gaarsiimo'},
  'seg_refused': {'fr': 'Refusées', 'en': 'Refused', 'ar': 'مرفوضة', 'aa': 'Cubte', 'so': 'La diiday'},
  'seg_done': {'fr': 'Terminées', 'en': 'Completed', 'ar': 'منتهية', 'aa': 'Dammite', 'so': 'La dhammeeyay'},
  'seg_cancelled': {'fr': 'Annulées', 'en': 'Cancelled', 'ar': 'ملغاة', 'aa': 'Bayse', 'so': 'La joojiyay'},
};

# Risely - Proje Bağlamı

## Uygulama Hakkında
Risely, Türkçe bir alışkanlık takibi / görev planlama Android uygulaması (Flutter/Dart ile yazılıyor). Kullanıcı (Mehmet) yeni başlayan bir geliştirici, Türkçe iletişim tercih ediyor.

## Mevcut Özellikler (çalışıyor)
- **Login/Splash/Hesap akışı**: LoginScreen artık gerçek Firebase Auth'a bağlı (e-posta/şifre giriş+kayıt, "Misafir Olarak Devam Et" → anonim giriş), Türkçe hata mesajları (`services/auth_error_messages.dart`). `main.dart`'taki `AuthGate` oturum durumunu dinleyip LoginScreen/SplashScreen/MainScreen arasında TEK yetkili yönlendirici (bkz. Veri Yönetimi). SplashScreen roket animasyonu + bildirim/timezone kurulumu + `TaskStore.loadData()` çalıştırır. Profil'de **HESAP** bölümü: misafirler için "Hesabını Oluştur" (`linkWithCredential`, aynı `uid` korunarak veri kaybı olmadan gerçek hesaba geçiş, isim de kaydedilir), gerçek hesaplar için e-posta gösterimi + "Çıkış Yap" (misafirse veri kaybı uyarısıyla)
- **Bulut Senkronizasyonu**: `services/firestore_sync_service.dart` — local-first (SharedPreferences birincil), her yerel yazmadan sonra arka planda Firestore'a push (fire-and-forget, yerel kaydı bloklamaz), girişte tek seferlik pull + last-write-wins birleştirme (`Task`/`MoodEntry.updatedAt` alanına göre). `firestore.rules`: her kullanıcı (anonim dahil) sadece kendi `users/{uid}` alt ağacına erişebiliyor. Offline'da uygulama tam işlevsel, bağlantı dönünce otomatik senkronize olur.
- **Ana Ekran (Home)**: Günaydın karşılaması, günün motivasyon mesajı, günlük başarı skor kartı (XP, yüzde), sabit/esnek görev listesi, gerçek zamanlı streak etiketi ("🔥 Seriye Başla!" / "🔥 N Günlük Seri!" / risk altındaysa "⚠️"), günlük mood kartı ("Bugün nasılsın?" → 5 emoji, kayıt sonrası kompakt satıra döner, dokununca değiştirilebilir)
- **Streak (Seri) Sistemi**: `TaskStore.currentStreak` / `longestStreak` / `isStreakAtRisk` — görev verisinden (allTasks) türetilen computed getter'lar, ayrı bir persist alanı yok
- **Mood Tracker**: `models/mood_entry.dart` (`MoodEntry`, günde 1 kayıt, 1-5 skor + opsiyonel not), `TaskStore.allMoods` + SharedPreferences kalıcılığı (`saved_moods`)
- **Takvim**: Haftalık/Aylık/Yıllık görünüm sekmeleri (CupertinoSlidingSegmentedControl ile)
- **İstatistikler**: Heatmap takvimi (GitHub tarzı, son 17 hafta, 5 kademeli yoğunluk, dokununca gün detayı bottom sheet'i, sağ üstte **Başarı/Ruh Hali geçiş anahtarı** — mood modu 6 kademeli ve amber renkte), üretkenlik-mood korelasyon kartı (yeterli veri varsa), Güncel Seri/En Uzun Seri kartları, tamamlanan/toplam görev, genel başarı oranı, kategori bazlı (Academic/Work/Community/Personal) ilerleme
- **Profil**: Avatar seçici, isim değiştirme, sabah motivasyon bildirimi saati kurma, karanlık/aydınlık mod, veri sıfırlama, pil optimizasyonu muafiyeti rehberi ("Bildirimler Gelmiyorsa" — durum gösterir, dokununca sistem izni + Samsung'a özel rehber diyalog açar)
- **Görev formu**: Görev ekleme/düzenleme, tarih/saat seçici (özel Samsung tarzı saat seçici widget'ı), kategori seçimi, görev bazlı bildirim hatırlatıcısı

## Proje Yapısı
```
lib/
├── main.dart                    → başlangıç noktası + RiselyApp (tema, dark mode) + AuthGate (oturum yönlendirme)
├── firebase_options.dart        → DefaultFirebaseOptions (google-services.json'dan elle üretildi, Android-only)
├── app_colors.dart              → isDarkModeNotifier + AppColors (renk paleti)
├── models/task.dart              → Task modeli (id, title, time, category, date, hasReminder, isDone, updatedAt vb.)
├── models/mood_entry.dart       → MoodEntry modeli (date, score 1-5, opsiyonel note, updatedAt)
├── services/services.dart       → TaskStore (ChangeNotifier, instance state, SharedPreferences ile kalıcılık + Firestore senkronizasyonu — main.dart'ta ChangeNotifierProvider ile sağlanıyor)
├── services/firestore_sync_service.dart → FirestoreSyncService (push/pull, local-first bulut senkronizasyonu)
├── services/auth_error_messages.dart → firebaseAuthErrorMessage() (LoginScreen + ProfileScreen ortak Türkçe hata mesajları)
├── services/notification_service.dart → NotificationService (bildirim zamanlama + pil optimizasyonu muafiyeti, permission_handler kullanır)
├── services/motivation_messages.dart  → motivationMessages sabiti (TaskStore ve NotificationService'in ortak bağımsız veri kaynağı)
├── screens/
│   ├── login_screen.dart        → e-posta/şifre giriş+kayıt, misafir girişi (kendi Navigator çağrısı YOK — AuthGate yönlendirir)
│   ├── splash_screen.dart       → onFinished callback'i alır, kendi Navigator çağrısı YOK
│   ├── main_screen.dart         → MainScreen (bottom nav + FAB) + TutorialOverlay (ilk açılış eğitimi)
│   ├── home_screen.dart
│   ├── calendar_screen.dart     → CalendarViewMode enum + CalendarScreen
│   ├── stats_screen.dart
│   ├── profile_screen.dart      → ProfileScreen (HESAP bölümü dahil) + AvatarPickerSheet
│   └── task_form.dart           → showTaskForm() + TaskFormSheet
└── widgets/
    ├── samsung_time_picker.dart → SamsungStyleTimePicker
    └── heatmap_calendar.dart    → HeatmapCalendar (StatsScreen üstünde, StatefulWidget; Başarı/Ruh Hali modları arasında geçiş yapar, TaskStore.getIntensityMapForLastDays / getMoodIntensityMapForLastDays kullanır)

firestore.rules                  → proje kökünde, Firebase Console'a manuel yapıştırıldı (CLI yok)
```

## Veri Yönetimi
`TaskStore` artık `ChangeNotifier` — instance state, `main.dart`'ta `ChangeNotifierProvider` ile sağlanıyor, `SharedPreferences` ile diskte JSON olarak saklanıyor (local-first birincil kaynak) + arka planda Firestore'a senkronize ediliyor (bkz. Mevcut Özellikler → Bulut Senkronizasyonu). Ekranlar `context.watch<TaskStore>()` ile otomatik yeniden çiziliyor (Home/Stats/Calendar/Profile), mutasyonlar (`addTask`/`toggleTask`/`deleteTask`/`clearAllData`/`resetLocalStateOnSignOut` vb.) TaskStore içinde encapsulate. Eski `onTaskToggled` callback zinciri (main_screen.dart → ekranlar → showTaskForm) tamamen kaldırıldı. `NotificationService` ayrı dosyada (`notification_service.dart`); TaskStore ona sadece `deleteTask` içinde tek yönlü bağımlı (döngüsel bağımlılık yok). Detay: roadmap.md Faz 4.

**Oturum/navigasyon kuralı (Faz 5'te öğrenildi, ÖNEMLİ):** `AuthGate` (main.dart) `FirebaseAuth.authStateChanges()`'i dinleyen TEK yetkili yönlendiricidir. `LoginScreen`/`SplashScreen`/hiçbir ekran kendi başına `Navigator.pushReplacement` ile "bir sonraki" auth-akış ekranına GEÇMEMELİ — bu, `AuthGate`'i içeren route'un yerine geçip `AuthGate`'i (ve oturum dinleyicisini) widget ağacından tamamen düşürür, sonraki oturum değişiklikleri (çıkış/tekrar giriş) bir daha hiç yakalanamaz. Yeni bir auth-akış ekranı eklenirse aynı kurala uy: sadece state değiştir (ör. `FirebaseAuth` çağrısı yap), navigasyonu `AuthGate`'e bırak.

## Sırada Ne Var
Detaylı, fazlara bölünmüş yol haritası artık **roadmap.md** dosyasında (proje kökünde) — uzun vadeli plan, "bitti" tanımları, riskler ve çapraz kurallar için oraya bakılmalı. Bu dosya sadece güncel özet için tutuluyor.

- **Faz 1 — Heatmap Takvim: TAMAMLANDI** (streak sistemi de dahil, bkz. Mevcut Özellikler)
- **Faz 2 — Bildirim Güvenilirliği: TAMAMLANDI** — pil optimizasyonu muafiyeti akışı eklendi (bkz. Mevcut Özellikler → Profil). Samsung J7 Pro (SM-J730F, Android 9) fiziksel cihazda ve Pixel 7 emülatöründe (zorla Doze modu + ekran kilitli + uygulama arka planda) test edildi: zamanlanmış görev hatırlatıcısı 3/3, sabah motivasyon bildirimi de doğrulandı. **Ek düzeltme (Faz 4 sırasında bulundu, 2026-07-09):** `splash_screen.dart`'ta cihazın saat dilimi tespiti başarısız olursa hardcoded `'Europe/Istanbul'`'a düşülüyordu — GMT gibi farklı ofsetli cihazlarda bildirimleri saatlerce kaydırıyordu (sessizce iptal bile edebiliyordu). Artık cihazın gerçek UTC ofsetine göre sabit bölge kullanılıyor.
- **Faz 3 — Mood Tracker: TAMAMLANDI** — günlük mood kaydı, heatmap'e Başarı/Ruh Hali geçiş anahtarı, üretkenlik-mood korelasyon kartı (bkz. Mevcut Özellikler). Pixel 7 emülatöründe uçtan uca test edildi.
- **Faz 4 — State Management Geçişi (Provider): TAMAMLANDI (2026-07-09).** TaskStore `ChangeNotifier`'a çevrildi (static→instance), mutasyonlar (`addTask`/`toggleTask`/`deleteTask`/`clearAllData`) encapsulate edildi, `main.dart` `ChangeNotifierProvider` ile sarmalandı, tüm ekranlar (Home→Stats→Calendar→Profile→TaskForm) tek tek `context.watch`'a geçirildi — `onTaskToggled` callback zinciri kodda hiç kalmayacak şekilde tamamen söküldü (grep ile doğrulandı), her ekran ayrı commit+push edildi. `NotificationService` ayrı dosyaya taşındı, motivasyon mesajları bağımsız sabite çıkarıldı. Regresyon testi: görev ekle/tamamla/sil, streak, tema değişimi, isim/avatar değişimi, görev hatırlatıcısı ve sabah motivasyonu bildirimleri gerçek cihazda doğrulandı. `flutter analyze` boyunca 0 yeni hata.
- **Faz 5 — Firebase: Gerçek Hesap + Bulut Senkronizasyonu: TAMAMLANDI (2026-07-11).** Firebase projesi ("risely-app") bağlandı, `applicationId` `com.mehmetincik.risely` olarak güncellendi. LoginScreen gerçek Firebase Auth'a bağlandı (e-posta/şifre + misafir/anonim), Türkçe hata mesajları. Firestore veri modeli + local-first push/pull senkronizasyon (bkz. Mevcut Özellikler). Misafir → kayıtlı hesap geçişi (`linkWithCredential`, aynı uid, veri kaybı yok) + isim alanı. Profil'e Çıkış Yap eklendi — bu sırada `AuthGate`'in kritik bir navigasyon hatası bulunup düzeltildi (bkz. Veri Yönetimi → Oturum/navigasyon kuralı). Kayıt formunda isim kaydının bazen kaybolduğu bir race condition da düzeltildi (`TaskStore.pendingUserName`). "Bitti" tanımı karşılandı: gerçek hesapla kayıt/giriş çalışıyor, misafir modu çalışıyor, veri cihazlar arasında taşınıyor (kullanıcı kendi ortamında doğruladı), offline'da uygulama tam işlevsel. `flutter analyze`: 0 yeni hata (42 önceden var olan info-level uyarı, Faz 8'e kadar tolere ediliyor).
- **Faz 4 → 5 → 7 → 8 zinciri katıdır** (Provider geçişi → Firebase → Premium → Yayın), roadmap.md'de gerekçesiyle yazılı. Faz 6 (Focus/Timer) bu zincirin dışında, esnek/opsiyonel. **Sırada: Faz 6 (Focus/Timer, esnek) ya da doğrudan Faz 7 (Premium Altyapısı — Faz 5 bittiği için artık önkoşulu karşılanıyor); hangisiyle devam edileceği kullanıcıyla netleştirilmeli.**
- **Bilinen küçük UI kusuru (henüz düzeltilmedi):** Home ekranının "Günaydın, {isim}" başlığı, isim uzun olduğunda (örn. 17+ karakter) sağdaki ikonlarla çakışıp görsel bir RenderFlex overflow uyarısı veriyor (`lib/screens/home_screen.dart`). Ayrı bir arka plan görevi olarak flag'lendi, kullanıcı henüz üzerinde çalışmadı.
- (Opsiyonel, düşük öncelik / Fikir Havuzu) `TaskStore.getUserLevelInfo()` şu an 5 seviyeli (Acemi Planlayıcı → Uzman), eskiden 9 seviyeli bir versiyon vardı, kullanıcı isterse geri getirilebilir
- (Fikir Havuzu) Google ile oturum aç — SHA-1 + `google_sign_in` paketi + yeni buton gerektiriyor, Faz 5 sırasında bilinçli olarak ertelendi

## Git / Kaynak Kontrolü
- GitHub: github.com/Mehmet-incik/Risely (main branch)
- Refactor commit + push tamamlandı, proje şu an temiz ve çalışır durumda
- Kullanıcı git workflow'unu biliyor: `git add .` → `git commit -m "..."` → `git push`

## İletişim Tercihleri
- Kullanıcı Türkçe konuşuyor, Türkçe yanıt ver
- Yeni başlayan bir geliştirici — teknik terimleri açıklayarak anlat, adım adım ilerle
- Android Studio kullanıyor (JetBrains/IntelliJ tabanlı), Windows üzerinde çalışıyor

## Test Yaklaşımı
- **Zamana bağlı testler** (bildirimler, zamanlanmış hatırlatıcılar vb.) **ve gerçek cihaz testlerini Claude Code kendi çalıştırmaz.** Bunun yerine kullanıcıya ön koşul + adımlar + beklenen sonuç içeren manuel bir test listesi hazırlar; kullanıcı kendi ortamında (gerçek cihaz/emülatör) test edip sonucu bildirir.
- **Hızlı UI duman testleri** (görev ekle/sil, ekran geçişi gibi saniyelik, zamana bağlı olmayan senaryolar) **ve kod içi doğrulamalar** (`flutter analyze`, grep, derleme) Claude Code tarafından emülatörde/kod üzerinde yapılabilir.

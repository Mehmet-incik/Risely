# Risely - Proje Bağlamı

## Uygulama Hakkında
Risely, Türkçe bir alışkanlık takibi / görev planlama Android uygulaması (Flutter/Dart ile yazılıyor). Kullanıcı (Mehmet) yeni başlayan bir geliştirici, Türkçe iletişim tercih ediyor.

## Mevcut Özellikler (çalışıyor)
- **Login/Splash akışı**: LoginScreen (henüz gerçek auth yok, direkt SplashScreen'e geçiyor) → SplashScreen (roket animasyonu, bildirim/timezone kurulumu)
- **Ana Ekran (Home)**: Günaydın karşılaması, günün motivasyon mesajı, günlük başarı skor kartı (XP, yüzde), sabit/esnek görev listesi, gerçek zamanlı streak etiketi ("🔥 Seriye Başla!" / "🔥 N Günlük Seri!" / risk altındaysa "⚠️"), günlük mood kartı ("Bugün nasılsın?" → 5 emoji, kayıt sonrası kompakt satıra döner, dokununca değiştirilebilir)
- **Streak (Seri) Sistemi**: `TaskStore.currentStreak` / `longestStreak` / `isStreakAtRisk` — görev verisinden (allTasks) türetilen computed getter'lar, ayrı bir persist alanı yok
- **Mood Tracker**: `models/mood_entry.dart` (`MoodEntry`, günde 1 kayıt, 1-5 skor + opsiyonel not), `TaskStore.allMoods` + SharedPreferences kalıcılığı (`saved_moods`)
- **Takvim**: Haftalık/Aylık/Yıllık görünüm sekmeleri (CupertinoSlidingSegmentedControl ile)
- **İstatistikler**: Heatmap takvimi (GitHub tarzı, son 17 hafta, 5 kademeli yoğunluk, dokununca gün detayı bottom sheet'i, sağ üstte **Başarı/Ruh Hali geçiş anahtarı** — mood modu 6 kademeli ve amber renkte), üretkenlik-mood korelasyon kartı (yeterli veri varsa), Güncel Seri/En Uzun Seri kartları, tamamlanan/toplam görev, genel başarı oranı, kategori bazlı (Academic/Work/Community/Personal) ilerleme
- **Profil**: Avatar seçici, isim değiştirme, sabah motivasyon bildirimi saati kurma, karanlık/aydınlık mod, veri sıfırlama, pil optimizasyonu muafiyeti rehberi ("Bildirimler Gelmiyorsa" — durum gösterir, dokununca sistem izni + Samsung'a özel rehber diyalog açar)
- **Görev formu**: Görev ekleme/düzenleme, tarih/saat seçici (özel Samsung tarzı saat seçici widget'ı), kategori seçimi, görev bazlı bildirim hatırlatıcısı

## Proje Yapısı (main.dart'tan yakın zamanda bölündü - refactor tamamlandı)
```
lib/
├── main.dart                    → başlangıç noktası + RiselyApp (tema, dark mode)
├── app_colors.dart              → isDarkModeNotifier + AppColors (renk paleti)
├── models/task.dart              → Task modeli (id, title, time, category, date, hasReminder, isDone vb.)
├── models/mood_entry.dart       → MoodEntry modeli (date, score 1-5, opsiyonel note)
├── services/services.dart       → TaskStore (ChangeNotifier, instance state, SharedPreferences ile kalıcılık — main.dart'ta ChangeNotifierProvider ile sağlanıyor)
├── services/notification_service.dart → NotificationService (bildirim zamanlama + pil optimizasyonu muafiyeti, permission_handler kullanır)
├── services/motivation_messages.dart  → motivationMessages sabiti (TaskStore ve NotificationService'in ortak bağımsız veri kaynağı)
├── screens/
│   ├── login_screen.dart
│   ├── splash_screen.dart
│   ├── main_screen.dart         → MainScreen (bottom nav + FAB) + TutorialOverlay (ilk açılış eğitimi)
│   ├── home_screen.dart
│   ├── calendar_screen.dart     → CalendarViewMode enum + CalendarScreen
│   ├── stats_screen.dart
│   ├── profile_screen.dart      → ProfileScreen + AvatarPickerSheet
│   └── task_form.dart           → showTaskForm() + TaskFormSheet
└── widgets/
    ├── samsung_time_picker.dart → SamsungStyleTimePicker
    └── heatmap_calendar.dart    → HeatmapCalendar (StatsScreen üstünde, StatefulWidget; Başarı/Ruh Hali modları arasında geçiş yapar, TaskStore.getIntensityMapForLastDays / getMoodIntensityMapForLastDays kullanır)
```

## Veri Yönetimi
`TaskStore` artık `ChangeNotifier` — instance state, `main.dart`'ta `ChangeNotifierProvider` ile sağlanıyor, `SharedPreferences` ile diskte JSON olarak saklanıyor. Ekranlar `context.watch<TaskStore>()` ile otomatik yeniden çiziliyor (Home/Stats/Calendar/Profile), mutasyonlar (`addTask`/`toggleTask`/`deleteTask`/`clearAllData` vb.) TaskStore içinde encapsulate. Eski `onTaskToggled` callback zinciri (main_screen.dart → ekranlar → showTaskForm) tamamen kaldırıldı. `NotificationService` artık ayrı dosyada (`notification_service.dart`); TaskStore ona sadece `deleteTask` içinde tek yönlü bağımlı (döngüsel bağımlılık yok). Detay: roadmap.md Faz 4.

## Sırada Ne Var
Detaylı, fazlara bölünmüş yol haritası artık **roadmap.md** dosyasında (proje kökünde) — uzun vadeli plan, "bitti" tanımları, riskler ve çapraz kurallar için oraya bakılmalı. Bu dosya sadece güncel özet için tutuluyor.

- **Faz 1 — Heatmap Takvim: TAMAMLANDI** (streak sistemi de dahil, bkz. Mevcut Özellikler)
- **Faz 2 — Bildirim Güvenilirliği: TAMAMLANDI** — pil optimizasyonu muafiyeti akışı eklendi (bkz. Mevcut Özellikler → Profil). Samsung J7 Pro (SM-J730F, Android 9) fiziksel cihazda ve Pixel 7 emülatöründe (zorla Doze modu + ekran kilitli + uygulama arka planda) test edildi: zamanlanmış görev hatırlatıcısı 3/3, sabah motivasyon bildirimi de doğrulandı. **Ek düzeltme (Faz 4 sırasında bulundu, 2026-07-09):** `splash_screen.dart`'ta cihazın saat dilimi tespiti başarısız olursa hardcoded `'Europe/Istanbul'`'a düşülüyordu — GMT gibi farklı ofsetli cihazlarda bildirimleri saatlerce kaydırıyordu (sessizce iptal bile edebiliyordu). Artık cihazın gerçek UTC ofsetine göre sabit bölge kullanılıyor.
- **Faz 3 — Mood Tracker: TAMAMLANDI** — günlük mood kaydı, heatmap'e Başarı/Ruh Hali geçiş anahtarı, üretkenlik-mood korelasyon kartı (bkz. Mevcut Özellikler). Pixel 7 emülatöründe uçtan uca test edildi.
- **Faz 4 — State Management Geçişi (Provider): TAMAMLANDI (2026-07-09).** TaskStore `ChangeNotifier`'a çevrildi (static→instance), mutasyonlar (`addTask`/`toggleTask`/`deleteTask`/`clearAllData`) encapsulate edildi, `main.dart` `ChangeNotifierProvider` ile sarmalandı, tüm ekranlar (Home→Stats→Calendar→Profile→TaskForm) tek tek `context.watch`'a geçirildi — `onTaskToggled` callback zinciri kodda hiç kalmayacak şekilde tamamen söküldü (grep ile doğrulandı), her ekran ayrı commit+push edildi. `NotificationService` ayrı dosyaya taşındı, motivasyon mesajları bağımsız sabite çıkarıldı. Regresyon testi: görev ekle/tamamla/sil, streak, tema değişimi, isim/avatar değişimi, görev hatırlatıcısı ve sabah motivasyonu bildirimleri gerçek cihazda doğrulandı. `flutter analyze` boyunca 0 yeni hata.
- **Faz 4 → 5 → 7 → 8 zinciri katıdır** (Provider geçişi → Firebase → Premium → Yayın), roadmap.md'de gerekçesiyle yazılı. **Sırada: Faz 5 (Firebase: Gerçek Hesap + Bulut Senkronizasyonu).**
- (Opsiyonel, düşük öncelik / Fikir Havuzu) `TaskStore.getUserLevelInfo()` şu an 5 seviyeli (Acemi Planlayıcı → Uzman), eskiden 9 seviyeli bir versiyon vardı, kullanıcı isterse geri getirilebilir

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

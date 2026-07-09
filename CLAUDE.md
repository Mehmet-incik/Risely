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
├── services/services.dart       → NotificationService (bildirim zamanlama + pil optimizasyonu muafiyeti, permission_handler kullanır) + TaskStore (ChangeNotifier, instance state, SharedPreferences ile kalıcılık — main.dart'ta ChangeNotifierProvider ile sağlanıyor)
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

Not: `TaskStore` ve `NotificationService` bilerek aynı dosyada (`services/services.dart`) tutuldu çünkü birbirlerine çapraz referans veriyorlar (TaskStore.getDailyMotivation → NotificationService.messages, NotificationService → TaskStore.userName) - ayırmak döngüsel import sorunu yaratırdı.

## Veri Yönetimi
`TaskStore` artık `ChangeNotifier` — instance state, `main.dart`'ta `ChangeNotifierProvider` ile sağlanıyor, `SharedPreferences` ile diskte JSON olarak saklanıyor. Ekranlar `context.watch<TaskStore>()` ile otomatik yeniden çiziliyor (Home/Stats/Calendar/Profile), mutasyonlar (`addTask`/`toggleTask`/`deleteTask`/`clearAllData` vb.) TaskStore içinde encapsulate. Eski `onTaskToggled` callback zinciri (main_screen.dart → ekranlar → showTaskForm) tamamen kaldırıldı. Detay: roadmap.md Faz 4.

## Sırada Ne Var
Detaylı, fazlara bölünmüş yol haritası artık **roadmap.md** dosyasında (proje kökünde) — uzun vadeli plan, "bitti" tanımları, riskler ve çapraz kurallar için oraya bakılmalı. Bu dosya sadece güncel özet için tutuluyor.

- **Faz 1 — Heatmap Takvim: TAMAMLANDI** (streak sistemi de dahil, bkz. Mevcut Özellikler)
- **Faz 2 — Bildirim Güvenilirliği: TAMAMLANDI** — pil optimizasyonu muafiyeti akışı eklendi (bkz. Mevcut Özellikler → Profil). Samsung J7 Pro (SM-J730F, Android 9) fiziksel cihazda ve Pixel 7 emülatöründe (zorla Doze modu + ekran kilitli + uygulama arka planda) test edildi: zamanlanmış görev hatırlatıcısı 3/3, sabah motivasyon bildirimi de doğrulandı.
- **Faz 3 — Mood Tracker: TAMAMLANDI** — günlük mood kaydı, heatmap'e Başarı/Ruh Hali geçiş anahtarı, üretkenlik-mood korelasyon kartı (bkz. Mevcut Özellikler). Pixel 7 emülatöründe uçtan uca test edildi.
- **Faz 4 — State Management Geçişi (Provider): DEVAM EDİYOR.** Tamamlanan: TaskStore `ChangeNotifier`'a çevrildi (static→instance), mutasyonlar encapsulate edildi (görev 2), `main.dart` `ChangeNotifierProvider` ile sarmalandı (görev 3), tüm ekranlar (Home→Stats→Calendar→Profile→TaskForm) tek tek `context.watch`'a geçirildi ve `onTaskToggled` callback zinciri kodda hiç kalmayacak şekilde tamamen söküldü — her ekran ayrı commit+push edildi (görev 4, `flutter analyze` 0 hata + emülatör duman testiyle doğrulandı). **Kalan:** görev 5 (`NotificationService`'i ayrı dosyaya taşıma — artık TaskStore instance olduğu için döngüsel bağımlılık sorunu çözülebilir), görev 6 (kapsamlı regresyon testi — bildirim kurma senaryosu bu oturumda test edilmedi), görev 7 (faz kapanışı: CLAUDE.md'nin bu bölümünü "TAMAMLANDI" yapmak + son push). Detay: roadmap.md Faz 4.
- **Faz 4 → 5 → 7 → 8 zinciri katıdır** (Provider geçişi → Firebase → Premium → Yayın), roadmap.md'de gerekçesiyle yazılı
- (Opsiyonel, düşük öncelik / Fikir Havuzu) `TaskStore.getUserLevelInfo()` şu an 5 seviyeli (Acemi Planlayıcı → Uzman), eskiden 9 seviyeli bir versiyon vardı, kullanıcı isterse geri getirilebilir

## Git / Kaynak Kontrolü
- GitHub: github.com/Mehmet-incik/Risely (main branch)
- Refactor commit + push tamamlandı, proje şu an temiz ve çalışır durumda
- Kullanıcı git workflow'unu biliyor: `git add .` → `git commit -m "..."` → `git push`

## İletişim Tercihleri
- Kullanıcı Türkçe konuşuyor, Türkçe yanıt ver
- Yeni başlayan bir geliştirici — teknik terimleri açıklayarak anlat, adım adım ilerle
- Android Studio kullanıyor (JetBrains/IntelliJ tabanlı), Windows üzerinde çalışıyor

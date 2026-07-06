# Risely - Proje Bağlamı

## Uygulama Hakkında
Risely, Türkçe bir alışkanlık takibi / görev planlama Android uygulaması (Flutter/Dart ile yazılıyor). Kullanıcı (Mehmet) yeni başlayan bir geliştirici, Türkçe iletişim tercih ediyor.

## Mevcut Özellikler (çalışıyor)
- **Login/Splash akışı**: LoginScreen (henüz gerçek auth yok, direkt SplashScreen'e geçiyor) → SplashScreen (roket animasyonu, bildirim/timezone kurulumu)
- **Ana Ekran (Home)**: Günaydın karşılaması, günün motivasyon mesajı, günlük başarı skor kartı (XP, yüzde), sabit/esnek görev listesi, gerçek zamanlı streak etiketi ("🔥 Seriye Başla!" / "🔥 N Günlük Seri!" / risk altındaysa "⚠️")
- **Streak (Seri) Sistemi**: `TaskStore.currentStreak` / `longestStreak` / `isStreakAtRisk` — görev verisinden (allTasks) türetilen computed getter'lar, ayrı bir persist alanı yok
- **Takvim**: Haftalık/Aylık/Yıllık görünüm sekmeleri (CupertinoSlidingSegmentedControl ile)
- **İstatistikler**: Heatmap takvimi (GitHub tarzı, son 17 hafta, 5 kademeli yoğunluk, dokununca gün detayı bottom sheet'i), Güncel Seri/En Uzun Seri kartları, tamamlanan/toplam görev, genel başarı oranı, kategori bazlı (Academic/Work/Community/Personal) ilerleme
- **Profil**: Avatar seçici, isim değiştirme, sabah motivasyon bildirimi saati kurma, karanlık/aydınlık mod, veri sıfırlama
- **Görev formu**: Görev ekleme/düzenleme, tarih/saat seçici (özel Samsung tarzı saat seçici widget'ı), kategori seçimi, görev bazlı bildirim hatırlatıcısı

## Proje Yapısı (main.dart'tan yakın zamanda bölündü - refactor tamamlandı)
```
lib/
├── main.dart                    → başlangıç noktası + RiselyApp (tema, dark mode)
├── app_colors.dart              → isDarkModeNotifier + AppColors (renk paleti)
├── models/task.dart             → Task modeli (id, title, time, category, date, hasReminder, isDone vb.)
├── services/services.dart       → NotificationService (bildirim zamanlama) + TaskStore (static state, SharedPreferences ile kalıcılık)
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
    └── heatmap_calendar.dart    → HeatmapCalendar (StatsScreen üstünde, TaskStore.getIntensityMapForLastDays kullanır)
```

Not: `TaskStore` ve `NotificationService` bilerek aynı dosyada (`services/services.dart`) tutuldu çünkü birbirlerine çapraz referans veriyorlar (TaskStore.getDailyMotivation → NotificationService.messages, NotificationService → TaskStore.userName) - ayırmak döngüsel import sorunu yaratırdı.

## Veri Yönetimi
Şu an **state management yok** — her şey `TaskStore` içinde `static` değişkenlerle tutuluyor, `SharedPreferences` ile diskte JSON olarak saklanıyor. Küçük ölçekte çalışıyor ama büyüdükçe (özellikle yeni özelliklerle) bir state management çözümüne (Provider, Riverpod vb.) geçiş düşünülebilir - şimdilik gerekli değil.

## Sırada Ne Var
Detaylı, fazlara bölünmüş yol haritası artık **roadmap.md** dosyasında (proje kökünde) — uzun vadeli plan, "bitti" tanımları, riskler ve çapraz kurallar için oraya bakılmalı. Bu dosya sadece güncel özet için tutuluyor.

- **Faz 1 — Heatmap Takvim: TAMAMLANDI** (streak sistemi de dahil, bkz. Mevcut Özellikler)
- **Sırada (Faz 1-2-3 arası sıra esnek):**
  - Faz 2: Bildirim Güvenilirliği (eski Android'de arka planda bildirim sorunu)
  - Faz 3: Mood Tracker (günlük ruh hali kaydı, heatmap altyapısını yeniden kullanır)
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

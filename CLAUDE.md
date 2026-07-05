# Risely - Proje Bağlamı

## Uygulama Hakkında
Risely, Türkçe bir alışkanlık takibi / görev planlama Android uygulaması (Flutter/Dart ile yazılıyor). Kullanıcı (Mehmet) yeni başlayan bir geliştirici, Türkçe iletişim tercih ediyor.

## Mevcut Özellikler (çalışıyor)
- **Login/Splash akışı**: LoginScreen (henüz gerçek auth yok, direkt SplashScreen'e geçiyor) → SplashScreen (roket animasyonu, bildirim/timezone kurulumu)
- **Ana Ekran (Home)**: Günaydın karşılaması, günün motivasyon mesajı, günlük başarı skor kartı (XP, yüzde), sabit/esnek görev listesi
- **Takvim**: Haftalık/Aylık/Yıllık görünüm sekmeleri (CupertinoSlidingSegmentedControl ile)
- **İstatistikler**: Tamamlanan/toplam görev, genel başarı oranı, kategori bazlı (Academic/Work/Community/Personal) ilerleme
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
└── widgets/samsung_time_picker.dart → SamsungStyleTimePicker
```

Not: `TaskStore` ve `NotificationService` bilerek aynı dosyada (`services/services.dart`) tutuldu çünkü birbirlerine çapraz referans veriyorlar (TaskStore.getDailyMotivation → NotificationService.messages, NotificationService → TaskStore.userName) - ayırmak döngüsel import sorunu yaratırdı.

## Veri Yönetimi
Şu an **state management yok** — her şey `TaskStore` içinde `static` değişkenlerle tutuluyor, `SharedPreferences` ile diskte JSON olarak saklanıyor. Küçük ölçekte çalışıyor ama büyüdükçe (özellikle yeni özelliklerle) bir state management çözümüne (Provider, Riverpod vb.) geçiş düşünülebilir - şimdilik gerekli değil.

## Sırada Ne Var (öncelik sırasıyla, kullanıcı ile üzerinde anlaşıldı)
1. **Streak (Seri) Sistemi** — ŞU AN BURADAYIZ. Ana ekranda "🔥 Seriye Başla!" etiketi zaten UI'da var ama arkasında gerçek mantık yok, sabit yazı. Yapılacaklar:
   - `currentStreak`, `longestStreak`, `lastCompletedDate` takibi (muhtemelen TaskStore içinde ya da ayrı bir StreakService)
   - Bir günde en az 1 görev tamamlanınca / hepsi tamamlanınca seri artışı mantığı (kullanıcıyla netleştirilmeli: "gün tamamlandı" ne demek?)
   - Bugün henüz görev tamamlanmadıysa ama dün tamamlanmışsa serinin "risk altında" olduğunu gösterme
   - SharedPreferences ile kalıcı hale getirme
   - Ana ekran etiketini gerçek sayıyla güncelleme (örn. "🔥 5 Günlük Seri!")
2. **Heatmap takvim** — GitHub tarzı, günlük başarı yoğunluğunu renk tonuyla gösteren görünüm (muhtemelen CalendarScreen'e ek bir sekme/görünüm olarak)
3. **Mood tracker** — günlük ruh hali kaydı
4. **Focus/Timer modu** — odaklanma süresi sayacı (arka planda çalışması gerekebilir, foreground service düşünülebilir)
5. (Opsiyonel, düşük öncelik) `TaskStore.getUserLevelInfo()` şu an 5 seviyeli (Acemi Planlayıcı → Uzman), eskiden 9 seviyeli bir versiyon vardı, kullanıcı isterse geri getirilebilir

## Git / Kaynak Kontrolü
- GitHub: github.com/Mehmet-incik/Risely (main branch)
- Refactor commit + push tamamlandı, proje şu an temiz ve çalışır durumda
- Kullanıcı git workflow'unu biliyor: `git add .` → `git commit -m "..."` → `git push`

## İletişim Tercihleri
- Kullanıcı Türkçe konuşuyor, Türkçe yanıt ver
- Yeni başlayan bir geliştirici — teknik terimleri açıklayarak anlat, adım adım ilerle
- Android Studio kullanıyor (JetBrains/IntelliJ tabanlı), Windows üzerinde çalışıyor

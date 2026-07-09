# RISELY — GELİŞTİRME YOL HARİTASI (roadmap.md)

> **Bu dosya nedir?** Risely projesinin uzun vadeli geliştirme planıdır. Proje sahibi (Mehmet) bu planı Claude Code / Claude Sonnet gibi modellerle birlikte yürütür. Bu dosyayı okuyan model, hiçbir ek bağlam olmadan projenin neresinde olunduğunu ve sırada ne olduğunu anlayabilmelidir. Dosyanın en sonundaki **"Bu Planı Nasıl Kullanmalısın"** bölümü, modeller için bağlayıcı talimatlar içerir.

---

## 0. PROJE KİMLİĞİ (Değişmez Bağlam)

- **Proje:** Risely — oyunlaştırılmış (gamified) alışkanlık takibi / görev planlama Android uygulaması
- **Hedef kitle:** Üniversite öğrencileri ve çalışan profesyoneller
- **Teknoloji:** Flutter/Dart, Android Studio, Windows geliştirme ortamı
- **Depo:** github.com/Mehmet-incik/Risely (branch: `main`)
- **Geliştirici profili:** Solo, yeni başlayan geliştirici; Claude Code ile iteratif ("vibe coding") çalışıyor; haftada **5-10 saat**; acil bitiş tarihi yok ama hız tercih ediliyor
- **Nihai hedef:** Önce kendisi ve yakın çevresi için kullanılabilir sürüm → sonra Google Play'de yayınlanabilir kalite → premium abonelik katmanı

### Mevcut mimari (bu plan yazıldığı andaki durum)
```
lib/
├── main.dart                    → başlangıç + RiselyApp (tema, dark mode)
├── app_colors.dart              → isDarkModeNotifier + AppColors
├── models/task.dart             → Task modeli
├── services/services.dart       → NotificationService + TaskStore (static state)
├── screens/ (login, splash, main, home, calendar, stats, profile, task_form)
└── widgets/samsung_time_picker.dart
```
- **Veri:** SharedPreferences (JSON) — bulut yok, hesap sistemi sahte (LoginScreen doğrudan geçiyor)
- **State management:** YOK — her şey `TaskStore` içinde static. Küçük ölçekte çalışıyor; buluta geçmeden önce değişmesi gerekiyor (bkz. Faz 4)
- **Bildirim:** flutter_local_notifications + timezone; `zonedSchedule` ile görev hatırlatıcıları
- **Bilinen açık sorun:** Samsung J7 Pro (Android 8.1) test cihazında zamanlanmış bildirimler ekran kapalıyken güvenilir tetiklenmiyor (bkz. Faz 2)

### Tamamlananlar (bu plana dahil DEĞİL, bitti)
Login/Splash akışı · Ana ekran (görev listesi, XP/başarı skoru) · Takvim (Haftalık/Aylık/Yıllık) · İstatistikler · Profil (avatar, bildirim saati, karanlık mod) · Görev formu (kategori, saat, hatırlatıcı) · Refactor (modüler dosya yapısı) · **Streak sistemi** (currentStreak, longestStreak, isStreakAtRisk — görev verisinden hesaplanan computed getter'lar)

---

## 1. FAZLARA GENEL BAKIŞ

| Faz | İçerik | Tahmini süre | Ön koşul |
|-----|--------|--------------|----------|
| 1 | Heatmap Takvim | 1-2 hafta | — (hemen başlanabilir) |
| 2 | Bildirim Güvenilirliği | 1-2 hafta | — (Faz 1'den bağımsız) |
| 3 | Mood Tracker | 1-2 hafta | Faz 1 önerilir (heatmap altyapısını yeniden kullanır) |
| 4 | State Management Geçişi (Provider) | 2-3 hafta | Faz 5'ten önce ZORUNLU |
| 5 | Firebase: Gerçek Hesap + Bulut Senkronizasyonu | 3 hafta | Faz 4 bitmeden BAŞLAMA |
| 6 | Focus/Timer Modu | 2 hafta | Faz 4 sonrası önerilir |
| 7 | Premium Altyapısı (IAP) + Özellik Kapıları | 2-3 hafta | Faz 5 bitmeden BAŞLAMA |
| 8 | Cila + Widget + Play Store Yayını | 2-3 hafta | Faz 7 sonrası |

> Haftada 5-10 saatle toplam kabaca **4-6 ay**. Fazlar 1-2-3 sırası esnektir (birbirinden bağımsız); **4 → 5 → 7 → 8 zinciri ise katıdır, sırası değiştirilemez.**

---

## FAZ 1 — HEATMAP TAKVİM (1-2 hafta)

**Amaç:** GitHub commit haritası tarzı, günlük başarı yoğunluğunu renk tonuyla gösteren görünüm. Streak sisteminin görsel devamı; motivasyon döngüsünü tamamlar.

**Görevler (sırayla):**
1. `TaskStore.getScoreForDate()` zaten var — gün başına 0-100 skor döndürüyor. Bunu 5 kademeli yoğunluk seviyesine (0: boş, 1-25, 26-50, 51-75, 76-100) çeviren bir yardımcı fonksiyon yaz.
2. Heatmap grid widget'ı oluştur: `widgets/heatmap_calendar.dart`. Son ~120 günü (yaklaşık 17 hafta × 7 gün) gösteren, `AppColors.xp` renginin opacity kademeleriyle boyanan kutucuklar.
3. Kutucuğa dokununca o günün tarih + skor + tamamlanan görev sayısını gösteren küçük bir tooltip/bottom sheet.
4. Yerleşim kararı: İstatistikler ekranının üstüne ekle (yeni sekme AÇMA — mevcut ekranı zenginleştir, navigasyonu şişirme).
5. Emülatörde test: geçmiş tarihli görevler ekleyip renklerin doğru kademelendiğini doğrula.
6. Commit + push: `feat: heatmap takvim eklendi`

**"Bitti" tanımı:** İstatistikler ekranında son ~4 ayı gösteren, dokununca gün detayı veren, karanlık/aydınlık modda düzgün görünen bir heatmap var ve GitHub'a push'landı.

**Riskler & B planı:**
- *Risk:* 120 günlük grid'de her kutucuk için `getScoreForDate()` çağrısı, görev sayısı arttıkça yavaşlayabilir (her çağrı tüm listeyi tarıyor). → *B planı:* Skorları tek geçişte hesaplayan bir `Map<DateTime, int>` üreten toplu fonksiyon yaz; yine yavaşsa hesaplamayı ekran açılışında bir kez yapıp sakla.
- *Risk:* Küçük ekranlarda grid taşar. → *B planı:* Yatay kaydırılabilir (SingleChildScrollView) yap, en güncel hafta sağda başlasın.

---

## FAZ 2 — BİLDİRİM GÜVENİLİRLİĞİ (1-2 hafta)

**Amaç:** Bilinen sorunun (eski Android'de ekran kapalıyken zamanlanmış bildirimlerin gelmemesi) kök nedenini bulup çözmek. **Bu faz, Play Store yayınından önce mutlaka kapanmalı** — bildirim, bir alışkanlık uygulamasının bel kemiğidir; güvenilmezse uygulama işlevini kaybeder.

**Görevler (sırayla):**
1. Teşhis: `AndroidManifest.xml`'de `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` izinlerini ve `RECEIVE_BOOT_COMPLETED` durumunu kontrol et.
2. `AndroidScheduleMode.exactAllowWhileIdle` kullanımını doğrula (kodda mevcut — cihazda gerçekten exact alarm izni verilmiş mi kontrol et; Android 12+ bu izni ayrıca istiyor).
3. Üretici pil optimizasyonu: Samsung'un agresif pil yönetimi bilinen bir sorundur. Uygulamayı pil optimizasyonundan muaf tutma isteği ekle (`ignoreBatteryOptimizations` akışı) ve/veya kullanıcıya profil ekranında "Bildirimler gelmiyorsa" rehber diyaloğu göster.
4. Cihazın yeniden başlatılması sonrası bildirimlerin kaybolduğunu doğrula/çöz: boot receiver ile yeniden zamanlama (flutter_local_notifications bunu kısmen kendisi yönetir — test et, eksikse tamamla).
5. İki cihazda test matrisi: Pixel 7 emülatörü (yeni Android) + Samsung J7 Pro (Android 8.1). Test senaryosu: bildirim kur → uygulamayı kapat → ekranı kilitle → bekle.
6. Commit + push: `fix: bildirim guvenilirligi iyilestirildi`

**"Bitti" tanımı:** Her iki test cihazında da, uygulama kapalı + ekran kilitliyken zamanlanmış bildirim en az 3/3 denemede geliyor. Gelmiyorsa nedeni belgelenmiş ve kullanıcıya rehber gösteriliyor.

**Riskler & B planı:**
- *Risk:* Android 8.1 + Samsung kombinasyonunda sorun OS seviyesinde çözülemeyebilir (üretici kısıtları). → *B planı:* Bunu kabul et, minimum desteklenen sürümü yükseltmeyi değerlendir (minSdk şu an 21) ya da eski cihazlarda "bildirimler gecikebilir" uyarısı göster. Mükemmeli kovalayıp fazda takılıp KALMA — 1-2 haftayı aşarsa belgeleyip devam et.
- *Risk:* Teşhis için çok sayıda gerçek cihaz denemesi gerekir, zaman yer. → *B planı:* Emülatörde Doze modunu simüle et: `adb shell dumpsys deviceidle force-idle`.

---

## FAZ 3 — MOOD TRACKER (1-2 hafta)

**Amaç:** Günlük ruh hali kaydı. Basit tutulmalı: günde 1 kayıt, 5'li emoji skalası (😞😕😐🙂😄), opsiyonel kısa not.

**Görevler (sırayla):**
1. `models/mood_entry.dart`: `MoodEntry {DateTime date, int score(1-5), String? note}` + toJson/fromJson.
2. `TaskStore`'a (ya da ayrı `MoodStore`'a) mood listesi + SharedPreferences kalıcılığı ekle. Görev verisiyle aynı deseni kullan (tutarlılık > yaratıcılık).
3. Ana ekrana günlük mood sorusu kartı: bugün kayıt yoksa "Bugün nasılsın?" kartı göster, kayıt varsa seçilen emojiyi minik göster (tekrar dokununca değiştirilebilir).
4. Heatmap entegrasyonu: Faz 1'deki heatmap widget'ını parametrik hale getir; İstatistikler'e ikinci bir heatmap (mood renkleri) ya da mevcut heatmap'e mood/başarı geçiş anahtarı ekle.
5. İstatistikler'e basit korelasyon kartı: "En üretken olduğun günlerdeki ortalama ruh halin: 🙂" gibi tek satırlık içgörü (karmaşık grafik YOK — bu premium'a malzeme, bkz. Premium Stratejisi).
6. Commit + push: `feat: mood tracker eklendi`

**"Bitti" tanımı:** Günde bir mood kaydedilebiliyor, uygulama yeniden başlatılınca korunuyor, heatmap'te/istatistikte görünüyor.

**Riskler & B planı:**
- *Risk:* Ana ekran kartlarla kalabalıklaşıyor. → *B planı:* Mood kartını kompakt tut (tek satır), kayıt sonrası küçült.
- *Risk:* Faz 1 yapılmadıysa heatmap entegrasyonu bloklanır. → *B planı:* Mood tracker heatmap OLMADAN da tamamlanabilir; entegrasyon adımını Faz 1 sonrasına ertele.

---

## FAZ 4 — STATE MANAGEMENT GEÇİŞİ: PROVIDER (2-3 hafta)

**Amaç:** Static `TaskStore`'dan `Provider` tabanlı (ChangeNotifier) mimariye geçiş. **Bu faz, Firebase'den (Faz 5) önce ZORUNLUDUR** — bulut senkronizasyonu "veri değişti → tüm dinleyenler güncellensin" akışı gerektirir; static değişkenlerle bu güvenilir kurulamaz ve `setState`/callback zincirleri (onTaskToggled) artık taşımaz.

**Neden Provider (Riverpod/Bloc değil)?** Yeni başlayan solo geliştirici için en düz öğrenme eğrisi, resmi Flutter dokümantasyonunda birinci sırada önerilen çözüm, mevcut `ValueListenableBuilder` (dark mode) deneyimiyle kavramsal olarak akraba. Karar verildi; model bu kararı yeniden AÇMASIN.

**Görevler (sırayla):**
1. `provider` paketini ekle. Önce SADECE oku/öğren: mevcut `TaskStore`'un hangi ekranlardan nasıl çağrıldığının haritasını çıkar (Claude Code'a çıkarttır).
2. `TaskStore`'u `ChangeNotifier`'a dönüştür: static üyeleri instance üyelerine çevir, veri değiştiren her metodun sonuna `notifyListeners()` ekle. Streak getter'ları aynen taşınır.
3. `main.dart`'ta `ChangeNotifierProvider` ile sarmala.
4. Ekranları TEK TEK geçir (hepsini birden DEĞİL): sıra önerisi Home → Stats → Calendar → Profile → TaskForm. Her ekran geçişinde `onTaskToggled` callback zincirinin o ekrana ait kısmını sök, `context.watch`/`Consumer` ile değiştir. **Her ekran geçişi ayrı commit.**
5. `NotificationService`'i ayrı dosyaya (`services/notification_service.dart`) taşı — TaskStore instance olunca döngüsel bağımlılık sorunu çözülebilir hale gelir; motivasyon mesajları listesini bağımsız bir sabite çıkar.
6. Regresyon testi: görev ekle/tamamla/sil, streak, tema değişimi, bildirim kurma — hepsi emülatörde elden geçir.
7. Commit + push: `refactor: provider tabanli state management`

**"Bitti" tanımı:** Kodda hiç static mutable state kalmadı, `onTaskToggled` callback zinciri tamamen söküldü, tüm mevcut özellikler regresyonsuz çalışıyor.

**Riskler & B planı:**
- *Risk:* En riskli faz — yarıda kalırsa kod iki dünyada (static + provider) asılı kalır. → *B planı:* Ekran-ekran geçiş + her ekranda ayrı commit bu riski yönetir; bir ekran bozulursa `git reset` ile sadece o adım geri alınır. Faz yarıdayken BAŞKA özellik geliştirme.
- *Risk:* Kavramlar (context.watch vs read, Consumer) kafa karıştırır. → *B planı:* Claude Code'a her değişiklikte "neden böyle" açıklaması yazdır; anlaşılmayan yerde ilerlemeden sor.

---

## FAZ 5 — FIREBASE: GERÇEK HESAP + BULUT SENKRONİZASYONU (3 hafta)

**Amaç:** Sahte LoginScreen'i gerçek Firebase Auth'a bağlamak ve görev/mood/ayar verisini Firestore ile senkronize etmek. **Premium'un teknik temeli budur** (bulut senkronizasyonu premium özellik olacak — ama altyapı herkes için kurulur, kapı Faz 7'de konur).

**Ön koşul: Faz 4 bitmiş olmalı. Bitmemişse bu faza BAŞLAMA.**

**Görevler (sırayla):**
1. Firebase projesi oluştur (console.firebase.google.com), `flutterfire configure` ile Android uygulamasını bağla. `google-services.json`'ın .gitignore'da olduğundan emin ol.
2. Firebase Auth: E-posta/şifre + "Misafir olarak devam et" (anonymous auth). Mevcut LoginScreen arayüzü zaten hazır — sadece `_submitForm`/`_continueAsGuest` fonksiyonlarını gerçek auth çağrılarına bağla. Hata durumları (yanlış şifre, zayıf şifre, kayıtlı e-posta) Türkçe mesajlarla ele alınmalı.
3. Firestore veri modeli: `users/{uid}/tasks/{taskId}` + `users/{uid}/moods/{entryId}` + `users/{uid}/settings`. Task.toJson zaten var — aynı şema kullanılır.
4. Senkronizasyon stratejisi (basit tut): **local-first**. SharedPreferences birincil kalır (offline çalışma bedava); her yazma işlemi arka planda Firestore'a da yazar; girişte Firestore'dan çekilip yerel ile birleştirilir (son yazan kazanır — last-write-wins; çakışma çözümü karmaşıklaştırma).
5. Misafir → kayıtlı hesap geçişi: anonymous hesabı e-posta hesabına yükseltme (linkWithCredential) — misafir verisi kaybolmamalı.
6. Güvenlik kuralları: Firestore rules ile her kullanıcı yalnız kendi verisini okuyup yazabilsin.
7. Test: iki emülatörde aynı hesapla giriş yapıp verinin taşındığını doğrula; uçak modunda çalışmayı doğrula.
8. Commit + push: `feat: firebase auth ve bulut senkronizasyonu`

**"Bitti" tanımı:** Gerçek hesapla kayıt/giriş çalışıyor, misafir modu çalışıyor, veri iki cihaz arasında taşınıyor, offline'da uygulama tam işlevsel.

**Riskler & B planı:**
- *Risk:* Faz büyük; 3 haftayı aşabilir. → *B planı:* Böl: 5a = sadece Auth (1 hafta), 5b = sadece senkronizasyon (2 hafta). 5a bitince commit'le, ara verilebilir.
- *Risk:* Senkronizasyon çakışmaları veri kaybettirir. → *B planı:* Last-write-wins bilinçli bir basitleştirmedir; solo kullanıcı senaryosunda (tek kişi, birden çok cihaz) yeterlidir. Veri kaybı raporlanırsa timestamp bazlı birleştirmeye geç.
- *Risk:* Firebase ücretsiz kotası aşılır. → *B planı:* Spark (ücretsiz) plan bu ölçek için fazlasıyla yeter; okuma sayısını azaltmak için girişte tek seferlik çekme (sürekli dinleme/stream YOK).

---

## FAZ 6 — FOCUS/TIMER MODU (2 hafta)

**Amaç:** Pomodoro tarzı odaklanma sayacı. Temel sürüm herkese; gelişmiş istatistikler premium'a (Faz 7).

**Görevler (sırayla):**
1. Basit tam ekran timer ekranı: süre seç (25/45/60 dk presetleri), başlat/duraklat/bitir; bitince yerel bildirim + titreşim.
2. Uygulama arka plana alınınca sayacın doğru devam etmesi: bitiş zamanını (timestamp) kaydet, ekrana dönünce kalan süreyi hesapla (sürekli çalışan arka plan servisi KURMA — bu aşamada gereksiz karmaşıklık; bitiş bildirimi zonedSchedule ile kurulur).
3. Tamamlanan odak seansını kaydet: `FocusSession {date, durationMinutes, taskId?}` — opsiyonel olarak bir göreve bağlanabilir.
4. Ana ekrana/görev kartına küçük "odaklan" kısayolu.
5. İstatistikler'e "bu hafta toplam odak süresi" tek kartı (detaylı döküm premium'a saklanır).
6. Commit + push: `feat: focus timer modu`

**"Bitti" tanımı:** Timer arka plana alınsa/ekran kilitlense bile doğru sayıyor, bitince bildirim geliyor, seanslar kaydedilip haftalık toplam görünüyor.

**Riskler & B planı:**
- *Risk:* "Arka planda gerçek servis" tavşan deliğine girilir (foreground service, izinler...). → *B planı:* Timestamp yaklaşımı %95 ihtiyacı karşılar; canlı geri sayım bildirimi (chronometer notification) istenirse ancak her şey bitince "cila" olarak dene.

---

## FAZ 7 — PREMIUM ALTYAPISI + ÖZELLİK KAPILARI (2-3 hafta)

**Amaç:** Google Play In-App Purchase (abonelik) entegrasyonu ve premium özelliklerin kapılanması. **Ön koşul: Faz 5 bitmiş olmalı** (bulut senkronizasyonu ana premium vaadi olduğundan, satacak şeyin önce var olması gerekir).

**Görevler (sırayla):**
1. Google Play Console hesabı aç (tek seferlik ~25$ ücret) ve uygulamayı **internal testing** kanalına yükle — IAP test etmek için uygulamanın konsolda tanımlı olması ŞARTTIR, bu yüzden bu adım en başta.
2. Konsolda abonelik ürünlerini tanımla: `risely_premium_monthly` ve `risely_premium_yearly` (yıllıkta indirim). Fiyat önerisi: pazar araştırması yap ama başlangıç için aylık 1-2$ bandı makul; sonradan artırmak zor, düşürmek kolay — düşükten başla.
3. `in_app_purchase` paketini entegre et: ürünleri listele, satın alma akışı, satın alma geri yükleme (restore purchases — Play hesabından doğrulama).
4. `PremiumService` (ChangeNotifier): `isPremium` durumunu tutar; SharedPreferences'a önbelleklenir, açılışta Play'den doğrulanır.
5. Özellik kapıları (feature gating): premium kontrolü TEK bir yerden yapılmalı (`if (premiumService.isPremium)`) — koşulları ekranlara dağıtma. Kapılanan özellikler için "kilit" rozeti + dokununca paywall ekranı.
6. Paywall ekranı: premium faydalarını listeleyen, aylık/yıllık seçenekli, sade bir satış ekranı. Karanlık desenler YOK (otomatik yenileme açıkça yazılır, kapatma butonu görünür).
7. Streak Freeze özelliği (premium): ayda 2 hak; bir gün görev tamamlanmazsa otomatik kullanılır, streak hesaplamasına "dondurulmuş gün" kavramı eklenir.
8. Test: Play Console'un lisans test hesaplarıyla satın alma/iptal/geri yükleme senaryoları.
9. Commit + push: `feat: premium abonelik altyapisi`

**"Bitti" tanımı:** Test hesabıyla abonelik satın alınabiliyor, isPremium doğru yansıyor, kapılar çalışıyor, geri yükleme çalışıyor, iptal senaryosu doğru işliyor.

**Riskler & B planı:**
- *Risk:* IAP test süreci meşakkatlidir (konsol onayları, test hesapları, saatler süren yayılma gecikmeleri). → *B planı:* Bu fazın takvimine baştan +%50 tampon koy; konsol beklerken başka fazın işini yap.
- *Risk:* Sunucu taraflı doğrulama (receipt validation) yok — teknik olarak kandırılabilir. → *B planı:* Bu ölçekte kabul edilebilir risk; ileride ciddi gelir olursa Firebase Cloud Functions ile doğrulama eklenir. Şimdi KURMA.

---

## FAZ 8 — CİLA + WIDGET + PLAY STORE YAYINI (2-3 hafta)

**Amaç:** Yayınlanabilir kalite ve mağaza süreci.

**Görevler (sırayla):**
1. Ana ekran widget'ı (premium): bugünün görev sayısı + streak gösteren basit Android widget (`home_widget` paketi). Widget teknik olarak ayrı bir dünya — basit tut, tek boyut yeter.
2. Teknik temizlik: `withOpacity` deprecated uyarılarını topluca `withValues()` ile değiştir; `flutter analyze` sıfır uyarıya yaklaşsın.
3. Görsel cila: boş durum ekranları, yükleme durumları, hata mesajları; uygulama ikonu son hali; splash ekranı süresi.
4. Onboarding gözden geçirme: TutorialOverlay'i yeni özellikleri (heatmap, mood, timer) kapsayacak şekilde güncelle.
5. Mağaza varlıkları: ekran görüntüleri (en az 4), kısa/uzun açıklama (Türkçe + İngilizce), gizlilik politikası sayfası (Firebase kullandığın için ZORUNLU — ücretsiz üreteçlerle hazırlanıp GitHub Pages'te barındırılabilir).
6. Data Safety formu (Play Console): Firebase Auth/Firestore'un topladığı veriler beyan edilir.
7. Internal testing → closed testing (yakın çevre davet edilir, geri bildirim toplanır, min. Google'ın istediği test süresi beklenir) → production.
8. Commit + push + sürüm etiketi: `release: v1.0.0`

**"Bitti" tanımı:** Uygulama Play Store'da yayında (ya da en azından closed testing'de gerçek kullanıcılarla) ve kritik hata raporu yok.

**Riskler & B planı:**
- *Risk:* Yeni geliştirici hesaplarında Google, üretime geçmeden önce belirli sayıda test kullanıcısı ve gün şartı koyuyor (politikaları değişken). → *B planı:* Closed testing şartlarını Faz 8'in BAŞINDA kontrol et; şart uzunsa closed testing'i Faz 7 biter bitmez başlat, cila işlerini test süresi işlerken yap.
- *Risk:* Widget beklenenden zor çıkar. → *B planı:* Widget v1.0'dan çıkarılabilir — yayını BLOKLAMASIN, v1.1'e ertelenir.

---

## 2. PREMIUM ÖZELLİKLER STRATEJİSİ

### İlke
Ücretsiz sürüm **tek başına tam ve tatmin edici** olmalı: görev takibi, streak, temel istatistik, bildirimler, mood, temel timer ücretsizde kalır. Premium; *sınırlama satmaz, güç satar* — kullanıcının sevdiği uygulamanın "daha fazlasını" sunar. Var olan ücretsiz bir özelliği sonradan paraya kilitleme (güven kaybının en hızlı yolu).

### Katman tablosu

| Özellik | Ücretsiz | Premium |
|---------|----------|---------|
| Görev ekleme/takip, kategoriler (mevcut 4) | ✔ Sınırsız | — |
| Streak sistemi | ✔ | + Streak Freeze (ayda 2 hak) |
| Heatmap (son 4 ay) | ✔ | + Tüm zamanlar görünümü |
| Mood tracker (günlük kayıt) | ✔ | + Mood-üretkenlik detay grafikleri |
| İstatistikler (temel) | ✔ | + Gelişmiş raporlar, PDF/CSV dışa aktarma |
| Bildirimler (görev + sabah motivasyonu) | ✔ | + Çoklu/akıllı hatırlatıcılar |
| Focus timer (temel + haftalık toplam) | ✔ | + Seans geçmişi, detaylı döküm, özel döngüler |
| Bulut senkronizasyonu & çoklu cihaz | — | ✔ (ana satış vaadi) |
| Özel kategori oluşturma, tekrarlayan görev şablonları | — | ✔ |
| Ek tema/avatar paketleri | — | ✔ |
| Ana ekran widget'ı | — | ✔ |

> Not: Firebase **hesabı** (giriş/kayıt) herkese açıktır — hesap ücretsiz, *senkronizasyon* premium. Böylece misafir→hesap geçişi ve ileride sosyal özellikler için taban hazır olur.

### Zamanlama
- **Faz 5:** Teknik altyapı (Firebase) kurulur — henüz kapı yok, kendin test edersin.
- **Faz 7:** IAP + kapılar + paywall. Premium burada "açılır".
- **Faz 8:** Yayın; ilk kullanıcı geri bildirimine göre katman tablosu revize edilebilir (tabloyu taşa yazma).

### Güven kuralları
1. Paywall dürüst olsun: fiyat, yenileme, iptal açıkça yazsın.
2. "Premium'a geç" dürtmesi günde en fazla bir bağlamsal noktada (örn. kilitli özelliğe dokununca) — rastgele pop-up YOK.
3. Premium olmayan kullanıcının verisi asla rehin tutulmaz (yerel veri her zaman erişilebilir).

---

## 3. ÇAPRAZ KURALLAR (Her Fazda Geçerli)

1. **Git disiplini:** Her mantıksal iş ayrı commit; her faz sonunda push. Faza başlamadan önce çalışan durum commit'lenmiş olmalı (`git status` temiz).
2. **Test cihazları:** Pixel 7 emülatörü (birincil) + mümkünse Samsung J7 Pro (eski Android gerçekliği).
3. **`flutter analyze`** her fazın kapanışında çalıştırılır; YENİ error sıfır olmalı (mevcut deprecated info'ları Faz 8'e kadar tolere edilir).
4. **CLAUDE.md güncellemesi:** Her faz bittiğinde CLAUDE.md'deki "Mevcut durum" ve "Sırada ne var" bölümleri güncellenir — bu, gelecek oturumların doğru başlaması için kritik.
5. **Kapsam sürünmesine karşı:** Faz ortasında akla gelen yeni fikirler koda değil, bu dosyanın en altındaki "Fikir Havuzu"na yazılır.

---

## 4. FİKİR HAVUZU (Plansız, İleride Değerlendirilecek)

- 9 seviyeli rütbe sistemine dönüş (eski kodda vardı: Acemi Planlayıcı → ... → 9 seviye)
- iOS sürümü
- Arkadaşlarla streak yarışması / sosyal özellikler
- Yapay zeka destekli görev önerileri
- Google ile oturum aç (Google Sign-In) — Faz 5 sırasında akla geldi (2026-07-09), e-posta/şifre + misafirden daha az sürtünmeli olabilir ama SHA-1 sertifika parmak izi kaydı + `google_sign_in` paketi + LoginScreen'e yeni buton gerektiriyor; Faz 5 çekirdeği bitmeden kapsamı büyütmemek için ertelendi

---

## 5. BU PLANI NASIL KULLANMALISIN (Modeller İçin Talimatlar)

Bu dosyayı okuyan model (Claude Code, Sonnet vb.) şu kurallara uyar:

1. **Konum tespiti:** Önce kullanıcıya hangi fazda olunduğunu sor ya da CLAUDE.md / git log'dan çıkar. Emin değilsen SOR, varsayma.
2. **Sıra bağlayıcıdır:** 4 → 5 → 7 → 8 zinciri değiştirilemez. Kullanıcı sıra dışı bir istek getirirse (örn. Faz 4 bitmeden Firebase), bu dosyadaki gerekçeyi hatırlat ve onay iste — kullanıcı bilinçli olarak ısrar ederse uygula, ama riski açıkça söyle.
3. **Faz içi görev sırası** önerilen sıradır; teknik zorunluluk yoksa küçük sapmalar serbesttir.
4. **"Bitti" tanımı karşılanmadan** faz kapanmış sayılmaz; kapanışta commit + push + CLAUDE.md güncellemesi yapılır/yaptırılır.
5. **Kapsamı koru:** Fazda yazmayan bir özellik istenirse önce "Fikir Havuzu"na eklemeyi öner; kullanıcı şimdi istiyorsa mevcut faza etkisini (süre/risk) belirtip onayla ilerle.
6. **Alınmış mimari kararları yeniden açma:** Provider (Riverpod değil), local-first senkronizasyon (last-write-wins), sunucu taraflı receipt doğrulaması YOK (şimdilik), Firebase (özel backend değil). Bu kararların gerekçeleri ilgili fazlarda yazılıdır.
7. **Kullanıcı profili:** Yeni başlayan bir geliştiriciyle Türkçe çalışıyorsun; değişikliklerin "neden"ini kısa da olsa açıkla; tam ve çalışır kod ver, yarım bırakma.
8. **Bu dosya yaşayan belgedir:** Faz gerçekliği değişirse (süre aşımı, kapsam değişikliği) kullanıcının onayıyla dosyayı güncelle — plan gerçeği yansıtmıyorsa değersizleşir.

---

*Bu roadmap, projenin o günkü durumuna ve hedeflerine göre Claude (Fable 5) ile hazırlanmıştır. Son güncelleme: 6 Temmuz 2026.*

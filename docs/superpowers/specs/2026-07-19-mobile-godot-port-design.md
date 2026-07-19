# Dodge Trainer Mobile — Godot/Android Port Tasarımı

Tarih: 2026-07-19
Durum: Kullanıcı onayladı (klasör kararıyla birlikte)

## Amaç

Mevcut tarayıcı tabanlı Phaser 3 dodge trainer oyununu Godot 4.x ile sıfırdan,
Android/Google Play hedefli olarak yeniden yapmak; reklam (AdMob) ve
"sonsuza kadar reklamsız" satın alması (Google Play Billing) ile
gelirlendirmek. iOS ilk sürümde kapsam dışı, ama kod iOS'a sonradan
taşınabilecek şekilde ayrıştırılır.

## Yer ve araçlar

- Godot projesi bu reponun içinde **`godot/`** alt klasöründe yaşar
  (Godot'da "Import" ile bu klasör gösterilir). Mevcut Phaser web sürümü
  repo kökünde olduğu gibi kalır.
- Godot 4.x, GDScript. Yatay (landscape) 1280×720 taban çözünürlük,
  `canvas_items` stretch ile her ekrana ölçeklenir.
- Reklam eklentisi: poing-studios **godot-admob-plugin**.
- IAP eklentisi: resmi **godot-google-play-billing**.

## Oyunun birebir taşınan kısmı

- Akış: ana menü → zorluk seçimi (EASY / NORMAL / HARD) → oyun → ölüm ekranı
  (RETRY / MENU).
- Oyuncu: sabit hızla hedefe yürüyen daire + sahte perspektif gölge elipsi.
- Mermiler: **bolt** (kenardan oyuncuya doğru düz giden top, hedefe rastgele
  açı sapması) ve **beam** (ince kırmızı telegraf çizgisi → 1 sn sonra aynı
  eksende kalın beyaz anlık ışın, kısa hasar penceresi).
- Spawner: zorluk başına spawn aralığı, minimum aralık, saniye başına
  hızlanma (ramp), mermi hızı, nişan sapması — mevcut `config.js`
  değerleriyle aynı.
- HUD: süre + kaçırılan mermi sayısı. Skor = hayatta kalma süresi + dodge.
- Tüm ayar değerleri tek dosyada: **`Config.gd`** autoload'u
  (`config.js`'in karşılığı; ayarlar asla başka dosyaya gömülmez).

## Mobil değişiklikleri

- **Dokunma = hareket emri** (sağ tık yerine). Yeşil hedef işareti korunur.
- Klavye yok; S-dur tuşu kaldırıldı (durmak için oyuncu olduğu yere dokunur).
- Yön: sadece landscape; export ayarında kilitlenir.

## Gelirlendirme

### Zorunlu reklam (interstitial)
- **Her 3 ölümde bir**, ölüm ekranından sonra tam ekran reklam; sayaç sıfırlanır.
- **Açılış merhameti:** uygulamanın her açılışından sonraki ilk **5 dakika**
  hiç zorunlu reklam gösterilmez (ölüm sayacı işler ama gösterim 5 dakika
  dolmadan başlamaz).
- Reklamsız satın alan kullanıcıya hiç gösterilmez.

### Ödüllü reklam (rewarded) — ikisi de sonuna kadar izlenince ödül verir
- **Diriliş:** ölüm ekranında "Reklam izle, devam et" — süre ve skor korunur,
  oyuncu aynı yerde kısa dokunulmazlıkla devam eder. **Tur başına 1 kez.**
- **Kalkan:** ana menüde "Reklam izle, kalkanla başla" — sonraki tur 1
  kalkanla başlar; ilk isabet öldürmez, kalkanı kırar ve kısa dokunulmazlık
  verir.
- Ödüllü reklamlar reklamsız satın almadan **etkilenmez** (opsiyonel kalır).

### Reklamsız satın alma (IAP)
- Google Play Billing, **non-consumable** ürün `remove_ads`, **4.99 USD**.
- Sadece zorunlu reklamları kaldırır.
- Açılışta Google Play'den mevcut satın almalar sorgulanır (cihaz
  değişse/uygulama silinse bile otomatik geri yükleme); ayrıca `user://`
  altında yerel olarak da saklanır.

## Kod mimarisi

- Sahneler: `Menu`, `Difficulty`, `Game`, `GameOver` (Godot scene'leri).
- Autoload singleton'ları:
  - `Config.gd` — tüm oyun ayarları.
  - `Ads.gd` — AdMob sarmalayıcı: `show_interstitial_if_due()`,
    `show_rewarded(kind, callback)`; ölüm sayacı ve 5 dk merhamet mantığı
    burada. Editörde/desteklenmeyen platformda sessizce hiçbir şey yapmaz
    (oyun reklamsız test edilebilir).
  - `IAP.gd` — Billing sarmalayıcı: `is_ad_free()`, `purchase_remove_ads()`,
    açılış sorgusu. Editörde sahte (her zaman reklamlı) davranır.
- Oyun sahneleri para tarafını bilmez; sadece `Ads`/`IAP` singleton'larının
  arayüzünü çağırır. iOS ileride sadece bu iki dosyanın altındaki eklenti
  değişerek eklenir.

## Hata durumları

- Reklam yüklenemezse (ağ yok vb.): zorunlu reklam sessizce atlanır (oyuncu
  bekletilmez); ödüllü reklam butonları pasif görünür.
- IAP sorgusu başarısızsa: son bilinen yerel değer kullanılır.

## Test / aşamalar

1. Oyunun Godot'da masaüstünde birebir çalışır hali (reklamsız).
2. Android export + gerçek telefonda dokunmatik test.
3. AdMob **test reklam ID'leriyle** reklam akışı (gerçek ID'ler yayında).
4. Play Console iç test kanalında IAP testi.
5. Yayın: Google Play geliştirici hesabı (25 USD), AdMob hesabı, gizlilik
   politikası sayfası, data safety formu.

## Kapsam dışı (ilk sürüm)

- iOS / App Store.
- Skor tablosu, yeni mermi türleri, ses/müzik, banner reklam.
- Portrait yön desteği.

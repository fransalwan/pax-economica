# Steam v1.0 Release & Engineering Checklist

Dokumen ini merangkum standar arsitektur dan *pipeline* yang diterapkan di **Pax Economica** agar siap dirilis ke **Steam (v1.0)** tanpa *refactoring* besar di akhir pengembangan.

---

## 1. Standar Arsitektur Teknis (Steam-Ready by Default)

1. **Pemisahan Save Data & Konfigurasi Lokal (`user://`):**
   - `user://saves/` -> Disinkronkan ke **Steam Auto-Cloud** (format ber-versi `save_version` agar aman terhadap *patch* baru).
   - `user://settings.cfg` -> **Tidak** disinkronkan ke Cloud agar resolusi layar, *fullscreen mode*, dan pengaturan grafis spesifik perangkat (PC Desktop vs Laptop/Steam Deck) tidak saling menimpa.
2. **Abstraksi `SteamManager` (GodotSteam GDExtension):**
   - Berjalan menggunakan *Safe Fallback Pattern*: Jika aplikasi Steam aktif dan `GodotSteam` terpasang, fitur *Overlay*, *Achievements*, *Rich Presence*, dan *Stats* menyala otomatis. Jika dijalankan langsung dari editor tanpa Steam, game tetap berjalan normal (*Standalone Mode*).
3. **Responsive Layout & Multi-Aspect Ratio:**
   - Mendukung penuh `16:9` (1080p/1440p/4K), `16:10` (1280x800 Steam Deck), dan `21:9` (Ultrawide) dengan fitur **UI Scale Slider (80% – 150%)**.
4. **Internationalization (i18n):**
   - Seluruh teks UI menggunakan kunci lokalisasi (`localization/*.csv`) untuk mendukung Bahasa Indonesia (`id`) dan Bahasa Inggris (`en`) sejak awal.

---

## 2. Spesifikasi Aset Storefront & Library Steam

### Store Capsules (`steam/store_assets/`)
- **Header Capsule:** `920 x 430 px`
- **Small Capsule:** `462 x 174 px`
- **Main Capsule:** `1232 x 706 px`
- **Vertical Capsule:** `748 x 896 px`
- **Screenshots:** Minimal 5 gambar (`1920 x 1080 px`, 100% tampilan in-game).
- **Trailer:** `1920 x 1080 px` MP4 (H.264, 60fps).

### Library Assets (`steam/store_assets/`)
- **Library Capsule:** `600 x 900 px`
- **Library Header:** `920 x 430 px`
- **Library Hero:** `3840 x 1240 px` (Tanpa teks/logo)
- **Library Logo:** `1280 x 720 px` (PNG transparan)
- **Client Icon:** `.ico` (`16x16` s/d `256x256`) & `.png` (`32x32`)

---

## 3. Deployment Pipeline (`steam/app_build/`)
- Export *build* Windows (`x86_64`) dan Linux (`x86_64`) dari Godot 4.
- Unggah ke depot Steam menggunakan `steamcmd` dengan skrip konfigurasi `.vdf` di dalam `steam/app_build/`.


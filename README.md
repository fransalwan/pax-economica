# Pax Economica 🏛️📈

**Pax Economica** adalah game *Grand Strategy & Macroeconomic Simulator* berbasis peta (*map-painter*) yang dibangun menggunakan **Godot Engine 4.x**. Game ini dirancang khusus untuk melatih intuisi dan kemampuan analisis makroekonomi dengan membangun peradaban/kekaisaran melalui kebijakan moneter, fiskal, produksi sisi penawaran (*supply-side*), dan perdagangan internasional dalam sistem ekonomi tertutup/semi-tertutup (*closed/semi-closed monetary loop*).

Seluruh arsitektur proyek ini dirancang sejak awal agar **Steam-Ready (v1.0)**—mendukung *Steam Auto-Cloud*, *GodotSteam (Achievements & Rich Presence)*, *Multi-Resolution/UI Scaling*, dan *Localization (i18n)*.

---

## 🚀 Cara Menjalankan Game & Editor

1. **Jalankan Game Langsung:**
   Klik 2x file **`run_game.bat`** di direktori utama proyek (atau buka proyek di Godot 4 lalu tekan `F5`).
2. **Buka di Godot Editor:**
   Klik 2x file **`open_editor.bat`** (atau *Import* file `project.godot` melalui Godot Engine 4.x).
3. **Jalankan Pengujian Otomatis (Headless Simulation Test):**
   ```powershell
   godot --headless --path . -s res://tests/simulation/MacroSimulationTest.gd
   ```

---

## 🎓 Panduan Demo Interaktif (In-Game Guided Tour)

Di bagian tengah-atas layar permainan terdapat panel **Asisten Ekonom & Panduan Demo Interaktif** dengan tombol eksekusi otomatis (**`⚡ Demo Otomatis`**) untuk mempelajari mekanika makroekonomi secara langsung:

1. **Demo 1/4 — Ekspansi Produksi Riil (*Supply-Side Growth*):**
   Meng-*upgrade* Infrastruktur logistik dan pabrik komoditas unggulan di Ibu Kota (**★ Sunda Kalapa**) untuk meningkatkan **PDB Riil** (output fisik) dan menurunkan pengangguran.
2. **Demo 2/4 — Eksperimen Cetak Uang (*Quantity Theory of Money $M \cdot V = P \cdot Y$*):**
   Mencetak uang baru (*Quantitative Easing / Seigniorage*) sebesar `+50K` ke Kas Negara dan mengamati lonjakan **Indeks Harga Konsumen (CPI) & Laju Inflasi** pada grafik *time-series*.
3. **Demo 3/4 — Jinakkan Inflasi dengan Suku Bunga (*Volcker Shock*):**
   Menaikkan **Suku Bunga Acuan (*Policy Rate*)** Bank Sentral ke `11%` dan menyerap likuiditas (*Quantitative Tightening*) untuk memperlambat *Velocity of Money* ($V$) dan menurunkan tekanan inflasi.
4. **Demo 4/4 — Simulasi Krisis Makroekonomi (*Crisis Lab*):**
   Memicu guncangan ekonomi nyata (*Supply-Side Stagflation Shock*, *Dutch Disease*, atau *Sovereign Debt Spiral*) dan melakukan intervensi kebijakan untuk menstabilkan kembali peradaban.

---

## ⌨️ Kontrol & Shortcut Permainan

| Tombol / Input | Fungsi |
| :--- | :--- |
| **Klik Kiri pada Peta** | Memilih provinsi & membuka detail demografi/produksi di Panel Kiri |
| **`WASD` / Panah / Klik Kanan + Geser** | Menggeser kamera peta (*Pan*) |
| **Scroll Mouse** | Memperbesar / memperkecil tampilan peta (*Zoom In / Out*) |
| **`Space`** | *Pause / Play* simulasi waktu |
| **`1` / `2` / `3`** | Mengatur kecepatan simulasi (`1x`, `2x`, `5x`) |
| **`F1`** | Mode Peta Politik (*Political Map Mode*) |
| **`F2`** | Heatmap PDB Provinsi (*Provincial GDP Heatmap*) |
| **`F3`** | Heatmap Kesejahteraan Populasi (*Standard of Living / SoL*) |
| **`F4`** | Heatmap Tingkat Pengangguran (*Unemployment Heatmap*) |
| **`F5`** | Heatmap Efisiensi Infrastruktur (*Infrastructure Heatmap*) |

---

## 🎯 Core Gameplay & Rumus Makroekonomi

1. **Produksi Riil & Pembentukan Harga Dinamis:**
   - Fungsi produksi berbasis *Cobb-Douglas* ($Y = A \cdot K^\alpha \cdot L^{1-\alpha} \cdot I_{eff}$) yang dipengaruhi infrastruktur provinsi, tenaga kerja, dan modal.
   - Harga komoditas bergerak dinamis mengikuti rasio *Supply/Demand*, PPN (*VAT*), dan jumlah uang beredar (*Monetary Multiplier* $\frac{M \cdot V}{Y_{real}}$).
2. **Akuntansi Nasional (GDP & CPI):**
   - Perhitungan **Nominal GDP** ($C + I + G + NX$), **Real GDP**, serta **Indeks Harga Konsumen (CPI)** dan laju **Inflasi ($\pi$)** secara *real-time*.
3. **Bank Sentral & Kebijakan Moneter:**
   - Kendalikan **Suku Bunga Acuan (*Policy Rate*)** untuk meredam inflasi atau memacu investasi swasta, serta kelola pencetakan uang (*QE*) dan penyerapan likuiditas (*QT*).
4. **Kebijakan Fiskal, Pasar Obligasi (*Bond Yields*), & Risiko Default:**
   - Atur struktur pajak (*Income Tax*, *Corporate Tax*, *VAT/PPN*, *Tariffs*), belanja infrastruktur, subsidi kesejahteraan, dan rasio *Debt-to-GDP* dengan imbal hasil surat utang (*Bond Yield*) yang bereaksi terhadap risiko gagal bayar.
5. **Perdagangan Internasional & Nilai Tukar (*FX Rate*):**
   - Arbitrase perdagangan otomatis antar-kekaisaran (**Kekaisaran Nusantara**, **Persemakmuran Mercia**, **Imperium Borealis**) berdasarkan keunggulan komparatif dan pergerakan nilai tukar mata uang (*Floating FX Rate*).

---

## 📂 Struktur Folder Proyek

```text
pax-economica/
├── addons/                     # Plugin pihak ketiga (misal: GodotSteam GDExtension)
├── assets/                     # Aset visual, audio, font, dan tekstur peta
├── data/                       # Definisi data statis (Komoditas, Negara, Provinsi, Skenario)
├── docs/                       # Dokumentasi teknis & desain
│   ├── GAME_DESIGN.md          # Blueprint rumus ekonomi & arsitektur fitur end-to-end
│   └── STEAM_RELEASE.md        # Checklist & standar engineering rilis Steam v1.0
├── localization/               # File terjemahan multi-bahasa (.csv / .po - ID & EN)
├── src/                        # Source code GDScript & Shaders
│   ├── autoload/               # Singletons (EventBus, SimulationClock, WorldEconomy, SteamManager, SaveManager, SettingsManager)
│   ├── core/                   # Logika simulasi murni (CommodityData, Market, Nation, Province)
│   ├── map/                    # Sistem peta interaktif (MapView, MapCamera, map_province.gdshader)
│   ├── scenes/world/           # Scene utama penggabung MapView + MapCamera + MacroHUD
│   ├── ui/                     # Antarmuka pengguna (MacroHUD, LineChart time-series widget)
│   └── utils/                  # Helper functions (FormatUtils untuk mata uang, %, populasi)
├── steam/                      # Konfigurasi & aset distribusi Steamworks
│   ├── achievements/           # Metadata Steam Achievements (achievements.json)
│   ├── app_build/              # Template skrip SteamPipe (app_build_template.vdf)
│   └── store_assets/           # Tempat penyimpanan Capsule & Library artwork
├── tests/                      # Pengujian otomatis (MacroSimulationTest.gd)
├── open_editor.bat             # Shortcut membuka project di Godot Editor
├── run_game.bat                # Shortcut menjalankan game secara langsung
└── project.godot               # Konfigurasi utama Godot Engine 4
```

---

## 🗺️ Roadmap Menuju Steam v1.0

- [x] **Phase 1 — Core Macroeconomic Engine & Analytical Dashboard:**
  Implementasi *Tick Clock*, model data `Nation`/`Province`/`Market`, kalkulasi *GDP/CPI/Interest Rate/Bond Yield*, serta komponen grafik *LineChart* multi-kurva.
- [x] **Phase 2 — Interactive Map, Shader Pipeline, & Guided UX:**
  Implementasi *Color-ID Lookup Map*, *1D LUT Heatmap Shader* untuk 5 *Map Modes*, *Camera2D Pan/Zoom*, label kepulauan interaktif, dan *Guided Demo Advisor*.
- [ ] **Phase 3 — Deep Pops System, Tech Tree & Diplomatic Treaties:**
  Strata sosial populasi (*Buruh, Petani, Birokrat, Kapitalis*), pohon riset institusi moneter (*Gold Standard* ke *Modern Central Banking*), dan perjanjian dagang bilateral.
- [ ] **Phase 4 — Steamworks Polish & Storefront Packaging (v1.0):**
  Integrasi biner *GodotSteam* (*Achievements*, *Auto-Cloud Save*, *Rich Presence*), lokalisasi penuh ID/EN, audio/SFX, dan *packaging* *SteamPipe*.

---

## 📚 Dokumentasi Lengkap

- 📘 **[Game Design & Macroeconomic Formulas (`docs/GAME_DESIGN.md`)](docs/GAME_DESIGN.md)**
- 🚀 **[Steam v1.0 Release & Engineering Checklist (`docs/STEAM_RELEASE.md`)](docs/STEAM_RELEASE.md)**

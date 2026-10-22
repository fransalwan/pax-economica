# Pax Economica 🏛️📈

**Pax Economica** adalah game *Grand Strategy & Macroeconomic Simulator* berbasis peta (*map-painter*) yang dibangun menggunakan **Godot Engine 4.x**. Game ini dirancang khusus untuk melatih intuisi dan kemampuan analisis makroekonomi dengan membangun peradaban/kekaisaran melalui kebijakan moneter, fiskal, produksi, dan perdagangan internasional dalam sistem ekonomi tertutup/semi-tertutup (*closed/semi-closed monetary loop*).

Seluruh arsitektur proyek ini dirancang sejak awal agar **Steam-Ready (v1.0)**—mendukung *Steam Auto-Cloud*, *GodotSteam (Achievements & Rich Presence)*, *Multi-Resolution/UI Scaling*, dan *Localization (i18n)*.

---

## 🎯 Core Gameplay & Mekanika Makroekonomi

Berbeda dengan game strategi konvensional di mana *gold* muncul begitu saja, setiap koin dan komoditas di **Pax Economica** berputar di antara **Rumah Tangga (Pops)**, **Sektor Produksi Provinsi**, **Pasar Komoditas**, **Bank Sentral**, dan **Kas Negara**:

1. **Analytical Gameplay Loop (`Observe → Hypothesize → Intervene → Evaluate`):**
   - Baca indikator ekonomi langsung di atas peta menggunakan *Heatmap Shader* (*Inflation Heat*, *GDP per Capita*, *Standard of Living*, *Trade Balance*).
2. **Produksi Riil & Pembentukan Harga Dinamis:**
   - Fungsi produksi berbasis *Cobb-Douglas* ($Y = A \cdot K^\alpha \cdot L^{1-\alpha} \cdot I_{eff}$) yang dipengaruhi infrastruktur provinsi, tenaga kerja, dan modal.
   - Harga komoditas bergerak dinamis mengikuti rasio *Supply/Demand* dan jumlah uang beredar (*Monetary Multiplier*).
3. **Akuntansi Nasional (GDP & CPI):**
   - Perhitungan **Nominal GDP** ($C + I + G + NX$), **Real GDP**, serta **Indeks Harga Konsumen (CPI)** dan laju **Inflasi ($\pi$)** secara *real-time*.
4. **Bank Sentral & Kebijakan Moneter:**
   - Kendalikan **Suku Bunga Acuan (*Policy Rate*)** untuk meredam inflasi atau memacu investasi swasta, serta kelola risiko pencetakan uang (*Seigniorage / Quantitative Easing*).
5. **Kebijakan Fiskal, Pasar Obligasi (*Bond Yields*), & Risiko Default:**
   - Atur struktur pajak (*Income Tax*, *Corporate Tax*, *VAT/PPN*, *Tariffs*), belanja infrastruktur, subsidi, dan rasio *Debt-to-GDP* dengan imbal hasil surat utang (*Bond Yield*) yang bereaksi terhadap risiko gagal bayar.
6. **Perdagangan Internasional & Nilai Tukar (*FX Rate*):**
   - Rasakan langsung dilema *Impossible Trinity*, keunggulan komparatif antar-kekaisaran, transisi dari *Gold Standard* ke *Fiat Floating Exchange Rate*, serta skenario krisis seperti *Dutch Disease* dan *Stagflation Shock*.

---

## 📂 Struktur Folder Proyek

Struktur direktori memisahkan **Data & Simulasi Murni (`src/core/`, `data/`)** dari **Presentasi Visual (`src/map/`, `src/ui/`)** serta artefak distribusi **Steam (`steam/`)**:

```text
pax-economica/
├── addons/                     # Plugin pihak ketiga (misal: GodotSteam GDExtension)
├── assets/                     # Aset visual, audio, font, dan tekstur peta
│   ├── audio/                  # Musik BGM, SFX, dan UI feedback sounds
│   │   ├── bgm/
│   │   ├── sfx/
│   │   └── ui/
│   ├── fonts/                  # Tipografi UI & angka tabel (tabular numerals)
│   ├── icons/                  # Ikon SVG untuk komoditas & indikator makro
│   │   ├── commodities/
│   │   └── indicators/
│   ├── map/                    # Tekstur peta & Color-ID lookup
│   │   ├── lut/                # 1D Color Lookup Textures untuk Heatmap Shader
│   │   └── textures/           # provinces_id.png, heightmap.png, terrain.png
│   └── themes/                 # Godot Theme (.tres) & StyleBox
├── data/                       # Definisi data statis (JSON / Custom Resources)
│   ├── commodities/            # Definisi komoditas & Base Price
│   ├── events/                 # Dynamic macroeconomic shocks & historical events
│   ├── nations/                # Data awal kekaisaran/peradaban
│   ├── provinces/              # Data populasi awal, sumber daya alam, & warna RGB provinsi
│   └── scenarios/              # Skenario latihan (Dutch Disease, Stagflation, Debt Crisis)
├── docs/                       # Dokumentasi teknis & desain
│   ├── GAME_DESIGN.md          # Blueprint rumus ekonomi & arsitektur fitur end-to-end
│   └── STEAM_RELEASE.md        # Checklist & standar engineering rilis Steam v1.0
├── localization/               # File terjemahan multi-bahasa (.csv / .po - ID & EN)
├── src/                        # Source code GDScript & Shaders
│   ├── autoload/               # Singletons (EventBus, SimulationClock, WorldEconomy, SteamManager, SaveManager, SettingsManager)
│   ├── core/                   # Logika simulasi murni (extends RefCounted / Resource)
│   │   ├── economy/            # Market, CentralBank, FiscalPolicy, Trade, FX, MacroAccounting
│   │   ├── empire/             # Nation, Province, PopGroup, Building
│   │   └── scenarios/          # Evaluasi kondisi menang/kalah & trigger krisis
│   ├── map/                    # Sistem peta interaktif
│   │   ├── camera/             # Pan, Zoom, & Smooth Map Camera2D
│   │   ├── modes/              # Controller untuk Map Modes (Political, GDP, Inflation, SoL)
│   │   ├── picker/             # O(1) RGB Color-ID Province Picker
│   │   └── shaders/            # GLSL CanvasItem Shaders untuk rendering peta & perbatasan
│   ├── scenes/                 # Scene utama permainan
│   │   ├── boot/               # Splash screen & inisialisasi awal
│   │   ├── main_menu/          # Menu utama, pemilihan skenario, & Load Game
│   │   └── world/              # Scene utama penggabung MapView + Simulation + HUD
│   ├── ui/                     # Antarmuka pengguna & dasbor analitik
│   │   ├── hud/                # Topbar indikator makro & kontrol kecepatan waktu (Tick Speed)
│   │   ├── modals/             # Pop-up krisis ekonomi & keputusan kebijakan
│   │   ├── panels/             # Panel manajemen mendalam
│   │   │   ├── central_bank/   # Pengaturan suku bunga acuan, cadangan emas, & money supply
│   │   │   ├── fiscal_budget/  # Pajak, subsidi, pengeluaran infrastruktur, & obligasi
│   │   │   ├── market_ledger/  # Tabel supply, demand, harga komoditas, & ekspor-impor
│   │   │   ├── province_inspector/ # Detail populasi, pabrik, & infrastruktur provinsi
│   │   │   └── trade_diplomacy/# Tarif dagang, embargo, & nilai tukar mata uang
│   │   ├── settings/           # Pengaturan resolusi, UI scaling, audio bus, & keybinds
│   │   └── widgets/            # Komponen UI reusable
│   │       ├── charts/         # Custom LineChart & BarChart time-series (_draw)
│   │       ├── tables/         # Sortable data tables untuk ledger ekonomi
│   │       └── tooltips/       # Nested tooltips untuk penjelasan rumus indikator
│   └── utils/                  # Helper functions (Format mata uang, persentase, math utils)
├── steam/                      # Konfigurasi & aset distribusi Steamworks
│   ├── achievements/           # Metadata & ikon Steam Achievements
│   ├── app_build/              # Template skrip SteamPipe (.vdf) untuk upload depot
│   └── store_assets/           # Tempat penyimpanan Capsule & Library artwork
└── tests/                      # Pengujian otomatis
    ├── simulation/             # Stress-test keseimbangan rumus ekonomi jangka panjang
    └── unit/                   # Unit test kalkulasi GDP, CPI, & harga pasar
```

---

## 🗺️ Roadmap Menuju Steam v1.0

- [ ] **Phase 1 — Core Macroeconomic Engine & UI Prototype:**
  Implementasi *Tick Clock*, model data `Nation`/`Province`/`Market`, kalkulasi *GDP/CPI/Interest Rate/Bond Yield*, serta komponen grafik *LineChart*.
- [ ] **Phase 2 — Interactive Map & Shader Pipeline:**
  Implementasi *Color-ID Lookup Map*, *1D LUT Heatmap Shader* untuk berbagai *Map Modes*, dan *Camera2D Pan/Zoom*.
- [ ] **Phase 3 — Empire Building, International Trade & FX:**
  Pembangunan infrastruktur provinsi, pertumbuhan kelas populasi (*Pops*), perdagangan lintas negara, tarif, dan nilai tukar mata uang dinamis.
- [ ] **Phase 4 — Crisis Scenarios & Steamworks Readiness (v1.0):**
  Skenario latihan makro (*Dutch Disease*, *Stagflation*, *Debt Spiral*), integrasi *GodotSteam* (*Achievements*, *Auto-Cloud Save*, *Rich Presence*), lokalisasi ID/EN, dan *packaging* *SteamPipe*.

---

## 📚 Dokumentasi Lengkap

- 📘 **[Game Design & Macroeconomic Formulas (`docs/GAME_DESIGN.md`)](docs/GAME_DESIGN.md)**
- 🚀 **[Steam v1.0 Release & Engineering Checklist (`docs/STEAM_RELEASE.md`)](docs/STEAM_RELEASE.md)**

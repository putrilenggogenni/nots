# NOTS

> **Capture info tugas, cek jadwalnya, biar NOTS yang ngingetin.**
> Nots membantu mahasiswa mengubah info tugas dari berbagai tempat jadi pengingat yang tertata.

![Flutter](https://img.shields.io/badge/Flutter-cross--platform-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13.7%2B-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Auth%20%2B%20PostgreSQL-3FCF8E?logo=supabase&logoColor=white)
![Status](https://img.shields.io/badge/status-in%20development-orange)

---

## Tentang NOTS

Info tugas, kuis, praktikum, dan ujian biasanya datang dari mana saja: chat group, foto papan tulis atau slide, sampai rekaman suara dosen. Untuk jadi pengingat, semuanya masih harus dipindah manual ke aplikasi lain. Langkahnya lumayan banyak, dan di situlah tenggat gampang kelewat.

NOTS mencoba memangkas langkah itu jadi tiga: **Tangkap, Konfirmasi, Diingatkan**. Kamu masukkan infonya, cek jadwal yang diusulkan, lalu simpan. Selesai.

Untuk sekarang NOTS difokuskan ke mahasiswa, dimulai dari mahasiswa di Surabaya sebagai pengguna uji. Ke depannya, pelajar dan pekerja yang sering dapat tenggat lewat pesan juga bisa memakainya.


## Alur yang direncanakan

1. **Tangkap**: masukkan info tenggat lewat teks, foto, atau suara.
2. **Konfirmasi**: cek usulan judul, mata kuliah, tanggal, dan jam. Kalau ada yang kurang pas, kamu bisa langsung koreksi.
3. **Diingatkan**: simpan, dan pengingatmu tersusun rapi per mata kuliah.

## Teknologi

| Bagian | Teknologi |
|---|---|
| Aplikasi | Flutter dan Dart |
| Autentikasi (sudah terhubung) | Supabase Auth |
| Database | Supabase PostgreSQL |
| Dependensi UI | `material_ui`, `google_fonts`, `flutter_svg` |
| Desain dan kolaborasi | Figma, GitHub |

Di rancangan, data aplikasi akan disimpan di empat tabel: `profiles`, `courses`, `tasks`, dan `reminders`.

## Menjalankan di lokal

### Yang perlu disiapkan

- Flutter SDK dengan Dart **3.13.7 atau lebih baru**
- Proyek Supabase, kalau mau mencoba daftar, masuk, dan pemulihan kata sandi
- Android Studio, atau perangkat/emulator yang didukung Flutter

### Langkah-langkah

```powershell
# Clone repository, lalu masuk ke folder project
git clone https://github.com/putrilenggogenni/nots
cd nots

# Ambil dependensi
flutter pub get
```

## Struktur proyek

```text
lib/
├── core/
│   ├── theme.dart
│   └── widgets/
├── features/
│   ├── auth/
│   └── reminders/
└── main.dart
assets/
└── images/
```

## Tekber Kelompok 1 - NOTS

| Nama | NRP |
|---|---|
| Mazaya Zharfani Erfindri | 5026241138 |
| Putri Lenggo Genni | 5026241040 |
| Romanna Tiolin Pangaribuan | 5026241024 |
| Eka Destriana Putri | 5026241164 |
| Arya Khairy Byan Setijono | 5026241154 |
| Muhammad Sahril | 5026231220 |

## Lisensi

Proyek ini dibuat untuk keperluan akademik. Hak atas karya ada pada para anggota tim.

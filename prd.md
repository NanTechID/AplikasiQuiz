Aplikasi Quiz Online Berbasis Flutter & Firebase
Deskripsi
Buatlah sebuah aplikasi Quiz Online menggunakan Flutter dan Firebase yang memiliki dua jenis pengguna, yaitu Dosen dan Mahasiswa. Aplikasi harus mampu melakukan proses pembuatan quiz, pelaksanaan quiz secara online, penilaian otomatis, serta pengiriman notifikasi kepada pengguna.

Ketentuan
Framework : Flutter

Backend : Firebase

Database : Cloud Firestore

Authentication : Firebase Authentication

Notification : Firebase Cloud Messaging (FCM)

State Management : Provider/Riverpod/BLoC (pilih salah satu)

Minimal Android SDK 24

Hak Akses
1. Dosen
Dosen harus dapat:

Login ke aplikasi.

Membuat Quiz baru.

Mengubah dan menghapus Quiz.

Menambahkan, mengubah, dan menghapus soal.

Menentukan waktu mulai dan waktu selesai Quiz.

Membuka dan menutup sesi Quiz.

Melihat daftar mahasiswa yang telah mengerjakan Quiz.

Melihat nilai setiap mahasiswa.

Melihat statistik hasil Quiz.

Menerima notifikasi ketika mahasiswa selesai mengerjakan Quiz.

2. Mahasiswa
Mahasiswa harus dapat:

Login ke aplikasi.

Melihat daftar Quiz yang tersedia.

Menerima notifikasi ketika Quiz dibuka.

Mengerjakan Quiz sesuai waktu yang ditentukan.

Melihat sisa waktu pengerjaan.

Submit jawaban.

Melihat nilai setelah Quiz selesai.

Melihat jawaban yang benar setelah mengerjakan Quiz.

Melihat riwayat hasil Quiz.

Fitur Wajib
Authentication
Login menggunakan Firebase Authentication.

Logout.

Auto Login.

Dashboard
Dashboard Dosen.

Dashboard Mahasiswa.

Quiz
CRUD Quiz.

CRUD Soal.

Status Quiz (Draft, Open, Closed).

Pelaksanaan Quiz
Timer otomatis.

Auto submit jika waktu habis.

Satu mahasiswa hanya boleh mengerjakan satu kali.

Penilaian
Perhitungan nilai otomatis.

Menampilkan jumlah jawaban benar dan salah.

Menampilkan nilai akhir.

Notifikasi
Mahasiswa menerima notifikasi ketika Quiz dibuka.

Dosen menerima notifikasi ketika mahasiswa selesai mengerjakan.

Struktur Database Firestore
Minimal terdiri dari collection:

users

quiz

questions

answers

Tampilan Minimal
Splash Screen

Login

Dashboard Dosen

Dashboard Mahasiswa

Daftar Quiz

Tambah Quiz

Tambah Soal

Halaman Mengerjakan Quiz

Halaman Nilai

Halaman Review Jawaban
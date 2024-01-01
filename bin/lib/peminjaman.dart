// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class Peminjaman {
  final int? id_peminjaman;
  String? tanggal_pinjam;
  String? tanggal_kembali;
  final int? id_buku;
  final String? kode_anggota;
  final int? id_petugas;


  Peminjaman(
      {required this.id_peminjaman,
      required this.kode_anggota,
      required this.tanggal_pinjam,
      required this.tanggal_kembali,
      required this.id_buku,
      required this.id_petugas});

  Map<String, dynamic> toMap() => {
        'id_peminjaman': id_peminjaman,
        'kode_anggota': kode_anggota,
        'tanggal_pinjam': tanggal_pinjam,
        'tanggal_kembali': tanggal_kembali,
        'id_buku': id_buku,
        'id_petugas': id_petugas
      };


  factory Peminjaman.fromJson(Map<String, dynamic> json) => Peminjaman(
      id_peminjaman: json['id_peminjaman'],
      kode_anggota: json['kode_anggota'],
      tanggal_pinjam: json['tanggal_pinjam'],
      tanggal_kembali: json['tanggal_kembali'],
      id_buku: json['id_buku'],
      id_petugas: json['id_petugas']);
}


Peminjaman peminjamanFromJson(String str) => Peminjaman.fromJson(json.decode(str));

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class Pengembalian {
  final int? id_pengembalian;
  String? tanggal_pengembalian;
  int? denda;
  final int? id_buku;
  final String? kode_anggota;
  final int? id_petugas;

  Pengembalian(
      {required this.id_pengembalian,
      required this.tanggal_pengembalian,
      required this.denda,
      required this.id_buku,
      required this.kode_anggota,
      required this.id_petugas});

  Map<String, dynamic> toMap() => {
        'id_pengembalian': id_pengembalian,
        'tanggal_pengembalian': tanggal_pengembalian,
        'denda': denda,
        'id_buku': id_buku,
        'kode_anggota': kode_anggota,
        'id_petugas': id_petugas
      };


  factory Pengembalian.fromJson(Map<String, dynamic> json) => Pengembalian(
      id_pengembalian: json['id_pengembalian'],
      tanggal_pengembalian: json['tanggal_pengembalian'],
      denda: json['denda'],
      id_buku: json['id_buku'],
      kode_anggota: json['kode_anggota'],
      id_petugas: json['id_petugas']);
}


Pengembalian pengembalianFromJson(String str) =>
    Pengembalian.fromJson(json.decode(str));

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class Buku {
  final int? id_buku;
  String? kode_buku;
  final String? judul_buku;
  final String? penulis_buku;
  final String? penerbit_buku;
  final String? tahun_penerbit;
  final int? stok;

  Buku(
      {required this.id_buku,
      required this.kode_buku,
      required this.judul_buku,
      required this.penulis_buku,
      required this.penerbit_buku,
      required this.tahun_penerbit,
      required this.stok});

  Map<String, dynamic> toMap() => {
        'id_buku': id_buku,
        'kode_buku': kode_buku,
        'judul_buku': judul_buku,
        'penulis_buku': penulis_buku,
        'penerbit_buku': penerbit_buku,
        'tahun_penerbit': tahun_penerbit,
        'stok': stok
      };


  factory Buku.fromJson(Map<String, dynamic> json) => Buku(
      id_buku: json['id_buku'],
      kode_buku: json['kode_buku'],
      judul_buku: json['judul_buku'],
      penulis_buku: json['penulis_buku'],
      penerbit_buku: json['penerbit_buku'],
      tahun_penerbit: json['tahun_penerbit'],
      stok: json['stok']);
}


Buku bukuFromJson(String str) => Buku.fromJson(json.decode(str));

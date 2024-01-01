// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class Anggota {
  final int? id_anggota;
  String? kode_anggota;
  final String? nama_anggota;
  final String? jurusan_anggota;
  final String? no_telp_anggota;
  final String? alamat_anggota;
  String? tanggal_input;
  String? modified;

  Anggota(
      {required this.id_anggota,
      required this.kode_anggota,
      required this.nama_anggota,
      required this.jurusan_anggota,
      required this.no_telp_anggota,
      required this.alamat_anggota,
      required this.tanggal_input,
      required this.modified});

  Map<String, dynamic> toMap() => {
        'id_anggota': id_anggota,
        'kode_anggota': kode_anggota,
        'nama_anggota': nama_anggota,
        'jurusan_anggota': jurusan_anggota,
        'no_telp_anggota': no_telp_anggota,
        'alamat_anggota': alamat_anggota,
        'tanggal_input': tanggal_input,
        'modified': modified
      };


  factory Anggota.fromJson(Map<String, dynamic> json) => Anggota(
      id_anggota: json['id_anggota'],
      kode_anggota: json['kode_anggota'],
      nama_anggota: json['nama_anggota'],
      jurusan_anggota: json['jurusan_anggota'],
      no_telp_anggota: json['no_telp_anggota'],
      alamat_anggota: json['alamat_anggota'],
      tanggal_input: json['tanggal_input'],
      modified: json['modified']);
}


Anggota anggotaFromJson(String str) => Anggota.fromJson(json.decode(str));

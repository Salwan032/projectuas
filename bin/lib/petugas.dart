// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class Petugas {
  final int? id_petugas;
  final String? nama_petugas;
  final String? jabatan_petugas;
  final String? email;
  String? password;
  final int role_id;
  final int is_active;
  String? tanggal_input;
  String? modified;

  Petugas({
    required this.id_petugas,
    required this.nama_petugas,
    required this.jabatan_petugas,
    required this.email,
    required this.password,
    required this.role_id,
    required this.is_active,
    required this.tanggal_input,
    required this.modified
  });

  Map<String, dynamic> toMap() => {
        'id_petugas': id_petugas,
        'nama_petugas': nama_petugas,
        'jabatan_petugas': jabatan_petugas,
        'email': email,
        'password': password,
        'role_id': role_id,
        'is_active': is_active,
        'tanggal_input': tanggal_input,
        'modified': modified
      };

  factory Petugas.fromJson(Map<String, dynamic> json) => Petugas(
        id_petugas: json['id_petugas'],
        nama_petugas: json['nama_petugas'],
        jabatan_petugas: json['jabatan_petugas'],
        email: json['email'],
        password: json['password'],
        role_id: json['role_id'],
        is_active: json['is_active'],
        tanggal_input: json['tanggal_input'],
        modified: json['modified']
      );
}

Petugas petugasFromJson(String str) => Petugas.fromJson(json.decode(str));

// // ignore_for_file: avoid_relative_lib_imports, unused_import, unused_local_variable, non_constant_identifier_names, prefer_interpolation_to_compose_strings, unused_element, unnecessary_string_interpolations

// ignore_for_file: unused_import, unused_element, unnecessary_new, prefer_collection_literals, prefer_interpolation_to_compose_strings, unused_local_variable, non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:string_validator/string_validator.dart';
import 'anggota.dart';
import 'buku.dart';
import 'peminjaman.dart';
import 'pengembalian.dart';
import 'petugas.dart';

class Controller {
  // fungsi membuat koneksi ke database perpustakaan
  Future<MySqlConnection> connectSql() async {
    var settings = ConnectionSettings(
        host: 'localhost', port: 3306, user: 'root', db: 'perpustakaan');
    var cn = await MySqlConnection.connect(settings);
    return cn;
  }

/*PETUGAS -> CRUD & AUTH*/

// SIGN UP PETUGAS -> untuk mendapatkan token bearer => akses (getPetugasWithAuth)
  Future<Response> signUp(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var email = "%${obj['email']}%";
    var password = "%${obj['password']}%";

    var conn = await connectSql();
    var sql = "SELECT * FROM petugas WHERE email like ?";
    var petugas = await conn.query(sql, [email]);
    if (petugas.isNotEmpty) {
      var strBase = "";

      for (var row in petugas) {
        strBase =
            '{"id_petugas": ${row["id_petugas"]},"email": "${row["email"]}", "password": "${row["password"]}" }';
      }

      final bytes = utf8.encode(strBase.toString());
      final base64Str = base64.encode(bytes);
      final token = "Bearer-$base64Str";
      var response = _responseSuccessMsg(token);
      return Response.ok(jsonEncode(response));
    } else {
      var response = _responseErrorMsg('Petugas Not Found');
      return Response.forbidden(jsonEncode(response));
    }
  }

// SignUp Petugas
// {
//   "email": "samsul@gmail.com"
// }

// GET PETUGAS
  Future<Response> getPetugasData(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM petugas";
    var petugas = await conn.query(sql, []);

    var response = _responseSuccessMsg(petugas.toString());
    return Response.ok(response.toString());
  }

// GET PETUGAS WITH AUTH -> Memasukkan token bearer pada AUTH (Bearer)
  Future<Response> getPetugasDataWithAuth(Request request) async {
    final isValidRequest = await _isValidRequestHeader(request);
    if (!isValidRequest) {
      var response = _responseErrorMsg('Invalid Token');
      return Response.forbidden(jsonEncode(response));
    }

    var conn = await connectSql();
    var sql = "SELECT * FROM petugas";
    var data = await conn.query(sql, []);

    final Map<String, dynamic> petugas = new Map<String, dynamic>();

    for (var row in data) {
      petugas["id_petugas"] = row["id_petugas"];
      petugas["nama_petugas"] = row["nama_petugas"];
      petugas["jabatan_petugas"] = row["jabatan_petugas"];
      petugas["email"] = row["email"];
      petugas["password"] = row["password"];
      petugas["role_id"] = row["role_id"];
      petugas["is_active"] = row["is_active"];
    }

    var response = jsonEncode(_responseSuccessMsg(petugas));
    return Response.ok(response.toString());
  }

// JANGAN LUPA MEMASUKKAN TOKEN BEARER PADA OPSI AUTH --> UNTUK GET PETUGAS WITH AUTH

// GET FILTER PETUGAS
  Future<Response> getPetugasDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var name = "%" + obj['nama_petugas'] + "%";

    var conn = await connectSql();
    var sql = "SELECT * FROM petugas WHERE nama_petugas like ?";
    var petugas = await conn.query(sql, [name]);
    var response = _responseSuccessMsg(petugas.toString());
    return Response.ok(response.toString());
  }

// (JSON) Filter Petugas
// {
//   "nama_petugas": "samsul"
// }

// CREATE PETUGAS
  Future<Response> postPetugasData(Request request) async {
    String body = await request.readAsString();
    Petugas petugas = petugasFromJson(body);

    if (!_isValidPetugas(petugas)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    petugas.tanggal_input = getDateNow();
    petugas.modified = getDateNow();

    String hashingPassword = hashPassword(petugas.password!);
    petugas.password = hashingPassword;

    var conn = await connectSql();
    var sqlExecute = """
    INSERT INTO petugas (id_petugas, nama_petugas, jabatan_petugas, email, password, role_id,
    is_active, tanggal_input, modified)
    VALUES
    (
    '${petugas.id_petugas}', '${petugas.nama_petugas}',
    '${petugas.jabatan_petugas}', '${petugas.email}',
    '${petugas.password}', '${petugas.role_id}', '${petugas.is_active}',
    '${petugas.tanggal_input}', '${petugas.modified}'
    )
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM petugas WHERE nama_petugas = ?";
    var petugasResponse = await conn.query(sql, [petugas.nama_petugas]);

    var response = _responseSuccessMsg(petugasResponse.toString());
    return Response.ok(response.toString());
  }

// (JSON) Create Petugas
// {
//   "id_petugas" : 1,
//   "nama_petugas": "samsul",
//   "jabatan_petugas": "Staff Engineering",
//   "email": "samsul@gmail.com",
//   "password": "rumahakudimana",
//   "role_id": 1,
//   "is_active": 1
// }

// UPDATE PETUGAS
  Future<Response> putPetugasData(Request request) async {
    String body = await request.readAsString();
    Petugas petugas = petugasFromJson(body);

    if (!_isValidPetugas(petugas)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    petugas.modified = getDateNow();

    String hashingPassword = hashPassword(petugas.password!);
    petugas.password = hashingPassword;

    var conn = await connectSql();
    var sqlExecute = """
      UPDATE petugas SET
      nama_petugas ='${petugas.nama_petugas}', jabatan_petugas = '${petugas.jabatan_petugas}',
      email = '${petugas.email}', role_id = '${petugas.role_id}',
      modified='${petugas.modified}'
      WHERE id_petugas ='${petugas.id_petugas}'
      """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM petugas WHERE id_petugas = ?";
    var petugasResponse = await conn.query(sql, [petugas.id_petugas]);

    var response = _responseSuccessMsg(petugasResponse.toString());
    return Response.ok(response.toString());
  }

// (JSON) Update Petugas
// {
//   "id_petugas" : 1,
//   "nama_petugas": "samsul",
//   "jabatan_petugas": "IT Developer",
//   "email": "samsul@gmail.com",
//   "password": "rumahakudisini",
//   "role_id": 1,
//   "is_active": 1
// }

// DELETE PETUGAS
  Future<Response> deletePetugas(Request request) async {
    String body = await request.readAsString();
    Petugas petugas = petugasFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM petugas WHERE id_petugas ='${petugas.id_petugas}'
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM petugas WHERE id_petugas = ?";
    var petugasResponse = await conn.query(sql, [petugas.id_petugas]);

    var response = _responseSuccessMsg(petugasResponse.toString());
    return Response.ok(response.toString());
  }

// (JSON) Delete Petugas
// {
//   "id_petugas" : 1,
//   "role_id": 1,
//   "is_active": 1
// }

/*ANGGOTA -> CRUD*/

// CREATE ANGGOTA
  Future<Response> postAnggotaData(Request request) async {
    String body = await request.readAsString();
    Anggota anggota = anggotaFromJson(body);
    anggota.tanggal_input = getDateNow();
    anggota.modified = getDateNow();
    anggota.kode_anggota = generateRandomKodeAnggota();

    var conn = await connectSql();
    var sqlExecute = """
INSERT INTO anggota (
  id_anggota, kode_anggota, nama_anggota, jurusan_anggota, no_telp_anggota, alamat_anggota, tanggal_input, modified
) VALUES (
  '${anggota.id_anggota}', '${anggota.kode_anggota}',
  '${anggota.nama_anggota}', '${anggota.jurusan_anggota}',
  '${anggota.no_telp_anggota}', '${anggota.alamat_anggota}',
  '${anggota.tanggal_input}', '${anggota.modified}'
)
""";

    var execute = await conn.query(sqlExecute, []);
    var sql = "SELECT * FROM anggota WHERE nama_anggota like ?";
    var result = await conn.query(sql, [anggota.nama_anggota]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Create Anggota
// {
//   "id_anggota": 1,
//   "nama_anggota": "dita",
//   "jurusan_anggota": "Ilmu Komputar",
//   "no_telp_anggota": "085811657352",
//   "alamat_anggota": "Tirta sari"
// }

// UPDATE ANGGOTA
  Future<Response> putAnggotaData(Request request) async {
    String body = await request.readAsString();
    Anggota anggota = anggotaFromJson(body);
    anggota.modified = getDateNow();

    if (!_isValidAnggota(anggota)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    anggota.kode_anggota = generateRandomKodeAnggota();

    var conn = await connectSql();
    var sqlExecute = """
UPDATE anggota SET
kode_anggota = '${anggota.kode_anggota}',
nama_anggota = '${anggota.nama_anggota}',
jurusan_anggota = '${anggota.jurusan_anggota}',
no_telp_anggota = '${anggota.no_telp_anggota}',
alamat_anggota = '${anggota.alamat_anggota}',
modified = '${anggota.modified}'
WHERE id_anggota = '${anggota.id_anggota}'
""";

    var execute = await conn.query(sqlExecute, []);
    var sql = "SELECT * FROM anggota WHERE id_anggota like ?";
    var result = await conn.query(sql, [anggota.id_anggota]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Update Anggota
// {
//  "id_anggota": 2
//  "nama_anggota": "dita",
//  "jurusan_anggota": "Sastra Jepang",
//  "no_telp_anggota": "123456789101",
//  "alamat_anggota": "Mekar Sari"
// }

// DELETE ANGGOTA
  Future<Response> deleteAnggota(Request request) async {
    String body = await request.readAsString();
    Anggota anggota = anggotaFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM anggota WHERE id_anggota ='${anggota.id_anggota}'
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM anggota WHERE id_anggota = ?";
    var anggotaResponse = await conn.query(sql, [anggota.id_anggota]);

    var response = _responseSuccessMsg(anggotaResponse.toString());
    return Response.ok(response.toString());
  }

// (JSON) Delete Anggota
// {
//   "id_anggota": 2
// }

// GET ANGGOTA
  Future<Response> getAnggotaData(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM anggota";
    var anggota = await conn.query(sql, []);

    var response = _responseSuccessMsg(anggota.toString());
    return Response.ok(response.toString());
  }

// GET FILTER ANGGOTA
  Future<Response> getAnggotaDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var name = "%" + obj['nama_anggota'] + "%";

    var conn = await connectSql();
    var sql = "SELECT * FROM anggota WHERE nama_anggota like ?";
    var anggota = await conn.query(sql, [name]);
    var response = _responseSuccessMsg(anggota.toString());
    return Response.ok(response.toString());
  }

// (JSON) Filter Anggota
// {
//   "nama_anggota": "sela"
// }

/*BUKU -> CRUD*/

// CREATE BUKU
  Future<Response> postBukuData(Request request) async {
    String body = await request.readAsString();
    Buku buku = bukuFromJson(body);

    buku.kode_buku = generateRandomKodeBuku();

    var conn = await connectSql();
    var sqlExecute = """
INSERT INTO buku (
  id_buku, kode_buku, judul_buku, penulis_buku, penerbit_buku, tahun_penerbit, stok
) VALUES (
  '${buku.id_buku}', '${buku.kode_buku}',
  '${buku.judul_buku}', '${buku.penulis_buku}',
  '${buku.penerbit_buku}', '${buku.tahun_penerbit}',
  '${buku.stok}'
)
""";

    var execute = await conn.query(sqlExecute, []);
    var sql = "SELECT * FROM buku WHERE judul_buku like ?";
    var result = await conn.query(sql, [buku.judul_buku]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Create Buku
// {
//   "id_buku" : 7,
//   "judul_buku": "Rahasia Keajaiban Bumi",
//   "penulis_buku": "Nurul Ihsan",
//   "penerbit_buku": "Luxima",
//   "tahun_penerbit": "2014",
//   "stok": 15
// }

// UPDATE BUKU
  Future<Response> putBukuData(Request request) async {
    String body = await request.readAsString();
    Buku buku = bukuFromJson(body);

    buku.kode_buku = generateRandomKodeBuku();

    var conn = await connectSql();
    var sqlExecute = """
UPDATE buku SET
kode_buku = '${buku.kode_buku}',
judul_buku = '${buku.judul_buku}',
penulis_buku = '${buku.penulis_buku}',
penerbit_buku = '${buku.penerbit_buku}',
tahun_penerbit = '${buku.tahun_penerbit}',
stok = '${buku.stok}'
WHERE id_buku = '${buku.id_buku}'
""";

    var execute = await conn.query(sqlExecute, []);
    var sql = "SELECT * FROM buku WHERE judul_buku like ?";
    var result = await conn.query(sql, [buku.judul_buku]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Update Buku
// {
//   "id_buku" : 7,
//   "judul_buku": "Rahasia Bumi",
//   "penulis_buku": "Nurul dan Ihsan",
//   "penerbit_buku": "Luxima",
//   "tahun_penerbit": "2012",
//   "stok": 11
// }

// DELETE BUKU
  Future<Response> deleteBuku(Request request) async {
    String body = await request.readAsString();
    Buku buku = bukuFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM buku WHERE id_buku ='${buku.id_buku}'
    """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM buku WHERE id_buku = ?";
    var bukuResponse = await conn.query(sql, [buku.id_buku]);

    var response = _responseSuccessMsg(bukuResponse.toString());
    return Response.ok(response.toString());
  }

// (JSON) Delete Buku
// {
//   "id_buku" : 7
// }

// GET BUKU
  Future<Response> getBukuData(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM buku";
    var buku = await conn.query(sql, []);

    var response = _responseSuccessMsg(buku.toString());
    return Response.ok(response.toString());
  }

// GET FILTER BUKU
  Future<Response> getBukuDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var judul = "%" + obj['judul_buku'] + "%";

    var conn = await connectSql();
    var sql = "SELECT * FROM buku WHERE judul_buku like ?";
    var buku = await conn.query(sql, [judul]);
    var response = _responseSuccessMsg(buku.toString());
    return Response.ok(response.toString());
  }

// (JSON) Filter Buku
// {
//   "judul_buku" : "Conan"
// }

  /*PEMINJAMAN -> CRUD*/

  // CREATE PEMINJAMAN
  Future<Response> postPeminjaman(Request request) async {
    String body = await request.readAsString();
    Peminjaman peminjaman = peminjamanFromJson(body);

    peminjaman.tanggal_pinjam = getDateNow();

    var conn = await connectSql();

    // Lakukan validasi stok sebelum peminjaman
    var bukuResult = await conn
        .query('SELECT stok FROM buku WHERE id_buku = ?', [peminjaman.id_buku]);
    var stokSaatIni = bukuResult.first[0]; // Mengambil nilai stok buku

    var pinjam = 1;

    if (stokSaatIni >= pinjam) {
      // Lakukan peminjaman jika stok mencukupi
      var sqlExecute = """
      INSERT INTO peminjaman (kode_anggota, tanggal_pinjam, tanggal_kembali, id_buku, id_petugas)
      VALUES ('${peminjaman.kode_anggota}', '${peminjaman.tanggal_pinjam}', '${DateTime.parse(peminjaman.tanggal_kembali!)}', '${peminjaman.id_buku}', '${peminjaman.id_petugas}')
    """;

      await conn.query(sqlExecute, []);

      // Mengurangi stok buku setelah peminjaman berhasil
      await kurangiStokBuku(conn, peminjaman.id_buku!, pinjam);
    }

    var sql = "SELECT * FROM peminjaman WHERE kode_anggota like ?";
    var result = await conn.query(sql, [peminjaman.kode_anggota]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Create Peminjaman
// {
//   "kode_anggota" : "173",
//   "tanggal_kembali": "2024-01-10",
//   "id_buku": 1,
//   "id_petugas": 1
// }

// UPDATE PEMINJAMAN
  Future<Response> putPeminjaman(Request request) async {
    String body = await request.readAsString();
    Peminjaman peminjaman = peminjamanFromJson(body);

    peminjaman.tanggal_pinjam = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
    UPDATE peminjaman SET
    tanggal_pinjam = '${peminjaman.tanggal_pinjam}',
    tanggal_kembali = '${DateTime.parse(peminjaman.tanggal_kembali!)}',
    id_buku = '${peminjaman.id_buku}',
    kode_anggota = '${peminjaman.kode_anggota}',
    id_petugas = '${peminjaman.id_petugas}'
    WHERE id_peminjaman = '${peminjaman.id_peminjaman}'
  """;

    var sql = "SELECT * FROM peminjaman WHERE kode_anggota like ?";
    var result = await conn.query(sql, [peminjaman.kode_anggota]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Update Peminjaman
// {
//   "id_peminjaman": 6,
//   "kode_anggota" : "173",
//   "tanggal_kembali": "2024-01-10",
//   "id_buku": 1,
//   "id_petugas": 1
// }

// DELETE PEMINJAMAN
  Future<Response> deletePeminjaman(Request request) async {
    String body = await request.readAsString();
    Peminjaman peminjaman = peminjamanFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM peminjaman WHERE id_peminjaman ='${peminjaman.id_peminjaman}'
  """;

    await tambahStokBuku(conn, peminjaman.id_buku!);

    var sql = "SELECT * FROM peminjaman WHERE id_peminjaman like ?";
    var result = await conn.query(sql, [peminjaman.id_peminjaman]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Delete Peminjaman
// {
//   "id_peminjaman": 6
// }

// GET PEMINJAMAN
  Future<Response> getPeminjaman(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM peminjaman";
    var peminjaman = await conn.query(sql, []);

    var response = _responseSuccessMsg(peminjaman.toString());
    return Response.ok(response.toString());
  }

// GET FILTER PEMINJAMAN
  Future<Response> getPeminjamanFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var nama = obj['nama_anggota'];

    var conn = await connectSql();

    //(INNER JOIN) dari tabel peminjaman ke tabel anggota --> untuk mendapatkan peminjaman a/n anggota
    var peminjaman = await conn.query(
        "SELECT * FROM peminjaman INNER JOIN anggota ON peminjaman.kode_anggota = anggota.kode_anggota WHERE nama_anggota like ?",
        [nama]);
    var response = _responseSuccessMsg(peminjaman.toString());
    return Response.ok(response.toString());
  }

// (JSON) Filter Peminjaman
// {
//   "nama_anggota": "dita"
// }

/*PENGEMBALIAN->CRUD*/

// CREATE PENGEMBALIAN
  Future<Response> postPengembalian(Request request) async {
    String body = await request.readAsString();
    Pengembalian pengembalian = pengembalianFromJson(body);

    var conn = await connectSql();

    pengembalian.tanggal_pengembalian = getDateNow();

    bool lewatTanggalKembali = await cekKeterlambatanPengembalian(
        conn,
        pengembalian.kode_anggota!,
        pengembalian.id_buku!,
        pengembalian.tanggal_pengembalian!);

    // Jika tanggal pengembalian melebihi tanggal yang ditentukan sebelumnya, tambahkan denda
    if (lewatTanggalKembali) {
      pengembalian.denda = 5000;
      // Anda dapat memasukkan logika lain di sini seperti menambahkan denda ke dalam database atau memberikan pesan kepada pengguna
    }

    // Proses pembuatan pengembalian buku
    var sqlExecute = """
    INSERT INTO pengembalian (tanggal_pengembalian, denda, id_buku, kode_anggota, id_petugas)
    VALUES ('${pengembalian.tanggal_pengembalian}', '${pengembalian.denda}', '${pengembalian.id_buku}', '${pengembalian.kode_anggota}', '${pengembalian.id_petugas}')
  """;

    var execute = await conn.query(sqlExecute, []);

    // Tambah stok buku yang dikembalikan
    await tambahStokBuku(conn, pengembalian.id_buku!);

    var sql = "SELECT * FROM pengembalian WHERE kode_anggota like ?";
    var result = await conn.query(sql, [pengembalian.kode_anggota]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Create Pengembalian
// {
//   "id_buku": 1,
//   "kode_anggota": "173",
//   "id_petugas": 1
// }

// UPDATE PENGEMBALIAN
  Future<Response> putPengembalian(Request request) async {
    String body = await request.readAsString();
    Pengembalian pengembalian = pengembalianFromJson(body);
    pengembalian.tanggal_pengembalian = getDateNow();

    var conn = await connectSql();

    // Logika untuk mengecek keterlambatan pengembalian
    bool lewatTanggalKembali = await cekKeterlambatanPengembalian(
        conn,
        pengembalian.kode_anggota!,
        pengembalian.id_buku!,
        pengembalian.tanggal_pengembalian!);

    // Jika tanggal pengembalian melebihi tanggal yang ditentukan sebelumnya, tambahkan denda
    if (lewatTanggalKembali) {
      pengembalian.denda = 5000;
      // Anda dapat memasukkan logika lain di sini seperti menambahkan denda ke dalam database atau memberikan pesan kepada pengguna
    }

    var sqlExecute = """
    UPDATE pengembalian SET
    tanggal_pengembalian = '${pengembalian.tanggal_pengembalian}',
    denda = '${pengembalian.denda}',
    id_buku = '${pengembalian.id_buku}',
    kode_anggota = '${pengembalian.kode_anggota}',
    id_petugas = '${pengembalian.id_petugas}'
    WHERE id_pengembalian = '${pengembalian.id_pengembalian}'
  """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM pengembalian WHERE kode_anggota like ?";
    var result = await conn.query(sql, [pengembalian.kode_anggota]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Update Pengembalian
// {
//   "id_pengembalian": 6,
//   "id_buku": 1,
//   "kode_anggota": "173",
//   "id_petugas": 1
// }

// DELETE PENGEMBALIAN
  Future<Response> deletePengembalian(Request request) async {
    String body = await request.readAsString();
    Pengembalian pengembalian = pengembalianFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM pengembalian WHERE id_pengembalian ='${pengembalian.id_pengembalian}'
  """;

    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM pengembalian WHERE id_pengembalian like ?";
    var result = await conn.query(sql, [pengembalian.id_pengembalian]);
    var response = _responseSuccessMsg(result);

    return Response.ok(response.toString());
  }

// (JSON) Delete Pengembalian
// {
//   "id_pengembalian": 6
// }

// GET PENGEMBALIAN
  Future<Response> getPengembalian(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM pengembalian";
    var pengembalian = await conn.query(sql, []);

    var response = _responseSuccessMsg(pengembalian.toString());
    return Response.ok(response.toString());
  }

// GET FILTER PENGEMBALIAN
  Future<Response> getPengembalianFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var nama = "%" + obj['nama_anggota'] + "%";

    var conn = await connectSql();

    // (INNER JOIN) dari tabel pengembalian.kode_anggota --> untuk mendapatkan pengembalian a/n anggota
    var pengembalian = await conn.query(
        "SELECT * FROM pengembalian INNER JOIN anggota ON pengembalian.kode_anggota = anggota.kode_anggota where nama_anggota like ? ",
        [nama]);
    var response = _responseSuccessMsg(pengembalian.toString());
    return Response.ok(response.toString());
  }

// (JSON) Filter Pengembalian
// {
//   "nama_anggota": "dita"
// }

/*<<--FUNCTION-->>*/

  // Response Sukses
  Map<String, dynamic> _responseSuccessMsg(dynamic msg) {
    return {'status': 200, '\nsuccess': true, '\ndata': msg};
  }

  // Response Gagal
  Map<String, dynamic> _responseErrorMsg(dynamic msg) {
    return {'status': 400, '\nsuccess': false, '\ndata': msg};
  }

// fungsi mendapatkan tanggal
  String getDateNow() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
    final String dateNow = formatter.format(now);
    return dateNow;
  }

// fungsi hashing password
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);

    return digest.toString();
  }

// Fungsi untuk menghasilkan ID buku secara acak
  String generateRandomKodeBuku() {
    final random = Random();
    String result = '';
    for (var i = 0; i < 6; i++) {
      result += random
          .nextInt(10)
          .toString(); // Menghasilkan angka acak dari 0 hingga 9
    }
    return result;
  }

// Fungsi untuk menghasilkan ID anggota secara acak
  String generateRandomKodeAnggota() {
    final random = Random();
    String result = '';
    for (var i = 0; i < 3; i++) {
      result += random
          .nextInt(10)
          .toString(); // Menghasilkan angka acak dari 0 hingga 9
    }
    return result;
  }

// Fungsi untuk mengurangi stok buku
  Future<void> kurangiStokBuku(var conn, int idBuku, int pinjam) async {
    var sqlExecute = """
    UPDATE buku SET stok = stok - 1 WHERE id_buku = $idBuku
  """;
    await conn.query(sqlExecute, []);
  }

// Fungsi untuk menambah stok buku
  Future<void> tambahStokBuku(var conn, int idBuku) async {
    var sqlExecute = """
    UPDATE buku SET stok = stok + 1 WHERE id_buku = $idBuku
  """;
    await conn.query(sqlExecute, []);
  }

// Cek Validasi Petugas
  bool _isValidPetugas(Petugas petugas) {
    if (petugas.nama_petugas == null ||
        petugas.jabatan_petugas == null ||
        petugas.email == null ||
        petugas.role_id == 0) {
      return false;
    }

    return true;
  }

// Cek Validasi Anggota
  bool _isValidAnggota(Anggota anggota) {
    if (anggota.nama_anggota == null ||
        anggota.jurusan_anggota == null ||
        anggota.no_telp_anggota == null) {
      return false;
    }

    return true;
  }

// Validasi Header Authorization
  Future<bool> _isValidRequestHeader(Request request) async {
    final authHeader =
        request.headers['Authorization'] ?? request.headers['authorization'];
    final parts = authHeader?.split('-');

    if (parts == null || parts.length != 2 || !parts[0].contains('Bearer')) {
      return false;
    }

    final token = parts[1];
    var validPetugas = await _isValidToken(token);
    if (validPetugas) {
      return true;
    } else {
      return false;
    }
  }

// Validasi Token
  Future<Response> getCheckAuth(Request request) async {
    String result = "";
    final isValidRequest = await _isValidRequestHeader(request);
    if (isValidRequest) {
      result = '{"isValid": true}';
      return Response.ok(result.toString());
    } else {
      result = '{"isValid": false}';
      return Response.forbidden(result.toString());
    }
  }

// Validasi Token
  Future<bool> _isValidToken(String token) async {
    final str = utf8.decode(base64.decode(token));
    var obj = json.decode(str);
    var id_petugas = obj['id_petugas'];

    var conn = await connectSql();
    var sql = "SELECT * FROM petugas WHERE id_petugas = ?";
    var petugas = await conn.query(sql, [id_petugas]);

    if (petugas.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

// Fungsi untuk memeriksa keterlambatan pengembalian
  Future<bool> cekKeterlambatanPengembalian(var conn, String kodeAnggota,
      int idBuku, String tanggalPengembalian) async {
    var sql =
        "SELECT tanggal_kembali FROM peminjaman WHERE kode_anggota = $kodeAnggota AND id_buku = $idBuku";
    var result = await conn.query(sql, []);
    if (result.isNotEmpty) {
      var tanggalKembaliSebelumnya = result.first[0];
      return DateTime.parse(tanggalPengembalian)
          .isAfter(tanggalKembaliSebelumnya);
    }
    return false;
  }
}

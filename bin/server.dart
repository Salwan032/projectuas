// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'lib/controller.dart';

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final Controller ctrl = Controller();
  ctrl.connectSql();

// Configure routes.
  final _router = Router()
    ..get('/', _rootHandler)
    ..get('/echo/<message>', _echoHandler)

    /*PETUGAS*/
    ..get('/petugas', ctrl.getPetugasData)
    ..post('/petugasFilter', ctrl.getPetugasDataFilter)
    ..post('/postPetugasData', ctrl.postPetugasData)
    ..put('/putPetugasData', ctrl.putPetugasData)
    ..delete('/deletePetugas', ctrl.deletePetugas)

    /*SIGNUP & AUTH PETUGAS*/
    ..post('/signup', ctrl.signUp)
    ..get('/checkAuth', ctrl.getCheckAuth)
    ..get('/petugasAuth', ctrl.getPetugasDataWithAuth)

    /*ANGGOTA*/
    ..get('/anggota', ctrl.getAnggotaData)
    ..post('/anggotaFilter', ctrl.getAnggotaDataFilter)
    ..post('/postAnggotaData', ctrl.postAnggotaData)
    ..put('/putAnggotaData', ctrl.putAnggotaData)
    ..put('/deleteAnggota', ctrl.deleteAnggota)

    /*BUKU*/
    ..get('/buku', ctrl.getBukuData)
    ..post('/bukuFilter', ctrl.getBukuDataFilter)
    ..post('/postBukuData', ctrl.postBukuData)
    ..put('/putBukuData', ctrl.putBukuData)
    ..delete('/deleteBuku', ctrl.deleteBuku)

    /*PEMINJAMAN*/
    ..post('/postPeminjaman', ctrl.postPeminjaman)
    ..put('/putPeminjaman', ctrl.putPeminjaman)
    ..get('/peminjaman', ctrl.getPeminjaman)
    ..post('/peminjamanFilter', ctrl.getPeminjamanFilter)

    /*PENGEMBALIAN*/
    ..post('/postPengembalian', ctrl.postPengembalian)
    ..put('/putPengembalian', ctrl.putPengembalian)
    ..put('/deletePengembalian', ctrl.deletePengembalian)
    ..get('/pengembalian', ctrl.getPengembalian)
    ..post('/pengembalianFilter', ctrl.getPengembalianFilter);

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

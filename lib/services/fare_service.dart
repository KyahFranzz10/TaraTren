import '../models/station.dart';
import 'transit_alert_service.dart';

class FareService {
  static final FareService _instance = FareService._internal();
  factory FareService() => _instance;
  FareService._internal();

  Map<String, dynamic> calculateFares(Station source, Station dest) {
    if (source.id == dest.id) {
      return {'sv': 0, 'sj': 0, 'sv50': 0, 'sj50': 0};
    }

    num sv = 0;
    num sj = 0;

    if (source.line == 'LRT1') {
      // Precise LRT-1 Stored Value (Beep) lookup matrix
      final List<List<int>> lrt1SVMatrix = [
        [
          16,
          19,
          20,
          22,
          23,
          26,
          27,
          28,
          29,
          31,
          32,
          33,
          34,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          45,
          46,
          49,
          52
        ], // Dr. Santos
        [
          19,
          16,
          18,
          20,
          21,
          23,
          24,
          26,
          27,
          28,
          29,
          31,
          32,
          33,
          35,
          36,
          36,
          37,
          38,
          40,
          41,
          42,
          44,
          47,
          50
        ], // Ninoy Aquino
        [
          20,
          18,
          16,
          18,
          19,
          22,
          22,
          24,
          25,
          27,
          28,
          29,
          30,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          42,
          45,
          48
        ], // PITX
        [
          22,
          20,
          18,
          16,
          17,
          20,
          20,
          22,
          23,
          25,
          26,
          27,
          28,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          40,
          43,
          46
        ], // MIA Road
        [
          23,
          21,
          19,
          17,
          16,
          18,
          19,
          21,
          22,
          23,
          25,
          26,
          27,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          39,
          42,
          45
        ], // Redemptorist
        [
          26,
          23,
          22,
          20,
          18,
          16,
          17,
          19,
          20,
          21,
          22,
          24,
          25,
          27,
          28,
          29,
          30,
          30,
          31,
          33,
          34,
          35,
          37,
          40,
          43
        ], // Baclaran
        [
          27,
          24,
          22,
          20,
          19,
          17,
          16,
          18,
          19,
          20,
          22,
          23,
          24,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          36,
          39,
          42
        ], // EDSA
        [
          28,
          26,
          24,
          22,
          21,
          19,
          18,
          16,
          17,
          19,
          20,
          21,
          22,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          33,
          34,
          38,
          40
        ], // Libertad
        [
          29,
          27,
          25,
          23,
          22,
          20,
          19,
          17,
          16,
          18,
          19,
          20,
          21,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          32,
          33,
          37,
          39
        ], // Gil Puyat
        [
          31,
          28,
          27,
          25,
          23,
          21,
          20,
          19,
          18,
          16,
          17,
          19,
          20,
          22,
          23,
          24,
          25,
          25,
          26,
          28,
          29,
          31,
          32,
          35,
          38
        ], // Vito Cruz
        [
          32,
          29,
          28,
          26,
          25,
          22,
          22,
          20,
          19,
          17,
          16,
          17,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          27,
          28,
          29,
          31,
          34,
          37
        ], // Quirino
        [
          33,
          31,
          29,
          27,
          26,
          24,
          23,
          21,
          20,
          19,
          17,
          16,
          17,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          27,
          28,
          29,
          33,
          35
        ], // Pedro Gil
        [
          34,
          32,
          30,
          28,
          27,
          25,
          24,
          22,
          21,
          20,
          19,
          17,
          16,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          27,
          28,
          32,
          34
        ], // UN Avenue
        [
          36,
          33,
          32,
          30,
          29,
          27,
          26,
          24,
          23,
          22,
          20,
          19,
          18,
          16,
          17,
          18,
          19,
          20,
          21,
          23,
          24,
          25,
          27,
          30,
          33
        ], // Central
        [
          37,
          35,
          33,
          31,
          30,
          28,
          27,
          25,
          24,
          23,
          21,
          20,
          19,
          17,
          16,
          17,
          18,
          19,
          20,
          21,
          23,
          24,
          25,
          29,
          31
        ], // Carriedo
        [
          38,
          36,
          34,
          32,
          31,
          29,
          28,
          26,
          25,
          24,
          22,
          21,
          20,
          18,
          17,
          16,
          17,
          18,
          19,
          20,
          21,
          23,
          24,
          28,
          30
        ], // D. Jose
        [
          39,
          36,
          35,
          33,
          32,
          30,
          29,
          27,
          26,
          25,
          23,
          22,
          21,
          19,
          18,
          17,
          16,
          17,
          18,
          20,
          20,
          22,
          23,
          27,
          30
        ], // Bambang
        [
          40,
          37,
          36,
          34,
          33,
          30,
          30,
          28,
          27,
          25,
          24,
          23,
          22,
          20,
          19,
          18,
          17,
          16,
          17,
          18,
          19,
          21,
          23,
          25,
          29
        ], // Tayuman
        [
          41,
          38,
          37,
          35,
          34,
          31,
          31,
          29,
          28,
          26,
          25,
          24,
          23,
          21,
          20,
          19,
          18,
          17,
          16,
          18,
          19,
          20,
          22,
          25,
          28
        ], // Blumentritt
        [
          42,
          40,
          38,
          36,
          35,
          33,
          32,
          30,
          30,
          28,
          27,
          25,
          24,
          23,
          21,
          20,
          20,
          18,
          18,
          16,
          17,
          19,
          20,
          24,
          26
        ], // Abad Santos
        [
          43,
          41,
          39,
          37,
          36,
          34,
          33,
          31,
          30,
          29,
          28,
          27,
          25,
          24,
          23,
          21,
          20,
          19,
          19,
          17,
          16,
          18,
          19,
          23,
          25
        ], // R. Papa
        [
          45,
          42,
          40,
          38,
          37,
          35,
          34,
          33,
          32,
          31,
          29,
          28,
          27,
          25,
          24,
          23,
          22,
          21,
          20,
          19,
          18,
          16,
          18,
          21,
          24
        ], // 5th Avenue
        [
          46,
          44,
          42,
          40,
          39,
          37,
          36,
          34,
          33,
          32,
          31,
          29,
          28,
          27,
          25,
          24,
          23,
          23,
          22,
          20,
          19,
          18,
          16,
          20,
          22
        ], // Monumento
        [
          49,
          47,
          45,
          43,
          42,
          40,
          39,
          38,
          37,
          35,
          34,
          33,
          32,
          30,
          29,
          28,
          27,
          25,
          25,
          24,
          23,
          21,
          20,
          16,
          19
        ], // Balintawak
        [
          52,
          50,
          48,
          46,
          45,
          43,
          42,
          40,
          39,
          38,
          37,
          35,
          34,
          33,
          31,
          30,
          30,
          29,
          28,
          26,
          25,
          24,
          22,
          19,
          16
        ], // FPJ
      ];

      // Precise LRT-1 Single Journey (SJT) lookup matrix
      final List<List<int>> lrt1SJMatrix = [
        [
          0,
          20,
          20,
          25,
          25,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          40,
          40,
          40,
          40,
          40,
          45,
          45,
          45,
          45,
          50,
          50,
          55
        ], // Dr. Santos
        [
          20,
          0,
          20,
          20,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          40,
          40,
          40,
          40,
          45,
          45,
          45,
          50,
          50,
          50
        ], // Ninoy Aquino
        [
          20,
          20,
          0,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          40,
          40,
          40,
          40,
          40,
          45,
          45,
          50
        ], // PITX
        [
          25,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          35,
          40,
          40,
          40,
          40,
          45,
          50
        ], // MIA Road
        [
          25,
          25,
          20,
          20,
          0,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          35,
          40,
          40,
          40,
          45,
          45
        ], // Redemptorist
        [
          30,
          25,
          25,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          40,
          40,
          45
        ], // Baclaran
        [
          30,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          35,
          40,
          40,
          45
        ], // EDSA
        [
          30,
          30,
          25,
          25,
          25,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          30,
          35,
          35,
          35,
          40,
          40
        ], // Libertad
        [
          30,
          30,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          30,
          35,
          35,
          40,
          40
        ], // Gil Puyat
        [
          35,
          30,
          30,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          30,
          35,
          35,
          40
        ], // Vito Cruz
        [
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          35,
          35,
          40
        ], // Quirino
        [
          35,
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          25,
          30,
          30,
          30,
          35,
          35
        ], // Pedro Gil
        [
          35,
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          25,
          30,
          30,
          35,
          35
        ], // UN Avenue
        [
          40,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          30,
          35
        ], // Central
        [
          40,
          35,
          35,
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          20,
          25,
          25,
          25,
          25,
          30,
          35
        ], // Carriedo
        [
          40,
          40,
          35,
          35,
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          20,
          25,
          25,
          25,
          30,
          30
        ], // D. Jose
        [
          40,
          40,
          35,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          20,
          25,
          25,
          30,
          30
        ], // Bambang
        [
          40,
          40,
          40,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          20,
          25,
          25,
          30
        ], // Tayuman
        [
          45,
          40,
          40,
          35,
          35,
          35,
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          25,
          30
        ], // Blumentritt
        [
          45,
          40,
          40,
          40,
          35,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          20,
          0,
          20,
          20,
          20,
          25,
          30
        ], // Abad Santos
        [
          45,
          45,
          40,
          40,
          40,
          35,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          20,
          0,
          20,
          20,
          25,
          25
        ], // R. Papa
        [
          45,
          45,
          40,
          40,
          40,
          35,
          35,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          20,
          0,
          20,
          25,
          25
        ], // 5th Avenue
        [
          50,
          45,
          45,
          40,
          40,
          40,
          40,
          35,
          35,
          35,
          35,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          25,
          20,
          20,
          20,
          0,
          20,
          25
        ], // Monumento
        [
          50,
          50,
          45,
          45,
          45,
          40,
          40,
          40,
          40,
          35,
          35,
          35,
          35,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          25,
          25,
          20,
          0,
          20
        ], // Balintawak
        [
          55,
          50,
          50,
          50,
          45,
          45,
          45,
          40,
          40,
          40,
          40,
          35,
          35,
          35,
          35,
          30,
          30,
          30,
          30,
          30,
          25,
          25,
          25,
          20,
          0
        ], // Fernando Poe Jr.
      ];

      // Precise LRT-1 50% Discount lookup matrix
      final List<List<int>> lrt1DiscMatrix = [
        [
          0,
          10,
          10,
          13,
          13,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          20,
          20,
          20,
          20,
          20,
          23,
          23,
          23,
          23,
          25,
          25,
          28
        ], // Dr. Santos
        [
          10,
          0,
          10,
          10,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          20,
          20,
          20,
          20,
          23,
          23,
          23,
          25,
          25,
          25
        ], // Ninoy Aquino
        [
          10,
          10,
          0,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          20,
          20,
          20,
          20,
          20,
          23,
          23,
          25
        ], // PITX
        [
          13,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          18,
          20,
          20,
          20,
          20,
          23,
          25
        ], // MIA Road
        [
          13,
          13,
          10,
          10,
          0,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          18,
          20,
          20,
          20,
          23,
          23
        ], // Redemptorist
        [
          15,
          13,
          13,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          20,
          20,
          23
        ], // Baclaran
        [
          15,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          18,
          20,
          20,
          23
        ], // EDSA
        [
          15,
          15,
          13,
          13,
          13,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          15,
          18,
          18,
          18,
          20,
          20
        ], // Libertad
        [
          15,
          15,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          15,
          18,
          18,
          20,
          20
        ], // Gil Puyat
        [
          18,
          15,
          15,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          15,
          18,
          18,
          20
        ], // Vito Cruz
        [
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          18,
          18,
          20
        ], // Quirino
        [
          18,
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          13,
          15,
          15,
          15,
          18,
          18
        ], // Pedro Gil
        [
          18,
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          13,
          15,
          15,
          18,
          18
        ], // UN Avenue
        [
          20,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          15,
          18
        ], // Central
        [
          20,
          18,
          18,
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          10,
          13,
          13,
          13,
          13,
          15,
          18
        ], // Carriedo
        [
          20,
          20,
          18,
          18,
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          10,
          13,
          13,
          13,
          15,
          15
        ], // D. Jose
        [
          20,
          20,
          18,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          10,
          13,
          13,
          15,
          15
        ], // Bambang
        [
          20,
          20,
          20,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          10,
          13,
          13,
          15
        ], // Tayuman
        [
          23,
          20,
          20,
          18,
          18,
          18,
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          13,
          15
        ], // Blumentritt
        [
          23,
          20,
          20,
          20,
          18,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          10,
          0,
          10,
          10,
          10,
          13,
          15
        ], // Abad Santos
        [
          23,
          23,
          20,
          20,
          20,
          18,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          10,
          0,
          10,
          10,
          13,
          13
        ], // R. Papa
        [
          23,
          23,
          20,
          20,
          20,
          18,
          18,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          10,
          0,
          10,
          13,
          13
        ], // 5th Avenue
        [
          25,
          23,
          23,
          20,
          20,
          20,
          20,
          18,
          18,
          18,
          18,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          13,
          10,
          10,
          10,
          0,
          10,
          13
        ], // Monumento
        [
          25,
          25,
          23,
          23,
          23,
          20,
          20,
          20,
          20,
          18,
          18,
          18,
          18,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          13,
          13,
          10,
          0,
          10
        ], // Balintawak
        [
          28,
          25,
          25,
          25,
          23,
          23,
          23,
          20,
          20,
          20,
          20,
          18,
          18,
          18,
          18,
          15,
          15,
          15,
          15,
          15,
          13,
          13,
          13,
          10,
          0
        ], // FPJ
      ];

      // Mapping station order to matrix index (1-25 range)
      // Dr. Santos (25) -> index 0; FPJ (1) -> index 24.
      int sIdx = (25 - source.order).clamp(0, 24);
      int dIdx = (25 - dest.order).clamp(0, 24);
      sv = lrt1SVMatrix[sIdx][dIdx];
      sj = lrt1SJMatrix[sIdx][dIdx];
      num disc = lrt1DiscMatrix[sIdx][dIdx];

      return {
        'sv': sv,
        'sj': sj,
        'sv50': disc.toDouble(),
        'sj50': disc.toDouble()
      };
    } else if (source.line == 'MRT3') {
      // Precise MRT-3 Single Journey (SJT) lookup matrix
      // Note: Beep card rates are identical to SJT on this line
      final List<List<int>> mrt3SJMatrix = [
        [0, 13, 13, 16, 16, 20, 20, 20, 24, 24, 24, 28, 28], // North Ave
        [13, 0, 13, 13, 16, 16, 20, 20, 20, 24, 24, 24, 28], // Quezon Ave
        [13, 13, 0, 13, 13, 16, 16, 20, 20, 20, 24, 24, 24], // GMA Kamuning
        [16, 13, 13, 0, 13, 13, 16, 16, 20, 20, 20, 24, 24], // Cubao
        [16, 16, 13, 13, 0, 13, 13, 16, 16, 20, 20, 20, 24], // Santolan
        [20, 16, 16, 13, 13, 0, 13, 13, 16, 16, 20, 20, 20], // Ortigas
        [20, 20, 16, 16, 13, 13, 0, 13, 13, 16, 16, 20, 20], // Shaw
        [20, 20, 20, 16, 16, 13, 13, 0, 13, 13, 16, 16, 20], // Boni
        [24, 20, 20, 20, 16, 16, 13, 13, 0, 13, 13, 16, 16], // Guadalupe
        [24, 24, 20, 20, 20, 16, 16, 13, 13, 0, 13, 13, 16], // Buendia
        [24, 24, 24, 20, 20, 20, 16, 16, 13, 13, 0, 13, 13], // Ayala
        [28, 24, 24, 24, 20, 20, 20, 16, 16, 13, 13, 0, 13], // Magallanes
        [28, 28, 24, 24, 24, 20, 20, 20, 16, 16, 13, 13, 0], // Taft Ave
      ];

      // Precise MRT-3 50% Discount lookup matrix
      final List<List<int>> mrt3DiscMatrix = [
        [0, 6, 6, 8, 8, 10, 10, 10, 12, 12, 12, 14, 14], // North Ave
        [6, 0, 6, 6, 8, 8, 10, 10, 10, 12, 12, 12, 14], // Quezon Ave
        [6, 6, 0, 6, 6, 8, 8, 10, 10, 10, 12, 12, 12], // GMA Kamuning
        [8, 6, 6, 0, 6, 6, 8, 8, 10, 10, 10, 12, 12], // Cubao
        [8, 8, 6, 6, 0, 6, 6, 8, 8, 10, 10, 10, 12], // Santolan
        [10, 8, 8, 6, 6, 0, 6, 6, 8, 8, 10, 10, 10], // Ortigas
        [10, 10, 8, 8, 6, 6, 0, 6, 6, 8, 8, 10, 10], // Shaw
        [10, 10, 10, 8, 8, 6, 6, 0, 6, 6, 8, 8, 10], // Boni
        [12, 10, 10, 10, 8, 8, 6, 6, 0, 6, 6, 8, 8], // Guadalupe
        [12, 12, 10, 10, 10, 8, 8, 6, 6, 0, 6, 6, 8], // Buendia
        [12, 12, 12, 10, 10, 10, 8, 8, 6, 6, 0, 6, 6], // Ayala
        [14, 12, 12, 12, 10, 10, 10, 8, 8, 6, 6, 0, 6], // Magallanes
        [14, 14, 12, 12, 12, 10, 10, 10, 8, 8, 6, 6, 0], // Taft Ave
      ];

      int sIdx = (source.order - 1).clamp(0, 12);
      int dIdx = (dest.order - 1).clamp(0, 12);
      sj = mrt3SJMatrix[sIdx][dIdx];
      sv = sj; // Beep matches SJT for MRT-3
      num disc = mrt3DiscMatrix[sIdx][dIdx];

      return {
        'sv': sv,
        'sj': sj,
        'sv50': disc.toDouble(),
        'sj50': disc.toDouble(),
      };
    } else if (source.line == 'LRT2') {
      // Precise LRT-2 Stored Value (Beep) lookup matrix
      final List<List<int>> lrt2SVMatrix = [
        [13, 15, 16, 18, 19, 21, 22, 23, 25, 26, 28, 31, 33], // Recto
        [15, 13, 15, 17, 18, 19, 21, 22, 24, 25, 27, 29, 32], // Legarda
        [16, 15, 13, 15, 16, 18, 19, 20, 22, 23, 26, 28, 30], // Pureza
        [18, 17, 15, 13, 15, 16, 17, 19, 20, 22, 24, 26, 29], // V. Mapa
        [19, 18, 16, 15, 13, 14, 16, 17, 19, 20, 22, 24, 27], // J. Ruiz
        [21, 19, 18, 16, 14, 13, 15, 16, 18, 19, 21, 23, 26], // Gilmore
        [22, 21, 19, 17, 16, 15, 13, 15, 16, 18, 20, 22, 25], // Betty Go
        [23, 22, 20, 19, 17, 16, 15, 13, 15, 16, 19, 21, 23], // Cubao
        [25, 24, 22, 20, 19, 18, 16, 15, 13, 14, 17, 19, 22], // Anonas
        [26, 25, 23, 22, 20, 19, 18, 16, 14, 13, 16, 18, 21], // Katipunan
        [28, 27, 26, 24, 22, 21, 20, 19, 17, 16, 13, 15, 18], // Santolan
        [31, 29, 28, 26, 24, 23, 22, 21, 19, 18, 15, 13, 16], // Marikina
        [33, 32, 30, 29, 27, 26, 25, 23, 22, 21, 18, 16, 13], // Antipolo
      ];

      // Precise LRT-2 Single Journey (SJT) lookup matrix
      final List<List<int>> lrt2SJMatrix = [
        [0, 15, 20, 20, 20, 25, 25, 25, 25, 30, 30, 35, 35], // Recto
        [15, 0, 15, 20, 20, 20, 25, 25, 25, 25, 30, 30, 35], // Legarda
        [20, 15, 0, 15, 20, 20, 20, 20, 25, 25, 30, 30, 30], // Pureza
        [20, 20, 15, 0, 15, 20, 20, 20, 20, 25, 25, 30, 30], // V. Mapa
        [20, 20, 20, 15, 0, 15, 20, 20, 20, 20, 25, 25, 30], // J. Ruiz
        [25, 20, 20, 20, 15, 0, 15, 20, 20, 20, 25, 25, 30], // Gilmore
        [25, 25, 20, 20, 20, 15, 0, 15, 20, 20, 20, 25, 25], // Betty Go
        [25, 25, 20, 20, 20, 20, 15, 0, 15, 20, 20, 25, 25], // Cubao
        [25, 25, 25, 20, 19, 18, 20, 15, 0, 15, 20, 20, 22], // Anonas
        [30, 25, 25, 25, 20, 20, 20, 20, 15, 0, 20, 20, 25], // Katipunan
        [30, 30, 30, 25, 25, 25, 20, 20, 20, 20, 0, 15, 20], // Santolan
        [35, 30, 30, 30, 25, 25, 25, 25, 20, 20, 15, 0, 20], // Marikina
        [35, 35, 30, 30, 30, 30, 25, 25, 25, 25, 20, 20, 0], // Antipolo
      ];

      // Precise LRT-2 50% Discount lookup matrix
      final List<List<int>> lrt2DiscMatrix = [
        [0, 8, 10, 10, 10, 13, 13, 13, 13, 15, 15, 18, 18], // Recto
        [8, 0, 8, 10, 10, 10, 13, 13, 13, 13, 15, 15, 18], // Legarda
        [10, 8, 0, 8, 10, 10, 10, 10, 13, 13, 15, 15, 15], // Pureza
        [10, 10, 8, 0, 8, 10, 10, 10, 10, 13, 13, 15, 15], // V. Mapa
        [10, 10, 10, 8, 0, 8, 10, 10, 10, 10, 13, 13, 15], // J. Ruiz
        [13, 10, 10, 10, 8, 0, 8, 10, 10, 10, 13, 13, 15], // Gilmore
        [13, 13, 10, 10, 10, 8, 0, 8, 10, 10, 10, 13, 13], // Betty Go
        [13, 13, 10, 10, 10, 10, 8, 0, 8, 10, 10, 13, 13], // Cubao
        [13, 13, 13, 10, 10, 10, 10, 8, 0, 8, 10, 10, 13], // Anonas
        [15, 13, 13, 13, 10, 10, 10, 10, 8, 0, 10, 10, 13], // Katipunan
        [15, 15, 15, 13, 13, 13, 10, 10, 10, 10, 0, 8, 10], // Santolan
        [18, 15, 15, 15, 13, 13, 13, 13, 10, 10, 8, 0, 10], // Marikina
        [18, 18, 15, 15, 15, 15, 13, 13, 13, 13, 10, 10, 0], // Antipolo
      ];

      int sIdx = (source.order - 1).clamp(0, 12);
      int dIdx = (dest.order - 1).clamp(0, 12);
      sv = lrt2SVMatrix[sIdx][dIdx];
      sj = lrt2SJMatrix[sIdx][dIdx];
      num sjDisc = lrt2DiscMatrix[sIdx][dIdx];

      return {
        'sv': sv,
        'sj': sj,
        'sv50':
            sv / 2.0, // Stored Value promo is exactly 50% (allowing decimals)
        'sj50': sjDisc
            .toDouble(), // Single Journey discount follows the integer rounding matrix
      };
    }

    return {
      'sv': sv,
      'sj': sj,
      'sv50': (sj / 2).ceil(),
      'sj50': (sj / 2).ceil(),
    };
  }

  Map<String, dynamic> getFareResult(Station source, Station dest,
      {String userType = 'normal'}) {
    if (source.id == dest.id) {
      return {'sv': 0, 'sj': 0, 'sv50': 0, 'sj50': 0};
    }

    Map<String, dynamic> fares;

    // Cross-line logic
    if (source.line != dest.line) {
      // 1. Determine transfer point
      String? transferLineA;
      int? transferOrderA;
      String? transferLineB;
      int? transferOrderB;

      // LRT1 <-> MRT3 (Via EDSA/Taft)
      if ((source.line == 'LRT1' && dest.line == 'MRT3') ||
          (source.line == 'MRT3' && dest.line == 'LRT1')) {
        transferLineA = 'LRT1';
        transferOrderA = 19; // EDSA
        transferLineB = 'MRT3';
        transferOrderB = 13; // Taft
      }
      // LRT1 <-> LRT2 (Via D.Jose/Recto)
      else if ((source.line == 'LRT1' && dest.line == 'LRT2') ||
          (source.line == 'LRT2' && dest.line == 'LRT1')) {
        transferLineA = 'LRT1';
        transferOrderA = 10; // D. Jose
        transferLineB = 'LRT2';
        transferOrderB = 1; // Recto
      }
      // LRT2 <-> MRT3 (Via Cubao)
      else if ((source.line == 'LRT2' && dest.line == 'MRT3') ||
          (source.line == 'MRT3' && dest.line == 'LRT2')) {
        transferLineA = 'LRT2';
        transferOrderA = 8; // Cubao
        transferLineB = 'MRT3';
        transferOrderB = 4; // Cubao
      }

      if (transferLineA != null) {
        // Build dummy transfer stations
        final dummyA = Station(
            id: 'tx-a',
            name: 'Transfer A',
            line: transferLineA,
            order: transferOrderA!,
            lat: 0,
            lng: 0,
            isTransfer: true,
            isTerminus: false,
            isExtension: false,
            opensOnLeft: false,
            connections: [],
            structureType: 'Elevated');
        final dummyB = Station(
            id: 'tx-b',
            name: 'Transfer B',
            line: transferLineB!,
            order: transferOrderB!,
            lat: 0,
            lng: 0,
            isTransfer: true,
            isTerminus: false,
            isExtension: false,
            opensOnLeft: false,
            connections: [],
            structureType: 'Elevated');

        // Sum the fares
        final leg1 = calculateFares(
            source.line == transferLineA ? source : dest, dummyA);
        final leg2 = calculateFares(
            source.line == transferLineB ? source : dest, dummyB);

        fares = {
          'sv': leg1['sv']! + leg2['sv']!,
          'sj': leg1['sj']! + leg2['sj']!,
          'sv50': leg1['sv50']! + leg2['sv50']!,
          'sj50': leg1['sj50']! + leg2['sj50']!,
        };
      } else {
        // Fallback for unlinked lines
        fares = calculateFares(source, dest);
      }
    } else {
      // Intra-line
      fares = calculateFares(source, dest);
    }

    Map<String, num> result = {
      'sv': fares['sv']!,
      'sj': fares['sj']!,
      'sv50': fares['sv50']!,
      'sj50': fares['sj50']!,
      'isPromo': 0,
    };

    // [Libreng Sakay Override]
    final activeEvents = TransitAlertService.activeFreeRides;
    final now = DateTime.now();
    for (var event in activeEvents) {
      bool isMatch = (event.line == 'ALL' || event.line == source.line);
      bool isSameDate = event.date.day == now.day &&
          event.date.month == now.month &&
          event.date.year == now.year;

      bool isTimeMatch = true;
      if (event.startHourRange != null) {
        isTimeMatch = false;
        final hour = now.hour;
        for (int i = 0; i < event.startHourRange!.length; i += 2) {
          if (hour >= event.startHourRange![i] &&
              hour < event.startHourRange![i + 1]) {
            isTimeMatch = true;
            break;
          }
        }
      }

      if (isMatch && isSameDate && isTimeMatch) {
        return {
          'sv': 0.0,
          'sj': 0.0,
          'sv50': 0.0,
          'sj50': 0.0,
          'sv_base': 0.0,
          'sj_base': 0.0,
          'isFreeRide': 1,
          'freeRideEvent': event.eventName,
          'freeRideDuration': event.duration,
        };
      }
    }

    // Apply the discount to the main fields if the user is a senior, student, or white beep holder
    if (userType == 'senior' ||
        userType == 'student' ||
        userType == 'white_beep') {
      return {
        ...result,
        'sj_base': result['sj']!,
        'sv_base': result['sv']!,
        'sj': result[
            'sj50']!, // Use the pre-calculated slightly different discounted rate
        'sv': result['sv50']!,
        'isDiscounted': 1,
      };
    }

    return {
      ...result,
      'sj_base': result['sj']!,
      'sv_base': result['sv']!,
      'isDiscounted': 0,
    };
  }
}

// LRT-2 (Purple Line) Station Data
// Covers: Pier 4 (Extension) → Antipolo
// Total: 16 stations (13 operational + 3 extension)

final List<Map<String, dynamic>> lrt2Stations = [
  // ── West Extension (Under Construction) ────────────────────────────────────
  {
    'code': 'PL-EXT03',
    'id': 'lrt2-pier4',
    'name': 'Pier 4',
    'line': 'LRT2',
    'order': -2,
    'lat': 14.603531,
    'lng': 120.961536,
    'city': 'Manila',
    'province': 'Metro Manila',
    'isExtension': true,
    'imageUrl': '',
    'landmark': 'North Port Passenger Terminal',
    'connectingRoutes':
        '• Ferry Service: Passenger Terminal (North Port)\n• Bus Routes: Route 35 (Recto), 22, 44, 45, 46, 47 (Manila Northport)\n• Jeep/e-Jeep Routes: Pier 4 - Divisoria, Pier 4 - North Harbor'
  },
  {
    'code': 'PL-EXT02',
    'id': 'lrt2-divisoria',
    'name': 'Divisoria',
    'line': 'LRT2',
    'order': -1,
    'lat': 14.602933,
    'lng': 120.967778,
    'city': 'Manila',
    'province': 'Metro Manila',
    'isExtension': true,
    'imageUrl': '',
    'landmark': 'Divisoria Market, 168 Mall',
    'connectingRoutes': 'none'
  },
  {
    'code': 'PL-EXT01',
    'id': 'lrt2-tutuban',
    'name': 'Tutuban',
    'line': 'LRT2',
    'order': 0,
    'lat': 14.606183,
    'lng': 120.971958,
    'city': 'Manila',
    'province': 'Metro Manila',
    'isTransfer': true,
    'isExtension': true,
    'imageUrl': '',
    'landmark': 'Tutuban Mall',
    'connectingRoutes':
        '• Transfer of Train Line: NSCR, PNR (Tutuban)\n• Bus Routes: Route 8, PNR 1, PNR 2 (Divisoria)\n• Jeep/e-Jeep Routes: Divisoria - Recto, Tutuban - Blumentritt'
  },
  // ── Operational Stations ────────────────────────────────────────────────────
  {
    'code': 'PL-01',
    'id': 'lrt2-recto',
    'name': 'Recto',
    'line': 'LRT2',
    'order': 1,
    'lat': 14.6036,
    'lng': 120.9831,
    'city': 'Manila',
    'province': 'Metro Manila',
    'isTransfer': true,
    'isTerminus': true,
    'imageUrl': 'assets/image/Stations/LRT2/Recto_Station.jpg',
    'landmark': 'Isetann Recto',
    'connectingRoutes':
        '• Transfer of Train Line: LRT-1 (Doroteo Jose), MRT-8 (Lerma)\n• Bus Routes: Route 13, 19, 20, 21, 42 (Avenida/Recto)\n• Jeep/e-Jeep Routes: Recto - Gastambide, Morayta - Recto, Divisoria - Cubao'
  },
  {
    'code': 'PL-02',
    'id': 'lrt2-legarda',
    'name': 'Legarda',
    'line': 'LRT2',
    'order': 2,
    'lat': 14.6009,
    'lng': 120.9926,
    'city': 'Manila',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/Legarda_Station.jpg',
    'landmark': 'San Sebastian College',
    'connectingRoutes':
        '• Bus Routes: Route 2, 3 (Legarda)\n• Jeep/e-Jeep Routes: Legarda - Bustillos, Malacañang Loop'
  },
  {
    'code': 'PL-03',
    'id': 'lrt2-pureza',
    'name': 'Pureza',
    'line': 'LRT2',
    'order': 3,
    'lat': 14.6018,
    'lng': 121.0052,
    'city': 'Manila',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/Pureza_Station.jpg',
    'landmark': 'PUP Mabini Campus',
    'connectingRoutes':
        '• Transfer of Train Line: PNR (Santa Mesa)\n• Bus Routes: Route 2, 3 (Pureza)\n• Ferry Service: Pasig River Ferry (PUP Ferry Station)\n• Jeep/e-Jeep Routes: PUP Loop, Lardizabal - Pag-asa'
  },
  {
    'code': 'PL-04',
    'id': 'lrt2-v-mapa',
    'name': 'V. Mapa',
    'line': 'LRT2',
    'order': 4,
    'lat': 14.6042,
    'lng': 121.0171,
    'city': 'Manila',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/V.Mapa_Station.jpg',
    'landmark': 'SM City Santa Mesa',
    'connectingRoutes':
        '• Bus Routes: Route 2, 3 (SM City Sta. Mesa)\n• Jeep/e-Jeep Routes: Stop & Shop - Boni, V. Mapa - Pasig'
  },
  {
    'code': 'PL-05',
    'id': 'lrt2-j-ruiz',
    'name': 'J. Ruiz',
    'line': 'LRT2',
    'order': 5,
    'lat': 14.6106,
    'lng': 121.0262,
    'city': 'San Juan',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/J.Ruiz_Station.jpg',
    'landmark': 'Pinaglabanan Shrine',
    'connectingRoutes':
        '• Bus Routes: Route 3 (J. Ruiz)\n• Jeep/e-Jeep Routes: San Juan - Little Baguio, San Juan Local'
  },
  {
    'code': 'PL-06',
    'id': 'lrt2-gilmore',
    'name': 'Gilmore',
    'line': 'LRT2',
    'order': 6,
    'lat': 14.6135,
    'lng': 121.0342,
    'city': 'Quezon City',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/Gilmore_Station.jpg',
    'landmark': 'St. Paul University, IT Center',
    'connectingRoutes':
        '• QCity Bus: Route 6 (Robinsons Magnolia)\n• Bus Routes: Route 3 (Gilmore)\n• Jeep/e-Jeep Routes: Gilmore - Greenhills, San Juan - Cubao'
  },
  {
    'code': 'PL-07',
    'id': 'lrt2-betty-go',
    'name': 'Betty Go-Belmonte',
    'line': 'LRT2',
    'order': 7,
    'lat': 14.6187,
    'lng': 121.0430,
    'city': 'Quezon City',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/Betty_Go-Belmonte_Station.jpg',
    'landmark': 'Quezon City Reception House',
    'connectingRoutes':
        '• Bus Routes: Route 3 (Betty Go-Belmonte)\n• Jeep/e-Jeep Routes: P. Tuazon - Cubao, Betty Go - Rosario'
  },
  {
    'code': 'PL-08',
    'id': 'lrt2-cubao',
    'name': 'Araneta Center-Cubao',
    'line': 'LRT2',
    'order': 8,
    'lat': 14.6228,
    'lng': 121.0528,
    'city': 'Quezon City',
    'province': 'Metro Manila',
    'isTransfer': true,
    'imageUrl': 'assets/image/Stations/LRT2/Araneta_Center-Cubao_Station.jpg',
    'landmark': 'Gateway Mall, Smart Araneta',
    'connectingRoutes':
        '• Transfer of Train Line: MRT-3\n• Bus Routes: Route 3 (Gateway Mall), 51, 53, 61 (Farmers Plaza)\n• Jeep/e-Jeep Routes: Cubao - Rodriguez, Cubao - Libis, Cubao - Rosario'
  },
  {
    'code': 'PL-09',
    'id': 'lrt2-anonas',
    'name': 'Anonas',
    'line': 'LRT2',
    'order': 9,
    'lat': 14.6280,
    'lng': 121.0647,
    'city': 'Quezon City',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/Anonas_Station.jpg',
    'landmark': 'St. Joseph Church',
    'connectingRoutes':
        '• Transfer of Train Line: MMS\n• QCity Bus: Route 3 (Anonas)\n• Bus Routes: Route 3, 51 (Anonas)\n• Jeep/e-Jeep Routes: Project 2 & 3 - Cubao, Molave - Cubao'
  },
  {
    'code': 'PL-10',
    'id': 'lrt2-katipunan',
    'name': 'Katipunan',
    'line': 'LRT2',
    'order': 10,
    'lat': 14.6310,
    'lng': 121.0727,
    'city': 'Quezon City',
    'province': 'Metro Manila',
    'opensOnLeft': true,
    'imageUrl': 'assets/image/Stations/LRT2/Katipunan_Station.jpg',
    'landmark': 'Ateneo de Manila, UP Diliman',
    'connectingRoutes':
        '• QCity Bus: Route 3, 7 (Katipunan Interchange)\n• Bus Routes: Route 3, 18, 36, 39, 41, 50, 51, 56 (Aurora Blvd)\n• Jeep/e-Jeep Routes: UP Loop'
  },
  {
    'code': 'PL-11',
    'id': 'lrt2-santolan',
    'name': 'Santolan',
    'line': 'LRT2',
    'order': 11,
    'lat': 14.6221,
    'lng': 121.0859,
    'city': 'Marikina',
    'province': 'Metro Manila',
    'opensOnLeft': true,
    'imageUrl': 'assets/image/Stations/LRT2/Santolan_Station.jpg',
    'landmark': 'SM City Marikina',
    'connectingRoutes':
        '• Bus Routes: Route 3, 56 (SM Marikina)\n• Jeep/e-Jeep Routes: SM Marikina - Pasig, Santolan - Libis'
  },
  {
    'code': 'PL-12',
    'id': 'lrt2-marikina-pasig',
    'name': 'Marikina-Pasig',
    'line': 'LRT2',
    'order': 12,
    'lat': 14.6205,
    'lng': 121.1003,
    'city': 'Pasig',
    'province': 'Metro Manila',
    'imageUrl': 'assets/image/Stations/LRT2/Marikina-Pasig_Station.jpg',
    'landmark': 'Robinsons Metro East',
    'connectingRoutes':
        '• Bus Routes: Route 3, 56 (Robinsons Metro East)\n• Jeep/e-Jeep Routes: Robinson - Marikina, Pasig - Marikina'
  },
  {
    'code': 'PL-13',
    'id': 'lrt2-antipolo',
    'name': 'Antipolo',
    'line': 'LRT2',
    'order': 13,
    'lat': 14.6248,
    'lng': 121.1213,
    'city': 'Antipolo',
    'province': 'Rizal',
    'isTerminus': true,
    'imageUrl': 'assets/image/Stations/LRT2/Antipolo_Station.jpg',
    'landmark': 'SM City Masinag',
    'connectingRoutes':
        '• Bus Routes: Route 3, 56 (SM Masinag)\n• Jeep/e-Jeep Routes: Masinag - Cogeo, Masinag - Padilla'
  },
  // ── East Extension (Planned) ────────────────────────────────────
  {
    'code': 'PL-14',
    'id': 'lrt2-cogeo',
    'name': 'Cogeo',
    'line': 'LRT2',
    'order': 14,
    'lat': 14.6262,
    'lng': 121.1350,
    'city': 'Antipolo',
    'province': 'Rizal',
    'isExtension': true,
    'imageUrl': '',
    'landmark': 'TBA',
    'connectingRoutes': 'TBA'
  },
];

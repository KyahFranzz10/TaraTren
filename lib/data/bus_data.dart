class BusRoute {
  final String routeId;
  final String name;
  final String terminals;
  final String structure;
  final String areas;
  final String? notes;
  final String category; // Added category

  const BusRoute({
    required this.routeId,
    required this.name,
    required this.terminals,
    required this.structure,
    required this.areas,
    this.notes,
    this.category = 'City Bus',
  });
}

const List<BusRoute> busRoutes = [
  BusRoute(
    routeId: '1',
    name: 'EDSA Carousel',
    terminals: 'Monumento ↔ PITX',
    structure: 'Monumento, EDSA, Globe Rotonda, Macapagal Blvd',
    areas: 'Caloocan, Makati, Mandaluyong, Parañaque, Pasay, QC',
    notes: 'Still widely known as Route E.',
  ),
  BusRoute(
    routeId: '2',
    name: 'Angono – Quiapo',
    terminals: 'SM Angono ↔ Quiapo Church',
    structure: 'Ortigas Ave, Granada St, N. Domingo, Magsaysay Blvd, Legarda',
    areas: 'Angono, Cainta, Manila, Pasig, San Juan, QC',
    notes: 'Most buses terminate at Taytay; covers pre-pandemic Taytay-Quiapo.',
  ),
  BusRoute(
    routeId: '3',
    name: 'Antipolo – Quiapo',
    terminals: 'Robinsons Antipolo ↔ Quiapo Church',
    structure: 'Sumulong Hwy, Aurora Blvd, Magsaysay Blvd, Quezon Blvd',
    areas: 'Antipolo, Cainta, Manila, Marikina, QC, San Juan',
    notes:
        'Serves as augmentation for LRT Line 2; many units terminate at Farmers Plaza.',
  ),
  BusRoute(
    routeId: '4',
    name: 'PITX – BGC',
    terminals: 'Venice Grand Canal ↔ PITX',
    structure: 'McKinley Rd, C-5, 32nd St, Kalayaan Flyover, Gil Puyat Ave',
    areas: 'Parañaque, Pasay, Taguig',
    notes:
        'Mostly operated by Green Frog; often terminates at Kalayaan instead of Venice.',
  ),
  BusRoute(
    routeId: '5',
    name: 'NLET – PITX',
    terminals: 'NLET (Sta. Maria) ↔ PITX',
    structure: 'NLEX, A. Bonifacio Ave, Dimasalang, Taft Ave, Macapagal Blvd',
    areas: 'Bocaue, Manila, Parañaque, Pasay, QC, Sta. Maria,Bulacan',
    notes: 'Originally Route 39.',
  ),
  BusRoute(
    routeId: '6',
    name: 'Sapang Palay – PITX via Commonwealth Avenue, Quezon Avenue ',
    terminals: 'Sapang Palay ↔ PITX',
    structure: 'Quirino Hwy, Commonwealth Ave, Quezon Ave, Taft Ave',
    areas: 'Caloocan, Manila, SJDM, Parañaque, Pasay, QC',
    notes: 'Route recently split; extended to northern SJDM areas in Oct 2025.',
  ),
  BusRoute(
    routeId: '6A',
    name: 'Sapang Palay – NIA via Commonwealth Avenue, East Avenue',
    terminals: 'Sapang Palay ↔ NIA South Road',
    structure: 'Quirino Hwy, Commonwealth Ave, East Ave, NIA Road',
    areas: 'Caloocan, Norzagaray, QC, SJDM',
    notes: 'Created in 2025 to serve the Triangle Park/Government area.',
  ),
  BusRoute(
    routeId: '7',
    name: 'Fairview – PITX via Commonwealth Avenue, Quezon Avenue',
    terminals: 'SM City Fairview ↔ PITX',
    structure: 'Commonwealth Ave, Quezon Ave, España, Taft Ave',
    areas: 'Manila, Parañaque, Pasay, QC',
    notes:
        'Modified in 2025 to bypass East Ave and go directly via Quezon Ave.',
  ),
  BusRoute(
    routeId: '8',
    name: 'Angat – Divisoria',
    terminals: 'Angat Public Market ↔ Divisoria',
    structure: 'NLEX, A. Bonifacio Ave, Rizal Ave, Abad Santos Ave',
    areas: 'Angat, Caloocan, Manila, QC, Sta. Maria',
    notes: 'Originally a provincial route integrated into city service.',
  ),
  BusRoute(
    routeId: '9',
    name: 'Angat – Monumento',
    terminals: 'Angat Public Market ↔ Monumento',
    structure: 'NLEX, Fortunato Halili Ave, EDSA',
    areas: 'Angat, Bocaue, Caloocan, Norzagaray, Sta. Maria',
    notes: 'Formerly Route 22.',
  ),
  BusRoute(
    routeId: '10',
    name: 'Ayala – Alabang',
    terminals: 'One Ayala ↔ Vista Terminal',
    structure: 'SLEX, East Service Rd, Ayala Ave',
    areas: 'Makati, Muntinlupa, Parañaque',
    notes: 'Some units terminate at Alabang South Station.',
  ),
  BusRoute(
    routeId: '11',
    name: 'Pasay – Balibago via Ayala Avenue',
    terminals: 'Gil Puyat Stn ↔ Santa Rosa',
    structure: 'SLEX, Ayala Ave, Taft Ave',
    areas: 'Makati, Pasay, Santa Rosa',
    notes: 'Originally Route 35; includes trips starting from One Ayala.',
  ),
  BusRoute(
    routeId: '12',
    name: 'Ayala – Biñan',
    terminals: 'Gil Puyat Stn ↔ Biñan (JAC)',
    structure: 'SLEX, Susana Heights, Ayala Ave, Taft Ave',
    areas: 'Biñan, Makati, Muntinlupa, San Pedro',
    notes:
        'Buses via Carmona Exit; others via Susana Heights terminate at Pacita.',
  ),
  BusRoute(
    routeId: '13',
    name: 'Bagong Silang – Sta. Cruz via Malinta Exit',
    terminals: 'Bagong Silang ↔ Avenida',
    structure: 'Gen. Luis St, NLEX, A. Bonifacio Ave, Blumentritt',
    areas: 'Caloocan, Manila, QC, Valenzuela',
    notes: 'Pre-pandemic route revived via Malinta Exit.',
  ),
  BusRoute(
    routeId: '14',
    name: 'Balagtas – PITX',
    terminals: 'Balagtas ↔ PITX',
    structure: 'MacArthur Hwy, Rizal Ave, Taft Ave, Macapagal Blvd',
    areas: 'Balagtas, Bulakan, Manila, Pasay',
    notes: 'Long-haul local service via MacArthur Highway.',
  ),
  BusRoute(
    routeId: '15A',
    name: 'BGC – Alabang',
    terminals: 'Market! Market! ↔ Vista Terminal Exchange',
    structure: 'Carlos P. Garcia Avenue / South Luzon Expressway',
    areas: 'Muntinlupa, Taguig',
  ),
  BusRoute(
    routeId: '15B',
    name: 'BGC – Pacita',
    terminals: 'Market! Market! ↔ Pacita Complex',
    structure:
        'All trips: Carlos P. Garcia Avenue / South Luzon Expressway / Manila South Road\n- Northbound: Gen. Malvar / Governor\'s Dr / Southwoods / Ecocentrum\n- Southbound: South Station / Susana Heights Access Road',
    areas: 'Biñan, Carmona, Muntinlupa, San Pedro, Taguig',
    notes: 'Key route for commuters from San Pedro to BGC.',
  ),
  BusRoute(
    routeId: '15C',
    name: 'BGC – Balibago',
    terminals: 'Market! Market! ↔ Santa Rosa Commercial Complex',
    structure:
        'Carlos P. Garcia Avenue / South Luzon Expressway / Santa Rosa–Tagaytay Road',
    areas: 'Santa Rosa, Taguig',
  ),
  BusRoute(
    routeId: '16',
    name: 'Eastwood Libis – Marriott Terminal via Acropolis',
    terminals: 'Eastwood City ↔ Newport City',
    structure:
        'Carlos P. Garcia Avenue, Upper McKinley Road, Venezia Drive, Turin Street, Lawton Avenue, Andrews Avenue, Domestic Road, NAIA Road',
    areas: 'Pasay, Pasig, Quezon City, Taguig',
    notes: 'Connects the East to the Airport via McKinley/BGC corridor.',
  ),
  BusRoute(
    routeId: '17',
    name: 'Fairview – Ayala',
    terminals: 'Novaliches ↔ Makati CBD',
    structure:
        'All trips: Quirino Highway / Commonwealth Avenue / Elliptical Road / Quezon Avenue / España Boulevard / Lerma Street / Quezon Boulevard / Padre Burgos Avenue / Taft Avenue / Gil Puyat Avenue / Ayala Avenue\n- Northbound: Ayala Avenue / Malugay Street / Zuellig Loop\n- Southbound: Belfast Street / Mindanao Avenue / EDSA',
    areas: 'Makati, Manila, Pasay, Quezon City',
    notes:
        'Originally a pre-pandemic SM Fairview-Baclaran via EDSA Ayala Avenue route. Buses terminate at Eton Centris',
  ),
  BusRoute(
    routeId: '18',
    name: 'SM North – PITX via C-5',
    terminals: 'SM North EDSA ↔ PITX',
    structure:
        'All trips: EDSA / Congressional Avenue / Luzon Avenue / Tandang Sora Avenue / Katipunan Avenue / Bonny Serrano Avenue / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / Upper McKinley Road / Venezia Drive / Turin Street / Lawton Avenue / Andrews Avenue / Domestic Road / NAIA Road / Seaside Drive / Macapagal Boulevard\n- Northbound: Junction Road / Eastwood Ave / Orchard Drive / Mindanao Avenue / North Avenue\n- Southbound: Park Avenue / Campus Avenue',
    areas: 'Parañaque, Pasay, Pasig, Quezon City, Taguig',
    notes:
        'Venice Grand Canal Mall acts as a semi-terminus, with most buses turning back north, instead of proceeding to PITX, or making PITX-Venice Grand Canal Mall and Venice Grand Canal Mall-North EDSA separate trips.',
  ),
  BusRoute(
    routeId: '19',
    name: 'Norzagaray FVR – Santa Cruz via Marilao Exit',
    terminals: 'Sapang Palay ↔ Avenida Bus Terminal',
    structure:
        'All trips: Balasing–San Jose Road / Roquero Avenue / Matiyaga Street / Maginhawa Street / Roquero Avenue / Bagong Buhay Avenue / Norzagaray / San Ignacio Street / Paso Street / San Jose Street / JP Rizal Street / San Ignacio Street / Villarica Road / Patubig Road / NLEX / A. Bonifacio Avenue / Blumentritt Road / Dimasalang Street / Doroteo Jose Street\n- Northbound: Oroquieta Road / San Lazaro Street / Maria Clara Street / Retiro Street / Roquero Avenue\n- Southbound: Aurora Boulevard / Laon Laan Street / A. Mendoza Street / Fugoso Street / Tomas Mapua Street',
    areas: 'Manila, Marilao, Norzagaray, Quezon City, San Jose del Monte',
  ),
  BusRoute(
    routeId: '20',
    name: 'Sapang Palay – Sta. Cruz via Malinta Exit',
    terminals: 'Sapang Palay ↔ Avenida Transport Terminal',
    structure:
        'All trips: Roquero Avenue / Bagong Buhay Avenue / Norzagaray / San Ignacio Street / Paso Street / San Jose Street / JP Rizal Street / San Ignacio Street / San Jose del Monte-Marilao Road / Santa Maria–Tungkong Mangga Road / Quirino Highway / Bocaue Road / Quirino Highway / General Luis Street / Bagbaguin Road / Paso De Blas Road / NLEX / A. Bonifacio Avenue / Blumentritt Road / Dimasalang Street\n- Northbound: Oroquieta Road / San Lazaro Street / Maria Clara Street / Retiro Street / Buenamar Street / Sarmiento Street / Belfast Street / Mindanao Avenue / Apayao Street / J.P. Rizal Street / San Jose Street / Paso Street\n- Southbound: Mahogany Street / Acacia Street / Aurora Boulevard / Laon Laan Street / A. Mendoza Street / Fugoso Street / Tomas Mapua Street',
    areas: 'Caloocan, Manila, Quezon City, San Jose del Monte, Valenzuela',
  ),
  BusRoute(
    routeId: '21',
    name: 'Sapang Palay – Santa Cruz',
    terminals: 'Sapang Palay ↔ Avenida Bus Terminal',
    structure:
        'All trips: Bagong Buhay Avenue / San Ignacio Street / Santa Maria–San Jose Road / Santa Maria Bypass Road / Fortunato Halili Avenue / NLEX / A. Bonifacio Avenue / Blumentritt Road / Dimasalang Street / Doroteo Jose Street\n- Northbound: Oroquieta Road / San Lazaro Street / Maria Clara Street / Retiro Street\n- Southbound: Aurora Boulevard / Laon Laan Street / A. Mendoza Street / Fugoso Street / Tomas Mapua Street',
    areas: 'Bocaue, Manila, Quezon City, San Jose del Monte, Santa Maria',
  ),
  BusRoute(
    routeId: '22',
    name: 'Sta. Maria – PITX via NLEX, R-10, Roxas Boulevard',
    terminals: 'Caypombo ↔ PITX',
    structure:
        'Fortunato Halili Avenue / NLEX / A. Bonifacio Avenue / 5th Avenue / C-3 Road / Radial Road 10 / Mel Lopez Boulevard / Bonifacio Drive / Roxas Boulevard / Seaside Drive / Macapagal Boulevard',
    areas: 'Bocaue, Manila, Parañaque, Pasay, Quezon City, Santa Maria',
  ),
  BusRoute(
    routeId: '23',
    name: 'Alabang – Plaza Lawton via Alabang-Zapote Road',
    terminals: 'Vista Terminal Exchange ↔ Lawton',
    structure:
        'All trips: Padre Burgos Avenue / Taft Avenue / Gil Puyat Avenue / Roxas Boulevard / Seaside Drive / Macapagal Boulevard / Pacific Avenue / Manila–Cavite Expressway / Alabang–Zapote Road / Bridgeway Avenue / Manila South Road\n- Southbound: Jose W. Diokno Boulevard',
    areas: 'Bacoor, Las Piñas, Manila, Muntinlupa, Parañaque, Pasay',
  ),
  BusRoute(
    routeId: '24',
    name: 'Alabang – Plaza Lawton via SSH',
    terminals: 'Vista Terminal Exchange ↔ Lawton',
    structure:
        'Alabang–Zapote Road / SLEX / Gil Puyat Avenue / Taft Avenue / Padre Burgos Avenue',
    areas: 'Makati, Manila, Muntinlupa, Parañaque, Pasay',
  ),
  BusRoute(
    routeId: '25',
    name: 'Biñan – Plaza Lawton',
    terminals: 'JAC Liner Biñan Terminal ↔ Lawton',
    structure:
        'Santo Domingo Street / A. Bonifacio Street / Manila South Road / SLEX / Osmeña Highway / Gil Puyat Avenue / Taft Avenue',
    areas: 'Biñan, Makati, Manila, Muntinlupa, San Pedro',
  ),
  BusRoute(
    routeId: '26',
    name: 'PITX – Cavite City',
    terminals: 'PITX ↔ Saulog Transit Terminal',
    structure:
        'All trips: Dra. Salamanca Street / Manila–Cavite Road / Magdiwang Highway / Tirona Highway / CAVITEX / Macapagal Boulevard\n- Westbound: Pacific Avenue / Julian Felipe Boulevard / M. Gregorio Road\n- Eastbound: Lopez Jaena Street / Miranda Street / Covelandia Road / Seaside Drive',
    areas: 'Cavite City, Kawit, Noveleta, Parañaque',
  ),
  BusRoute(
    routeId: '27',
    name: 'Dasmariñas – Lawton via PITX',
    terminals: 'Dasmariñas ↔ Lawton',
    structure:
        'All trips: Aguinaldo Highway / CAVITEX / Pacific Avenue / Macapagal Boulevard\n- Dasmarinas - Lawton: Pala-Pala Road, Jose W. Diokno Boulevard, Gil Puyat Avenue, Taft Avenue, Padre Burgos Avenue\n- Dasmarinas - PITX: Aguinaldo Highway, Macapagal Boulevard',
    areas: 'Bacoor, Dasmariñas, Imus, Parañaque, Pasay',
  ),
  BusRoute(
    routeId: '28',
    name: 'PITX – Naic',
    terminals: 'PITX ↔ Naic Grand Central Terminal',
    structure:
        'All trips: Poblete Street / Antero Soriano Highway / CAVITEX / Pacific Avenue / Macapagal Boulevard\n- Eastbound: Covelandia Road',
    areas: 'General Trias, Kawit, Naic, Noveleta, Parañaque, Tanza',
  ),
  BusRoute(
    routeId: '29',
    name: 'PITX – Silang',
    terminals: 'PITX ↔ Acienda Outlet Mall',
    structure:
        'All trips: Poblete Street / Antero Soriano Highway / CAVITEX / Pacific Avenue / Macapagal Boulevard\n- Eastbound: Covelandia Road',
    areas: 'General Trias, Kawit, Naic, Noveleta, Parañaque, Tanza',
  ),
  BusRoute(
    routeId: '30',
    name: 'PITX – Balibago',
    terminals: 'PITX ↔ Santa Rosa Commercial Complex',
    structure:
        'All trips: Pearl Road / Francisco A. Canicosa Avenue / Santa Rosa–Tagaytay Road / SLEX / Osmeña Highway / Gil Puyat Avenue / Roxas Boulevard / Macapagal Boulevard\n- Northbound: Emerald Road / Jose W. Diokno Boulevard / EDSA / Globe Rotonda\n- Southbound: Seaside Drive / Turquoise Road / Diamond Road / Zircon Road / Amethyst Road',
    areas: 'Makati, Parañaque, Pasay, Santa Rosa',
  ),
  BusRoute(
    routeId: '31',
    name: 'PITX – Trece Martires',
    terminals: 'PITX / Ayala ↔ SM City Trece Martires',
    structure:
        'All trips: Capitol Road / Governor\'s Drive / Trece Martires–Indang Road / Antero Soriano Highway / CAVITEX',
    areas:
        'Bacoor, Dasmariñas, General Trias, Imus, Parañaque, Tanza, Trece Martires',
  ),
  BusRoute(
    routeId: '32',
    name: 'PITX – General Mariano Alvarez',
    terminals: 'PITX ↔ Puregold GMA Cavite',
    structure:
        'Congressional Road / Governor\'s Drive / Molino–Paliparan Road / Bacoor Boulevard / Aguinaldo Boulevard / CAVITEX / Pacific Avenue / Macapagal Boulevard',
    areas: 'Bacoor, Dasmariñas, General Mariano Alvarez, Parañaque, Silang',
  ),
  BusRoute(
    routeId: '33',
    name: 'North EDSA – SJDM',
    terminals: 'SM North EDSA ↔ Starmall San Jose del Monte',
    structure:
        'All trips: EDSA / Congressional Avenue / Mindanao Avenue / Quirino Highway\n- Northbound: Belfast Street / Regalado Highway\n- Southbound: North Avenue',
    areas: 'Caloocan, Quezon City, San Jose del Monte',
  ),
  BusRoute(
    routeId: '34',
    name: 'PITX – Montalban via Quezon Avenue',
    terminals: 'PITX ↔ San Rafael',
    structure:
        'All trips: Rodriguez Highway / Jose P. Rizal Street / General Luna Avenue / Batasan–San Mateo Road / Batasan Road / Commonwealth Avenue / Elliptical Road / Quezon Avenue / España Boulevard / Lerma Street / Quezon Boulevard / Padre Burgos Avenue / Taft Avenue / Gil Puyat Avenue / Roxas Boulevard / Macapagal Boulevard\n- Northbound: Seaside Drive\n- Southbound: Jose W. Diokno Boulevard / EDSA / Globe Rotonda',
    areas: 'Manila, Parañaque, Pasay, Quezon City, Rodriguez, San Mateo',
  ),
  BusRoute(
    routeId: '35',
    name: 'PITX – Balagtas via MacArthur Highway',
    terminals: 'PITX ↔ Metrolink Bus Corp. Terminal',
    structure:
        'All trips: MacArthur Highway / Rizal Avenue / 5th Avenue / C-3 Road / Radial Road 10 / Mel Lopez Boulevard / Bonifacio Drive / Jose W. Diokno Boulevard / Macapagal Boulevard / Seaside Drive / NAIA Road\n- Northbound: Ninoy Aquino Avenue / Gil Puyat Avenue',
    areas:
        'Balagtas, Bocaue, Caloocan, Malabon, Manila, Marilao, Meycauayan, Navotas, Parañaque, Pasay, Valenzuela',
  ),
  BusRoute(
    routeId: '36',
    name: 'Alabang – Fairview (Nova Stop) via C5, Commonwealth Avenue',
    terminals: 'Vista Terminal Exchange ↔ Robinsons Novaliches',
    structure:
        'All trips: Mindanao Avenue / Commonwealth Avenue / Tandang Sora Avenue / Katipunan Avenue / Bonny Serrano Avenue / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / SLEX / Manila South Road\n- Northbound: East Service Road / Regalado Highway\n- Southbound: Belfast Street',
    areas: 'Muntinlupa, Pasig, Quezon City, Taguig',
  ),
  BusRoute(
    routeId: '37',
    name: 'Fairview – Monumento via Malinta Exit',
    terminals: 'Monumento ↔ Robinsons Novaliches',
    structure:
        'EDSA / NLEX / Bagbaguin Road / General Luis Street / Quirino Highway',
    areas: 'Caloocan, Quezon City, Valenzuela',
  ),
  BusRoute(
    routeId: '38',
    name: 'Pacita – Fairview (Nova Stop) via Baesa & Ayala Avenue',
    terminals: 'Pacita Complex ↔ SM City Fairview',
    structure:
        'All trips: Quirino Highway / NLEX / A. Bonifacio Avenue / Blumentritt Road / Dimasalang Street / Laon Laan Road / A. Mendoza Street / Quezon Boulevard / Padre Burgos Avenue / Taft Avenue / Quirino Avenue / Osmeña Highway / SLEX / Susana Heights Access Road / Manila South Road\n- Northbound: Retiro Street\n- Southbound: Aurora Boulevard / Ayala Boulevard / San Marcelino Street',
    areas: 'Makati, Manila, Muntinlupa, Quezon City, San Pedro',
  ),
  BusRoute(
    routeId: '39',
    name: 'Pacita – Fairview via C5, Commonwealth Avenue',
    terminals: 'Pacita Complex ↔ SM City Fairview',
    structure:
        'All trips: Mindanao Avenue / Commonwealth Avenue / Tandang Sora Avenue / Katipunan Avenue / Bonny Serrano Avenue / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / SLEX / Manila South Road / Susana Heights Access Road / Pacita Avenue\n- Northbound: Regalado Highway\n- Southbound: Belfast Street',
    areas: 'Muntinlupa, Pasig, Quezon City, San Pedro, Taguig',
  ),
  BusRoute(
    routeId: '40',
    name: 'Alabang – Fairview (Nova Stop) via Ayala Avenue',
    terminals: 'Vista Terminal Exchange ↔ Robinsons Novaliches',
    structure:
        'All trips: Quirino Highway / NLEX / A. Bonifacio Avenue / Blumentritt Road / Dimasalang Street / Laon Laan Road / A. Mendoza Street / Quezon Boulevard / Padre Burgos Avenue / Taft Avenue / Gil Puyat Avenue / Ayala Avenue / EDSA / SLEX / Manila South Road\n- Northbound: Retiro Street / East Service Road\n- Southbound: Aurora Boulevard / Ayala Boulevard / San Marcelino Street',
    areas: 'Makati, Manila, Muntinlupa, Pasay, Parañaque, Quezon City',
  ),
  BusRoute(
    routeId: '41',
    name:
        'Novaliches – FTI via C5, Market! Market!, Eastwood City, UP Town Center, Luzon, Commonwealth Avenue',
    terminals: 'Robinsons Novaliches ↔ Arca South',
    structure:
        'All trips: Quirino Highway / Mindanao Avenue / Commonwealth Avenue / Tandang Sora Avenue / Katipunan Avenue / Bonny Serrano Avenue / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / East Service Road / Arca Boulevard\n- Northbound: Regalado Highway\n- Southbound: Belfast Street',
    areas: 'Pasig, Quezon City, Taguig',
  ),
  BusRoute(
    routeId: '42',
    name: 'Malanday – Ayala via MacArthur Highway',
    terminals: 'Malanday Transport Terminal ↔ One Ayala',
    structure:
        'All trips: MacArthur Highway / Rizal Avenue / Padre Burgos Avenue / Taft Avenue / Gil Puyat Avenue\n- Northbound: Carriedo Street\n- Southbound: Ronquillo Street / Plaza Santa Cruz Road',
    areas: 'Caloocan, Makati, Malabon, Manila, Pasay, Valenzuela',
  ),
  BusRoute(
    routeId: '43',
    name: 'PITX –  NAIA Loop',
    terminals: 'PITX ↔ NAIA Terminal 1 ↔ NAIA Terminal 2 ↔ NAIA Terminal 3',
    structure:
        'Macapagal Boulevard / Seaside Drive / NAIA Road / Ninoy Aquino Avenue / Domestic Road / Andrews Avenue',
    areas: 'Parañaque, Pasay',
  ),
  BusRoute(
    routeId: '44',
    name: 'Alabang – Navotas Terminal via Sucat Road',
    terminals: 'Vista Terminal Exchange ↔ Navotas City Terminal',
    structure:
        'C-4 Road / Radial Road 10 / Mel Lopez Boulevard / Bonifacio Drive / Roxas Boulevard / NAIA Road / Ninoy Aquino Avenue / Dr. Santos Avenue / SLEX / Manila South Road',
    areas: 'Manila, Muntinlupa, Navotas, Parañaque, Pasay',
  ),
  BusRoute(
    routeId: '45',
    name: '	FTI – Navotas via Ayala Avenue',
    terminals: 'Arca South ↔ Navotas City Terminal',
    structure:
        'All trips: C-4 Road / Radial Road 10 / Mel Lopez Boulevard / Bonifacio Drive / Roxas Boulevard / Gil Puyat Avenue / EDSA / SLEX / Lawton Avenue / East Service Road / Arca Boulevard\n- Northbound: Ayala Avenue / Malugay Street / Zuellig Loop',
    areas: 'Navotas, Pasay, Taguig',
  ),
  BusRoute(
    routeId: '46',
    name: 'Pacita – Navotas via Ayala Avenue',
    terminals: 'Pacita Complex ↔ Navotas City Terminal',
    structure:
        'All trips: C-4 Road / Radial Road 10 / Mel Lopez Boulevard / Bonifacio Drive / Roxas Boulevard / Gil Puyat Avenue / EDSA / SLEX / Susana Heights Access Road / Manila South Road / Pacita Avenue\n- Northbound: Ayala Avenue / Malugay Street / Zuellig Loop',
    areas: 'Makati, Manila, Muntinlupa, Navotas, Pasay, San Pedro',
  ),
  BusRoute(
    routeId: '47',
    name: 'PITX – Navotas',
    terminals: 'PITX ↔ Navotas City Terminal',
    structure:
        'C-4 Road / R-10 Road / Mel Lopez Boulevard / Bonifacio Drive / Roxas Boulevard / Seaside Drive / Macapagal Boulevard',
    areas: 'Manila, Navotas, Parañaque, Pasay',
  ),
  BusRoute(
    routeId: '48',
    name: 'Pacita – Plaza Lawton',
    terminals: 'Pacita Complex ↔Lawton',
    structure:
        'Manila South Road / Susana Heights Access Road / SLEX / Osmeña Highway / Gil Puyat Avenue / Taft Avenue',
    areas: 'Biñan, Makati, Manila, Muntinlupa, Pasay, San Pedro',
  ),
  BusRoute(
    routeId: '49',
    name: 'SJDM – NAIA',
    terminals: 'Starmall San Jose del Monte ↔ NAIA Terminal 2',
    structure:
        'All trips: Quirino Highway / Mindanao Avenue / Commonwealth Avenue / Elliptical Road / Quezon Avenue / España Boulevard / Lerma Street / Quezon Boulevard / Padre Burgos Avenue / Taft Avenue / Gil Puyat Avenue / Roxas Boulevard / Dr. Santos Avenue / NAIA Road\n- Northbound: Ninoy Aquino Avenue / Regalado Highway\n- Southbound: Belfast Street',
    areas:
        'Caloocan, Manila, Parañaque, Pasay, Quezon City, San Jose del Monte',
  ),
  BusRoute(
    routeId: '50',
    name: 'VGC – Alabang via C5, Mindanao Avenue',
    terminals: 'Valenzuela Gateway Complex ↔ Vista Terminal Exchange',
    structure:
        'All trips: NLEX / Mindanao Avenue / Congressional Avenue / Luzon Avenue / Tandang Sora Avenue / Katipunan Avenue / Bonny Serrano Avenue / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / SLEX / Manila South Road\n- Northbound: East Service Road',
    areas: 'Muntinlupa, Pasig, Quezon City, Taguig, Valenzuela',
  ),
  BusRoute(
    routeId: '51',
    name: 'VGC – Cubao via Mindanao Avenue',
    terminals: 'Valenzuela Gateway Complex ↔ Farmers Plaza',
    structure:
        'NLEX / Mindanao Avenue / Congressional Avenue / Luzon Avenue / Tandang Sora Avenue / Katipunan Avenue / P. Tuazon Boulevard / EDSA / Aurora Boulevard',
    areas: 'Quezon City, Valenzuela',
  ),
  BusRoute(
    routeId: '52',
    name: 'VGC – PITX',
    terminals: 'Valenzuela Gateway Complex ↔ PITX',
    structure:
        'NLEX / Andres Bonifacio Avenue / Blumentritt Road / Dimasalang Street / Laong Laan Road / Andalucia Street / Quezon Boulevard / Padre Burgos Avenue / Roxas Boulevard / EDSA / Macapagal Boulevard',
    areas: 'Manila, Parañaque, Pasay, Quezon City, Valenzuela',
  ),
  BusRoute(
    routeId: '53',
    name: 'Cubao – Pacita via E. Rodriguez Sr. Avenue',
    terminals: 'Farmers Plaza ↔ Pacita Complex',
    structure:
        'All trips: Times Square Avenue / Aurora Boulevard / E. Rodriguez Sr. Avenue / España Boulevard / Lerma Street / Quezon Boulevard / Padre Burgos Avenue / Taft Avenue / Quirino Avenue / Osmeña Highway / SLEX / Susana Heights Access Road / Manila South Road\n- Northbound: D. Tuazon Street\n- Southbound: Gen. Aguinaldo Avenue / Gen. MacArthur Avenue',
    areas: 'Makati, Manila, Muntinlupa, Quezon City, San Pedro',
  ),
  BusRoute(
    routeId: '54',
    name: 'Quiapo – Pandacan (Beata)',
    terminals: 'Carriedo station ↔ Pandacan Transport Terminal',
    structure:
        'All trips: Carlos Palanca Street / Ayala Boulevard / United Nations Avenue / Paz Mendoza Guazon Street / Jesus Street / Palumpong Street / Beata Street / Lorenzo De La Paz Street\n- Northbound: Romualdez Street / Padre Burgos Avenue\n- Southbound: Natividad Lopez Street / San Marcelino Street',
    areas: 'Manila',
  ),
  BusRoute(
    routeId: '55',
    name: 'PITX – Lancaster New City',
    terminals: 'PITX ↔ Lancaster New City',
    structure:
        'Advincula Avenue / Antero Soriano Highway / Covelandia Road / CAVITEX / Pacific Avenue / Macapagal Boulevard',
    areas: 'General Trias, Imus, Kawit, Parañaque',
  ),
  BusRoute(
    routeId: '56',
    name: 'Antipolo – BGC via C5, Marcos Highway',
    terminals: 'Robinsons Antipolo ↔ Venice Grand Canal Mall',
    structure:
        'Sumulong Highway / Marcos Highway / FVR Road / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / Upper McKinley Road',
    areas: 'Antipolo, Cainta, Marikina, Pasig, Quezon City, Taguig',
  ),
  BusRoute(
    routeId: '57',
    name: 'Antipolo – BGC via C6',
    terminals: 'Robinsons Antipolo ↔ Venice Grand Canal Mall',
    structure:
        'L. Sumulong Memorial Circle / Ortigas Avenue Extension / Taytay Diversion Road / Highway 2000 / Ejercito Avenue / C-6 Road / General Santos Avenue / SLEX / Carlos P. Garcia Avenue / Upper McKinley Road',
    areas: 'Antipolo, Parañaque, Pasig, Taguig, Taytay',
  ),
  BusRoute(
    routeId: '58',
    name: 'Alabang – Naic via Governor\'s Drive',
    terminals: 'Vista Terminal Exchange ↔ Naic Grand Central Terminal',
    structure: 'SLEX / Governor\'s Drive / Antero Soriano Highway',
    areas:
        'Carmona, Dasmariñas, General Mariano Alvarez, General Trias, Muntinlupa, Naic, Silang, Tanza, Trece Martires',
  ),
  BusRoute(
    routeId: '59',
    name: 'Cubao – Dasmariñas Robinson Pala-Pala via GMA – Carmona – SLEX – C5',
    terminals: 'Farmers Plaza ↔ Robinson Pala-Pala (Dasmariñas)',
    structure:
        'Gen. Romulo Avenue / P. Tuazon Boulevard / Katipunan Avenue / Bonny Serrano Avenue / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / SLEX / Governor\'s Drive',
    areas:
        'Carmona, Dasmariñas, General Mariano Alvarez, Muntinlupa, Pasig, Quezon City, Taguig',
  ),
  BusRoute(
    routeId: '60',
    name: 'BGC – Southwoods',
    terminals: 'Venice Grand Canal Mall ↔ Southwoods Mall',
    structure:
        'Upper McKinley Road / Carlos P. Garcia Avenue / SLEX / Southwoods Avenue',
    areas: 'Biñan, Taguig',
  ),
  BusRoute(
    routeId: '61',
    name: 'Ayala – Southwoods',
    terminals: 'One Ayala ↔ Southwoods Mall',
    structure:
        'All trips: EDSA / Gil Puyat Avenue / SLEX / Southwoods Avenue / Ecocentrum Avenue\n- Northbound: Osmeña Highway / Gil Puyat Avenue / Ayala Avenue',
    areas: 'Biñan, Makati',
  ),
  BusRoute(
    routeId: '62',
    name: 'Ayala – BGC Loop',
    terminals: 'RCBC Plaza ↔ Market! Market!',
    structure:
        'Taft Avenue / Gil Puyat Avenue / Ayala Avenue / McKinley Road / 5th Avenue / 26th Street / Carlos P. Garcia Avenue / SLEX / East Service Road / Arca Boulevard',
    areas: 'Makati, Pasay, Taguig',
  ),
  BusRoute(
    routeId: '63',
    name: 'Ayala – BGC Loop (via Kalayaan)',
    terminals: 'One Ayala ↔ Market! Market!',
    structure:
        '- Northbound: 26th Street / 5th Avenue / McKinley Road / Ayala Avenue\n- Southbound: Gil Puyat Avenue / Kalayaan Flyover / 32nd Street',
    areas: 'Makati, Taguig',
  ),
  BusRoute(
    routeId: '64',
    name: 'Sta. Maria – North Edsa via A. Bonifacio, Quezon Avenue',
    terminals: 'Caypombo ↔ SM North EDSA',
    structure:
        'All trips: Norzagaray–Santa Maria Road / Santa Maria Bypass Road / Fortunato Halili Avenue / NLEX / Andres Bonifacio Avenue / 5th Avenue / Sgt. Rivera Street / Gregorio Araneta Avenue / Quezon Avenue / Senator Miriam P. Defensor-Santiago Avenue / EDSA\n- Northbound: Congressional Avenue / Mindanao Avenue\n- Southbound: North Avenue',
    areas: 'Bocaue, Caloocan, Quezon City, Santa Maria',
  ),
  BusRoute(
    routeId: '65',
    name: 'Antipolo – PITX via C5, Ortigas Avenue',
    terminals: 'Robinsons Antipolo ↔ PITX',
    structure:
        'L. Sumulong Memorial Circle / Ortigas Avenue Extension / Eulogio Rodriguez Jr. Avenue / Carlos P. Garcia Avenue / Upper McKinley Road / Park Avenue / Campus Avenue / Turin Street / Venezia Drive / Lawton Avenue / Sales Road / Andrews Avenue / Domestic Road / NAIA Road / Seaside Drive / Macapagal Boulevard',
    areas:
        'Antipolo, Cainta, Parañaque, Pasay, Pasig, Quezon City, Taguig, Taytay',
  ),
  BusRoute(
    routeId: '66',
    name: 'Antipolo – PITX via C6, East Service Road',
    terminals: 'Robinsons Antipolo ↔ PITX',
    structure: 'Parañaque, Cavite',
    areas: 'Specialized airport link for the Cavite gateway.',
  ),

  // ── PNR Augmentation Service ───────────────────────────────────────────────
  BusRoute(
    routeId: 'PNR-S',
    category: 'PNR Augmentation',
    name: 'PNR South Augmentation',
    terminals: 'Divisoria (Tutuban) ↔ Alabang',
    structure: 'Abad Santos, Recto, Legarda, Quirino Ave, Nagtahan, SLEX',
    areas: 'Manila, Makati, Taguig, Muntinlupa',
    notes: 'Temporary Train replacement during NSCR construction.',
  ),
  BusRoute(
    routeId: 'PNR-N',
    category: 'PNR Augmentation',
    name: 'PNR North Augmentation',
    terminals: 'Tutuban ↔ Malolos',
    structure: 'MacArthur Highway, NLEX',
    areas: 'Manila, Caloocan, Valenzuela, Bulacan',
    notes: 'Temporary Train replacement during NSCR construction.',
  ),

  // ── Express Service (Premium P2P) ──────────────────────────────────────────
  BusRoute(
    routeId: 'P2P-A-ATC',
    category: 'Premium P2P',
    name: 'Ayala-ATC Express',
    terminals: 'One Ayala ↔ Alabang Town Center',
    structure: 'Skyway / SLEX',
    areas: 'Makati, Muntinlupa',
    notes: 'RRCG/DNS Operator',
  ),
  BusRoute(
    routeId: 'P2P-A-ANTI',
    category: 'Premium P2P',
    name: 'Ayala-Antipolo Express',
    terminals: 'One Ayala ↔ Robinsons Antipolo',
    structure: 'C-5 / Ortigas Ave Ext',
    areas: 'Makati, Antipolo',
    notes: 'Fully Air-conditioned',
  ),
  BusRoute(
    routeId: 'P2P-T-CLARK',
    category: 'Premium P2P',
    name: 'Trinoma-Clark Express',
    terminals: 'Trinoma ↔ Clark Intl. Airport',
    structure: 'NLEX / SCTEX',
    areas: 'QC, Pampanga',
    notes: 'Scheduled hourly',
  ),
  BusRoute(
    routeId: 'P2P-P-BAGUIO',
    category: 'Premium P2P',
    name: 'PITX-Baguio Express',
    terminals: 'PITX ↔ Baguio City',
    structure: 'Skyway / TPLEX',
    areas: 'Parañaque, Baguio',
    notes: 'Premium Sleeper options',
  ),

  // ── BGC Bus (BTC) ────────────────────────────────────────────────────────
  BusRoute(
    routeId: 'BGC-E',
    category: 'BGC Bus',
    name: 'East Express',
    terminals: 'EDSA Ayala ↔ Market! Market!',
    structure: 'Direct Link',
    areas: 'Makati, Taguig',
    notes: '6 AM – 10 PM',
  ),
  BusRoute(
    routeId: 'BGC-N',
    category: 'BGC Bus',
    name: 'North Route',
    terminals: 'EDSA Ayala ↔ Uptown Mall',
    structure: 'BGC Turf, TGT, HSBC',
    areas: 'Makati, Taguig',
    notes: '6 AM – 10 PM',
  ),
  BusRoute(
    routeId: 'BGC-W',
    category: 'BGC Bus',
    name: 'West Route',
    terminals: 'EDSA Ayala ↔ BGC Stopover',
    structure: 'Net One, Fort Victoria',
    areas: 'Makati, Taguig',
    notes: '6 AM – 10 PM',
  ),
  BusRoute(
    routeId: 'BGC-C',
    category: 'BGC Bus',
    name: 'Central Route',
    terminals: 'Market! Market! Loop',
    structure: 'Nutriasia, University Pkwy',
    areas: 'Taguig',
    notes: '6 AM – 10 PM',
  ),
  BusRoute(
    routeId: 'BGC-NIGH',
    category: 'BGC Bus',
    name: 'Night Route',
    terminals: 'EDSA Ayala Loop',
    structure: 'All Major BGC Stops',
    areas: 'Makati, Taguig',
    notes: '10 PM – 5 AM',
  ),

  // ── Love Bus (Electric Relaunch) ─────────────────────────────────────────
  BusRoute(
    routeId: 'LOVE-E-G',
    category: 'Love Bus',
    name: 'Eastwood-Galleria',
    terminals: 'Eastwood City ↔ Robinsons Galleria',
    structure: 'C-5, Ortigas Ave, Arcovia, Tiendesitas',
    areas: 'QC, Pasig',
    notes: '100% Electric Fleet',
  ),
  BusRoute(
    routeId: 'LOVE-H',
    category: 'Love Bus',
    name: 'Heritage Loop',
    terminals: 'Intramuros ↔ National Museum',
    structure: 'P. Burgos, Manila Cathedral',
    areas: 'Manila',
    notes: 'Weekend Tourist Special',
  ),

  // ── Quezon City Bus Service (QCity Bus) ──────────────────────────────────
  BusRoute(
    routeId: 'QC-1',
    category: 'QCity Bus',
    name: 'QC Route 1',
    terminals: 'QC Hall ↔ Cubao',
    structure: 'Kalayaan Ave, P. Tuazon',
    areas: 'Quezon City',
    notes: 'QC Hall / Cubao Expo',
  ),
  BusRoute(
    routeId: 'QC-2',
    category: 'QCity Bus',
    name: 'QC Route 2',
    terminals: 'QC Hall ↔ Litex',
    structure: 'Commonwealth, IBP Road',
    areas: 'Quezon City',
    notes: 'QC Hall / Litex Market',
  ),
  BusRoute(
    routeId: 'QC-3',
    category: 'QCity Bus',
    name: 'QC Route 3',
    terminals: 'Welcome Rotonda ↔ Aurora',
    structure: 'Quezon Ave, Hemady St.',
    areas: 'Quezon City',
    notes: 'Rotonda / Katipunan',
  ),
  BusRoute(
    routeId: 'QC-4',
    category: 'QCity Bus',
    name: 'QC Route 4',
    terminals: 'QC Hall ↔ General Luis',
    structure: 'Mindanao Ave, Novaliches',
    areas: 'Quezon City',
    notes: 'QC Hall / Nova Proper',
  ),
  BusRoute(
    routeId: 'QC-5',
    category: 'QCity Bus',
    name: 'QC Route 5',
    terminals: 'QC Hall ↔ Mindanao Ave',
    structure: 'Visayas Ave, Congressional',
    areas: 'Quezon City',
    notes: 'QC Hall / Quirino Hwy',
  ),
  BusRoute(
    routeId: 'QC-6',
    category: 'QCity Bus',
    name: 'QC Route 6',
    terminals: 'QC Hall ↔ Gilmore',
    structure: 'Robinsons Magnolia, Hemady',
    areas: 'Quezon City',
    notes: 'QC Hall / LRT-2 Gilmore',
  ),
  BusRoute(
    routeId: 'QC-7',
    category: 'QCity Bus',
    name: 'QC Route 7',
    terminals: 'QC Hall ↔ Ortigas Ave Ext',
    structure: 'C-5, Katipunan, Eastwood',
    areas: 'Quezon City',
    notes: 'QC Hall / Robinsons Bridgetowne',
  ),
  BusRoute(
    routeId: 'QC-8',
    category: 'QCity Bus',
    name: 'QC Route 8',
    terminals: 'QC Hall ↔ Muñoz',
    structure: 'Congressional Ave, EDSA',
    areas: 'Quezon City',
    notes: 'QC Hall / LRT-1 Roosevelt',
  ),
];

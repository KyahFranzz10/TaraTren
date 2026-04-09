import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station.dart';

class TrackData {
  static LatLng? snapToTrack(double lat, double lng, String lineName) {
    List<LatLng>? track;
    if (lineName == 'LRT1') track = lrt1Track;
    else if (lineName == 'LRT2') track = lrt2Track;
    else if (lineName == 'MRT3') track = mrt3Track;
    if (track == null || track.isEmpty) return null;

    LatLng? bestSnap;
    double minSqD = double.infinity;

    // Cartesian approximation for Metro Manila
    final double latToMeters = 111139.0;
    final double lngToMeters = 111320.0 * 0.968;

    double pX = lng * lngToMeters;
    double pY = lat * latToMeters;

    for (int i = 0; i < track.length - 1; i++) {
      double aX = track[i].longitude * lngToMeters;
      double aY = track[i].latitude * latToMeters;
      double bX = track[i + 1].longitude * lngToMeters;
      double bY = track[i + 1].latitude * latToMeters;

      double lenSq = (bX - aX) * (bX - aX) + (bY - aY) * (bY - aY);
      double t = 0.0;
      if (lenSq != 0) {
        t = ((pX - aX) * (bX - aX) + (pY - aY) * (bY - aY)) / lenSq;
        t = t.clamp(0.0, 1.0);
      }

      double projX = aX + t * (bX - aX);
      double projY = aY + t * (bY - aY);

      double dSq = (pX - projX) * (pX - projX) + (pY - projY) * (pY - projY);

      if (dSq < minSqD) {
        minSqD = dSq;
        bestSnap = LatLng(projY / latToMeters, projX / lngToMeters);
      }
    }
    return bestSnap;
  }

  static LatLng? snapToTransfer(double lat, double lng) {
    LatLng? bestSnap;
    double minSqD = double.infinity;
    final double latToMeters = 111139.0;
    final double lngToMeters = 111320.0 * 0.968;

    double pX = lng * lngToMeters;
    double pY = lat * latToMeters;

    for (var track in transferWalkways) {
      for (int i = 0; i < track.length - 1; i++) {
        double aX = track[i].longitude * lngToMeters;
        double aY = track[i].latitude * latToMeters;
        double bX = track[i + 1].longitude * lngToMeters;
        double bY = track[i + 1].latitude * latToMeters;

        double lenSq = (bX - aX) * (bX - aX) + (bY - aY) * (bY - aY);
        double t = 0.0;
        if (lenSq != 0) {
          t = ((pX - aX) * (bX - aX) + (pY - aY) * (bY - aY)) / lenSq;
          t = t.clamp(0.0, 1.0);
        }

        double projX = aX + t * (bX - aX);
        double projY = aY + t * (bY - aY);
        double dSq = (pX - projX) * (pX - projX) + (pY - projY) * (pY - projY);

        if (dSq < minSqD) {
          minSqD = dSq;
          bestSnap = LatLng(projY / latToMeters, projX / lngToMeters);
        }
      }
    }
    return bestSnap;
  }

  static const List<List<LatLng>> transferWalkways = [
    // Doroteo Jose (LRT-1) - Recto (LRT-2)
    [
      const LatLng(14.605216, 120.982282),
      const LatLng(14.6052, 120.982684),
      const LatLng(14.605076, 120.982862),
      const LatLng(14.604785, 120.982808),
      const LatLng(14.604198, 120.98269),
      const LatLng(14.603897, 120.98262),
      const LatLng(14.603923, 120.982486),
    ],
    // EDSA (LRT-1) - Taft Avenue (MRT-3)
    [
      const LatLng(14.538485, 121.000789),
      const LatLng(14.538126, 121.000843),
      const LatLng(14.537914, 121.000865),
      const LatLng(14.537805, 121.000945),
      const LatLng(14.537763, 121.001058),
      const LatLng(14.537779, 121.001181),
    ],
    // Araneta Center-Cubao (LRT-2 to MRT-3)
    [
      const LatLng(14.622564, 121.052855),
      const LatLng(14.621925, 121.053168),
      const LatLng(14.621697, 121.052728),
      const LatLng(14.62096, 121.052642),
      const LatLng(14.620197, 121.052379),
      const LatLng(14.619722, 121.052593),
      const LatLng(14.619558, 121.052336),
      const LatLng(14.619283, 121.051784),
      const LatLng(14.619078, 121.051413),
    ],
  ];

  static const List<LatLng> lrt1Track = [
    LatLng(14.485394, 120.989564),
    LatLng(14.486298, 120.989935),
    LatLng(14.487669, 120.990605),
    LatLng(14.488723, 120.991308),
    LatLng(14.489123, 120.991474),
    LatLng(14.49466, 120.992408),
    LatLng(14.495039, 120.992485),
    LatLng(14.495428, 120.992646),
    LatLng(14.49581, 120.992914),
    LatLng(14.496612, 120.993674),
    LatLng(14.49696, 120.994001),
    LatLng(14.497176, 120.994154),
    LatLng(14.497433, 120.994277),
    LatLng(14.497636, 120.994339),
    LatLng(14.497888, 120.994376),
    LatLng(14.498376, 120.994382),
    LatLng(14.498355, 120.994379),
    LatLng(14.49949, 120.994363),
    LatLng(14.500284, 120.994347),
    LatLng(14.500606, 120.994293),
    LatLng(14.501069, 120.99414),
    LatLng(14.501383, 120.993918),
    LatLng(14.501629, 120.993674),
    LatLng(14.501842, 120.993362),
    LatLng(14.502024, 120.992906),
    LatLng(14.502079, 120.992467),
    LatLng(14.502136, 120.991316),
    LatLng(14.502175, 120.990964),
    LatLng(14.50238, 120.990441),
    LatLng(14.502816, 120.989996),
    LatLng(14.502998, 120.989846),
    LatLng(14.503478, 120.98969),
    LatLng(14.503826, 120.989672),
    LatLng(14.504009, 120.989689),
    LatLng(14.504279, 120.98976),
    LatLng(14.50507, 120.990074),
    LatLng(14.506888, 120.99082),
    LatLng(14.507038, 120.990884),
    LatLng(14.507849, 120.991117),
    LatLng(14.509152, 120.991442),
    LatLng(14.511866, 120.992174),
    LatLng(14.513008, 120.992367),
    LatLng(14.517994, 120.992947),
    LatLng(14.522127, 120.993376),
    LatLng(14.526489, 120.993376),
    LatLng(14.530291, 120.992925),
    LatLng(14.531205, 120.992839),
    LatLng(14.531555, 120.992949),
    LatLng(14.531924, 120.993263),
    LatLng(14.53208, 120.993789),
    LatLng(14.532124, 120.99476),
    LatLng(14.532285, 120.996541),
    LatLng(14.532357, 120.996777),
    LatLng(14.532508, 120.996959),
    LatLng(14.535473, 120.999293),
    LatLng(14.537103, 121.000473),
    LatLng(14.537768, 121.00072),
    LatLng(14.538324, 121.00072),
    LatLng(14.539996, 121.000382),
    LatLng(14.547727, 120.998611),
    LatLng(14.554052, 120.997195),
    LatLng(14.560822, 120.995602),
    LatLng(14.562479, 120.995205),
    LatLng(14.56347, 120.994728),
    LatLng(14.570168, 120.991606),
    LatLng(14.575505, 120.988634),
    LatLng(14.576544, 120.988033),
    LatLng(14.582421, 120.984696),
    LatLng(14.586818, 120.982186),
    LatLng(14.587249, 120.982014),
    LatLng(14.587716, 120.981992),
    LatLng(14.588448, 120.982127),
    LatLng(14.588806, 120.982196),
    LatLng(14.590374, 120.981982),
    LatLng(14.591573, 120.981907),
    LatLng(14.591988, 120.981858),
    LatLng(14.592798, 120.981617),
    LatLng(14.595524, 120.980791),
    LatLng(14.595861, 120.980705),
    LatLng(14.597377, 120.980823),
    LatLng(14.597824, 120.980925),
    LatLng(14.598509, 120.981263),
    LatLng(14.599184, 120.981376),
    LatLng(14.600933, 120.981633),
    LatLng(14.602522, 120.981869),
    LatLng(14.603814, 120.981939),
    LatLng(14.605371, 120.98203),
    LatLng(14.611045, 120.982465),
    LatLng(14.616838, 120.982711),
    LatLng(14.622621, 120.982883),
    LatLng(14.628029, 120.983044),
    LatLng(14.62859, 120.983017),
    LatLng(14.629195, 120.982754),
    LatLng(14.630593, 120.981429),
    LatLng(14.63131, 120.980893),
    LatLng(14.631824, 120.9807),
    LatLng(14.632472, 120.980689),
    LatLng(14.632919, 120.980818),
    LatLng(14.636028, 120.982298),
    LatLng(14.637901, 120.983173),
    LatLng(14.638267, 120.983267),
    LatLng(14.638683, 120.983352),
    LatLng(14.644368, 120.983559),
    LatLng(14.654385, 120.983881),
    LatLng(14.656124, 120.98394),
    LatLng(14.656622, 120.984095),
    LatLng(14.656918, 120.984369),
    LatLng(14.657094, 120.984809),
    LatLng(14.657146, 120.98542),
    LatLng(14.657416, 121.003869),
    LatLng(14.657655, 121.020412),
    LatLng(14.657551, 121.021121),
    LatLng(14.657292, 121.022547),
    LatLng(14.656949, 121.024007),
    LatLng(14.656373, 121.026458),
    LatLng(14.656363, 121.027097),
    LatLng(14.656222, 121.028271),
    LatLng(14.655864, 121.029859),
    LatLng(14.655589, 121.030347),
    LatLng(14.653399, 121.031812),
  ];

  static const List<LatLng> lrt2Track = [
    LatLng(14.603565, 120.9835),
    LatLng(14.603326, 120.984739),
    LatLng(14.602599, 120.986273),
    LatLng(14.600959, 120.989717),
    LatLng(14.60059, 120.99057),
    LatLng(14.600507, 120.99094),
    LatLng(14.600533, 120.991477),
    LatLng(14.600855, 120.992587),
    LatLng(14.601167, 120.993574),
    LatLng(14.601187, 120.994159),
    LatLng(14.601006, 120.994781),
    LatLng(14.600627, 120.995656),
    LatLng(14.600554, 120.996122),
    LatLng(14.60059, 120.996407),
    LatLng(14.600845, 120.997388),
    LatLng(14.600871, 120.997742),
    LatLng(14.600663, 120.998493),
    LatLng(14.600637, 120.998815),
    LatLng(14.600673, 120.999218),
    LatLng(14.600803, 120.999647),
    LatLng(14.60099, 121.000049),
    LatLng(14.601104, 121.000457),
    LatLng(14.601286, 121.002018),
    LatLng(14.601551, 121.00337),
    LatLng(14.601696, 121.005113),
    LatLng(14.602298, 121.011744),
    LatLng(14.602542, 121.014259),
    LatLng(14.602631, 121.015118),
    LatLng(14.602812, 121.015697),
    LatLng(14.603113, 121.016121),
    LatLng(14.604105, 121.017135),
    LatLng(14.60899, 121.022092),
    LatLng(14.609228, 121.022387),
    LatLng(14.609446, 121.022725),
    LatLng(14.610308, 121.025342),
    LatLng(14.610578, 121.026163),
    LatLng(14.612686, 121.032493),
    LatLng(14.612945, 121.033158),
    LatLng(14.613516, 121.034092),
    LatLng(14.618551, 121.042621),
    LatLng(14.619444, 121.04422),
    LatLng(14.620326, 121.046956),
    LatLng(14.621012, 121.048779),
    LatLng(14.621583, 121.050088),
    LatLng(14.622808, 121.05291),
    LatLng(14.627199, 121.061783),
    LatLng(14.627759, 121.063081),
    LatLng(14.628029, 121.064701),
    LatLng(14.628403, 121.066965),
    LatLng(14.629327, 121.069239),
    LatLng(14.631029, 121.072801),
    LatLng(14.632327, 121.075537),
    LatLng(14.632504, 121.076503),
    LatLng(14.632192, 121.077393),
    LatLng(14.631465, 121.078155),
    LatLng(14.630573, 121.078756),
    LatLng(14.629005, 121.079861),
    LatLng(14.625154, 121.082726),
    LatLng(14.622133, 121.085976),
    LatLng(14.621032, 121.08706),
    LatLng(14.619589, 121.08898),
    LatLng(14.619029, 121.089785),
    LatLng(14.618748, 121.090343),
    LatLng(14.618613, 121.091073),
    LatLng(14.618634, 121.091738),
    LatLng(14.61878, 121.092585),
    LatLng(14.619579, 121.096394),
    LatLng(14.620212, 121.099312),
    LatLng(14.620472, 121.100675),
    LatLng(14.621759, 121.106855),
    LatLng(14.622403, 121.109923),
    LatLng(14.623306, 121.114268),
    LatLng(14.624147, 121.118206),
    LatLng(14.62479, 121.121339),
  ];

  static const List<LatLng> mrt3Track = [
    LatLng(14.53769, 121.002042),
    LatLng(14.538438, 121.008511),
    LatLng(14.538905, 121.011665),
    LatLng(14.539155, 121.013092),
    LatLng(14.539601, 121.014669),
    LatLng(14.540505, 121.016837),
    LatLng(14.541429, 121.018532),
    LatLng(14.541782, 121.0191),
    LatLng(14.549026, 121.027826),
    LatLng(14.554353, 121.034231),
    LatLng(14.560428, 121.041409),
    LatLng(14.56158, 121.042793),
    LatLng(14.562255, 121.043447),
    LatLng(14.563367, 121.044198),
    LatLng(14.564768, 121.044885),
    LatLng(14.5671, 121.045593),
    LatLng(14.572079, 121.047041),
    LatLng(14.573532, 121.047964),
    LatLng(14.581112, 121.053522),
    LatLng(14.583916, 121.055346),
    LatLng(14.587924, 121.056719),
    LatLng(14.589543, 121.057277),
    LatLng(14.590436, 121.057405),
    LatLng(14.593551, 121.058328),
    LatLng(14.595918, 121.059208),
    LatLng(14.596666, 121.059573),
    LatLng(14.597912, 121.059723),
    LatLng(14.599386, 121.05968),
    LatLng(14.600528, 121.059594),
    LatLng(14.603996, 121.058178),
    LatLng(14.607463, 121.056633),
    LatLng(14.619486, 121.051075),
    LatLng(14.632649, 121.045024),
    LatLng(14.635203, 121.043394),
    LatLng(14.642863, 121.038394),
    LatLng(14.652226, 121.032279),
  ];

  static LatLng interpolateAlongTrack(String lineName, LatLng start, LatLng end, double percent) {
    List<LatLng>? track;
    final normLine = lineName.replaceAll('-', '').toUpperCase();
    if (normLine == 'LRT1') track = lrt1Track;
    else if (normLine == 'LRT2') track = lrt2Track;
    else if (normLine == 'MRT3') track = mrt3Track;
    
    if (track == null || track.isEmpty) {
      return LatLng(
        start.latitude + (end.latitude - start.latitude) * percent,
        start.longitude + (end.longitude - start.longitude) * percent,
      );
    }

    int startIndex = findClosestIndex(track, start);
    int endIndex = findClosestIndex(track, end);

    if (startIndex == -1 || endIndex == -1) {
       return LatLng(
        start.latitude + (end.latitude - start.latitude) * percent,
        start.longitude + (end.longitude - start.longitude) * percent,
      );
    }

    if (startIndex == endIndex) return track[startIndex];

    List<LatLng> subPath;
    if (startIndex < endIndex) {
      subPath = track.sublist(startIndex, endIndex + 1);
    } else {
      subPath = track.sublist(endIndex, startIndex + 1).reversed.toList();
    }

    double totalDist = 0;
    List<double> segmentDistances = [];
    for (int i = 0; i < subPath.length - 1; i++) {
      double d = Geolocator.distanceBetween(
        subPath[i].latitude, subPath[i].longitude,
        subPath[i+1].latitude, subPath[i+1].longitude
      );
      segmentDistances.add(d);
      totalDist += d;
    }

    if (totalDist == 0) return start;

    double targetDist = percent * totalDist;
    double currentDist = 0;

    for (int i = 0; i < segmentDistances.length; i++) {
      if (currentDist + segmentDistances[i] >= targetDist) {
        double segmentPercent = (targetDist - currentDist) / segmentDistances[i];
        return LatLng(
          subPath[i].latitude + (subPath[i+1].latitude - subPath[i].latitude) * segmentPercent,
          subPath[i].longitude + (subPath[i+1].longitude - subPath[i].longitude) * segmentPercent,
        );
      }
      currentDist += segmentDistances[i];
    }

    return subPath.last;
  }

  static LatLng getTurnbackPosition(String lineName, Station terminus, double percent) {
    List<LatLng>? track;
    final normLine = lineName.replaceAll('-', '').toUpperCase();
    if (normLine == 'LRT1') track = lrt1Track;
    else if (normLine == 'LRT2') track = lrt2Track;
    else if (normLine == 'MRT3') track = mrt3Track;
    
    if (track == null || track.isEmpty) return LatLng(terminus.lat, terminus.lng);

    int stationIdx = findClosestIndex(track, LatLng(terminus.lat, terminus.lng));
    if (stationIdx == -1) return LatLng(terminus.lat, terminus.lng);

    int targetIdx = stationIdx;
    // Check if more points exist beyond the terminus
    if (stationIdx < track.length / 2) {
      // Near start, move towards 0
      targetIdx = 0;
    } else {
      // Near end, move towards length-1
      targetIdx = track.length - 1;
    }

    if (targetIdx == stationIdx) return track[stationIdx];

    return LatLng(
      track[stationIdx].latitude + (track[targetIdx].latitude - track[stationIdx].latitude) * percent,
      track[stationIdx].longitude + (track[targetIdx].longitude - track[stationIdx].longitude) * percent,
    );
  }

  static int findClosestIndex(List<LatLng> track, LatLng point) {
    int bestIndex = -1;
    double minSqD = double.infinity;
    for (int i = 0; i < track.length; i++) {
      double dy = track[i].latitude - point.latitude;
      double dx = track[i].longitude - point.longitude;
      double dSq = dy * dy + dx * dx;
      if (dSq < minSqD) {
        minSqD = dSq;
        bestIndex = i;
      }
    }
    return bestIndex;
  }
}

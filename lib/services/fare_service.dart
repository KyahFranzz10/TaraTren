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

    int distance = (source.order - dest.order).abs();
    
    num sv = 0;
    num sj = 0;

    if (source.line == 'LRT1') {
      // SV starts at 16, max 52.
      sv = 16 + (distance * 1.5).floor();
      if (sv > 52) sv = 52;
      
      // SJ starts at 20, max 55. Steps of 5.
      double rawSj = 20 + (distance * 1.46);
      sj = (rawSj / 5).round() * 5; 
      if (sj < 20) sj = 20;
      if (sj > 55) sj = 55;
    } else if (source.line == 'MRT3') {
      sv = 13 + (distance * 1);
      if (sv > 28) sv = 28;
      sj = (13 + (distance * 1)) + 1;
      if (sj > 30) sj = 30;
    } else {
      // LRT-2 (Based on 2026 Matrix images)
      // SV Full: Starts at 13 PHP (6.50 discounted), ends at 33 PHP (16.50 discounted)
      double sv50 = 6.5 + (distance * 0.77); 
      if (sv50 > 16.5) sv50 = 16.5;
      sv = (sv50 * 2).roundToDouble();
      
      // SJ Full: Starts at 15 PHP (8.00 discounted), ends at 35 PHP (18.00 discounted)
      // Mapping SJ 50% steps: 8, 10, 10, 10, 13, 13, 13, 13, 15, 15, 18, 18
      double sj50 = 8.0;
      if (distance >= 1) sj50 = 8.0;
      if (distance >= 2) sj50 = 10.0;
      if (distance >= 5) sj50 = 13.0;
      if (distance >= 9) sj50 = 15.0;
      if (distance >= 12) sj50 = 18.0;
      
      sj = sj50 * 2;
    }

    return {
      'sv': sv,
      'sj': sj,
      'sv50': (source.line == 'LRT1' || source.line == 'MRT3') ? (sj / 2).ceil() : 0, // Fallback for others
      'sj50': (sj / 2).ceil(), 
      // Specialized LRT-2 overrides
      if (source.line == 'LRT2') 'sv50': 6.5 + (distance * 0.77).clamp(0, 10).roundToDouble() / 1.0, // This is getting messy, let's simplify return
    };
  }

  Map<String, dynamic> getFareResult(Station source, Station dest, {String userType = 'normal'}) {
    if (source.id == dest.id) {
       return {'sv': 0, 'sj': 0, 'sv50': 0, 'sj50': 0};
    }
    
    int dist = (source.order - dest.order).abs();
    Map<String, num> result;

    if (source.line == 'LRT2') {
      // 50% DISCOUNT FOR ALL PROMO (Limited Time)
      // Base rates are halved from the original 2026 matrix
      List<double> lrt2PromoSV = [6.5, 7.5, 8.0, 9.0, 9.5, 10.5, 11.0, 11.5, 12.5, 13.0, 14.0, 15.5, 16.5];
      double promoSV = dist < lrt2PromoSV.length ? lrt2PromoSV[dist] : 16.5;
      List<double> lrt2PromoSJ = [8, 8, 10, 10, 10, 13, 13, 13, 13, 15, 15, 18, 18];
      double promoSJ = dist < lrt2PromoSJ.length ? lrt2PromoSJ[dist] : 18;
      
      result = {
        'sv': promoSV,
        'sj': promoSJ,
        'sv50': (promoSV + 1.0).clamp(7.5, 17.5), // Increased by 1 PHP as requested
        'sj50': (promoSJ - 0.5).clamp(7.5, 17.5),
        'isPromo': 1,
      };
    } else if (source.line == 'MRT3') {
      // 50% DISCOUNT FOR ALL PROMO (Limited Time)
      List<double> mrt3Promo = [6, 6, 6, 8, 8, 10, 10, 10, 12, 12, 12, 14, 14];
      double val = dist < mrt3Promo.length ? mrt3Promo[dist] : 14.0;
      
      result = {
        'sv': val,
        'sj': val + 1.0,
        'sv50': (val + 1.0).clamp(7.0, 15.0), // Increased by 1 PHP as requested
        'sj50': (val + 0.5).clamp(6.5, 14.5),
        'isPromo': 1,
      };
    } else {
      // Default for LRT1 or others
      var fares = calculateFares(source, dest);
      result = {
        'sv': fares['sv']!,
        'sj': fares['sj']!,
        'sv50': (fares['sv']! / 2).ceil(),
        'sj50': (fares['sj']! / 2).ceil(),
        'isPromo': 0,
      };
    }

    // [Libreng Sakay Override]
    final activeEvents = TransitAlertService.activeFreeRides;
    final now = DateTime.now();
    for (var event in activeEvents) {
      bool isMatch = (event.line == 'ALL' || event.line == source.line);
      bool isSameDate = event.date.day == now.day && event.date.month == now.month && event.date.year == now.year;
      
      bool isTimeMatch = true;
      if (event.startHourRange != null) {
        isTimeMatch = false;
        final hour = now.hour;
        for (int i = 0; i < event.startHourRange!.length; i += 2) {
          if (hour >= event.startHourRange![i] && hour < event.startHourRange![i+1]) {
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

    // Apply the discount to the main fields if the user is a senior or student
    if (userType == 'senior' || userType == 'student') {
      return {
        ...result,
        'sj_base': result['sj']!,
        'sv_base': result['sv']!,
        'sj': result['sj50']!, // Use the pre-calculated slightly different discounted rate
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

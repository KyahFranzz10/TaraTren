import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  static const List<_ChangelogVersion> _versions = [
    _ChangelogVersion(
      version: 'V0.3.0',
      date: 'April 20, 2026',
      tag: 'LATEST',
      tagColor: Color(0xFF10B981),
      entries: [
        _ChangelogEntry(Icons.security_rounded, 'Database Security Hardening', 'Implemented Row Level Security (RLS) for favorites and profiles, ensuring 100% user data privacy.', _EntryType.feature),
        _ChangelogEntry(Icons.verified_user_rounded, 'Modernized Dev Profile', 'Completely redesigned the About Developer screen with glassmorphism styling and official GitHub integration.', _EntryType.feature),
        _ChangelogEntry(Icons.train_rounded, 'Rolling Stock Standard', 'Transitioned all fleet terminology to the professional "Rolling Stock" industry standard.', _EntryType.improvement),
        _ChangelogEntry(Icons.account_circle_rounded, 'High-Res Social Avatars', 'Upgraded social login profile pictures to dynamic high-resolution versions for a premium UI feel.', _EntryType.improvement),
        _ChangelogEntry(Icons.settings_suggest_rounded, 'Centralized Settings Hub', 'Unified all technical, theme, and security controls into a single streamlined Settings screen.', _EntryType.improvement),
        _ChangelogEntry(Icons.contrast_rounded, 'Theme-Aware Journey Data', 'Added full Light/Dark mode support for all station travel intervals and route planning results.', _EntryType.improvement),
        _ChangelogEntry(Icons.check_circle_rounded, 'Data Sanitization Fix', 'Resolved matching errors in favorite station logic via improved string trimming and sanitization.', _EntryType.fix),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.2.6-Alpha',
      date: 'April 13, 2026',
      tag: 'PREVIOUS',
      tagColor: Colors.grey,
      entries: [
        _ChangelogEntry(Icons.view_carousel_rounded, 'Visual Mirror Perspective', 'Dynamic Island carousel now automatically mirror-flips based on upcoming door sides for a 1:1 view.', _EntryType.feature),
        _ChangelogEntry(Icons.shield_rounded, '7-Layer Precision Guard', 'Strengthened road-vehicle rejection with Stop-Pattern Analysis and 10-tick confidence barrier.', _EntryType.feature),
        _ChangelogEntry(Icons.gps_fixed_rounded, 'High-Precision Boarding', 'Utilizes 50m geofence boxes for 100% accurate entry/exit journaling even with delayed tracking.', _EntryType.feature),
        _ChangelogEntry(Icons.bug_report_rounded, 'Station Sequence Fix', 'Resolved logic errors where the Dynamic Island would skip the current station or jump ahead.', _EntryType.fix),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.2.5-Alpha',
      date: 'April 13, 2026',
      tag: 'PREVIOUS',
      tagColor: Colors.grey,
      entries: [
        _ChangelogEntry(Icons.payments_rounded, 'Official 2026 Fare Matrices', 'Integrated 100% accurate station-to-station fare matrices for LRT-1, LRT-2, and MRT-3 as per official tariff schedules.', _EntryType.feature),
        _ChangelogEntry(Icons.calculate_rounded, 'Precision Discount Engine', 'Dedicated 50% discount matrices for Seniors, Students, and PWDs, including special rounding policies for Single Journey cards.', _EntryType.feature),
        _ChangelogEntry(Icons.timer_10_rounded, 'Operational Timing Standards', 'Upgraded train tracking with exact station-to-station timing weights for high-precision ETA and map movements.', _EntryType.feature),
        _ChangelogEntry(Icons.analytics_rounded, 'Tariff Alignment Fixes', 'Corrected specific rounding rules for MRT-3 and decimal-based promos for LRT-2 Stored Value cards.', _EntryType.fix),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.2.3-Alpha',
      date: 'April 10, 2026',
      tag: 'PREVIOUS',
      tagColor: Color(0xFF6B7280),
      entries: [
        _ChangelogEntry(Icons.layers_rounded, 'Multi-Leg Journey Grouping', 'The Digital Trip Journal now groups separate legs of a commute (e.g., MRT-3 to LRT-2) into a single session.', _EntryType.feature),
        _ChangelogEntry(Icons.straighten_rounded, 'Heading Stabilization', 'Re-engineered the map heading engine to provide smooth, straight-line tracking along the rail tracks.', _EntryType.improvement),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.2.2-Alpha',
      date: 'April 10, 2026',
      tag: 'PREVIOUS',
      tagColor: Color(0xFF6B7280),
      entries: [
        _ChangelogEntry(Icons.campaign, 'Smart Advisory Alerts', 'News feed scraper now intelligently detects critical operational issues (e.g. Technical Issue, LRTAdvisory) and pushes proactive system alerts.', _EntryType.feature),
        _ChangelogEntry(Icons.picture_in_picture_alt, 'Unified Dynamic Island', 'Combined the in-app and system-wide Dynamic Islands into a single high-performance overlay for universal UI consistency.', _EntryType.feature),
        _ChangelogEntry(Icons.transfer_within_a_station, 'Walkway Transfer Detection', 'The tracking overlay now explicitly brands transit walkways as "Transfer" and shifts colors visually from origin to destination lines.', _EntryType.feature),
        _ChangelogEntry(Icons.power_settings_new, 'Persistent Island Standby', 'Spawning the Dynamic Island manually will cause it to persistently sit in Standby instead of auto-hiding when offboard.', _EntryType.improvement),
        _ChangelogEntry(Icons.speed, 'Clarified LIVE Metrics', 'Explicitly updated the telemetry dashboard descriptors below the dynamic tracker to ensure speed and distances are clearly labeled.', _EntryType.improvement),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.24-Alpha',
      date: 'April 7, 2026',
      tag: 'PREVIOUS',
      tagColor: Color(0xFF6B7280),
      entries: [
        _ChangelogEntry(Icons.sensors_rounded, 'True Real-Time Arrivals', 'Merged crowdsourced GPS tracking into station ETAs. Live trains now override simulated schedules for 100% accuracy.', _EntryType.feature),
        _ChangelogEntry(Icons.record_voice_over_rounded, 'Francis Voice Pack', 'Added custom station announcements recorded by the developer specifically for the LRT-1 line.', _EntryType.feature),
        _ChangelogEntry(Icons.motion_photos_on_rounded, 'Fluid Map Tracking', 'Increased map refresh rate to 500ms for zero-lag train movement with verified "Live" pulsing markers.', _EntryType.improvement),
        _ChangelogEntry(Icons.auto_awesome_motion_rounded, 'Clutter Reduction', 'Live trains now automatically hide nearby simulated icons (800m threshold) to reduce map confusion.', _EntryType.improvement),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.23-Alpha',
      date: 'April 6, 2026',
      tag: 'PREVIOUS',
      tagColor: Color(0xFF6B7280),
      entries: [
        _ChangelogEntry(Icons.directions_transit_filled_rounded, 'Directional Arrivals', 'Upcoming arrivals are now separated by direction (Northbound/Southbound or Westbound/Eastbound) for better clarity.', _EntryType.improvement),
        _ChangelogEntry(Icons.person_pin_circle_rounded, 'Guest Feedback Support', 'Enabled feedback submissions for guest users with an optional email address for follow-ups.', _EntryType.feature),
        _ChangelogEntry(Icons.filter_list_rounded, 'Operational Savings', 'Savings comparison now filters only active rail lines, excluding future projects for accurate fare data.', _EntryType.improvement),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.22-Alpha',
      date: 'April 5, 2026',
      tag: 'PREVIOUS',
      tagColor: Color(0xFF6B7280),
      entries: [
        _ChangelogEntry(Icons.branding_watermark_rounded, 'Station-Centric Headers', 'Station detail screens now feature high-res station imagery as the primary header focal point.', _EntryType.improvement),
        _ChangelogEntry(Icons.animation_rounded, 'Animated Rail Profiles', 'Rail line logos and names now fluidly animate and scale into the app bar on scroll across all lists.', _EntryType.improvement),
        _ChangelogEntry(Icons.visibility_rounded, 'MRT-3 High-Contrast UI', 'Implemented dynamic text coloring for MRT-3: White while expanded over images and Black when collapsed over yellow.', _EntryType.improvement),
        _ChangelogEntry(Icons.construction_rounded, 'Expansion Context', 'Automatically hides accessibility facilities (Escalators, Elevators) for stations currently under construction.', _EntryType.feature),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.21-Alpha',
      date: 'April 4, 2026',
      tag: null,
      tagColor: Colors.transparent,
      entries: [
        _ChangelogEntry(Icons.map, 'Dashed Transit Segments', 'Future extensions and under-construction lines are now rendered with dashed lines to distinguish them from active tracks.', _EntryType.improvement),
        _ChangelogEntry(Icons.timer, 'Station-to-Station Travel Times', 'View estimated travel minutes between stations directly in the line list view.', _EntryType.feature),
        _ChangelogEntry(Icons.dashboard_customize, 'Interactive Rail Grid', 'New grid-based visualization of the transit network with precise operational status mapping.', _EntryType.feature),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.20-Phase II',
      date: 'April 4, 2026',
      tag: null,
      tagColor: Colors.transparent,
      entries: [
        _ChangelogEntry(Icons.speed, 'Live Train Speed & Pace', 'Real-time speedometer and performance tracking (High Speed, Station Halt) both in-app and in the persistent notification.', _EntryType.feature),
        _ChangelogEntry(Icons.people_alt, 'Social Crowd Pulse', 'Manually report current crowd levels (Light, Moderate, Heavy) to help fellow commuters with live community consensus.', _EntryType.feature),
        _ChangelogEntry(Icons.ac_unit, 'Train Gen & Cooling Info', 'View train generation (1G-4G) and predicted AC performance (Strong/Moderate) for upcoming arrivals.', _EntryType.feature),
        _ChangelogEntry(Icons.record_voice_over, 'Custom Voice Packs', 'Choose between Professional, Casual, or Taglish/Conyo personalities for all station announcements.', _EntryType.feature),
        _ChangelogEntry(Icons.transfer_within_a_station, 'Walking Transfer Guides', 'Step-by-step visual paths and directions for transfers between rail lines (e.g., LRT-1 DJ to LRT-2 Recto).', _EntryType.feature),
        _ChangelogEntry(Icons.wheelchair_pickup, 'Station Accessibility Flags', 'Real-time tracking of elevators, escalators, and PWD-friendliness for all active stations.', _EntryType.feature),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.20-Alpha',
      date: 'April 3, 2026',
      tag: null,
      tagColor: Colors.transparent,
      entries: [
        _ChangelogEntry(Icons.satellite_alt, 'Satellite Map View', 'Added satellite imagery toggle on both the Main Map and Future Manila Rail Network screens. Powered by ESRI World Imagery.', _EntryType.feature),
        _ChangelogEntry(Icons.wifi_off, 'Offline Map Caching', 'Map tiles are now cached locally on the device. Once an area is viewed online, it loads instantly even without internet.', _EntryType.feature),
        _ChangelogEntry(Icons.map, 'Improved Map Tiles', 'Switched to CartoDB Light map provider for cleaner, faster, and more transit-friendly map backgrounds.', _EntryType.improvement),
        _ChangelogEntry(Icons.person, 'Guest Username Support', 'Guest users can now set a custom username when signing in. The name is displayed in the navigation drawer.', _EntryType.feature),
        _ChangelogEntry(Icons.movie_filter, 'Redesigned Splash Screen', 'New cinematic splash screen with a 3D-flipping logo animation and a dynamic background map image.', _EntryType.improvement),
        _ChangelogEntry(Icons.label, 'Tara Tren Branding', 'App name corrected to "Tara Tren" across all screens.', _EntryType.fix),
        _ChangelogEntry(Icons.warning_amber_rounded, 'Fixed OSM France Map Error', 'Resolved "Terms of Use" block from the OpenStreetMap France tile server.', _EntryType.fix),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.19',
      date: 'April 2, 2026',
      tag: 'PREVIOUS',
      tagColor: Color(0xFF6B7280),
      entries: [
        _ChangelogEntry(Icons.route, 'Future Manila Rail Network', 'Added an interactive map of all planned and future rail lines (MRT-7, NSCR, etc.) with station details.', _EntryType.feature),
        _ChangelogEntry(Icons.favorite, 'Favorite Stations', 'Quick-access Favorite Stations section on the Home Screen, synced via Firebase.', _EntryType.feature),
        _ChangelogEntry(Icons.record_voice_over, 'Dual-Language Voice Announcements', 'Bilingual station announcements (Filipino & English) with configurable speed and language settings.', _EntryType.feature),
        _ChangelogEntry(Icons.label_off, 'Station Label Toggle', 'Added a button on the map to show or hide station name labels for a cleaner view.', _EntryType.improvement),
        _ChangelogEntry(Icons.settings_voice, 'Refined Voice Settings', 'Removed redundant voice toggle from station info screen and cleaned up announcement language UI.', _EntryType.improvement),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.18',
      date: 'April 2, 2026',
      tag: null,
      tagColor: Colors.transparent,
      entries: [
        _ChangelogEntry(Icons.payments, 'Fare Calculator', 'Full fare matrix with Normal, Senior, PWD, and Student discounts, including 50% promo for LRT-2 and MRT-3.', _EntryType.feature),
        _ChangelogEntry(Icons.how_to_reg, 'Onboarding Flow', 'New onboarding screens to capture user profile (commuter type) and request necessary permissions.', _EntryType.feature),
        _ChangelogEntry(Icons.door_front_door, 'Door-Opening Side Data', 'Added accurate platform side data (open left/right) for all LRT-1, LRT-2, and MRT-3 stations.', _EntryType.feature),
        _ChangelogEntry(Icons.gps_fixed, 'Foreground GPS Tracking', 'Stabilized location tracking by switching to a foreground model, fixing GPS "stuck" states.', _EntryType.fix),
      ],
    ),
    _ChangelogVersion(
      version: 'V0.1.17',
      date: 'April 1, 2026',
      tag: null,
      tagColor: Colors.transparent,
      entries: [
        _ChangelogEntry(Icons.notifications_active, 'Expanded Notification System', 'Added Journey & Ride, Schedule & Timing, and Proximity alert categories.', _EntryType.feature),
        _ChangelogEntry(Icons.train, 'Live & Simulated Trains', 'Real-time crowdsourced train markers and GTFS-based simulated train positions on the map.', _EntryType.feature),
        _ChangelogEntry(Icons.info_outline, 'Refined Station Details', 'Station detail screens now show landmarks, bus routes, transfers, and crowd insights.', _EntryType.improvement),
        _ChangelogEntry(Icons.remove_circle_outline, 'Removed Upcoming Arrivals', 'Removed unreliable "Upcoming Arrivals" tab from station details due to missing live API.', _EntryType.fix),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changelog', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('TaraTren Version History', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final v = _versions[index];
          return _buildVersionCard(context, v);
        },
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, _ChangelogVersion v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  v.version,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Spacer(),
                if (v.tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: v.tagColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      v.tag!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Text(v.date, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Entries
          ...v.entries.map((e) => _buildEntry(e)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEntry(_ChangelogEntry entry) {
    Color typeColor;
    String typeLabel;
    switch (entry.type) {
      case _EntryType.feature:
        typeColor = const Color(0xFF3B82F6);
        typeLabel = 'NEW';
        break;
      case _EntryType.improvement:
        typeColor = const Color(0xFF8B5CF6);
        typeLabel = 'IMPROVED';
        break;
      case _EntryType.fix:
        typeColor = const Color(0xFFEF4444);
        typeLabel = 'FIX';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon, size: 18, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1F2937)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────

enum _EntryType { feature, improvement, fix }

class _ChangelogVersion {
  final String version;
  final String date;
  final String? tag;
  final Color tagColor;
  final List<_ChangelogEntry> entries;

  const _ChangelogVersion({
    required this.version,
    required this.date,
    required this.tag,
    required this.tagColor,
    required this.entries,
  });
}

class _ChangelogEntry {
  final IconData icon;
  final String title;
  final String description;
  final _EntryType type;

  const _ChangelogEntry(this.icon, this.title, this.description, this.type);
}

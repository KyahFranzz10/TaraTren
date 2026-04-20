# Changelog

All notable changes to the **TaraTren** project.
 
## [0.3.0] - 2026-04-20
### Added
- **Guest-First Onboarding**: Complete transition to a map-centric entry; land directly on the Map Screen with core features unlocked (Map, Fare Calculator, Line Info).
- **Identity & Navigation Overhaul**: Migrated user profile and authentication entry to a new persistent global AppBar.
- **High-Fidelity Social Avatars**: Implemented dynamic URL resolution for social login profile pictures (e.g., Google) to request high-resolution (400px) versions for a premium UI.
- **Database Security Hardening**: Implemented granular **Row Level Security (RLS)** policies for `profiles`, `favorites`, and `trips` tables in Supabase, ensuring user data is private and secure.
- **Savings Comparison 2.0**:
  - **Multi-Line Journey Support**: Individual Origin/Destination selectors for complex transfers (LRT-1, LRT-2, MRT-3).
  - **Network Fare Bridging**: Cross-line fare calculation sum logic via major hubs (EDSA/Taft, D.Jose/Recto, Cubao).
  - **Hybrid Precision Inputs**: New slider + manual text field combos for Distance, Fuel Price, and Parking.
  - **Inflation-Adjusted Pricing**: Increased fuel cap to 200 PHP/L with a modern 145 PHP/L default.
- **Thematic Timeline Consistency**: Integrated full Dark/Light theme support for station-to-station intervals and journey results in both **Route Planner** and **Station List**.
- **Modernized Developer Profile**: Completely redesigned the **About Developer** screen with a theme-aware glassmorphism "Story Card," official GitHub social integration, and high-fidelity contact chips.

### Changed
- **Centralized Command Center**: Unified all technical and security settings (Theme Mode, Account Deletion) into the **Settings Screen**, streamlining the **Profile Screen** to act purely as a Commuter Identity Hub.
- **Professional Terminology**: Standardized transit terminology by transitioning all references from **"Our Fleet"** to the industry-standard **"Rolling Stock"**.
- **Unified Auth Flow**: Bypassed redundant login/intro screens for a faster "Time-to-Map" experience.
- **Refined App Drawer**: Replaced "Guest Commuter" with active "Sign In?" CTAs and dynamic sign-out visibility.
- **Cleaned Home Interface**: Removed redundant headers and branding to make the Map the primary focus.

### Fixed
- **Favorite Station Logic**: Improved data sanitization and string trimming for the "Add to Favorite" feature to prevent database matching errors.
- **Dialog Layout Overflows**: Fixed horizontal text cropping in locked feature dialogs across multiple screen sizes.
- **Dropdown Assertion Errors**: Resolved the "exactly one item" Flutter error when switching train lines or selecting extension stations.
- **Extension Awareness**: Added logic to filter out non-operational extension stations from live savings calculations.

## [0.2.6-Alpha] - 2026-04-13
### Added
- **Visual Mirror Perspective (Dynamic Island)**: The carousel now automatically flips based on the upcoming platform's side (Facing Right vs. Facing Left) for a 1:1 passenger view.
- **7-Layer False-Positive Guard**: Significantly strengthened road-vehicle rejection with new Stop-Pattern Analysis and 10-tick (~5s) sustained confidence barrier.
- **Island Platform Metadata**: Integrated door-opening synchronization for all LRT-2 and MRT-3 island platforms (e.g., Katipunan, Taft Ave).
- **Precision Boarding & Alighting**: Refactored entry/exit detection to use 50m geofence boxes, ensuring 100% accurate journaling even if tracking starts late.

### Fixed
- **Carousel Sequence Gaps**: Resolved a logic error where the Dynamic Island would skip the current station and jump ahead during stops.
- **Stationary Leg Updates**: Ensured the 'End Station' is updated even when the train is stationary at a platform.
- **Heading Stability at Halt**: Island now locks to the last reliable heading when stopped to prevent UI flipping.

## [0.2.5-Alpha] - 2026-04-13
### Added
- **Official 2026 Fare Matrices**: Implemented 100% accurate station-to-station fare lookup tables for LRT-1, LRT-2, and MRT-3.
- **Precision Discount Engine**: Added dedicated 50% discount matrices for Students, Seniors, and PWDs, following official rail tariff rounding rules.
- **High-Precision Tracking Standards**: Upgraded the train tracking engine with exact operational timing weights for every segment (LRT-1: 58 min, LRT-2: 31 min, MRT-3: 33.5 min).

### Fixed
- **LRT-2 Matrix Precision**: Integrated specific decimal-based Stored Value promos and integer-based Single Journey discounts for the Purple Line.
- **MRT-3 Tariff Alignment**: Corrected the "round-down" policy for 50% discounts on the Yellow Line (e.g., ₱13.00 fare → ₱6.00 discount).


## [0.2.3-Alpha] - 2026-04-10
### Added
- **Multi-Leg Journey Grouping**: The Digital Trip Journal now intelligently groups separate train line logs into a single "Multi-leg Journey" card if they occur within 90 minutes.
- **Dynamic Journey Totals**: Added automated total fare calculation and segment summarization for complex multi-line commutes.
- **Transfer Checkpointing**: Implemented a "Walkway Checkpoint" mechanism that finalizes trip logs as you enter transfer paths, ensuring separate legs are recorded accurately.

### Fixed
- **Dynamic Island Stabilizer**: Re-engineered the heading engine to use position-delta calculation; map arrows and island tracking are now "Straight" and follow the tracks without jitter.
- **LRT-1 Station Sequence**: Fixed the "1 station ahead" jump; MIA Road and Asiaworld-PITX now follow correctly from Redemptorist.
- **LRT-2 Directionality**: Resolved East-West axis errors; Westbound trips now correctly display upcoming stations in the proper sequence.
- **Line-Aware Directions**: Restricted cardinal labels based on line type; LRT-1/MRT-3 now focus on North/South while LRT-2 focuses on East/West.

## [0.2.2-Alpha] - 2026-04-10
### Added
- **Subway-Ready Offline Mode**: Implemented full SQLite persistence for the News Feed; transit advisories are now cached locally for reading in underground stations.
- **Predictive Hybrid ETA Engine**: Integrated a segment-averaging logic that fuses live GPS velocity with historical data for stable arrival predictions.
- **Two-Stage Arrival Experience**: Added high-urgency Dynamic Island states for 'Approaching' (150m) and 'Now Arriving' (50m) with animated pulse feedback.
- **Verified Commuter Pulse**: Upgraded Crowd Insights to show real-time contributor counts and 'Verified Live' badges.
- **Smart Advisory Scoring**: Weighted engine for advisory detection that classifies severity (🚨, ⚠️, ✅) and triggers smart notifications.

### Changed
- **Advisory Hash-Tracking**: Implemented content-based hashing to eliminate redundant notifications for the same advisory post.
- **Background Isolate Sync**: Enhanced Firebase Auth and Firestore reliability within the Background Tracking Service.

### Fixed
- **Terminus Logic**: Fixed an issue where the Dynamic Island would remain active with stale data after arriving at a terminal station.
- **Notification Spams**: Optimized the news scraper to prevent multiple pings during high-frequency social media updates.

## [0.1.25] - 2026-04-07
### Added
- **System-Wide Dynamic Island**: Implemented a floating journey dashboard that persists across all Android applications.
- **Branded Overlay UI**: Added neon borders and circular rail line icons (L, P, M).
- **About the Developer Screen**: New dedicated screen featuring the developer profile, photo, and mission statement.
- **Legal & Privacy Info**: Updated and separated the DPA 2012 compliance and disclaimer sections.
- **Arrival Alerts in Island**: Immersive arrival notifications (Platform side, Station name) directly within the Dynamic Island.
- **Developer Test Suite**: Updated tools to simulate journeys globally (including background delays).

### Changed
- **Notification Cleanup**: Removed redundant standard arrival alerts to prioritize the Dynamic Island UI.
- **Image Optimization**: Optimized developer profile photo from 30MB RAW to 108KB JPEG.
- **UI/UX Refinement**: Split "About" and "Legal" into distinct sections in Settings.

### Fixed
- **Background Rendering**: Explicitly declared overlay services in AndroidManifest for cross-device support.
- **Permission Flow**: Improved SYSTEM_ALERT_WINDOW request handling in Settings.

## [0.1.24] - 2026-04-06
### Added
- Live train tracking for MRT-3 and LRT-2.
- Interactive stations map with real-time commuter-sourced data.

---
*Para sa bawat Pilipinong Commuter.*

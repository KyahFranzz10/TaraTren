# Changelog

All notable changes to the **TaraTren** project.

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

import 'package:flutter/material.dart';
import '../services/location_service.dart';

class DynamicIslandOverlay extends StatefulWidget {
  final Widget? child;
  const DynamicIslandOverlay({super.key, this.child});

  @override
  State<DynamicIslandOverlay> createState() => _DynamicIslandOverlayState();
}

class _DynamicIslandOverlayState extends State<DynamicIslandOverlay>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _inStationZone = false;
  bool _forceHidden = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _widthAnimation = Tween<double>(begin: 200.0, end: 350.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _radiusAnimation = Tween<double>(begin: 22.0, end: 28.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _heightAnimation = Tween<double>(begin: 52.0, end: 170.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    LocationService().distanceToNext.addListener(_handleDistanceChange);
    LocationService().isOnboard.addListener(_handleOnboardChange);
  }

  void _handleOnboardChange() {
    if (!LocationService().isOnboard.value) {
      setState(() => _forceHidden = false);
    }
  }

  @override
  void dispose() {
    LocationService().distanceToNext.removeListener(_handleDistanceChange);
    LocationService().isOnboard.removeListener(_handleOnboardChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleDistanceChange() {
    final dist = LocationService().distanceToNext.value;
    if (dist != null && dist < 150) {
      if (!_inStationZone) {
        _inStationZone = true;
        if (!_isExpanded) _toggleExpand(true);
      }
    } else if (dist == null || dist > 250) {
      if (_inStationZone) {
        _inStationZone = false;
        if (_isExpanded) _toggleExpand(false);
      }
    }
  }

  void _toggleExpand(bool expand) {
    if (expand == _isExpanded) return;
    setState(() {
      _isExpanded = expand;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        ValueListenableBuilder<bool>(
          valueListenable: LocationService().isOnboard,
          builder: (context, isOnboard, _) {
            if (!isOnboard) return const SizedBox.shrink();

            if (_forceHidden) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _forceHidden = false),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                    ),
                    child: Center(
                      child: Icon(Icons.directions_transit, color: _getLineColor(LocationService().onboardLine.value ?? ''), size: 22),
                    ),
                  ),
                ),
              );
            }

            return ValueListenableBuilder<String?>(
              valueListenable: LocationService().onboardLine,
              builder: (context, line, _) {
                final Color lineCol = _getLineColor(line ?? '');
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _toggleExpand(!_isExpanded),
                      onLongPress: () {
                        setState(() => _forceHidden = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Island minimized. Tap the top-right bubble to restore it."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: _widthAnimation.value,
                            height: _heightAnimation.value,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D0D0D),
                              borderRadius: BorderRadius.circular(_radiusAnimation.value),
                              border: Border.all(
                                color: lineCol.withValues(alpha: 0.8),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: lineCol.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              type: MaterialType.transparency,
                              child: _buildIslandContent(line, lineCol),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildIslandContent(String? line, Color lineCol) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                _buildIndicator(line, lineCol),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isExpanded)
                        _buildCollapsedContent(line)
                      else
                        _buildExpandedContent(line, lineCol),
                    ],
                  ),
                ),
                if (!_isExpanded)
                  const _PulseGlow()
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(String? line) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        LocationService().islandStatusLabel,
        LocationService().nextStationName,
        LocationService().currentStationOnboard,
      ]),
      builder: (context, _) {
        String? status = LocationService().islandStatusLabel.value;
        String? nextSt = LocationService().nextStationName.value;
        String? currentSt = LocationService().currentStationOnboard.value;

        String mini = line?.toUpperCase() ?? "TRANSIT";
        if (status != null) {
          String contextSt = status.contains("Next") ? (nextSt ?? "") : (currentSt ?? "");
          mini = "$status $contextSt";
        }
        return Text(
          mini,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        );
      },
    );
  }

  Widget _buildExpandedContent(String? line, Color lineCol) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              line?.toUpperCase() ?? "TRANSIT",
              style: TextStyle(
                color: lineCol.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<String?>(
              valueListenable: LocationService().islandStatusLabel,
              builder: (context, status, _) {
                 return Text(
                  (status?.contains(" • ") == true 
                     ? status!.split(" • ").last 
                     : (status ?? "TRACKING")).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _toggleExpand(false),
              child: const Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 18),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _toggleExpand(false);
                setState(() => _forceHidden = true);
              },
              child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ValueListenableBuilder<String?>(
            valueListenable: LocationService().islandBodyText,
            builder: (context, body, _) {
              if (body != null) {
                return Container(
                  key: const ValueKey("bodyText"),
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Row(
                key: const ValueKey("tracking"),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: LocationService().nextStationName,
                    builder: (context, name, _) => _StationLabel(name: name ?? "--", isMain: false),
                  ),
                  AnimatedTrainLine(pointingLeft: true, lineColor: lineCol),
                  Column(
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: LocationService().currentStationOnboard,
                        builder: (context, name, _) => _StationLabel(name: name ?? "Tracking...", isMain: true),
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: LocationService().currentDirection,
                        builder: (context, dir, _) {
                          return Text(
                            dir?.toUpperCase() ?? "TRACKING",
                            style: TextStyle(
                              color: lineCol.withValues(alpha: 0.8),
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  AnimatedTrainLine(pointingLeft: true, lineColor: lineCol),
                  ValueListenableBuilder<String?>(
                    valueListenable: LocationService().prevStationName,
                    builder: (context, name, _) => _StationLabel(name: name ?? "--", isMain: false),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _metricItem(Icons.speed, "${LocationService().currentSpeed.value ?? 0}", "km/h"),
             _metricItem(Icons.compare_arrows, _formatMetricDist(LocationService().distanceToNext.value), "km"),
             _metricItem(Icons.timer_outlined, LocationService().islandStatusLabel.value?.contains("Stopped") == true ? "ARRIVED" : "LIVE", "STATUS"),
          ],
        ),
      ],
    );
  }

  String _formatMetricDist(double? dist) {
    if (dist == null) return "--";
    return (dist / 1000).toStringAsFixed(1);
  }

  Widget _metricItem(IconData icon, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.orangeAccent),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildIndicator(String? line, Color activeColor) {
    String letter = "T";
    if (line != null) {
      if (line.contains("LRT1")) letter = "L";
      else if (line.contains("LRT2")) letter = "P";
      else if (line.contains("MRT3")) letter = "M";
    }
    
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: activeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.4),
            blurRadius: 4,
          )
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Color _getLineColor(String line) {
    switch (line.toUpperCase()) {
      case 'LRT1': return Colors.green;
      case 'LRT2': return Colors.purple;
      case 'MRT3': return Colors.yellow;
      default: return Colors.blue;
    }
  }
}

class _StationLabel extends StatelessWidget {
  final String name;
  final bool isMain;
  const _StationLabel({required this.name, required this.isMain});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isMain ? Colors.white : Colors.white54,
          fontSize: isMain ? 13 : 10,
          fontWeight: isMain ? FontWeight.w900 : FontWeight.normal,
          decoration: TextDecoration.none,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class AnimatedTrainLine extends StatefulWidget {
  final bool pointingLeft;
  final Color lineColor;
  const AnimatedTrainLine({super.key, this.pointingLeft = false, required this.lineColor});

  @override
  State<AnimatedTrainLine> createState() => _AnimatedTrainLineState();
}

class _AnimatedTrainLineState extends State<AnimatedTrainLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: widget.lineColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = widget.pointingLeft ? (1.0 - _controller.value) : _controller.value;
              return Align(
                alignment: Alignment((value * 2) - 1.0, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  color: const Color(0xFF0D0D0D), 
                  child: Icon(
                    Icons.directions_subway,
                    color: widget.lineColor,
                    size: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PulseGlow extends StatefulWidget {
  const _PulseGlow();

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseController,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

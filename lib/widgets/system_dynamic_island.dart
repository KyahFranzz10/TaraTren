import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class SystemDynamicIsland extends StatefulWidget {
  const SystemDynamicIsland({super.key});

  @override
  State<SystemDynamicIsland> createState() => _SystemDynamicIslandState();
}

class _SystemDynamicIslandState extends State<SystemDynamicIsland> with TickerProviderStateMixin {
  String? _nextStation;
  String? _line;
  String? _prevStation;
  String? _currentStation;
  String? _statusLabel;
  int? _speed;
  double? _distance;
  String? _pace;
  String? _bodyText;
  bool _isExpanded = false;
  bool _isArrivalAlert = false;
  bool _wasAutoExpanded = false;

  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  Color _lastColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _colorAnimation = ColorTween(
      begin: Colors.orange,
      end: Colors.orange,
    ).animate(_colorController);

    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        final String? newLine = event['line'];
        final bool lineChanged = newLine != _line;
        
        setState(() {
          _nextStation = event['nextStation'];
          _line = newLine;
          _speed = event['speed'];
          _bodyText = event['bodyText'];
          _isArrivalAlert = event['isArrivalAlert'] ?? false;
          _prevStation = event['prevStation'];
          _currentStation = event['currentStation'];
          _statusLabel = event['statusLabel'];
          _distance = event['distance'];
          _pace = event['pace'];

          if (lineChanged && _line != null) {
            Color targetColor = _getLineColor(_line);
            _colorAnimation = ColorTween(
              begin: _lastColor,
              end: targetColor,
            ).animate(CurvedAnimation(
              parent: _colorController,
              curve: Curves.easeInOut,
            ));
            _colorController.forward(from: 0);
            _lastColor = targetColor;
          }

          // Handle intelligent auto-expand and auto-collapse lifecycles
          bool needsExpansion = _isArrivalAlert || (_statusLabel != null && _statusLabel!.contains('Stopped'));
          
          if (needsExpansion && !_wasAutoExpanded) {
            _isExpanded = true;
            _wasAutoExpanded = true;
          } else if (!needsExpansion && _wasAutoExpanded) {
            _isExpanded = false;
            _wasAutoExpanded = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? direction;
    if (_statusLabel != null && _statusLabel!.contains(" • ")) {
      direction = _statusLabel!.split(" • ").first.toUpperCase();
    }
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          final activeColor = _colorAnimation.value ?? _getLineColor(_line);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 90), // Restored to place it correctly below the app header
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                onLongPress: () => FlutterOverlayWindow.closeOverlay(),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    width: _isExpanded ? 350 : 200,
                    height: _isExpanded ? 165 : 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIndicator(_line, activeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_isExpanded)
                                Builder(
                                  builder: (context) {
                                    String mini = _line?.toUpperCase() ?? "TRANSIT";
                                    if (_statusLabel != null) {
                                      String contextSt = _statusLabel!.contains("Next") ? (_nextStation ?? "") : (_currentStation ?? "");
                                      mini = "${_statusLabel!} $contextSt";
                                    }
                                    return MarqueeText(
                                      text: mini,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    );
                                  }
                                )
                          else ...[
                            Row(
                              children: [
                                Text(
                                  _line?.toUpperCase() ?? "TRANSIT",
                                  style: TextStyle(
                                    color: activeColor.withValues(alpha: 0.9),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    (_statusLabel?.contains(" • ") == true 
                                       ? _statusLabel!.split(" • ").last 
                                       : (_statusLabel ?? "TRACKING")).toUpperCase(),
                                    key: ValueKey(_statusLabel),
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => FlutterOverlayWindow.closeOverlay(),
                                  child: const Icon(Icons.close, color: Colors.white38, size: 14),
                                ),
                               ],
                             ),
                             const SizedBox(height: 10),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Expanded(flex: 3, child: _stationLabel(_nextStation ?? "--", isMain: false)),
                                 AnimatedTrainLine(pointingLeft: true, lineColor: activeColor),
                                 Expanded(
                                    flex: 3, 
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _stationLabel(_currentStation ?? "Tracking...", isMain: true),
                                        if (direction != null)
                                          Text(
                                            direction,
                                            style: TextStyle(
                                              color: activeColor.withValues(alpha: 0.8),
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  AnimatedTrainLine(pointingLeft: true, lineColor: activeColor),
                                  Expanded(flex: 3, child: _stationLabel(_prevStation ?? "--", isMain: false)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation, 
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation), 
                                    child: child
                                  )
                                ),
                                child: _bodyText != null
                                  ? Container(
                                      key: const ValueKey("bodyText"),
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        _bodyText!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      key: const ValueKey("metrics"),
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _metricItem(Icons.speed, "${_speed ?? 0}", "km/h"),
                                        _metricItem(Icons.social_distance, _distance == null ? "--" : "${(_distance! / 1000).toStringAsFixed(1)}", "km"),
                                        _metricItem(Icons.timer_outlined, _pace ?? "LIVE", "STATUS"),
                                      ],
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!_isExpanded)
                      const PulseIndicator()
                    else
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _isExpanded = false),
                      ),
                  ],
                ),
              ),
            ),
          ),
          ],
        );
      },
    ),
  );
}

  Widget _metricItem(IconData icon, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

  Widget _stationLabel(String name, {required bool isMain}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
            child: child,
          ),
        );
      },
      child: Text(
        name,
        key: ValueKey(name),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isMain ? Colors.white : Colors.white54,
          fontSize: isMain ? 13 : 10,
          fontWeight: isMain ? FontWeight.w900 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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

  Color _getLineColor(String? line) {
    switch (line?.toUpperCase()) {
      case 'LRT1': return Colors.green;
      case 'LRT2': return Colors.purple;
      case 'MRT3': return Colors.yellow;
      default: return Colors.orange;
    }
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
          // The Colored Line
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: widget.lineColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Flowing Train Icon
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = widget.pointingLeft ? (1.0 - _controller.value) : _controller.value;
              return Align(
                alignment: Alignment((value * 2) - 1.0, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  color: const Color(0xFF0D0D0D), // Match background color to mask the line
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

class PulseIndicator extends StatefulWidget {
  const PulseIndicator({super.key});

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))
      ..addListener(() {
        if (_scrollController.hasClients) {
          double maxScroll = _scrollController.position.maxScrollExtent;
          if (maxScroll > 0) {
            _scrollController.jumpTo(_animController.value * maxScroll);
          }
        }
      });
      
    Future.delayed(const Duration(milliseconds: 1000), () {
       if (mounted) _animController.repeat(reverse: true);
    });
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _animController.forward(from: 0).whenComplete(() {
         if (mounted) _animController.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}

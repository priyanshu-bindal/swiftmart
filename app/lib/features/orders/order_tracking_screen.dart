import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/eta_countdown.dart';
import '../../shared/widgets/order_status_timeline.dart';
import '../../shared/widgets/rider_marker_painter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, this.orderId = 'SM-9824AZ'});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  late AnimationController _riderController;
  late Animation<double> _riderProgress;

  // Fixed curve polyline route (mock)
  final List<LatLng> _routePoints = [
    const LatLng(28.6139, 77.2090), // Store
    const LatLng(28.6150, 77.2105),
    const LatLng(28.6165, 77.2120),
    const LatLng(28.6180, 77.2135),
    const LatLng(28.6190, 77.2155),
    const LatLng(28.6210, 77.2180),
    const LatLng(28.6235, 77.2210), // Customer
  ];

  LatLng _currentRiderPosition = const LatLng(28.6139, 77.2090);
  double _riderBearing = 0.0;
  bool _zoomCompleted = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    // Map Zoom Animation (12 -> 15 over 800ms)
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _zoomAnimation = Tween<double>(begin: 12.0, end: 15.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.elasticOut),
    );

    // Rider Movement Animation (45 seconds)
    _riderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    );

    // TweenSequence for pauses
    // 5 moving segments, 4 pauses (20% intervals)
    _riderProgress =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: 0.2),
            weight: 20,
          ), // Move
          TweenSequenceItem(
            tween: Tween(begin: 0.2, end: 0.2),
            weight: 3.3,
          ), // Pause 1.5s
          TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.4), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.4), weight: 3.3),
          TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.6), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.6), weight: 3.3),
          TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.8), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.8), weight: 3.3),
          TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 20),
        ]).animate(
          CurvedAnimation(parent: _riderController, curve: Curves.easeInOut),
        );

    _zoomController.addListener(() {
      if (_mapReady) {
        _mapController.move(_currentRiderPosition, _zoomAnimation.value);
      }
    });

    _zoomController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _zoomCompleted = true);
        if (!WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations) {
          _riderController.forward();
        }
      }
    });

    _riderController.addListener(_updateRiderPosition);
  }

  void _updateRiderPosition() {
    if (!mounted || !_mapReady) return;

    final progress = _riderProgress.value;
    final totalDistance = _calculateTotalDistance();
    final currentDistance = totalDistance * progress;

    double accumulatedDistance = 0.0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final p1 = _routePoints[i];
      final p2 = _routePoints[i + 1];
      final distance = const Distance().as(LengthUnit.Meter, p1, p2);

      if (accumulatedDistance + distance >= currentDistance) {
        // We are on this segment
        final segmentProgress =
            (currentDistance - accumulatedDistance) / distance;
        final prevPos = _currentRiderPosition;

        final newLat = lerpDouble(p1.latitude, p2.latitude, segmentProgress)!;
        final newLng = lerpDouble(p1.longitude, p2.longitude, segmentProgress)!;
        _currentRiderPosition = LatLng(newLat, newLng);

        if (prevPos.latitude != newLat || prevPos.longitude != newLng) {
          _riderBearing = const Distance().bearing(
            prevPos,
            _currentRiderPosition,
          );
        }

        _mapController.move(_currentRiderPosition, _mapController.camera.zoom);
        setState(() {});
        return;
      }
      accumulatedDistance += distance;
    }
  }

  double _calculateTotalDistance() {
    double total = 0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      total += const Distance().as(
        LengthUnit.Meter,
        _routePoints[i],
        _routePoints[i + 1],
      );
    }
    return total;
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _riderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Background Dark
      body: Stack(
        children: [
          // 1. Flutter Map
          Opacity(
                opacity: 1.0,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentRiderPosition,
                    initialZoom: 12.0, // Before zoom animation
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () {
                      _mapReady = true;
                      if (!disableAnimations) {
                        _zoomController.forward();
                      } else {
                        // Skip zoom, jump to end
                        setState(() => _zoomCompleted = true);
                        _mapController.move(_currentRiderPosition, 15.0);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.swiftmart.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: const Color(0xFF6C3CE1), // Deep Violet
                          strokeWidth: 4.0,
                          borderColor: const Color(
                            0xFF00D4AA,
                          ), // Teal Mint Border (glow)
                          borderStrokeWidth: 1.5,
                          strokeJoin: StrokeJoin.round,
                          strokeCap: StrokeCap.round,
                        ),
                      ],
                    ),
                    if (_zoomCompleted || disableAnimations)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentRiderPosition,
                            width: 60,
                            height: 60,
                            alignment: const Alignment(0, -0.2),
                            child: (disableAnimations)
                                ? RiderMarkerIcon(bearing: _riderBearing)
                                : const RiderMarkerIcon().animate().scale(
                                    duration: 300.ms,
                                    curve: Curves.elasticOut,
                                    begin: const Offset(0.0, 0.0),
                                    end: const Offset(1.0, 1.0),
                                  ),
                          ),
                        ],
                      ),
                  ],
                ),
              )
              .animate(
                target: (disableAnimations) ? 1.0 : 0.0,
              ) // 0.0 triggers fade
              .fadeIn(duration: 800.ms, curve: Curves.easeOut),

          // 2. Top UI Overlay (ETA Card)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${widget.orderId}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (!disableAnimations)
                                    Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2ECC71),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                        .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(reverse: true),
                                        )
                                        .scale(
                                          begin: const Offset(0.8, 0.8),
                                          end: const Offset(1.3, 1.3),
                                          duration: 600.ms,
                                        )
                                  else
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2ECC71),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Rider on the way',
                                    style: TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white12,
                          ),
                          const SizedBox(width: 24),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ETA',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              EtaCountdown(initialMinutes: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Sheet Overlay
          if (_zoomCompleted || disableAnimations)
            DraggableScrollableSheet(
              initialChildSize: 0.35, // about ~250px up to 300px roughly
              minChildSize: 0.15, // 120px ish
              maxChildSize: 0.45,
              builder: (context, scrollController) {
                Widget sheet = Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E), // Background Dark
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A3E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF6C3CE1),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'John Doe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFF39C12),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '4.8',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.white24,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '1.2 km away',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00D4AA), // Teal Mint
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.phone,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const OrderStatusTimeline(currentStepIndex: 3),
                        ],
                      ),
                    ),
                  ),
                );

                if (disableAnimations) return sheet;

                return sheet.animate().slideY(
                  begin: 1.0,
                  end: 0.0,
                  duration: 400.ms, // 400ms after rider appearance
                  delay: 400
                      .ms, // Rider appears at 0ms scale out, so sheet starts moving up at 400ms delay since this widget is mounted after zoom finishes
                  curve: Curves.easeOutBack, // springSimulation-like
                );
              },
            ),
        ],
      ),
    );
  }
}

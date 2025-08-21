import 'dart:async';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final StreamController<String> _eventController = StreamController<String>.broadcast();

  Stream<String> get eventStream => _eventController.stream;

  void triggerInventoryUpdated() {
    _eventController.add('InventoryUpdated');
  }

  void triggerDashboardUpdated() {
    _eventController.add('DashboardUpdated');
  }

  void dispose() {
    _eventController.close();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/therapy_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/dashboard_page.dart';

// Imports for Local Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart'; // For parsing time string
import 'package:myapp/main.dart'; // To access flutterLocalNotificationsPlugin

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController _therapyNameController = TextEditingController();
  String? _selectedTime;
  int _bottomNavIndex = 2;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
    '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM',
    '05:00 PM', '05:30 PM', '06:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _therapyNameController.dispose();
    super.dispose();
  }

  DateTime? _getCombinedDateTime(DateTime date, String timeString) {
    try {
      final format = DateFormat("hh:mm a"); // e.g., 09:00 AM
      final time = format.parse(timeString);
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (e) {
      print('Error parsing time string: $e');
      return null;
    }
  }

  Future<void> _showBookingConfirmationNotification(
    String therapyName, DateTime sessionDateTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'therapy_booking_confirmation_channel', // Unique Channel ID
      'Booking Confirmations',                // Channel Name
      channelDescription: 'Channel for immediate booking confirmations',
      importance: Importance.high, // Use high to make it pop up
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      sessionDateTime.millisecondsSinceEpoch % 100000 + 3, // Unique ID for confirmation
      'Session Booked: $therapyName',
      'Your session for $therapyName is set for ${DateFormat.yMMMd().format(sessionDateTime)} at ${DateFormat.jm().format(sessionDateTime)}.',
      platformChannelSpecifics,
      payload: 'BookingConfirmation|$therapyName|${sessionDateTime.toIso8601String()}',
    );
    print('Showed booking confirmation notification for $therapyName');
  }

  Future<void> _scheduleSessionNotifications(
      String therapyName, DateTime sessionDateTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'therapy_reminder_channel', // Channel ID
      'Therapy Reminders',       // Channel Name
      channelDescription: 'Channel for therapy session reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosPlatformChannelSpecifics);

    // Reminder 1: 1 day before
    final tz.TZDateTime reminderTimeDayBefore =
        tz.TZDateTime.from(sessionDateTime, tz.local).subtract(const Duration(days: 1));
    
    if (reminderTimeDayBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        sessionDateTime.millisecondsSinceEpoch % 100000 + 1,
        'Upcoming Therapy: $therapyName',
        'Your session for $therapyName is tomorrow at ${DateFormat.jm().format(sessionDateTime)}.',
        reminderTimeDayBefore,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'TherapyReminder|$therapyName|${sessionDateTime.toIso8601String()}|1day',
      );
      print('Scheduled 1-day reminder for $therapyName at $reminderTimeDayBefore');
    }

    // Reminder 2: 1 hour before
    final tz.TZDateTime reminderTimeHourBefore =
        tz.TZDateTime.from(sessionDateTime, tz.local).subtract(const Duration(hours: 1));

    if (reminderTimeHourBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        sessionDateTime.millisecondsSinceEpoch % 100000 + 2,
        'Therapy Reminder: $therapyName',
        'Your session for $therapyName is in one hour at ${DateFormat.jm().format(sessionDateTime)}.',
        reminderTimeHourBefore,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'TherapyReminder|$therapyName|${sessionDateTime.toIso8601String()}|1hour',
      );
      print('Scheduled 1-hour reminder for $therapyName at $reminderTimeHourBefore');
    }

    // Reminder 3: At session start time
    final tz.TZDateTime sessionStartTime = tz.TZDateTime.from(sessionDateTime, tz.local);
    if (sessionStartTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        sessionDateTime.millisecondsSinceEpoch % 100000 + 4, // Unique ID for session start
        'Therapy Starting: $therapyName',
        'Your session for $therapyName is starting now.',
        sessionStartTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'TherapyReminder|$therapyName|${sessionDateTime.toIso8601String()}|start',
      );
      print('Scheduled session start notification for $therapyName at $sessionStartTime');
    }
  }

  void _bookSession() async {
    if (_therapyNameController.text.isEmpty || _selectedTime == null || _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter therapy, select date and time.')),
      );
      return;
    }

    final DateTime? sessionDateTime = _getCombinedDateTime(_selectedDay!, _selectedTime!);

    if (sessionDateTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid date or time selected.')),
      );
      return;
    }

    if (sessionDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot book a session in the past.')),
      );
      return;
    }

    String therapyName = _therapyNameController.text;

    Provider.of<TherapyProvider>(context, listen: false).addSession(
      therapyName,
      _selectedTime!,
    );

    // Show immediate booking confirmation notification
    await _showBookingConfirmationNotification(therapyName, sessionDateTime);

    // Schedule 1-day, 1-hour, and session start time reminders
    await _scheduleSessionNotifications(therapyName, sessionDateTime);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session Booked! Notifications are set.')),
    );
    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), 
        ),
        title: const Text(
          'Book a Therapy Session',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Therapy Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _therapyNameController,
              decoration: InputDecoration(
                hintText: 'Enter therapy type (e.g., Shirodhara)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.now().subtract(const Duration(days: 1)), 
              lastDay: DateTime.now().add(const Duration(days: 365)),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  DateTime now = DateTime.now();
                  DateTime today = DateTime(now.year, now.month, now.day);
                  if (selectedDay.isBefore(today)) {
                     _selectedDay = today; 
                     _focusedDay = today;
                  } else {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Select a Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Book Session',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 0 || index == 1) {
            Navigator.of(context).pop();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Scheduling'),
        ],
      ),
    );
  }
}

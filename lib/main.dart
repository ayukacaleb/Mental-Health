import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'mental_health_practices.dart';
import 'local_support_groups.dart';
import 'mood_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeNotifications();
  runApp(MentalHealthApp());
}

Future<void> _initializeNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MentalHealthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health Support',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MoodData moodData = MoodData();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _scheduleDailyNotification();
    _checkMoodAndPrompt();
  }

  void _scheduleDailyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_mood_channel',
      'Daily Mood Notifications',
      channelDescription: 'Daily reminders to enter your mood',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Mood Reminder',
      'How are you feeling today?',
      tz.TZDateTime.now(tz.local).add(Duration(hours: 24)),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _checkMoodAndPrompt() async {
    final moods = await moodData.getMoods();
    if (moods.isEmpty) {
      _showMoodSelectionDialog(context);
    }
  }

  Future<void> _showMoodSelectionDialog(BuildContext context) async {
    String? selectedMood;
    final List<String> moods = ['Happy', 'Sad', 'Anxious', 'Angry', 'Calm', 'Stressed'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('How are you feeling today?'),
          content: DropdownButton<String>(
            value: selectedMood,
            hint: Text('Select your mood'),
            items: moods.map((mood) {
              return DropdownMenuItem<String>(
                value: mood,
                child: Text(mood),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMood = value; // Update selectedMood
              });
              if (value != null) {
                Navigator.of(context).pop();
                // Ensure selectedMood is non-null before passing
                _logMood(value); // Pass the non-null value here
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logMood(String mood) async {
    await moodData.saveMood(mood);
    _showMoodFeedbackDialog(mood);
  }

  Future<void> _showMoodFeedbackDialog(String mood) async {
    String status = 'You are doing well! Keep it up!';
    String suggestions = '';

    if (mood == 'Sad') {
      status = 'You seem to be feeling sad.';
      suggestions = 'Consider talking to a friend or a professional.';
    } else if (mood == 'Anxious') {
      status = 'You seem to be feeling anxious.';
      suggestions = 'Try practicing deep breathing or mindfulness exercises.';
    } else if (mood == 'Angry') {
      status = 'You seem to be feeling angry.';
      suggestions = 'Consider taking a walk or practicing relaxation techniques.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mood Logged'),
        content: Text('You are feeling: $mood\n\nStatus: $status\nSuggestions: $suggestions'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Health Resources'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildResourcesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesList(BuildContext context) {
    final List<Map<String, dynamic>> resources = [
      {
        'title': 'Crisis Hotline: 1199 (Kenya)',
        'action': 'call',
        'icon': FontAwesomeIcons.phoneAlt,
      },
      {
        'title': 'Mental Health Resources',
        'action': 'url',
        'icon': FontAwesomeIcons.link,
      },
      {
        'title': 'Coping with Stress: Local Support Groups',
        'action': 'navigate',
        'icon': FontAwesomeIcons.users,
      },
      {
        'title': 'Good Mental Health Practices',
        'action': 'navigate',
        'icon': FontAwesomeIcons.smile,
      },
      {
        'title': 'Mental Health Facilities',
        'action': 'webview',
        'icon': FontAwesomeIcons.home,
      },
    ];

    return Column(
      children: resources.map((resource) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(resource['icon'], color: Colors.blue),
            title: Text(resource['title'], style: TextStyle(fontSize: 18)),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            onTap: () {
              if (resource['action'] == 'call') {
                _callCrisisHotline();
              } else if (resource['action'] == 'url') {
                _launchURL('https://www.mentalhealthfirstaid.org/mental-health-resources/');
              } else if (resource['action'] == 'webview') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(),
                  ),
                );
              } else {
                if (resource['title'] == 'Coping with Stress: Local Support Groups') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LocalSupportGroups()),
                  );
                } else if (resource['title'] == 'Good Mental Health Practices') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MentalHealthPractices()),
                  );
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _callCrisisHotline() async {
    const phoneNumber = 'tel:1199';
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }
}

// WebView Screen for displaying the mental health facilities
class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition on Android
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Health Facilities'),
      ),
      body: WebView(
        initialUrl: 'https://www.whatseatingmymind.com/list-of-mental-healthcare-facilities',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
      ),
    );
  }
}

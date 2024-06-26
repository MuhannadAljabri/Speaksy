import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../backend/firebase.dart';
import '../style/colors.dart';
import '../backend/infoRetrieval.dart';

class Speaker {
  final String userID;
  final String firstName;
  final String lastName;
  final List<String> topics;
  final List<String> languages;

  final String pictureUrl;

  Speaker(this.userID, this.firstName, this.pictureUrl, this.lastName,
      this.topics, this.languages);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget build(BuildContext context) {
    return MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String userStatus = "";
  bool isSpeaker = false; // Flag to check if the user is a speaker
  bool showStatusBar = true;

  String firstName = "";
  final DatabaseReference _speakersRef =
      FirebaseDatabase.instance.ref().child('speaker_requests');

  final DatabaseReference _userssRef =
      FirebaseDatabase.instance.ref().child('users');

  List<Speaker> _speakers = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
    _loadSpeakers();
    checkIfSpeaker();
    Timer(
      const Duration(seconds: 2),
      () {
        setShowStatusBarToFalse();
      },
    );
  }

  List<Speaker> filteredSpeakers = [];
  List<String> selectedLanguages = [];
  List<String> selectedTopics = [];

  void setShowStatusBarToFalse() async {
    if (userStatus == 'approved' || userStatus == 'declined') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showStatusBar', false);
    }
  }

  void checkIfSpeaker() async {
    // Assuming you're using Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;

    final speakerSnapshot = await _speakersRef.child(user!.uid).once();
    final userSnapshot = await _userssRef.child(user!.uid).once();

    if (speakerSnapshot != null) {
      Map<dynamic, dynamic> speakerData =
          speakerSnapshot.snapshot.value as Map<dynamic, dynamic>;

      Map<dynamic, dynamic> userData =
          userSnapshot.snapshot.value as Map<dynamic, dynamic>;

      setState(() {
        userStatus = speakerData["status"];
        isSpeaker = true; // User is a speaker
        print('${isSpeaker.toString()}, ${userData['firstName']}');
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      showStatusBar = prefs.getBool('showStatusBar') ?? false;
    }
  }

  Future<void> loadUsers() async {
    GetUserInfo try1 = GetUserInfo();
    firstName = await try1.loadUserInfo();
  }

  Future<void> _loadSpeakers() async {
    User? user = FirebaseAuth.instance.currentUser;

    final speakerSnapshot = await _speakersRef.once();
    final userSnapshot = await _userssRef.once();

    List<Speaker> speakers = [];

    Map<dynamic, dynamic> speakerData =
        speakerSnapshot.snapshot.value as Map<dynamic, dynamic>;

    Map<dynamic, dynamic> userData =
        userSnapshot.snapshot.value as Map<dynamic, dynamic>;

    if (speakerData != null) {
      speakerData.forEach((key, value) {
        if (value['status'] == 'approved') {
          //Change to approved when the app is ready
          speakers.add(Speaker(
              key, // userID
              userData[key]['firstName'] ?? '',
              value['pictureUrl'] ?? '',
              userData[key]['lastName'] ?? '',
              List<String>.from(value['topics']),
              List<String>.from(value['languages'])));
        }
      });
    }

    setState(() {
      _speakers = speakers;
      filteredSpeakers = speakers;
    });
  }

  bool isDrawerOpen = false;
  bool isFilterPageOpen = false;
  bool isFilterVisible = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
            color: Colors.black), // Change icon color to black
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Good day,\n ',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  height: 2,
                ),
              ),
              TextSpan(
                text: firstName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  height: 0,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 75,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list),
              iconSize: 34,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FilterPage(
                            selectedTopics: selectedTopics,
                            selectedLanguages: selectedLanguages,
                            allSpeakers: _speakers,
                          )),
                ).then((value) {
                  if (value != null && value is List<Speaker>) {
                    setState(() {
                      filteredSpeakers = value;
                    });
                  }
                });
              })
        ],
      ),
      body: Column(children: [
        const SizedBox(
          height: 5,
        ),
        if (userStatus.isNotEmpty && isSpeaker && showStatusBar)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                  alignment: Alignment.center,
                  width: 400,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorsReference.borderColorGray),
                    color: ColorsReference.darkBlue,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(children: [
                    const SizedBox(
                      width: 15,
                    ),
                    const Text(
                      "Your request's Status:",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    Text(userStatus,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    const SizedBox(width: 15)
                  ]))),
        Expanded(
            child: ListView.builder(
                itemCount: filteredSpeakers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: GestureDetector(
                        onTap: () {
                          final speakerId = filteredSpeakers[index].userID;
                          Navigator.pushNamed(
                            context,
                            '/speaker_profile',
                            arguments: speakerId,
                          );
                          // Handle box click, you can navigate to another screen or perform an action
                          print(
                              'Name clicked: ${filteredSpeakers[index].firstName}');
                        },
                        child: Container(
                          width: double.infinity,
                          height: 144,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: ColorsReference.borderColorGray),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            children: [
                              Container(
                                  width: double.maxFinite,
                                  height: 80,
                                  margin: const EdgeInsets.only(
                                      left: 20, bottom: 5),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: ColorsReference.borderColorGray,
                                      ),
                                    ),
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  child: Row(
                                      // Circle at the far left
                                      children: [
                                        ClipOval(
                                          child: Container(
                                            height: 65,
                                            width: 65,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: ColorsReference
                                                      .borderColorGray),
                                              color: const Color.fromARGB(
                                                  255, 255, 255, 255),
                                              shape: BoxShape.circle,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: filteredSpeakers[index]
                                                  .pictureUrl,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Text(
                                          '${filteredSpeakers[index].firstName} ${filteredSpeakers[index].lastName}',
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ])),
                              // Name in the center

                              Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10, left: 20),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/hashtag_icon.svg",
                                        height: 15,
                                        width: 15,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        'Topics',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 108, 108, 108),
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                          child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Wrap(
                                                  children: buildItemWidgets(
                                                      filteredSpeakers[index]
                                                          .topics))))
                                    ],
                                  ))
                            ],
                          ),
                        )),
                  );
                })),
      ]),
    ));
  }
}

List<Widget> buildItemWidgets(List<String> items) {
  List<Widget> textWidgets = [];

  for (var item in items) {
    textWidgets.add(
      Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 4), // Adjust margin as needed
        decoration: BoxDecoration(
          color: ColorsReference.lightBlue, // Adjust color as needed
          borderRadius:
              BorderRadius.circular(36), // Adjust border radius as needed
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              12, 4, 12, 4), // Adjust padding as needed
          child: Text(
            item,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600), // Adjust text style as needed
          ),
        ),
      ),
    );
  }

  return textWidgets;
}

class FilterPage extends StatefulWidget {
  final List<String> selectedTopics;
  final List<String> selectedLanguages;
  final List<Speaker> allSpeakers;

  FilterPage({
    required this.selectedTopics,
    required this.selectedLanguages,
    required this.allSpeakers,
  });

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  List<String> _selectedTopics = [];
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _selectedTopics = List.from(widget.selectedTopics);
    _selectedLanguages = List.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        title: const Text('Filter',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
            )),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ), // Change the back button icon here
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              List<Speaker> filteredSpeakers =
                  widget.allSpeakers.where((speaker) {
                bool topicsMatch = _selectedTopics.isEmpty ||
                    speaker.topics
                        .any((topic) => _selectedTopics.contains(topic));
                bool languagesMatch = _selectedLanguages.isEmpty ||
                    speaker.languages.any(
                        (language) => _selectedLanguages.contains(language));
                return topicsMatch && languagesMatch;
              }).toList();
              Navigator.pop(context, filteredSpeakers);
            },
            child: const Text(
              'Apply',
              style: TextStyle(
                  color: ColorsReference.lightBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          ListTile(
            title: const Text(
              'Select topics:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            ),
            subtitle: Wrap(
              children: List<Widget>.generate(
                widget.allSpeakers
                    .expand((speaker) => speaker.topics)
                    .toSet()
                    .toList()
                    .length,
                (index) {
                  String topic = widget.allSpeakers
                      .expand((speaker) => speaker.topics)
                      .toSet()
                      .toList()[index];
                  return CheckboxListTile(
                    title: Text(
                      topic,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 16),
                    ),
                    value: _selectedTopics.contains(topic),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value != null) {
                          if (value) {
                            _selectedTopics.add(topic);
                          } else {
                            _selectedTopics.remove(topic);
                          }
                        }
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: ColorsReference.lightBlue,
                  );
                },
              ),
            ),
          ),
          ListTile(
            title: const Text(
              'Select spoken languages:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            subtitle: Wrap(
              children: List<Widget>.generate(
                widget.allSpeakers
                    .expand((speaker) => speaker.languages)
                    .toSet()
                    .toList()
                    .length,
                (index) {
                  String language = widget.allSpeakers
                      .expand((speaker) => speaker.languages)
                      .toSet()
                      .toList()[index];
                  return CheckboxListTile(
                    title: Text(
                      language,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    value: _selectedLanguages.contains(language),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value != null) {
                          if (value) {
                            _selectedLanguages.add(language);
                          } else {
                            _selectedLanguages.remove(language);
                          }
                        }
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: ColorsReference.lightBlue,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

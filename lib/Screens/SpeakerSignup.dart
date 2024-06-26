import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speak_iq/Screens/privacy_policy.dart';
import 'package:speak_iq/Screens/terms_and_conditions.dart';

import 'package:speak_iq/Style/style.dart';
import 'package:speak_iq/backend/firebase.dart';
import 'package:speak_iq/style/colors.dart';
import 'package:speak_iq/style/route_animation.dart';

class SpeakerSignUp extends StatefulWidget {
  const SpeakerSignUp({super.key});

  @override
  State<SpeakerSignUp> createState() => _SpeakerSignUpState();
}

class _SpeakerSignUpState extends State<SpeakerSignUp> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedFile;
  File? _selectedImage;
  String _fileName = '';
  String _imageName = '';
  String _filePath = '';
  String _imagePath = '';
  String? _fileDownloadUrl;
  String? _imageDownloadUrl;
  final Reference _storageReference = FirebaseStorage.instance.ref();
  bool passwordVisible = true;
  bool confirmPasswordVisible = true;
  bool isRegisterButtonClicked = false;
  Color borderColorGray = const Color.fromRGBO(206, 206, 206, 0.5);
  Color textColorBlack = Color.fromARGB(255, 66, 66, 66);
  Color primaryColorGreen = const Color(0xFF2CA6A4);

  // Declare the lists of topics and spoken languages
  List<String> availableTopics = [
    'Diversity',
    'Leadership',
    "Women's issues",
    'Innovation',
    'Entreprenuership',
    'Motivational'
    'Mental health',
    'Customer experience',
    'Artificial Intelligence',
    'Emotional intelligence',
    'Communication',
    'Future trends',
    'Technology',
    'Culture',
    'Employee management',
    'Team building',
    'Storytelling',
    'Celebrity',
    'Diversity, equity and inclusion',
    'Inspirational',
    'Politics',
    'Personal development',
    'Corporate culture',
    'Marketing',
    'Media',
    'Beauty',
    'STEM'
  ]; // Your list of words
  List<String> selectedTopics = [];
  List<String> availableLanguages = [
    'English',
    'Spanish',
  ]; // Your list of words
  List<String> selectedLanguages = [];

  // Declare controllers for each text field
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController linkController = TextEditingController();

  Future<void> submission() async {
    try {
      // Validate the form
      if (!_formKey.currentState!.validate()) {
        return;
      }

      // Create the user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // If user creation is successful, proceed with submission
      User? user = userCredential.user;
      if (user != null) {
        UserUploader userUploader = UserUploader();
        String firstName = firstNameController.text;
        String lastName = lastNameController.text;
        String phoneNumber = phoneNumberController.text;
        String email = emailController.text;
        File pictureFile = File(_imagePath);
        File pdfFile = File(_filePath);
        // Upload the speaker information to the database
        await userUploader.uploadUserInfo(
            firstName: firstName,
            lastName: lastName,
            phoneNum: phoneNumber,
            email: email);
        await userUploader.uploadSpeakerInfo(
            firstName: firstName,
            lastName: lastName,
            bio: bioController.text,
            link: linkController.text,
            topics: selectedTopics,
            languages: selectedLanguages,
            picture: pictureFile,
            pdfFile: pdfFile);

        // Example: printing user information
        print("User ID: ${user.uid}");
        print("Full Name: ${firstNameController.text}");
        print("Last Name: ${lastNameController.text}");
        print("Email: ${emailController.text}");
        // ... (other print statements)
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Congratulations!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: ColorsReference.darkBlue,
              content: const Text(
                'You have successfully created an account! You will be notified once your request as a speaker is approved.',
                style: TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home', // This will clear the navigation stack
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            );
          },
        );
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('showStatusBar', true);
      }
    } catch (e) {
      // Handle authentication error
      print('Error creating user: $e');

      // Check if the error is due to the email already being in use
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Account Exists',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: ColorsReference.darkBlue,
              content: const Text(
                'An account with this email already exists. Please login or use a different email.',
                style: TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _choosePdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _selectedFile = File(result.files.single.path!);
        _fileName = _selectedFile!.path.split('/').last;
      });
    }
  }

  Future<void> _deletePdfFile() async {
    setState(() {
      _filePath = '';
      _selectedFile = null;
      _fileName = '';
    });
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _imagePath = pickedFile != null ? pickedFile.path : "";
      _selectedImage = pickedFile != null ? File(pickedFile.path) : null;
      _imageDownloadUrl = null;
    });

    if (_selectedImage != null) (print('Image Selected!'));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (Logo, Text, Back Button, background)
              Stack(
                //alignment: Alignment.center,
                children: [
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 245, 245, 245),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/speaksy_blue_logo.svg',
                              height: 100,
                              width: 200,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Register new account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF212121),
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                height: 0,
                              ),
                            ),
                          ]),
                    ),
                  ),
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                      ),
                    ),
                    child: IconButton(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left: 30, top: 50),
                      iconSize: 28,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        // Navigate back to the previous screen
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: GestureDetector(
                    onTap: () {
                      _pickImageFromGallery();
                    },
                    child: Center(
                      child: Column(
                      children: [
                        Container(
                        alignment: Alignment.center,
                        height: 85,
                        width: 85,
                        decoration: BoxDecoration(
                            color: Color.fromARGB(250, 240, 240, 240),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            border: _selectedImage == null && isRegisterButtonClicked == true
                          ? Border.all(
                              color: Colors.red, // Set border color to red
                              width: 1.0, // Set border width
                            ) : null,
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30.0),
                                child: Container(
                                    height: 85,
                                    width: 85,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )),
                              )
                            : SvgPicture.asset(
                                'assets/camera_icon.svg',
                                height: 24,
                                width: 24,
                                color: ColorsReference.lightBlue,
                              ),
                      ),
                        if (_selectedImage == null && isRegisterButtonClicked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'This field is required',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                      ),
                    ),
                  )),
              // Name Text Field
              Form(
                key: _formKey,
                child: Column(children: [
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 14),
                      child: RequiredTextField(
                          hintText: 'Enter your first name',
                          labelText: 'First Name',
                          textController: firstNameController)),
                  // Last name text field
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: RequiredTextField(
                          hintText: 'Enter your last name',
                          labelText: 'Last Name',
                          textController: lastNameController)),
                  // Email text field
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: RequiredTextField(
                          hintText: 'Enter your email',
                          labelText: 'Email',
                          textController: emailController)),
                  // Password text field
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: Container(
                      child: TextFormField(
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 6) {
                            return 'The password should be at least 6 characters';
                          }
                        },
                        controller: passwordController,
                        obscureText: passwordVisible,
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color: textColorBlack),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 2.0,
                                color: Color.fromRGBO(206, 206, 206, 0.5)),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 2.0,
                                color: Color.fromRGBO(44, 44, 44, 0.494)),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          contentPadding:
                              const EdgeInsets.only(top: 20, left: 25),
                          suffixIcon: IconButton(
                            color: textColorBlack,
                            icon: Icon(passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(
                                () {
                                  passwordVisible = !passwordVisible;
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Confirm Password text field
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: Container(
                      child: TextFormField(
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                        },
                        controller: confirmPasswordController,
                        obscureText: confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color: textColorBlack),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 2.0,
                                color: Color.fromRGBO(206, 206, 206, 0.5)),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 2.0,
                                color: Color.fromRGBO(44, 44, 44, 0.494)),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          contentPadding:
                              const EdgeInsets.only(top: 20, left: 25),
                          suffixIcon: IconButton(
                            color: textColorBlack,
                            icon: Icon(confirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(
                                () {
                                  confirmPasswordVisible =
                                      !confirmPasswordVisible;
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Phone number text field
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: RequiredTextField(
                        hintText: "Enter your phone number",
                        labelText: "Phone Number (optional)",
                        textController: phoneNumberController,
                        optional: true,
                      )),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 41, right: 16, top: 20),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Topics (Maximum 5 selections)',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 10),
                    child: Wrap(
                      spacing: 8.0,
                      children: availableTopics.map((word) {
                        return FilterChip(
                          label: Text(word),
                          selected: selectedTopics.contains(word),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (selectedTopics.length < 5) {
                                  selectedTopics.add(word);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      backgroundColor: ColorsReference.darkBlue,
                                      content: Text(
                                        'You can\'t select more than 5 topics.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                selectedTopics.remove(word);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.only(left: 41, right: 16, top: 20),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Spoken Languages (select all that applies)',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 10),
                    child: Wrap(
                      spacing: 8.0,
                      children: availableLanguages.map((word) {
                        return FilterChip(
                          label: Text(word),
                          selected: selectedLanguages.contains(word),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedLanguages.add(word);
                              } else {
                                selectedLanguages.remove(word);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  // Bio input box
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 30),
                    child: TextFormField(
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                      },
                      controller: bioController,
                      decoration: InputDecoration(
                          labelStyle: TextStyle(color: textColorBlack),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 2.0,
                                color: Color.fromRGBO(206, 206, 206, 0.5)),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 2.0,
                                color: Color.fromRGBO(44, 44, 44, 0.494)),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: 'Bio (Maximum 5 Lines of Text)',
                          isDense: true,
                          contentPadding: const EdgeInsets.only(
                              top: 20, left: 25, right: 47, bottom: 40),
                          hintMaxLines: 5,
                          hintText:
                              "Enter your bio here! Please describe yourself as professional and nice as possible. "),
                    ),
                  ),

                  // Sheet upload button
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: _selectedFile == null
                          ? Column(children: [
                              Container(
                                height: 100,
                                width: 350,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all<
                                            Color>(
                                        (Color.fromARGB(250, 240, 240, 240))),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        side:
                                            BorderSide(color: borderColorGray),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    _choosePdfFile();
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/upload_button.svg',
                                        width: 20,
                                        height: 20,
                                        semanticsLabel: 'vector',
                                        color: ColorsReference.lightBlue,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Upload your speaker’s sheet as PDF",
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: ColorsReference.lightBlue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ])
                          : Column(
                              children: [
                                Container(
                                    alignment: Alignment.center,
                                    height: 100,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/Pdf_icon.png',
                                          height: 70,
                                          width: 70,
                                        ),
                                        const SizedBox(width: 20),
                                        Flexible(
                                          child: Text(
                                            '$_fileName',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins'),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 15,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _deletePdfFile();
                                          },
                                          // ignore: deprecated_member_use
                                          child: SvgPicture.asset(
                                            'assets/delete_button.svg',
                                            color: const Color.fromRGBO(
                                                236, 0, 0, 1),
                                          ),
                                        ),
                                      ],
                                    )),
                              ],
                            )),

                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 20),
                    child: RequiredTextField(
                        hintText: "Paste here a link to your video",
                        labelText: "Link to Video",
                        textController: linkController),
                  ),
                ]),
              ),

              // Register button
              Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Container(
                    height: 48,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            ColorsReference.darkBlue),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          isRegisterButtonClicked = true;
                        });
                        if (_formKey.currentState!.validate() && _selectedImage != null) {
                          submission();
                        }
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )),
                  Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 0),
              child: GestureDetector(
                onTap: () {
                  // Navigate to the login page
              Navigator.of(context).push(slidingFromDown(const TermsAndConditions()));
                },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'By clicking register you agree to our Terms and Conditions',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 0),
              child: GestureDetector(
                onTap: () {
                  // Navigate to the login page
              Navigator.of(context).push(slidingFromDown(const PrivacyPolicy()));
                },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'and Privacy Policy',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
              // Navigate to login page
              Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?",
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 14)),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: ColorsReference.lightBlue,
                              ),
                            ))
                      ]))
            ],
          ),
        ),
      ),
    );
  }
}

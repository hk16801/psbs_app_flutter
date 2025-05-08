import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  int? openIndex;

  final List<Map<String, String>> abouts = [
    {
      "title": "How Our Shop Pet Care Started",
      "content":
          "We started our pet care shop from a deep passion for animals. Initially, we offered basic care services and gradually expanded into other services such as health care and pet training. We are committed to providing a safe and friendly environment for every pet we serve."
    },
    {
      "title": "Mission Statement",
      "content":
          "Our mission is to provide high-quality pet care services, ensuring the satisfaction of both pets and their owners. We not only care for pets but also educate owners on the best ways to care for their pets, creating a community that loves animals."
    },
    {
      "title": "Value Added Services",
      "content":
          "We offer a variety of value-added services to ensure that your pets are always healthy and happy. This includes services such as bathing, grooming, nutritional consulting, and training. We continuously update the latest trends in the pet care industry to serve our customers best."
    },
    {
      "title": "Social Responsibility",
      "content":
          "We believe in contributing to the community and society. We participate in animal protection activities and support charities related to pets. In this way, we not only help animals but also raise community awareness about the responsibility of caring for animals."
    },
  ];

  void toggleDropdown(int index) {
    setState(() {
      openIndex = openIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB3E5FC), Colors.teal.shade50],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome To Our Family",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We are dedicated to providing exceptional pet care. Our journey began with basic services and has expanded to include grooming, health care, training, and many more.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: abouts.length,
                itemBuilder: (context, index) {
                  bool isOpen = openIndex == index;
                  return Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            abouts[index]["title"]!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          trailing: Icon(
                            isOpen ? Icons.expand_less : Icons.expand_more,
                            color: Colors.teal.shade700,
                          ),
                          onTap: () => toggleDropdown(index),
                        ),
                        AnimatedSize(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          child: Container(
                            padding: isOpen
                                ? EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10)
                                : EdgeInsets.zero,
                            child: isOpen
                                ? Text(
                                    abouts[index]["content"]!,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade700),
                                    textAlign: TextAlign.justify,
                                  )
                                : SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/HomePage/about/img1.png",
                    width: 280,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

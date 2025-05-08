import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final contactInfo = [
      ContactItem("Phone", "assets/HomePage/contact/phone.png",
          ["0847772254", "0812570907"]),
      ContactItem("Email", "assets/HomePage/contact/email.png",
          ["nhulengoctam.37.8@gmail.com", "nhat08046428@gmail.com"]),
      ContactItem("Address", "assets/HomePage/contact/marker.png",
          ["600 Nguyen Van Cu, Ninh Kieu District, Can Tho City"]),
      ContactItem("Open Hours", "assets/HomePage/contact/clock.png",
          ["Mon - Fri: 7 AM - 6 PM", "Saturday: 9 AM - 4 PM"]),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyan[100]!, Color(0xFF48CAE4)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Animate(
              effects: [FadeEffect(), SlideEffect(begin: Offset(0, 50))],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "OUR CONTACTS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800]),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Get in Touch",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Have a question or need assistance?\nReach out to us anytime!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: contactInfo.map((contact) {
                return Animate(
                  effects: [
                    FadeEffect(delay: Duration(milliseconds: 200)),
                    SlideEffect(begin: Offset(0, 30)),
                  ],
                  child: ContactCard(contact: contact),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactItem {
  final String title;
  final String iconPath;
  final List<String> details;
  ContactItem(this.title, this.iconPath, this.details);
}

class ContactCard extends StatelessWidget {
  final ContactItem contact;

  ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Image.asset(contact.iconPath, width: 50, height: 50),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(height: 6),
                ...contact.details.map((detail) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        detail,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

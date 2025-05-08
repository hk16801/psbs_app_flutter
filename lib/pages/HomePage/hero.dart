import 'package:flutter/material.dart';

class HeroSection extends StatefulWidget {
  @override
  _HeroSectionState createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int selectedPetIndex = 0;

  final List<Map<String, dynamic>> pets = [
    {
      "category": "dog",
      "name": "Shiba Inu",
      "image": "assets/HomePage/hero/shiba.jpg",
      "description": "A loyal and spirited Japanese breed."
    },
    {
      "category": "dog",
      "name": "Beagle",
      "image": "assets/HomePage/hero/beagle.jpg",
      "description": "Friendly and curious, perfect for families."
    },
    {
      "category": "cat",
      "name": "Bengal",
      "image": "assets/HomePage/hero/Bengal.jpg",
      "description": "Playful, energetic, with wild markings."
    },
    {
      "category": "cat",
      "name": "British Longhair",
      "image": "assets/HomePage/hero/British_Longhair.jpg",
      "description": "A fluffy and affectionate breed."
    },
    {
      "category": "cat",
      "name": "Burmilla",
      "image": "assets/HomePage/hero/Burmilla.jpg",
      "description": "A rare breed with a shimmering coat."
    },
    {
      "category": "dog",
      "name": "Bulldog",
      "image": "assets/HomePage/hero/Canis_lupus_familiaris.jpg",
      "description": "A calm and courageous companion."
    },
    {
      "category": "cat",
      "name": "Chartreux",
      "image": "assets/HomePage/hero/Chartreux.jpg",
      "description": "A quiet, intelligent French cat breed."
    },
    {
      "category": "cat",
      "name": "LaPerm",
      "image": "assets/HomePage/hero/LaPerm.jpg",
      "description": "Known for its curly coat and affection."
    },
    {
      "category": "dog",
      "name": "Pomeranian",
      "image": "assets/HomePage/hero/pomeranian.jpg",
      "description": "A tiny but bold fluffy companion."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pet = pets[selectedPetIndex];

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/HomePage/hero/blue-pattern.png"),
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Unleash",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
              Text(
                "the Power",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                "of PetEase",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Centered Learn More Button
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/services');
              },
              child: Text("Start Your Journey",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),

          SizedBox(height: 40),

          // Pet Details Section
          Column(
            children: [
              Text(
                pet["category"].toUpperCase(),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2aa6df)),
              ),
              Text(
                pet["name"],
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrangeAccent),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  pet["description"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic),
                ),
              ),
              SizedBox(height: 20),
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(pet["image"]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 30),

          // Pet Selection Grid
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pets.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPetIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedPetIndex == index
                            ? Colors.orange
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(pets[index]["image"]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

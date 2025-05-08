import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class Review {
  final String image;
  final String name;
  final String description;

  Review({required this.image, required this.name, required this.description});
}

class ReviewScreen extends StatelessWidget {
  final List<Review> reviews = [
    Review(
        image: 'assets/HomePage/review/1.jpg',
        name: 'Alex Smith',
        description:
            'The veterinary team is professional and caring, providing excellent health check-ups and vaccinations. Highly recommend!'),
    Review(
        image: 'assets/HomePage/review/2.jpg',
        name: 'Daniel Tuner',
        description:
            'Great experience! The vets are knowledgeable and explain everything clearly about my pet health.'),
    Review(
        image: 'assets/HomePage/review/3.jpg',
        name: 'Jacey Maragrett',
        description:
            'Outstanding pet care services! The staff is friendly and my pet always looks great after grooming.'),
    Review(
        image: 'assets/HomePage/review/4.jpg',
        name: 'Elizebeth Swan',
        description:
            'I love their grooming services! My pet comes home clean and happy every time.'),
    Review(
        image: 'assets/HomePage/review/5.jpg',
        name: 'Ethan Dane',
        description:
            'The pet grooming service exceeded my expectations! The staff was attentive and made my dog feel comfortable. He looked fantastic after the grooming session. Highly recommend for anyone looking to pamper their pets!'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade50,
            Colors.cyan[100]!,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(seconds: 1),
                builder: (context, double opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'Our Reviews',
                      style: TextStyle(
                          color: Color(0xFF1182c5),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'What People Say',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              CarouselSlider(
                options: CarouselOptions(
                  height: 550,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  autoPlayInterval: Duration(seconds: 3),
                  viewportFraction: 1.0,
                ),
                items: reviews.map((review) {
                  return Builder(
                    builder: (BuildContext context) {
                      return AnimatedOpacity(
                        opacity: 1,
                        duration: Duration(milliseconds: 500),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  spreadRadius: 4)
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(review.image),
                              ),
                              SizedBox(height: 15),
                              Text(
                                review.name,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              SizedBox(height: 8),
                              Image.asset(
                                'assets/HomePage/review/Stars.jpg',
                                width: 150,
                              ),
                              SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  review.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

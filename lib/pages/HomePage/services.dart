import 'package:flutter/material.dart';
import 'package:flutter_swiper_plus/flutter_swiper_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Service {
  final String image;
  final String name;
  final String description;

  Service({required this.image, required this.name, required this.description});
}

final List<Service> services = [
  Service(
      image: 'assets/HomePage/services/service-icon1.svg',
      name: 'Medical',
      description:
          'Includes regular veterinary check-ups, vaccinations, and other medical services.'),
  Service(
      image: 'assets/HomePage/services/service-icon2.svg',
      name: 'Grooming',
      description:
          'Offers bathing, haircuts, nail trimming, and ear cleaning to keep your pets clean.'),
  Service(
      image: 'assets/HomePage/services/pet-boarding.png',
      name: 'Hotel',
      description:
          'Book short-term or long-term stays at our pet shop, ensuring your pets are well cared for.'),
];

class ServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Our Best Services',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2aa6df),
          ),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'We provide top-notch services to ensure your pets receive the best care.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          height: 350,
          child: Swiper(
            autoplay: true,
            autoplayDelay: 3500,
            duration: 600,
            loop: true,
            viewportFraction: 0.9,
            scale: 0.9,
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildImage(service.image),
                    SizedBox(height: 15),
                    Text(
                      service.name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        service.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/services');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Explore'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.endsWith('.svg')) {
      return SvgPicture.asset(imagePath, width: 120, height: 120);
    } else {
      return Image.asset(imagePath, width: 120, height: 120);
    }
  }
}

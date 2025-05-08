import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/booking_service_type.dart';
import 'package:intl/intl.dart';


class BookingServiceChoice extends StatefulWidget {
  final String cusId;
  final List<BookingChoice> bookingChoices;
  final Function(int) onRemove;
  final Function() onUpdate;
  final Function(BookingChoice) onVariantChange;

  const BookingServiceChoice({
    required this.cusId,
    required this.bookingChoices,
    required this.onRemove,
    required this.onUpdate,
    required this.onVariantChange,
    Key? key,
  }) : super(key: key);

  @override
  _BookingServiceChoiceState createState() => _BookingServiceChoiceState();
}

class _BookingServiceChoiceState extends State<BookingServiceChoice> {
  String _error = "";
  final _currencyFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

  void _updateVariant(int index, ServiceVariant newVariant) {
    print('=== BookingServiceChoice: _updateVariant ===');
    print('Previous variant: ${widget.bookingChoices[index].serviceVariant?.content} - ${widget.bookingChoices[index].serviceVariant?.price}');
    print('New variant: ${newVariant.content} - ${newVariant.price}');
    
    final updatedChoice = BookingChoice(
      service: widget.bookingChoices[index].service,
      pet: widget.bookingChoices[index].pet,
      serviceVariant: newVariant,
      price: newVariant.price,  // Update price with new variant price
      bookingDate: widget.bookingChoices[index].bookingDate,
      variants: widget.bookingChoices[index].variants,
    );

    setState(() {
      widget.bookingChoices[index] = updatedChoice;
    });

    // Notify parent components of the change
    widget.onVariantChange(updatedChoice);
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.bookingChoices.asMap().entries.map((entry) {
          final index = entry.key;
          final choice = entry.value;

          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service and Pet Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medical_services, 
                                    size: 18, 
                                    color: Colors.purple.shade700),
                                SizedBox(width: 8),
                                Text(
                                  "Service",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              choice.service.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pets, 
                                    size: 18, 
                                    color: Colors.green.shade700),
                                SizedBox(width: 8),
                                Text(
                                  "Pet",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              choice.pet.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Variant Selection
                  if (choice.variants.isNotEmpty) ...[
                    Text(
                      "Service Variant",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<ServiceVariant>(
  isExpanded: true,
  decoration: InputDecoration(
    border: InputBorder.none,
    hintText: "Select variant",
  ),
  value: choice.serviceVariant,
  items: choice.variants.map((variant) {
    return DropdownMenuItem<ServiceVariant>(
      value: variant,
      child: Text(
        "${variant.content} - ${_currencyFormatter.format(variant.price)}",
        overflow: TextOverflow.ellipsis,
      ),
    );
  }).toList(),
  onChanged: (ServiceVariant? value) {
    if (value != null) {
      _updateVariant(index, value);
    }
  },
),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Price Display
                  Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "Total Price:",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.green.shade800,
        ),
      ),
      Text(
        _currencyFormatter.format(choice.price),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    ],
  ),
),
                ],
              ),
            ),
          );
        }).toList(),

        // Error Message
        if (_error.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(12),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, 
                      color: Colors.red.shade700, 
                      size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class ShopCard extends StatelessWidget {
  final String name;
  final String address;
  final String distanceText;
  final String imagePath;
  final VoidCallback? onTap;

  const ShopCard({
    super.key,
    required this.name,
    required this.address,
    required this.distanceText,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // IMAGE (Network + Asset both)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imagePath.startsWith("http")
                    ? Image.network(
                        imagePath,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 70,
                          width: 70,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.store),
                        ),
                      )
                    : Image.asset(
                        imagePath,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
              ),

              const SizedBox(width: 12),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Address line
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Distance line
                    Text(
                      distanceText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:io';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_helper.dart';
import '../data/models/models.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isListMode;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onLongPress,
    this.isListMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListMode) {
      return _buildListMode();
    }
    return _buildGridMode();
  }

  Widget _buildGridMode() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.markerCount} ${trip.markerCount == 1 ? 'marker' : 'markers'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListMode() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverImage(width: 100),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppTheme.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.markerCount} ${trip.markerCount == 1 ? 'marker' : 'markers'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage({double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: isListMode ? double.infinity : 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.6),
            AppTheme.secondaryColor.withOpacity(0.4),
          ],
        ),
      ),
      child: trip.coverImagePath != null
          ? Image.file(
              File(trip.coverImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderIcon();
              },
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Icon(
      Icons.map_outlined,
      size: 48,
      color: Colors.white54,
    );
  }

  String _getSubtitle() {
    if (trip.startDate != null && trip.endDate != null) {
      return '${DateHelper.formatDisplayDate(trip.startDate)} - ${DateHelper.formatDisplayDate(trip.endDate)}';
    } else if (trip.startDate != null) {
      return 'From ${DateHelper.formatDisplayDate(trip.startDate)}';
    } else {
      return 'Created ${DateHelper.getRelativeTimeString(trip.createdAt)}';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Profile Section
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1), width: 1),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: const NetworkImage("https://i.pravatar.cc/150?u=bitanic"),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Siang,",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  user?.email?.split('@')[0].toUpperCase() ?? "Zidane Rafiyanto",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),

        // Quick Stats Row
        Row(
          children: [
            Expanded(child: _buildStatCard(context, "Active", "8", "Sensors", Icons.sensors, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, "Soil", "60%", "Target", Icons.water_drop_outlined, Colors.cyan)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, "pH", "6.2", "Ideal", Icons.science_outlined, Colors.indigo)),
          ],
        ),

        const SizedBox(height: 24),

        // NPK Status Card
        _buildSectionTitle(context, "NPK Status"),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProgressItem(context, "Nitrogen (N)", 0.75, "75%", Colors.blue),
                const SizedBox(height: 16),
                _buildProgressItem(context, "Phosphorus (P)", 0.45, "45%", Colors.purple),
                const SizedBox(height: 16),
                _buildProgressItem(context, "Potassium (K)", 0.82, "82%", Colors.orange),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Aktivitas Terbaru
        _buildSectionTitle(context, "Aktivitas Terbaru"),
        const SizedBox(height: 12),
        _buildActivityItem(context, "Irigasi Otomatis Dijalankan", "Zonasi A - 15 Menit yang lalu", Icons.water_drop, Colors.blue),
        const SizedBox(height: 12),
        const SizedBox(height: 40),

        // Log Out Button (Especially for Petani)
        Center(
          child: OutlinedButton.icon(
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(BuildContext context, String label, double progress, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

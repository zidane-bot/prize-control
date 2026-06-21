import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/theme_provider.dart';
import 'screens/home_page.dart';
import 'tabs/kendali_tab.dart';
import 'tabs/monitoring_tab.dart';
import 'tabs/web_history_tab.dart';
import 'tabs/alerts_tab.dart';
import 'tabs/settings_tab.dart';
import 'screens/mobile_history_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/bandwidth_efficiency_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _webSelectedIndex = 0;
  int _mobileSelectedIndex = 0; // Maps to: 0=Home, 1=Kendali, 2=Alerts, 3=Settings

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check screen width to determine responsiveness
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 800;

    if (isWebLayout) {
      return _buildWebLayout(context, isDark, colorScheme, themeProvider);
    } else {
      return _buildMobileLayout(context, isDark, colorScheme, themeProvider);
    }
  }

  // --- WEBSITE LAYOUT (WITH SIDEBAR) ---
  Widget _buildWebLayout(BuildContext context, bool isDark, ColorScheme colorScheme, ThemeProvider themeProvider) {
    final List<Widget> webTabs = [
      const HomePage(),
      const KendaliTab(),
      const MonitoringTab(),
      const BandwidthEfficiencyScreen(),
      const WebHistoryTab(),
      const AlertsTab(),
      const SettingsTab(),
      AboutScreen(
        isEmbedded: true,
        onBack: () {
          setState(() {
            _webSelectedIndex = 0;
          });
        },
      ),
      ContactScreen(
        isEmbedded: true,
        onBack: () {
          setState(() {
            _webSelectedIndex = 0;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: isDark 
          ? (kIsWeb ? const Color(0xFF060F08) : const Color(0xFF0F172A)) 
          : const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sleek Sidebar (Web Only)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark 
                  ? (kIsWeb ? const Color(0xFF0C1E0F) : const Color(0xFF1E293B)) 
                  : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark 
                      ? (kIsWeb ? const Color(0x1F22C55E) : const Color(0xFF334155)) 
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "BITANIC",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: colorScheme.onSurface,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark && kIsWeb ? const Color(0x1F22C55E) : null,
                ),
                const SizedBox(height: 16),
                
                // Sidebar Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, "Dashboard", isDark, colorScheme),
                      _buildSidebarItem(1, Icons.tune_outlined, Icons.tune_rounded, "Control Panel", isDark, colorScheme),
                      _buildSidebarItem(2, Icons.sensors_outlined, Icons.sensors_rounded, "Monitoring", isDark, colorScheme),
                      _buildSidebarItem(3, Icons.speed_outlined, Icons.speed_rounded, "Efisiensi Bandwidth IoT", isDark, colorScheme),
                      _buildSidebarItem(4, Icons.history_rounded, Icons.history_rounded, "History Log", isDark, colorScheme),
                      _buildSidebarItem(5, Icons.warning_amber_rounded, Icons.warning_rounded, "Alerts", isDark, colorScheme),
                      _buildSidebarItem(6, Icons.settings_outlined, Icons.settings_rounded, "Settings", isDark, colorScheme),
                      const SizedBox(height: 16),
                      Divider(
                        color: isDark && kIsWeb ? const Color(0x1F22C55E) : null,
                      ),
                      const SizedBox(height: 8),
                      _buildSidebarItem(7, Icons.info_outline_rounded, Icons.info_rounded, "About Us", isDark, colorScheme),
                      const SizedBox(height: 8),
                      _buildSidebarItem(8, Icons.people_alt_outlined, Icons.people_alt_rounded, "Tim Pengembang", isDark, colorScheme),
                    ],
                  ),
                ),

                // Theme Mode and Logout Footer
                Divider(
                  height: 1,
                  color: isDark && kIsWeb ? const Color(0x1F22C55E) : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        onPressed: () => themeProvider.toggleTheme(),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                        onPressed: () {
                          Provider.of<AuthProvider>(context, listen: false).signOut();
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // Main Web Contents
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: webTabs[_webSelectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index, 
    IconData inactiveIcon, 
    IconData activeIcon, 
    String label, 
    bool isDark, 
    ColorScheme colorScheme
  ) {
    final isSelected = _webSelectedIndex == index;
    final activeBgColor = colorScheme.primary.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _webSelectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13.5,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT (WITH BOTTOM NAV) ---
  Widget _buildMobileLayout(BuildContext context, bool isDark, ColorScheme colorScheme, ThemeProvider themeProvider) {
    // Tabs list for mobile (Index mapping: 0=Home, 1=Kendali, 2=Alerts, 3=Settings)
    final List<Widget> mobileTabs = [
      const HomePage(),
      const KendaliTab(),
      const AlertsTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "BITANIC",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: colorScheme.onSurface,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "BITANIC",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text('About Us', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text('Tim Pengembang', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.error)),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: mobileTabs[_mobileSelectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _getMobileBottomNavIndex(),
          onTap: (index) {
            if (index == 2) {
              // Navigasi ke screen baru khusus History di Mobile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MobileHistoryScreen()),
              );
            } else {
              setState(() {
                // Map the bottom nav tap index back to selected index
                if (index < 2) {
                  _mobileSelectedIndex = index;
                } else {
                  _mobileSelectedIndex = index - 1; // Adjust index because History is pushed
                }
              });
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.4),
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune_rounded),
              label: "Kendali",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              activeIcon: Icon(Icons.warning_rounded),
              label: "Alerts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  int _getMobileBottomNavIndex() {
    // Maps _mobileSelectedIndex back to BottomNavigationBar index
    if (_mobileSelectedIndex < 2) {
      return _mobileSelectedIndex;
    } else {
      return _mobileSelectedIndex + 1;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_utils.dart';
import 'review_service.dart';
import 'dart:ui';
import 'preferences_data.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userInfo;
  Image? profilePhoto;
  late SharedPreferences _prefs;
  String? savedData;
  late String username;
  late String currentUser; // Usuario actualmente autenticado
  
  // Variables para reviews
  List<dynamic> _reviews = [];
  bool _canViewReviews = false;
  int _reviewCount = 0;
  double _averageRating = 0.0;
  Map<String, double> _categoryAverages = {};
  bool _loadingReviews = true;
  bool _canLeaveReview = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      username = args['username'];
    }
    initializeSharedPreferences();
    loadData();
    _loadUserInfo();
    getCurrentUser(); // Obtener el usuario actualmente autenticado
  }

  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> loadData() async {
    await initializeSharedPreferences();
    savedData = _prefs.getString('key');
    setState(() {}); // Actualiza el estado para reflejar los cambios
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final user = await authService.getUserInfo(widget.username);

      print('=== DEBUG PROFILE PAGE ===');
      print('Username: ${widget.username}');
      print('User data received: ${user != null}');
      if (user != null) {
        print('profilePhoto: ${user['profilePhoto']}');
        print('profilePhoto type: ${user['profilePhoto'].runtimeType}');
      }
      print('=========================');

      if (user != null) {
        setState(() {
          userInfo = {
            'username': user['username'],
            'birthdate': user['birthdate'], // Agregar fecha de nacimiento
            'gender': user['gender'], // Agregar género
            'preferences': user['preferences'],
            'personalInfo': user['personalInfo'],
            'livingHabits': user['livingHabits'],
            'housingInfo': user['housingInfo'],
            'dealBreakers': user['dealBreakers'],
            'verification': user['verification'],
            'profilePhoto': user['profilePhoto'],
            'aboutMe': user['aboutMe'],
            'isVerified': user['isVerified'],
          };
        });
      }

      if (userInfo?['profilePhoto'] != null) {
        print('Processing profilePhoto: ${userInfo?['profilePhoto']}');
        final imageProvider = ImageUtils.getImageProvider(userInfo?['profilePhoto']);
        print('ImageProvider created: ${imageProvider != null}');
        if (imageProvider != null) {
          setState(() {
            profilePhoto = Image(image: imageProvider);
          });
        }
      } else {
        print('No profilePhoto in userInfo');
      }
    } catch (error) {
      print('Error loading user information: $error');
      // Puedes manejar el error de alguna manera (por ejemplo, mostrar un mensaje al usuario)
    }
  }

  Future<void> getCurrentUser() async {
    final authService = AuthService();
    currentUser = await authService.loadUserData('username');
    
    // Cargar reviews después de tener el currentUser
    if (currentUser.isNotEmpty) {
      _loadReviews();
      _checkCanLeaveReview();
    }
  }

  // Cargar reviews del usuario
  Future<void> _loadReviews() async {
    // Solo cargar reviews si el usuario tiene lugar
    if (userInfo?['housingInfo']?['hasPlace'] != true) {
      setState(() {
        _loadingReviews = false;
      });
      return;
    }

    try {
      // Obtener reviews
      final reviewsData = await ReviewService.getReviewsForUser(
        username: widget.username,
        requesterUsername: currentUser,
      );

      // Obtener estadísticas
      final statsData = await ReviewService.getReviewStats(widget.username);

      setState(() {
        _reviews = reviewsData['reviews'] ?? [];
        _canViewReviews = reviewsData['canViewReviews'] ?? false;
        _reviewCount = reviewsData['reviewCount'] ?? 0;
        _averageRating = statsData['averageRating'] ?? 0.0;
        _categoryAverages = statsData['categoryAverages'] ?? {};
        _loadingReviews = false;
      });
    } catch (error) {
      print('Error loading reviews: $error');
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  // Verificar si el usuario actual puede dejar una review
  Future<void> _checkCanLeaveReview() async {
    if (currentUser == widget.username) {
      // No puedes dejarte review a ti mismo
      return;
    }

    try {
      final result = await ReviewService.canLeaveReview(
        reviewer: currentUser,
        reviewed: widget.username,
      );

      setState(() {
        _canLeaveReview = result['canLeave'] ?? false;
      });
    } catch (error) {
      print('Error checking review permissions: $error');
    }
  }

  // Calcular edad desde fecha de nacimiento
  int? _calculateAge(String? birthdateString) {
    if (birthdateString == null || birthdateString.isEmpty) return null;
    
    try {
      final birthdate = DateTime.parse(birthdateString);
      final today = DateTime.now();
      int age = today.year - birthdate.year;
      
      // Ajustar si aún no ha cumplido años este año
      if (today.month < birthdate.month ||
          (today.month == birthdate.month && today.day < birthdate.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      print('Error calculando edad: $e');
      return null;
    }
  }

  // Obtener traducción de género
  String _getGenderText(String? gender) {
    switch (gender) {
      case 'male':
        return 'Hombre';
      case 'female':
        return 'Mujer';
      case 'other':
        return 'Otro';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._buildProfileContentList(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomBarButton(
                icon: Icons.flash_on,
                label: 'Explorar',
                onTap: () {
                  // Lógica para el botón del rayo
                },
              ),
              _buildBottomBarButton(
                icon: Icons.home,
                label: 'Inicio',
                onTap: () {
                  Navigator.pushReplacementNamed(context, homeRoute);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700], size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProfileContentList() {
    final isCurrentUserProfile = currentUser == widget.username;
    
    return [
      _buildProfileImage(),
      const SizedBox(height: 20),
      // Botón de Editar Perfil (solo para el propio usuario)
      if (isCurrentUserProfile) _buildEditProfileButton(),
      if (isCurrentUserProfile) const SizedBox(height: 10),
      // Botón de Exportar Datos (solo para el propio usuario)
      if (isCurrentUserProfile) _buildExportDataButton(),
      if (isCurrentUserProfile) const SizedBox(height: 10),
      // Botones de gestión de fotos (solo para el propio usuario)
      if (isCurrentUserProfile) _buildPhotoManagementButtons(),
      if (isCurrentUserProfile) const SizedBox(height: 10),
      // Botón de Panel Admin (solo para admins)
      if (isCurrentUserProfile) _buildAdminButton(),
      if (isCurrentUserProfile) const SizedBox(height: 10),
      // Botón de Eliminar Cuenta (solo para el propio usuario)
      if (isCurrentUserProfile) _buildDeleteAccountButton(),
      const SizedBox(height: 20),
      _buildAdditionalImages(),
      const SizedBox(height: 20),
      _buildHomeImages(),
      const SizedBox(height: 20),
      _buildAdditionalInfoSection(),
    ];
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red[700],
          side: BorderSide(color: Colors.red[300]!),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton() {
    // Verificar si el usuario es admin
    final authService = AuthService();
    final userData = authService.loadUserData('isAdmin');
    final isAdmin = userData == true;

    if (!isAdmin) {
      return const SizedBox.shrink(); // No mostrar nada si no es admin
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, adminPanelRoute);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Panel de Administración',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    // Solo mostrar en el perfil propio
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (userInfo == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cargando información del perfil...')),
                );
                return;
              }
              Navigator.pushNamed(
                context,
                editProfileRoute,
                arguments: {
                  'username': widget.username,
                  'userData': userInfo,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(Icons.edit, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportDataButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: OutlinedButton.icon(
        onPressed: _exportUserData,
        icon: const Icon(Icons.download, size: 20),
        label: const Text('Exportar mis datos'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue[700],
          side: BorderSide(color: Colors.blue[300]!),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Exportar datos del usuario (Ley 25.326 Art. 14)
  void _exportUserData() async {
    try {
      final username = userInfo?['username'];
      
      // Diálogo informativo
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Text('Exportar Datos'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Se descargará un archivo JSON con toda tu información:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('• Datos de perfil'),
                Text('• Intereses y hábitos'),
                Text('• Información de vivienda'),
                Text('• Matches y estadísticas'),
                Text('• Enlaces a tus fotos'),
                SizedBox(height: 12),
                Text(
                  'Esto cumple con tu derecho de acceso a datos personales (Ley 25.326).',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exportar'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Exportando datos...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Llamar al endpoint de exportación
      final authService = AuthService();
      final token = _prefs.getString('accessToken');
      
      final response = await http.get(
        Uri.parse('${AuthService.api}/export/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Datos exportados exitosamente
        final exportData = jsonDecode(response.body);
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Mostrar diálogo con preview de los datos
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Datos Exportados'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tus datos han sido exportados exitosamente.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text('Vista previa (primeros campos):'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          JsonEncoder.withIndent('  ').convert(exportData).substring(0, 300) + '...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'En una aplicación web, esto se descargaría automáticamente. En la app móvil, puedes copiar y guardar esta información.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception('Error al exportar datos: ${response.statusCode}');
      }
    } catch (error) {
      print('Error exportando datos: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al exportar datos. Intenta nuevamente.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildPhotoManagementButtons() {
    // Obtener si el usuario tiene lugar
    final hasPlace = userInfo?['housingInfo']?['hasPlace'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Botón de Fotos de Perfil
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/manage-profile-photos',
                      arguments: {'username': widget.username},
                    );
                    // Recargar perfil cuando vuelve de la página de fotos
                    _loadUserInfo();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: const [
                        Icon(Icons.photo_library, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Mis Fotos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón de Fotos del Hogar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasPlace 
                      ? [Colors.teal.shade400, Colors.teal.shade600]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (hasPlace ? Colors.teal : Colors.grey).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/manage-home-photos',
                      arguments: {
                        'username': widget.username,
                        'hasPlace': hasPlace,
                      },
                    );
                    // Recargar perfil cuando vuelve de la página de fotos del hogar
                    _loadUserInfo();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: const [
                        Icon(Icons.home_work, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Mi Hogar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    final isCurrentUserProfile = currentUser == widget.username;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.person,
            title: 'Acerca de mí',
            content: userInfo?['personalInfo']['aboutMe'],
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.work,
            title: 'Trabajo',
            content: userInfo?['personalInfo']['job'],
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.favorite,
            title: 'Lo que me gusta',
            content: _formatPreferences(userInfo?['preferences']),
            color: Colors.pink,
            isEditable: false,
          ),
          
          // Mostrar religión y política solo si es el perfil propio
          if (isCurrentUserProfile) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.church,
              title: 'Religión',
              content: userInfo?['personalInfo']['religion'],
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.how_to_vote,
              title: 'Política',
              content: userInfo?['personalInfo']['politicPreference'],
              color: Colors.teal,
            ),
          ],
          
          const SizedBox(height: 24),
          const Text(
            'Estilo de Vida',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildLivingHabitsSection(),
          
          const SizedBox(height: 24),
          const Text(
            'Búsqueda de Vivienda',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildHousingInfoSection(),
          
          // Sección de Reviews (solo si el usuario tiene lugar)
          if (userInfo?['housingInfo']?['hasPlace'] == true) ...[
            const SizedBox(height: 24),
            _buildReviewsSection(),
          ],
          
          if (currentUser == widget.username) ...[
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? content,
    required Color color,
    bool isEditable = true,
  }) {
    final isCurrentUserProfile = currentUser == widget.username;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (isCurrentUserProfile && isEditable)
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit, color: color, size: 20),
                      onPressed: () {
                        _editAboutMe(title, content);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content ?? 'No especificado',
              style: TextStyle(
                fontSize: 15,
                color: content != null ? Colors.black87 : Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editAboutMe(String title, String? content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedContent = content ?? '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                _getIconForTitle(title),
                color: _getColorForTitle(title),
              ),
              const SizedBox(width: 12),
              Text(
                'Editar $title',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextFormField(
            initialValue: content ?? '',
            maxLines: title == 'Acerca de mí' ? 4 : 1,
            decoration: InputDecoration(
              hintText: 'Escribe aquí...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _getColorForTitle(title),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              updatedContent = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColorForTitle(title),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final authService = AuthService();
                final username = userInfo?['username'];
                final accessToken = _prefs.getString('accessToken');
                await authService.updateProfile(
                  username,
                  job: title == 'Trabajo' ? updatedContent : null,
                  religion: title == 'Religión' ? updatedContent : null,
                  politicPreference: title == 'Política' ? updatedContent : null,
                  aboutMe: title == 'Acerca de mí' ? updatedContent : null,
                  accessToken: accessToken,
                );
                Navigator.of(context).pop();
                await _loadUserInfo();
              },
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Acerca de mí':
        return Icons.person;
      case 'Trabajo':
        return Icons.work;
      case 'Religión':
        return Icons.church;
      case 'Política':
        return Icons.how_to_vote;
      default:
        return Icons.edit;
    }
  }

  Color _getColorForTitle(String title) {
    switch (title) {
      case 'Acerca de mí':
        return Colors.blue;
      case 'Trabajo':
        return Colors.orange;
      case 'Religión':
        return Colors.purple;
      case 'Política':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Widget _buildProfileImage() {
    final dynamic profilePhoto = userInfo?['profilePhoto'];

    if (profilePhoto != null && profilePhoto is String) {
      final imageProvider = ImageUtils.getImageProvider(profilePhoto);
      
      if (imageProvider != null) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 400,
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Image(
                    image: imageProvider,
                    width: 400,
                    height: 500,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: 400,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24.0),
                    bottomRight: Radius.circular(24.0),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20.0,
                bottom: 20.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          userInfo?['username'] ?? '',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        if (_calculateAge(userInfo?['birthdate']) != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            ', ${_calculateAge(userInfo?['birthdate'])}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (userInfo?['gender'] != null && userInfo?['gender'] != '') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            userInfo?['gender'] == 'male'
                                ? Icons.man
                                : userInfo?['gender'] == 'female'
                                    ? Icons.woman
                                    : Icons.person,
                            size: 18,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getGenderText(userInfo?['gender']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Mostrar rating si tiene lugar y reviews
                    if (userInfo?['housingInfo']?['hasPlace'] == true && 
                        _reviewCount > 0 && 
                        !_loadingReviews) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_averageRating.toStringAsFixed(1)} ($_reviewCount reviews)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildVerificationBadges(),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    // Cuando no hay foto de perfil, mostrar un placeholder completo
    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 400,
            height: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              color: Colors.grey[300],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Center(
                child: Icon(
                  Icons.account_circle,
                  size: 150,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          Container(
            width: 400,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24.0),
                bottomRight: Radius.circular(24.0),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 20.0,
            bottom: 20.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      userInfo?['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    if (_calculateAge(userInfo?['birthdate']) != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        ', ${_calculateAge(userInfo?['birthdate'])}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (userInfo?['gender'] != null && userInfo?['gender'] != '') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        userInfo?['gender'] == 'male'
                            ? Icons.man
                            : userInfo?['gender'] == 'female'
                                ? Icons.woman
                                : Icons.person,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getGenderText(userInfo?['gender']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                _buildVerificationBadges(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatList(List<dynamic>? items) {
    if (items != null && items.isNotEmpty) {
      return items.join(', ');
    }
    return 'No especificado';
  }

  String _formatPreferences(dynamic preferences) {
    if (preferences == null) {
      return 'No especificado';
    }

    // Si es una lista (formato antiguo), usar formatList
    if (preferences is List) {
      return _formatList(preferences);
    }

    // Si es un objeto (formato nuevo con categorías)
    if (preferences is Map) {
      List<String> allTags = [];
      
      preferences.forEach((mainCat, subCats) {
        if (subCats is Map) {
          subCats.forEach((subCat, tags) {
            if (tags is List && tags.isNotEmpty) {
              // Convertir cada tag al formato legible usando PreferencesData
              allTags.addAll(tags.map((t) {
                final tagKey = t.toString();
                return PreferencesData.tagLabels[tagKey] ?? tagKey;
              }));
            }
          });
        }
      });

      if (allTags.isEmpty) {
        return 'No especificado';
      }

      return allTags.join(', ');
    }

    return 'No especificado';
  }

  Widget _buildLivingHabitsSection() {
    final livingHabits = userInfo?['livingHabits'];
    if (livingHabits == null) {
      return const Text('No especificado', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: [
        _buildHabitRow(
          Icons.smoking_rooms,
          'Fumador',
          livingHabits['smoker'] == true ? 'Sí' : 'No',
          livingHabits['smoker'] == true ? Colors.orange : Colors.green,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.pets,
          'Mascotas',
          livingHabits['hasPets'] == true ? 'Tiene mascotas' : 'No tiene',
          livingHabits['hasPets'] == true ? Colors.brown : Colors.grey,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.favorite,
          'Acepta mascotas',
          livingHabits['acceptsPets'] == true ? 'Sí' : 'No',
          livingHabits['acceptsPets'] == true ? Colors.pink : Colors.grey,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.cleaning_services,
          'Limpieza',
          _translateCleanliness(livingHabits['cleanliness']),
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.volume_up,
          'Nivel de ruido',
          _translateNoiseLevel(livingHabits['noiseLevel']),
          Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.schedule,
          'Horarios',
          _translateSchedule(livingHabits['schedule']),
          Colors.indigo,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.people,
          'Nivel social',
          _translateSocialLevel(livingHabits['socialLevel']),
          Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.local_bar,
          'Consumo de alcohol',
          _translateDrinker(livingHabits['drinker']),
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildHousingInfoSection() {
    final housingInfo = userInfo?['housingInfo'];
    if (housingInfo == null) {
      return const Text('No especificado', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: [
        _buildHabitRow(
          Icons.home,
          'Situación',
          housingInfo['hasPlace'] == true ? 'Tiene lugar' : 'Busca lugar',
          housingInfo['hasPlace'] == true ? Colors.green : Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.location_city,
          'Ciudad',
          housingInfo['city'] ?? 'No especificado',
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.place,
          'Zona',
          housingInfo['generalZone'] ?? 'No especificado',
          Colors.deepOrange,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.calendar_today,
          'Fecha de mudanza',
          housingInfo['moveInDate'] ?? 'No especificado',
          Colors.cyan,
        ),
        const SizedBox(height: 12),
        _buildHabitRow(
          Icons.access_time,
          'Duración',
          _translateStayDuration(housingInfo['stayDuration']),
          Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _buildHabitRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _translateCleanliness(String? value) {
    switch (value) {
      case 'low': return 'Relajado';
      case 'normal': return 'Normal';
      case 'high': return 'Muy ordenado';
      default: return 'No especificado';
    }
  }

  String _translateNoiseLevel(String? value) {
    switch (value) {
      case 'quiet': return 'Tranquilo';
      case 'normal': return 'Normal';
      case 'social': return 'Social/Fiestas';
      default: return 'No especificado';
    }
  }

  String _translateSchedule(String? value) {
    switch (value) {
      case 'early': return 'Madrugador';
      case 'normal': return 'Normal';
      case 'night': return 'Nocturno';
      default: return 'No especificado';
    }
  }

  String _translateSocialLevel(String? value) {
    switch (value) {
      case 'independent': return 'Independiente';
      case 'friendly': return 'Amigable';
      case 'very_social': return 'Muy social';
      default: return 'No especificado';
    }
  }

  String _translateDrinker(String? value) {
    switch (value) {
      case 'never': return 'Nunca';
      case 'social': return 'Social';
      case 'regular': return 'Regularmente';
      default: return 'No especificado';
    }
  }

  String _translateStayDuration(String? value) {
    switch (value) {
      case '3months': return '3 meses';
      case '6months': return '6 meses';
      case '1year': return '1 año';
      case 'longterm': return 'Largo plazo (1+ año)';
      default: return 'No especificado';
    }
  }

  Widget _buildVerificationBadges() {
    final verification = userInfo?['verification'];
    if (verification == null) {
      return const SizedBox.shrink();
    }

    List<Widget> badges = [];

    // Email verificado
    if (verification['emailVerified'] == true || userInfo?['isVerified'] == true) {
      badges.add(_buildBadge(
        icon: Icons.email,
        label: 'Email',
        color: Colors.green,
      ));
    }

    // Teléfono verificado
    if (verification['phoneVerified'] == true) {
      badges.add(_buildBadge(
        icon: Icons.phone,
        label: 'Teléfono',
        color: Colors.blue,
      ));
    }

    // ID verificado
    if (verification['idVerified'] == true) {
      badges.add(_buildBadge(
        icon: Icons.badge,
        label: 'ID',
        color: Colors.purple,
      ));
    }

    // Selfie verificado
    if (verification['selfieVerified'] == true) {
      badges.add(_buildBadge(
        icon: Icons.face,
        label: 'Selfie',
        color: Colors.orange,
      ));
    }

    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Sin verificar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges,
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: color),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalImages() {
    // Implementa según tus necesidades
    return Container();
  }

  Widget _buildHomeImages() {
    // Implementa según tus necesidades
    return Container();
  }

  void _logout() async {
    try {
      final authService = AuthService();
      
      // Mostrar diálogo de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 12),
                Text('Cerrar Sesión'),
              ],
            ),
            content: const Text(
              '¿Estás seguro que deseas cerrar sesión?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Cerrando sesión...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Llamar al logout del servicio (revoca el token en el servidor)
      final success = await authService.logout(context);

      // Limpiar estado local
      setState(() {
        userInfo = null;
        profilePhoto = null;
      });

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  success 
                    ? 'Sesión cerrada exitosamente' 
                    : 'Sesión cerrada localmente',
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navegar a login
        Navigator.pushReplacementNamed(context, loginRoute);
      }
    } catch (error) {
      print('Error durante el cierre de sesión: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión, pero se limpió la sesión local'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushReplacementNamed(context, loginRoute);
      }
    }
  }

  // Botón de eliminar cuenta (Cumplimiento Ley 25.326 Art. 16)
  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: OutlinedButton.icon(
        onPressed: _deleteAccount,
        icon: const Icon(Icons.delete_forever, size: 20),
        label: const Text('Eliminar mi cuenta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red[900],
          side: BorderSide(color: Colors.red[900]!, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Eliminar cuenta permanentemente (Ley 25.326 - Derecho al Olvido)
  void _deleteAccount() async {
    try {
      final username = userInfo?['username'];
      
      // Primer diálogo de advertencia
      final confirm1 = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ Eliminar Cuenta',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Esta acción es PERMANENTE e IRREVERSIBLE.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Se eliminarán:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Tu perfil completo'),
                Text('• Todas tus fotos'),
                Text('• Tus matches y chats'),
                Text('• Toda tu información personal'),
                SizedBox(height: 12),
                Text(
                  '¿Estás seguro que deseas continuar?',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );

      if (confirm1 != true) return;

      // Segundo diálogo de confirmación final
      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Confirmación Final',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              '¿Realmente deseas eliminar tu cuenta de forma permanente?\n\nEsta es tu última oportunidad para cancelar.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, mantener mi cuenta'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, eliminar definitivamente'),
              ),
            ],
          );
        },
      );

      if (confirm2 != true) return;

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Eliminando cuenta...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Llamar al endpoint de eliminación
      final authService = AuthService();
      final token = _prefs.getString('accessToken');
      
      final response = await http.delete(
        Uri.parse('${AuthService.api}/delete/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Limpiar datos locales
        await authService.logout(context);
        await _prefs.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Cuenta eliminada exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navegar a login después de 2 segundos
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
        }
      } else {
        throw Exception('Error al eliminar cuenta: ${response.statusCode}');
      }
    } catch (error) {
      print('Error eliminando cuenta: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al eliminar cuenta. Intenta nuevamente.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ========== SECCIÓN DE REVIEWS ==========

  Widget _buildReviewsSection() {
    if (_loadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // Título con rating promedio
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_reviewCount > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($_reviewCount)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Botón de dejar review
        if (_canLeaveReview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _showCreateReviewDialog,
              icon: const Icon(Icons.rate_review),
              label: const Text('Dejar una Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Mostrar reviews o mensaje
        if (_reviewCount == 0)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Este usuario aún no tiene reviews',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          _buildReviewsList(),
      ],
    );
  }

  Widget _buildReviewsList() {
    return Column(
      children: [
        // Promedios por categoría (solo si puede ver)
        if (_canViewReviews && _categoryAverages.isNotEmpty)
          _buildCategoryAverages(),

        const SizedBox(height: 20),

        // Lista de reviews
        ..._reviews.take(3).map((review) => _buildReviewCard(review)).toList(),

        // Botón ver más o upgrade premium
        if (_reviewCount > 3)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: _canViewReviews
                  ? () {
                      // TODO: Mostrar todas las reviews en una página separada
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                        ),
                      );
                    }
                  : _showPremiumDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canViewReviews ? Colors.blue : Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _canViewReviews
                    ? 'Ver todas las reviews ($_reviewCount)'
                    : '⭐ Hazte Premium para ver todas',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryAverages() {
    final categories = {
      'cleanliness': {'label': 'Limpieza', 'icon': Icons.cleaning_services},
      'communication': {'label': 'Comunicación', 'icon': Icons.chat},
      'accuracy': {'label': 'Precisión', 'icon': Icons.check_circle},
      'location': {'label': 'Ubicación', 'icon': Icons.location_on},
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: categories.entries.map((entry) {
          final rating = _categoryAverages[entry.key] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(entry.value['icon'] as IconData, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value['label'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                _buildStarRating(rating),
                const SizedBox(width: 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toDouble();
    final comment = review['comment'] ?? '';
    final reviewer = review['reviewer'] ?? 'Usuario';
    final timestamp = review['createdAt'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con reviewer y rating
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        reviewer[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewer,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (timestamp.isNotEmpty)
                            Text(
                              _formatReviewDate(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStarRating(rating),
                  ],
                ),
                const SizedBox(height: 12),
                // Comentario
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          // Blur si no puede ver
          if (!_canViewReviews)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showPremiumDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Desbloquear con Premium'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  String _formatReviewDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoy';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 30) {
        return 'Hace ${difference.inDays} días';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'Hace $years ${years == 1 ? 'año' : 'años'}';
      }
    } catch (e) {
      return '';
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.purple, size: 28),
            SizedBox(width: 8),
            Text('Premium'),
          ],
        ),
        content: const Text(
          'Hazte Premium para:\n\n'
          '⭐ Ver todas las reviews completas\n'
          '👀 Ver quién te dio like\n'
          '💬 Enviar mensajes sin esperar match\n'
          '🚀 Y mucho más...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navegar a página de suscripción
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sistema de pagos próximamente'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suscribirme'),
          ),
        ],
      ),
    );
  }

  void _showCreateReviewDialog() {
    double rating = 5.0;
    double cleanliness = 5.0;
    double communication = 5.0;
    double accuracy = 5.0;
    double location = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Dejar una Review'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating General', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: rating.toString(),
                    onChanged: (value) => setState(() => rating = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  
                  // Limpieza
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.cleaning_services, size: 20),
                      const SizedBox(width: 8),
                      const Text('Limpieza'),
                      const Spacer(),
                      Text(cleanliness.toStringAsFixed(1)),
                    ],
                  ),
                  Slider(
                    value: cleanliness,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => cleanliness = value),
                  ),
                  
                  // Comunicación
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.chat, size: 20),
                      const SizedBox(width: 8),
                      const Text('Comunicación'),
                      const Spacer(),
                      Text(communication.toStringAsFixed(1)),
                    ],
                  ),
                  Slider(
                    value: communication,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => communication = value),
                  ),
                  
                  // Precisión
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      const Text('Precisión'),
                      const Spacer(),
                      Text(accuracy.toStringAsFixed(1)),
                    ],
                  ),
                  Slider(
                    value: accuracy,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => accuracy = value),
                  ),
                  
                  // Ubicación
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      const Text('Ubicación'),
                      const Spacer(),
                      Text(location.toStringAsFixed(1)),
                    ],
                  ),
                  Slider(
                    value: location,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => location = value),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Comentario
                  const Text('Comentario', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Comparte tu experiencia...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor escribe un comentario'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  // Mostrar loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final result = await ReviewService.createReview(
                    reviewer: currentUser,
                    reviewed: widget.username,
                    rating: rating,
                    categories: {
                      'cleanliness': cleanliness,
                      'communication': communication,
                      'accuracy': accuracy,
                      'location': location,
                    },
                    comment: commentController.text.trim(),
                  );

                  // Cerrar loading
                  if (mounted) Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Review enviada'),
                        backgroundColor: result['success'] ? Colors.green : Colors.red,
                      ),
                    );

                    if (result['success']) {
                      // Recargar reviews
                      _checkCanLeaveReview();
                      _loadReviews();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enviar Review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

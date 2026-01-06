import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_utils.dart';

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

      if (user != null) {
        setState(() {
          userInfo = {
            'username': user['username'],
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
        final imageProvider = ImageUtils.getImageProvider(userInfo?['profilePhoto']);
        if (imageProvider != null) {
          setState(() {
            profilePhoto = Image(image: imageProvider);
          });
        }
      }
    } catch (error) {
      print('Error loading user information: $error');
      // Puedes manejar el error de alguna manera (por ejemplo, mostrar un mensaje al usuario)
    }
  }

  Future<void> getCurrentUser() async {
    final authService = AuthService();
    currentUser = await authService.loadUserData('username');
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
      // Botones de gestión de fotos (solo para el propio usuario)
      if (isCurrentUserProfile) _buildPhotoManagementButtons(),
      if (isCurrentUserProfile) const SizedBox(height: 10),
      // Botón de Panel Admin (solo para admins)
      if (isCurrentUserProfile) _buildAdminButton(),
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
            content: _formatList(userInfo?['preferences']),
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
      setState(() {
        userInfo = null;
        profilePhoto = null;
      });

      // Muestra un mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cierre de sesión exitoso.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Navega a la página de inicio de sesión
      Navigator.pushReplacementNamed(context, loginRoute);
    } catch (error) {
      print('Error durante el cierre de sesión: $error');
      // Puedes manejar el error de alguna manera (mostrar un mensaje al usuario, por ejemplo)
    }
  }
}

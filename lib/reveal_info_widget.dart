import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'socket_service.dart';
import 'dart:async';

class RevealInfoWidget extends StatefulWidget {
  final String currentUsername;
  final String matchedUsername;

  const RevealInfoWidget({
    Key? key,
    required this.currentUsername,
    required this.matchedUsername,
  }) : super(key: key);

  @override
  _RevealInfoWidgetState createState() => _RevealInfoWidgetState();
}

class _RevealInfoWidgetState extends State<RevealInfoWidget> {
  Map<String, dynamic>? _revealedInfo;
  Map<String, dynamic>? _matchedUserInfo;
  bool _isLoading = true;
  final SocketService _socketService = SocketService();
  StreamSubscription? _revealInfoSubscription;

  @override
  void initState() {
    super.initState();
    _loadRevealedInfo();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Escuchar eventos de reveal_info_updated
    _socketService.onCustomEvent('reveal_info_updated').listen((data) {
      // Solo actualizar si el evento es relevante para este match
      if (data['matchedUser'] == widget.currentUsername || 
          data['matchedUser'] == widget.matchedUsername) {
        print('[DEBUG] Reveal info updated event received, reloading...');
        _loadRevealedInfo();
      }
    });
  }

  Future<void> _loadRevealedInfo() async {
    try {
      print('[DEBUG] Loading revealed info for ${widget.currentUsername} and ${widget.matchedUsername}');
      
      // Obtener info del usuario actual
      final currentUser = await AuthService().getUserInfo(widget.currentUsername);
      print('[DEBUG] Current user data: ${currentUser?['username']}');
      print('[DEBUG] Current user revealedInfo: ${currentUser?['revealedInfo']}');
      
      // Obtener info del usuario con el que hizo match
      final matchedUser = await AuthService().getUserInfo(widget.matchedUsername);
      print('[DEBUG] Matched user data: ${matchedUser?['username']}');
      print('[DEBUG] Matched user revealedInfo: ${matchedUser?['revealedInfo']}');

      // Buscar la información revelada específica de este match (por el usuario actual)
      final revealedInfoList = currentUser?['revealedInfo'] as List?;
      Map<String, dynamic>? currentUserRevealed;
      
      if (revealedInfoList != null) {
        for (var info in revealedInfoList) {
          if (info['matchedUser'] == widget.matchedUsername) {
            currentUserRevealed = info;
            print('[DEBUG] Found current user revealed info: $info');
            break;
          }
        }
      }

      // Buscar la información revelada por el otro usuario
      final matchedUserRevealedList = matchedUser?['revealedInfo'] as List?;
      Map<String, dynamic>? matchedUserRevealed;
      
      if (matchedUserRevealedList != null) {
        for (var info in matchedUserRevealedList) {
          if (info['matchedUser'] == widget.currentUsername) {
            matchedUserRevealed = info;
            print('[DEBUG] Found matched user revealed info: $info');
            break;
          }
        }
      }

      print('[DEBUG] Current user revealed zones: ${currentUserRevealed?['revealedZones']}');
      print('[DEBUG] Matched user revealed zones: ${matchedUserRevealed?['revealedZones']}');

      setState(() {
        _revealedInfo = {
          'revealedZones': currentUserRevealed?['revealedZones'] ?? false,
          'revealedBudget': currentUserRevealed?['revealedBudget'] ?? false,
          'revealedContact': currentUserRevealed?['revealedContact'] ?? false,
          'revealedName': currentUserRevealed?['revealedName'] ?? false,
          // Solo mostrar si AMBOS revelaron
          'showZones': (currentUserRevealed?['revealedZones'] ?? false) && 
                      (matchedUserRevealed?['revealedZones'] ?? false),
          'showBudget': (currentUserRevealed?['revealedBudget'] ?? false) && 
                       (matchedUserRevealed?['revealedBudget'] ?? false),
          'showContact': (currentUserRevealed?['revealedContact'] ?? false) && 
                        (matchedUserRevealed?['revealedContact'] ?? false),
          'showName': (currentUserRevealed?['revealedName'] ?? false) && 
                     (matchedUserRevealed?['revealedName'] ?? false),
        };
        _matchedUserInfo = matchedUser;
        _isLoading = false;
        
        print('[DEBUG] Final showZones: ${_revealedInfo!['showZones']}');
        print('[DEBUG] Final showBudget: ${_revealedInfo!['showBudget']}');
        print('[DEBUG] Final showContact: ${_revealedInfo!['showContact']}');
      });
    } catch (error) {
      print('[DEBUG ERROR] Error loading revealed info: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Obtener los barrios específicos correctos según si tiene lugar o busca
  List<dynamic>? _getSpecificNeighborhoods() {
    final housingInfo = _matchedUserInfo?['housingInfo'];
    if (housingInfo == null) return null;
    
    final hasPlace = housingInfo['hasPlace'] ?? false;
    
    // Intentar obtener barrios nuevos primero
    if (hasPlace) {
      final neighborhoods = housingInfo['specificNeighborhoodsOrigin'];
      if (neighborhoods != null && neighborhoods is List && neighborhoods.isNotEmpty) {
        return neighborhoods;
      }
    } else {
      final neighborhoods = housingInfo['specificNeighborhoodsDestination'];
      if (neighborhoods != null && neighborhoods is List && neighborhoods.isNotEmpty) {
        return neighborhoods;
      }
    }
    
    // Fallback a preferredZones legacy
    return housingInfo['preferredZones'];
  }

  Future<void> _revealInformation(String infoType) async {
    try {
      final response = await AuthService().revealInformation(
        widget.currentUsername,
        widget.matchedUsername,
        infoType,
      );

      if (response) {
        // Notificar al otro usuario via Socket.IO
        _socketService.emit('reveal_info', {
          'username': widget.currentUsername,
          'matchedUser': widget.matchedUsername,
          'infoType': infoType,
        });
        
        // Recargar la información inmediatamente
        await _loadRevealedInfo();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Información revelada. ${_shouldShowInfo(infoType) ? "¡Ahora ambos pueden verla!" : "Esperando que el otro usuario también revele."}'),
            backgroundColor: _shouldShowInfo(infoType) ? Colors.green : Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al revelar información'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _shouldShowInfo(String infoType) {
    switch (infoType) {
      case 'zones':
        return _revealedInfo?['showZones'] ?? false;
      case 'budget':
        return _revealedInfo?['showBudget'] ?? false;
      case 'contact':
        return _revealedInfo?['showContact'] ?? false;
      case 'name':
        return _revealedInfo?['showName'] ?? false;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.lock_open, color: Colors.blue.shade700),
        title: const Text(
          'Revelar información adicional',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Ambos deben aceptar para verla',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barrios específicos
                _buildRevealOption(
                  icon: Icons.location_on,
                  title: 'Barrios específicos',
                  description: 'Revelar barrios/localidades preferidos',
                  isRevealed: _revealedInfo?['revealedZones'] ?? false,
                  canShow: _revealedInfo?['showZones'] ?? false,
                  onReveal: () => _revealInformation('zones'),
                  revealedData: _getSpecificNeighborhoods(),
                ),

                const SizedBox(height: 12),

                // Presupuesto aproximado
                _buildRevealOption(
                  icon: Icons.attach_money,
                  title: 'Rango de presupuesto',
                  description: 'Revelar presupuesto aproximado',
                  isRevealed: _revealedInfo?['revealedBudget'] ?? false,
                  canShow: _revealedInfo?['showBudget'] ?? false,
                  onReveal: () => _revealInformation('budget'),
                  revealedData: _matchedUserInfo?['housingInfo'] != null
                      ? '\$${_matchedUserInfo!['housingInfo']['budgetMin']} - \$${_matchedUserInfo!['housingInfo']['budgetMax']}'
                      : null,
                ),

                const SizedBox(height: 12),

                // Nombre y Apellido
                _buildRevealOption(
                  icon: Icons.badge,
                  title: 'Nombre y Apellido',
                  description: 'Revelar nombre completo',
                  isRevealed: _revealedInfo?['revealedName'] ?? false,
                  canShow: _revealedInfo?['showName'] ?? false,
                  onReveal: () => _revealInformation('name'),
                  revealedData: (_matchedUserInfo?['personalInfo']?['firstName'] != null && 
                                 _matchedUserInfo?['personalInfo']?['firstName'] != '' &&
                                 _matchedUserInfo?['personalInfo']?['lastName'] != null &&
                                 _matchedUserInfo?['personalInfo']?['lastName'] != '')
                      ? '${_matchedUserInfo!['personalInfo']['firstName']} ${_matchedUserInfo!['personalInfo']['lastName']}'
                      : null,
                ),

                const SizedBox(height: 12),

                // Información de contacto
                _buildRevealOption(
                  icon: Icons.phone,
                  title: 'Información de contacto',
                  description: 'Revelar teléfono/email',
                  isRevealed: _revealedInfo?['revealedContact'] ?? false,
                  canShow: _revealedInfo?['showContact'] ?? false,
                  onReveal: () => _revealInformation('contact'),
                  revealedData: _matchedUserInfo?['email'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealOption({
    required IconData icon,
    required String title,
    required String description,
    required bool isRevealed,
    required bool canShow,
    required VoidCallback onReveal,
    dynamic revealedData,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canShow ? Colors.green.shade50 : (isRevealed ? Colors.blue.shade50 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canShow ? Colors.green.shade300 : (isRevealed ? Colors.blue.shade300 : Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: canShow ? Colors.green.shade700 : (isRevealed ? Colors.blue.shade600 : Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: canShow ? Colors.green.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (isRevealed && !canShow) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Esperando que el otro usuario también revele',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (canShow && revealedData != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      revealedData is List
                          ? revealedData.join(', ')
                          : revealedData.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          canShow
              ? Icon(Icons.check_circle, color: Colors.green.shade700)
              : isRevealed
                  ? Icon(Icons.schedule, color: Colors.blue.shade600)
                  : ElevatedButton(
                      onPressed: onReveal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Revelar'),
                    ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _revealInfoSubscription?.cancel();
    super.dispose();
  }
}

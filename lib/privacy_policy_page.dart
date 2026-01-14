import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'POLÍTICA DE PRIVACIDAD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Última actualización: 14 de Enero de 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const Divider(height: 32),
                
                _buildSection(
                  '1. Introducción',
                  'En Roomier, nos tomamos muy en serio la privacidad de nuestros usuarios. '
                  'Esta Política de Privacidad describe cómo recopilamos, usamos, almacenamos '
                  'y protegemos su información personal.',
                ),
                
                _buildSection(
                  '2. Información que Recopilamos',
                  'Recopilamos los siguientes tipos de información:\n\n'
                  'Información de Perfil:\n'
                  '• Nombre de usuario y contraseña\n'
                  '• Fecha de nacimiento\n'
                  '• Correo electrónico\n'
                  '• Foto de perfil\n'
                  '• Información personal (trabajo, religión, preferencias políticas)\n'
                  '• Intereses y hobbies\n\n'
                  'Información de Convivencia:\n'
                  '• Hábitos de vida (horarios, limpieza, ruido, etc.)\n'
                  '• Preferencias de vivienda\n'
                  '• Presupuesto (PRIVADO)\n'
                  '• Zonas preferidas (PRIVADO)\n\n'
                  'Información de Uso:\n'
                  '• Interacciones en la aplicación\n'
                  '• Mensajes enviados\n'
                  '• Matches realizados\n'
                  '• Dirección IP y datos del dispositivo',
                ),
                
                _buildSection(
                  '3. Cómo Usamos su Información',
                  'Utilizamos su información para:\n'
                  '• Crear y gestionar su cuenta\n'
                  '• Conectarlo con posibles roommates compatibles\n'
                  '• Calcular compatibilidad mediante nuestro algoritmo\n'
                  '• Facilitar comunicación entre usuarios\n'
                  '• Mejorar nuestros servicios\n'
                  '• Prevenir fraudes y abusos\n'
                  '• Enviar notificaciones relevantes\n'
                  '• Cumplir con obligaciones legales',
                ),
                
                _buildSection(
                  '4. Sistema de Privacidad Progresiva',
                  'Roomier implementa un sistema único de privacidad progresiva:\n\n'
                  '• Su presupuesto y zonas específicas NO son visibles inicialmente\n'
                  '• Esta información solo se revela cuando AMBOS usuarios lo aprueban\n'
                  '• Usted controla qué información revela y cuándo\n'
                  '• Puede revocar el acceso en cualquier momento',
                ),
                
                _buildSection(
                  '5. Compartir Información',
                  'Su información es compartida en los siguientes casos:\n\n'
                  'Con otros usuarios:\n'
                  '• Información pública de perfil (nombre, foto, intereses, hábitos)\n'
                  '• Información revelada progresivamente (tras aprobación mutua)\n\n'
                  'NO compartimos:\n'
                  '• Su contraseña\n'
                  '• Información sensible sin su consentimiento\n'
                  '• Datos con terceros para marketing\n'
                  '• Información de pago (si aplicable)',
                ),
                
                _buildSection(
                  '6. Seguridad de Datos',
                  'Implementamos múltiples medidas de seguridad:\n'
                  '• Encriptación de contraseñas con bcrypt\n'
                  '• Tokens JWT para autenticación segura\n'
                  '• Protección contra ataques de fuerza bruta (rate limiting)\n'
                  '• Servidores seguros\n'
                  '• Monitoreo continuo de seguridad\n\n'
                  'Sin embargo, ningún sistema es 100% seguro. Le recomendamos usar '
                  'contraseñas fuertes y no compartir credenciales.',
                ),
                
                _buildSection(
                  '7. Sus Derechos',
                  'Usted tiene derecho a:\n'
                  '• Acceder a su información personal\n'
                  '• Corregir información incorrecta\n'
                  '• Solicitar eliminación de su cuenta\n'
                  '• Exportar sus datos\n'
                  '• Oponerse al procesamiento de sus datos\n'
                  '• Revocar consentimientos\n'
                  '• Presentar quejas ante autoridades',
                ),
                
                _buildSection(
                  '8. Retención de Datos',
                  'Conservamos su información:\n'
                  '• Mientras su cuenta esté activa\n'
                  '• Por el tiempo necesario para cumplir obligaciones legales\n'
                  '• Hasta 30 días después de eliminar su cuenta (periodo de gracia)\n\n'
                  'Después de este periodo, su información será eliminada permanentemente, '
                  'excepto datos requeridos por ley.',
                ),
                
                _buildSection(
                  '9. Menores de Edad',
                  'Roomier NO está destinada a menores de 18 años. Si descubrimos que un '
                  'menor ha creado una cuenta, la eliminaremos inmediatamente.',
                ),
                
                _buildSection(
                  '10. Cookies y Tecnologías Similares',
                  'Utilizamos cookies y tecnologías similares para:\n'
                  '• Mantener su sesión activa\n'
                  '• Recordar sus preferencias\n'
                  '• Analizar el uso de la aplicación\n'
                  '• Mejorar la experiencia del usuario',
                ),
                
                _buildSection(
                  '11. Transferencias Internacionales',
                  'Sus datos pueden ser procesados en servidores ubicados en diferentes países. '
                  'Aseguramos que dichas transferencias cumplan con las leyes de protección de datos aplicables.',
                ),
                
                _buildSection(
                  '12. Cambios a esta Política',
                  'Podemos actualizar esta política periódicamente. Los cambios significativos '
                  'serán notificados mediante:\n'
                  '• Notificación en la aplicación\n'
                  '• Email a su dirección registrada\n'
                  '• Actualización de la fecha en esta página',
                ),
                
                _buildSection(
                  '13. Contacto y Preguntas',
                  'Para ejercer sus derechos o resolver dudas sobre privacidad:\n\n'
                  'Email: roomier2024@gmail.com\n'
                  'Asunto: "Privacidad - [Su consulta]"\n\n'
                  'Responderemos en un plazo máximo de 30 días.',
                ),
                
                _buildSection(
                  '14. Cumplimiento Legal',
                  'Esta política cumple con:\n'
                  '• Ley de Protección de Datos Personales de Argentina (Ley 25.326)\n'
                  '• Principios de GDPR (si aplicable)\n'
                  '• Mejores prácticas internacionales de privacidad',
                ),
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade700, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.blue.shade700, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Su privacidad es importante. Nunca venderemos su información personal '
                          'a terceros. Tiene control total sobre qué información comparte.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Legal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Desarrollador: Francisco Baralle\n'
            'Email de contacto: roomier2024@gmail.com\n'
            'Domicilio fiscal: Córdoba, Argentina',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cumplimos con:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '• Ley 25.326 de Protección de Datos Personales\n'
            '• Ley 24.240 de Defensa del Consumidor\n'
            '• Ley 27.078 Argentina Digital',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

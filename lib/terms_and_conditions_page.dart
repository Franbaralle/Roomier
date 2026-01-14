import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
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
                    'TÉRMINOS Y CONDICIONES DE USO',
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
                  '1. Aceptación de los Términos',
                  'Al acceder y utilizar Roomier ("la Aplicación"), usted acepta estar sujeto a estos Términos y Condiciones. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar la Aplicación.',
                ),
                
                _buildSection(
                  '2. Elegibilidad',
                  'Para utilizar Roomier, debe:\n'
                  '• Ser mayor de 18 años\n'
                  '• Proporcionar información veraz y precisa\n'
                  '• Mantener la seguridad de su cuenta\n'
                  '• No crear múltiples cuentas\n'
                  '• No usar la aplicación para fines ilegales',
                ),
                
                _buildSection(
                  '3. Uso de la Aplicación',
                  'Roomier es una plataforma para conectar personas que buscan roommates. '
                  'La Aplicación facilita el contacto, pero no garantiza la compatibilidad, '
                  'honestidad o seguridad de otros usuarios. Usted es responsable de todas '
                  'las interacciones y acuerdos que realice con otros usuarios.',
                ),
                
                _buildSection(
                  '4. Contenido del Usuario',
                  'Al publicar contenido en Roomier, usted:\n'
                  '• Garantiza que tiene derecho a compartir dicho contenido\n'
                  '• Nos otorga licencia para usar, mostrar y distribuir su contenido\n'
                  '• Es responsable de la veracidad de su información\n'
                  '• Se compromete a no publicar contenido ofensivo, ilegal o engañoso',
                ),
                
                _buildSection(
                  '5. Conducta Prohibida',
                  'Está estrictamente prohibido:\n'
                  '• Acosar, amenazar o intimidar a otros usuarios\n'
                  '• Suplantar identidad o crear perfiles falsos\n'
                  '• Enviar spam o contenido no solicitado\n'
                  '• Usar la aplicación para estafas o fraudes\n'
                  '• Extraer datos de otros usuarios sin consentimiento\n'
                  '• Intentar acceder a cuentas de otros usuarios',
                ),
                
                _buildSection(
                  '6. Verificación y Seguridad',
                  'Roomier puede ofrecer servicios de verificación de identidad. Sin embargo, '
                  'NO GARANTIZAMOS la identidad, historial o intenciones de ningún usuario. '
                  'Es su responsabilidad tomar precauciones al interactuar con otros usuarios.',
                ),
                
                _buildSection(
                  '7. Privacidad y Protección de Datos Personales',
                  'Su información personal será manejada según nuestra Política de Privacidad '
                  'y en cumplimiento de la Ley 25.326 de Protección de Datos Personales de Argentina. '
                  'Información sensible como presupuesto y zonas específicas solo será revelada '
                  'cuando usted lo autorice explícitamente.',
                ),
                
                _buildSection(
                  '7.1. Tratamiento de Datos Sensibles (Ley 25.326)',
                  'En cumplimiento del Art. 7 de la Ley 25.326, Roomier puede recolectar los siguientes '
                  'datos sensibles ÚNICAMENTE con su consentimiento expreso y por escrito:\n\n'
                  '• Religión (opcional)\n'
                  '• Preferencia política (opcional)\n\n'
                  'IMPORTANTE:\n'
                  '• Estos datos son completamente OPCIONALES\n'
                  '• Solo se recolectarán si usted da su consentimiento específico mediante checkbox\n'
                  '• Se utilizarán exclusivamente para mejorar la compatibilidad en el matching\n'
                  '• Puede solicitar su eliminación en cualquier momento\n'
                  '• NO compartiremos estos datos con terceros\n'
                  '• Están protegidos con medidas de seguridad adicionales\n\n'
                  'El consentimiento para estos datos sensibles es independiente y NO está incluido '
                  'en la aceptación general de estos términos. Debe otorgarse de forma específica '
                  'durante el registro.',
                ),
                
                _buildSection(
                  '7.2. Derechos del Titular de Datos (ARCO)',
                  'Según la Ley 25.326, usted tiene derecho a:\n\n'
                  '• ACCESO: Consultar qué datos tenemos sobre usted\n'
                  '• RECTIFICACIÓN: Corregir datos inexactos o desactualizados\n'
                  '• CANCELACIÓN: Solicitar la eliminación de sus datos\n'
                  '• OPOSICIÓN: Negarse al tratamiento de sus datos\n\n'
                  'Para ejercer estos derechos, contáctenos en roomier2024@gmail.com. '
                  'Responderemos en un plazo de 10 días hábiles.',
                ),
                
                _buildSection(
                  '8. Terminación de Cuenta',
                  'Nos reservamos el derecho de suspender o terminar su cuenta si:\n'
                  '• Viola estos términos\n'
                  '• Recibe múltiples reportes de otros usuarios\n'
                  '• Utiliza la aplicación de manera inapropiada\n'
                  '• Proporciona información falsa o engañosa',
                ),
                
                _buildSection(
                  '9. Limitación de Responsabilidad',
                  'Roomier NO ES RESPONSABLE por:\n'
                  '• Daños resultantes del uso de la aplicación\n'
                  '• Pérdidas económicas por interacciones con otros usuarios\n'
                  '• Problemas de vivienda o convivencia\n'
                  '• Veracidad de la información de otros usuarios\n'
                  '• Disputas entre usuarios',
                ),
                
                _buildSection(
                  '10. Recomendaciones de Seguridad',
                  'Le recomendamos encarecidamente:\n'
                  '• Conocer a posibles roommates en lugares públicos\n'
                  '• Verificar identidad mediante documentos oficiales\n'
                  '• No compartir información financiera sensible prematuramente\n'
                  '• Leer y firmar contratos de arrendamiento apropiados\n'
                  '• Reportar comportamiento sospechoso o inapropiado',
                ),
                
                _buildSection(
                  '11. Propiedad Intelectual',
                  'Todo el contenido, diseño, logos y funcionalidades de Roomier son propiedad '
                  'de la aplicación y están protegidos por leyes de propiedad intelectual.',
                ),
                
                _buildSection(
                  '12. Modificaciones',
                  'Nos reservamos el derecho de modificar estos términos en cualquier momento. '
                  'Los cambios serán efectivos inmediatamente después de su publicación. '
                  'El uso continuado de la aplicación constituye aceptación de los términos modificados.',
                ),
                
                _buildSection(
                  '13. Legislación Aplicable',
                  'Estos términos se rigen por las leyes de Argentina. Cualquier disputa será '
                  'resuelta en los tribunales competentes de Córdoba, Argentina.',
                ),
                
                _buildSection(
                  '14. Contacto',
                  'Para preguntas sobre estos términos, contáctenos en:\n'
                  'Email: roomier2024@gmail.com',
                ),
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'IMPORTANTE: Roomier es una plataforma de conexión. No somos responsables '
                          'de los acuerdos o interacciones entre usuarios. Use la aplicación con prudencia.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),                
                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                
                // Footer con datos fiscales (Ley 27.078)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Legal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Desarrollado por: Francisco Baralle\n'
                        'Email: roomier2024@gmail.com\n'
                        'Domicilio: Córdoba, Argentina\n\n'
                        'Esta aplicación cumple con:\n'
                        '• Ley 25.326 - Protección de Datos Personales\n'
                        '• Ley 24.240 - Defensa del Consumidor\n'
                        '• Ley 27.078 - Servicios de Comunicación',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),              ],
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
}

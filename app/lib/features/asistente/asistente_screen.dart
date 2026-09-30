import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_drawer.dart';
import '../deudas/deudas_service.dart';
import '../movimientos/movimientos_service.dart';
import 'asistente_service.dart';

class _Mensaje {
  final String texto;
  final bool esUsuario;
  _Mensaje(this.texto, this.esUsuario);
}

class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});
  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Mensaje> _mensajes = [];
  bool _pensando = false;

  static const _sugerencias = [
    '¿Cuánto puedo gastar este fin de semana?',
    '¿En qué estoy gastando demasiado?',
    '¿Cómo va mi disponible real este mes?',
  ];

  Future<void> _enviar(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || _pensando) return;
    setState(() {
      _mensajes.add(_Mensaje(limpio, true));
      _pensando = true;
    });
    _inputCtrl.clear();
    _scrollAlFinal();

    try {
      final movimientos = await MovimientosService.obtenerTodos();
      final deudas = await DeudasService.obtenerTodas();
      final respuesta = await AsistenteService.preguntar(
        pregunta: limpio,
        movimientos: movimientos,
        deudas: deudas,
      );
      setState(() => _mensajes.add(_Mensaje(respuesta, false)));
    } catch (e) {
      setState(() => _mensajes.add(_Mensaje(
        e.toString().replaceAll('Exception: ', ''),
        false,
      )));
    } finally {
      setState(() => _pensando = false);
      _scrollAlFinal();
    }
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente financiero')),
      drawer: AppDrawer(actual: DrawerRuta.asistente),
      body: Column(
        children: [
          Expanded(
            child: _mensajes.isEmpty
                ? _estadoVacio()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (ctx, i) => _burbuja(_mensajes[i]),
                  ),
          ),
          if (_pensando)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.copper),
                  ),
                  const SizedBox(width: 10),
                  Text('Pensando...', style: AppText.caption),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.onyx,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.graphite),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu pregunta...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        onPressed: () => _enviar(_inputCtrl.text),
                        icon: const Icon(Icons.arrow_upward, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.paperWhite,
                          foregroundColor: Colors.black,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EL DISPONIBLE REAL', style: AppText.eyebrow),
          const SizedBox(height: 8),
          Text('Pregúntame lo que quieras', style: AppText.heading.copyWith(fontSize: 28)),
          const SizedBox(height: 24),
          ..._sugerencias.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _enviar(s),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.graphite),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s, style: AppText.body.copyWith(fontSize: 14)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _burbuja(_Mensaje m) {
    return Align(
      alignment: m.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: m.esUsuario ? AppColors.paperWhite : AppColors.onyx,
          border: m.esUsuario ? null : Border.all(color: AppColors.graphite),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          m.texto,
          style: AppText.body.copyWith(
            fontSize: 14,
            color: m.esUsuario ? Colors.black : AppColors.bone,
          ),
        ),
      ),
    );
  }
}
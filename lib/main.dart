// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'ListaAgenda.dart';

void main() {
  runApp(const MyApp());
}

final Map<String, String> musicas = {
  'Música 1': 'assets/musica1.mp3',
  'Música 2': 'assets/musica2.mp3',
  'Música 3': 'assets/musica3.mp3',
  'Música 4': 'assets/musica4.mp3'
};

class Tarefa {
  final String hora;
  final String minutos;
  final String nome;
  final String musica;

  Tarefa({
    required this.hora,
    required this.minutos,
    required this.nome,
    required this.musica,
  });

  @override
  String toString() {
    String horaFormatado = hora.padLeft(2, '0');
    String minutoFormatado = minutos.padLeft(2, '0');
    return '$horaFormatado:$minutoFormatado, Nome: $nome, Música: $musica';
  }

  static Tarefa fromString(String tarefaString) {
    var partes = tarefaString.split(', ');
    var horaMin = partes[0].split(':');

    return Tarefa(
      hora: horaMin[0],
      minutos: horaMin[1],
      nome: partes[1].split(': ')[1],
      musica: partes[2].split(': ')[1],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Agenda inteligente';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _textEditingController = TextEditingController();
  final List<int> numeros = List.generate(24, (index) => index);

  // Variáveis globais movidas para o início da classe
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late Timer _tempo;
  String? selectedHour;
  String? selectedMinute;
  String musicaSelecionada = 'Música 1';
  late AssetsAudioPlayer _player = AssetsAudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _tempo = Timer.periodic(Duration(seconds: 1), (tempo) {
      setState(() {}); // Atualiza o relógio a cada segundo
      _verificarAlarmes();
    });
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          await _onSelectNotification(response.payload);
        }
      },
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _tempo.cancel();
    super.dispose();
  }

  Future<void> _onSelectNotification(String? payload) async {
    if (payload != null) {
      _player.stop();
      await flutterLocalNotificationsPlugin.cancel(0);
    }
  }

  Future<void> _showNotification(Tarefa tarefa) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      onlyAlertOnce: true,
      ongoing: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Alarme',
      'Tarefa: ${tarefa.nome}',
      platformChannelSpecifics,
      payload: 'stop_music',
    );
  }

  Future<void> _adicionarTarefa() async {
    if (selectedHour != null &&
        selectedMinute != null &&
        _textEditingController.text.isNotEmpty &&
        musicaSelecionada.isNotEmpty) {
      Tarefa novaTarefa = Tarefa(
        hora: selectedHour!,
        minutos: selectedMinute!,
        nome: _textEditingController.text,
        musica: musicaSelecionada,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? tarefasString = prefs.getStringList('tarefas');
      if (tarefasString == null) {
        tarefasString = [];
      }
      tarefasString.add(novaTarefa.toString());
      prefs.setStringList('tarefas', tarefasString);

      setState(() {
        selectedHour = null;
        selectedMinute = null;
        _textEditingController.clear();
        musicaSelecionada = 'Música 1';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarefa adicionada com sucesso!'),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erro'),
          content:
              Text('Preencha todos os campos antes de adicionar a tarefa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _tocarmusica(String musica) async {
    String? musicaPasta = musicas[musica];
    if (musicaPasta != null) {
      AssetsAudioPlayer.newPlayer().open(
        Audio(musicaPasta),
        autoStart: true,
        showNotification: true,
      );
    }
  }

  Future<void> _verificarAlarmes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? tarefasString = prefs.getStringList('tarefas');
    if (tarefasString == null) return;

    DateTime agora = DateTime.now();
    for (var tarefaString in tarefasString) {
      Tarefa tarefa = Tarefa.fromString(tarefaString);
      DateTime horaTarefa = DateTime(
        agora.year,
        agora.month,
        agora.day,
        int.parse(tarefa.hora),
        int.parse(tarefa.minutos),
      );

      if (agora.isAtSameMomentAs(horaTarefa) || agora.isAfter(horaTarefa)) {
        _tocarmusica(tarefa.musica);
        _showNotification(tarefa);
        tarefasString.remove(tarefaString);
        prefs.setStringList('tarefas', tarefasString);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1f1e1e),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(124, 61, 191, 1),
        title: const Text(
          'AGENDA INTELIGENTE',
          style: TextStyle(
              color: Colors.white,
              fontFamily: "ds-digital",
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListaAgenda()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 300, // Ajuste a largura conforme necessário
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontFamily: "ds-digital",
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Hora',
                                  labelStyle:
                                      TextStyle(color: Color(0xffffffff)),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xff9e9e9e),
                                      width: 4,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 5,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                items: List.generate(24, (index) => index)
                                    .map((int value) {
                                  String formattedValue =
                                      value.toString().padLeft(2, '0');
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      formattedValue,
                                      style:
                                          TextStyle(color: Color(0xffffffff)),
                                    ),
                                  );
                                }).toList(),
                                dropdownColor: Color(0xff1f1e1e),
                                onChanged: (int? formattedValue) {
                                  setState(() {
                                    selectedHour = formattedValue.toString();
                                  });
                                },
                                value: selectedHour != null
                                    ? int.parse(selectedHour!)
                                    : null,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Minutos',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xff9e9e9e),
                                      width: 4,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 5,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                items: List.generate(60, (index) => index)
                                    .map((int value) {
                                  String formattedValue =
                                      value.toString().padLeft(2, '0');
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      formattedValue,
                                      style:
                                          TextStyle(color: Color(0xffffffff)),
                                    ),
                                  );
                                }).toList(),
                                dropdownColor: Color(0xff1f1e1e),
                                onChanged: (int? formattedValue) {
                                  setState(() {
                                    selectedMinute = formattedValue.toString();
                                  });
                                },
                                value: selectedMinute != null
                                    ? int.parse(selectedMinute!)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _textEditingController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Digite o nome da tarefa',
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff9e9e9e),
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: musicaSelecionada,
                          items: musicas.keys.map((String musica) {
                            return DropdownMenuItem<String>(
                              value: musica,
                              child: Text(
                                musica,
                                style: TextStyle(color: Color(0xffffffff)),
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: 'Selecione a música',
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xff9e9e9e),
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          dropdownColor: Color(0xff1f1e1e),
                          onChanged: (String? musicaSelecionadaNovo) {
                            setState(() {
                              musicaSelecionada = musicaSelecionadaNovo!;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 75),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                _adicionarTarefa();
                              },

                              // Chama a função para adicionar tarefa
                              style: ElevatedButton.styleFrom(
                                  primary:
                                      const Color.fromRGBO(124, 61, 191, 1),
                                  minimumSize: const Size(150, 40),
                                  maximumSize: const Size(380, 70),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 10)),
                              child: const Text(
                                'ADICIONAR TAREFA',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: "ds-digital",
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

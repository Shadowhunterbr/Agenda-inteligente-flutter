import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListaAgenda extends StatefulWidget {
  const ListaAgenda({Key? key}) : super(key: key);

  @override
  _ListaAgendaState createState() => _ListaAgendaState();
}

class _ListaAgendaState extends State<ListaAgenda> {
  late List<String> tarefas;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? tarefasString = prefs.getStringList('tarefas');
    if (tarefasString == null) {
      tarefasString = [];
    }
    setState(() {
      tarefas = tarefasString ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff000000),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(124, 61, 191, 1),
        title: const Text(
          'Lista de tarefas',
          style: TextStyle(
              color: Colors.white,
              fontFamily: "ds-digital",
              fontWeight: FontWeight.bold),
        ),
      ),
      body: tarefas.isEmpty
          ? Center(
              child: Text(
                'Nenhuma tarefa adicionada',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: tarefas.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(tarefas[index]),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    String tarefaRemovida = tarefas[index];
                    setState(() {
                      tarefas.removeAt(index);
                      _atualizarTarefas();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tarefa removida'),
                        action: SnackBarAction(
                          label: 'Desfazer',
                          onPressed: () {
                            setState(() {
                              tarefas.insert(index, tarefaRemovida);
                              _atualizarTarefas();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: const Color(0xff333333),
                    child: ListTile(
                      title: Text(
                        tarefas[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _atualizarTarefas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tarefas', tarefas);
  }
}

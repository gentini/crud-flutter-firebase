import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  static String tag = '/home';

  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    CollectionReference tarefas =
        FirebaseFirestore.instance.collection('todos');

    return Scaffold(
      appBar: AppBar(
        title: Text('App Tarefas'),
      ),
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<QuerySnapshot>(
        stream: tarefas.orderBy('data', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data.docs.length == 0) {
            return Center(child: Text('Nenhum registro no banco de dados'));
          }

          return new ListView(
            children: snapshot.data.docs.map((DocumentSnapshot document) {
              return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: ListTile(
                      title: new Text(document.data()['titulo']),
                      subtitle: new Text(document.data()['descricao']),
                      //isThreeLine: true,
                      onTap: () {
                        tituloController.text = document['titulo'];
                        descricaoController.text = document['descricao'];

                        final form = GlobalKey<FormState>();

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Editar a Tarefa'),
                              content: Form(
                                key: form,
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height / 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text('Título'),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          //hintText: document['titulo'],
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        controller: tituloController,
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'Este campo não pode ser vazio';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 18),
                                      Text('Descrição'),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          //hintText: document['descricao'],
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        controller: descricaoController,
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'Este campo não pode ser vazio';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Map<String, dynamic> atualizaTarefa =
                                        new Map<String, dynamic>();
                                    atualizaTarefa["titulo"] =
                                        tituloController.text;
                                    atualizaTarefa["descricao"] =
                                        descricaoController.text;

                                    FirebaseFirestore.instance
                                        .collection("todos")
                                        .doc(document.id)
                                        .update(atualizaTarefa)
                                        .whenComplete(
                                            () => Navigator.of(context).pop());
                                  },

                                  //color: Colors.orange,
                                  child: Text('Salvar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      leading: IconButton(
                        icon: Icon(
                          document.data()['feito']
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 32,
                        ),
                        onPressed: () => document.reference.update({
                          'feito': !document.data()['feito'],
                        }),
                      ),
                      trailing: CircleAvatar(
                          backgroundColor: Colors.red[300],
                          foregroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => document.reference.delete(),
                          ))));
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => modalCreate(context),
        tooltip: 'Adicionar novo',
        child: Icon(Icons.add),
      ),
    );
  }

  // Cria a Tarefa - Adiciona uma Tarefa nova
  modalCreate(BuildContext context) {
    var form = GlobalKey<FormState>();

    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Criar nova Tarefa'),
          content: Form(
            key: form,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Título'),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Insira a Tarefa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: tituloController,
                    validator: (value) {
                      return value.isNotEmpty
                          ? null
                          : 'Este campo não pode ser vazio';
                    },
                  ),
                  SizedBox(height: 18),
                  Text('Descrição'),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Insira a Descrição da Tarefa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: descricaoController,
                    validator: (value) {
                      return value.isNotEmpty
                          ? null
                          : 'Este campo não pode ser vazio';
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (form.currentState.validate()) {
                  await FirebaseFirestore.instance.collection("todos").add({
                    'titulo': tituloController.text,
                    'descricao': descricaoController.text,
                    'feito': false,
                    'data': Timestamp.now(),
                  });

                  Navigator.of(context).pop();
                }
              },
              //color: Colors.orange,
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

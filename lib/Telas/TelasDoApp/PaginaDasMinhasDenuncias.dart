import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth
import 'CriarReportScreen.dart'; // Para o botão de adicionar

class paginaDasMinhasDenuncias extends StatefulWidget {
  const paginaDasMinhasDenuncias({super.key});

  @override
  State<paginaDasMinhasDenuncias> createState() => _paginaDasMinhasDenunciasState();
}

class _paginaDasMinhasDenunciasState extends State<paginaDasMinhasDenuncias> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper para obter cor e ícone com base no status (igual ao de paginaDasDenuncias)
  Widget _buildStatusChip(String status) {
    Color chipColor = Colors.grey;
    IconData chipIcon = Icons.help_outline;
    String statusText = status;

    switch (status.toLowerCase()) {
      case 'pendente':
        chipColor = Colors.orange.shade700;
        chipIcon = Icons.hourglass_empty;
        statusText = 'Pendente';
        break;
      case 'resolvido':
      case 'concluído': // Add variations if needed
        chipColor = Colors.green.shade700;
        chipIcon = Icons.check_circle_outline;
        statusText = 'Resolvido'; // Standardize display text
        break;
      case 'rejeitado':
      case 'inválido':
        chipColor = Colors.red.shade700;
        chipIcon = Icons.cancel_outlined;
         statusText = 'Rejeitado';
        break;
      // Add more cases as needed
      default:
        chipColor = Colors.grey.shade600;
        chipIcon = Icons.info_outline;
    }

    return Chip(
      avatar: Icon(chipIcon, color: Colors.white, size: 16),
      label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }


  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color.fromRGBO(255, 253, 208, 1),
        body: Center(
          child: Text('Faça login para ver as suas denúncias.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 253, 208, 1),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: currentUser.uid) // Filtra pelo userId
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Ainda não criou nenhuma denúncia.'));
          }

          final minhasDenuncias = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: minhasDenuncias.length,
            itemBuilder: (context, index) {
              final denuncia = minhasDenuncias[index];
              final dados = denuncia.data() as Map<String, dynamic>;

              final String imagemUrl = dados['imagemURL'] ?? '';
              final String descricao = dados['descricao'] ?? 'Sem descrição';
              final Timestamp timestamp = dados['data'] ?? Timestamp.now();
              final String dataFormatada = timestamp.toDate().toString().substring(0, 16); // Formato AAAA-MM-DD HH:MM
              final String status = dados['status'] ?? 'Desconhecido'; // Obter status
              // final String userId = dados['userId'] ?? ''; // userId está aqui, mas não precisamos exibir o nome nesta tela

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Usar o mesmo Status Chip da outra página
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           _buildStatusChip(status), // Exibir o status com o novo estilo
                           Text(
                            dataFormatada,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (imagemUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imagemUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 180,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image, color: Colors.grey[600], size: 50),
                              );
                            },
                          ),
                        ),
                      if (imagemUrl.isNotEmpty) const SizedBox(height: 12),
                      Text(
                        descricao,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Não precisamos exibir 'Por: nome' aqui, pois são as denúncias do próprio utilizador
                      // const SizedBox(height: 8),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Container(...), // Status antigo removido
                      //     Text(...), // Data antiga removida
                      //   ],
                      // ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CriarReportScreen()),
          );
        },
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


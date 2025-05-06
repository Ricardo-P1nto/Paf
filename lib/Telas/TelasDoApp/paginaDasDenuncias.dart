import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Widget para buscar e exibir dados do utilizador dinamicamente
class UserInfoWidget extends StatelessWidget {
  final String userId;

  const UserInfoWidget({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Busca os dados do utilizador na coleção 'utilizadores'
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('utilizadores').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostra um indicador de carregamento enquanto busca os dados
          return Text('A carregar...', style: TextStyle(fontSize: 12, color: Colors.grey[600]));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          // Mostra 'Utilizador desconhecido' se houver erro ou o utilizador não for encontrado
          return Text('Utilizador desconhecido', style: TextStyle(fontSize: 12, color: Colors.grey[700]));
        }

        // Extrai os dados do utilizador do snapshot
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final nomeUsuario = userData?['nome'] ?? 'Nome não encontrado'; // Usa o nome do documento do utilizador

        // Exibe o nome do utilizador
        return Text(
          'Por: $nomeUsuario',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        );
      },
    );
  }
}

class paginaDasDenuncias extends StatelessWidget {
  const paginaDasDenuncias({super.key});

  // Helper para obter cor e ícone com base no status
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
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 253, 208, 1),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar denúncias: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma denúncia encontrada.'));
          }

          final denuncias = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: denuncias.length,
            itemBuilder: (context, index) {
              final denuncia = denuncias[index];
              final dados = denuncia.data() as Map<String, dynamic>;

              final String imagemUrl = dados['imagemURL'] ?? '';
              final String descricao = dados['descricao'] ?? 'Sem descrição';
              final Timestamp timestamp = dados['data'] ?? Timestamp.now();
              final String dataFormatada = timestamp.toDate().toString().substring(0, 16); // Formato AAAA-MM-DD HH:MM
              final String userId = dados['userId'] ?? ''; // Obter o userId da denúncia
              final String status = dados['status'] ?? 'Desconhecido'; // Obter o status da denúncia

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
                      // Adicionar Status Chip no topo do Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           _buildStatusChip(status), // Exibir o status
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
                      const SizedBox(height: 8),
                      // Mover UserInfoWidget para baixo da descrição
                      if (userId.isNotEmpty)
                        UserInfoWidget(userId: userId)
                      else
                        Text('Por: Utilizador desconhecido', style: TextStyle(fontSize: 12, color: Colors.grey[700])), // Fallback se userId estiver vazio

                      // Data foi movida para o topo junto com o status
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     if (userId.isNotEmpty)
                      //       UserInfoWidget(userId: userId)
                      //     else
                      //       Text('Por: Utilizador desconhecido', style: TextStyle(fontSize: 12, color: Colors.grey[700])), 
                      //     Text(
                      //       dataFormatada,
                      //       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      //     ),
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
    );
  }
}


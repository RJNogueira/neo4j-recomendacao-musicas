// =====================================================================
// 08_caminhos.cypher  |  PASSO 8: caminhos entre nos
// =====================================================================
// POR QUE? Em grafos, a PROPRIA ligacao e informacao. Um caminho explica
// como duas coisas se relacionam ("por que essas musicas sao parecidas?").

// 8.1 Menor caminho entre duas musicas (atraves de usuarios, artistas e generos)
MATCH (a:Musica {id:'M001'}), (b:Musica {id:'M050'})
MATCH p = shortestPath((a)-[:OUVIU|PERTENCE_AO|INTERPRETADA_POR*..6]-(b))
RETURN p;

// 8.2 Menor caminho na rede social (grau de separacao entre dois usuarios)
MATCH (a:Usuario {id:'U001'}), (b:Usuario {id:'U040'})
MATCH p = shortestPath((a)-[:SEGUE*..8]-(b))
RETURN p, length(p) AS graus_de_separacao;

// 8.3 Quem sao os usuarios mais "populares" (mais seguidos)?
MATCH (:Usuario)-[:SEGUE]->(u:Usuario)
RETURN u.nome AS usuario, count(*) AS seguidores
ORDER BY seguidores DESC LIMIT 10;

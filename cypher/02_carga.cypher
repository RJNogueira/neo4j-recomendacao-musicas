// =====================================================================
// 02_carga.cypher  |  PASSO 2: carregar os CSVs no grafo
// =====================================================================
// ANTES DE RODAR:
//  - Copie os arquivos da pasta data/ para a pasta "import" do seu Neo4j
//    (Neo4j Desktop: ... > Open folder > Import | Docker: volume /var/lib/neo4j/import).
//  - Usando Neo4j Aura (nuvem)? Troque 'file:///musicas.csv' pelo link RAW do GitHub, ex.:
//    'https://raw.githubusercontent.com/RJNogueira/neo4j-recomendacao-musicas/main/data/musicas.csv'
//
// REGRA DE OURO: use MERGE (e nao CREATE) para nos. MERGE = "ache ou crie".
// Assim, rodar o script duas vezes nao gera duplicatas.
// LOAD CSV le tudo como TEXTO, por isso usamos toInteger()/toFloat().

// ---- 2.1 Musicas + Artistas + Generos (um CSV cria 3 tipos de no) ----
LOAD CSV WITH HEADERS FROM 'file:///musicas.csv' AS row
MERGE (m:Musica {id: row.id})
  SET m.titulo = row.titulo, m.ano = toInteger(row.ano)
MERGE (a:Artista {id: row.artista_id})
  SET a.nome = row.artista_nome
MERGE (g:Genero {nome: row.genero})
MERGE (m)-[:INTERPRETADA_POR]->(a)
MERGE (m)-[:PERTENCE_AO]->(g);

// ---- 2.2 Usuarios ----
LOAD CSV WITH HEADERS FROM 'file:///usuarios.csv' AS row
MERGE (u:Usuario {id: row.id})
  SET u.nome = row.nome, u.pais = row.pais;

// ---- 2.3 Relacao OUVIU (o "coracao" da recomendacao) ----
// Aqui precisamos de MATCH: os nos Usuario e Musica JA existem, so ligamos.
// Por isso a ordem importa: nos primeiro, relacionamentos depois.
LOAD CSV WITH HEADERS FROM 'file:///ouviu.csv' AS row
MATCH (u:Usuario {id: row.usuario_id})
MATCH (m:Musica  {id: row.musica_id})
MERGE (u)-[r:OUVIU]->(m)
  SET r.nota = toInteger(row.nota), r.vezes = toInteger(row.vezes);

// ---- 2.4 Relacao SEGUE (rede social entre usuarios) ----
LOAD CSV WITH HEADERS FROM 'file:///segue.csv' AS row
MATCH (a:Usuario {id: row.origem_id})
MATCH (b:Usuario {id: row.destino_id})
MERGE (a)-[:SEGUE]->(b);

// ---- 2.5 Relacao RECOMENDA (recomendacoes ja calculadas em Python) ----
LOAD CSV WITH HEADERS FROM 'file:///recomenda.csv' AS row
MATCH (u:Usuario {id: row.usuario_id})
MATCH (m:Musica  {id: row.musica_id})
MERGE (u)-[r:RECOMENDA]->(m)
  SET r.score = toFloat(row.score), r.metodo = row.metodo,
      r.usuarios_similares = toInteger(row.usuarios_similares);

// ---- 2.6 CONFERENCIA: os numeros devem bater com o esperado ----
// Esperado: Usuario 40 | Musica 100 | Artista 20 | Genero 5
MATCH (n) RETURN labels(n)[0] AS tipo, count(*) AS total ORDER BY tipo;
// Esperado: OUVIU 510 | SEGUE 134 | RECOMENDA 200 | INTERPRETADA_POR 100 | PERTENCE_AO 100
MATCH ()-[r]->() RETURN type(r) AS relacao, count(*) AS total ORDER BY relacao;

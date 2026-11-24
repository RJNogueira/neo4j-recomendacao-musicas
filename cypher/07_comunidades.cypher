// =====================================================================
// 07_comunidades.cypher  |  PASSO 7: "tribos musicais" (Louvain)
// =====================================================================
// O QUE E? O Louvain encontra grupos de nos mais conectados entre si do
// que com o resto. Aqui: grupos de usuarios (e musicas) com o mesmo gosto.
// Como nosso dataset tem 5 generos favoritos, esperamos ~5 comunidades.

CALL gds.graph.drop('escutas', false);
CALL gds.graph.project('escutas', ['Usuario','Musica'],
  {OUVIU: {orientation: 'UNDIRECTED'}});

// POR QUE 'write'? Grava o numero da comunidade como propriedade
// ('comunidade') em cada no, para podermos filtrar e colorir no Bloom.
CALL gds.louvain.write('escutas', {writeProperty: 'comunidade'})
YIELD communityCount, modularity;

// Quantos usuarios em cada comunidade?
MATCH (u:Usuario)
RETURN u.comunidade AS comunidade, count(*) AS usuarios ORDER BY comunidade;

// Qual genero domina cada comunidade? (validacao: deve bater com o gosto)
MATCH (u:Usuario)-[:OUVIU]->(:Musica)-[:PERTENCE_AO]->(g:Genero)
WITH u.comunidade AS comunidade, g.nome AS genero, count(*) AS escutas
ORDER BY comunidade, escutas DESC
RETURN comunidade, collect(genero)[0] AS genero_dominante;

// Recomendar o que e popular na "tribo" do usuario
MATCH (u:Usuario {id: 'U001'})
MATCH (outro:Usuario {comunidade: u.comunidade})-[:OUVIU]->(rec:Musica)
WHERE NOT (u)-[:OUVIU]->(rec)
RETURN rec.titulo AS musica, count(DISTINCT outro) AS popularidade_na_tribo
ORDER BY popularidade_na_tribo DESC LIMIT 10;

// DICA DE PRINT: no Neo4j Bloom, crie uma "regra de estilo" que colore
// os nos Usuario pela propriedade 'comunidade'. E a imagem mais bonita do projeto.

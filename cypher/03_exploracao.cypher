// =====================================================================
// 03_exploracao.cypher  |  PASSO 3: conhecer o grafo (queries basicas)
// =====================================================================
// POR QUE? Antes de recomendar qualquer coisa, e bom "passear" pelo grafo
// para confirmar que a carga fez sentido. Tire PRINTS destas visualizacoes.

// Como o modelo ficou no banco? (print para o README)
CALL db.schema.visualization();

// O "mapa" de um usuario: o que ele ouviu e de qual genero (print!)
MATCH p = (:Usuario {id:'U001'})-[:OUVIU]->(:Musica)-[:PERTENCE_AO]->(:Genero)
RETURN p LIMIT 25;

// Musicas mais ouvidas da base (soma das "vezes")
MATCH (:Usuario)-[o:OUVIU]->(m:Musica)
RETURN m.titulo AS musica, sum(o.vezes) AS total_de_plays
ORDER BY total_de_plays DESC LIMIT 10;

// Generos mais populares
MATCH (:Usuario)-[:OUVIU]->(:Musica)-[:PERTENCE_AO]->(g:Genero)
RETURN g.nome AS genero, count(*) AS escutas ORDER BY escutas DESC;

// Artistas com mais ouvintes diferentes
MATCH (u:Usuario)-[:OUVIU]->(:Musica)-[:INTERPRETADA_POR]->(a:Artista)
RETURN a.nome AS artista, count(DISTINCT u) AS ouvintes
ORDER BY ouvintes DESC LIMIT 10;

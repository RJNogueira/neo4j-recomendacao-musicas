// =====================================================================
// 04_recomendacoes.cypher  |  PASSO 4: os algoritmos de recomendacao
// =====================================================================
// ANTES: defina o usuario alvo (rode este comando sozinho no Neo4j Browser):
//   :param uid => 'U001'
// Se preferir, troque $uid por 'U001' direto nas queries.
// Todas as queries abaixo EXCLUEM musicas que o usuario ja ouviu:
//   NOT (u)-[:OUVIU]->(rec)   <- "nao recomendar o que ele ja conhece".

// ---------------------------------------------------------------------
// 4.1 COLD START (usuario novo, sem historico)
// POR QUE: sem historico nao da para comparar usuarios. Entao usamos
// popularidade: as melhores musicas do genero que o usuario escolheu.
// (defina antes:  :param genero => 'Rock')
// ---------------------------------------------------------------------
MATCH (:Genero {nome: $genero})<-[:PERTENCE_AO]-(m:Musica)<-[o:OUVIU]-()
RETURN m.titulo AS musica, count(o) AS escutas, round(avg(o.nota), 2) AS nota_media
ORDER BY escutas DESC, nota_media DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.2 ITEM A ITEM: "quem ouve esta musica tambem ouve..."
// POR QUE: e o estilo "clientes que compraram X tambem compraram Y".
// (defina antes:  :param mid => 'M001')
// ---------------------------------------------------------------------
MATCH (:Musica {id: $mid})<-[:OUVIU]-(u:Usuario)-[:OUVIU]->(rec:Musica)
WHERE rec.id <> $mid
RETURN rec.titulo AS musica, count(u) AS ouvintes_em_comum
ORDER BY ouvintes_em_comum DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.3 FILTRAGEM COLABORATIVA (a principal!)
// POR QUE: "pessoas parecidas com voce gostaram disto". Passos:
//   a) achar quem ouviu as mesmas musicas que o usuario alvo;
//   b) ficar com os 20 mais parecidos (mais musicas em comum);
//   c) olhar o que eles curtiram (nota >= 4) e voce ainda nao ouviu.
// ---------------------------------------------------------------------
MATCH (alvo:Usuario {id: $uid})-[:OUVIU]->(m:Musica)<-[:OUVIU]-(similar:Usuario)
WHERE similar <> alvo
WITH alvo, similar, count(m) AS em_comum
ORDER BY em_comum DESC LIMIT 20
MATCH (similar)-[r:OUVIU]->(rec:Musica)
WHERE r.nota >= 4 AND NOT (alvo)-[:OUVIU]->(rec)
RETURN rec.titulo AS recomendacao,
       count(DISTINCT similar) AS usuarios_similares,
       round(avg(r.nota), 2) AS nota_media
ORDER BY usuarios_similares DESC, nota_media DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.4 BASEADA EM CONTEUDO
// POR QUE: nao depende de outros usuarios. Descobrimos os 3 generos que
// o usuario mais ouve e sugerimos musicas desses generos.
// ---------------------------------------------------------------------
MATCH (u:Usuario {id: $uid})-[o:OUVIU]->(:Musica)-[:PERTENCE_AO]->(g:Genero)
WITH u, g, sum(o.vezes) AS afinidade
ORDER BY afinidade DESC LIMIT 3
MATCH (g)<-[:PERTENCE_AO]-(rec:Musica)-[:INTERPRETADA_POR]->(a:Artista)
WHERE NOT (u)-[:OUVIU]->(rec)
RETURN rec.titulo AS musica, a.nome AS artista, g.nome AS genero, afinidade
ORDER BY afinidade DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.5 HIBRIDA: amigos + genero
// POR QUE: combina o "social" (o que quem eu sigo curtiu) com o conteudo
// (genero que eu ja ouco). Pontuacao: 2 pontos por amigo + 1 se o genero
// ja faz parte do meu gosto. Facil de explicar em entrevista.
// ---------------------------------------------------------------------
MATCH (u:Usuario {id: $uid})-[:SEGUE]->(amigo:Usuario)-[r:OUVIU]->(rec:Musica)
WHERE r.nota >= 4 AND NOT (u)-[:OUVIU]->(rec)
WITH u, rec, count(DISTINCT amigo) AS amigos
OPTIONAL MATCH (rec)-[:PERTENCE_AO]->(g:Genero)<-[:PERTENCE_AO]-(:Musica)<-[:OUVIU]-(u)
WITH rec, amigos, count(DISTINCT g) AS bonus_genero
RETURN rec.titulo AS musica, amigos, bonus_genero,
       amigos * 2 + bonus_genero AS score
ORDER BY score DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.6 AMIGOS DE AMIGOS (descoberta social)
// POR QUE: mostra o poder dos grafos: 2 saltos na rede social em 1 linha.
// (Em SQL seriam varios JOINs encadeados.)
// ---------------------------------------------------------------------
MATCH (u:Usuario {id: $uid})-[:SEGUE*2]->(fof:Usuario)-[r:OUVIU]->(rec:Musica)
WHERE fof <> u AND r.nota >= 4 AND NOT (u)-[:OUVIU]->(rec)
RETURN rec.titulo AS musica, count(DISTINCT fof) AS indicacoes
ORDER BY indicacoes DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.7 DIVERSIDADE: no maximo 2 musicas por artista
// POR QUE: evita uma lista com 10 musicas da mesma banda.
// ---------------------------------------------------------------------
MATCH (alvo:Usuario {id: $uid})-[:OUVIU]->(:Musica)<-[:OUVIU]-(sim:Usuario)-[r:OUVIU]->(rec:Musica)
WHERE sim <> alvo AND r.nota >= 4 AND NOT (alvo)-[:OUVIU]->(rec)
WITH rec, count(DISTINCT sim) AS score
ORDER BY score DESC
MATCH (rec)-[:INTERPRETADA_POR]->(a:Artista)
WITH a, collect({musica: rec.titulo, score: score})[..2] AS top2
UNWIND top2 AS t
RETURN a.nome AS artista, t.musica AS musica, t.score AS score
ORDER BY score DESC LIMIT 10;

// ---------------------------------------------------------------------
// 4.8 EXPLICABILIDADE: "por que recomendaram isso?"
// POR QUE: recomendacao com motivo gera confianca. Mostra quem gostou da
// musica e quais musicas essa pessoa tem em comum com voce.
// (defina antes:  :param rec_id => 'M010')
// ---------------------------------------------------------------------
MATCH (u:Usuario {id: $uid})-[:OUVIU]->(m:Musica)<-[:OUVIU]-(viz:Usuario)-[r:OUVIU]->(:Musica {id: $rec_id})
WHERE r.nota >= 4
RETURN viz.nome AS quem_gostou, r.nota AS nota,
       collect(m.titulo)[..3] AS musicas_em_comum_com_voce
LIMIT 5;

// ---------------------------------------------------------------------
// 4.9 CONFERIR com as recomendacoes pre-calculadas (relacao RECOMENDA)
// ---------------------------------------------------------------------
MATCH (:Usuario {id: $uid})-[r:RECOMENDA]->(m:Musica)
RETURN m.titulo AS musica, r.score AS score, r.usuarios_similares AS similares
ORDER BY score DESC;

// =====================================================================
// 06_similaridade.cypher  |  PASSO 6: usuarios parecidos
// =====================================================================
// IDEIA: dois usuarios sao parecidos se ouviram muitas musicas iguais.
// Medida usada: indice de Jaccard = (musicas em comum) / (musicas de um OU do outro).
// 0 = nada em comum | 1 = gostos identicos.

// ---- 6.1 Em Cypher puro (nao precisa de GDS; bom para aprender) ----
// (defina antes:  :param uid => 'U001')
MATCH (a:Usuario {id: $uid})-[:OUVIU]->(m:Musica)<-[:OUVIU]-(b:Usuario)
WITH a, b, count(m) AS comum
MATCH (a)-[:OUVIU]->(ma:Musica)
WITH a, b, comum, count(ma) AS total_a
MATCH (b)-[:OUVIU]->(mb:Musica)
WITH a, b, comum, total_a, count(mb) AS total_b
RETURN b.nome AS usuario_parecido, comum,
       round(toFloat(comum) / (total_a + total_b - comum), 3) AS jaccard
ORDER BY jaccard DESC LIMIT 5;

// ---- 6.2 Com GDS: Node Similarity (escala para milhoes de nos) ----
CALL gds.graph.drop('sim', false);
CALL gds.graph.project('sim', ['Usuario','Musica'], 'OUVIU');

// POR QUE 'write'? Gravamos a similaridade no proprio grafo (SIMILAR_A).
// Assim a recomendacao vira uma query simples e rapida, sem recalcular.
CALL gds.nodeSimilarity.write('sim', {
  topK: 10, similarityCutoff: 0.1,
  writeRelationshipType: 'SIMILAR_A', writeProperty: 'score'
});

// ---- 6.3 Recomendar usando SIMILAR_A ----
MATCH (u:Usuario {id: 'U001'})-[s:SIMILAR_A]->(viz:Usuario)-[r:OUVIU]->(rec:Musica)
WHERE r.nota >= 4 AND NOT (u)-[:OUVIU]->(rec)
RETURN rec.titulo AS recomendacao,
       round(sum(s.score * r.nota), 3) AS relevancia
ORDER BY relevancia DESC LIMIT 10;

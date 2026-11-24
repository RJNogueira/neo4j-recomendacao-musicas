// =====================================================================
// 05_gds_pagerank.cypher  |  PASSO 5: PageRank (Graph Data Science)
// =====================================================================
// REQUISITO: plugin GDS (Neo4j Desktop com plugin "Graph Data Science",
// Neo4j Sandbox ou AuraDS). No Aura Free o GDS NAO esta disponivel.
//
// O QUE E PAGERANK? O algoritmo do Google: um no e "importante" se muitos
// nos importantes apontam para ele. Aqui: musica importante = ouvida por
// muitos usuarios que tambem sao "centrais".
//
// POR QUE "PROJETAR" O GRAFO? O GDS nao trabalha direto no banco: ele
// cria uma copia otimizada na memoria (a "projecao"). E como tirar uma
// foto do grafo so com o que importa para o calculo.

// Limpa projecao antiga (o 'false' evita erro se nao existir)
CALL gds.graph.drop('escutas', false);

// UNDIRECTED: a importancia pode "andar" nos dois sentidos (usuario<->musica)
CALL gds.graph.project('escutas', ['Usuario','Musica'],
  {OUVIU: {orientation: 'UNDIRECTED'}});

// 5.1 PageRank global: as musicas mais "centrais" da base
CALL gds.pageRank.stream('escutas')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score
WHERE n:Musica
RETURN n.titulo AS musica, round(score, 4) AS pagerank
ORDER BY pagerank DESC LIMIT 10;

// 5.2 PageRank PERSONALIZADO (a recomendacao!)
// POR QUE: com sourceNodes, o "passeio aleatorio" sempre recomeca no
// usuario alvo. Resultado: musicas proximas DELE no grafo ganham mais nota.
MATCH (u:Usuario {id: 'U001'})
CALL gds.pageRank.stream('escutas', {sourceNodes: [u], maxIterations: 20})
YIELD nodeId, score
WITH u, gds.util.asNode(nodeId) AS n, score
WHERE n:Musica AND NOT (u)-[:OUVIU]->(n)
RETURN n.titulo AS recomendacao, round(score, 4) AS score
ORDER BY score DESC LIMIT 10;

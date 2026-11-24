// =====================================================================
// 01_constraints.cypher  |  PASSO 1: regras de unicidade (constraints)
// =====================================================================
// POR QUE FAZER ISSO PRIMEIRO?
// Uma constraint de unicidade diz ao Neo4j: "nao pode existir dois
// usuarios com o mesmo id". Ela faz duas coisas boas ao mesmo tempo:
//   1) evita duplicatas (se rodar a carga duas vezes, nao duplica);
//   2) cria um indice, que deixa o MATCH por id MUITO mais rapido.
// Sem isso, a carga com muitos dados fica lenta.
// O "IF NOT EXISTS" permite rodar o script de novo sem dar erro.

CREATE CONSTRAINT usuario_id  IF NOT EXISTS FOR (u:Usuario) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT musica_id   IF NOT EXISTS FOR (m:Musica)  REQUIRE m.id IS UNIQUE;
CREATE CONSTRAINT artista_id  IF NOT EXISTS FOR (a:Artista) REQUIRE a.id IS UNIQUE;
CREATE CONSTRAINT genero_nome IF NOT EXISTS FOR (g:Genero)  REQUIRE g.nome IS UNIQUE;

// Conferir se foram criadas:
SHOW CONSTRAINTS;

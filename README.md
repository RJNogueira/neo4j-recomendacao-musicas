# Recomendação de Músicas com Grafos (Neo4j Aura)

Projeto prático de **banco de dados em grafos** que recomenda músicas usando **Neo4j Aura Free**, **Data Importer**, **Cypher** e **Neo4j Explore**. Os dados são fictícios e foram gerados para formar "tribos musicais" fáceis de visualizar.

> Desafio de projeto da DIO — Banco de Dados em Grafos com Neo4j. Autor: **Rodrigo Nogueira** · [GitHub](https://github.com/RJNogueira) · Repositório: https://github.com/RJNogueira/neo4j-recomendacao-musicas

Tribos musicais no Neo4j Explore

*Cada cor é o gênero favorito de um grupo de usuários. As bolinhas cinzas são as músicas que ligam as tribos.*

---

## 1. O problema

Plataformas como Spotify e YouTube Music precisam responder: **"que música este usuário vai gostar?"** A resposta está nas **conexões**: quem ouviu o quê, quem é parecido com quem, quem segue quem e a que gênero cada música pertence.

## 2. Por que grafos?

Recomendar é "seguir os fios" de um mural:

> *Eu → músicas que ouvi → outras pessoas que ouviram as mesmas → músicas que elas curtiram e eu ainda não ouvi.*

| Banco relacional (SQL) | Grafo (Neo4j) |
| --- | --- |
| Vários `JOIN` encadeados, difíceis de ler | Um padrão de caminho legível: `(u)-[:OUVIU]->(m)<-[:OUVIU]-(outro)` |
| Nova relação exige novas tabelas | Basta criar um novo tipo de relacionamento |
| "Amigos de amigos" vira uma query complexa | `[:SEGUE*2]` resolve em uma linha |

## 3. Modelo do grafo

Desenhado antes no [Arrows.app](https://arrows.app).

Modelo do grafo

**Nós**

| Label | Propriedades | Representa |
| --- | --- | --- |
| `Usuario` | id, nome, pais, genero\_favorito\* | Quem ouve música |
| `Musica` | id, titulo, ano | Uma faixa |
| `Artista` | id, nome | Quem interpreta |
| `Genero` | nome | Estilo musical |

\* `genero_favorito` é calculada por query (seção 6) e funciona como "tribo".

**Relacionamentos**

| Relação | Direção | Propriedades | Significado |
| --- | --- | --- | --- |
| `OUVIU` | Usuario → Musica | nota (1-5), vezes | Histórico de escuta (base da recomendação) |
| `SEGUE` | Usuario → Usuario | — | Rede social |
| `RECOMENDA` | Usuario → Musica | score, metodo, usuarios\_similares | Recomendação pré-calculada |
| `INTERPRETADA_POR` | Musica → Artista | — | Autoria |
| `PERTENCE_AO` | Musica → Genero | — | Classificação |

**Por que este desenho?** Artista e Gênero são **nós** (e não só texto dentro da música) para podermos navegar por eles: "outras músicas deste artista", "ouvintes deste gênero". Como propriedade, essa navegação seria limitada.

## 4. Dataset

Dados **fictícios** em [`data/`](data/), gerados por [`scripts/gerar_dataset.py`](scripts/gerar_dataset.py) (seed fixa, reproduzível).

| Arquivo | Linhas | Vira no grafo |
| --- | --- | --- |
| `usuarios.csv` | 40 | nós `Usuario` |
| `artistas.csv` | 20 | nós `Artista` |
| `musicas.csv` | 100 | nós `Musica` + relações `INTERPRETADA_POR` e `PERTENCE_AO` (e os 5 nós `Genero`) |
| `ouviu.csv` | 510 | relações `OUVIU` |
| `segue.csv` | 134 | relações `SEGUE` |
| `recomenda.csv` | 200 | relações `RECOMENDA` |

Total: **165 nós e 1.044 relacionamentos**. Cada usuário tem um gênero favorito, o que forma 5 tribos de gosto.

## 5. Como foi feita a importação (Neo4j Aura Free + Data Importer)

1. Criei uma instância **AuraDB Free** no [Aura Console](https://console.neo4j.io) e guardei as credenciais (a senha aparece uma única vez).
2. No menu **Import** abri o **Data Importer**, carreguei os 6 CSVs do computador e escolhi **Define manually**.
3. Criei os **4 nós** (label, arquivo, colunas e ID) e as **5 relações** (tipo, arquivo, coluna de origem e de destino), como na tabela abaixo.
4. Usei **Preview** para conferir o grafo e **Run import** para carregar.
5. Conferi as contagens no **Query** (seção 6.1).

| Nó ou relação | Arquivo | ID, ou origem → destino (coluna) | Propriedades |
| --- | --- | --- | --- |
| `Usuario` | usuarios.csv | ID: `id` | nome, pais |
| `Musica` | musicas.csv | ID: `id` | titulo, ano (integer) |
| `Artista` | artistas.csv | ID: `id` | nome |
| `Genero` | musicas.csv | ID: `nome` (coluna `genero`) | nome |
| `OUVIU` | ouviu.csv | Usuario (`usuario_id`) → Musica (`musica_id`) | nota, vezes (integer) |
| `SEGUE` | segue.csv | Usuario (`origem_id`) → Usuario (`destino_id`) | — |
| `RECOMENDA` | recomenda.csv | Usuario (`usuario_id`) → Musica (`musica_id`) | score (float), metodo, usuarios\_similares (integer) |
| `INTERPRETADA_POR` | musicas.csv | Musica (`id`) → Artista (`artista_id`) | — |
| `PERTENCE_AO` | musicas.csv | Musica (`id`) → Genero (`genero`) | — |

Modelo no Data Importer

## 6. Conferência e perguntas de negócio

### 6.1 Os números batem?

```
MATCH (n) RETURN labels(n)[0] AS tipo, count(*) AS total ORDER BY tipo;
MATCH ()-[r]->() RETURN type(r) AS relacao, count(*) AS total ORDER BY relacao;
```

Esperado: Artista 20, Genero 5, Musica 100, Usuario 40 · INTERPRETADA\_POR 100, OUVIU 510, PERTENCE\_AO 100, RECOMENDA 200, SEGUE 134.

Contagens

### 6.2 Perguntas que o grafo responde

| # | Pergunta | Evidência |
| --- | --- | --- |
| 1 | Como ficou o modelo no banco? |  |
| 2 | O que um usuário ouviu e de que gêneros? |  |
| 3 | Que "tribos musicais" existem? |  |
| 4 | O que recomendar por gostos parecidos? |  |
| 5 | **Por que** recomendamos esta música? |  |
| 6 | Quem tem gosto mais parecido com o meu? |  |
| 7 | O que meus amigos estão curtindo? |  |
| 8 | Como duas músicas se conectam? |  |

### 6.3 As queries principais

**Tribos musicais**: descobre o gênero favorito de cada usuário e grava na propriedade `genero_favorito`.

```
MATCH (u:Usuario)-[o:OUVIU]->(:Musica)-[:PERTENCE_AO]->(g:Genero)
WITH u, g, sum(o.vezes) AS plays
ORDER BY u.id, plays DESC
WITH u, collect(g.nome)[0] AS favorito
SET u.genero_favorito = favorito
RETURN favorito AS tribo, count(*) AS usuarios
ORDER BY usuarios DESC;
```

**Filtragem colaborativa**: "pessoas parecidas com você gostaram disto". Acha os 20 usuários com mais músicas em comum e sugere o que eles curtiram (nota ≥ 4) e você ainda não ouviu.

```
WITH 'U001' AS uid
MATCH (alvo:Usuario {id: uid})-[:OUVIU]->(m:Musica)<-[:OUVIU]-(similar:Usuario)
WHERE similar <> alvo
WITH alvo, similar, count(m) AS em_comum
ORDER BY em_comum DESC LIMIT 20
MATCH (similar)-[r:OUVIU]->(rec:Musica)
WHERE r.nota >= 4 AND NOT (alvo)-[:OUVIU]->(rec)
RETURN rec.titulo AS recomendacao,
       count(DISTINCT similar) AS usuarios_similares,
       round(avg(r.nota), 2) AS nota_media
ORDER BY usuarios_similares DESC, nota_media DESC LIMIT 10;
```

**Explicabilidade**: devolve um *grafo* que mostra o usuário, as músicas em comum, o vizinho de gosto e a música recomendada.

```
WITH 'U001' AS uid
MATCH (alvo:Usuario {id: uid})-[:RECOMENDA]->(rec:Musica)
      <-[r:OUVIU]-(viz:Usuario)-[:OUVIU]->(m:Musica)<-[:OUVIU]-(alvo)
WHERE r.nota >= 4
RETURN alvo, rec, viz, m LIMIT 40;
```

**Híbrida (amigos + gênero)**: 2 pontos por amigo que curtiu, mais 1 ponto se o gênero já faz parte do gosto do usuário.

```
WITH 'U001' AS uid
MATCH (u:Usuario {id: uid})-[:SEGUE]->(amigo:Usuario)-[r:OUVIU]->(rec:Musica)
WHERE r.nota >= 4 AND NOT (u)-[:OUVIU]->(rec)
WITH u, rec, count(DISTINCT amigo) AS amigos
OPTIONAL MATCH (rec)-[:PERTENCE_AO]->(g:Genero)<-[:PERTENCE_AO]-(:Musica)<-[:OUVIU]-(u)
WITH rec, amigos, count(DISTINCT g) AS bonus_genero
RETURN rec.titulo AS musica, amigos, bonus_genero, amigos * 2 + bonus_genero AS score
ORDER BY score DESC LIMIT 10;
```

Todas as queries (similaridade de Jaccard, caminho entre músicas, etc.).

## 7. Visualização no Neo4j Explore

No **Explore**, usei a regra de estilo **Unique values** na categoria `Usuario`, pela propriedade `genero_favorito`: cada gênero ganhou uma cor. A categoria `Musica` ficou em cinza para não esconder as tribos.

| Usuários e músicas | Só a rede social (`Usuario - SEGUE - Usuario`) |
| --- | --- |
|  |  |

## 8. Troubleshooting (problemas reais que enfrentei)

| Problema | Causa | Solução |
| --- | --- | --- |
| Não consegui marcar *Unique* na constraint do nó | O ID escolhido no Importer já cria uma constraint **Key**, que inclui unicidade e obrigatoriedade | Deixar como está: Key já cobre as duas regras |
| Propriedade `Nome` com N maiúsculo em `Genero` | O Importer sugeriu o nome em maiúscula, e as queries usam `g.nome` (o Neo4j diferencia maiúsculas) | Renomear para `nome` no painel de propriedades |
| Labels como `Usuarios`, `Musicas`, `Artistas` | O Importer sugeriu o nome do arquivo (plural) | Corrigir para o singular: `Usuario`, `Musica`, `Artista` |
| `Usuario` só tinha a propriedade `id` | O mapeamento trouxe uma coluna só | Usar **Map from table** de novo, ou adicionar `nome` e `pais` com o botão + |
| Seta `INTERPRETADA_POR` virou um laço na própria `Musica` | Soltei o arrasto na bolinha de origem, e o destino ficou igual à origem (From: Musica, To: Musica) | Apagar e refazer, soltando dentro do `Artista`. Conferir **From** e **To** antes de mapear |
| Aviso *Must be specified* nas propriedades da seta `OUVIU` | `nota` e `vezes` estavam sem coluna escolhida | Selecionar a coluna correspondente em cada propriedade |
| Preview do Importer mostrava os usuários soltos | O preview usa só uma amostra das linhas | Conferir o canvas completo e as contagens depois do import |
| No Explore só aparecia 4 das 5 cores de tribo | O laranja padrão de `Musica` era parecido com a cor de uma tribo e escondia os usuários dela | Mudar a cor de `Musica` para um cinza neutro |
| `genero_favorito` não aparecia no Explore | A Perspective foi gerada antes da query das tribos | Rodar a query das tribos e **atualizar a Perspective** |
| PageRank e Louvain não rodam | O plano **Aura Free não tem GDS** (Graph Data Science) | Usei Cypher puro: Jaccard e a propriedade `genero_favorito` como "tribo". |

## 9. Aprendizados

- Desenhar o modelo no **Arrows.app antes** de importar evitou retrabalho: o desenho virou o roteiro do Importer.
- **Ordem importa**: nós primeiro, relacionamentos depois.
- Conferir **contagens** logo após o import mostra erros de mapeamento antes das queries.
- **Maiúsculas e minúsculas** importam no Neo4j (labels, tipos e propriedades).
- Um resultado em formato de **grafo** (explicabilidade) comunica melhor do que uma tabela.
- Visualização com **cores por propriedade** transforma números em algo que qualquer pessoa entende.

## 10. Próximos passos

- Peso por **recência** (propriedade `data` em `OUVIU`).
- Dataset real (Last.fm, Million Song Dataset).
- **GDS** em Neo4j Desktop ou AuraDS: PageRank personalizado, Node Similarity, Louvain (scripts prontos em `cypher/`).
- Embeddings de nós (FastRP) + kNN.
- API de recomendação em Python com o driver oficial do Neo4j.

## 11. Estrutura do repositório

```
neo4j-recomendacao-musicas/
├── README.md
├── data/                          # CSVs de exemplo (dados fictícios)
├── cypher/
│   ├── aura/
│   │   ├── criar_grafo_completo.cypher   # criar nós e relações (copiar e colar)
│   │   └── aura_passo_a_passo.cypher     # LOAD CSV + queries de recomendação
│   └── 01_... a 08_...            # versão Neo4j Desktop (inclui GDS)
├── docs/
│   ├── modelo-arrows.json         # esboço para importar no Arrows.app
│   ├── modelo-grafo.png           # imagem do modelo
│   ├── guia-arrows-app.pdf
│   ├── guia-neo4j-aura.pdf
│   ├── guia-importar-neo4j-leigo.pdf
│   └── prints/                    # evidências (Query, Importer e Explore)
└── scripts/gerar_dataset.py       # gera os CSVs (seed fixa)
```

## 📚 Referências

- [Neo4j Aura](https://neo4j.com/docs/aura/) · [Data Importer](https://neo4j.com/docs/data-importer/) · [Cypher](https://neo4j.com/docs/cypher-manual/current/) · [Explore](https://neo4j.com/docs/aura/explore/)
- [Arrows.app](https://arrows.app) · [neo4j-graph-examples](https://github.com/neo4j-graph-examples)

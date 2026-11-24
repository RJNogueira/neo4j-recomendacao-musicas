import csv, random, itertools
from collections import defaultdict
random.seed(42)

generos = {
 "Rock": ["Pedra Viva","Eco do Asfalto","Trovão Azul","Ferrugem Sonora"],
 "MPB": ["Maré Mansa","Luz de Cajueiro","Violão de Maio","Rio Sereno"],
 "Sertanejo": ["Poeira Dourada","Estrada Real","Moda da Porteira","Cavalo Branco"],
 "Eletronica": ["Pixel Noturno","Circuito Aberto","Neon Delta","Batida Zero"],
 "Jazz": ["Quarteto Cobalto","Noites de Veludo","Sax e Chuva","Trio Meridiano"],
}
palavras = ["Horizonte","Saudade","Faísca","Madrugada","Ponte","Cinza","Verão","Espelho","Vento","Janela"]
sufixos = ["Vermelho","Distante","Infinito","de Ontem","Sem Fim"]

artistas, musicas = [], []
aid = mid = 0
for g, nomes in generos.items():
    for nome in nomes:
        aid += 1
        artistas.append([f"A{aid:03d}", nome, g])
        for k in range(5):
            mid += 1
            titulo = f"{palavras[(mid*3)%10]} {sufixos[(mid+k)%5]}"
            musicas.append([f"M{mid:03d}", titulo, random.randint(1998,2025), f"A{aid:03d}", nome, g])

nomes_u = ["Ana","Bruno","Carla","Diego","Elisa","Fabio","Gabi","Hugo","Iara","João","Karen","Lucas","Marta","Nando","Olivia","Paulo","Quiteria","Rafael","Sara","Tiago","Ursula","Vitor","Wanda","Xavier","Yara","Zeca","Alice","Bento","Cecilia","Davi","Eva","Felipe","Giovana","Heitor","Isis","Julio","Laura","Mateus","Nina","Otavio"]
paises = ["BR","BR","BR","BR","PT","IT","AR"]
gen_lista = list(generos)
usuarios, pref = [], {}
for i, n in enumerate(nomes_u):
    uid = f"U{i+1:03d}"
    usuarios.append([uid, n, random.choice(paises)])
    pref[uid] = gen_lista[i % 5]

por_genero = defaultdict(list)
for m in musicas: por_genero[m[5]].append(m[0])
todas = [m[0] for m in musicas]

ouviu = []
ouvidas = defaultdict(dict)
for uid, _, _ in usuarios:
    g = pref[uid]
    n_main = random.randint(8,14)
    escolhidas = random.sample(por_genero[g], min(n_main, len(por_genero[g])))
    outras = [m for m in todas if m not in por_genero[g]]
    escolhidas += random.sample(outras, random.randint(1,3))
    for m in escolhidas:
        main = m in por_genero[g]
        nota = random.choice([3,4,4,5,5]) if main else random.choice([1,2,3,4])
        vezes = random.randint(5,60) if main else random.randint(1,8)
        ouviu.append([uid, m, nota, vezes])
        ouvidas[uid][m] = nota

segue = set()
uids = [u[0] for u in usuarios]
for uid in uids:
    mesma = [x for x in uids if x != uid and pref[x] == pref[uid]]
    outra = [x for x in uids if pref[x] != pref[uid]]
    for x in random.sample(mesma, random.randint(2,4)): segue.add((uid,x))
    if random.random() < .5: segue.add((uid, random.choice(outra)))
segue = sorted(segue)

recomenda = []
for uid in uids:
    sc = defaultdict(float); cnt = defaultdict(int)
    for v in uids:
        if v == uid: continue
        comum = set(ouvidas[uid]) & set(ouvidas[v])
        if not comum: continue
        sim = len(comum) / len(set(ouvidas[uid]) | set(ouvidas[v]))
        for m, nota in ouvidas[v].items():
            if m not in ouvidas[uid] and nota >= 4:
                sc[m] += sim * nota; cnt[m] += 1
    top = sorted(sc.items(), key=lambda x: -x[1])[:5]
    for m, s in top:
        recomenda.append([uid, m, round(s,3), "colaborativa", cnt[m]])

def salvar(nome, cab, linhas):
    with open(nome, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(cab); w.writerows(linhas)

salvar("artistas.csv", ["id","nome","genero"], artistas)
salvar("musicas.csv", ["id","titulo","ano","artista_id","artista_nome","genero"], musicas)
salvar("usuarios.csv", ["id","nome","pais"], usuarios)
salvar("ouviu.csv", ["usuario_id","musica_id","nota","vezes"], ouviu)
salvar("segue.csv", ["origem_id","destino_id"], segue)
salvar("recomenda.csv", ["usuario_id","musica_id","score","metodo","usuarios_similares"], recomenda)
print(len(artistas),len(musicas),len(usuarios),len(ouviu),len(segue),len(recomenda))

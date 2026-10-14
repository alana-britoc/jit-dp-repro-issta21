set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

run() { if [[ "$DRY_RUN" == "1" ]]; then echo "[dry-run] $*"; else "$@"; fi; }

# ---------- labels ----------
label() { run gh label create "$1" --color "$2" --description "$3" --force >/dev/null; }
label setup       0E8A16 "Ambiente, dados e organização"
label reproducao  1D76DB "Reprodução dos resultados do artigo"
label extensao    D93F0B "Novos modelos e experimentos"
label analise     5319E7 "Análise, estatística e discussão"
label docs        FBCA04 "Relatório, README e apresentação"
label opcional    C5DEF5 "Só se sobrar tempo"
label bloqueante  B60205 "Bloqueia outras tarefas"

# ---------- milestones ----------
milestone() {
  if [[ "$DRY_RUN" == "1" ]]; then echo "[dry-run] milestone: $1"; return; fi
  gh api "repos/{owner}/{repo}/milestones" -f title="$1" -f description="$2" >/dev/null 2>&1 || true
}
milestone "Fase 0 - Preparação"   "Leitura, repositório, ambiente e dados"
milestone "Fase 1 - Reprodução"   "Reproduzir LApredict, LR-JIT, DeepJIT (e CC2Vec se der)"
milestone "Fase 2 - Extensão"     "Pipeline comum e novos modelos"
milestone "Fase 3 - Análise"      "Estatística, gráficos e respostas às perguntas de pesquisa"
milestone "Fase 4 - Entrega"      "Relatório, README final e apresentação"

# ---------- issues ----------
# uso: issue "título" "labels (vírgula)" "milestone" "corpo"
issue() {
  run gh issue create --title "$1" --label "$2" --milestone "$3" --body "$4" >/dev/null
  echo "criada: $1"
}

M0="Fase 0 - Preparação"
M1="Fase 1 - Reprodução"
M2="Fase 2 - Extensão"
M3="Fase 3 - Análise"
M4="Fase 4 - Entrega"

# ===== Fase 0 =====
issue "Cada membro: ler o artigo e escrever resumo de 1 página" "setup" "$M0" \
"Ler *Deep Just-in-Time Defect Prediction: How Far Are We?* (ISSTA 2021) e o JITLine (arXiv 2103.07068).

- [ ] Resumo individual com as próprias palavras (problema, método, resultados, limitações)
- [ ] Salvar em \`reports/resumos/<nome>.md\`

**Pronto quando:** todos os membros enviaram o resumo por PR."

issue "Definir ambiente reprodutível (conda/venv) para nosso código" "setup" "$M0" \
"O repo original pede Python 3.7+, numpy 1.20.1, pandas 1.2.3 e torch 1.2.0+. Nosso código pode usar versões atuais, mas o código original talvez precise de ambiente separado.

- [ ] Ambiente do nosso código (\`requirements.txt\` ou \`environment.yml\`)
- [ ] Ambiente separado para rodar o código original, se necessário
- [ ] Documentar no README como criar cada um

**Pronto quando:** outro membro cria o ambiente do zero e roda um script de teste."

issue "Clonar o repo original em third_party e registrar o commit de referência" "setup" "$M0" \
"Repo: https://github.com/ZZR0/ISSTA21-JIT-DP (licença MIT, confirmada na página do repo).

- [ ] Clonar em \`third_party/ISSTA21-JIT-DP\` (pasta no .gitignore)
- [ ] Registrar o hash do commit em \`third_party/README.md\`
- [ ] O README do original manda clonar \`ISSTA2021-JIT-DP\`; confirmar qual nome funciona
- [ ] Ler \`run.py\` de DeepJIT, CC2Vec e JIT_Baseline e anotar as flags (\`-RQ2_T5\`, \`-RQ4_T8\`...)"

issue "Baixar datasets.tar.gz e documentar o formato dos dados" "setup,bloqueante" "$M0" \
"O README do original aponta o \`datasets.tar.gz\` num Google Drive. Conferir também o Zenodo (https://zenodo.org/records/4727756) como cópia de segurança.

- [ ] Baixar e extrair em \`DeepJIT/\`, \`CC2Vec/\` e \`JIT_Baseline/\` (dentro de third_party)
- [ ] Documentar em \`data/README.md\`: arquivos, colunas, tamanho, o que há de texto (mensagem, diff) e de features
- [ ] Guardar sha256 dos arquivos baixados
- [ ] Responder: os dados trazem diff/tokens suficientes para o modelo estilo JITLine e para CodeBERT?

**Pronto quando:** qualquer membro consegue carregar um projeto com um comando."

issue "Definir onde rodar GPU e medir uso real de memória" "setup" "$M0" \
"O README pede GPU 1080Ti, 128 GB de RAM e 50 GB de disco para o retreino. Isso excede um Colab gratuito.

- [ ] Listar opções: máquina da faculdade, Colab, Kaggle, alguém do grupo com GPU
- [ ] Rodar o menor projeto (JDT, ~13 mil commits) e medir RAM e tempo reais
- [ ] Decidir se DeepJIT será retreinado ou se usaremos só os resultados em cache"

issue "Reunião de escopo: projetos, modelos e divisão de tarefas" "setup" "$M0" \
"- [ ] Escolher 2 ou 3 projetos (sugestão: QT, OpenStack, Gerrit)
- [ ] Fechar a lista de modelos novos (núcleo vs extensão)
- [ ] Atribuir responsáveis às issues das fases 1 e 2
- [ ] Confirmar com o professor formato de entrega e exigências sobre modelos novos"

# ===== Fase 1 =====
issue "Rodar a análise rápida (ResultAnalysis) e guardar as tabelas de referência" "reproducao" "$M1" \
"Usa os resultados em cache do repo original; não exige GPU.

\`\`\`
cd ResultAnalysis
python analysis.py -RQ2_T5
python analysis.py -RQ4_T8
\`\`\`

- [ ] Gerar ao menos Tabelas 2, 5 e 8 e a Figura 5
- [ ] Salvar em \`results/referencia_artigo/\`

**Pronto quando:** temos os números do artigo em CSV/imagem dentro do nosso repo."

issue "Reproduzir LApredict no nosso código" "reproducao" "$M1" \
"Regressão logística usando só a feature LA (linhas adicionadas).

- [ ] Implementar em \`src/models/lapredict.py\` (scikit-learn)
- [ ] Mesma divisão cronológica do artigo (80% treino, 20% teste)
- [ ] Comparar AUC com a Tabela 8 (ex.: QT 0,7438; OpenStack 0,7491; Gerrit 0,7495)
- [ ] Registrar tempo de treino e teste"

issue "Reproduzir LR-JIT (14 features) no nosso código" "reproducao" "$M1" \
"Regressão logística sobre as 14 features de Kamei (NS, ND, NF, Entropy, LA, LD, LT, FIX, NDEV, AGE, NUC, EXP, REXP, SEXP).

- [ ] Implementar em \`src/models/lr_jit.py\`
- [ ] Comparar AUC com a Tabela 5 do artigo
- [ ] Reproduzir também a Figura 7 (AUC por feature isolada)"

issue "Rodar o JIT_Baseline original (LR-JIT, DBN-JIT, LApredict) e comparar com o nosso" "reproducao" "$M1" \
"O README informa cerca de 10 min por RQ em CPU.

- [ ] \`cd JIT_Baseline && python run.py -RQ2_T5\` (e -RQ4_T8)
- [ ] Comparar com nossa implementação da issue anterior
- [ ] Anotar diferenças e hipóteses"

issue "Retreinar DeepJIT em um projeto" "reproducao" "$M1" \
"README informa treino de 6 h a 1 dia por RQ; a Tabela 9 do artigo mostra cerca de 23 min por projeto. Medir qual vale.

- [ ] Escolher 1 projeto
- [ ] \`python run.py -RQ2_T5 -train_deepjit\` e \`-pred_deepjit\`
- [ ] Comparar AUC com a Tabela 5 (QT: 0,6927; OpenStack: 0,7132)
- [ ] Registrar tempo real e hardware usado"

issue "CC2Vec: retreinar ou usar apenas resultados em cache" "reproducao,opcional" "$M1" \
"README informa treino de 1 a 3 dias. Só vale tentar se houver GPU e tempo.

- [ ] Decidir após medir o DeepJIT
- [ ] Se não retreinar, citar no relatório que usamos os resultados em cache"

issue "Investigar possível vazamento de teste no CC2Vec (PQ7)" "reproducao,analise" "$M1" \
"O JITLine afirma que o CC2Vec aprende as representações com treino e teste juntos. Verificar se o código do artigo-base repete isso.

- [ ] Ler \`CC2Vec/run.py\` e o fluxo de \`-train_cc2vec\` / \`-pred_cc2vec\`
- [ ] Anotar em quais dados o CC2Vec é treinado
- [ ] Concluir: há ou não uso de dados de teste? Registrar evidência (trecho de código, linha)"

issue "Tabela comparativa: artigo vs nossa reprodução" "reproducao,docs" "$M1" \
"- [ ] Uma tabela por modelo reproduzido (AUC do artigo, o nosso, diferença)
- [ ] Discutir diferenças (versão dos dados, seed, hardware, bibliotecas)
- [ ] Salvar em \`reports/reproducao.md\`"

# ===== Fase 2 =====
issue "Pipeline comum: carregar dados, dividir cronologicamente, salvar resultados" "extensao,bloqueante" "$M2" \
"- [ ] \`src/data_loading.py\` e \`src/split.py\` (80/20 cronológico, mais validação interna cronológica para tuning)
- [ ] \`src/run_experiment.py\` com CLI: \`--project --model --seed\`
- [ ] Saída em \`results/<projeto>_<modelo>_<seed>.csv\`

**Pronto quando:** rodar LApredict por esse pipeline reproduz o AUC da issue de reprodução."

issue "Módulo de métricas (AUC, PR-AUC, F1, MCC, FAR, d2h, esforço)" "extensao" "$M2" \
"Métricas do artigo-base e do JITLine.

- [ ] AUC, PR-AUC, F1, MCC, FAR, d2h
- [ ] PCI@20%LOC, Effort@20%Recall, Popt (ordenando por probabilidade/LOC)
- [ ] Limiar escolhido no treino, nunca no teste
- [ ] Testes unitários com casos pequenos"

issue "Modelos de árvore nas 14 features (Random Forest, XGBoost/LightGBM)" "extensao" "$M2" \
"- [ ] Implementar em \`src/models/tree_models.py\`
- [ ] Tuning moderado com validação cronológica dentro do treino
- [ ] 10 a 16 seeds
- [ ] Pergunta: algum supera o LApredict? (PQ2)"

issue "Modelo com texto: TF-IDF da mensagem de commit + features" "extensao" "$M2" \
"- [ ] TF-IDF só da mensagem, depois combinado com LA e com as 14 features
- [ ] Classificadores: regressão logística e Random Forest
- [ ] Pergunta: a mensagem melhora o resultado? (PQ3)"

issue "Modelo estilo JITLine: bag-of-tokens do diff + Random Forest" "extensao" "$M2" \
"Baseado no JITLine (CountVectorizer sem lowercase; literais viram <NUM> e <STR>; RF com 300 árvores).

- [ ] Depende de a issue de dados confirmar que há diff/tokens
- [ ] Versão base sem SMOTE; SMOTE com DE como variação opcional
- [ ] Comparar com LApredict nos mesmos dados (PQ8)"

issue "Fine-tuning de CodeBERT (ou similar) em mensagem + diff" "extensao,opcional" "$M2" \
"Extensão ambiciosa; só com GPU.

- [ ] Documentar limite de tokens e como o diff é truncado
- [ ] Um projeto, poucas seeds
- [ ] Medir tempo e comparar custo-benefício (PQ4, PQ6)"

issue "Rodar todos os modelos com várias seeds e registrar configurações" "extensao" "$M2" \
"- [ ] Script que roda a grade projeto x modelo x seed
- [ ] Guardar seed, hash do commit, versões das bibliotecas e hardware em cada resultado"

# ===== Fase 3 =====
issue "Testes estatísticos (Wilcoxon / Scott-Knott) e tamanho de efeito" "analise" "$M3" \
"- [ ] Comparar modelos sobre as seeds
- [ ] Reportar p-valor e tamanho de efeito (Cliff's delta)"

issue "Gráficos e tabelas comparativas" "analise" "$M3" \
"- [ ] AUC, PR-AUC, F1, MCC, Recall@20% de esforço, tempo de treino
- [ ] Um gráfico de custo-benefício (ganho por segundo de treino)
- [ ] Salvar em \`reports/figuras/\`"

issue "Análise de erro: onde o LApredict falha (ex.: JDT e Platform)" "analise" "$M3" \
"No artigo, LApredict perde para o DeepJIT na Platform (0,7461 vs 0,7712).

- [ ] Investigar por quê (distribuição de LA, taxa de defeitos, tamanho dos commits)
- [ ] Os novos modelos corrigem isso?"

issue "Discussão: AUC do LApredict é igual em within e cross-project" "analise" "$M3" \
"No artigo, o AUC do LApredict é idêntico em within-project e cross-project, o que decorre de o AUC depender só do ranking dos commits por LA, não de robustez do modelo.

- [ ] Verificar empiricamente
- [ ] Discutir com outras métricas (F1/MCC em limiar escolhido no treino)"

issue "Responder as perguntas de pesquisa PQ1 a PQ8" "analise,docs" "$M3" \
"- [ ] Uma resposta curta, com número e evidência, por pergunta
- [ ] Incluir resultados negativos
- [ ] Ver lista de perguntas no documento do projeto"

# ===== Fase 4 =====
issue "Relatório final" "docs" "$M4" \
"Estrutura: introdução; resumo do artigo; metodologia; resultados da reprodução; extensão; discussão; ameaças à validade; conclusão; referências.

- [ ] Rascunho completo
- [ ] Revisão cruzada entre membros
- [ ] Ameaças: SZZ, subconjunto de projetos, tuning, hardware, tempo"

issue "README final com instruções de reprodução em poucos comandos" "docs" "$M4" \
"- [ ] Passo a passo do ambiente ao resultado
- [ ] Tempo esperado e hardware necessário
- [ ] Teste: alguém de fora do grupo reproduz"

issue "Apresentação (se exigida) e revisão final do repositório" "docs" "$M4" \
"- [ ] Slides
- [ ] Limpar branches, fechar issues, conferir .gitignore e licença"

echo
echo "Pronto. Veja em: gh issue list"

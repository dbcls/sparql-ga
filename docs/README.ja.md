# SPARQL-GA

SPARQL クエリを、遺伝的アルゴリズム(以下GA)を使って、より高速に検索ができるように最適化します。

## 遺伝的アルゴリズムでの説明

[遺伝的アルゴリズム \- Wikipedia](https://ja.wikipedia.org/wiki/%E9%81%BA%E4%BC%9D%E7%9A%84%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0) を利用して、SPARQL-GAでは以下のように実装をしました。

1. 与えられたSPARQLクエリをもとに、染色体の長さを決め、初期の個体群を生成する。
2. 個体群の各個体に関して、クエリの実行時間をもとに評価値を決定する
3. 次世代の親となる個体を２つ選ぶ。このとき評価値に応じた確率で選ばれる。
4. 親として選ばれた個体２つを交叉させる。
5. 生成された個体に関して、一定の確率で突然変異が起こる。
6. 次世代の集団に加える。
7. ３−６の操作を、次世代の個体群が決められた個体数になるまで繰り返す
8. 世代が決められてた回数に達するまで、２に戻る
9. 結果を出力する

### 個体、個体群

SPARQL-GAでは、個体をSPARQLクエリを精製するためものとして定義します。

決められた数の個体数の集団を個体群と定義します。

### 染色体、遺伝子

TODO: 染色体の説明を書く、遺伝子の説明を書く

SPARQL-GAでは、クエリをパースして、染色体とします。
遺伝子は、BGPが配列となっている部分の添字をとします。


TODO: クエリと染色体の対応する図を載せる。

### 集団のサイズ

集団のサイズとは、１世代あたりの個体(SPARQLクエリ)の数となります。

### 世代数

個体群の生成、評価を行う回数となります。

### 評価

SPARQL-GAでは、クエリの実行にかかった時間を元に、評価値をきめます。
評価値は、クエリの実行時間が短ければ高くなるように以下の式で求めます。

```text
評価値 = 1 / クエリの実行時間
```

評価に関しては以下のようになります。

1. 各個体の染色体から、SPARQLクエリを生成する
2. 決められた回数、１で生成されたクエリをエンドポイントへ投げる
3. 中央値を、その個体の評価値とする。

### 選択

ルーレット選択を用いて、親と成る個体が選ばれます。

各個体の評価値の合計を全体として、各個体は、全体に対する各個体の適合度の割合で親として選択されます。
大きな適合度をもつものほど、親として選ばれる確率が高くなります。

- [ルーレット選択 遺伝的アルゴリズム \- Wikipedia](https://ja.wikipedia.org/wiki/%E9%81%BA%E4%BC%9D%E7%9A%84%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0#%E3%83%AB%E3%83%BC%E3%83%AC%E3%83%83%E3%83%88%E9%81%B8%E6%8A%9E)

### 交叉

選択で選ばれた２つの個体を親として、交叉を行います。
SPARQL-GAでは、交叉は必ず行われます。
交叉の際には、順序が考慮されるように
 OX: Order Crossover を使用しました。

手法の詳細は以下を参照ください。

- [On Genetic Crossover Operators for
Relative Order Preservation](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.50.1898&rep=rep1&type=pdf)
- [順序交叉(OX:Order crossover)](http://ono-t.d.dooo.jp/GA/GA-order.html#OX)

### 突然変異

各個体は、与えられた確率で突然変異するかどうかが決められます。
突然変異が適用されるときは、クエリとして成立するように、個体の中の染色体の２つの位置が選ばれ、それぞれの位置の情報が交換されます。

## 準備

実行の前に、実行に必要なものを揃えます。
必要なものは、以下になります。

- SPARQL
  - 最適化したいクエリ
  - 最適化したいクエリを投げるエンドポイント
- Ruby関連
  - 実行に必要なライブラリ

### SPARQL

最適化したいSPARQLクエリを準備します。
このときに、SPARQLエンドポイントも知る必要があります。

以下のクエリを例に、この文書では説明を進めます

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ncbigene: <http://identifiers.org/ncbigene/>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX up: <http://purl.uniprot.org/core/>
PREFIX p9: <http://purl.uniprot.org/SHA-384/>
SELECT DISTINCT ?gene ?node_55 ?refseq
WHERE {
  p9:17D627D6E7D33D1A4BA3D187BD44176CE1C44E3D7324007F701F2B6A533B485BD039D59A62E6ED0BD89CB363094213C2 .
  ?gene obo:so_part_of ?refseq .
  ?gene dct:identifier "BRCA1" .
  ?gene rdfs:seeAlso ncbigene:672 .
  ?gene rdfs:subClassOf ?node_55 .
}
```

### Ruby のライブラリ

以下のコマンドでインストールします。
この場合インストール先は、カレントディレクトリの、 `vendor/bundle` になります。

```console
bundle install --path vendor/bundle
```

## 実行

実際にクエリを最適化します。

このとき、指定した順番でクエリを実行させるために、以下の句を先頭につけたクエリを、SPARQLエンドポイントに投げます。

`DEFINE sql:select-option "order"`

そのため現状では、Virtuosoを使用しているエンドポイントが対象となります。

### Rubyのコマンド

使い方は、以下のようになります。

```console
bundle exec ruby sparql-ga.rb \
  --endpoint="http://dev.togogenome.org/sparql" \
  --sparqlquery=sample.rq \
  --population_size=100 \
  --generations=50 \
  --remove-backslash
```

この例では

- エンドポイント
  - "http://dev.togogenome.org/sparql"
- SPARQLクエリ
  - sample.rq
- 集団のサイズ
  - 100
- 世代数
  - 50
- バックスラッシュを取り除くオプション
  - 有効

### オプションの説明

SPARQL-GAでは、以下のようなオプションがあります。

```text
Usage: sparql-ga [options]
    -v
        --verbose
        --sparqlquery=VAL
        --endpoint=VAL
        --population_size=4
        --generations=2
        --number_of_trials=3
        --remove_backslash
```

各オプションの意味は以下になります。

- `-v`, `--verbose`
  - 詳細な情報を出力する(default: 有効)
- `--sparqlquery`
  - 最適化するSPARQLクエリが書かれているファイル
- `--population_size`
  - 集団のサイズ(default: 4)
- `--generations`
  - 世代数(default: 2)
- `--number_of_trials`
  - 個体を評価する際の同じクエリの実行回数(default: 3)
- `--remove_backslash`
  - バックスラッシュを削除するかどうかのフラグ(deafult: false)

## 結果の把握

出力された結果の把握

### 出力の解釈

コマンドの実行が終了すると以下のような出力がされます。

```console
All times Best fit: Chr [2, 1, 0, 3] => 22.30997477334286, elapsed time: 0.04482300003292039
All times Fastest fit: Chr [2, 1, 0, 3] => 26.556898159366327, elapsed time: 0.03765499999281019
```

上から

- 最も評価値が高い個体の染色体の情報、および、評価値、実行時間
- 一番高速な結果がでた個体の染色体情報、および、評価値、実行時間
  - 偶然の可能性もある

### ディレクトリ構造

ディレクトリ構造は以下のようになっています。

`result` というディレクトリのしたに実行した日時のディレクトリができます。
このディレクトリのしたに３つディレクトリができます。
そのほかに、各世代終了時点での、いかのものが出力されています。

- 最も評価値の高い個体の情報 `*_bestfit.txt`
- 一番高速な結果が出た個体の情報 `*_fastest.txt`

`result/20220214T112233/`

このような階層になっています。

```text
└── 20220219T002117
    ├── 0_bestfit.txt
    ├── 0_fastest.txt
    ├── 1_bestfit.txt
    ├── 1_fastest.txt
    ├── 2_bestfit.txt
    ├── 2_fastest.txt
    ├── sparql
    └── timearray
```

### ファイルについて

各ディレクトリに格納されるファイルは、各個体の情報を元にファイル名が決まります。
染色体の情報が `3, 2, 0, 4, 1` である場合、ファイル名は、`3_2_0_4_1` となります。
このファイル名に拡張子が付きます。

#### sparql

各個体ごとに、実行したsparqlクエリが入るディレクトリです

ディレクトリの中には、各個体の情報からファイル名がきまり、拡張子は、 `rq` となります。

実際のファイルの中身は、以下のようになります。

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ncbigene: <http://identifiers.org/ncbigene/>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX up: <http://purl.uniprot.org/core/>
PREFIX p9: <http://purl.uniprot.org/SHA-384/>
SELECT DISTINCT ?gene ?node_55 ?refseq ?protein
WHERE {
?gene rdfs:seeAlso ncbigene:672 .
?gene dct:identifier "BRCA1" .
?gene rdfs:subClassOf ?node_55 .
?protein up:mappedAnnotation p9:17D627D6E7D33D1A4BA3D187BD44176CE1C44E3D7324007F701F2B6A533B485BD039D59A62E6ED0BD89CB363094213C2 .
?gene obo:so_part_of ?refseq .
}
```

#### timearray

各個体ごとに、実行したすべての時間が記録されます。

ファイルの中身は、以下のようになります。

各個体の、すべての実行時間を記録したファイルがあります。
ファイルの形式は、カンマ区切りのファイルです

```csv
0.05539399999543093,0.054195000004256144,0.05448300001444295
```

## 参考情報

- [ルーレット選択 遺伝的アルゴリズム \- Wikipedia](https://ja.wikipedia.org/wiki/%E9%81%BA%E4%BC%9D%E7%9A%84%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0#%E3%83%AB%E3%83%BC%E3%83%AC%E3%83%83%E3%83%88%E9%81%B8%E6%8A%9E)
- [On Genetic Crossover Operators for
Relative Order Preservation](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.50.1898&rep=rep1&type=pdf)
- [順序交叉(OX:Order crossover)](http://ono-t.d.dooo.jp/GA/GA-order.html#OX)

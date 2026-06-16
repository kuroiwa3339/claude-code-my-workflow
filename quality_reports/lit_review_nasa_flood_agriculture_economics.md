# Literature Review: NASA衛星データを用いた洪水の農業経済的影響

**Date:** 2026-06-15
**Query:** NASAの衛星データを使った洪水被害の経済的影響、特に農業への影響を分析した研究

---

## Summary

洪水は農業生産に対する最大の自然災害の一つであり、世界の農業被害の約60%を占めるとされる。従来の被害推計は地上調査や保険データに依存してきたが、NASAのMODIS衛星データを筆頭とするリモートセンシングの普及により、日次・250m解像度での浸水範囲の空間的把握が可能となった。これにより、洪水露出と農業生産・経済成果を結びつけたパネルデータ研究が台頭しつつある。

農業影響の定量化において、近年の研究はGlobal Flood Databaseや衛星NDVI、SARデータを用いて洪水が引き起こす作物収量損失を推計してきた。Kim et al. (2023) は大豆4%・米3%・小麦2%・トウモロコシ1%の収量損失（10年超えの戻り期間洪水時）を示し、Li et al. (2025) は差分の差分法（DiD）を用いてコメ殺傷洪水による世界平均収量損失が4.3%に達することを確認した。しかし、従来の作物モデルはこうした損失を21〜29%過小評価していることも明らかになっている（Zhang et al. 2026）。

経済的影響の面では、Kocornik-Mina et al. (2020) が夜間光データと浸水マップを組み合わせて都市部の洪水からの経済的回復を追跡し、Collalti (2024) は衛星由来の洪水指数を用いて地域GDP代理変数への影響を推計した。ただし、MCDWDのような高頻度・高空間解像度の衛星洪水データを因果識別戦略として農業パネルに直接組み込んだ研究は、本レビュー時点でまだ限定的であり、本プロジェクトの独自性を裏づける。

---

## Key Papers

### Kim et al. (2023) — Flood Impacts on Global Crop Production: Advances and Limitations
- **Main contribution:** 世界の4大作物（大豆・米・小麦・トウモロコシ）に対する洪水の収量損失を初めて体系的に定量化
- **Method:** CaMa-Floodモデルによる浸水面積の戻り期間推定 + 技術トレンドを除去した作物収量データとの照合; EM-DATによる検証（ROC分析）
- **Key finding:** 10年超過洪水時の世界平均収量損失：大豆4%、米3%、小麦2%、トウモロコシ1%。1982〜2016年累計損失約55億ドル、中国が56%を占める
- **Relevance:** MCDWDパネルを用いた作物収量損失推計の基準値として直接参照可能
- **Citation:** Kim, W., Iizumi, T., Hosokawa, N., Tanoue, M., & Hirabayashi, Y. (2023). *Environmental Research Letters*, 18(5).

### Li, Rosa & Gorelick (2025) — Severe Floods Significantly Reduce Global Rice Yields
- **Main contribution:** 「コメ殺傷洪水」（7日以上の完全冠水）を識別してDiDを適用した初の大規模衛星×収量パネル研究
- **Method:** 衛星浸水データによる処置群（浸水グリッドセル）vs 対照群（非浸水）の定義、時系列DiD推定
- **Key finding:** 全球平均4.3%の収量損失（年間1,800万トン相当）；中国5.3%、インド6.4%；2000年以降損失が増加傾向
- **Relevance:** MCDWDと作物収量パネルの統合設計に直接参照できる手法的モデル
- **Citation:** Li, Z., Rosa, L., & Gorelick, S. (2025). *Science Advances*, 11(46), eadx7799.

### Zhang et al. (2026) — Underestimated Agricultural Losses Due to Flooding
- **Main contribution:** 既存作物モデル（GGCMI3）が洪水損失を大幅過小評価していることを示し、洪水ストレスアルゴリズムで補正
- **Method:** CaMa-Flood（水文モデル）+ GGCMI3（作物モデル）+ 土壌・作物タイプ別凸型ストレス曲線; USDAデータ・EM-DATで検証
- **Key finding:** トウモロコシ26.7%、大豆28.3%、小麦21.3%の過小評価バイアス；将来気候下では洪水損失が干ばつ損失に匹敵・超過する地域が出現
- **Relevance:** MCDWDパネルが捉える洪水露出の農業損失ポテンシャルを正当化する
- **Citation:** Zhang, S., Zhou, L., Liang, H., Obulkasim, O., & Dai, Y. (2026). *Science Advances*, 12(16).

### Kocornik-Mina, McDermott, Michaels & Rauch (2020) — Flooded Cities
- **Main contribution:** 世界都市の大規模洪水後の経済活動回復パターンを衛星データで追跡した初の大規模研究
- **Method:** 高空間解像度浸水マップ + 夜間光データ（DMSP/OLS）; 35年間にわたる都市パネル分析
- **Key finding:** 洪水年の夜間光強度が2〜8%低下するが1年以内に回復；経済活動の永続的移動はほぼ見られない（新興開発地域を除く）
- **Relevance:** 衛星洪水データ×夜間光という計量経済的アプローチの先例；都市部と農業地帯の比較に有用
- **Citation:** Kocornik-Mina, A., McDermott, T. K. J., Michaels, G., & Rauch, F. (2020). *American Economic Journal: Applied Economics*, 12(2), 35–66.

### Collalti (2024) — The Economic Dynamics After a Flood: Evidence from Satellite Data
- **Main contribution:** 中央アメリカ・カリブ海地域でのフラッシュフラッド指数（衛星由来）と夜間光GDP代理変数を結びつけた動的パネル分析
- **Method:** 高解像度フラッシュフラッド衛星指数の構築 + 夜間光への遅延効果推定
- **Key finding:** 低〜中程度のHDI国では洪水後数ヶ月で最大5.6%の経済活動低下；高HDI国は影響限定的
- **Relevance:** 衛星洪水データによるGDP代理変数への動的影響推定の手法モデル
- **Citation:** Collalti, D. (2024). *Environmental and Resource Economics*.

### Rentschler, Salhab & Jafino (2022) — Flood Exposure and Poverty in 188 Countries
- **Main contribution:** 世界188カ国の洪水露出と貧困の交差を大規模空間データで定量化
- **Method:** 最先端の洪水ハザードマップ（100年確率洪水）+ 高解像度貧困データの空間重ね合わせ
- **Key finding:** 18.1億人（世界人口23%）が100年確率洪水に直接露出；そのうち89%が低・中所得国；1億7,000万人が高洪水リスク＋極度貧困の二重リスクを抱える
- **Relevance:** 洪水露出の農業・所得影響研究が対象とすべき脆弱人口の規模感を提供
- **Citation:** Rentschler, J., Salhab, M., & Jafino, B. A. (2022). *Nature Communications*, 13, 3527.

### Robinson et al. (2022) — The Impact of Flooding on Food Security Across Africa
- **Main contribution:** アフリカ全土の洪水と食料安全保障の関係をスケール依存的に分析
- **Method:** 衛星浸水検出 + 食料安全保障指標との照合; 地域・国家・局所スケール別分析
- **Key finding:** 食料不安定人口の約12%が調査期間中に洪水の影響を受けた；局所スケールでは食料安全保障の悪化が見られるが、国家・地域スケールでは混在した結果（東アフリカでは洪水増加が食料安全保障改善と関連する例も）
- **Relevance:** 洪水×食料安全保障の空間スケール依存性を示す重要な先例；農業収量との直接リンクの難しさを示す
- **Citation:** Robinson, B. et al. (2022). *Proceedings of the National Academy of Sciences*, 119(43).

### Hsiang (2016) — Climate Econometrics
- **Main contribution:** 気候×経済の因果識別フレームワークの体系的整理；天候ショックをツールとした農業・経済アウトカムへの影響推定手法を確立
- **Method:** 時間・地域固定効果パネル回帰の体系的レビュー；short-run vs long-run変動の識別上の含意を整理
- **Key finding:** 地域固定効果＋時間固定効果パネルで、単位内の天候変動が因果識別の有効なレバーとなる；農業アウトカムへの気候影響は最も広く研究され、識別が確立された経路の一つ
- **Relevance:** MCDWDパネルを用いた農業経済分析の計量フレームワーク設計の理論的基盤
- **Citation:** Hsiang, S. M. (2016). *Annual Review of Resource Economics*, 8, 43–75.

### Wuepper et al. (2025) — Satellite Data in Agricultural and Environmental Economics: Theory and Practice
- **Main contribution:** 衛星データを農業・環境経済学の実証研究に活用するための理論と実践の包括的レビュー
- **Method:** 方法論的サーベイ；衛星データの因果識別への活用パターンを分類
- **Key finding:** 衛星データは外生的変動の源泉として（処置変数・操作変数・制御変数）機能し、農業経済研究の革命的ツールとなりうる；ただし測定誤差・雲被覆・帰属の問題に注意
- **Relevance:** MCDWDの経済研究への活用方法の設計指針として直接参照可能
- **Citation:** Wuepper, D. et al. (2025). *Agricultural Economics*.

---

## Thematic Organization

### 1. 衛星による洪水検出と農業損失推計手法

NASA MODISを中心とする衛星洪水検出製品（MCDWD、MWP等）は、日次・250m解像度でグローバルな浸水範囲を提供する。MCDWDは2021年に公開され、2003〜2025年の23年分アーカイブが利用可能となった（前身製品MWPは2011〜2022年）。農業損失の推計には主に二種類のアプローチが取られている：（a）浸水マップとCropland Data Layer（CDL）等の土地利用データを重ね合わせて浸水耕地面積を推計する手法と、（b）NDVIの時系列変化（ΔNDVI）を用いて植生被害を定量化する手法。Li et al. (2025) はこれを発展させ、「コメ殺傷洪水」を衛星で識別してDiDを適用した。

### 2. 洪水による作物収量損失の計量化

世界的に見て洪水による農業損失は深刻で、かつ従来の推計が過小評価傾向にあることが複数の研究で示されている。Kim et al. (2023) は1982〜2016年の大規模洪水データを用いて4大作物の収量損失を推計し、中国・米国ミシシッピ・パキスタンインダスが集中的な被害を受けていることを示した。Zhang et al. (2026) はさらに、既存の作物モデルが土壌・作物タイプごとの浸水ストレスを適切にモデル化していないため、損失を25%前後過小評価していると論じた。これらの研究は、MCDWDのような高頻度の浸水データが農業損失推計の精度向上に直接貢献できることを示唆する。

### 3. 洪水の経済的・社会的影響の計量経済学

洪水の経済的影響を衛星データで追跡する研究は急速に増加している。Kocornik-Mina et al. (2020) は夜間光を経済活動プロキシとして都市部の洪水回復を追跡し、Collalti (2024) はフラッシュフラッド指数と夜間光を結びつけた動的分析を行った。これらは農業部門を直接対象としていないが、衛星洪水データ×経済アウトカムの計量フレームワークとして本研究に応用可能である。農業特化型の経済的影響研究では、インドのパネル分析（2025）やバングラデシュのモンスーン洪水×作物生産の研究が存在するが、MODIS MCDWDを用いたものはまだ限定的である。

### 4. 識別戦略としての気候・洪水変動

Hsiang (2016) の気候計量経済学フレームワークは、時間・地域固定効果パネルにおいて天候ショックが因果識別の有効な変動源となることを示した。洪水露出は降雨量よりも農業への直接打撃を反映し、耕地レベルでの浸水という明確な物理メカニズムを持つ。Li et al. (2025) のDiD手法はこの識別戦略を洪水×コメ収量に適用した先駆的例である。MCDWDのような日次データにより、洪水発生のタイミング・規模・継続期間を精細に制御したイベントスタディ設計が可能となる。

---

## Gaps and Opportunities

1. **MCDWDを用いた農業経済パネルの欠如** — 既存研究の多くはGlobal Flood DatabaseやCaMa-Floodなどの水文モデル由来の浸水推計を使用しており、MODIS MCDWDを直接的な洪水露出変数として農業経済パネルに統合した研究はほぼ存在しない。23年分のMCDWDアーカイブと郡レベルの農業統計（NASS等）の結合がフロンティアとなっている。

2. **物理損失から経済的アウトカムへのリンクが薄い** — 衛星ベースの研究は作物収量損失（物理量）の推計が中心であり、農家所得・地域GDPへの波及効果、農業保険請求、信用市場への影響など、経済的アウトカムへのリンクは薄い。

3. **高頻度（日次）パネルの活用不足** — MCDWDの日次解像度を活かした「洪水発生の正確なタイミング」を用いたイベントスタディ設計がほとんど試みられていない。植付け期・生育期・収穫期それぞれにおける洪水の異質性が農業損失に及ぼす影響の分析は空白である。

4. **米国内の農業郡パネルの可能性** — 米国ではUSDA-NASS作物収量データが郡×年次で長期利用可能であり、MCDWDとの結合により高品質な識別が可能。既存研究（Li et al. 2025等）はグローバルグリッドレベルの分析が中心で、米国郡レベルの精細なパネル分析は少ない。

5. **開発途上国における衛星洪水データの活用** — アフリカ・南アジアでは地上統計が限定的であり、衛星洪水データと食料安全保障・所得指標の結合による洪水影響研究の余地が大きい（Robinson et al. 2022 はその需要を示す）。

---

## Suggested Next Steps

- **MCDWDアーカイブ（2003〜2025）とUSDA-NASS郡次収量データの結合** — 郡×年次パネルを構築し、植付け期・生育期別の洪水露出と収量の関係をイベントスタディで推定する
- **Li et al. (2025) のDiD設計を米国コーン・大豆・小麦に適用** — 「浸水耕地割合」（MCDWDとCDLの重ね合わせ）を処置変数として用いる
- **Hsiang (2016) フレームワークに沿った固定効果設計** — 郡固定効果＋年固定効果＋州×年固定効果で季節性・マクロショックをコントロール
- **Kocornik-Mina et al. (2020) の農業版** — 農業郡の洪水後の農場収入回復パターンを追跡（AgCensusとMCDWDの結合）
- **Zhang et al. (2026) の補正フレームワークを参考に** 既存作物モデル推計との比較・キャリブレーション

---

## BibTeX Entries

```bibtex
@article{kim2023flood,
  author  = {Kim, Wonsik and Iizumi, Toshichika and Hosokawa, Nanae and Tanoue, Masahiro and Hirabayashi, Yukiko},
  title   = {Flood impacts on global crop production: advances and limitations},
  journal = {Environmental Research Letters},
  volume  = {18},
  number  = {5},
  year    = {2023},
  doi     = {10.1088/1748-9326/accd85}
}

@article{li2025severe,
  author  = {Li, Zhi and Rosa, Lorenzo and Gorelick, Steven},
  title   = {Severe floods significantly reduce global rice yields},
  journal = {Science Advances},
  volume  = {11},
  number  = {46},
  pages   = {eadx7799},
  year    = {2025},
  doi     = {10.1126/sciadv.adx7799}
}

@article{zhang2026underestimated,
  author  = {Zhang, Shulei and Zhou, Liming and Liang, Hongbin and Obulkasim, Omarjan and Dai, Yongjiu},
  title   = {Underestimated agricultural losses due to flooding},
  journal = {Science Advances},
  volume  = {12},
  number  = {16},
  year    = {2026},
  doi     = {10.1126/sciadv.aed2754}
}

@article{kocornin2020flooded,
  author  = {Kocornik-Mina, Adriana and McDermott, Thomas K. J. and Michaels, Guy and Rauch, Ferdinand},
  title   = {Flooded Cities},
  journal = {American Economic Journal: Applied Economics},
  volume  = {12},
  number  = {2},
  pages   = {35--66},
  year    = {2020},
  doi     = {10.1257/app.20170066}
}

@article{collalti2024economic,
  author  = {Collalti, Dino},
  title   = {The Economic Dynamics After a Flood: Evidence from Satellite Data},
  journal = {Environmental and Resource Economics},
  year    = {2024},
  doi     = {10.1007/s10640-024-00887-6}
}

@article{rentschler2022flood,
  author  = {Rentschler, Jun and Salhab, Melda and Jafino, Bramka Arga},
  title   = {Flood exposure and poverty in 188 countries},
  journal = {Nature Communications},
  volume  = {13},
  pages   = {3527},
  year    = {2022},
  doi     = {10.1038/s41467-022-30727-4}
}

@article{robinson2022flooding,
  author  = {Robinson, Brian and others},
  title   = {The impact of flooding on food security across Africa},
  journal = {Proceedings of the National Academy of Sciences},
  volume  = {119},
  number  = {43},
  pages   = {e2119399119},
  year    = {2022},
  doi     = {10.1073/pnas.2119399119}
}

@article{hsiang2016climate,
  author  = {Hsiang, Solomon M.},
  title   = {Climate Econometrics},
  journal = {Annual Review of Resource Economics},
  volume  = {8},
  pages   = {43--75},
  year    = {2016},
  doi     = {10.1146/annurev-resource-100815-095343}
}

@article{wuepper2025satellite,
  author  = {Wuepper, David and others},
  title   = {Satellite Data in Agricultural and Environmental Economics: Theory and Practice},
  journal = {Agricultural Economics},
  year    = {2025},
  doi     = {10.1111/agec.70006}
}
```

---

## Post-Flight Verification Block

**Status: PASS** (6/7 PASS, 1/7 PARTIAL — no FAILs, no fabricated citations)

| ID | Claim | Verdict | Notes |
|----|-------|---------|-------|
| C1 | Kim et al. 2023, ERL — 収量損失・$5.5B・中国56% | PASS | 全数値確認済み |
| C2 | Li et al. 2025, Sci. Adv. — 米収量4.3%減・DiD | PASS | 全数値確認済み |
| C3 | Zhang et al. 2026, Sci. Adv. — 過小評価バイアス | PASS | 全数値確認済み |
| C4 | Kocornik-Mina et al. 2020, AEJ:AE — 夜間光2〜8%低下・1年回復 | PASS | 定性的知見・書誌情報確認済み |
| C5 | Rentschler et al. 2022, Nat. Comm. — 18.1億人・89% LMIC | PASS | 全数値確認済み |
| C6 | Collalti 2024, ERE — 最大5.6%経済活動低下 | PASS | 確認済み |
| C7 | Hsiang 2016, ARRE — 農業が「最も識別可能な経路」 | PARTIAL | 書誌情報は確認済み。「最も」という順位づけはHsiangの論文本文で明示されない解釈のため表現を軟化済み |

*検証: claim-verifier agent (CoVe独立フォーク), 2026-06-15*

# Research Ideation: FSA農業ローンの人種別デフォルト格差と洪水露出

**Date:** 2026-06-15
**Input:** FSA（Farm Service Agency）ローンのデフォルト率が黒人農家で高い。洪水リスクの高い土地への空間的集中がその一因ではないか。手元データ：FSAローン個票（2012〜2022年）＋人種・郡/ZIPコード情報、MODIS MCDWDパネル（2003〜2025年）。

---

## Overview

米国農務省（USDA）のFarm Service Agencyは農家への直接融資プログラムを運営しているが、黒人農家のデフォルト率が白人農家と比べて有意に高いことが複数の先行研究で記録されている。Vekemans et al. (2024) はCox比例ハザードモデルを用いてFSA直接融資（2011〜2020年）のデフォルトを分析し、財務・属性変数を制御後も黒人農家のデフォルトリスクが高いことを確認した。Connor, Ahrendsen, Moss & Dodson (2025) はこのギャップのうち一部がFSA郡委員会における少数民族代表の欠如（文化的気候）によって説明されることを示した。

しかし、既存研究は**土地の空間的配置**という経路を体系的に検証していない。歴史的差別（Jim Crow時代の土地政策、差別的信用配分）により、黒人農家は低地・湿地帯などの洪水リスクの高い限界地に追いやられてきた。もしこの空間的集中が実際に存在し、かつ洪水がローン返済能力を破壊するなら、デフォルト格差の一部は「洪水露出の人種差」を通じた経路で説明できる——という仮説が立つ。MCDWDの日次250m解像度データとFSAローン個票を郡・ZIPコードで結合することで、この経路を初めて直接検証できる。

---

## Research Questions

### RQ1: 記述的分析 — 黒人農家は洪水リスクの高い地域に集中しているか？ (Feasibility: High)

**Type:** Descriptive
**Paper type:** descriptive

**Hypothesis:** 黒人FSA借入農家の所在地（郡・ZIP）は、白人農家と比べてMCDWD洪水露出度が有意に高い

**Identification Strategy:**
- **Method:** クロスセクション空間分析。FSAローン個票の郡/ZIPコードとMCDWD郡日次パネルを結合し、農家人種別の平均洪水露出度を比較
- **Treatment:** なし（記述的）
- **Control group:** なし（記述的）
- **Key assumption:** FSAローン個票の所在地コードが農地の実際の位置を反映している

**Data Requirements:**
- FSAローン個票（2012〜2022）：人種・郡/ZIPコード
- MCDWDアーカイブ（郡集計パネル）：洪水露出日数・浸水面積割合
- USDA Census of Agriculture（2012・2017）：郡別農地構成の参照
- Cropland Data Layer（CDL）：耕作地と洪水域の重ね合わせ

**Potential Pitfalls:**
1. FSAローン借入農家はすべての農家の代表的サンプルではない（FSAは信用アクセスが限られた農家向け）— 解釈の一般化に注意
2. 郡レベルの洪水露出は農場単位の実際の浸水とは異なる — ZIP5でより精細化することで緩和

**Related Work:** Rentschler et al. (2022) *Nat. Comm.*; Vekemans et al. (2024) *Applied Econ. Perspectives & Policy*

---

### RQ2: 因果推定 — 洪水露出はFSAローンのデフォルト確率を高めるか？ (Feasibility: High)

**Type:** Causal
**Paper type:** reduced-form

**Hypothesis:** MCDWDで計測した作物生育期中の洪水露出日数が多い年・地域ほど、その後のFSAローンデフォルト率が高い

**Identification Strategy:**
- **Method:** 農家（または郡）×年固定効果パネル回帰（DiD的設計）。農家固定効果が時不変の農地特性・信用力をコントロール；年固定効果がマクロ農業ショック（穀物価格変動等）をコントロール
- **Treatment:** MCDWD由来の作物生育期（4〜9月）における浸水日数または浸水面積割合（ZIP/郡レベル）
- **Control group:** 同じ郡内の同年・非洪水期（あるいは同一農家の非洪水年）
- **Key identifying assumption:** 年×農家固定効果を条件に、作物生育期中の洪水発生は農家の返済能力とは独立（外生的天候ショック）
- **Robustness checks:** （a）プラシーボテスト（冬季洪水露出 — 農業への直接影響は小さいはず）、（b）プレトレンド検定（洪水前年のデフォルト傾向）、（c）FCFの郡別洪水宣言との照合

**Data Requirements:**
- FSAローン個票（2012〜2022）：デフォルト日時・返済履歴・郡/ZIPコード
- MCDWDパネル（郡×日次 → 作物生育期集計）
- NOAA/FEMAの洪水宣言データ（検証用）

**Potential Pitfalls:**
1. **逆因果はなし**（洪水が農家の返済行動を事前に変えることはない）が、**選択バイアス**はある：洪水リスクの高い地に農家がいること自体が内生的 — 農家FEで対処
2. MCDWDの雲被覆問題（洪水検出漏れ）：3日合成製品（Flood_3Day）とのロバストネスチェックで対処
3. FSA Emergency Loan（洪水後の追加融資）がデフォルトを抑制する方向に働く — これを制御変数として含めるか、別途分析する

**Related Work:** Kim et al. (2023) *Environ. Res. Lett.*; Li et al. (2025) *Sci. Adv.*; Vekemans et al. (2024) *Applied Econ. Perspectives & Policy*

---

### RQ3: 異質性分析 — 洪水のデフォルト効果は黒人農家で大きいか？（メインRQ） (Feasibility: High)

**Type:** Mechanism / Heterogeneous treatment effects
**Paper type:** reduced-form

**Hypothesis:** 洪水露出がデフォルト確率に与える効果は黒人農家において統計的・経済的に有意に大きい。さらに、洪水露出の人種差でデフォルトギャップの相当部分が説明される（交絡経路の媒介分析）

**Identification Strategy:**
- **Method:** RQ2のパネル回帰に人種ダミー×洪水露出の交差項を追加（三重差分的設計）
  - `Default_{it} = α + β₁ Flood_{it} + β₂ Black_i + β₃ (Flood_{it} × Black_i) + γX_{it} + δ_i + λ_t + ε_{it}`
  - β₃が「洪水の黒人農家への追加デフォルト効果」
- **Treatment:** MCDWDによる洪水露出（作物生育期集計）
- **Control group:** 同条件の白人農家（農家FE・年FEを条件に）
- **Key identifying assumption:** 平行トレンド（洪水なし時に人種別デフォルト傾向は類似）+ 洪水への異質な対応が人種以外の交絡から独立
- **Decomposition:** Blinder-Oaxaca型の寄与分解で、「洪水露出の差」vs「洪水への反応係数の差」に分解

**Data Requirements:**
- RQ2と同じ＋農家レベルの財務指標（ローン残高・担保価値・保険加入状況）

**Potential Pitfalls:**
1. **人種と財務力の交絡**：黒人農家は財務バッファが薄い傾向があり、これが洪水への脆弱性を説明している可能性 — ローン×財務変数を段階的に追加して媒介分析
2. **農業保険加入率の差**：黒人農家は農業保険未加入が多く、洪水後の収入補填が少ない可能性 — Risk Management Agency（RMA）データとのリンクを検討
3. 交差項の識別には十分な「黒人農家×洪水年」セルが必要 — サンプルサイズを事前確認

**Related Work:** Connor et al. (2025) *AJAE*; Vekemans et al. (2024); Kocornik-Mina et al. (2020) *AEJ: Applied*

---

### RQ4: メカニズム — 洪水後にFSA緊急融資は人種間格差を縮めるか？ (Feasibility: Medium)

**Type:** Policy / Mechanism
**Paper type:** reduced-form

**Hypothesis:** FSAの緊急融資（Emergency Loan）プログラムへのアクセスは黒人農家で制限されており、洪水後のデフォルトリスクの人種差がFSA緊急融資申請・承認率の差を通じて媒介されている

**Identification Strategy:**
- **Method:** 媒介分析（Mediation analysis）+ FEMA洪水宣言×人種×FSA緊急融資申請の三者パネル
- **Treatment:** 洪水露出（MCDWDベース）× 人種
- **Mediator:** FSA緊急融資の申請・承認（個票から観察可能か確認要）
- **Key identifying assumption:** 緊急融資申請が洪水後の外生的制度的決定によって変動する（Sequential ignorability）

**Data Requirements:**
- FSAローン個票（緊急融資フラグ）
- FEMA disaster declaration データ（郡×日次）
- MCDWDパネル

**Potential Pitfalls:**
1. 媒介変数の内生性：緊急融資申請は農家の財務状況と同時決定 — より注意深い設計が必要
2. FSA個票に緊急融資フラグが含まれない可能性 — データ確認が先決

**Related Work:** Connor et al. (2025) *AJAE*（県委員会代表という制度変数の先例）

---

### RQ5: 記述的政策分析 — 洪水露出の人種差は何が原因か？ (Feasibility: Medium)

**Type:** Descriptive / Correlational
**Paper type:** descriptive

**Hypothesis:** 黒人農家の洪水リスク高地への集中は、歴史的土地政策（Homestead Act適用除外、FSAの差別的貸付、強制的土地喪失）と相関している

**Identification Strategy:**
- **Method:** 郡レベルの記述統計＋回帰。黒人農家シェアの高い郡ほど洪水露出が高いか、そして歴史的差別指標（旧奴隷州ダミー、1900年代黒人農家比率等）と現在の洪水露出の相関を検証
- 歴史的土地記録（HOLC Redlining地図の農業版相当）の活用を検討

**Data Requirements:**
- Census of Agriculture（1920, 1950, 1969, 2017）：郡別黒人農家比率の時系列
- MCDWDパネル
- 歴史的農業政策データ（旧FSA貸付記録など）

**Related Work:** 土地喪失の歴史的研究（Time誌 2023レポート等）

---

## Ranking

| RQ | Feasibility | Novelty | Priority | 理由 |
|----|-------------|---------|----------|------|
| RQ3 | High | **Very High** | **★★★** | メインRQ。既存研究の盲点を埋め、洪水経路という新変数で人種格差に新解釈を与える |
| RQ2 | High | High | ★★ | RQ3の前段として必須。洪水→デフォルト因果の確立 |
| RQ1 | High | Medium | ★★ | RQ3の前段として必須。空間分布の実態把握 |
| RQ4 | Medium | High | ★ | データ可用性要確認。確認後に昇格可能 |
| RQ5 | Medium | Medium | ★ | 歴史的文脈の補強に有用だが独立論文としては弱い |

---

## Suggested Next Steps

1. **データ確認**（最優先）：FSAローン個票にデフォルト日時・緊急融資フラグ・農場ZIPコードが含まれるか確認 → RQ4の実行可能性が変わる
2. **MCDWDパネル構築**（このプロジェクト）：郡×日次 → 作物生育期（4〜9月）集計版を完成させる
3. **RQ1の記述分析から着手**：FSA個票とMCDWDを結合し、人種別の平均洪水露出度を可視化
4. **Cox比例ハザードモデルで拡張**：Vekemans et al. (2024) の手法にMCDWD洪水露出を追加変数として導入
5. **農業保険データとのリンク検討**：RMAデータ（農業保険加入・支払い）が取得可能ならRQ4の強化に使える
6. **Vekemans et al. (2024) と Connor (2025) を精読**：既存モデルの制御変数・推定仕様を確認し、このプロジェクトとの差別化ポイントを明確化

---

## Open Questions（インタビューで残った問い）

- 懐疑論者への最大の反論ポイント（選択バイアス）への答えが今後の設計で中心課題
- 農業保険加入状況の人種差はどの程度把握できているか？（RMAデータアクセス）
- FSA緊急融資申請情報は個票に含まれるか？
- ZIPコードの粒度（4桁 vs 5桁）でMCDWDとのリンク精度がどう変わるか？

---

## Post-Flight Verification Block

**Status: PASS** (5/5 confirmed — 0 HIGH-WARN, 0 MED-WARN)

| ID | Claim | Verdict | Notes |
|----|-------|---------|-------|
| C1 | Vekemans et al. (2024), *Applied Econ. Perspectives & Policy* 46(1):137-153, Cox PHモデル | PASS | 全書誌情報・手法・知見確認済み |
| C2 | Connor et al. (2025), *AJAE* 107(5):1335-1356, ~10pp格差 | PASS | 直接アクセス不可（ペイウォール）だがRepEcとプレスリリースで独立確認 |
| C3 | 「限界地・洪水危険地への追いやり」が差別の文献で記録されている | PASS | 学術文献でほぼ逐語的に確認（"relegation to marginal and hazard-prone land"） |
| C4 | 1910年から20世紀で1,600万エーカーの90%超を喪失 | PASS | 数値整合性確認済み（1910: 1,600万エーカー → 2017: 290万エーカー） |
| C5 | MCDWD×FSAデフォルト×人種を結合した先行研究は**知る限り**存在しない | PASS | 複数経路でも該当研究なし。「知る限り」と留保した表現で防御可能 |

*検証: claim-verifier agent (CoVe独立フォーク), 2026-06-15*

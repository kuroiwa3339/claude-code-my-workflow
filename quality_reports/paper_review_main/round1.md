# Manuscript Review: Climate Adaptation through Employer-Provided Health Insurance: Evidence from U.S. Agriculture

**Date:** 2026-06-15
**Reviewer:** review-paper skill — adversarial mode, Round 1
**File:** Papers/main.tex
**Mode:** --adversarial (critic-fixer loop, max 5 rounds)

---

## Summary Assessment

**Overall recommendation:** Revise & Resubmit (Major Revision)

This paper examines whether employer-provided health insurance serves as a labor market adaptation mechanism to rising temperatures, using 30 years of NAWS data on U.S. crop workers. The contribution is genuinely novel: the existing climate-labor literature focuses almost entirely on wages and labor supply, while fringe benefits—especially health insurance—have been largely ignored. The use of a long-run moving-average temperature specification to capture compensation-contract adjustment is well-motivated and consistent with recent adaptation literature (Cui et al. 2020, 2022). The finding of adaptation inequality by legal status is the paper's most policy-relevant result.

That said, the paper has a cluster of concerns that must be resolved before submission. The identification argument is underdeveloped, the economic magnitude is never contextualized against plausible climate scenarios, the adversarial wage-prediction puzzle from the compensating differentials framework goes unexplained, and the adaptation inequality section—the strongest finding—is treated too briefly relative to its importance. The draft also contains internal working notes and compilation artifacts that must be removed.

---

## Strengths

1. **Genuine novelty.** Employer-provided health insurance as a climate adaptation margin has not been studied. The connection between heat exposure, health risk, and fringe benefit provision fills a real gap.
2. **Rich, rare data.** The confidential NAWS with legal-status information is difficult to obtain; using 30 years of it is a significant data advantage.
3. **Well-grounded conceptual framework.** Adapting Zivin & Neidell (2016)'s AC adoption model to health insurance is clean and delivers testable predictions.
4. **Multiple robustness checks.** Alternative fixed effects, spouse insurance, farm-size controls, and alternative temperature horizons are all included.
5. **Important heterogeneity.** The documented/undocumented gap and specialty/field crop splits are substantively interesting and empirically credible.

---

## Major Concerns

### MC1: Identification — Within-County Variation and Omitted Trends

- **Dimension:** Identification
- **Issue:** The strategy exploits within-county variation in 10-year moving-average temperature normals. Over 30 years (1993–2022), this variation is likely modest. The paper does not report how much within-county variation exists in the key temperature variables, making it impossible to assess whether the estimates are identified off economically meaningful shifts or off statistical noise in a few counties. More importantly, a 10-year moving average of temperature will trend upward over the sample period due to climate change, and this global trend is not fully absorbed by state-by-year FEs if there is differential warming across counties within a state. A county in California's Central Valley warming faster than a coastal county creates within-state variation—but that variation may be confounded with other differential economic trends (e.g., farm consolidation, H-2A program growth, commodity-price cycles) that are correlated at the county level.
- **Suggestion:** (a) Report a figure or table showing the distribution of within-county variation in the above-37°C bin variable—both across and within counties. (b) Add a county-specific quadratic time trend robustness check (not just linear, since climate change is accelerating). (c) Discuss which counties drive the variation and whether their trends are plausibly exogenous.
- **Location:** Section 5 (Method), Section 6.1 (Robustness)

### MC2: Economic Magnitude — No Climate-Scenario Benchmark

- **Dimension:** Econometrics / Argument
- **Issue:** The headline coefficient is 0.25 pp per 1 pp increase in the share of above-37°C days over 10 years, against a baseline health insurance rate of 14%. The paper presents this as evidence of "meaningful" adaptation, but never benchmarks it against projected climate change. What does a 2°C or 4°C warming scenario imply for the share of above-37°C days? If plausible 21st-century warming implies a 3–5 pp shift in extreme heat days for the counties in the sample, the implied adaptation effect is 0.75–1.25 pp—a ~5–9% increase in baseline HI coverage. Whether this is large or small depends entirely on the counterfactual health cost, which is also not quantified. Without this benchmark, the "adaptation is partial" conclusion lacks empirical grounding.
- **Suggestion:** Add a back-of-envelope calculation using CMIP6 or PRISM projection data for the study counties. Report the implied effect under a moderate (RCP4.5) and high (RCP8.5) warming scenario. This requires no new regression—just applying the estimated coefficient to projected shifts in the temperature distribution.
- **Location:** Section 6 (Results, pp. 11–13), Section 8 (Conclusion)

### MC3: The Wage Puzzle — Compensating Differentials Predicts Wage Decline

- **Dimension:** Argument / Econometrics
- **Issue:** The conceptual framework (Section 3.2) models health insurance as a compensating differential: firms that provide health insurance pay *less* wages (by X, the compensating differential) because workers value the benefit. If this framework is correct, rising temperatures should simultaneously increase health insurance provision *and* reduce wages (as health insurance substitutes for wages). The paper finds no wage response. This is not a minor inconsistency—it is a direct contradiction of the model's core prediction. The paper acknowledges only that "compensation adjustments to sustained warming occur through health-related fringe benefits rather than wages" (p. 13), without noting that the wage silence falsifies the compensating differentials prediction.
- **Suggestion:** Explicitly address this puzzle. Three possible explanations: (a) agricultural labor markets are not perfectly competitive and wages are downwardly sticky, so the adjustment is one-sided; (b) the compensating differential X is already priced into the labor market before the period studied and the marginal shift is in insurance not wages; (c) the magnitude of the health insurance effect is small enough that the wage offset is below statistical detection thresholds. The paper should commit to one of these and show evidence for it, or revise the model to not predict a wage decline.
- **Location:** Section 3.2 (Conceptual Framework), Section 6 (Results)

### MC4: H-2A Exclusion and Compositional Threat

- **Dimension:** Identification / External Validity
- **Issue:** The NAWS explicitly excludes H-2A guest workers. H-2A is the fastest-growing source of agricultural labor: the number of H-2A workers has grown from ~48,000 in 2005 to over 370,000 in 2022 (DOL data). H-2A workers are: (i) legally authorized, (ii) often provided employer-sponsored housing and transportation but usually not health insurance in the sense measured here, and (iii) concentrated in hotter, labor-scarce states (Florida, Georgia, North Carolina). If hotter counties experienced faster H-2A adoption (to fill heat-induced labor shortages), the *non-H-2A* workers remaining in NAWS may be a selected sample: better protected, more permanent, more likely to receive HI. This selection would bias the estimated temperature coefficient upward.
- **Suggestion:** Check whether the H-2A share by county and year is available (DOL publishes county-level H-2A certification data). If so, add H-2A county-year share as a control and re-run the main specification. Discuss the H-2A exclusion as a key external validity caveat even if the data are unavailable.
- **Location:** Section 4.1 (Data), Limitations (Section 8)

### MC5: Adaptation Inequality Section Is Underdeveloped

- **Dimension:** Argument / Writing
- **Issue:** Section 7 (Adaptation Inequality) is the most policy-relevant part of the paper—the finding that undocumented workers do not share in the health insurance adaptation is striking and important. But the section spans fewer than two pages and the main result is stated in two opaque sentences (lines 568–572): "We find that documented workers tend to receive health insurance under high temperatures. In contrast, regarding workers' compensation, undocumented workers tend to receive workers' compensation." This juxtaposition is confusing: workers' compensation (medical) is itself a fringe benefit—saying undocumented workers "receive WC" instead of "receive health insurance" does not constitute evidence of adaptation inequality; WC medical and HI are different things. The section also does not report the differential magnitude (how much larger is the documented effect vs. the undocumented effect?), does not test whether the two coefficients are statistically significantly different from each other, and does not connect the result back to the bargaining-power mechanism in the model (Section 3.2, last paragraph).
- **Suggestion:** (a) Report a formal test of equality between the documented and undocumented temperature coefficients. (b) Clarify the WC vs. HI comparison—is the claim that undocumented workers receive WC instead of HI, implying WC is their only adaptation channel? If so, explain why this is inferior (WC covers only work-related injuries, not off-job illness). (c) Expand the section to 3–4 paragraphs with explicit quantitative comparison and a connecting paragraph to the model mechanism.
- **Location:** Section 7 (Adaptation Inequality, pp. 18–19)

---

## Minor Concerns

### mc1: Working notes and internal memos in manuscript body (lines 106–138)
- **Issue:** Two unformatted bullet lists appear immediately after the abstract: "Dr. Mishra comments" and a TODO list ("Add model", "Add medicaid and ACA", etc.). These are clearly not intended for the reader.
- **Suggestion:** Delete entirely or wrap in `\begin{comment}...\end{comment}`.

### mc2: Empty citation (line 168)
- **Issue:** "increase fatigue on the job \citep{}." — the citation is empty and will produce a compile warning and a missing reference in the output.
- **Suggestion:** Find and insert the intended citation (likely Schulte et al. 2016 or similar occupational health reference).

### mc3: Duplicate `\label{trendfringewage}` (lines 377, 641, 660)
- **Issue:** Same label appears three times. LaTeX will cross-reference to whichever appears first, silently producing wrong cross-references for the later two figures.
- **Suggestion:** Rename the appendix figure labels to `\label{agedistribution}` and `\label{trendfringewagebylegality}`.

### mc4: Duplicate packages in preamble
- **Issue:** `\usepackage{pgfplots}` (×3), `\usepackage{xcolor}`, `\usepackage{tikz}`, `\usepackage{datetime2}`, `\usepackage{adjustbox}`, `\usepackage{array}`, `\usepackage{comment}`, `\usepackage{authblk}` (all ×2). Also `\pagenumbering{arabic}`, `\geometry{margin=1in}`, `\setlength{\affilsep}`, `\renewcommand\Affilfont` each duplicated 2–3 times.
- **Suggestion:** De-duplicate; keep one instance of each.

### mc5: Double-negative in Table 1 note (line 373)
- **Issue:** "The variables are not unweighted." — means "weighted," which is the opposite of what is intended.
- **Suggestion:** Change to "Note: Variables are unweighted." or "Note: Sampling weights are not applied."

### mc6: Summary statistics N vs regression N discrepancy
- **Issue:** Summary table reports N = 58,095 but Table 1 regression uses N = 64,713. No explanation is given.
- **Suggestion:** Add a footnote explaining that the larger regression sample includes workers matched to weather data but not all workers in the summary table (or vice versa).

### mc7: Typos
- Line 155: "Futhermore" → "Furthermore"
- Line 408: "resutls" → "results"
- Line 568: `\ref {hetero2}` (extra space in label) → `\ref{hetero2}`
- Line 605: "limitations in the studies" → "limitations in the study"
- Line 669: "county leve share" → "county level share"
- Abstract: "employer sponsored" → "employer-sponsored"; "agricultural worker'" → "agricultural workers'"

### mc8: Abstract omits adaptation inequality finding
- **Issue:** The abstract discusses heterogeneity only briefly ("substantial heterogeneity across crop types, worker characteristics, and time periods") without mentioning the documented/undocumented gap, which is arguably the paper's most novel finding on adaptation inequality.
- **Suggestion:** Add one sentence to the abstract explicitly stating the differential effect for undocumented workers.

### mc9: Citation style inconsistency
- **Issue:** Line 175 uses `\cite{}` instead of `\citep{}` (the pattern everywhere else).
- **Suggestion:** Replace `\cite{luo_health_2018}` with `\citep{luo_health_2018}`.

### mc10: Figure caption in appendix says "***" (lines 891, 906)
- **Issue:** Appendix figure captions end with "***" which appears to be a placeholder.
- **Suggestion:** Remove "***".

---

## Referee Objections

### RO1: The 10-year moving average conflates adaptation with time trends
**Why it matters:** This is the most common objection to moving-average specifications. If health insurance provision has been trending up (as Figure \ref{trendfringewage} shows it has), and within-county temperatures have been trending up (as climate change implies), then the correlation between the two is mechanically confounded by a common time trend—even with state-by-year FEs, if the trending is differential within states. The paper never reports how much within-county variation in the 10-year average exists, so the reader cannot assess whether the strategy is credible.
**How to address it:** Report within-county SDs of the key temperature bin variables. Add county quadratic time trends as a robustness check. If the main results survive, the concern is muted.

### RO2: H-2A worker exclusion creates compositional bias
**Why it matters:** H-2A workers grew from ~50k to ~370k over the sample period, concentrated in hotter states. Their exclusion from NAWS means the observed NAWS workforce is a changing selection of the agricultural workforce. If hotter counties shifted toward H-2A (legal, usually no HI) and away from NAWS workers (undocumented, sometimes HI), the within-county increase in HI rate among NAWS workers is partly a composition effect, not climate adaptation.
**How to address it:** Obtain county-year H-2A certification counts from DOL and add as a control. At minimum, discuss explicitly and place in limitations.

### RO3: Compensating differentials predicts wage decline — where is it?
**Why it matters:** If health insurance is a wage substitute (the model's prediction), wages should fall where HI rises. They don't. This undermines the compensating differentials interpretation and raises doubt about whether the HI effect is really an adaptation response or is driven by something else (e.g., state regulation, unionization trends in specialty crops).
**How to address it:** Test whether workers who receive HI in hotter areas earn lower wages than similar workers without HI (a direct test of the substitution). Or reframe the model to not predict wage substitution (e.g., if employers absorb the cost via profit reduction rather than wage reduction).

### RO4: The effect is driven entirely by specialty crops — is this robust?
**Why it matters:** The heterogeneity results show the effect is concentrated in specialty crops. Specialty crops are also more heavily unionized (UFW), concentrated in specific states (CA, FL), and have faced specific labor-shortage policy pressures. Is the whole result just California specialty-crop growers expanding HI due to state mandates or labor competition? The paper does not test this.
**How to address it:** Re-run main results excluding California. Check whether the specialty-crop effect is driven by states with explicit heat-protection standards (CA, WA, MN).

### RO5: Why isn't the adaptation effect larger given 30 years of exposure?
**Why it matters:** If employers are rational adapters and temperatures have been rising for 30 years, a 1.6% increase in HI coverage (from 14% to ~14.25%) is surprisingly small. One explanation is that the model prediction is correct but the HI supply side is constrained (small farms cannot afford group insurance even if they want to offer it). Another is that the NAWS sample is already a selected, relatively well-covered group. A third is that the effect is real but small because wages and other mechanisms matter more. The paper doesn't take a stand.
**How to address it:** Discuss the supply-side constraint explicitly. Ideally, use the farm-size control to test whether the temperature-HI relationship is stronger in counties with more large farms (which can supply group insurance more cheaply).

---

## Specific Section Comments

**Abstract (line 96):** "which are important for compensating for sustaining productivity and work place risk" — this phrase is grammatically garbled. Suggested revision: "which are important for sustaining worker productivity and mitigating workplace health risk."

**Introduction (line 163):** The third contribution paragraph (climate and labor markets) does not mention Derenoncourt et al. (2021) or Colmer (2021), which directly examine how labor contracts mediate environmental shocks. Ensure these are correctly cited.

**Section 3.2, final paragraph:** The prediction about undocumented workers having lower compensating differential X is stated qualitatively but not formalized. Given how important this is for Section 7, consider adding a simple inequality: if X_undoc < X_doc, then the relative profitability gain from providing HI is smaller for firms employing undocumented workers. This formally motivates Section 7.

**Section 4.1 (line 331):** "The data comes from the AG DATA from Aaron Smith." — this informal attribution should be replaced with a proper footnote citation (website + access date).

**Table 1:** The table caption says "The graphs show the coefficient estimates" — this is incorrect; Table 1 is a regression table, not graphs. Fix caption.

**Section 6 (line 408):** "In our data, a uniform upward shift in daily maximum temperatures generates approximately a one percentage-point increase in the share of extremely hot days (37–50°C)." This claim needs a citation or derivation. How was this calculated?

**Section 6.2 (line 483):** County-specific linear time trends are described as a robustness check but no standalone figure is presented—results are buried in Figure \ref{mainresultdiffe} without being discussed in the text with any numerical specifics. Describe what changes and what stays the same.

**Section 7 (line 563):** "employers still can offer alternative assistance such as health care stipends and paying for a portion of medical expenses" — this claim cites a Pennsylvania State University agricultural extension document. A peer-reviewed or government source would be more appropriate for a journal submission.

---

## Summary Statistics

| Dimension | Rating (1–5) |
|-----------|-------------|
| Argument Structure | 3 |
| Identification | 2 |
| Econometrics | 3 |
| Literature | 4 |
| Writing | 3 |
| Presentation | 2 |
| **Overall** | **3** |

---

## Round 1 Finding Summary (for loop convergence tracking)

| ID | Type | Location | Status |
|----|------|----------|--------|
| MC1 | MAJOR | Methods / Robustness | OPEN |
| MC2 | MAJOR | Results / Conclusion | OPEN |
| MC3 | MAJOR | Framework / Results | OPEN |
| MC4 | MAJOR | Data / Limitations | OPEN |
| MC5 | MAJOR | Section 7 | OPEN |
| mc1 | MINOR | Lines 106–138 | Fixable immediately |
| mc2 | MINOR | Line 168 | Needs author input (citation) |
| mc3 | MINOR | Lines 377/641/660 | Fixable immediately |
| mc4 | MINOR | Preamble | Fixable immediately |
| mc5 | MINOR | Line 373 | Fixable immediately |
| mc6 | MINOR | Data section | Needs author input |
| mc7 | MINOR | Various lines | Fixable immediately |
| mc8 | MINOR | Abstract | Fixable with author input |
| mc9 | MINOR | Line 175 | Fixable immediately |
| mc10 | MINOR | Appendix captions | Fixable immediately |
| RO1 | FATAL | Methods | OPEN |
| RO2 | FATAL | Data | OPEN |
| RO3 | FATAL | Framework / Results | OPEN |
| RO4 | ADDRESSABLE | Results | OPEN |
| RO5 | ADDRESSABLE | Results | OPEN |

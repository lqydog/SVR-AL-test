# 给 Codex 的任务 Prompt（MATLAB / Windows / Codex CLI）
> 目标：让你生成一个**可直接运行的 MATLAB 工程**（含 roadmap、模块化代码、自动化测试、PNG 可视化输出、以及 Windows CMD 下一键调用 MATLAB 的 CI 脚本）。
开始编码前请读取 docs/spec.md 作为参考与自检清单；如与本 prompt 有冲突，以本 prompt 为准
---

## 1. 总目标与约束（必须满足）

### 1.1 总目标
构建一个面向工程可靠度分析与 RBDO 的 surrogate 建模框架：
- 用 **RBF-SVR** 拟合极限状态函数 **g(x)**；
- 用 **pool-based active learning** 在固定候选池中迭代选点（**单点迭代**，非 batch）；
- surrogate 需要在全局范围内 **LSF（g=0）附近精度高**（RBDO 解通常靠近 LSF）。

### 1.2 强约束
- 维度：`d < 10`；真实查询（FEM/黑盒）预算：`Nmax <= 100`。
- 主动学习：**pool-based**：训练前生成固定 `pool`，后续新点只能从 `pool` 里选；**单点迭代**。
- 平台：**MATLAB R2021b+**，依赖 **Statistics and Machine Learning Toolbox**（`fitrsvm / lhsdesign / kmeans / pdist2`）。
- 调参：每轮新增样本后都要用 `fitrsvm(...,'OptimizeHyperparameters','auto')` 做 **Bayesian Optimization + 10-fold CV**；`MaxObjectiveEvaluations` 可配置。
- 不确定度：SVR 不输出方差，用 **bootstrap M=20** 仅估计 `σ(x)`；点预测 **始终来自主模型** `modelMain`。
- 采样准则（二选一，均需实现并可配置切换）：
  - **A1 = |ĝ(x)| / (d(x)+εd)**（靠近 LSF + 分散）
  - **Uboot = |ĝ(x)| / (σ(x)+εσ)**（仿 U-function）
- 停止：达到 `Nmax` 或 `P_f` 收敛（相对变化 < `eta` 且连续 `Kconsec` 次）。

---

## 2. 强制新增要求：所有可视化必须保存为 PNG

1) 工程必须创建输出目录：`outputs/`（若不存在自动创建）。  
2) 所有 demo/脚本/端到端流程里的图必须保存为 **PNG**（不能只显示 figure，也不能只保存为 `.fig/.pdf`）。  
3) 保存方式统一（MATLAB R2021b+ 推荐）：
   - 优先 `exportgraphics(fig, pngPath, "Resolution", dpi);`
   - fallback：`saveas(fig, pngPath);`
4) 封装成 `src/utils/saveFigurePng.m`，并确保无 GUI 环境也能工作。
5) 端到端测试必须检查 PNG 文件存在且文件大小 > 0 bytes。

---

## 3. 你需要交付的内容（必须全部给出）

### 3.1 Roadmap（写在 README 顶部）
给出分阶段路线图（每阶段：目标、关键产出、验收标准、风险点与应对）。至少包含：
1) 项目骨架与配置系统  
2) 归一化模块  
3) pool 生成模块  
4) 初始 DOE（k-means 投影到 pool）  
5) SVR 主模型训练 + BayesOpt(10-fold)  
6) bootstrap σ(x)  
7) 主动学习选点（A1 / Uboot）  
8) Pf 收敛与日志/模型持久化  
9) 2D 解析 demo + PNG 可视化输出  
10) 单元测试与回归测试  
11) Windows CMD 下本地 MATLAB 一键执行（tools/ 脚本）  

### 3.2 工程代码（可直接运行）
请按以下目录结构生成（可微调，但必须保持职责清晰、可扩展）。**注意：采用方案 A：`scripts/`、`tests/`、`tools/` 在项目根目录**，这样 `runtests("tests")` 与脚本路径天然一致。

```text
svr_active_learning/
  README.md
  ARCHITECTURE.md
  outputs/                   # 运行时生成（若不存在则创建）
  src/
    config/
      defaultOptions.m
    core/
      runActiveLearning.m
      computePfHat.m
      stopCriteria.m
      selectNextPoint.m
      kmeansDoeFromPool.m
    model/
      trainSvrMain.m
      trainBootstrapSigma.m
      predictMainAndSigmaOnPool.m
    sampling/
      buildPoolTruncInvLhs.m
    norm/
      fitNormModel.m
      applyMinMax01.m
      applyZScore.m
      applyNormForSvrTrain.m
      applyNormForSvrPredict.m
    problems/
      gfun2d_analytic.m
      make2dNormalProblem.m
    utils/
      setRng.m
      saveFigurePng.m
      assertNoDuplicates.m
      ismemberRowsTol.m
  scripts/
    demo2d_analytic.m
  tests/
    TestNormalization.m
    TestPool.m
    TestDOE.m
    TestAcquisition.m
    TestStopCriteria.m
    TestEndToEnd2D.m
  tools/
    run_ci.m
    verify_outputs.m
    run_matlab_tests.bat
```

### 3.3 自动化测试（必须能一键运行）
- 使用 `matlab.unittest.TestCase`；在项目根目录执行 `runtests("tests")` 可跑全部测试。
- 测试必须快：测试配置可缩小 `Npool`（如 200~1000）、`bayesoptMaxEvals`（如 5）、`bootstrapM`（如 5）；但默认实现仍应为 `bootstrapM=20`。
- 端到端测试：至少保证 `scripts/demo2d_analytic.m` 在小预算下能跑通、输出文件存在、关键字段齐全。

### 3.4 必须交付一份架构说明文件（新增需求）
你必须生成 `ARCHITECTURE.md`，内容至少包含：
- 项目总体架构图（用 Markdown 文字/ASCII/mermaid 均可）
- 每个顶层目录（src/scripts/tests/tools/outputs）的职责
- `src/` 下每个模块（norm/sampling/model/core/utils/problems）的职责、关键输入输出
- 每个脚本/工具文件的用途与调用方式（尤其是 `tools/run_ci.m`、`tools/run_matlab_tests.bat`）
- 数据流说明：Xpool → DOE → 训练 → bootstrap → acquisition → 新采样 → Pf 收敛

---

## 4. 关键算法实现要求（必须按此实现）

### 4.1 两层归一化
1) **min-max 到 [0,1]^d**：用于 pool、距离、kmeans、可视化。  
2) **z-score 标准化**：SVR 训练/预测用；`mu,sigma` 必须由**当前训练集**估计，并用于候选池预测，避免泄漏。  

实现 `normModel = struct('lb',lb,'ub',ub,'mu',mu,'sigma',sigma)`，并提供：
- `fitNormModel(Xtrain, lb, ub) -> normModel`
- `applyMinMax01(X, normModel)` / `applyZScore(X, normModel)`
- `applyNormForSvrTrain` 与 `applyNormForSvrPredict`（明确区分，确保不会用到 pool 的统计量）

### 4.2 pool 生成：截断逆变换 + LHS
- 截断概率 `alpha = 0.001`；`Pmin = alpha/2, Pmax = 1-alpha/2`。  
- 每维：先 LHS 得到 `r in [0,1]`，缩放到 `[Pmin,Pmax]` 得 `u`，再 `x = F^{-1}(u)`（用 `icdf`）。  
- 输出：
  - `Xpool`（物理空间）
  - `lb, ub`（每维 `icdf(Pmin/Pmax)` 作为增广区间边界）
  - `Xpool01 = applyMinMax01(Xpool, normModel)`（用于距离与 kmeans）

### 4.3 初始 DOE：k-means 从 pool 中选点并投影回 pool
- 在 `[0,1]^d` 上对 `Xpool01` 做 `kmeans(k=N0)`；
- 对每个簇中心，找最近的 pool 点作为 DOE；需要去重/替换。

### 4.4 SVR 主模型训练：每轮都 BayesOpt + 10-fold
- 每轮新增 1 个真实样本后，都要重新调参并训练主模型。  
- `fitrsvm` RBF 核；训练样本等权（不要传 Weights）。  
- `HyperparameterOptimizationOptions` 固定 `KFold=10`，并暴露 `MaxObjectiveEvaluations` 为配置。  
- 训练输入必须用 z-score 后的 `Xz`；输出主模型 `modelMain`，并保存本轮最佳超参（用于 bootstrap 复用）。

### 4.5 bootstrap 估计 σ(x)：仅用于不确定度
- 以训练集做 `M=20` 次 bootstrap 重采样训练子模型，得到 `σ(x) = std(ĝ^(m)(x))`。  
- 点预测 `ĝ(x)` 始终来自 `modelMain`；bootstrap 均值不用于点预测。  
- 工程优化：bootstrap 子模型复用主模型本轮超参，仅换重采样索引。

### 4.6 主动学习选点（实现 A1 与 Uboot）
候选集合 `C = pool \ sampled`。  

- 距离计算：在 `Xpool01` 空间对候选点到训练点求最近邻距离 `d(x)`（用 `pdist2` 向量化）。  
- 方案 A1：`A1 = |ĝ(x)| / (d(x)+eps_d)`，取最小者；并列用 `d(x)` 更大者破同分。  
- 方案 Uboot：`Uboot = |ĝ(x)| / (σ(x)+eps_sigma)`，取最小者；同样实现 tie-break。  
- 去重：必须剔除已采样点；可用“距离阈值”去掉过近点。

### 4.7 Pf 估计与停止
每轮在整个 pool 上用主模型预测，计算：
`PfHat = mean(ĝ(pool) <= 0)`。  

停止规则：
- `N_total >= Nmax` 立停；  
- 或 `|Pf(t)-Pf(t-1)|/max(Pf(t-1),1e-6) < eta` 且连续满足 `Kconsec` 次。

---

## 5. 二维解析 Demo（必须实现并作为端到端示例）

### 5.1 解析 LSF
实现：
`g(x1,x2)=sin(5*x1/2)+2 - ((x1^2+4)*(x2-1))/20`

随机变量：
- `x1 ~ N(1.5,1)`，`x2 ~ N(2.5,1)`，独立；失效 `g<=0`。

二维测试里，用该解析函数代替 FEM 调用；pool 仍按 `alpha=0.001` 生成。

### 5.2 demo 必须输出（scripts/demo2d_analytic.m）
1) `PfHat` 随 query 次数曲线（保存 `outputs/pf_curve_*.png`）  
2) 采样点分布 + 真/拟合 LSF 等值线对比（保存 `outputs/samples_lsf_*.png`）  
3) `.mat` 日志：采样序列、Pf 历史、`A1_min` 或 `Uboot_min` 历史（例如 `outputs/log_*.mat`）  
4) `outputs/model_final_*.mat`：最终 surrogate（含必要参数/结构）  

---

## 6. 配置项（必须集中管理且有默认值）
实现 `src/config/defaultOptions.m`，至少包含：
- `alpha = 0.001`
- `Npool`（demo 默认 1e4；测试可更小）
- `N0 = 20`
- `Nmax = 100`
- `acqMethod = "A1" | "Uboot"`
- `eps_d, eps_sigma`（默认 1e-12）
- `bootstrapM = 20`
- `eta`（默认 1e-2）与 `Kconsec = 3`
- `bayesoptMaxEvals`（默认 20~40；测试可更小）
- `rngSeed`（确保可复现）

---

## 7. 代码质量要求（必须遵守）
- 全部函数要有 `help` 头注释（用途/输入输出/示例）。  
- 关键计算要向量化（尤其是 pool 上预测与距离计算）。  
- 输入校验：维度一致、NaN/Inf、边界合法、重复点处理等。  
- 日志结构 `log` 清晰：`X_train, y_train, idx_doe, idx_al, PfHatHist, acqMinHist, options, normModel, hyperparamsHist(optional)`。  
- 随机数统一：入口 `setRng(seed)`，不要到处 `rng(...)`。  
- demo 生成图形时保存 PNG 后可 `close(fig)` 释放资源。  

---

## 8. Windows / Codex CLI：本地 MATLAB 自动执行与自检（必须实现）

### 8.1 必须新增文件
- `tools/run_ci.m`：统一入口脚本，负责：
  1) `cd` 到项目根目录（用 `fileparts(mfilename('fullpath'))` 向上定位）
  2) `addpath(genpath('src'))`
  3) `if ~exist('outputs','dir'), mkdir('outputs'); end`
  4) `results = runtests('tests');`
  5) 若存在失败用例，打印详细失败信息到控制台，并 `exit(1)`
  6) 运行 `scripts/demo2d_analytic.m`
  7) 调用 `tools/verify_outputs.m` 检查 outputs 下至少存在：
     - `pf_curve_*.png`、`samples_lsf_*.png`，且文件大小 > 0
     - `log_*.mat`、`model_final_*.mat`
  8) 全部通过后 `exit(0)`

- `tools/verify_outputs.m`：封装输出检查；失败则 `error("...")`（不要写成 `error(.)`）。

- `tools/run_matlab_tests.bat`（Windows CMD）：
  - 用 `matlab -batch` 调用 `tools/run_ci.m`
  - 把控制台输出重定向到 `outputs\test_log.txt`
  - 用 MATLAB 的退出码作为脚本退出码（CI/自动修复循环依赖这一点）

### 8.2 README 里必须写清运行方式
- 运行 demo：`matlab -batch "run('scripts/demo2d_analytic.m')"`
- 运行测试：`matlab -batch "results=runtests('tests'); disp(results); assert(all([results.Passed]));"`
- 一键 CI（推荐）：`tools\run_matlab_tests.bat`

---

## 9. 最终回答输出要求（对 Codex 的要求）
在你的最终回答中同时给出：
1) Roadmap（分阶段）  
2) 目录树 + 每个文件的职责说明（包含 tools 与 ARCHITECTURE.md）  
3) 所有文件的完整代码（按文件分段贴出，文件名作为标题）  
4) 运行说明（README 同步包含）：如何运行 demo 与 tests；PNG 输出位置与命名规则  

> 重要：请不要只给伪代码。我需要可以复制到本地就能运行的 MATLAB 代码与测试。

# 给 Codex 的任务 Prompt（MATLAB / Windows / Codex CLI / Fast+Full / 自动验收）
> 更新日期：2026-01-08  
> 目标：让你在 **Windows + Codex CLI** 环境下，生成/增量修改一个**可直接运行的 MATLAB 工程**：包含 roadmap、模块块化实现、自动化测试、PNG 可视化输出、以及 Windows CMD 下一键调用 MATLAB 的 **Fast/Full 两档 CI**，并在最后执行**自动验收**并把结果落盘。

> 开始编码前请读取 `docs/spec.md` 作为参考与自检清单；如与本 prompt 有冲突，以本 prompt 为准。

---

## 0. 工作模式（非常重要）

你可能面对两种情况：

### 0.1 新建工程（从零生成）
如果仓库/工程不存在：按本 prompt 的目录结构从零创建全部文件。

### 0.2 增量修改（推荐）
如果仓库已存在（例如你先前已按旧版 prompt 生成过工程）：  
**不得重写/推翻现有功能**，只允许做最小必要改动来满足新增需求。你必须：
- 先 `git status`（如果是 git 仓库）或列出目录树，确认现状；
- 只在需要的地方改动；
- 保持原有接口尽量不变，必要时通过兼容封装/新增可选参数实现；
- 修改后必须运行 Fast 与 Full 验证（见第 8、9 节）。

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

## 2. 强制要求：所有可视化必须保存为 PNG

1) 工程必须创建输出目录：`outputs/`（若不存在自动创建）。  
2) 所有 demo/脚本/端到端流程里的图必须保存为 **PNG**（不能只显示 figure，也不能只保存为 `.fig/.pdf`）。  
3) 保存方式统一（MATLAB R2021b+ 推荐）：
   - 优先 `exportgraphics(fig, pngPath, "Resolution", dpi);`
   - fallback：`saveas(fig, pngPath);`
4) 封装成 `src/utils/saveFigurePng.m`，并确保无 GUI 环境也能工作。
5) 端到端验证必须检查 PNG 文件存在且文件大小 > 0 bytes。

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
10) 单元测试与回归测试（Fast/Full 两档）  
11) Windows CMD 下本地 MATLAB 一键执行（tools/ 脚本）  
12) 自动验收（运行脚本 + 保存验收报告到 outputs/）

### 3.2 工程目录结构（方案 A：scripts/tests/tools 在根目录）
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
    run_matlab_tests_fast.bat
    run_matlab_tests_full.bat
    run_matlab_tests.bat            # 兼容入口：默认等价 fast（可保留）
```

### 3.3 自动化测试（必须能一键运行，含 Fast 与 Full 两档）

- 使用 `matlab.unittest.TestCase`；在项目根目录执行 `runtests("tests")` 可跑全部测试。

#### Fast（默认用于开发/CI，必须快）
- Fast 模式允许缩小配置以保证测试快速完成：
  - `Npool`（如 200~1000）
  - `bayesoptMaxEvals`（如 5）
  - `bootstrapM`（如 5）
  - `Nmax`（如 10~30）
- Fast 目标：验证代码正确性、接口一致性、输出文件存在性（PNG/MAT），不强求数值最优。

#### Full（默认参数验证，必须实现并保存结果）
- Full 模式：按 `src/config/defaultOptions.m` 的**默认参数**运行端到端验证（例如 `Npool=1e4`、`bootstrapM=20`、`bayesoptMaxEvals=20~40`、`Nmax=100` 等以 defaultOptions 为准）。
- Full 必须：
  1) 运行全部单元测试（tests）
  2) 运行 demo（`scripts/demo2d_analytic.m`）
  3) 将测试结果与日志保存到 `outputs/`（见第 8 节 tools 要求）
  4) 生成可读报告：`outputs/test_report_full.html`（优先）或 `outputs/junit_full.xml`

- Fast/Full 的参数差异必须通过 `options` 注入实现：
  - Full：直接使用 `defaultOptions()` 返回的默认值；
  - Fast：在 Full 默认 options 基础上覆盖少量字段（如 `Npool`/`bayesoptMaxEvals`/`bootstrapM`/`Nmax`），不得改动算法逻辑。

### 3.4 必须交付一份架构说明文件
你必须生成 `ARCHITECTURE.md`，至少包含：
- 项目总体架构图（Markdown 文字/ASCII/mermaid 均可）
- 每个顶层目录（src/scripts/tests/tools/outputs）的职责
- `src/` 下每个模块（norm/sampling/model/core/utils/problems）的职责、关键输入输出
- 每个脚本/工具文件用途与调用方式（尤其 `tools/run_ci.m`、`tools/run_matlab_tests_fast.bat`、`tools/run_matlab_tests_full.bat`）
- 数据流说明：Xpool → DOE → 训练 → bootstrap → acquisition → 新采样 → Pf 收敛

---

## 4. 关键算法实现要求（必须按 spec.md + 本 prompt 实现）
（本节保持与你现有实现一致：两层归一化、pool 生成、kmeans DOE、每轮 BayesOpt+10fold、bootstrap σ、A1/Uboot、Pf 与停止准则等。）
> 具体算法条款请对照 `docs/spec.md` 自检；如与你实现冲突，修正实现。

---

## 5. 二维解析 Demo（必须实现并作为端到端示例）
- 解析 LSF：
  `g(x1,x2)=sin(5*x1/2)+2 - ((x1^2+4)*(x2-1))/20`
- 分布：`x1 ~ N(1.5,1)`，`x2 ~ N(2.5,1)`，独立；失效 `g<=0`。
- demo 输出（必须全部落盘到 outputs/）：
  - `pf_curve_*.png`
  - `samples_lsf_*.png`
  - `log_*.mat`
  - `model_final_*.mat`

---

## 6. 配置项（必须集中管理）
`src/config/defaultOptions.m` 至少包含：
- `alpha, Npool, N0, Nmax, acqMethod, eps_d, eps_sigma, bootstrapM, eta, Kconsec, bayesoptMaxEvals, rngSeed`
并保证可通过 options 注入覆盖（Fast 覆盖少量字段；Full 不覆盖）。

---

## 7. 代码质量要求（必须遵守）
- 全部函数带 `help` 头注释；关键计算向量化；输入校验；日志结构清晰；随机数统一入口 `setRng(seed)`。
- demo 保存 PNG 后可 `close(fig)` 释放资源。
- outputs 文件命名避免覆盖（建议带 run id 或时间戳）。

---

## 8. Windows / Codex CLI：本地 MATLAB 自动执行与自检（必须实现）

### 8.1 必须新增/修改的文件
- `tools/run_ci.m`：统一入口脚本，支持 `mode` 参数：`"fast"` 或 `"full"`。
  - `run_ci("fast")`：
    1) 定位项目根目录并 `addpath(genpath('src'))`
    2) 确保 `outputs/` 存在
    3) 运行 tests（Fast 配置）
    4) 运行 demo（Fast 配置）
    5) 调用 `tools/verify_outputs.m`
    6) 保存结果：
       - `outputs/test_results_fast.mat`
       - `outputs/test_log_fast.txt`（用 `diary`）
    7) 失败 `exit(1)`；成功 `exit(0)`。

  - `run_ci("full")`：
    1) 定位项目根目录并 `addpath(genpath('src'))`
    2) 确保 `outputs/` 存在
    3) 按 defaultOptions 默认参数运行 tests + demo（不得覆盖缩小参数）
    4) 调用 `tools/verify_outputs.m`
    5) 保存结果：
       - `outputs/test_results_full.mat`
       - `outputs/test_log_full.txt`
       - `outputs/test_report_full.html`（优先）或 `outputs/junit_full.xml`
    6) 失败 `exit(1)`；成功 `exit(0)`。

- `tools/verify_outputs.m`：封装输出检查；失败 `error("...")`。必须区分 fast/full 所需产物。
- `tools/run_matlab_tests_fast.bat`：调用 `matlab -batch` 执行 `run_ci('fast')`，重定向日志，透传退出码。
- `tools/run_matlab_tests_full.bat`：调用 `matlab -batch` 执行 `run_ci('full')`，重定向日志，透传退出码。
- `tools/run_matlab_tests.bat`（可选兼容）：默认等价 fast。

### 8.2 README 必须写清运行方式
- Fast CI：`tools\run_matlab_tests_fast.bat`
- Full CI：`tools\run_matlab_tests_full.bat`
- 单独 demo：`matlab -batch "run('scripts/demo2d_analytic.m')"`
- 单独 tests：`matlab -batch "results=runtests('tests'); disp(results); assert(all([results.Passed]));"`

---

## 9. 自动验收与结果落盘（必须执行并保存）

你必须在完成代码修改后，**在本地实际执行验收**，而不是只给出“修改总结”。验收顺序：

1) 执行 Fast：`tools\run_matlab_tests_fast.bat`  
2) Fast 通过后执行 Full：`tools\run_matlab_tests_full.bat`

### 9.1 必须在回复中贴出（验收回传）
每次运行后都要在回复里提供：
- CMD 退出码（ERRORLEVEL）
- 对应日志文件末尾 80 行：
  - `outputs\test_log_fast.txt` 或 `outputs\test_log_full.txt`
- `dir outputs` 的文件列表（至少列出新生成文件）

若失败：你必须基于日志定位原因、修复代码，并自动重跑，直到 Fast 与 Full 都通过。

### 9.2 必须保存验收报告到 outputs/
你必须生成一个验收报告文件，例如：
- `outputs/acceptance_summary.md`（或带时间戳），内容至少包含：
  - Fast/Full 运行时间、退出码
  - 产物清单（png/mat/report）
  - 关键配置快照（Fast 覆盖项、Full 默认项）
  - 若有失败与重试，记录重试次数与最终状态
并在最后一次回复中指明该文件路径。

---

## 10. 最终回答输出要求（对 Codex 的要求）
在最终回复中同时给出：
1) Roadmap（分阶段）  
2) 目录树 + 每个文件职责说明（包含 tools 与 ARCHITECTURE.md）  
3) 变更点总结（若是增量修改：列出新增/修改文件）  
4) 验收结果回传（按第 9 节要求）  

> 注意：推送到 GitHub / 发布到指定页面属于单独任务，除非我在后续消息里明确要求，否则不要自动执行 git push。

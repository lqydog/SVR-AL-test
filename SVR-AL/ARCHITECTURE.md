# Architecture

## Data Flow（核心数据流）
1) `problems/*` 定义随机变量分布与显式/隐式 LSF：`g(x)`
2) `sampling/buildPoolTruncInvLhs` 生成固定 `Xpool`
3) `core/kmeansDoeFromPool` 从 pool 选初始 DOE（返回 pool 索引）
4) `core/runActiveLearning` 迭代：
   - 归一化：`norm/*`（pool 距离计算在 `[0,1]^d`，SVR 训练/预测用 z-score）
   - 主模型：`model/trainSvrMain`（BayesOpt + 10-fold CV）
   - 不确定度：`model/trainBootstrapSigma`（bootstrap 子模型）
   - 采样准则：`core/selectNextPoint`（A1 / Uboot）
   - Pf：`core/computePfHat`（在整个 pool 上评估）
5) `scripts/demo2d_analytic.m` 生成可视化与落盘
6) `tools/run_ci.m` 负责 Fast/Full 自动执行与落盘；`tools/verify_outputs.m` 检查产物

## Key Conventions（关键约定）
- 所有新增样本只能从 `Xpool` 中选取（pool-based）
- 单点迭代：每轮只新增 1 个样本
- 采样准则以“最小化 score”为选点规则（越接近 LSF 且越值得采样）
- 图像统一通过 `src/utils/saveFigurePng.m` 保存为 PNG


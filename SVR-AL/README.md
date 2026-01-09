# SVR + Active Learning（pool-based）用于 LSF 拟合 / 可靠度分析

本工程按 `docs/spec.md` 与 `docs/prompt_new_complete.md` 从零实现：
- RBF-SVR（`fitrsvm`）拟合极限状态函数 `g(x)`
- pool-based active learning（固定候选池、单点迭代）
- 两种采样准则可切换：`A1` / `Uboot`
- 每轮新增样本后：BayesOpt + 固定 10-fold CV 重新调参并训练主模型
- SVR 不确定度：bootstrap 集成估计 `σ(x)`，点预测始终来自主模型
- 2D 解析 demo：保存 PNG/日志/模型到 `outputs/`
- Windows 一键 Fast/Full CI：`tools/`

## 依赖说明
- 若安装了 Statistics and Machine Learning Toolbox：将优先使用 `fitrsvm / lhsdesign / kmeans / pdist2 / makedist / icdf`。
- 若未安装：将自动使用 `src/compat/*` 的兼容实现（保证工程可运行）。

## Roadmap（分阶段）
1) 骨架与配置：`src/config/defaultOptions.m` + 目录结构；验收：能被 `matlab -batch` 调用
2) 归一化模块：min-max→`[0,1]^d` + z-score；验收：单测通过、无 NaN/Inf
3) pool 生成：截断逆变换 + LHS；验收：维度/边界/统计检查通过
4) 初始 DOE：k-means（归一化空间）+ 投影回 pool 点 + 去重；验收：DOE 点唯一且来自 pool
5) 主模型训练：RBF-SVR + BayesOpt(10-fold)；验收：训练/预测可运行、输出稳定
6) bootstrap σ(x)：M=20 估计不确定度；验收：σ(x) 非负且维度匹配
7) 主动学习选点：A1 / Uboot；验收：单点迭代、永远从 pool 选点、无重复
8) Pf 收敛与停止：在整个 pool 上估计 `P̂f`；验收：达到预算或收敛停止
9) 2D 解析 demo：曲线+采样+LSF 对比图；验收：PNG/日志/模型落盘
10) 测试与回归：Fast/Full 两档；验收：`tools/run_ci.m` 两档都通过
11) Windows 一键执行：`tools/*.bat`；验收：`ERRORLEVEL` 透传
12) 自动验收：输出 `outputs/acceptance_summary.md`；验收：包含 fast/full 关键记录与产物清单

## 运行方式
- Fast CI：`tools\run_matlab_tests_fast.bat`
- Full CI：`tools\run_matlab_tests_full.bat`
- 单独 demo：`matlab -batch "run('scripts/demo2d_analytic.m')"`
- 单独 tests：`matlab -batch "results=runtests('tests'); disp(results); assert(all([results.Passed]));"`

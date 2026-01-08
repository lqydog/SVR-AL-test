# SVR + Adaptive Sampling（主动学习）用于可靠度分析/LSF 拟合技术方案（最新版）

> 约束与目标  
> - 随机变量维度：**d < 10**  
> - LSF：工程中 **隐式**（一次 query = 一次昂贵 FEM），测试阶段可用 **显式解析 LSF** 评估  
> - Query 预算：**FEM 调用次数 ≤ 100**  
> - 应用场景：训练后的 surrogate 将用于 **RBDO**，优化器全局选点，最终解几乎必然靠近 **LSF（g=0）**，因此要求 **全局范围内 LSF 附近精度都要高**  
> - 指定细节：超参数调优采用 **Bayesian Optimization + K-fold CV**；采样为 **单点迭代（非 batch）**；pool-based active learning

> **实现平台（MATLAB）**  
> - 本技术方案要求使用 **MATLAB** 完整实现（建议 R2021b 或更高版本）。  
> - 主要依赖：**Statistics and Machine Learning Toolbox**（`fitrsvm`、`kmeans`、`lhsdesign`、`pdist2` 等）。  
> - 文中出现的伪代码与函数接口均以 MATLAB 语法/函数名为准；中间结果与最终模型建议以 `*.mat` 形式保存。

---

## 1. 归一化

### 1.1 目的
- 统一尺度，避免某些维度因量纲差异主导核距离
- 保障距离型探索项（最近邻距离）有效
- 提升 SVR 数值稳定性，改善调参可靠性

### 1.2 两层归一化（推荐）
1) **物理边界缩放到 [0,1]^d**（用于 pool、距离计算、k-means、可视化）
\[
\tilde x_j = \frac{x_j-x_{j,\min}}{x_{j,\max}-x_{j,\min}}
\]

2) **SVR 训练用 z-score 标准化**（用于提升拟合稳定性）
\[
z_j=\frac{x_j-\mu_j}{s_j}
\]
- \(\mu_j,s_j\) 由 **当前训练集** 估计，并用于训练与候选池预测（避免数据泄漏与漂移）

> 实现建议：维护 `normModel = struct('lb',lb,'ub',ub,'mu',mu,'sigma',sigma)`；统一用于 `normalize(X,'unit')` 与 `normalize(X,'zscore')`。

---

## 2. pool（候选池）

### 2.1 目标
采用 **pool-based active learning**：训练开始前生成固定候选池 `pool`，后续所有新增样本从 `pool` 中挑选。  
要求同时满足：
- **概率域合理**（体现随机变量分布与截断）
- **空间填充性好**（全局覆盖，减少空洞）
- 面向 RBDO：避免只在高概率区拟合好，低概率但优化器可能访问区域拟合差

### 2.2 假设
- 随机变量之间 **独立**（已确认）

### 2.3 候选池生成：截断逆变换采样（Truncated Inverse Transform Sampling）+ LHS
对每一维随机变量 \(X_j\)：

a) **确定概率边界（基于截断概率 \(\alpha\) 的增广区间 / augmented space）**  
对每一维随机变量 \(X_j\)，给定**截断概率**（区间外概率质量，双侧尾部总和）\(\alpha_j\)。本文默认各维采用相同截断概率：
\[
\alpha_j=\alpha=0.001
\]
则该维在 CDF 空间的截断边界为：
\[
P_{j,\min}=\alpha/2,\quad P_{j,\max}=1-\alpha/2
\]
对应到物理空间（或该维的真实变量空间）的增广区间为：
\[
x_{j,\min}=F_j^{-1}(P_{j,\min}),\quad x_{j,\max}=F_j^{-1}(P_{j,\max})
\]
当 \(\alpha=0.001\) 时，有 \(P_{j,\min}=0.0005,\;P_{j,\max}=0.9995\)，即该维区间外概率质量为 0.001。

> 说明：这里的“0.001”描述的是**原始分布**在增广区间外的概率质量（coverage = \(1-\alpha\)）。采用截断逆变换生成的 `pool_prob` 会**仅在该增广区间内取样**，因此在 `pool_prob` 中“落在区间外的样本比例”理论上为 0（这是截断采样的定义）。



b) **LHS 采样并缩放**
- 在 \([0,1]\) 上用 LHS 生成 \(r_{ij}\)
- 缩放到 \([P_{j,\min},P_{j,\max}]\)
\[
u_{ij}=P_{j,\min}+(P_{j,\max}-P_{j,\min})r_{ij}
\]

c) **逆映射**
\[
x_{ij}=F_j^{-1}(u_{ij})
\]

得到 `Xpool ∈ R^(Npool×d)`。

### 2.4 pool规模建议
- 2D 解析测试：`Npool = 1e4 ~ 5e4`
- d<10：`Npool = 1e4` 通常足够  
pool 只耗 CPU，不增加 FEM 次数。


## 3. 初始DOE

### 3.1 目标
在 pool-based 前提下选取 \(N_0\) 个初始样本，使其全局覆盖性好，降低早期模型失真风险。

### 3.2 方法：k-means 从 pool 中选 DOE（已确认）
1) 将 pool 映射到 \([0,1]^d\)
2) 在归一化空间对 pool 进行 `kmeans(k=N0)`
3) **投影回 pool 点**：对每个簇中心取最近的 pool 点  
\[
x_k^{DOE}=\arg\min_{x\in pool}\|x-c_k\|
\]
4) 去重与替换（次近邻/再次搜索）

### 3.3 初始样本数建议
- 推荐 \(N_0=20\)（预算100时稳）
- 若问题极平滑可取 15，但不建议更小

---

## 4. SVR训练（SVR + bootstrap 集成）

### 4.1 模型
- 使用 `fitrsvm` 的 RBF 核 SVR 进行回归，拟合 \(g(x)\)
- 预测输出为 \(\hat g(x)\)

### 4.2 训练样本等权（不加权SVR）
本方案不对训练样本设置差异化权重，对所有训练样本采用相同权重：
\[
w_i \equiv 1,\quad i=1,\dots,N
\]
实现上，MATLAB 训练 SVR 时不再传入 `'Weights'` 参数（或等价地传入全 1 向量）。  
LSF 附近精度的提升主要由第6章的采样准则持续将新样本推向 \(g(x)\approx 0\) 的区域来实现。

### 4.3 不确定度估计：bootstrap 仅用于 \(\sigma(x)\)
由于 SVR 不直接输出预测方差，采用 bootstrap 集成**仅用于不确定性度量**，点预测由“每轮调参后的主模型”负责：

- **主模型（点预测）**：每轮新增 1 个样本并完成第5章调参后，得到主 SVR 模型 \(f_{\text{main}}\)。其预测记为  
\[
\hat g(x)=f_{\text{main}}(x)
\]
- **bootstrap（不确定度）**：对训练集进行 \(M=20\) 次 bootstrap 重采样，训练 \(M\) 个子模型 \(\hat g^{(m)}(x)\)。以子模型预测的离散程度刻画不确定性：  
\[
\bar g(x)=\frac{1}{M}\sum_{m=1}^M \hat g^{(m)}(x),\quad
\sigma(x)=\sqrt{\frac{1}{M-1}\sum_{m=1}^M\left(\hat g^{(m)}(x)-\bar g(x)\right)^2}
\]
其中 \(\bar g(x)\) **仅用于计算** \(\sigma(x)\)，最终 surrogate 的点预测始终使用主模型 \(\hat g(x)\)。

> 工程建议：bootstrap 子模型可复用主模型本轮选出的超参（\(C,\epsilon,\gamma/KernelScale\)），仅改变训练样本的重采样，以降低每轮计算开销并保持不确定度口径一致。

---


## 5. 调参策略（BayesOpt + K折CV）

### 5.1 超参集合
- \(C\)（BoxConstraint）、\(\epsilon\)、\(\gamma\)（或 KernelScale）
- 推荐在 log 空间搜索（logC/logEps/logGamma）

### 5.2 调参路径（MATLAB 内置贝叶斯优化，固定10折CV）
采用 MATLAB `fitrsvm` 内置超参优化（Bayesian Optimization + **10-fold CV**）：
- `fitrsvm(...,'OptimizeHyperparameters','auto')`
- 内部通过 **10 折交叉验证** 选择 \((C,\epsilon,\gamma/KernelScale)\)

> 工程实现：通过 `HyperparameterOptimizationOptions` 固定 `KFold=10`，并设置 `MaxObjectiveEvaluations`（例如 20–40）以控制每轮调参开销与稳定性。

### 5.3 调参频率（每次新增点均调参）
由于训练集每轮都会新增 1 个真实 FEM 样本点，最优超参可能随数据分布变化而漂移。本方案采用“**每轮新增点后都重新调参**”的策略：
- 迭代流程：新增样本 → 重新执行 `fitrsvm(...,'OptimizeHyperparameters','auto')` → 更新 surrogate
- 若计算预算紧张，可适当降低 `MaxObjectiveEvaluations`，但仍保持“每轮必调”的一致流程。

---


## 6. 采样准则（两种方案均需实现，可切换/可对比）

> 要求：6.2 与 6.3 两种采样准则都必须在代码中实现。每次运行必须通过配置指定使用哪一种方案，并在所有输出（图、日志、模型文件）中注明本次结果对应的方案。


### 6.1 记号与候选集
- 当前训练集：\(\mathcal{D}=\{(x_i,g_i)\}_{i=1}^{N}\)
- 候选池：`pool`（固定）
- 本轮候选集合（排除已采样点）：
\[
\mathcal{C}=pool\setminus \{x_i\}_{i=1}^{N}
\]
- surrogate 预测：点预测使用主模型 \(\hat g(x)\)，不确定度 \(\sigma(x)\) 由 bootstrap 集成给出（见 4.3）。

> 距离计算空间：为保证各维尺度一致，最近邻距离统一在 \([0,1]^d\) 的 min-max 归一化空间（记为 \(\tilde x\)）上计算欧氏距离。

### 6.1.1 方案选择与接口（新增）
- 在实现中必须提供一个配置项（例如 `acqMethod`），取值：
  - `A1`：对应 6.2 的 |g|/d 准则
  - `Uboot`：对应 6.3 的 bootstrap-U 准则
- 所有“选点/迭代日志/图形输出/模型保存”必须记录并输出该配置值，确保可追溯。


### 6.2 方案一：\(|g|/d\)（靠近 LSF + 空间分散）
对任意候选点 \(x\in\mathcal{C}\)，定义其到训练集的最近邻距离（欧氏距离）：
\[
d(x)=\min_{x_i\in \mathcal{D}} \|\tilde x-\tilde x_i\|
\]
并定义采样评分：
\[
A_1(x)=\frac{|\hat g(x)|}{d(x)+\epsilon_d}
\]
其中 \(\epsilon_d>0\) 为数值稳定项（避免极小距离导致除零，推荐 \(\epsilon_d=10^{-12}\sim 10^{-9}\)）。

**选点规则（单点迭代）：**
\[
x_{\text{new}}=\arg\min_{x\in\mathcal{C}} A_1(x)
\]
直观解释：\(|\hat g(x)|\) 越小越接近 LSF，\(d(x)\) 越大越“远离已采样点”，因此该准则实现“靠近边界 + 避免重复聚集”。

### 6.3 方案二：Bootstrap-\(U\)（仿 U-function 形式）
对任意候选点 \(x\in\mathcal{C}\)，定义：
\[
U_{\text{boot}}(x)=\frac{|\hat g(x)|}{\sigma(x)+\epsilon_\sigma}
\]
其中 \(\sigma(x)\) 来自 bootstrap 集成，\(\epsilon_\sigma>0\) 为数值稳定项（推荐 \(\epsilon_\sigma=10^{-12}\sim 10^{-9}\)，或设为当前 \(\sigma\) 的极小分位数下界）。

**选点规则（单点迭代）：**
\[
x_{\text{new}}=\arg\min_{x\in\mathcal{C}} U_{\text{boot}}(x)
\]
直观解释：优先采样“可能在边界附近（\(|\mu|\) 小）且模型最不确定（\(\sigma\) 大）”的点。

### 6.4 去重与边界情况处理（两种方案通用）
1) **排除已采样点**：从 \(\mathcal{C}\) 中移除训练集中已出现的点；或将与训练集最近邻距离 \(d(x)\) 小于阈值的点剔除。  
2) **并列解处理（tie-break）**：若多个点的评分极接近，可优先选择 \(d(x)\) 更大的点以提升覆盖性。  
3) **数值稳定**：\(\epsilon_d,\epsilon_\sigma\) 仅用于防止除零，不应主导评分，建议固定为很小常数或采用分位数下界。

### 6.5 结果标注与可追溯性（新增，强制）
每次运行必须在以下位置注明本次采样方案（`A1` 或 `Uboot`）：

1) **输出文件名必须带方案标识**
- `pf_curve_<METHOD>.png`（例如 `pf_curve_A1.png` / `pf_curve_Uboot.png`）
- `samples_lsf_<METHOD>.png`
- `log_<METHOD>.mat`
- `model_final_<METHOD>.mat`

2) **图中必须标注**
- 图标题或角标写明：`Acquisition: A1` 或 `Acquisition: Uboot`

3) **日志 .mat 必须包含字段**
- `log.acqMethod`：字符串（`"A1"` 或 `"Uboot"`）
- `log.scoreName`：例如 `"A1"` / `"Uboot"`
- `log.scoreMinHistory`：每轮最小评分历史（对应 `A1_min(t)` 或 `Uboot_min(t)`）
- 其他已有字段保持不变（采样序列、Pf 历史等）

---


## 7. 停止准则

### 7.1 预算封顶
- FEM query 次数达到 `Nmax=100` 立即停止

### 7.2 失效概率 \(\hat P_f\) 收敛（在整个 pool 上评估）
每轮迭代在**整个候选池** `pool` 上，用当前最新训练好的**主模型**对每个点进行预测，得到 \(\hat g_t(x)\)。  
将 \(\hat g_t(x)\le 0\) 的点判定为失效点，则失效概率估计为：
\[
\hat P_f^{(t)}=\frac{1}{N_{pool}}\sum_{x\in pool}\mathbb{I}(\hat g_t(x)\le 0)
=\frac{\#\{x\in pool: \hat g_t(x)\le 0\}}{N_{pool}}
\]
停止条件（相对变化）：
\[
\frac{|\hat P_f^{(t)}-\hat P_f^{(t-1)}|}{\max(\hat P_f^{(t-1)},10^{-6})}<\eta
\]
- \(\eta\) 推荐 `1e-2 ~ 5e-3`
- 连续满足 `K=3` 次才停止（防抖）

---



## 9. 二维解析测试输出

> 本章仅用于 **二维显式解析 LSF** 的方法验证与可视化；工程隐式 LSF（FEM）场景可跳过图形输出，只保留数值日志与模型保存。

### 9.1 测试函数（显式解析）
用于验证的二维显式 LSF 取：
\[
g(x_1,x_2)=\sin\left(\frac{5x_1}{2}\right)+2-\frac{(x_1^2+4)(x_2-1)}{20}
\]
随机变量为两个独立正态变量：
\[
x_1\sim\mathcal{N}(1.5,1),\quad x_2\sim\mathcal{N}(2.5,1)
\]
其中 \(\mathcal{N}(\mu,\sigma)\) 表示均值为 \(\mu\)、标准差为 \(\sigma\) 的正态分布。失效判据为 \(g(x_1,x_2)\le 0\)。

> 二维测试时，FEM/黑盒调用由上述解析函数直接计算 \(g\) 值替代；候选池 `pool` 仍按第2章基于截断概率 \(\alpha=0.001\) 的截断逆变换 + LHS 生成。

### 9.2 必须输出
1) **失效概率估计的收敛**
- \(\hat P_f\) vs query 次数曲线  
- 其中每轮 \(\hat P_f\) 均按 7.2 的规则：在**整个 pool** 上用当前 surrogate 预测并统计 \(\hat g(x)\le 0\) 的比例。

2) **最终总 query 次数**
- `N_total`（以及可选：`N_DOE`, `N_AL`）

3) **二维采样点分布与 LSF 形状可视化**
- **真实 LSF（解析）**：绘制真实 \(g(x)=0\) 等值线（用于对照）
- **surrogate LSF（收敛后）**：绘制收敛后 surrogate 主模型的 \(\hat g(x)=0\) 等值线，作为“拟合出来的 LSF 形状”
- 标出采样点（DOE 点与主动学习点可用不同标记），并叠加失效/安全区域示意（可选）

4) **迭代日志（必须注明方案）**
- 保存采样序列、\hat P_f 历史、以及采样准则对应的最优值历史：
  - 若本次运行方案为 A1：保存 `A1_min(t)`
  - 若本次运行方案为 Uboot：保存 `Uboot_min(t)`
- 日志文件名必须带方案标识：`log_<METHOD>.mat`
- 日志结构必须包含 `acqMethod` 字段（见 6.5）


5) **模型保存**
- `model_final.mat`：最终 surrogate（含 bootstrap 集成或其必要参数）

---


## 10. 执行顺序（主流程摘要）

1) 定义问题边界、分布与截断概率 \(\alpha=0.001\)；建立归一化映射  
2) 生成 `pool`（截断逆变换 + LHS；必要时可合并空间池以增强覆盖）  
3) 从 `pool` 用 k-means 选初始 DOE，执行 FEM/解析函数 query 得到初始 \(g\)  
4) 循环（单点迭代）：  
   - 新增样本后：用 `fitrsvm(...,'OptimizeHyperparameters','auto')`（固定 **10 折 CV**）重新调参并训练**主模型**，得到点预测 \(\hat g(x)\)  
   - 基于训练集做 bootstrap 训练子模型，得到不确定度 \(\sigma(x)\)（点预测仍以主模型 \(\hat g(x)\) 为准）  
   - 在 `pool` 上预测 \hat g(x), \sigma(x)，按配置 `acqMethod` 计算评分并选点（A1 或 Uboot）。
   - 需要对比两种方案：在相同随机种子与相同初始 DOE 前提下分别跑两次（A1 与 Uboot），并按 6.5 规则分别输出与标注结果。
   - 执行 FEM/解析函数 query，更新训练集与日志  
   - 按第7章在整个 `pool` 上计算 \(\hat P_f\) 并判断停止  
5) 输出（二维测试场景）：采样点分布、真实 LSF 与 surrogate 主模型的 \(\hat g(x)=0\) 等值线、\(\hat P_f\) 收敛曲线；保存最终模型与日志

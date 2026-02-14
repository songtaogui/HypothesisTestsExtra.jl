
# API Reference {#API-Reference}

## Extra Hypothesis Tests {#Extra-Hypothesis-Tests}

Common statistical tests not present in the base `HypothesisTests.jl` package.

### Welch&#39;s ANOVA {#Welch's-ANOVA}
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.WelchANOVATest' href='#HypothesisTestsExtra.WelchANOVATest'><span class="jlbinding">HypothesisTestsExtra.WelchANOVATest</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
WelchANOVATest(groups)
WelchANOVATest(groups::AbstractVector{<:Real}...)
WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Welch&#39;s ANOVA test of the hypothesis that the `groups` means are equal. This test is an alternative to the standard One-Way ANOVA when the assumption of  equal variances (homoscedasticity) is violated.

The test statistic is approximately F-distributed.

Implements: [`pvalue`](@ref)

**Example**

```julia
# input arrays
WelchANOVATest(randn(10), randn(15).+1, randn(12).+2)

# input DataFrame
using StatsBase, DataFrames
cdf = DataFrame(A = sample(["G1","G2"], 100), B = sample(randn(10), 100))
WelchANOVATest(cdf, :A, :B)
```


**External links**
- [Welch&#39;s t-test and ANOVA on Wikipedia](https://en.wikipedia.org/wiki/Welch%27s_t-test)
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/NewTests/welchanova.jl#L7-L33" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### RxC Contingency Table Tests {#RxC-Contingency-Table-Tests}

Tests for independence in tables larger than 2x2.
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.FisherExactTestRxC' href='#HypothesisTestsExtra.FisherExactTestRxC'><span class="jlbinding">HypothesisTestsExtra.FisherExactTestRxC</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
FisherExactTestRxC(tbl::AbstractMatrix{<:Integer})
```


A smart constructor that acts as a drop-in replacement for Fisher&#39;s Exact Test.
- If `tbl` is **2x2**, it returns a standard `HypothesisTests.FisherExactTest` object  (calculating the exact p-value deterministically and supporting Odds Ratio CI).
  
- If `tbl` is **RxC** (where R&gt;2 or C&gt;2), it returns a `FisherExactTestMC` object  (estimating the p-value via Monte Carlo simulation).
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/NewTests/fisherrxc.jl#L24-L33" target="_blank" rel="noreferrer">source</a></Badge>



```julia
FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
```


Compute Fisher&#39;s Exact Test for general RxC tables from a raw DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L146-L150" target="_blank" rel="noreferrer">source</a></Badge>



```julia
FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
```


Compute Fisher&#39;s Exact Test (RxC) from aggregated frequency data.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L157-L161" target="_blank" rel="noreferrer">source</a></Badge>



```julia
FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
```


Compute Fisher&#39;s Exact Test for general RxC tables.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L121-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.FisherExactTestMC' href='#HypothesisTestsExtra.FisherExactTestMC'><span class="jlbinding">HypothesisTestsExtra.FisherExactTestMC</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
FisherExactTestMC(tbl::AbstractMatrix{<:Integer})
```


Internal struct for performing Monte Carlo Fisher&#39;s exact test on R x C tables. Users should generally use `FisherExactTestRxC` which automatically selects between this and the exact 2x2 test.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/NewTests/fisherrxc.jl#L5-L11" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Trend and Association Tests {#Trend-and-Association-Tests}

Tests designed for ordinal or linear relationships between categories.
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.CochranArmitageTest' href='#HypothesisTestsExtra.CochranArmitageTest'><span class="jlbinding">HypothesisTestsExtra.CochranArmitageTest</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
CochranArmitageTest(success, total; scores=:equidistant)
```


Perform the Cochran-Armitage test for trend in proportions. 

**Arguments**
- `success`: Vector of success counts for each level.
  
- `total`: Vector of total counts for each level.
  
- `scores`: `:equidistant` (default), `:midrank`, or a `Vector{Float64}`.
  

**Example**

```julia
success = [10, 15, 25]
total = [100, 100, 100]
test = CochranArmitageTest(success, total; scores=:equidistant)
pvalue(test)
confint(test) # Confidence interval for the slope
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/NewTests/trends.jl#L36-L54" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.JonckheereTerpstraTest' href='#HypothesisTestsExtra.JonckheereTerpstraTest'><span class="jlbinding">HypothesisTestsExtra.JonckheereTerpstraTest</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
JonckheereTerpstraTest(groups)
```


Perform the Jonckheere-Terpstra test for monotonic trend among k independent samples. Includes correction for ties in the data.

**Example**

```julia
g1 = [10, 12, 12, 14]
g2 = [13, 15, 15, 17]
g3 = [18, 20, 22, 22]
test = JonckheereTerpstraTest([g1, g2, g3])
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/NewTests/trends.jl#L113-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.LinearByLinearTest' href='#HypothesisTestsExtra.LinearByLinearTest'><span class="jlbinding">HypothesisTestsExtra.LinearByLinearTest</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
LinearByLinearTest(tbl; row_scores=:equidistant, col_scores=:equidistant)
```


Perform the Linear-by-Linear Association test for RxC contingency tables.

**Example**

```julia
tbl = [10 5 2; 3 8 12; 1 2 15]
test = LinearByLinearTest(tbl; row_scores=:midrank)
confint(test) # Confidence interval for Pearson correlation r
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/NewTests/trends.jl#L188-L199" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Post-Hoc Analysis {#Post-Hoc-Analysis}

Tools for following up on significant ANOVA or Chi-square results.

### Parametric &amp; Non-Parametric {#Parametric-and-Non-Parametric}

Pairwise comparisons for K-sample tests (e.g., Tukey, Dunn).
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.PostHocPar' href='#HypothesisTestsExtra.PostHocPar'><span class="jlbinding">HypothesisTestsExtra.PostHocPar</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
PostHocPar(groups; method=:tukey, alpha=0.05, alpha_levene=0.05, cld=false, pairs=nothing, row_labels=[])
```


Perform parametric post-hoc pairwise comparisons (Multiple Comparison Procedures) on a set of data groups.

**Arguments**
- `groups::AbstractVector{<:AbstractVector{<:Real}}`: A vector of vectors, where each inner vector contains the numerical observations for a specific group.
  

**Keyword Arguments**
- `method::Symbol`: The post-hoc algorithm to use. Defaults to `:tukey`. See the **Supported Methods** section below for details on each option.
  
- `alpha::Float64`: The significance level (Type I error rate) for the hypothesis tests and confidence intervals. Defaults to `0.05`.
  
- `alpha_levene::Float64`: The threshold used for the internal Levene&#39;s test. If the p-value of Levene&#39;s test is below this value, a warning is issued suggesting the data has unequal variances (heteroscedasticity) and recommending `:tamhane`. Defaults to `0.05`.
  
- `cld::Bool`: If `true`, generates Compact Letter Display (CLD) codes. Groups sharing the same letter are not significantly different. Defaults to `false`.
  
- `pairs`: An optional `Vector{Tuple{Int, Int}}` specifying a subset of group indices to compare (e.g., `[(1, 2), (1, 3)]`). If `nothing` (default), all possible pairwise combinations are tested.
  
- `row_labels`: Optional vector of strings to label the groups in the output. If empty, defaults to &quot;Group1&quot;, &quot;Group2&quot;, etc.
  

**Supported Methods**

The `method` argument accepts the following symbols:

**1. Equal Variance Assumed (Homoscedasticity):**
- `:tukey` (Default): **Tukey&#39;s HSD (Honest Significant Difference)**.   Based on the Studentized Range distribution. It controls the Family-Wise Error Rate (FWER) for all pairwise comparisons. It is the standard choice for balanced or slightly unbalanced designs.
  
- `:lsd`: **Fisher&#39;s LSD (Least Significant Difference)**.   Performs individual t-tests without FWER adjustment. It is the most powerful (least conservative) but carries a high risk of Type I errors (false positives) as the number of groups increases.
  
- `:bonferroni`: **Bonferroni Correction**.   Adjusts the significance level to `alpha / m` (where m is the number of tests). It is very conservative and strictly controls FWER, but often lacks power.
  
- `:sidak`: **Sidak Correction**.   Adjusts the significance level to `1 - (1 - alpha)^(1/m)`. It is slightly more powerful than Bonferroni while maintaining strict FWER control (assuming independence).
  
- `:scheffe`: **Scheffe&#39;s Method**.   Based on the F-distribution. It is designed to control FWER for _all possible_ linear contrasts, not just pairwise comparisons. Consequently, it is extremely conservative for simple pairwise tests.
  
- `:snk`: **Student-Newman-Keuls**.   A stepwise multiple range procedure. It adjusts the critical value based on the number of steps between means. It is less conservative than Tukey but does not strictly control FWER in the strong sense.
  
- `:duncan`: **Duncan&#39;s New Multiple Range Test**.   Similar to SNK but uses a more liberal protection level. It has higher power but a higher rate of Type I errors compared to SNK or Tukey.
  

**2. Unequal Variance Assumed (Heteroscedasticity):**
- `:tamhane`: **Tamhane&#39;s T2**.   Uses Welch&#39;s t-test (which adjusts degrees of freedom for unequal variances) combined with a Sidak-like multiplicative correction for the p-value. This is the recommended method when Levene&#39;s test is significant.
  

**Returns**

Returns a `PostHocTestResult` object containing detailed comparison statistics (diff, standard error, test statistic, critical value, p-value, confidence intervals) and CLD letters if requested.

**Example**

```julia
PostHocPar([randn(10), randn(10).+5, randn(10).+0.1]; cld = true, row_labels=["Control", "TreatA", "TreatB"])
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/posthoc.jl#L13-L59" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
```


Parametric post-hoc (e.g., Tukey).  Type requirements: `group_col` (Categorical), `data_col` (Numeric).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L23-L27" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
```


Perform parametric post-hoc pairwise comparisons (e.g., Tukey&#39;s HSD). Groups are defined by the `GroupedDataFrame` keys. Type requirements: `data_col` must be Numeric.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L27-L33" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.PostHocNonPar' href='#HypothesisTestsExtra.PostHocNonPar'><span class="jlbinding">HypothesisTestsExtra.PostHocNonPar</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
PostHocNonPar(groups; method=:dunn_bonferroni, alpha=0.05, cld=false, pairs=nothing, row_labels=[])
```


Perform non-parametric post-hoc pairwise comparisons on a set of data groups.  This function is typically used after a significant Kruskal-Wallis test to determine which specific groups differ. It operates on the **ranks** of the data rather than the raw values.

**Arguments**
- `groups::AbstractVector{<:AbstractVector{<:Real}}`: A vector of vectors, where each inner vector contains the numerical observations for a specific group.
  

**Keyword Arguments**
- `method::Symbol`: The post-hoc algorithm to use. Defaults to `:dunn_bonferroni`. See the **Supported Methods** section below for details.
  
- `alpha::Float64`: The significance level (Type I error rate). Defaults to `0.05`.
  
- `cld::Bool`: If `true`, generates Compact Letter Display (CLD) codes based on the rank comparisons. Groups sharing the same letter are not significantly different. Defaults to `false`.
  
- `pairs`: An optional `Vector{Tuple{Int, Int}}` specifying a subset of group indices to compare. If `nothing` (default), all possible pairwise combinations are tested.
  
- `row_labels`: Optional vector of strings to label the groups in the output. If empty, defaults to &quot;Group1&quot;, &quot;Group2&quot;, etc.
  

**Supported Methods**

The `method` argument accepts the following symbols. All methods automatically apply a tie correction factor to the standard error if ties are present in the data.

**1. Dunn&#39;s Test (Z-test based):** Dunn&#39;s test approximates the distribution of the difference in mean ranks using a normal distribution (Z-test). It allows for various p-value adjustment methods to control the Family-Wise Error Rate (FWER).
- `:dunn`: **Unadjusted Dunn&#39;s Test**.   Performs raw comparisons without correcting for multiple testing. High power but high risk of Type I errors (false positives).
  
- `:dunn_bonferroni` (Default): **Dunn&#39;s Test with Bonferroni Correction**.   Adjusts p-values by multiplying by the number of tests. Strict FWER control, conservative.
  
- `:dunn_sidak`: **Dunn&#39;s Test with Sidak Correction**.   Adjusts p-values using `1 - (1 - p)^m`. Slightly more powerful than Bonferroni while maintaining FWER control.
  

**2. Nemenyi Test (Studentized Range based):**
- `:nemenyi`: **Nemenyi Test**.   This is the non-parametric equivalent of Tukey&#39;s HSD. It uses the Studentized Range distribution (approximated with infinite degrees of freedom) to determine critical values. It controls FWER for all pairwise comparisons and is generally more conservative than Dunn&#39;s test, especially for large numbers of groups.
  

**Returns**

Returns a `PostHocTestResult` object containing detailed comparison statistics (diff in mean ranks, standard error, Z/Q statistic, critical value, p-value, confidence intervals) and CLD letters if requested.

**Example**

```julia
# 3 groups with different distributions
g1 = rand(10)
g2 = rand(10) .+ 2
g3 = rand(10) .+ 0.5

# Perform Dunn's test with Bonferroni correction and generate CLD letters
result = PostHocNonPar([g1, g2, g3]; method=:dunn_bonferroni, cld=true, row_labels=["Ctrl", "TrtA", "TrtB"])
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/posthoc.jl#L121-L167" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
```


Non-parametric post-hoc (e.g., Dunn).  Type requirements: `group_col` (Categorical), `data_col` (Numeric or Ordered).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L7-L11" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
```


Non-parametric post-hoc pairwise comparisons (e.g., Dunn&#39;s test). Groups are defined by the `GroupedDataFrame` keys. Type requirements: `data_col` must be Numeric or Ordered Categorical.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L7-L13" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Contingency Tables {#Contingency-Tables}

Post-hoc analysis for Chi-square or Fisher tests (e.g., row-wise comparisons or adjusted standardized residuals).
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.PostHocContingencyRow' href='#HypothesisTestsExtra.PostHocContingencyRow'><span class="jlbinding">HypothesisTestsExtra.PostHocContingencyRow</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
PostHocContingencyRow(table::AbstractMatrix{<:Integer}; method=:chisq, adjustment=:bonferroni, cld=false, alpha=0.05, pairs=nothing, row_labels=[])
```


Perform pairwise comparisons between rows of a contingency table to identify which groups differ significantly in their distribution across columns.

**Arguments**
- `table::AbstractMatrix{<:Integer}`: The RxC contingency table.
  

**Keyword Arguments**
- `method::Symbol`: The statistical test to use for pairwise comparisons.
  - `:chisq` (Default): Pearson&#39;s Chi-square test. Fast and standard for large samples.
    
  - `:fisher`: Fisher&#39;s Exact Test. 
    - For **2x2** sub-tables, it computes the exact p-value.
      
    - For **2xC** sub-tables (where C &gt; 2), it estimates the p-value via Monte Carlo simulation (see `FisherExactTestRxC`).
      
    
  
- `adjustment::Symbol`: The method to adjust p-values for multiple comparisons.
  - `:bonferroni`: Strong control of FWER (p * m).
    
  - `:bh` (or `:fdr`): Benjamini-Hochberg procedure for False Discovery Rate control.
    
  - `:none`: No adjustment.
    
  
- `alpha::Float64`: Significance level. Defaults to `0.05`.
  
- `cld::Bool`: If `true`, generates Compact Letter Display codes based on the proportion of the first column. Defaults to `false`.
  
- `pairs`: An optional `Vector{Tuple{Int, Int}}` specifying a subset of row indices to compare (e.g., `[(1, 2), (1, 3)]`). If `nothing` (default), all possible pairwise combinations are tested.
  
- `row_labels`: Optional vector of strings to label the rows in the output.
  

**Returns**

Returns a `PostHocTestResult` object containing comparison statistics and adjusted p-values.

**Example**

```julia
using HypothesisTests

# Data: 4 Groups (Rows) vs 3 Outcomes (Cols: Success, Neutral, Fail)
# Group 1 and 2 are similar, Group 3 is different, Group 4 is very different
table = [
    50 30 20; # Group 1
    48 32 20; # Group 2 (Similar to 1)
    20 40 40; # Group 3 (Different)
    10 10 80  # Group 4 (Very different)
]
row_labs = ["Grp1", "Grp2", "Grp3", "Grp4"]

# 1. Standard Pairwise Chi-Square with Bonferroni adjustment
# Also requesting Compact Letter Display (cld=true)
res_chisq = PostHocContingencyRow(table, method=:chisq, adjustment=:bonferroni, 
                                  cld=true, row_labels=row_labs)

# Inspect the Compact Letter Display (if generated)
# println(res_chisq.letters) 
# Expected: Grp1 and Grp2 might share a letter (e.g., "a"), Grp3 "b", Grp4 "c"

# 2. Pairwise Fisher's Exact Test (Robust for small counts and supports RxC)
# Only comparing Group 1 vs Group 4 and Group 1 vs Group 3
specific_pairs = [(1, 4), (1, 3)]
res_fisher = PostHocContingencyRow(table, method=:fisher, adjustment=:none,
                                   pairs=specific_pairs, row_labels=row_labs)

# Print p-values for the specific pairs
for cmp in res_fisher.comparisons
    println("Comparing $(row_labs[cmp.idx_a]) vs $(row_labs[cmp.idx_b]): p = $(cmp.p_val)")
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/posthoc.jl#L348-L409" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
```


Perform row-wise post-hoc comparisons (e.g., Chi-Sq or Fisher) on raw categorical data.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L36-L40" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform row-wise post-hoc comparisons on aggregated frequency data (Long format).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L60-L64" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform row-wise post-hoc comparisons. Rows are defined by `gd` groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L42-L47" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.PostHocContingencyCell' href='#HypothesisTestsExtra.PostHocContingencyCell'><span class="jlbinding">HypothesisTestsExtra.PostHocContingencyCell</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
PostHocContingencyCell(table::AbstractMatrix{<:Integer}; method=:asr, adjustment=:bonferroni, alpha=0.05, row_labels=[], col_labels=[])
```


Perform cell-level post-hoc analysis on a contingency table to identify specific cells that contribute significantly to the overall association.

**Arguments**
- `table`: RxC contingency table (Matrix of Integers).
  
- `method`: 
  - `:asr`: Adjusted Standardized Residuals. Tests if a cell deviates from independence.
    
  - `:fisher_1vsall`: Fisher&#39;s Exact Test for each cell (One vs Rest).
    
  
- `adjustment::Symbol`: The method to adjust p-values for multiple comparisons.
  - `:bonferroni`: Strong control of FWER (p * m).
    
  - `:bh` (or `:fdr`): Benjamini-Hochberg procedure for False Discovery Rate control.
    
  - `:none`: No adjustment.
    
  
- `row_labels`: Optional vector of strings for row names.
  
- `col_labels`: Optional vector of strings for column names.
  

**Returns**

A `ContingencyCellTestResult` object containing matrices for statistics, raw p-values, adjusted p-values, and significance flags.

**Examples**

```julia
using HypothesisTests, Distributions

# Create a 3x3 contingency table (e.g., 3 Age Groups vs 3 Preferences)
# Rows: Young, Middle, Old
# Cols: Option A, Option B, Option C
table = [
    30 10 10;  # Young mostly prefer A
    10 30 10;  # Middle mostly prefer B
    10 10 30   # Old mostly prefer C
]
r_labs = ["Young", "Middle", "Old"]
c_labs = ["Opt_A", "Opt_B", "Opt_C"]

# 1. Use Adjusted Standardized Residuals (ASR) with Bonferroni correction
res_asr = PostHocContingencyCell(table, method=:asr, adjustment=:bonferroni,
                                 row_labels=r_labs, col_labels=c_labs)

# Check the matrix of adjusted residuals (Z-scores)
# println(res_asr.stats_mat)

# Check which cells are significant (True/False matrix)
# println(res_asr.sig_mat)

# 2. Use One-vs-Rest Fisher's Exact Test with FDR (Benjamini-Hochberg) adjustment
res_fisher = PostHocContingencyCell(table, method=:fisher_1vsall, adjustment=:bh,
                                    row_labels=r_labs, col_labels=c_labs)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/posthoc.jl#L224-L274" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
```


Perform cell-level post-hoc analysis (e.g., ASR) on raw categorical data.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L47-L51" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform cell-level post-hoc analysis on aggregated frequency data (Long format).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L71-L75" target="_blank" rel="noreferrer">source</a></Badge>



```julia
PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform cell-level post-hoc analysis (ASR). Rows are defined by `gd` groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L60-L65" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Structures &amp; Results {#Structures-and-Results}

Helper structures for storing and exporting results.
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.PostHocTestResult' href='#HypothesisTestsExtra.PostHocTestResult'><span class="jlbinding">HypothesisTestsExtra.PostHocTestResult</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
PostHocTestResult
```


Container for the results of a post-hoc multiple comparison test.

**Fields**
- `method::Symbol`: The name of the post-hoc method used (e.g., `:tukey`, `:bonferroni`).
  
- `comparisons::Vector{PostHocComparison}`: A list of all pairwise comparisons performed.
  
- `alpha::Float64`: The significance level used for the test (e.g., 0.05).
  
- `use_cld::Bool`: Whether Compact Letter Display (CLD) was calculated.
  
- `cld_letters::Dict{Int, String}`: Mapping of group indices to CLD letters (if applicable).
  
- `label_map::Dict{Int, String}`: Mapping of internal group indices back to original labels (e.g., &quot;Control&quot;, &quot;Treat&quot;).
  

**Methods**
- `DataFrame(res)`: Convert detailed pairwise results to a DataFrame.
  
- `GroupTestToDataframe(res)`: Convert CLD results to a DataFrame.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/types.jl#L40-L56" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.PostHocComparison' href='#HypothesisTestsExtra.PostHocComparison'><span class="jlbinding">HypothesisTestsExtra.PostHocComparison</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
PostHocComparison
```


Stores the statistical results of a single pairwise comparison between two groups.

**Fields**
- `group1::Int`: Index of the first group in the comparison.
  
- `group2::Int`: Index of the second group in the comparison.
  
- `diff::Float64`: The difference between means (Group1 - Group2).
  
- `se::Float64`: Standard Error of the difference.
  
- `statistic::Float64`: Test statistic (e.g., t-value or q-value).
  
- `crit_val::Float64`: Critical value for the test statistic at the specified alpha.
  
- `p_value::Float64`: Calculated p-value for the comparison.
  
- `lower_ci::Float64`: Lower bound of the confidence interval.
  
- `upper_ci::Float64`: Upper bound of the confidence interval.
  
- `rejected::Bool`: Boolean flag indicating if the null hypothesis was rejected (significant difference).
  
- `note::String`: Additional annotations or warnings (e.g., &quot;ns&quot;, &quot;***&quot;).
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/types.jl#L8-L25" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.ContingencyCellTestResult' href='#HypothesisTestsExtra.ContingencyCellTestResult'><span class="jlbinding">HypothesisTestsExtra.ContingencyCellTestResult</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ContingencyCellTestResult
```


Stores the results of post-hoc cell-wise analysis for contingency tables (e.g., Adjusted Standardized Residuals).

**Fields**
- `method::Symbol`: The method used for cell analysis (e.g., `:asr` for Adjusted Standardized Residuals).
  
- `adjust_method::Symbol`: P-value adjustment method for multiple comparisons (e.g., `:bonferroni`, `:fdr`).
  
- `observed::Matrix{Int}`: The original matrix of observed counts.
  
- `stats_matrix::Matrix{Float64}`: Matrix of test statistics (e.g., Z-scores for ASR or Odds Ratios).
  
- `pvals_matrix::Matrix{Float64}`: Matrix of raw p-values.
  
- `adj_pvals_matrix::Matrix{Float64}`: Matrix of adjusted p-values.
  
- `sig_matrix::Matrix{Bool}`: Boolean matrix indicating significance at the given alpha level.
  
- `alpha::Float64`: Significance level.
  
- `row_labels::Vector{String}`: Labels for the rows of the contingency table.
  
- `col_labels::Vector{String}`: Labels for the columns of the contingency table.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/types.jl#L68-L84" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.GroupTestToDataframe' href='#HypothesisTestsExtra.GroupTestToDataframe'><span class="jlbinding">HypothesisTestsExtra.GroupTestToDataframe</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
GroupTestToDataframe(res::PostHocTestResult)
```


Get CLD (Compact Letter Display) labels of PostHocTestResult as a DataFrame. Returns columns: `GroupIndex`, `GroupLabel`, and `CLD`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/types.jl#L310-L315" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.CellTestToDataframe' href='#HypothesisTestsExtra.CellTestToDataframe'><span class="jlbinding">HypothesisTestsExtra.CellTestToDataframe</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
CellTestToDataframe(res::ContingencyCellTestResult)
```


Generate a matrix-form DataFrame from ContingencyCellTestResult. Cell content format is &quot;Value*&quot; (if significant) or &quot;Value&quot;.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/PostHoc/types.jl#L275-L280" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## DataFrames Extensions {#DataFrames-Extensions}

This package extends `HypothesisTests.jl` and internal methods to support `DataFrame` and `GroupedDataFrame` inputs. 

**Note on GroupedDataFrame Dispatch:** For all `GroupedDataFrame` (GDF) methods, the grouping is determined by the GDF&#39;s keys. You do not need to specify a group column; the first grouping column in the GDF is used as the Independent Variable (IV).

### Categorical Tests (Independence) {#Categorical-Tests-Independence}

Supports raw data (two columns) or aggregated frequency data (three columns).
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.ChisqTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.ChisqTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.ChisqTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
```


Compute Pearson&#39;s Chi-square test from a raw DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L86-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.ChisqTest-Tuple{DataFrame, Symbol, Symbol, Symbol}' href='#HypothesisTests.ChisqTest-Tuple{DataFrame, Symbol, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.ChisqTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
```


Compute Pearson&#39;s Chi-square test from aggregated frequency data.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L98-L102" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.ChisqTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.ChisqTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.ChisqTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ChisqTest(gd::GroupedDataFrame, col_col::Symbol)
ChisqTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
```


Compute Pearson&#39;s Chi-square test. Rows are defined by `gd` groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L82-L87" target="_blank" rel="noreferrer">source</a></Badge>

</details>


::: warning Missing docstring.

Missing docstring for `HypothesisTests.ChisqTest(::GroupedDataFrame, ::Symbol, ::Symbol)`. Check Documenter&#39;s build log for details.

:::
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.FisherExactTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.FisherExactTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.FisherExactTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
```


Compute Fisher&#39;s Exact Test from a raw DataFrame (2x2 only).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L122-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.FisherExactTest-Tuple{DataFrame, Symbol, Symbol, Symbol}' href='#HypothesisTests.FisherExactTest-Tuple{DataFrame, Symbol, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.FisherExactTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
```


Compute Fisher&#39;s Exact Test from aggregated frequency data (2x2 only).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L134-L138" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.FisherExactTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.FisherExactTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.FisherExactTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)
FisherExactTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
```


Compute Fisher&#39;s Exact Test (2x2 only). Rows are defined by `gd` groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L101-L106" target="_blank" rel="noreferrer">source</a></Badge>

</details>


::: warning Missing docstring.

Missing docstring for `HypothesisTests.FisherExactTest(::GroupedDataFrame, ::Symbol, ::Symbol)`. Check Documenter&#39;s build log for details.

:::
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.PowerDivergenceTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.PowerDivergenceTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.PowerDivergenceTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
```


Compute Power Divergence Test from a raw DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L168-L172" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.PowerDivergenceTest-Tuple{DataFrame, Symbol, Symbol, Symbol}' href='#HypothesisTests.PowerDivergenceTest-Tuple{DataFrame, Symbol, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.PowerDivergenceTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Compute Power Divergence Test from aggregated frequency data.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L182-L186" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.PowerDivergenceTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.PowerDivergenceTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.PowerDivergenceTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Compute Power Divergence Test.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L139-L144" target="_blank" rel="noreferrer">source</a></Badge>

</details>


::: warning Missing docstring.

Missing docstring for `HypothesisTests.PowerDivergenceTest(::GroupedDataFrame, ::Symbol, ::Symbol)`. Check Documenter&#39;s build log for details.

:::
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.FisherExactTestRxC-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTestsExtra.FisherExactTestRxC-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.FisherExactTestRxC</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
```


Compute Fisher&#39;s Exact Test for general RxC tables from a raw DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L146-L150" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.FisherExactTestRxC-Tuple{DataFrame, Symbol, Symbol, Symbol}' href='#HypothesisTestsExtra.FisherExactTestRxC-Tuple{DataFrame, Symbol, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.FisherExactTestRxC</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
```


Compute Fisher&#39;s Exact Test (RxC) from aggregated frequency data.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L157-L161" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.FisherExactTestRxC-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTestsExtra.FisherExactTestRxC-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTestsExtra.FisherExactTestRxC</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
```


Compute Fisher&#39;s Exact Test for general RxC tables.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L121-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>


::: warning Missing docstring.

Missing docstring for `FisherExactTestRxC(::GroupedDataFrame, ::Symbol, ::Symbol)`. Check Documenter&#39;s build log for details.

:::

### K-Sample &amp; Variance Tests {#K-Sample-and-Variance-Tests}

Tests comparing 2 or more groups.
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.OneWayANOVATest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.OneWayANOVATest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.OneWayANOVATest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform One-Way ANOVA on a DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L198-L202" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.OneWayANOVATest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.OneWayANOVATest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.OneWayANOVATest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform One-Way ANOVA. `gd` groups define the independent variable.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L162-L166" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.WelchANOVATest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTestsExtra.WelchANOVATest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.WelchANOVATest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Welch&#39;s ANOVA on a DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L209-L213" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.WelchANOVATest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTestsExtra.WelchANOVATest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTestsExtra.WelchANOVATest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Welch&#39;s ANOVA.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L173-L177" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.KruskalWallisTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.KruskalWallisTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.KruskalWallisTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Kruskal-Wallis Rank Sum Test on a DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L220-L224" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.KruskalWallisTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.KruskalWallisTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.KruskalWallisTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Kruskal-Wallis Rank Sum Test. Supports Numeric or Ordered DV.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L184-L188" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.LeveneTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.LeveneTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.LeveneTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Levene&#39;s Test on a DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L234-L238" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.LeveneTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.LeveneTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.LeveneTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
LeveneTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Levene&#39;s Test for homogeneity of variance.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L200-L204" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.BrownForsytheTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.BrownForsytheTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.BrownForsytheTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Brown-Forsythe Test on a DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L245-L249" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.BrownForsytheTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.BrownForsytheTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.BrownForsytheTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Brown-Forsythe Test.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L211-L215" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.FlignerKilleenTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.FlignerKilleenTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.FlignerKilleenTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Fligner-Killeen Test on a DataFrame.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L256-L260" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.FlignerKilleenTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.FlignerKilleenTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.FlignerKilleenTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Fligner-Killeen Test.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L222-L226" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Two-Sample Tests {#Two-Sample-Tests}

Specialized tests for exactly 2 groups.
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.EqualVarianceTTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.EqualVarianceTTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.EqualVarianceTTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Student&#39;s T-Test. Validation of binary groups is handled during extraction.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L271-L274" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.EqualVarianceTTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.EqualVarianceTTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.EqualVarianceTTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Student&#39;s T-Test. `gd` must contain exactly 2 groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L237-L241" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.UnequalVarianceTTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.UnequalVarianceTTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.UnequalVarianceTTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Welch&#39;s T-Test (unequal variance) on a DataFrame (exactly 2 groups).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L281-L285" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.UnequalVarianceTTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.UnequalVarianceTTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.UnequalVarianceTTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Welch&#39;s T-Test (unequal variance). `gd` must contain exactly 2 groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L248-L252" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.VarianceFTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.VarianceFTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.VarianceFTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform F-Test for variances on a DataFrame (exactly 2 groups).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L292-L296" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.VarianceFTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.VarianceFTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.VarianceFTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform F-Test for variances. `gd` must contain exactly 2 groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L259-L263" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.MannWhitneyUTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.MannWhitneyUTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.MannWhitneyUTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Mann-Whitney U Test. Automatically handles categorical data codes.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L303-L306" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.MannWhitneyUTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.MannWhitneyUTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.MannWhitneyUTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Mann-Whitney U Test. `gd` must contain exactly 2 groups. Supports Numeric or Ordered DV.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L270-L275" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.ApproximateTwoSampleKSTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTests.ApproximateTwoSampleKSTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTests.ApproximateTwoSampleKSTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Approximate Two-Sample KS Test on a DataFrame (exactly 2 groups).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L315-L319" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTests.ApproximateTwoSampleKSTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTests.ApproximateTwoSampleKSTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTests.ApproximateTwoSampleKSTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Approximate Two-Sample KS Test. `gd` must contain exactly 2 groups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L287-L291" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Trend and Association Tests {#Trend-and-Association-Tests-2}

These methods require ordered categorical data where appropriate (e.g., Jonckheere-Terpstra or Cochran-Armitage).
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.CochranArmitageTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTestsExtra.CochranArmitageTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.CochranArmitageTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol; scores=:equidistant)
```


Perform Cochran-Armitage test for trend in proportions on raw dataframe.
- `group_col` (IV): Must be Ordered Categorical.
  
- `data_col` (DV): Must be Binary.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L346-L352" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.CochranArmitageTest-Tuple{DataFrame, Symbol, Symbol, Symbol}' href='#HypothesisTestsExtra.CochranArmitageTest-Tuple{DataFrame, Symbol, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.CochranArmitageTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol, freq_col::Symbol; scores=:equidistant)
```


Perform Cochran-Armitage test for trend in proportions on freq dataframe.
- `group_col` (IV): Must be Ordered Categorical.
  
- `data_col` (DV): Must be Binary.
  
- `freq_col` (Frequencies): Must be numeric.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L362-L369" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.CochranArmitageTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTestsExtra.CochranArmitageTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTestsExtra.CochranArmitageTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform Cochran-Armitage test for trend.  `gd` keys must be Ordered. `data_col` must be Binary.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L324-L330" target="_blank" rel="noreferrer">source</a></Badge>

</details>


::: warning Missing docstring.

Missing docstring for `CochranArmitageTest(::GroupedDataFrame, ::Symbol, ::Symbol)`. Check Documenter&#39;s build log for details.

:::
<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.JonckheereTerpstraTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTestsExtra.JonckheereTerpstraTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.JonckheereTerpstraTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JonckheereTerpstraTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
```


Perform Jonckheere-Terpstra test.
- `group_col` (IV): Must be Ordered Categorical.
  
- `data_col` (DV): Must be Numeric or Ordered Categorical.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L326-L332" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.JonckheereTerpstraTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTestsExtra.JonckheereTerpstraTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTestsExtra.JonckheereTerpstraTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JonckheereTerpstraTest(gd::GroupedDataFrame, data_col::Symbol)
```


Perform Jonckheere-Terpstra test.  The GroupedDataFrame keys must be Ordered Categorical. `data_col` must be Numeric or Ordered.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L302-L308" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.LinearByLinearTest-Tuple{DataFrame, Symbol, Symbol}' href='#HypothesisTestsExtra.LinearByLinearTest-Tuple{DataFrame, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.LinearByLinearTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
```


Perform Linear-by-Linear Association test.
- `row_col` (IV): Must be Ordered Categorical.
  
- `col_col` (DV): Must be Ordered Categorical.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L379-L385" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.LinearByLinearTest-Tuple{DataFrame, Symbol, Symbol, Symbol}' href='#HypothesisTestsExtra.LinearByLinearTest-Tuple{DataFrame, Symbol, Symbol, Symbol}'><span class="jlbinding">HypothesisTestsExtra.LinearByLinearTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform Linear-by-Linear Association test.
- `row_col` (IV): Must be Ordered Categorical.
  
- `col_col` (DV): Must be Ordered Categorical.
  
- `freq_col` (Frequencies): Must be numeric.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/dataframe_ext.jl#L392-L399" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='HypothesisTestsExtra.LinearByLinearTest-Tuple{GroupedDataFrame, Symbol}' href='#HypothesisTestsExtra.LinearByLinearTest-Tuple{GroupedDataFrame, Symbol}'><span class="jlbinding">HypothesisTestsExtra.LinearByLinearTest</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
```


Perform Linear-by-Linear Association test. Both `gd` groups and `col_col` must be Ordered Categorical.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/songtaogui/HypothesisTestsExtra.jl/blob/7ad07c986555449d206911d1f74ce1568c633a02/src/Dispatch/groupeddataframe_ext.jl#L355-L361" target="_blank" rel="noreferrer">source</a></Badge>

</details>


::: warning Missing docstring.

Missing docstring for `LinearByLinearTest(::GroupedDataFrame, ::Symbol, ::Symbol)`. Check Documenter&#39;s build log for details.

:::

// KAN deep-dive slides (initial comprehensive draft)

#import "@preview/definitely-not-isec-slides:1.0.1": *
#import "template.typ": *

#let fig_path = "figures/"
#let theme_primary = rgb("fc5555")
// Background color used by `#color-block` (defaults to `self.colors.lite`).
#let theme_block_bg = rgb("f4f6fb")

#show: definitely-not-isec-theme.with(
  aspect-ratio: "16-9",
  slide-alignment: top,
  font: "Helvetica",
  progress-bar: false,
  institute: [HM],
  logo: [#image(fig_path + "hm-logo.svg", width: 2cm)],
  config-info(
    title: [Deep Dive: Kolmogorov-Arnold Networks (KANs)],
    subtitle: [Accuracy, Interpretability, and Scaling Beyond MLPs],
    authors: [Team KAN (replace names)],
    extra: [Advanced Deep Learning Deep Dive],
    footer: [
      #grid(
        columns: (1fr, auto, 1fr),
        align: bottom,
        align(left)[Team KAN],
        align(center)[Advanced Deep Learning],
        align(right)[#datetime.today().display("[day padding:none]. [month repr:short] [year]")],
      )
    ],
    download-qr: "",
  ),
  config-common(
    handout: false,
  ),
  config-colors(
    primary: theme_primary,
    lite: theme_block_bg,
  ),
)

// Set global text size
#set text(size: 17pt)

// Style links to be blue and underlined
#show link: set text(fill: blue)
#show link: it => underline(it)

// Make figure captions compact (avoid large "Figure N:" prefixes in slides).
#show figure.caption: it => {
  set text(size: 11pt, fill: gray)
  it.body
}

// The title slide summarizes the talk.
#title-slide()

#slide(title: [Roadmap])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Part I: Motivation + Theory])[
        - Why move non-linearities to edges?
        - KAT vs UAT (theorem shift)
      ]
      #color-block(title: [Part II: Architecture + Training])[
        - KAN layer = matrix of 1D functions
        - Splines, residual activation, grid updates
      ]
    ],
    [
      #color-block(title: [Part III: Accuracy + Scaling])[
        - Scaling laws (alpha ~ 4) and grid extension
        - PDE + symbolic regression benchmarks
      ]
      #color-block(title: [Part IV: Interpretability + Critique])[
        - Sparsification, pruning, symbolification
        - Practical limits and open questions
      ]
    ],
  )
]

#slide(title: [MLP vs KAN (shallow): where does nonlinearity live?])[
  #grid(
    columns: (1.25fr, 1fr),
    gutter: 0.9cm,
    [
      #figure(
        image(fig_path + "kan_mlp_shallow.png", width: 100%),
        caption: [Shallow MLP vs shallow KAN (Fig. 0.1a,b). @kan-liu2025],
      )
      #v(0.25em)
      #color-block(title: [Key idea], spacing: 0.55em)[
        - MLP: fixed activation $sigma$ on nodes; learn weights $w_(j,i)$ on edges.
        - KAN: learn 1D edge functions $phi_(q,p)$; nodes only sum inputs.
        - Intuition: learn expressive 1D building blocks, then compose across layers.
      ]
    ],
    [
      #color-block(title: [Shallow formulas])[
        - MLP / UAT-style:
          $ f(bold(x)) approx sum_(j=1)^m a_j sigma(bold(w)_j^T bold(x) + b_j) $
        - KAN / KAT-style:
          $ f(bold(x)) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p)) $
      ]
      #text(size: 11pt)[@cybenko1989approximation @hornik1989multilayer @kolmogorov1957representation @kan-liu2025]

      #v(0.2em)
      #text(
        size: 12pt,
        fill: gray,
      )[Connections: fixed vs learnable nonlinearity; inductive bias towards symbolic/compositional structure.]
    ],
  )
]

#slide(title: [MLP vs KAN (deep): what gets learned?])[
  #grid(
    columns: (1.25fr, 1fr),
    gutter: 0.9cm,
    [
      #figure(
        image(fig_path + "kan_mlp_deep.png", width: 100%),
        caption: [Deep MLP vs deep KAN (Fig. 0.1c,d). @kan-liu2025],
      )
      #v(0.25em)
      #color-block(title: [Deep takeaway], spacing: 0.55em)[
        - Deep MLPs: learn linear maps $bold(W)_l$; nonlinearity stays fixed.
        - Deep KANs: learn function matrices $bold(Phi)_l$ (one 1D function per edge).
        - Practical upside: plot/inspect learned edge functions directly.
      ]
    ],
    [
      // TODO replace ∘ with poper typst symbol for function composition
      #color-block(title: [Deep composition])[
        - Deep MLP:
          $ "MLP"(bold(x)) = (bold(W)_(L-1) ∘ sigma ∘ bold(W)_(L-2) ∘ ... ∘ sigma ∘ bold(W)_0)(bold(x)) $
        - Deep KAN:
          $ "KAN"(bold(x)) = (bold(Phi)_(L-1) ∘ ... ∘ bold(Phi)_0)(bold(x)) $
      ]
      #text(size: 11pt)[@cybenko1989approximation @hornik1989multilayer @kan-liu2025]

      #v(0.2em)
      #color-block(title: [Interpretation])[
        - MLP: learn linear maps $bold(W)$; nonlinearity is fixed.
        - KAN: learn edge functions $phi_(l,j,i)$; nodes are sums.
      ]
    ],
  )
]

#slide(title: [UAT vs KAT: what do they guarantee?])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [UAT (MLPs)])[
        - Statement: 2-layer nets can approximate any continuous $f$ on a compact domain.
        - Learnable parts: $bold(W), bold(b)$ (activations fixed).
        - Caveat: existence result; rates can still suffer from dimensionality.

        $ f(bold(x)) approx sum_(j=1)^m a_j sigma(bold(w)_j^T bold(x) + b_j) $

        #text(size: 11pt)[@cybenko1989approximation @hornik1989multilayer]
      ]
    ],
    [
      #color-block(title: [KAT (Kolmogorov–Arnold)])[
        - Statement: represent $f:[0,1]^n -> RR$ via sums of 1D functions + addition.
        - Promise: reduce multivariate learning to learning many 1D functions.
        - Caveat: worst-case representations can be highly non-smooth/fractal.

        $ f(bold(x)) = sum_(q=1)^(2n+1) Phi_q(sum_(p=1)^n phi_(q,p)(x_p)) $

        #text(
          size: 11pt,
        )[@kan-liu2025 @kolmogorov1957representation @braun2009constructive @schmidt2021kolmogorov @girosi1989representation]
      ]
    ],
  )

  #v(0.2em)
  #text(
    size: 12pt,
    fill: gray,
  )[KAN viewpoint: assume smooth/compositional structure; learn $phi$ with splines and add depth to avoid pathological 2-layer forms. @kan-liu2025 @poggio2020theoretical]
]

#slide(title: [KAN layer mechanics])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #text(size: 16pt)[
        Each layer is a matrix of learnable 1D functions:
      ]
      $ x_(l+1,j) = sum_(i=1)^(n_l) phi_(l,j,i)(x_(l,i)) $
      $ bold(x)_(l+1) = bold(Phi)_l bold(x)_l $
      #text(size: 11pt)[@kan-liu2025]
      #v(0.2em)
      #text(size: 16pt)[
        Each edge function is a residual spline:
      ]
      $ phi(x)= w_b b(x) + w_s sum_i c_i B_i(x) $
      #text(size: 11pt)[@kan-liu2025 @de1978practical]
      #v(0.3em)
      #text(size: 12pt, fill: gray)[Residual $b(x)$ defaults to SiLU; spline coefficients are trainable.]
    ],
    [
      #figure(
        image(fig_path + "spline_notation.png", width: 100%),
        caption: [B-spline parametrization and grid refinement. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Training and optimization tricks])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Optimization details])[
        - Residual activation: $phi(x)=w_b b(x)+w_s "spline"(x)$.
        - Initialize spline near zero; initialize $w_b$ like Xavier.
        - Update spline grids as activation ranges drift.
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #color-block(title: [Connections])[
        - Initialization and stability in deep networks
        - Loss landscapes and optimization schedules
        - Bias–variance trade-off when increasing capacity
      ]
    ],
  )
]

#section-slide(title: [Accuracy & Scaling], subtitle: [How KANs generalize and grow])[
  #figure(
    image(fig_path + "model_scaling.pdf", width: 100%),
    caption: [Fast scaling trends on structured function classes. @kan-liu2025],
  )
]

#slide(title: [Scaling laws])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Theory + observation])[
        - Smooth-KAT bound: $|f - "KAN"_G| <= C G^(-(k+1))$ (cubic: $k=3 -> alpha approx 4$).
        - Comparison: manifold view ($alpha approx (k+1)/d$) vs arity view ($alpha approx (k+1)/2$).
        - Empirically: KANs reach steeper scaling than MLPs on compositional data.
      ]
      #text(size: 11pt)[@kan-liu2025 @de1978practical @sharma2020neural @michaud2023precision]
      #v(0.3em)
      #text(size: 12pt, fill: gray)[Connections: scaling laws; approximation theory; bias–variance trade-off.]
    ],
    [
      #figure(
        image(fig_path + "model_scaling.pdf", width: 100%),
        caption: [Scaling vs MLP baselines. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Grid extension: fine-grain without retraining])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Key idea])[
        - Start with coarse grids, then refine spline knots.
        - Initialize finer grids by least-squares fit to the coarse spline.
        - Produces staircase-like drops in loss after each extension.
      ]
      #text(size: 11pt)[@kan-liu2025]
      #v(0.3em)
      #text(size: 12pt, fill: gray)[Connections: model scaling vs training schedules; KAN adds explicit fine-graining.]
    ],
    [
      #figure(
        image(fig_path + "extend_grid.pdf", width: 100%),
        caption: [Grid extension illustration. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Grid extension: why it works])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Why grid extension works])[
        - External dofs: graph structure (width/depth) learns compositional structure.
        - Internal dofs: spline grid points learn 1D functions precisely.
        - Grid extension: increase internal dofs without re-initializing.
        - Warm-start: least-squares fit a finer spline to the coarse spline (per edge).
        - Effect: staircase-like loss drops after each refinement; cost grows with grid size.
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #grid(
        columns: (1fr, 1fr),
        gutter: 0.4cm,
        [
          #figure(
            image(fig_path + "extend_grid_left.png", width: 100%),
            caption: [Staircase loss drops after each refinement. @kan-liu2025],
          )
        ],
        [
          #figure(
            image(fig_path + "extend_grid_right.png", width: 100%),
            caption: [Training time vs grid size. @kan-liu2025],
          )
        ],
      )
    ],
  )
]

#slide(title: [Accuracy results: PDEs and scientific fitting])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Results])[
        - PDE solving: Poisson equation solved with smaller KANs at higher accuracy.
        - Special functions + Feynman datasets show strong sample efficiency.
        - Suggests KANs as compact, high-precision function approximators.
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #figure(
        image(fig_path + "PDE_results.pdf", width: 100%),
        caption: [PDE benchmark results. @kan-liu2025],
      )
    ],
  )
]

#section-slide(title: [Interpretability & Science], subtitle: [From pruning to symbolic laws])[
  #figure(
    image(fig_path + "interpretable_examples_short.png", width: 100%),
    caption: [Symbolic recovery examples from pruned/simplified KANs. @kan-liu2025],
  )
]

#slide(title: [Interpretability toolkit: sparsify, prune, symbolify])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Four steps to a formula])[
        - Sparsify: encourage few active edges (L1 + entropy).
        - Visualize: inspect learned 1D edge functions $phi_(l,j,i)$.
        - Prune: drop inactive nodes to a minimal shape $[n_0, ..., n_L]$.
        - Symbolify: snap splines to analytic forms with an affine wrapper
          $ y approx c f(a x + b) + d $
          (grid search for $a,b$; linear regression for $c,d$).
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #figure(
        image(fig_path + "toy_interpretability_evolution.png", width: 100%),
        caption: [Sparsification + pruning yields simpler, more interpretable KANs. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Interpretability: hyperparameters matter])[
  #grid(
    columns: (1fr, 1.25fr),
    gutter: 0.8cm,
    [
      #color-block(title: [What changes (and why)])[
        - Entropy regularization: encourages sparse, readable graphs.
        - $lambda$: sparsity–accuracy trade-off; too small → dense, too large → underfit.
        - Grid size $G$ + spline order $k$: resolution vs compute (larger $G$ is slower).
        - Random seeds can reveal different relations in unsupervised discovery.
      ]
      #text(size: 11pt)[@kan-liu2025]
      #v(0.3em)
      #text(size: 12pt, fill: gray)[Takeaway: interpretability is an objective + design choice, not a byproduct.]
    ],
    [
      #figure(
        image(fig_path + "interpretability_hyperparameters.png", width: 100%),
        caption: [Dependence on regularization, seeds, and spline resolution. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Interactive symbolification (toy example)])[
  #grid(
    columns: (1.15fr, 1fr),
    gutter: 0.8cm,
    [
      #figure(
        image(fig_path + "sr.png", width: 100%),
        caption: [Interactive workflow for symbolic regression with KANs. @kan-liu2025],
      )
    ],
    [
      #color-block(title: [What the user does])[
        - Train with sparsification.
        - Prune to a minimal graph.
        - Set/suggest symbolic forms (manual or assisted).
        - Retrain only affine parameters and export the symbolic formula.
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
  )
]

#slide(title: [Case study (math): knot invariants (unsupervised)])[
  #grid(
    columns: (1fr, 1.25fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Unsupervised discovery idea], spacing: 0.55em)[
        - Goal: discover sparse relations among many invariants (not just predict one target).
        - Train a sparse classifier KAN (shape $[18, 1, 1]$).
        - Fix the last activation to a Gaussian peak at 0 ⇒ positives satisfy
          $ sum_(i=1)^18 g_i(x_i) approx 0 $ (read $g_i$ off learned edges).
        - Sweep seeds + $lambda$ and cluster multiple discovered relations.
      ]
    ],
    [
      #figure(
        image(fig_path + "knot_unsupervised.png", width: 100%),
        caption: [Knot dataset (unsupervised): rediscovered relations. @kan-liu2025 @davies2021advancing @gukov2023searching],
      )
    ],
  )
]

#slide(title: [Case study (physics): mobility edges via KANs])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [From data to an order parameter], spacing: 0.55em)[
        - Goal: learn the mobility edge separating localized vs extended phases.
        - Localization metric (eigenstate $bold(psi)^(k)$):
          $ "IPR"_k = (sum_n |psi_n^(k)|^4) / (sum_n |psi_n^(k)|^2)^2 $
          $ D_k = - log("IPR"_k) / log(N) $
        - Train → sparsify/prune → symbolify to recover a compact boundary $g(·)=0$
          (human-in-the-loop: constrain the symbol library).
      ]
    ],
    [
      #figure(
        image(fig_path + "mobility_edge.png", width: 100%),
        caption: [Mobility-edge discovery before/after symbolic snapping. @kan-liu2025 @anderson1958absence],
      )
    ],
  )
]

#slide(title: [Symbolic regression: KANs vs classic SR])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Why KANs help])[
        - Continuous search in function space (gradients) before snapping to symbols.
        - Debuggable intermediate artifacts: plots of $phi_(l,j,i)$.
        - Works even when the target is not exactly symbolic (splines as fallback).
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #color-block(title: [Related SR methods])[
        - Genetic / heuristic: Eureqa @Dubckov2011EureqaSR
        - Physics-inspired: AI Feynman @udrescu2020ai @udrescu2020ai2
        - NN-based: EQL @martius2016extrapolation, OccamNet @dugan2020occamnet
        - Program search: PySR @cranmer2023interpretable
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
  )
]

#slide(title: [Continual learning and locality])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Local plasticity])[
        - B-spline activations are local in input space.
        - Updates can be localized, reducing catastrophic forgetting.
        - Promising for continual or lifelong learning regimes.
      ]
      #text(size: 11pt)[@kan-liu2025]
      #v(0.3em)
      #text(
        size: 12pt,
        fill: gray,
      )[Connections: catastrophic forgetting; local adaptation; compute reuse in continual settings.]
    ],
    [
      #figure(
        image(fig_path + "continual_learning.pdf", width: 100%),
        caption: [Continual learning experiments. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Limitations and open questions])[
  #color-block(title: [Practical limits])[
    - Training is slower (poor batching; no optimized spline kernels). @kan-liu2025
    - Scaling claims are strongest on structured, low-data scientific tasks.
    - Choosing minimal KAN shapes is still an open design problem.
    - Can KANs replace MLP blocks in CNNs/Transformers without hardware regressions?
  ]
  #v(0.3em)
  #text(size: 12pt, fill: gray)[Connections: throughput vs parameter count; hardware efficiency vs expressivity.]
]

#slide(title: [Summary + discussion prompts])[
  #color-block(title: [Takeaways])[
    - KANs move nonlinearity to edges, learning 1D functions directly.
    - Grid extension + spline parametrization yield strong accuracy/scaling.
    - Sparsification enables symbolic interpretability (white-box ML).
    - Trade-off: better accuracy/interpretability vs slower training.
  ]

  #color-block(title: [Questions for the track])[
    - Where would KANs beat MLPs (e.g., scientific regression, PDEs, transformer MLP blocks)?
    - What hardware/software advances would make KANs practical?
    - How should we evaluate interpretability vs performance for science?
  ]
]

#slide(title: [References])[
  #set text(size: 9pt)
  #set par(leading: 0.75em, spacing: 0.18em)
  #set list(spacing: 0.18em)
  // Prevent single bibliography entries from splitting across columns.
  #show list.item: it => block(breakable: false)[it]
  #columns(2, gutter: 0.9cm)[
    #bibliography("references.bib", title: none)
  ]
]

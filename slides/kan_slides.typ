// KAN deep-dive slides (initial comprehensive draft)

#import "@preview/definitely-not-isec-slides:1.0.1": *
#import "template.typ": *
#import "notes.typ": *


#let fig_path = "figures/"
#let theme_primary_hm = rgb("fc5555")
#let theme_block_bg = rgb("f4f6fb")

#show: definitely-not-isec-theme.with(
  aspect-ratio: "16-9",
  slide-alignment: top,
  font: "Helvetica",
  progress-bar: false,
  institute: [Munich University of Applied Sciences],
  logo: [#image(fig_path + "hm-logo.svg", width: 2cm)],
  config-info(
    title: [Deep Dive: Kolmogorov-Arnold Networks (KANs)],
    subtitle: [Accuracy, Interpretability, and Scaling Beyond MLPs],
    authors: [Jan Duchscherer, Felix Schladt],
    extra: [Advanced Deep Learning Deep Dive],
    footer: [
      #grid(
        columns: (1fr, auto, 1fr),
        align: bottom,
        align(left)[Felix Schladt #sym.dot Jan Duchscherer],
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
    primary: theme_primary_hm,
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



#slide(title: [Table of Contents])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Part I: Motivation + Theory])[
        - From _MLPs_ to _KANs_
        - KAT vs UAT (theorem shift)
        - Curse of dimensionality (CoD)
      ]
      #color-block(title: [Part II: Architecture + Training])[
        - KAN layer mechanics (function matrices)
        - Splines, residual activation, grid updates
      ]
    ],
    [
      #color-block(title: [Part III: Accuracy + Scaling])[
        - Scaling laws + grid extension
        - PDEs + scientific fitting
      ]
      #color-block(title: [Part IV: Interpretability + Critique])[
        - Sparsify → prune → symbolify
        - Practical limits and open questions
      ]
    ],
  )
]

#section-slide(
  title: [Introduction to Kolmogorov-Arnold Networks],
  subtitle: [From fixed activations to learnable 1D edge functions],
)[
  #figure(
    image(fig_path + "mlp-vs-kan2.png", width: 100%),
    caption: [MLP vs KAN overview.],
  )
]

#slide(title: [Motivation])[
  #color-block(title: [Why KANs?])[
    - Interpretability: learned *1D edge functions* can be inspected and simplified.
    - Parameter efficiency on scientific tasks. @kan-liu2025
    - Better inductive bias when the target is smooth + compositional (common in physics/biology). @kan-liu2025
  ]
]

#slide(title: [From MLPs to KANs])[
  #color-block(title: [Same layout, different nonlinearity])[
    - MLP: scalar weights $w_(j,i)$ on edges; fixed activation $sigma$ on nodes.
    - KAN: each edge is a learnable 1D function $phi_(j,i)(x)$ (e.g., a spline).
    - Nodes just add inputs → interpret learned functions directly.
  ]
]

// Adapted form https://typst.app/project/w3ZP87eMnIzmHrBT2OpRN1
#slide(title: [From MLPs to Kolmogorov-Arnold Networks (KANs)])[
  #color-block(title: [Same wiring, different learnable object])[
    Same basic layout as MLPs (fully connected layers):

    - MLP: scalar weight $w_(i,j)$ on each edge, fixed activation $sigma$ on neurons.
    - KAN: each edge has a learnable 1D function $Phi_(i,j)(x)$ (e.g., spline).
      - Neurons just add inputs.
  ]
]

// Adapted form https://typst.app/project/w3ZP87eMnIzmHrBT2OpRN1
#slide(title: [Introduction to Kolmogorov-Arnold Networks])[
  #figure(
    image(fig_path + "mlp-vs-kan2.png", height: 90%),
    caption: [MLP vs. KAN overview @serranoacademy_kolmogorov-arnold_2024],
  )
]

#slide(title: [The Kolmogorov-Arnold theorem])[
  #grid(
    columns: (1fr, 1.1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Key statement])[
        - Any continuous $f(x_1, dots, x_n)$ on $[0,1]^n$ can be represented using *1D functions + addition*.
        - The only _true_ multivariate operation is *sum*; everything else can be composed from univariate transforms + additions.
        - 1D functions can be approximated very well (e.g., with splines).
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #align(center)[
        #set text(size: 20pt)
        $
          f(bold(x))= f(x_1, dots, x_n) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p))
        $
      ]
      #good-note([*Simple splines can approximate high-dimensional functions*])
    ],
  )
]

#slide(title: [The Kolmogorov-Arnold Theorem])[

  #figure(
    caption: [
      #set text(size: 20pt)
      If $f$ is a multivariate continuous function,it can be written as a finite composition of cnoninuous functios of a  single variable and addation. (True for $f: [0,1]^n -> RR$, where $Phi q, p: [0,1] -> RR$ and $Phi q: RR -> RR$)@kan-liu2025],
  )[
    #align(center)[
      #set text(size: 30pt)
      $
        f(bold(x))= f(x_1, dots, x_n) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p))
      $
    ]
  ]
]


#slide(title: [Can any high-dimensional function be represented by KANs?])[
  #quote-block()[
    Classical KAT is elegant, but the required 1D inner functions can be non-smooth/fractal → hard to learn in practice.
  ]
  #v(0.25em)
  #good-note[
    #text(size: 19pt)[*Mitigation:*]
    // - Classical KAT guarantees existence, but inner 1D functions can be highly non-smooth/fractal.
    // - Mitigation: go beyond the rigid depth-2, width $(2n+1)$ form → use deeper/wider KANs.
    // - In many real tasks we expect smooth, compositionally sparse structure, making KAT-like forms learnable.
    // - This counts especially for scientific datasets, where underlying laws are often smooth and compositional.
    - Don't stick to the rigid depth-2, width $(2n+1)$ form → use deeper/wider KANs to admit smoother representations.
    - In real tasks we often expect smooth + compositionally sparse structure, so “typical cases” may admit smooth KA-like representations.
  ]
]

#slide(title: [Splines])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Why splines?])[
        - Smooth *piecewise-polynomial* functions of one variable $x$.
        - Controlled by knots + coefficients → flexible local curves.
        - Approximate 1D functions well with few parameters.

        #v(0.25em)
        In KANs, each edge learns its own spline $phi_(j,i)(x)$. @kan-liu2025
      ]
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      #figure(
        image(fig_path + "spline (1).png", width: 100%),
        caption: [Spline example.],
      )
    ],
  )
]

#slide(title: [Splines (example)])[
  #grid(
    columns: (20%, 80%),
    gutter: 10pt,
    [
      0.5\
      0.2\
      0.7
    ],
    [
      #image(fig_path + "spline (1).png", width: 100%)
    ],
  )
]

#slide(title: [Splines (in KANs)])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      - Smooth *piecewise-polynomial* functions of one variable $x$
      - Controlled by knots + coefficients → flexible local curves
      - Approximate 1D functions very well with few parameters

      #good-note[In KANs, each edge learns its own 1D spline $phi_(i,j)(x)$. @kan-liu2025]
    ],
    [
      #figure(
        image(fig_path + "spline_notation.png", width: 100%),
        caption: [Spline notation and grid refinement. @kan-liu2025],
      )
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
      #color-block(title: [Key idea])[
        - MLP: fixed activation $sigma$ on nodes; learn weights $w_(j,i)$ on edges.
        - KAN: learn 1D edge functions $phi_(q,p)$; nodes only sum inputs.
        - Intuition: learn expressive 1D building blocks, then compose across layers.
        - Sum is the only multivariate operation (no explicit products).
        - Example trick: $x dot y = exp(log x + log y)$ shows how products can be expressed by univariate maps + addition.
      ]
    ],
    [
      #color-block(title: [Shallow formulas])[
        - MLP / UAT-style:
          $ f(bold(x)) approx sum_(j=1)^m a_j sigma(bold(w)_j^T bold(x) + b_j) $
        - KAN / KAT-style:
          $ f(bold(x)) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p)) $
      ]
      #text(size: 11pt)[@kan-liu2025]

      //[Connections: fixed vs learnable nonlinearity; inductive bias towards symbolic/compositional structure.]
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
      #color-block(title: [Deep takeaway])[
        - Deep MLPs: learn linear maps $bold(W)_l$; nonlinearity stays fixed.
        - Deep KANs: learn function matrices $bold(Phi)_l$ (one 1D function per edge).
        - Practical upside: plot/inspect learned edge functions directly.
      ]
    ],
    [
      // TODO replace ∘ with poper typst symbol for function composition
      #color-block(title: [Deep composition])[
        - Deep MLP:
          $
            "MLP"(bold(x)) = (bold(W)_(L-1) compose sigma compose bold(W)_(L-2) compose ... compose sigma compose bold(W)_0)(bold(x))
          $
        - Deep KAN:
          $ "KAN"(bold(x)) = (bold(Phi)_(L-1) compose ... compose bold(Phi)_0)(bold(x)) $
      ]
      #text(size: 11pt)[@kan-liu2025]

      #v(0.2em)
      #color-block(title: [Interpretation])[
        - MLP: learn linear maps $bold(W)$; nonlinearity is fixed.
        - KAN: learn edge functions $phi_(l,j,i)$; nodes are sums.
      ]
    ],
  )
]


#slide(title: [UAT vs KAT: what do they guarantee?])[
]

#slide(title: [Curse of dimensionality: where the pain shows up])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [MLPs (UAT): existence → not efficiency])[
        - UAT is an *existence* guarantee: a shallow MLP can approximate any continuous $f$ on a compact set.
        - It does *not* guarantee dimension-free efficiency: in worst cases, required width / samples can grow exponentially with dimension.
        - Deep nets often help by exploiting *structure* (compositionality / low intrinsic dimension), but this is not automatic.
      ]
      #quote-block[
        CoD for MLPs typically bites via *sample/width blow-up* when $f$ has no exploitable structure.
      ]
    ],
    [
      #color-block(title: [KANs (KART): shift the difficulty])[
        - KART suggests reducing multivariate learning to learning many 1D functions.
        - But the classical 2-layer representation can require *highly non-smooth / fractal* inner functions → hard to learn.
        - Deep/wide KANs assume a *smooth compositional* representation exists; then each edge is a learnable 1D problem.
      ]
      #quote-block[
        KANs do not delete CoD; they try to *negotiate* with it by betting on smooth, compositional structure.
      ]
    ],
  )
  #grid(
    columns: (1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [UAT (MLPs)])[
        - Statement: 2-layer nets can approximate any continuous $f$ on a compact domain.
        - Learnable parts: $bold(W), bold(b)$ (activations fixed).
        - Caveat: existence result; rates can still suffer from dimensionality.

        $ f(bold(x)) approx sum_(j=1)^m a_j sigma(bold(w)_j^T bold(x) + b_j) $

        #text(size: 11pt)[@kan-liu2025]
      ]
    ],
    [
      #color-block(title: [KAT (Kolmogorov-Arnold)])[
        - Statement: represent $f:[0,1]^n -> RR$ via sums of 1D functions + addition.
        - Promise: reduce multivariate learning to learning many 1D functions.
        - Caveat: worst-case representations can be highly non-smooth/fractal.

        $ f(bold(x)) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p)) $

        #text(
          size: 11pt,
        )[@kan-liu2025]
      ]
    ],
  )

  #v(0.2em)
  #text(
    size: 12pt,
    fill: gray,
  )[KAN viewpoint: assume smooth/compositional structure; learn $phi$ with splines and add depth to avoid pathological 2-layer forms. @kan-liu2025]
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
      #text(size: 11pt)[@kan-liu2025]
      #v(0.3em)
      #text(size: 12pt, fill: gray)[
        Residual $b(x)$ defaults to SiLU; spline coefficients are trainable.
        Local B-spline basis → localized updates → potentially less catastrophic forgetting (continual learning intuition).
      ]
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

      - *Residual activations:*
        $
          phi(bold(x))=w_b b(bold(x))+w_s "spline"bold((x))
        $
        + well-defined outputs outside spline grid
        + simplified optimization target
      - *Grid update:* periodically estimate the activation distribution and *move knot/grid points* to maintain good coverage.
        - non-differentiable reparameterization step).
      - B-splines are a practical choice (locality), but KAN #sym.eq.not splines: other orthogonal bases / global activations are possible.
      #text(size: 11pt)[@kan-liu2025]
    ],
    [
      // [Connections])[
      // - Initialization and stability in deep networks
      // - Loss landscapes and optimization schedules
      // - Bias-variance trade-off when increasing capacity
      // ]
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
        - Caveat: this advantage assumes the target admits a *smooth compositional* KAN/KAR; we usually do not know this structure a priori.
      ]
      #text(size: 11pt)[@kan-liu2025]
      // [Connections: scaling laws; approximation theory; bias-variance trade-off.]
    ],
    [
      #figure(
        image(fig_path + "model_scaling.pdf", width: 100%),
        caption: [Scaling vs MLP baselines. @kan-liu2025],
      )
    ],
  )
]

#slide(title: [Why symbolic extraction matters (beyond "post-hoc")])[
  #grid(
    columns: (1.05fr, 0.95fr),
    gutter: 0.8cm,
    [
      #color-block(title: [From fit → formula])[
        - Goal: not only predict, but *compress* knowledge into a symbolic law.
        - This turns supervised learning into a form of *scientific discovery*:
          we obtain an explicit equation that can be checked, generalized, and reused.
        - KANs help because intermediate artifacts are readable: 1D edge functions $phi(\cdot)$.
      ]
      #quote-block[
        Interpretability is not an afterthought here; it is an explicit objective.
      ]
    ],
    [
      #figure(
        image(fig_path + "toy_interpretability_evolution.png", width: 100%),
        caption: [From dense model → sparse graph → symbolic form (schematic). @kan-liu2025],
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
        - Improves accuracy without retraining a larger model from scratch.
      ]
      #text(size: 11pt)[@kan-liu2025]
      // [Connections: model scaling vs training schedules; KAN adds explicit fine-graining.]
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
        - $lambda$: sparsity-accuracy trade-off; too small → dense, too large → underfit.
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

// #slide(title: [Case study (math): knot invariants (unsupervised)])[
//   #grid(
//     columns: (1fr, 1.25fr),
//     gutter: 0.8cm,
//     [
//       #color-block(title: [Unsupervised discovery idea])[
//         - Goal: discover sparse relations among many invariants (not just predict one target).
//         - Train a sparse classifier KAN (shape $[18, 1, 1]$).
//         - Fix the last activation to a Gaussian peak at 0 ⇒ positives satisfy
//           $ sum_(i=1)^18 g_i(x_i) approx 0 $ (read $g_i$ off learned edges).
//         - Sweep seeds + $lambda$ and cluster multiple discovered relations.
//       ]
//     ],
//     [
//       #figure(
//         image(fig_path + "knot_unsupervised.png", width: 100%),
//         caption: [Knot dataset (unsupervised): rediscovered relations. @kan-liu2025 ],
//       )
//     ],
//   )
// ]

#slide(title: [Case study (physics): mobility edges via KANs])[
  #grid(
    columns: (1.1fr, 1fr),
    gutter: 0.8cm,
    [
      #color-block(title: [From data to an order parameter])[
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
        caption: [Mobility-edge discovery before/after symbolic snapping. @kan-liu2025],
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
        - Genetic / heuristic: Eureqa
        - Physics-inspired: AI Feynman
        - NN-based: EQL, OccamNet
        - Program search: PySR
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
        - Trade-off: locality can be computationally expensive; global bases may be faster but lose locality.
      ]
      #text(size: 11pt)[@kan-liu2025]
      // [Connections: catastrophic forgetting; local adaptation; compute reuse in continual settings.]
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
    - Choosing minimal KAN shapes is still an open design problem (we usually don\'t know the target\'s compositional structure).
    - Can KANs replace MLP blocks in CNNs/Transformers without hardware regressions?
  ]
  // [Connections: throughput vs parameter count; hardware efficiency vs expressivity.]
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

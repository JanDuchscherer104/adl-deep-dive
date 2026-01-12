#import "template.typ": *
#import "notes.typ": *


#let fig_path = "figures/"
#let theme_primary_hm = rgb("fc5555")
#let theme_block_bg = rgb("f4f6fb")

#show: definitely-not-isec-theme.with(
  aspect-ratio: "16-9",
  slide-alignment: top,
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
#set text(size: 18pt)

// Style links to be blue and underlined
#show link: set text(fill: blue)
#show link: it => underline(it)

// Make figure captions compact (avoid large "Figure N:" prefixes in slides).
#show figure.caption: it => {
  set text(size: 18pt, fill: gray)
  it.body
}

#show ref: set text(size: 12pt)

#set grid(gutter: 20pt)
#show list: set par(leading: 0.5em)
#set list(spacing: 1em)

#title-slide(
  title: [Kolmogorov-Arnold Networks],
  subtitle: [#image(fig_path + "kan-intro-flowchart.png", height: 5.2cm)],
)

// DO WE WANT A TOC?
// #slide(title: [Table of Contents])[
//   #grid(
//     columns: (1fr, 1fr),
//     gutter: 0.8cm,
//     [
//       #color-block(title: [Part I: Motivation + Theory])[
//         - From _MLPs_ to _KANs_
//         - KAT vs UAT (theorem shift)
//         - Curse of dimensionality (CoD)
//       ]
//       #color-block(title: [Part II: Architecture + Training])[
//         - KAN layer mechanics (function matrices)
//         - Splines, residual activation, grid updates
//       ]
//     ],
//     [
//       #color-block(title: [Part III: Accuracy + Scaling])[
//         - Scaling laws + grid extension
//         - PDEs + scientific fitting
//       ]
//       #color-block(title: [Part IV: Interpretability + Critique])[
//         - Sparsify → prune → symbolify
//         - Practical limits and open questions
//       ]
//     ],
//   )
// ]

#section-slide(
  title: [Introduction to Kolmogorov-Arnold Networks],
  //subtitle: [From fixed activations to learnable 1D edge functions],
)[
  #figure(
    image(fig_path + "mlp-vs-kan2.png", width: 100%),
    caption: [MLP vs KAN overview.],
  )
]

// START PART I: FELIX' PART
// #slide(title: [Motivation])[
//   #color-block(title: [Why KANs?])[
//     - Interpretability: learned *1D edge functions* can be inspected and simplified.
//     - Parameter efficiency on scientific tasks. @liu_kan_2025
//     - Better inductive bias when the target is smooth + compositional (common in physics/biology). @liu_kan_2025
//   ]
// ]

#slide(title: [MLPs: strengths and structural limits])[
  #grid(
    columns: (1.2fr, 1fr),
    gutter: 30pt,
    [
      // NOTE: By “structure-aware” I mean: vanilla MLPs do not *explicitly enforce or prefer* compositional / modular / symbolic structure. They can approximate anything, but any compositional structure must be discovered implicitly. Stronger inductive biases can encode prior knowledge and make internal structure easier to inspect or extract.
      #quote-block()[MLPs are universal approximators — but not structure-aware.]

      #v(10pt)
      #color-block(title: [Structural limitations], spacing: 0.55em)[
        - *Interpretability*: Knowledge is contained in distributed parametric pattern; individual components are _not_ meaningful by design.
        // Interpretability does not come naturally.
        - *Entangled degrees of freedom*: the same parameters encode both structure and precision.
      ]

      #v(15pt)

    ],
    [
      #figure(caption: [A small MLP (structure and precision are intertwined)])[
        #image(fig_path + "mlp_simple.png", height: 80%)
      ]
    ],
  )
  #text(size: 22pt)[
    #align(center + horizon)[
      #note[
        + Can we separate _what_ is computed from _how precisely_ it is computed?
        + Can we design a network that is equally expressive but more interpretable?
      ]
    ]
  ]
]

#slide(title: [Features of KANs])[
  #grid(
    columns: 3,
    // gutter: 20pt,
    [
      #color-block(title: [Where KANs work well])[
        #block(height: 8cm)[
          - Built for _smooth + compositional_ relationships
          - Matches structure common in physics / biology
          - Allocate capacity where needed (local splines)
        ]
      ]
    ],
    [
      #color-block(title: [Efficient in  science tasks])[
        #block(height: 8cm)[
          - Often similar error with fewer parameters than MLP baselines
          - Function fitting and differential-equation solving (common in science)
          - Precision scales independently from structure
          // - Supports incremental and localized updates.

        ]
      ]
    ],

    [
      #color-block(title: [Interpretability])[
        #block(height: 8cm)[
          - Inidividual components / connections are meaningful.
          - Can be inspected, pruned, simplified into compact relations
          - Extract a symbolic equation from the trained model
        ]
      ]
    ],
  )
  @liu_kan_2025
]

#slide(title: [MLP vs KAN: Visual comparison])[
  #figure(
    image(fig_path + "mlp-vs-kan3.png", height: 90%),
    caption: [MLP vs. KAN visualization (learnable parts in blue, fixed in pink) @serranoacademy_kolmogorov-arnold_2024],
  )
]

//  TODO: ensure to touch "both can be represented as dense bipartite graphs" (input to hidden, hidden to output)
#slide(title: [From MLPs to KANs])[
  // #color-block(title: [Same layout, different nonlinearity])[
  //   - MLP: scalar weights $w_(j,i)$ on edges; fixed activation $sigma$ on nodes.
  // ]

  #grid(
    columns: 2,
    gutter: 30pt,
    [
      #color-block(title: [MLP])[
        - Scalar weights $w_(j,i)$ on edges.
        - Fixed activation functions $sigma$ on nodes.

          #v(0.2em)
          #text(size: 16pt)[
            $ bold(x)_(l+1) = sigma(bold(#text(fill: green)[$W$])_l bold(x)_l + bold(#text(fill: green)[$b$])_l) $
          ]

          *Learnable weights + fixed activations*

      ]
    ],
    [
      #color-block(title: [KAN])[
        - Each edge is a *learnable 1D function* $phi_(j,i)(x)$
        - Nodes add input → interpret learned functions.

        #v(0.2em)
        #text(size: 16pt)[
          $ x_(l+1,j) = sum_(i=1)^(n_l) #text(fill: green)[$phi$] _(l,j,i)(x_(l,i)) $
        ]

        *Nodes add, function on edges are learned*
      ]
    ],
  )

  #v(0.35em)
  #align(horizon + center)[
    #good-note([
      Same dense bipartite wiring.

      Activations become learnable & move from nodes to edges.
    ])
  ]
  @liu_kan_2025
]

// #slide(title: [From MLPs to Kolmogorov-Arnold Networks (KANs)])[
//   #color-block(title: [Same wiring, different learnable object])[
//     Same basic layout as MLPs (fully connected layers):

//     - MLP: scalar weight $w_(i,j)$ on each edge, fixed activation $sigma$ on neurons.
//     - KAN: each edge has a learnable 1D function $Phi_(i,j)(x)$ (e.g., spline).
//       - Neurons just add inputs.
//   ]
// ]



#slide(title: [The Kolmogorov-Arnold theorem])[
  #grid(
    columns: 2,
    [
      #color-block(title: [])[
        - Any continuous $f(x_1, dots, x_n)$ on $[0,1]^n$ can be represented using *1D functions + addition*.

        - The only _true_ multivariate operation is *sum*; everything else can be composed from univariate transforms + additions.

        // - 1D functions can be approximated very well (e.g., with splines).
        - Spines are well-suited to approximate 1D functions efficiently.
      ]
      #text(size: 12pt)[@liu_kan_2025]
    ],
    box(height: 100%)[
      #align(center)[
        // #set text(size: 40pt)
        #figure(caption: [Kolmogorov-Arnold Theorem@liu_kan_2025])[
          $
            f(bold(x))= f(x_1, dots, x_n) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p))
          $
        ]

        #v(60pt)

        #figure(caption: [KAT representation example for $x y$\ ($(x + y)^2/2$ requires 1D summary of $t = x + y$)])[
          #set text(size: 26pt)
          $x y = - x^2/2 - y^2/2 + (x+y)^2/2$
          #v(15pt)
        ]

      ]

      // #v(50pt)
      // #good-note([*Simple splines can approximate high-dimensional functions*])
    ],
  )
]

// #slide(title: [The Kolmogorov-Arnold Theorem])[

//   #figure(
//     caption: [
//       // #set text(size: 20pt)
//       If $f$ is a multivariate continuous function,it can be written as a finite composition of cnoninuous functios of a  single variable and addation. (True for $f: [0,1]^n -> RR$, where $Phi q, p: [0,1] -> RR$ and $Phi q: RR -> RR$)@liu_kan_2025],
//   )[
//     #align(center)[
//       // #set text(size: 30pt)
//       $
//         f(bold(x))= f(x_1, dots, x_n) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p))
//       $
//     ]
//   ]
// ]



#slide(title: [Splines])[
  #v(30pt)
  #grid(
    columns: (1.1fr, 1fr),
    [
      - *Smooth*, *piecewise-polynomial* & *locally bounded* functions of one variable $x$.
      // - Controlled by by 3 knots + 2 neighboring knots + coefficients.
      - Approximate 1D functions well with few parameters.

      - Controlled by knots $B_(m)(x)$ + coefficients $c_m$.

      - Each Spline is a combination of many cubic Basis Splines (B-Splines)

        $
          phi_(j,i)(x) = sum_(m=0)^(G+k-1) c_m B_(m)(x)
        $
      @liu_kan_2025@serranoacademy_kolmogorov-arnold_2024

      // - Basis Splines (B-Splines)
      //   - use a basis function
      //   - e.g. const, quadratic, polynomial
      //   - bounded to a range of $x$

      // - Out of range, a residual function is used

      // #color-block(title: [Splines in KANs])[
      //   - Each edge learns its own spline $phi_(j,i)(x)$
      //   - Each requires only a few learnable parameters
      // ]

    ],
    [

      #figure(
        image(fig_path + "cubic_bspline_basis_3_nonuniform.svg", width: 100%),
        caption: [Edge function (dashed): linear combination of $G=3$ B-Splines wiofth degree $k=3$],
      )

      #v(20pt)

      #quote-block()[In KANs, each edge learns its own 1D spline $phi_(i,j)(x)$. @liu_kan_2025]
    ],
  )
]

// #slide(title: [Splines (example)])[
//   #grid(
//     columns: (20%, 80%),
//     gutter: 10pt,
//     [
//       0.5\
//       0.2\
//       0.7
//     ],
//     [
//       #image(fig_path + "spline (1).png", width: 100%)
//     ],
//   )
// ]

// #slide(title: [Splines in KANs])[
//   #grid(
//     columns: 2,
//     gutter: 30pt,
//     [
//       - Smooth *piecewise-polynomial* functions of one variable $x$
//       - Controlled by knots + coefficients → flexible local curves
//       - Approximate 1D functions very well with _few parameters_

//       #v(30pt)

//       #quote-block()[In KANs, each edge learns its own 1D spline $phi_(i,j)(x)$. @liu_kan_2025]
//     ],
//     [
//       #figure(
//         image(fig_path + "spline_notation.png", width: 100%),
//         caption: [Spline notation and grid refinement. @liu_kan_2025],
//       )
//     ],
//   )
// ]

// I think the nonlinearity is sufficiently introduced in earlier slides already
// #slide(title: [MLP vs KAN (shallow): where does nonlinearity live?])[
//   #grid(
//     columns: (1.25fr, 1fr),
//     [
//       #figure(
//         image(fig_path + "kan_mlp_shallow.png", width: 100%),
//         caption: [Shallow MLP vs shallow KAN (Fig. 0.1a,b). @liu_kan_2025],
//       )
//       #v(0.25em)
//       #color-block(title: [Key idea])[
//         - MLP: fixed activation $sigma$ on nodes; learn weights $w_(j,i)$ on edges.
//         - KAN: learn 1D edge functions $phi_(q,p)$; nodes only sum inputs.
//         - Intuition: learn expressive 1D building blocks, then compose across layers.
//         - Sum is the only multivariate operation (no explicit products).
//         - Example trick: $x dot y = exp(log x + log y)$ shows how products can be expressed by univariate maps + addition.
//       ]
//     ],
//     [
//       #color-block(title: [Shallow formulas])[
//         - MLP / UAT-style:
//           $ f(bold(x)) approx sum_(j=1)^m a_j sigma(bold(w)_j^T bold(x) + b_j) $
//         - KAN / KAT-style:
//           $ f(bold(x)) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p)) $
//       ]
//       #text(size: 11pt)[@liu_kan_2025]

//       //[Connections: fixed vs learnable nonlinearity; inductive bias towards symbolic/compositional structure.]
//     ],
//   )
// ]

// #slide(title: [MLP vs KAN (deep): what gets learned?])[
//   #grid(
//     columns: (1.25fr, 1fr),
//     [
//       #figure(
//         image(fig_path + "kan_mlp_deep.png", width: 100%),
//         caption: [Deep MLP vs deep KAN (Fig. 0.1c,d). @liu_kan_2025],
//       )
//       #v(0.25em)
//       #color-block(title: [Deep takeaway])[
//         - Deep MLPs: learn linear maps $bold(W)_l$; nonlinearity stays fixed.
//         - Deep KANs: learn function matrices $bold(Phi)_l$ (one 1D function per edge).
//         - Practical upside: plot/inspect learned edge functions directly.
//       ]
//     ],
//     [
//       // TODO replace ∘ with poper typst symbol for function composition
//       #color-block(title: [Deep composition])[
//         - Deep MLP:
//           $
//             "MLP"(bold(x)) = (bold(W)_(L-1) compose sigma compose bold(W)_(L-2) compose ... compose sigma compose bold(W)_0)(bold(x))
//           $
//         - Deep KAN:
//           $ "KAN"(bold(x)) = (bold(Phi)_(L-1) compose ... compose bold(Phi)_0)(bold(x)) $
//       ]
//       @liu_kan_2025

//       #v(0.2em)
//       #color-block(title: [Interpretation])[
//         - MLP: learn linear maps $bold(W)$; nonlinearity is fixed.
//         - KAN: learn edge functions $phi_(l,j,i)$; nodes are sums.
//       ]
//     ],
//   )
// ]

#slide(title: [Can KAT represent any high-dimensional function?])[
  #quote-block()[
    // Classical KAT is elegant, but the required 1D inner functions can be non-smooth/fractal → hard to learn in practice.
    Classical KAT is elegant, but resulting 1D inner functions can be non-smooth or fractal
    - Hard to learn in 2 Layer MLPs in practice
    - Earlier research described it as _“theoretically sound but practically useless"_@girosi_representation_1989@poggio_theoretical_2019
  ]
  #v(30pt)
  #color-block(title: [Mitigation])[
    // - Classical KAT guarantees existence, but inner 1D functions can be highly non-smooth/fractal.
    // - Mitigation: go beyond the rigid depth-2, width $(2n+1)$ form → use deeper/wider KANs.
    // - In many real tasks we expect smooth, compositionally sparse structure, making KAT-like forms learnable.
    // - This counts especially for scientific datasets, where underlying laws are often smooth and compositional.
    - Don't stick to the rigid depth-2, width $(2n+1)$ form
      - use deeper/wider KANs to admit smoother representations (_Use more than 2 layers_)
    #v(0.8em)
    - In real tasks we often expect smooth + compositionally sparse structure
      - most typical cases allows smooth KA-like representations
  ]
]

#slide(title: [Curse of Dimensionality])[
  #quote-block()[More input dimensions #sym.arrow.r combinations explode #sym.arrow.r exponential growth of parameters]

  ===== MLPs
  - Universal Approximation Theorem: 2-layer MLP can _approximate any continuous f_
  - But no efficiency guarantee
    - _width_ can grow _exponentially_ with dimension (CoD in practice)

  ===== KANs
  - _Stack layers_ to learn compositional structure (feature learning)
  - Replace weights with learnable 1D functions
  - No high-D spline grid:
    - many _1D splines + sums_, can beat CoD when the target is _smooth + compositional_
]

/*
#slide(title: [Curse of dimensionality: where the pain shows up])[
  #grid(
    columns: (1fr, 1fr),
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
    [
      #color-block(title: [UAT (MLPs)])[
        - Statement: 2-layer nets can approximate any continuous $f$ on a compact domain.
        - Learnable parts: $bold(W), bold(b)$ (activations fixed).
        - Caveat: existence result; rates can still suffer from dimensionality.

        $ f(bold(x)) approx sum_(j=1)^m a_j sigma(bold(w)_j^T bold(x) + b_j) $

        @liu_kan_2025
      ]
    ],
    [
      #color-block(title: [KAT (Kolmogorov-Arnold)])[
        - Statement: represent $f:[0,1]^n -> RR$ via sums of 1D functions + addition.
        - Promise: reduce multivariate learning to learning many 1D functions.
        - Caveat: worst-case representations can be highly non-smooth/fractal.

        $ f(bold(x)) = sum_(q=1)^(2n+1) Phi_(q)(sum_(p=1)^n phi_(q,p)(x_p)) $

        @liu_kan_2025
      ]
    ],
  )

  #v(0.2em)
  #text(
    size: 12pt,
    fill: gray,
  )[KAN viewpoint: assume smooth/compositional structure; learn $phi$ with splines and add depth to avoid pathological 2-layer forms. @liu_kan_2025]
]
*/
#slide(title: [KAN layer (definition + shape)])[
  #grid(
    columns: (1.4fr, 0.95fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Layer = matrix of 1D functions], spacing: 0.5em)[
        - Each edge learns a univariate function
        $ phi_(l,j,i): RR -> RR. $

        - Activation of the $j$-th neuron in layer $l+1$: // as sum of incoming signals

        $ x_(l+1,j) = sum_(i=1)^(n_l) phi_(l,j,i)(x_(l,i)) $

        // - $n_l$ nodes in layer $l$ (shape $[n_0, dots, n_L]$).\
        //   Indices: $i$ input, $j$ output.
        - A single KAN layer can be written in *matrix form*:

        #text(size: 16pt)[
          $
            bold(x)_(l+1) =
            underbrace(
              mat(
                phi_(l,1,1)(dot.c), phi_(l,1,2)(dot.c), dots, phi_(l,1,n_l)(dot.c);
                phi_(l,2,1)(dot.c), phi_(l,2,2)(dot.c), dots, phi_(l,2,n_l)(dot.c);
                dots.v, dots.v, , dots.v;
                phi_(l,n_(l+1),1)(dot.c), phi_(l,n_(l+1),2)(dot.c), dots, phi_(l,n_(l+1),n_l)(dot.c)
              ),
              #v(0.5cm) #text(size: 26pt)[$bold(Phi)_l in (RR -> RR)^(n_(l+1) times n_l)$]
            )
            bold(x)_l
            \
          $
        ]

      ]
    ],
    [
      #figure(
        image(fig_path + "spline_notation_kan_only.png", width: 60%),
        caption: text(size: 12pt, fill: gray)[B-spline parametrization and grid refinement. @liu_kan_2025],
      )

      #color-block(title: [General KAN with $L$ layers])[#text(size: 16pt)[
          $
            "KAN"(bold(x)) =
            (bold(Phi)_(L-1) compose bold(Phi)_(L-2) compose dots compose bold(Phi)_0)(bold(x))\
          $
          KART #sym.image KAN of shape $[n arrow.r 2n+1 arrow.r 1]$
        ]
      ]],
  )
]
// TODO: add slide on examle fn exp(sin(x1^2 + x2^2)+ sin(x3^2 + x4^2)) - resulting shape.

#slide(title: [Edge Functions - Residual Splines])[
  #grid(
    columns: (1.05fr, 0.95fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Edge - Residual Spline], spacing: 0.55em)[
        $
          phi(x) = #text(fill: green)[$w_b$] b(x) + #text(fill: green)[$w_s$] sum_i #text(fill: green)[$c_i$] #text(fill: red)[$B_(i)(x)$]
        $

        - Trainable (per edge, backprop): #text(fill: green)[$c_i$], #text(fill: green)[$w_b$], #text(fill: green)[$w_s$]
        - #text(fill: red)[$B_(i)(x)$]: B-spline basis functions (fixed *given the current knot*).
        - $b(x)$: fixed *global* non-linearity (i.e. SiLU).
          #v(0.1em)
          #text(size: 16pt)[
            1. Ensure $phi$ is well-defined on $RR$
            2. Residual path eases optimization -- learn deviation from $b(x)$ rather than full function
          ]
      ]
    ],
    [
      #figure(
        image(fig_path + "silu_minimal.svg", width: 60%),
        caption: [SiLU base function $b(x)$.],
      )
      // TODO: should we move this to the previous section "Splines in KANs"?
      #color-block(title: [Why splines?])[
        - *local*, *translation-invariant* \
          #text(size: 14pt)[
            - local capacity allocation \
            - continual learning #sym.arrow.t
            - catastrophic forgetting #sym.arrow.b
          ]
        - Allows for other basis functions (Fourier, Chebyshev).
        - Locality #sym.arrow.l.r global efficiency.
      ]
    ],
  )
]

#slide(title: [Grid Update - Knot Relocation])[
  #grid(
    columns: (1fr, 1.4fr),
    [
      #color-block(title: [Keep knots where the data lives], spacing: 0.55em)[
        - _Non-stationary_ activations in training, but splines live on bounded grid
        - #strong[Grid update:] periodically estimate activation distributions; _move knots_ to maintain coverage//(e.g., via quantiles).
        - Not by backprop: _non-differentiable reparameterization_
      ]
      #figure(
        image(fig_path + "two_gaussians_drift_minimal.svg", width: 72%),
        caption: text(size: 12pt)[Activation drift motivates knot relocation.],
      )
    ],
    [
      #figure(
        image(fig_path + "spline_notation_grid_extension.jpg", width: 79%),
      )
      // #text(size: 15pt)[
      #quote-block[
        _Grid updates_ reallocate representational capacity at *fixed number of knots* (contrast: grid extension adds knots).
      ]
    ],
  )
]
#slide(title: [Grid Extension: Curriculum over Spatial Resolution])[
  #grid(
    columns: (1fr, 0.8fr),
    gutter: 0.8cm,
    [
      #color-block(title: [Key idea], spacing: 0.55em)[
        - *Grid extension*: add knots ($G$ #sym.arrow.r $G'$) #sym.arrow.r higher spline resolution.
        - Curriculum-style schedule:
          1. Start with coarse spatial resolution -- fewer knots, global structure, simpler optimization.
          2. Gradually increase resolution, initialize finer splines via least-squares fit to coarse spline.

        - Monitor validation error to stop grid extension once improvement ceases.
        // - Validation-guided capacity scheduling: stop grid extension once validation error stops improving.
      ]

      // TODO: page on Internal vs External DOF!
      // #color-block(title: [Why this works], spacing: 0.55em)[
      //   - Two kinds of capacity:
      //     - *External DOF*: width/depth → learns **compositional structure**.
      //     - *Internal DOF*: spline grid → learns **1D function precision**.
      //   - Grid extension increases *internal* DOF only.
      //   - Warm start: finer splines are initialized by least-squares fitting the coarse spline (per edge).
      // ]

      // #quote-block[
      //   Interpretation: grid extension is *adaptive mesh refinement* in function space.
      // ]

    ],
    [
      #figure(
        image(fig_path + "extend_grid_left.png", width: 100%),
        caption: [Staircase-like loss drops after each grid refinement. @liu_kan_2025],
      )
      #v(0.4em)
      #text(size: 14pt)[
        $
          {c'_j} =
          op("argmin", limits: #true)_(\{c'_j\})
          bb(E)_(x ~ p(x))
          (sum_(j=0)^(G_2+k-1) c'_j B'_(j)(x) - sum_(i=0)^(G_1+k-1) c_i B_(i)(x))^2
        $
      ]
    ],
  )
]

#slide(title: [External vs internal DoF: structure vs precision])[
  #color-block(title: [Two kinds of degrees of freedom (DoF)], spacing: 0.55em)[
    - *External DoF*: the computation graph (width / depth / connectivity) → learns *how variables interact*.
    - *Internal DoF*: resolution inside each 1D function (spline grid $G$, coefficients) → learns *how precisely* a subfunction is represented.
    - KANs combine both: MLPs have external DoF (no fine-graining); splines have internal DoF (no compositional graph). @liu_kan_2025
  ]

  #grid(
    columns: 2,
    gutter: 30pt,
    box(height: 70%)[
      #color-block(title: [MLPs: external DoF dominates], spacing: 0.55em)[
        - Scaling accuracy usually means increasing width/depth (new graph capacity).
        - No internal “refinement knob”: node activations are fixed.
        - Consequence: improving one region can perturb the function globally.
      ]
      #set align(center)
      #good-note([Structure and precision are entangled.])
    ],
    box(height: 70%)[
      #color-block(title: [KANs: external + internal DoF], spacing: 0.55em)[
        - External DoF (graph shape) learns *compositional structure*.
        - Internal DoF (splines on edges) refines *local precision*.
        - Grid extension increases internal DoF while keeping the graph fixed. @liu_kan_2025
      ]
      #set align(center)
      #good-note([External structure and internal precision can be scaled separately.])
    ],
  )

  // #v(10pt)
  // #quote-block[
  //   Next: simplify *external* DoF via sparsify → prune, then simplify *internal* DoF via symbolification.\
  //   Bonus: internal DoF are local in input space → local plasticity → less catastrophic forgetting.
  // ]
]

// #section-slide(title: [Interpretability & philosophy])[
//   #figure(
//     image(fig_path + "toy_interpretability_evolution.png", width: 100%),
//     caption: [From dense KAN → sparse graph → symbolic form (schematic). @liu_kan_2025],
//   )
// ]

// TODO: computational complexity of KAN vs MLP.
//

// #section-slide(title: [Accuracy & Scaling], subtitle: [How KANs generalize and grow])[
//   #figure(
//     image(fig_path + "model_scaling.pdf", width: 100%),
//     caption: [Fast scaling trends on structured function classes. @liu_kan_2025],
//   )
// ]

// #slide(title: [Scaling laws])[
//   #grid(
//     columns: 2,
//     [
//       #figure(
//         image(fig_path + "model_scaling.pdf", width: 80%),
//         caption: [Scaling vs MLP baselines. @liu_kan_2025],
//       )
//       #color-block(title: [Theory + observation])[
//         - Smooth-KAT bound: $|f - "KAN"_G| <= C G^(-(k+1))$ (cubic: $k=3 -> alpha approx 4$).
//         - Comparison: manifold view ($alpha approx (k+1)/d$) vs arity view ($alpha approx (k+1)/2$).
//         - Empirically: KANs reach steeper scaling than MLPs on compositional data.
//         - Caveat: this advantage assumes the target admits a *smooth compositional* KAN/KAR; we usually do not know this structure a priori.
//       ]
//       @liu_kan_2025
//       // [Connections: scaling laws; approximation theory; bias-variance trade-off.]
//     ],
//     [
//       #figure(
//         image(fig_path + "model_scaling.pdf", width: 100%),
//         caption: [Scaling vs MLP baselines. @liu_kan_2025],
//       )
//     ],
//   )
// ]

// #slide(title: [Why symbolic extraction matters])[
//   #grid(
//     columns: 2,
//     [
//       #color-block(title: [From fit → formula])[
//TODO<INCLUDE>
//         - Goal: not only predict, but *compress* knowledge into a symbolic law.
//TODO</INCLUDE>
//         - This turns supervised learning into a form of *scientific discovery*:
//           we obtain an explicit equation that can be checked, generalized, and reused.
//         - KANs help because intermediate artifacts are readable: 1D edge functions $phi(\cdot)$.
//       ]
//       #quote-block[
//         Interpretability is not an afterthought here; it is an explicit objective.
//       ]
//     ],
//     [
//       #figure(
//         image(fig_path + "toy_interpretability_evolution.png", width: 100%),
//         caption: [From dense model → sparse graph → symbolic form (schematic). @liu_kan_2025],
//       )
//     ],
//   )
// ]


// #section-slide(title: [Interpretability & Science], subtitle: [From pruning to symbolic laws])[
//   #figure(
//     image(fig_path + "interpretable_examples_short.png", width: 100%),
//     caption: [Symbolic recovery examples from pruned/simplified KANs. @liu_kan_2025],
//   )
// ]

// #slide(title: [Interpretability toolkit: sparsify, prune, symbolify])[
//   #grid(
//     columns: 2,
//     [
// #color-block(title: [Four steps to a formula])[
//   - Sparsify: encourage few active edges (L1 + entropy).
//   - Visualize: inspect learned 1D edge functions $phi_(l,j,i)$.
//   - Prune: drop inactive nodes to a minimal shape $[n_0, ..., n_L]$.
//   - Symbolify: snap splines to analytic forms with an affine wrapper
//     $ y approx c f(a x + b) + d $
//     (grid search for $a,b$; linear regression for $c,d$).
// ]
//       @liu_kan_2025
//     ],
//     [
//       #figure(
//         image(fig_path + "toy_interpretability_evolution.png", width: 100%),
//         caption: [Sparsification + pruning yields simpler, more interpretable KANs. @liu_kan_2025],
//       )
//     ],
//   )

// ]


// #slide(title: [Connectionism ↔ Symbolism])[
//   #grid(
//     columns: 3,
//     gutter: 25pt,
//     [
//       #color-block(title: [Connectionism], spacing: 0.55em)[
//         - Learning via gradient descent.
//         - Parameters optimized end-to-end.
//       ]
//     ],
//     [
//       #color-block(title: [Reductionism], spacing: 0.55em)[
//         - Meaningful intermediate parts.
//         - Inspectable edge functions.
//       ]
//     ],
//     [
//       #color-block(title: [Symbolism], spacing: 0.55em)[
//         - Explicit formulas after training.
//         - Human-readable scientific laws.
//         -
//       ]
//     ],
//   )

//   #v(15pt)
//   #quote-block[
//     KANs are connectionist during training and symbolic at readout due to their _reductionist_ structure.
//   ]
// ]

#slide(title: [Sparsification & Symbolification])[
  #grid(
    columns: (2fr, 1fr),
    [
      #figure(
        image(fig_path + "sr.png", width: 100%),
        caption: [Interactive workflow for symbolic regression with KANs. @liu_kan_2025],
      )
    ],
    [
      #color-block(title: [Simplify the DoF (structure #sym.arrow.r equation)], spacing: 0.55em)[
        + *Sparsify* edge functions: L1 penality + entropy regularization.
        + *Prune* to a minimal shape (discover external structure).
        + *Symbolify* edge functions: replace splines with $y approx c f(a x + b) + d$.
        + Retrain only affine parameters and export a symbolic formula (human-in-the-loop). @liu_kan_2025
      ]
    ],
  )
]



//
#slide(title: [Continual learning and locality])[
  #grid(
    columns: 2,
    [
      #color-block(title: [Local plasticity])[
        - B-spline bases are local: one sample updates only a few *nearby* spline coefficients.
        - Previously learned regions stay intact → reduced catastrophic forgetting (toy sequential peaks).
        - MLPs use global activations (ReLU/Tanh/SiLU): local updates can propagate broadly → interference.
        - Caveat: results are preliminary; “locality” in high dimensions is less clear. @liu_kan_2025
      ]
      // [Connections: catastrophic forgetting; local adaptation; compute reuse in continual settings.]
    ],
    [
      #figure(
        image(fig_path + "continual_learning.pdf", width: 100%),
        caption: [Continual learning experiments. @liu_kan_2025],
      )
    ],
  )
]



//  TODO: split into takeaways and limitations color-block
#slide(title: [Summary + discussion prompts])[
  #grid(
    columns: 2,
    gutter: 30pt,
    [
      #color-block(title: [Takeaways])[
        - KANs are most suited for structured, compositional, low-data scientific tasks.
        // TODO: w
        // - KANs move nonlinearity to edges, learning 1D functions directly.
        - Grid extension allows good finetuning and steerable representation capacity.
        - Sparsification enables symbolic interpretability and discovery of symbolic formulas (white-box ML).
      ]
    ],
    [
      #color-block(title: [Limitations])[
        - Training is slower (non-optimized acceleration HW). @liu_kan_2025
        - Limited framework support
        - Still a novel concept, paper released in Feb. 2025
      ]

    ],
  )

  #v(20pt)

  #quote-block([
    *Trade-off: better accuracy/interpretability vs slower training*
  ])

]

// #warning-note([
//   Why are KANS not yet used in production if they offer that much benefit in many scenarios?
//   - Framework support
//   - Not much industrial know how
//   - Is there something else?
// ])

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

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

// #slide(title: [Motivation])[
//   #color-block(title: [Why KANs?])[
//     - Interpretability: learned *1D edge functions* can be inspected and simplified.
//     - Parameter efficiency on scientific tasks. @liu_kan_2025
//     - Better inductive bias when the target is smooth + compositional (common in physics/biology). @liu_kan_2025
//   ]
// ]

#slide(title: [Multi-Layer Perceptrons(MLPs) & its Problems])[
  #grid(
    columns: (1.2fr, 1fr),
    gutter: 30pt,
    [
      #quote-block()[MLPs are powerful universal function approximators]

      #v(10pt)
      #color-block(title: [Drawbacks of MLPs])[
        - Knowledge is contained in "billion" of _weights_
        - Weights are not easily _interpretable_
          - Why do we get the result we get?
      ]

      #v(20pt)
      #note("Can we design a network equally powerful but interpretable?")

    ],
    [
      #figure(caption: [Example of a small Multi-Layer Perceptron(MLP) network])[
        #image(fig_path + "mlp_simple.png", height: 70%)
      ]
    ],
  )
]

#slide(title: [Features of KANs])[
  #grid(
    columns: 2,
    rows: 2,
    [
      #color-block(title: [Why KANs can work well])[
        - Built for _smooth + compositional_ relationships
        - Matches structure common in physics / biology
      ]
    ],
    [
      #color-block(title: [Efficiency on scientific tasks])[
        - Often similar error with fewer parameters than MLP baselines
        - Function fitting and differential-equation solving (common in science)
      ]
    ],

    [
      #color-block(title: [Interpretability])[
        - Each connection is a learned 1D function
        - Can be inspected, pruned, simplified into compact relations
      ]
    ],
    [
      #color-block(title: [From model to equation])[
        - Extract a human readable equation from the trained model
        #v(52pt)
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

#slide(title: [From MLPs to KANs])[
  // #color-block(title: [Same layout, different nonlinearity])[
  //   - MLP: scalar weights $w_(j,i)$ on edges; fixed activation $sigma$ on nodes.
  // ]

  #grid(
    columns: 2,
    color-block(title: [MLP])[
      - scalar weights $w_(j,i)$ on edges
      - fixed activation functions $sigma$ on nodes

      *The weights are learned, the functions are fixed*
    ],
    color-block(title: [KAN])[
      - each edge is a learnable 1D function $phi_(j,i)(x)$
      - Nodes add input → interpret learned functions

      *nodes add, function on edges are learned*
    ],
  )

  #set align(bottom)
  #good-note([*Instead of learning weights, KANs learn functions*])
  #v(50pt)
]

// // Adapted form https://typst.app/project/w3ZP87eMnIzmHrBT2OpRN1
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

        - 1D functions can be approximated very well (e.g., with splines).
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
          $x y =  - x^2/2 - y^2/2 + (x+y)^2/2$
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
      - Smooth *piecewise-polynomial* functions of one variable $x$.

      - Controlled by knots + coefficients → _flexible local curves_
      - Approximate 1D functions well with few parameters

      - Spline is bounded to a region

      - Fully defined by 3 knots + 2 neighboring knots

      - Each Spline is a combination of many cubic Basis Splines (B-Splines)
        

      // - Basis Splines (B-Splines)
      //   - use a basis function
      //   - e.g. const, quadratic, polynomial
      //   - bounded to a range of $x$

      // - Out of range, a residual function is used

      // #color-block(title: [Splines in KANs])[
      //   - Each edge learns its own spline $phi_(j,i)(x)$
      //   - Each requires only a few learnable parameters
      // ]
      @liu_kan_2025@serranoacademy_kolmogorov-arnold_2024
    ],
    [
      // #figure(
      //   // image(fig_path + "spline (1).png", width: 100%),
      //   caption: [Constant B-Splines example\ (simplest type of basis splines)],
      // )

      #figure(
        image(fig_path + "spline_notation.png", width: 100%),
        caption: [Each edge function is a combination of many cubic B-Splines  @liu_kan_2025],
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
  #quote-block()[more input dimensions -> combinations explode -> exponential growth of parameters]

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

// #warning-note(
//   "Remove this KAN LAYER MECHANICS SLIDE? Layers are mentioned before, gets quite mathy,is this actually helpful? And we need to cut somewhere",
// )

// <MERGE: KAN layer section (3 slides)>
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
        $ phi(x) = w_b b(x) + w_s sum_i c_i B_i(x) $

        - Trainable (per edge, backprop): $c_i$, $w_b$, $w_s$
        - $B_(i)(x)$: B-spline basis functions (fixed *given the current knot grid*).
        - $b(x)$: fixed *global* non-linearity
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
      #color-block(title: [Why splines?])[
        - *local*, *translation-invariant* \
          #text(size: 14pt)[
            - local capacity allocation \
            - continual learning #sym.arrow.t
            - catastrophic forgetting #sym.arrow.b
          ]
        - Allows for other basis functions (Fourier, Chebyshev)
        - Locality #sym.arrow.l.r global efficiency.
      ]
    ],
  )
]

#slide(title: [Grid Update - Knot Relocation])[
  #grid(
    columns: (1fr, 1fr),
    gutter: 20pt,
    [
      #color-block(title: [Keep knots where the data lives], spacing: 0.55em)[
        - _Non-stationary_ activations in training, but splines live on bounded grid
        - #strong[Grid update:] periodically estimate activation distributions; _move knots_ to maintain coverage//(e.g., via quantiles).
        - Not by backprop: _non-differentiable reparameterization_
      ]
      #figure(
        image(fig_path + "two_gaussians_drift_minimal.svg", width: 60%),
        caption: text(size: 12pt)[Activation drift motivates knot relocation.],
      )
    ],
    [
      #figure(
        image(fig_path + "spline_notation_grid_extension.jpg", width: 80%),
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
      #text(size: 12pt)[
        $
          c'_j =
          op("argmin")_(\{c'_j\})
          E_(x ~ p(x))
          (sum_(j=0)^(G_2+k-1) c'_j B'_j(x) - sum_(i=0)^(G_1+k-1) c_i B_i(x))^2
        $
      ]
      #text(size: 11pt)[@liu_kan_2025]
    ],
  )
]

#slide(title: [Scaling & Accuracy: MLPs vs. KANs])[


#grid(columns: 2, gutter: 30pt,
box(height: 90%)[
#color-block(title: [MLPs: External DoF = *structure*])[
  - Width, depth, connectivity
  - Determines which variables interact and in what hierarchy
  - Encodes compositional structure

]
#set align(bottom+center)
#good-note([To get more accuracy, we make the whole network bigger])
],
box(height: 90%)[
#color-block(title: [ KANs : internal DoF = *precision*])[
- Parameters that refine a fixed structure.
- In KANs: spline coefficients + knot resolution.
- Encodes *how accurately* each subfunction is represented.

]
#set align(bottom+center)

#good-note([First get the structure right; then sharpen the parts.])
]
)
]

// #section-slide(title: [Interpretability & philosophy])[
//   #figure(
//     image(fig_path + "toy_interpretability_evolution.png", width: 100%),
//     caption: [From dense KAN → sparse graph → symbolic form (schematic). @liu_kan_2025],
//   )
// ]

// TODO: computational complexity of KAN vs MLP.


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
//         - Goal: not only predict, but *compress* knowledge into a symbolic law.
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
//       #color-block(title: [Four steps to a formula])[
//         - Sparsify: encourage few active edges (L1 + entropy).
//         - Visualize: inspect learned 1D edge functions $phi_(l,j,i)$.
//         - Prune: drop inactive nodes to a minimal shape $[n_0, ..., n_L]$.
//         - Symbolify: snap splines to analytic forms with an affine wrapper
//           $ y approx c f(a x + b) + d $
//           (grid search for $a,b$; linear regression for $c,d$).
//       ]
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

// #slide(title: [Interpretability: hyperparameters matter])[
//   #grid(
//     columns: (1fr, 1.25fr),
//     [
//       #color-block(title: [What changes (and why)])[
//         - Entropy regularization: encourages sparse, readable graphs.
//         - $lambda$: sparsity-accuracy trade-off; too small → dense, too large → underfit.
//         - Grid size $G$ + spline order $k$: resolution vs compute (larger $G$ is slower).
//         - Random seeds can reveal different relations in unsupervised discovery.
//       ]
//       @liu_kan_2025
//       #v(0.3em)
//       #text(size: 12pt, fill: gray)[Takeaway: interpretability is an objective + design choice, not a byproduct.]
//     ],
//     [
//       #figure(
//         image(fig_path + "interpretability_hyperparameters.png", width: 100%),
//         caption: [Dependence on regularization, seeds, and spline resolution. @liu_kan_2025],
//       )
//     ],
//   )
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
      #color-block(title: [Step-wise symbolification])[
        - Train with sparsification (L1 weight-decay + entropy).
        - Prune to a minimal graph.
        - Replace splines with suitable symbolic functions.
        - Retrain only affine parameters and export the symbolic formula.
      ]
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
//         caption: [Knot dataset (unsupervised): rediscovered relations. @liu_kan_2025 ],
//       )
//     ],
//   )
// ]

// #slide(title: [Case study (physics): mobility edges via KANs])[
//   #grid(
//     columns: 2,
//     [
//       #color-block(title: [From data to an order parameter])[
//         - Goal: learn the mobility edge separating localized vs extended phases.
//         - Localization metric (eigenstate $bold(psi)^(k)$):
//           $ "IPR"_k = (sum_n |psi_n^(k)|^4) / (sum_n |psi_n^(k)|^2)^2 $
//           $ D_k = - log("IPR"_k) / log(N) $
//         - Train → sparsify/prune → symbolify to recover a compact boundary $g(·)=0$
//           (human-in-the-loop: constrain the symbol library).
//       ]
//     ],
//     [
//       #figure(
//         image(fig_path + "mobility_edge.png", width: 100%),
//         caption: [Mobility-edge discovery before/after symbolic snapping. @liu_kan_2025],
//       )
//     ],
//   )
// ]


//
#slide(title: [Continual learning and locality])[
  #grid(
    columns: 2,
    [
      #color-block(title: [Local plasticity])[
        - B-spline activations are local in input space.
        - Updates can be localized, reducing catastrophic forgetting.
        - Promising for continual or lifelong learning regimes.
        - Trade-off: locality can be computationally expensive; global bases may be faster but lose locality.
      ]
      @liu_kan_2025
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

    ]
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

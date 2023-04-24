import ProofWidgets.Component.InteractiveSvg
import ProofWidgets.Component.HtmlDisplay
import examples.WaveEquation

open Lean
open ProofWidgets Svg Jsx

open SciLean

abbrev State (n : USize) := ℝ^{n} × ℝ^{n}


def frame : Frame where
  xmin := -1
  ymin := -1
  xSize := 2
  width := 400
  height := 400

def isvg (n) [Nonempty (Idx n)] : InteractiveSvg (State n) where
  init := (⊞ i, Real.sin (2*Real.pi*(i.1 : ℝ)/40),
           ⊞ i, 0)

  frame := frame

  update time Δt action mouseStart mouseEnd selected getData state :=
    let m := 1.0
    let k := 10000.0
    solver m k 1 ⟨time⟩ state ⟨0.01*Δt⟩

  render time mouseStart mouseEnd state :=
    {
      elements := Id.run do
        let mut pts : Array (Point frame) := .mkEmpty n.toNat
        -- let mut qts : Array (Point frame) := .mkEmpty n.toNat
        let Δθ := 2*Real.pi / n
        for i in fullRange (Idx n) do
          let θ := i.1 * Δθ
          let r := 0.5 + 0.2*state.1[i]
          pts := pts.push (.abs (r*θ.cos).toFloat (r*θ.sin).toFloat)
          -- qts := qts.push (.abs (-frame.xmin + (i.1.toNat.toFloat/n.toNat.toFloat)*frame.xSize) (0.3*state.1[i].toFloat))
        #[Svg.circle (.abs 0 0) (.abs 2) |>.setFill (1.0,1.0,1.0), 
          Svg.polygon pts |>.setFill (0.95,0.95,0.95) |>.setStroke (0.2,0.2,0.2) (.px 1)]-- ,
          -- Svg.polyline qts |>.setStroke (0.2,0.8,0.2) (.px 1)]
    }

instance : Nonempty (Idx 100) := sorry

open Server RequestM in
@[server_rpc_method]
def updateSvg (params : UpdateParams (State 100)) : RequestM (RequestTask (UpdateResult (State 100))) := (isvg 100).serverRpcMethod params

-- TODO: the tsx file is pretty broken
@[widget_module]
def SvgWidget : Component (UpdateResult (State 100)) where
  javascript := include_str ".." / "lake-packages" / "proofwidgets" / "build" / "js" / "interactiveSvg.js"

def init : UpdateResult (State 100) := {
  html := Html.ofTHtml <div>Init!!!</div>,
  state := { state := (isvg 100).init
             time := 0
             selected := none
             mousePos := none
             idToData := (isvg 100).render 0 none none (isvg 100).init |>.idToDataList}
}

#html <SvgWidget html={init.html} state={init.state}/>

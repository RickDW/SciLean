import SciLean.Notation
import SciLean.Core.Attributes
import SciLean.Core.HasAdjoint

namespace SciLean

class Dagger {α : Sort u} (a : α) {β : outParam $ Sort v} (b : outParam β)

open Lean Elab Term Meta in
elab:max x:term:max "†" : term => withFreshMacroScope do
  _ ← synthInstance (← elabType (← `(Dagger $x ?m)))
  elabTerm (← `(?m)) none


noncomputable
def adjoint {X Y : Type} [SemiHilbert X] [SemiHilbert Y] (f : X → Y) : Y → X :=
  match Classical.propDecidable (has_adjoint f) with
  | isTrue h =>
    let f' := Classical.choose h.has_adjoint
    f'
  | isFalse _ => 0
  
@[default_instance]
instance (f : X → Y) [SemiHilbert X] [SemiHilbert Y] : Dagger f (adjoint f) := ⟨⟩

instance adjoint_hasAdjoint {X Y} [SemiHilbert X] [SemiHilbert Y] (f : X → Y) [HasAdjointT f]
  : HasAdjoint (f†) := sorry_proof


--------------------------------------------------------------------------------

variable {α β γ : Type}
variable {X Y Z : Type} [SemiHilbert X] [SemiHilbert Y] [SemiHilbert Z]
variable {Y₁ Y₂ : Type} [SemiHilbert Y₁] [SemiHilbert Y₂]
variable {ι : Type} [Enumtype ι]

@[simp ↓, autodiff]
theorem id.arg_x.adj_simp
  : (λ x : X => x)† = λ x => x := sorry_proof

@[simp ↓, autodiff]
theorem const.arg_x.adj_simp
  : (λ (x : X) (i : ι) => x)† = λ f => ∑ i, f i := sorry_proof

@[simp ↓, autodiff]
theorem const.arg_y.adj_simp
  : (λ (y : Y) => (0 : X))† = λ y' => (0 : Y) := sorry_proof

@[simp ↓ low-3, autodiff low-3]
theorem swap.arg_y.adj_simp
  (f : ι → Y → Z) [∀ i, HasAdjointT (f i)] 
  : (λ y i => f i y)† = λ g => ∑ i, (f i)† (g i) := sorry_proof

@[simp ↓ low, autodiff low-3]
theorem comp.arg_x.adj_simp
  (f : Y → Z) [HasAdjointT f] 
  (g : X → Y) [HasAdjointT g] 
  : (λ x => f (g x))† = λ z => g† (f† z) := sorry_proof

-- @[simp ↓ low]
-- theorem subst.arg_x.adj_simp
--   (f : X → Y → Z) [HasAdjoint (λ ((x,y) : X × Y) => f x y)] 
--   (g : X → Y) [HasAdjoint g] 
--   : (λ x => f x (g x))† 
--     = λ z =>
--         let f' := (λ (x,y) => f x y)†
--         (f' z).1 + g† (f' z).2
-- := by sorry_proof

-- TODO: add simp guard!
@[simp ↓ low, autodiff low]
theorem diag.arg_x.adj_simp
  (f : Y₁ → Y₂ → Z) [HasAdjointNT 2 f] 
  (g₁ : X → Y₁) [HasAdjointT g₁] 
  (g₂ : X → Y₂) [HasAdjointT g₂] 
  : (λ x => f (g₁ x) (g₂ x))† 
    = λ z => (λ (y₁,y₂) => (g₁† y₁) + (g₂† y₂)) $
             (λ (y₁,y₂) => f y₁ y₂)† z 
:= by sorry_proof

-- This prevents an infinite loop when using `adjoint_of_diag` 
-- with `g₁ = Prod.fst` and `g₂ = Prod.snd`
@[simp ↓ low+1, autodiff low+1]
theorem diag.arg_x.adj_simp_safeguard
  (f : X → Y → Z) [HasAdjointNT 2 f]
  : adjoint (λ xy => f xy.1 xy.2) = (uncurryN 2 f)† := by rfl; done 

@[simp ↓ low, autodiff low]
theorem eval.arg_f.adj_simp
  (i : ι)
  : (λ (f : ι → X) => f i)† = (λ f' j => ([[i = j]] * f' : X))
:= sorry_proof

@[simp ↓ low-1, autodiff low-1]
theorem eval.arg_x.parm1.adj_simp
  (f : X → ι → Z) [HasAdjointT f] (i : ι)
  : (λ x => f x i)† = (λ x' => f† (λ j => ([[i = j]] * x')))
:= 
by 
  rw [comp.arg_x.adj_simp (λ (x : ι → Z) => x i) f]
  simp; done

----------------------------------------------------------------------
  -- These theorems are problematic when used with simp


@[simp ↓ low-1, autodiff low-1] -- try to avoid using this theorem
theorem comp.arg_x.parm1.adj_simp
  (a : α) 
  (f : Y → α → Z) [HasAdjointT (λ y => f y a)]
  (g : X → Y) [HasAdjointT g] 
  : 
    (λ x => f (g x) a)† = λ z => g† ((hold λ y => f y a)† z)
:= by 
  (apply comp.arg_x.adj_simp (λ y => f y a) g); done

example
  (a : α) 
  (f : Y → α → Z) [HasAdjointT (λ y => f y a)]
  (g : X → Y) [HasAdjointT g] 
  : 
    (λ x => f (g x) a)† = λ z => g† ((λ y => f y a)† z)
:= by simp

@[simp ↓ low-1, autodiff low-1] -- try to avoid using this theorem
theorem comp.arg_x.parm2.adj_simp
  (a : α) (b : β)
  (f : Y → α → β → Z) [HasAdjointT (λ y => f y a b)]
  (g : X → Y) [HasAdjointT g] 
  : 
    (λ x => f (g x) a b)† = λ z => g† ((hold λ y => f y a b)† z)
:= by 
  (apply comp.arg_x.adj_simp (λ y => f y a b) g); done

@[simp ↓ low-1, autodiff low-1] -- try to avoid using this theorem
theorem comp.arg_x.parm3.adj_simp
  (a : α) (b : β) (c : γ)
  (f : Y → α → β → γ → Z) [HasAdjointT (λ y => f y a b c)]
  (g : X → Y) [HasAdjointT g] 
  : 
    (λ x => f (g x) a b c)† = λ z => g† ((hold λ y => f y a b c)† z)
:= by 
  (apply comp.arg_x.adj_simp (λ y => f y a b c) g); done

-- theorem adjoint_of_comp_at_point4
-- ...

@[simp ↓ low-1, autodiff low-1] -- try to avoid using this theorem
theorem diag.arg_x.parm1.adj_simp
  (a : α)
  (f : Y₁ → Y₂ → α → Z) [HasAdjointNT 2 (λ y₁ y₂ => f y₁ y₂ a)] 
  (g₁ : X → Y₁) [HasAdjointT g₁] 
  (g₂ : X → Y₂) [HasAdjointT g₂] 
  : (λ x => f (g₁ x) (g₂ x) a)† 
    = λ z => (λ (y₁,y₂) => (g₁† y₁) + (g₂† y₂)) $
             (hold λ (y₁,y₂) => f y₁ y₂ a)† z
:= by 
  (apply diag.arg_x.adj_simp (λ y₁ y₂ => f y₁ y₂ a) g₁ g₂); done

@[simp ↓ low-1, autodiff low-1] -- try to avoid using this theorem
theorem diag.arg_x.parm2.adj_simp
  (a : α) (b : β)
  (f : Y₁ → Y₂ → α → β → Z) [HasAdjointNT 2 (λ  y₁ y₂ => f y₁ y₂ a b)] 
  (g₁ : X → Y₁) [HasAdjointT g₁] 
  (g₂ : X → Y₂) [HasAdjointT g₂] 
  : (λ x => f (g₁ x) (g₂ x) a b)† 
    = λ z => (λ (y₁,y₂) => (g₁† y₁) + (g₂† y₂)) $
             (hold λ (y₁,y₂) => f y₁ y₂ a b)† z
:= by 
  (apply diag.arg_x.adj_simp (λ y₁ y₂ => f y₁ y₂ a b) g₁ g₂); done


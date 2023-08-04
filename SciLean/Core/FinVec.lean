import SciLean.Core.SemiInnerProductSpace

namespace SciLean

class Basis (ι : outParam $ Type v) (K : outParam $ Type w)(X : Type u)  where
  basis : ι → X
  proj  : ι → X → K

class DualBasis (ι  : outParam $ Type v) (K : outParam $ Type w) (X : Type u) where
  dualBasis : ι → X
  dualProj  : ι → X → K

class BasisDuality (X : Type u) where
  toDual   : X → X  -- transforms basis vectors to dual basis vectors
  fromDual : X → X  -- transforma dual basis vectors to basis vectors

section Basis

  instance (K : Type _) [IsROrC K] : Basis Unit K K := 
  {
    basis := λ _ => 1
    proj  := λ _ x => x
  }

  instance (K : Type _) [IsROrC K] : DualBasis Unit K K := 
  {
    dualBasis := λ _ => 1
    dualProj  := λ _ x => x
  }

  instance (K : Type _) [IsROrC K] : BasisDuality K := 
  {
    toDual := λ x => x
    fromDual  := λ x => x
  }

  /-- `ⅇ i` is the i-th basis vector -/
  prefix:max "ⅇ" => Basis.basis
  /-- `ⅇ[X] i` is the i-th basis vector of type `X` -/
  macro:max "ⅇ[" X:term "]" i:term : term => `(Basis.basis (X:=$X) $i)

  /-- `ⅇ' i` is the i-th dual basis vector -/
  prefix:max "ⅇ'" => DualBasis.dualBasis
  /-- `ⅇ'[X] i` is the i-th dual basis vector of type `X` -/
  macro:max "ⅇ'[" X:term "]" i:term : term => `(DualBasis.dualBasis (X:=$X) $i)

  /-- `ⅆ i x` is projection of `x` onto i-th basis vector `ⅇ i` -/
  prefix:max "ⅆ" => Basis.proj
  /-- `ⅆ' i x` is projection of `x` onto i-th dual basis vector `ⅇ' i` -/
  prefix:max "ⅆ'" => DualBasis.dualProj

  instance {X Y ι κ K} [Basis ι K X] [Basis κ K Y] [Zero X] [Zero Y] : Basis (ι ⊕ κ) K (X × Y)  where
    basis := λ i =>
      match i with
      | Sum.inl ix => (ⅇ ix, 0)
      | Sum.inr iy => (0, ⅇ iy)
    proj := λ i x =>
      match i with
      | Sum.inl ix => ⅆ ix x.1
      | Sum.inr iy => ⅆ iy x.2

  instance {X Y ι κ K} [DualBasis ι K X] [DualBasis κ K Y] [Zero X] [Zero Y] : DualBasis (ι ⊕ κ) K (X × Y) where
    dualBasis := λ i =>
      match i with
      | Sum.inl ix => (ⅇ' ix, 0)
      | Sum.inr iy => (0, ⅇ' iy)
    dualProj := λ i x =>
      match i with
      | Sum.inl ix => ⅆ' ix x.1
      | Sum.inr iy => ⅆ' iy x.2

  instance {X Y} [BasisDuality X] [BasisDuality Y] : BasisDuality (X×Y) where
    toDual := λ (x,y) => (BasisDuality.toDual x, BasisDuality.toDual y)
    fromDual := λ (x,y) => (BasisDuality.fromDual x, BasisDuality.fromDual y)

end Basis

class OrthonormalBasis (ι K X : Type _) [Semiring K] [Basis ι K X] [Inner K X] : Prop where
  is_orthogonal : ∀ i j, i ≠ j → ⟪ⅇ[X] i, ⅇ j⟫[K] = 0
  is_orthonormal : ∀ i, ⟪ⅇ[X] i, ⅇ i⟫[K] = 1

open BigOperators
/--
 -/
class FinVec (ι : outParam $ Type _) (K : Type _) (X : Type _) [outParam $ Fintype ι] [IsROrC K] [DecidableEq ι] extends SemiInnerProductSpace K X, Basis ι K X, DualBasis ι K X, BasisDuality X where
  is_basis : ∀ x : X, x = ∑ i : ι, ⅆ i x • ⅇ[X] i
  duality : ∀ i j, ⟪ⅇ[X] i, ⅇ'[X] j⟫[K] = if i=j then 1 else 0
  to_dual   : toDual   x = ∑ i,  ⅆ i x • ⅇ'[X] i
  from_dual : fromDual x = ∑ i, ⅆ' i x •  ⅇ[X] i

theorem basis_ext {ι K X} {_ : Fintype ι} [DecidableEq ι] [IsROrC K] [FinVec ι K X] (x y : X)
  : (∀ i, ⟪x, ⅇ i⟫[K] = ⟪y, ⅇ i⟫[K]) → (x = y) := sorry

theorem dualBasis_ext {ι K X} {_ : Fintype ι} [DecidableEq ι] [IsROrC K] [FinVec ι K X] (x y : X)
  : (∀ i, ⟪x, ⅇ' i⟫[K] = ⟪y, ⅇ' i⟫[K]) → (x = y) := sorry

theorem inner_proj_dualProj {ι K X} {_ : Fintype ι} [DecidableEq ι] [IsROrC K] [FinVec ι K X] (x y : X)
  : ⟪x, y⟫[K] = ∑ i, ⅆ i x * ⅆ' i y :=
by 
  calc 
    ⟪x, y⟫[K] = ∑ i, ∑ j, ⟪(ⅆ i x) • ⅇ[X] i, (ⅆ' j y) • ⅇ' j⟫[K] := by sorry -- rw[← (FinVec.is_basis x), ← (FinVec.is_basis y)]
         _ = ∑ i, ∑ j, (ⅆ i x * ⅆ' j y) * ⟪ⅇ[X] i, ⅇ' j⟫[K] := by sorry -- use linearity of the sum
         _ = ∑ i, ∑ j, (ⅆ i x * ⅆ' j y) * if i=j then 1 else 0 := by simp [FinVec.duality]
         _ = ∑ i, ⅆ i x * ⅆ' i y := sorry -- summing over [[i=j]]  

variable {ι K X} {_ : Fintype ι} [DecidableEq ι] [IsROrC K] [FinVec ι K X]

@[simp]
theorem inner_basis_dualBasis (i j : ι)
  : ⟪ⅇ[X] i, ⅇ' j⟫[K] = if i=j then 1 else 0 :=
by apply FinVec.duality

@[simp]
theorem inner_dualBasis_basis  (i j : ι)
  : ⟪ⅇ'[X] i, ⅇ j⟫[K] = if i=j then 1 else 0 :=
by sorry

@[simp]
theorem inner_dualBasis_proj  (i : ι) (x : X)
  : ⟪x, ⅇ' i⟫[K] = ⅆ i x :=
by 
  calc
    ⟪x, ⅇ' i⟫[K] = ⟪∑ j, ⅆ j x • ⅇ[X] j, ⅇ' i⟫[K] := by sorry -- rw[← (FinVec.is_basis x)]
            _ = ∑ j, ⅆ j x * if j=i then 1 else 0 := by sorry -- inner_basis_dualBasis and some linearity
            _ = ⅆ i x := by sorry

@[simp]
theorem inner_basis_dualProj (i : ι) (x : X)
  : ⟪x, ⅇ i⟫[K] = ⅆ' i x :=
by sorry

@[simp]
theorem proj_basis (i j : ι)
  : ⅆ i (ⅇ[X] j) = if i=j then 1 else 0 :=
by simp only [←inner_dualBasis_proj, inner_basis_dualBasis, eq_comm]; done

@[simp]
theorem dualProj_dualBasis (i j : ι)
  : ⅆ' i (ⅇ'[X] j) = if i=j then 1 else 0 :=
by simp only [←inner_basis_dualProj, inner_dualBasis_basis, eq_comm]; done


instance : FinVec Unit K K where
  is_basis := by simp[Basis.proj, Basis.basis]
  duality := by simp[Basis.proj, Basis.basis, DualBasis.dualProj, DualBasis.dualBasis, Inner.inner]; done
  to_dual := by sorry
  from_dual := by sorry

instance : OrthonormalBasis Unit K K where
  is_orthogonal  := sorry
  is_orthonormal := sorry

-- @[infer_tc_goals_rl]
instance {ι κ K X Y} {_ : Fintype ι} {_ : Fintype κ} [DecidableEq ι] [DecidableEq κ] [IsROrC K] [FinVec ι K X] [FinVec κ K Y]
  : FinVec (ι⊕κ) K (X×Y) where
  is_basis := sorry
  duality := sorry
  to_dual := sorry
  from_dual := sorry

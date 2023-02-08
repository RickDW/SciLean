/- 

  In this file we provide some goodies for Prod 

  Namely 
    1. index access: 
       `(42, 1.0, "hello").get 2 == "hello"`
    2. index set:
       `(42,3.14159,"hello").set 2 "world" = (42,3.14159,"world")`
    3. curry function:
       `curryN 3 (λ ((i,j,k) : Nat×Nat×Nat) => i + j) = (λ i j k => i + j)`
    4. uncurry function
       `uncurryN 3 (λ i j k : Nat => i + j) = λ (i,j,k) => i + j`
 -/ 

----------------------------------------------------------------------

class Prod.Size (α : Type) where
  size : Nat

class Prod.SizeFlat (α : Type) where
  sizeFlat : Nat

instance (priority := low) (α) : Prod.Size α where
  size := 1

instance (priority := low) (α) : Prod.SizeFlat α where
  sizeFlat := 1

instance (α β) [sb : Prod.Size β] : Prod.Size (α×β) where
  size := 1 + sb.size

instance (α β) [sa : Prod.SizeFlat α] [sb : Prod.SizeFlat β] : Prod.SizeFlat (α×β) where
  sizeFlat := sa.sizeFlat + sb.sizeFlat

/-- Size of a product type

Counts types only at the top level, so `A×B` and `(A×B)×C` have both size 2 but `A×B×C` has size 3.
 -/
@[reducible]
def Prod.size {α β : Type} [Prod.Size β] (_ : α × β) : Nat := Prod.Size.size (α × β)

/-- Size of a product type

Counts all types, so `A×B` has flat size 2 and `(A×B)×C` have both `A×B×C` flat size 3.
 -/
@[reducible]
def Prod.sizeFlat {α β : Type} [Prod.SizeFlat α] [Prod.SizeFlat β] 
  (_ : α × β) : Nat := Prod.SizeFlat.sizeFlat (α × β)

--------------------------------------------------------------------------------

class Prod.Get (X : Type) (i : Nat) where
  {type : Type}
  get : X → type

attribute [reducible] Prod.Get.type Prod.Get.get

@[reducible]
instance (priority := low) : Prod.Get X 0 := ⟨λ x => x⟩

@[reducible]
instance : Prod.Get (X×Y) 0 := ⟨λ x => x.fst⟩

@[reducible]
instance [pg : Prod.Get Y n] : Prod.Get (X×Y) (n+1) := ⟨λ x => pg.get x.snd⟩

abbrev Prod.get {X Y} (i : Nat) [pg : Prod.Get (X×Y) i] (x : X×Y) := pg.get x

--------------------------------------------------------------------------------

class Prod.Set (X : Type) (i : Nat) (T : outParam Type) where
  seti : X → T → X

attribute [reducible] Prod.Set.seti

@[reducible]
instance (priority := low) : Prod.Set X 0 X := ⟨λ x x₀ => x₀⟩

@[reducible]
instance : Prod.Set (X×Y) 0 X := ⟨λ (x,y) x₀ => (x₀,y)⟩

@[reducible]
instance {X Y : Type} {Yₙ : outParam Type} [pg : Prod.Set Y n Yₙ] 
  : Prod.Set (X×Y) (n+1) Yₙ := ⟨λ (x,y) y₀ => (x, pg.seti n y y₀)⟩

abbrev Prod.set {X Xs : Type} {Xᵢ : outParam Type} 
  (i : Nat) [pg : Prod.Set (X×Xs) i Xᵢ] (x : X×Xs) (xi) := pg.seti i x xi

--------------------------------------------------------------------------------

class Prod.Uncurry (n : Nat) (F : Type) (Xs : outParam Type) (Y : outParam Type) where
  uncurry : F → Xs → Y

attribute [reducible] Prod.Uncurry.uncurry

@[reducible]
instance (priority := low) {X Y : Type} : Prod.Uncurry 1 (X→Y) X Y where
  uncurry := λ (f : X → Y) (x : X) => f x

@[reducible]
instance {X Y : Type} {Xs' Y' : outParam Type} [c : Prod.Uncurry n Y Xs' Y']
  : Prod.Uncurry (n+1) (X→Y) (X×Xs') Y' where
  uncurry := λ (f : X → Y) ((x,xs) : X×Xs') => c.uncurry n (f x) xs

abbrev uncurryN {F : Type} {Xs Y : outParam Type} 
  (n : Nat) (f : F) [Prod.Uncurry n F Xs Y] 
  := Prod.Uncurry.uncurry (n:=n) f


--------------------------------------------------------------------------------

class Prod.Curry (n : Nat) (Xs : Type) (Y : Type) (F : outParam Type) where
  curry : (Xs → Y) → F

attribute [reducible] Prod.Curry.curry

@[reducible]
instance (priority := low) : Prod.Curry 1 X Y (X→Y) where
  curry := λ (f : X → Y) => f

@[reducible]
instance {X Xs Y : Type} {F : outParam Type} [c : outParam $ Prod.Curry n Xs Y F] 
  : Prod.Curry (n+1) (X×Xs) Y (X→F) where
  curry := λ (f : X×Xs → Y) => (λ (x : X) => c.curry n (λ y => f (x,y)))

abbrev curryN {Xs Y : outParam $ Type} {F : outParam Type} 
  (n : Nat) (f : Xs → Y) [outParam $ Prod.Curry n Xs Y F] := Prod.Curry.curry n f

--------------------------------------------------------------------------------

section Tests

  example : (42,3.14159,"hello").get 0 = 42 := by rfl
  example : (42,3.14159,"hello").get 1 = 3.14159 := by rfl
  example : (42,3.14159,"hello").get 2 = "hello" := by rfl
  example : ("hello", (42, 3.14159), "world").get 1 = (42,3.14159) := by rfl

  -- Product is right associative and we respect it
  example : (42,3.14159,"hello").size = 3 := by rfl
  example : (42,(3.14159,"hello")).size = 3 := by rfl
  example : ((42,3.14159),"hello").size = 2 := by rfl
  example : ((42,3.14159),"hello").sizeFlat = 3 := by rfl
  example : ((42,3.14159),("hello","world")).size = 3 := by rfl
  example : ((42,3.14159),("hello","world")).sizeFlat = 4 := by rfl

  example : (42,3.14159,"hello").set 2 "world" = (42,3.14159,"world") := by rfl

  example : uncurryN 3 (λ i j k : Nat => i + j) = λ (i,j,k) => i + j := by rfl
  example : uncurryN 2 (λ i j k : Nat => i + j) = λ (i,j) k => i + j := by rfl

  example : curryN 3 (λ ((i,j,k) : Nat×Nat×Nat) => i + j) = (λ i j k : Nat  => i + j) := by rfl
  -- example : curryN 2 (λ ((i,j,k) : Nat×Nat×Nat) => i + j) = (λ (i : Nat) ((j,k) : Nat×Nat) => i + j) := by rfl

end Tests

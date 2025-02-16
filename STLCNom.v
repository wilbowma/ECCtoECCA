Require Export Omega.
Require Export Metalib.Metatheory.
Require Export Metalib.LibLNgen.


(** Some fresh variables *)
Notation X := (fresh nil).
Notation Y := (fresh (X :: nil)).
Notation Z := (fresh (X :: Y :: nil)).

Inductive n_exp : Set :=
 | n_var (x:atom)
 | n_abs (x:atom) (t:n_exp)
 | n_app (t1:n_exp) (t2:n_exp).

Hint Constructors n_exp.

(** For example, we can encode the expression [(\X.Y X)] as below.  *)

Definition demo_rep1 := n_abs X (n_app (n_var Y) (n_var X)).

(** For example, we can encode the expression [(\Z.Y Z)] as below.  *)

Definition demo_rep2 := n_abs Z (n_app (n_var Y) (n_var Z)).

Fixpoint fv_nom (n : n_exp) : atoms :=
  match n with
  | n_var x => {{x}}
  | n_abs x n => remove x (fv_nom n)
  | n_app t1 t2 => fv_nom t1 `union` fv_nom t2
  end.

(** What makes this a *nominal* representation is that our
    operations are based on the following swapping function for
    names.  Note that this operation is symmetric: [x] becomes
    [y] and [y] becomes [x]. *)

Definition swap_var (x:atom) (y:atom) (z:atom) :=
  if (z == x) then y else if (z == y) then x else z.

(** The main insight of nominal representations is that we can
    rename variables, without capture, using a simple
    structural induction. Note how in the [n_abs] case we swap
    all variables, both bound and free.
    For example:
      (swap x y) (\z. (x y)) = \z. (y x))
      (swap x y) (\x. x) = \y.y
      (swap x y) (\y. x) = \x.y
*)
Fixpoint swap (x:atom) (y:atom) (t:n_exp) : n_exp :=
  match t with
  | n_var z     => n_var (swap_var x y z)
  | n_abs z t1  => n_abs (swap_var x y z) (swap x y t1)
  | n_app t1 t2 => n_app (swap x y t1) (swap x y t2)
  end.


(** Because swapping is a simple, structurally recursive
    function, it is highly automatable using the [default_simp]
    tactic from LNgen library.
    This tactic "simplifies" goals using a combination of
    common proof steps, including case analysis of all disjoint
    sums in the goal. Because atom equality returns a sumbool,
    this makes this tactic useful for reasoning by cases about
    atoms.
    For more information about the [default_simp] tactic, see
    [metalib/LibDefaultSimp.v].
    WARNING: this tactic is not always safe. It's a power tool
    and can put your proof in an irrecoverable state. *)

Example swap1 : forall x y z, x <> z -> y <> z ->
    swap x y (n_abs z (n_app (n_var x)(n_var y))) = n_abs z (n_app (n_var y) (n_var x)).
Proof.
  intros. simpl; unfold swap_var; default_simp.
Qed.

Example swap2 : forall x y, x <> y ->
    swap x y (n_abs x (n_var x)) = n_abs y (n_var y).
Proof.
  intros. simpl; unfold swap_var; default_simp.
Qed.

Example swap3 : forall x y, x <> y ->
     swap x y (n_abs y (n_var x)) = n_abs x (n_var y).
Proof.
  intros. simpl; unfold swap_var; default_simp.
Qed.


(** We define the "alpha-equivalence" relation that declares
    when two nominal terms are equivalent (up to renaming of
    bound variables).
    Note the two different rules for [n_abs]: either the
    binders are the same and we can directly compare the
    bodies, or the binders differ, but we can swap one side to
    make it look like the other.  *)

Inductive aeq : n_exp -> n_exp -> Prop :=
 | aeq_var : forall x,
     aeq (n_var x) (n_var x)
 | aeq_abs_same : forall x t1 t2,
     aeq t1 t2 -> aeq (n_abs x t1) (n_abs x t2)
 | aeq_abs_diff : forall x y t1 t2,
     x <> y ->
     x `notin` fv_nom t2 ->
     aeq t1 (swap y x t2) ->
     aeq (n_abs x t1) (n_abs y t2)
 | aeq_app : forall t1 t2 t1' t2',
     aeq t1 t1' -> aeq t2 t2' ->
     aeq (n_app t1 t2) (n_app t1' t2').

Hint Constructors aeq.


Example aeq1 : forall x y, x <> y -> aeq (n_abs x (n_var x)) (n_abs y (n_var y)).
Proof.
  intros.
  eapply aeq_abs_diff; auto.
  simpl; unfold swap_var; default_simp.
Qed.

(*************************************************************)
(** ** Properties about swapping                             *)
(*************************************************************)


(** Now let's look at some simple properties of swapping. *)

Lemma swap_id : forall n x,
    swap x x n = n.
Proof.
  induction n; simpl; unfold swap_var;  default_simp.
Qed.

(** Demo: We will need the next two properties later in the tutorial,
    so we show that even though there are many cases to consider,
    [default_simp] can find these proofs. *)

Lemma fv_nom_swap : forall z y n,
  z `notin` fv_nom n ->
  y `notin` fv_nom (swap y z n).
Proof.
  (* WORKINCLASS *)
  induction n; intros; simpl; unfold swap_var; default_simp.
Qed. (* /WORKINCLASS *)

Lemma shuffle_swap : forall w y n z,
    w <> z -> y <> z ->
    (swap w y (swap y z n)) = (swap w z (swap w y n)).
Proof.
  (* WORKINCLASS *)
  induction n; intros; simpl; unfold swap_var; default_simp.
Qed. (* /WORKINCLASS *)

(*************************************************************)
(** ** Exercises                                             *)
(*************************************************************)


(** *** Recommended Exercise: [swap] properties
    Prove the following properties about swapping, either
    explicitly (by destructing [x == y]) or automatically
    (using [default_simp]).  *)

Lemma swap_symmetric : forall t x y,
    swap x y t = swap y x t.
Proof.
  (* ADMITTED *)
  induction t;  simpl; unfold swap_var; default_simp.
Qed.   (* /ADMITTED *)

Lemma swap_involutive : forall t x y,
    swap x y (swap x y t) = t.
Proof.
  (* ADMITTED *)
  induction t;  simpl; unfold swap_var; default_simp.
Qed.   (* /ADMITTED *)

(** *** Challenge exercise: equivariance
    Equivariance is the property that all functions and
    relations are preserved under swapping. (Hint:
    [default_simp] will be slow on some of these properties, and
    sometimes won't be able to do them automatically.)  *)
Lemma swap_var_equivariance : forall v x y z w,
    swap_var x y (swap_var z w v) =
    swap_var (swap_var x y z) (swap_var x y w) (swap_var x y v).
Proof.
  (* ADMITTED *)
  unfold swap_var; default_simp.
Qed.   (* /ADMITTED *)

Lemma swap_equivariance : forall t x y z w,
    swap x y (swap z w t) = swap (swap_var x y z) (swap_var x y w) (swap x y t).
Proof.
  (* ADMITTED *)
  induction t; intros; simpl.
  - rewrite swap_var_equivariance. auto.
  - rewrite swap_var_equivariance. rewrite IHt. auto.
  - rewrite IHt1. rewrite IHt2. auto.
Qed. (* /ADMITTED *)

Lemma notin_fv_nom_equivariance : forall x0 x y t ,
  x0 `notin` fv_nom t ->
  swap_var x y x0  `notin` fv_nom (swap x y t).
Proof.
  (* ADMITTED *)
  induction t; intros; simpl in *.
  - unfold swap_var; default_simp.
  - unfold swap_var in *. default_simp.
  - destruct_notin. eauto.
Qed. (* /ADMITTED *)

(* HINT: For a helpful fact about sets of atoms, check AtomSetImpl.union_1 *)

Lemma in_fv_nom_equivariance : forall x y x0 t,
  x0 `in` fv_nom t ->
  swap_var x y x0 `in` fv_nom (swap x y t).
Proof.
  (* ADMITTED *)
  induction t; intros; simpl in *.
  - unfold swap_var; default_simp; fsetdec.
  - unfold swap_var in *. default_simp; fsetdec.
  - destruct (AtomSetImpl.union_1 H); fsetdec.
Qed. (* ADMITTED *)


Lemma aeq_equivariance : forall x y t1 t2,
    aeq t1 t2 ->
    aeq (swap x y t1) (swap x y t2).
Proof.
  (* ADMITTED *)
  induction 1; intros; simpl in *; auto.
  destruct (swap_var x y x0 == swap_var x y y0).
  - rewrite e. eapply aeq_abs_same.
    rewrite swap_equivariance in IHaeq.
    rewrite e in IHaeq.
    rewrite swap_id in IHaeq.
    auto.
  - rewrite swap_equivariance in IHaeq.
    eapply aeq_abs_diff; auto.
    eapply notin_fv_nom_equivariance; auto.
Qed. (* /ADMITTED *)




(*************************************************************)
(** * Size based reasoning                                   *)
(*************************************************************)


(** Some properties about nominal terms require calling the
    induction hypothesis not on a direct subterm, but on one
    that has first had a swapping applied to it.
    However, swapping names does not change the size of terms,
    so that means we can prove such properties by induction on
    that size.  *)

Fixpoint size (t : n_exp) : nat :=
  match t with
  | n_var x => 1
  | n_abs x t => 1 + size t
  | n_app t1 t2 => 1 + size t1 + size t2
  end.

Lemma swap_size_eq : forall x y t,
    size (swap x y t) = size t.
Proof.
  induction t; simpl; auto.
Qed.

Hint Rewrite swap_size_eq.

(* HIDE *)
(** ** Nominal induction *)

Lemma nominal_induction_size :
     forall n, forall t, size t <= n ->
     forall P : n_exp -> Type,
    (forall x, P (n_var x)) ->
    (forall x t, (forall y, P (swap x y t)) -> P (n_abs x t)) ->
    (forall t1 t2, P t1 -> P t2 -> P (n_app t1 t2)) ->
    P t.
Proof.
  induction n.
  intros t SZ; destruct t; intros; simpl in SZ; omega.
  intros t SZ P VAR ABS APP; destruct t; simpl in *.
  - auto.
  - apply ABS.
    intros y.
    apply IHn; eauto; rewrite swap_size_eq; try omega.
  - apply APP.
    apply IHn; eauto; omega.
    apply IHn; eauto; omega.
Defined.

Definition nominal_induction
  : forall (P : n_exp -> Type),
    (forall x : atom, P (n_var x)) ->
    (forall (x : atom) (t : n_exp),
        (forall y : atom, P (swap x y t)) -> P (n_abs x t)) ->
    (forall t1 t2 : n_exp, P t1 -> P t2 -> P (n_app t1 t2)) ->
    forall t : n_exp, P t :=
  fun P VAR APP ABS t =>
  nominal_induction_size (size t) t ltac:(auto) P VAR APP ABS.
(* /HIDE *)

(** ** Capture-avoiding substitution *)

(** We need to use size to define capture avoiding
    substitution. Because we sometimes swap the name of the
    bound variable, this function is _not_ structurally
    recursive. So, we add an extra argument to the function
    that decreases with each recursive call. *)

Program Fixpoint subst (t:n_exp) (u :n_exp) (x:atom) {measure (size t)} : n_exp :=
  match t with
          | n_var y => if (x == y) then u else t
          | n_abs y t1 => if (x == y) then t
                        else let (z,_) := atom_fresh (fv_nom u \u fv_nom t) in
                             n_abs z (subst (swap y z t1) u x)
          | n_app t1 t2 => n_app (subst t1 u x) (subst t2 u x)
  end.
Obligation 1. simpl. rewrite <- (swap_size_eq y z t1). auto. Defined.
Obligation 2. cbn. omega. Defined.
Obligation 3. cbn. omega. Defined.

Eval vm_compute in (subst (n_var X) (n_var Y) X).
Compute (subst (n_abs X (n_var X)) (n_var Y) X).
Eval simpl in (subst (n_abs X (n_var X)) (n_var Y) X).
Example substex : forall (x y: var), (subst (n_var x) (n_var y) x) = (n_var y).
Proof.
intros x y. cbn. destruct (x == x).
- reflexivity.
- contradiction.
Qed. 

(*  Title:      HOL/Divides.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1999  University of Cambridge
*)

header {* The division operators div, mod and the divides relation "dvd" *}

theory Divides
imports Power
uses "~~/src/Provers/Arith/cancel_div_mod.ML"
begin

subsection {* Syntactic division operations *}

class div = times +
  fixes div :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" (infixl "div" 70)
  fixes mod :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" (infixl "mod" 70)
begin

definition
  dvd  :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infixl "dvd" 50)
where
  [code func del]: "m dvd n \<longleftrightarrow> (\<exists>k. n = m * k)"

end

subsection {* Abstract divisibility in commutative semirings. *}

class semiring_div = comm_semiring_1_cancel + div + 
  assumes mod_div_equality: "a div b * b + a mod b = a"
    and div_by_0: "a div 0 = 0"
    and mult_div: "b \<noteq> 0 \<Longrightarrow> a * b div b = a"
begin

lemma div_by_1: "a div 1 = a"
  using mult_div [of one a] zero_neq_one by simp

lemma mod_by_1: "a mod 1 = 0"
proof -
  from mod_div_equality [of a one] div_by_1 have "a + a mod 1 = a" by simp
  then have "a + a mod 1 = a + 0" by simp
  then show ?thesis by (rule add_left_imp_eq)
qed

lemma mod_by_0: "a mod 0 = a"
  using mod_div_equality [of a zero] by simp

lemma mult_mod: "a * b mod b = 0"
proof (cases "b = 0")
  case True then show ?thesis by (simp add: mod_by_0)
next
  case False with mult_div have abb: "a * b div b = a" .
  from mod_div_equality have "a * b div b * b + a * b mod b = a * b" .
  with abb have "a * b + a * b mod b = a * b + 0" by simp
  then show ?thesis by (rule add_left_imp_eq)
qed

lemma mod_self: "a mod a = 0"
  using mult_mod [of one] by simp

lemma div_self: "a \<noteq> 0 \<Longrightarrow> a div a = 1"
  using mult_div [of _ one] by simp

lemma div_0: "0 div a = 0"
proof (cases "a = 0")
  case True then show ?thesis by (simp add: div_by_0)
next
  case False with mult_div have "0 * a div a = 0" .
  then show ?thesis by simp
qed

lemma mod_0: "0 mod a = 0"
  using mod_div_equality [of zero a] div_0 by simp 

lemma dvd_def_mod [code func]: "a dvd b \<longleftrightarrow> b mod a = 0"
proof
  assume "b mod a = 0"
  with mod_div_equality [of b a] have "b div a * a = b" by simp
  then have "b = a * (b div a)" unfolding mult_commute ..
  then have "\<exists>c. b = a * c" ..
  then show "a dvd b" unfolding dvd_def .
next
  assume "a dvd b"
  then have "\<exists>c. b = a * c" unfolding dvd_def .
  then obtain c where "b = a * c" ..
  then have "b mod a = a * c mod a" by simp
  then have "b mod a = c * a mod a" by (simp add: mult_commute)
  then show "b mod a = 0" by (simp add: mult_mod)
qed

lemma dvd_refl: "a dvd a"
  unfolding dvd_def_mod mod_self ..

lemma dvd_trans:
  assumes "a dvd b" and "b dvd c"
  shows "a dvd c"
proof -
  from assms obtain v where "b = a * v" unfolding dvd_def by auto
  moreover from assms obtain w where "c = b * w" unfolding dvd_def by auto
  ultimately have "c = a * (v * w)" by (simp add: mult_assoc)
  then show ?thesis unfolding dvd_def ..
qed

lemma one_dvd: "1 dvd a"
  unfolding dvd_def by simp

lemma dvd_0: "a dvd 0"
unfolding dvd_def proof
  show "0 = a * 0" by simp
qed

end


subsection {* Division on the natural numbers *}

instantiation nat :: semiring_div
begin

definition
  div_def: "m div n == wfrec (pred_nat^+)
                          (%f j. if j<n | n=0 then 0 else Suc (f (j-n))) m"

lemma div_eq: "(%m. m div n) = wfrec (pred_nat^+)
               (%f j. if j<n | n=0 then 0 else Suc (f (j-n)))"
by (simp add: div_def)

definition
  mod_def: "m mod n == wfrec (pred_nat^+)
                          (%f j. if j<n | n=0 then j else f (j-n)) m"

lemma mod_eq: "(%m. m mod n) =
              wfrec (pred_nat^+) (%f j. if j<n | n=0 then j else f (j-n))"
by (simp add: mod_def)

lemmas wf_less_trans = def_wfrec [THEN trans,
  OF eq_reflection wf_pred_nat [THEN wf_trancl], standard]

lemma div_less [simp]: "m < n \<Longrightarrow> m div n = (0\<Colon>nat)"
  by (rule div_eq [THEN wf_less_trans]) simp

lemma le_div_geq: "0 < n \<Longrightarrow> n \<le> m \<Longrightarrow> m div n = Suc ((m - n) div n)"
  by (rule div_eq [THEN wf_less_trans]) (simp add: cut_apply less_eq)

lemma DIVISION_BY_ZERO_MOD [simp]: "a mod 0 = (a\<Colon>nat)"
  by (rule mod_eq [THEN wf_less_trans]) simp

lemma mod_less [simp]: "m < n \<Longrightarrow> m mod n = (m\<Colon>nat)"
  by (rule mod_eq [THEN wf_less_trans]) simp

lemma le_mod_geq: "(n\<Colon>nat) \<le> m \<Longrightarrow> m mod n = (m - n) mod n"
  by (cases "n = 0", simp, rule mod_eq [THEN wf_less_trans])
    (simp add: cut_apply less_eq)

lemma mod_if: "m mod (n\<Colon>nat) = (if m < n then m else (m - n) mod n)"
  by (simp add: le_mod_geq)

instance proof
  fix n m :: nat
  show "(m div n) * n + m mod n = m"
    apply (cases "n = 0", simp)
    apply (induct m rule: nat_less_induct [rule_format])
    apply (subst mod_if)
    apply (simp add: add_assoc add_diff_inverse le_div_geq)
    done
next
  fix n :: nat
  show "n div 0 = 0"
    by (rule div_eq [THEN wf_less_trans], simp)
next
  fix n m :: nat
  assume "n \<noteq> 0"
  then show "m * n div n = m"
    by (induct m) (simp_all add: le_div_geq)
qed
  
end


subsubsection{*Simproc for Cancelling Div and Mod*}

lemmas mod_div_equality = semiring_div_class.times_div_mod_plus_zero_one.mod_div_equality [of "m\<Colon>nat" n, standard]

lemma mod_div_equality2: "n * (m div n) + m mod n = (m::nat)"
  unfolding mult_commute [of n]
  by (rule mod_div_equality)

lemma div_mod_equality: "((m div n)*n + m mod n) + k = (m::nat) + k"
  by (simp add: mod_div_equality)

lemma div_mod_equality2: "(n*(m div n) + m mod n) + k = (m::nat) + k"
  by (simp add: mod_div_equality2)

ML {*
structure CancelDivModData =
struct

val div_name = @{const_name Divides.div};
val mod_name = @{const_name Divides.mod};
val mk_binop = HOLogic.mk_binop;
val mk_sum = NatArithUtils.mk_sum;
val dest_sum = NatArithUtils.dest_sum;

(*logic*)

val div_mod_eqs = map mk_meta_eq [@{thm div_mod_equality}, @{thm div_mod_equality2}]

val trans = trans

val prove_eq_sums =
  let val simps = @{thm add_0} :: @{thm add_0_right} :: @{thms add_ac}
  in NatArithUtils.prove_conv all_tac (NatArithUtils.simp_all_tac simps) end;

end;

structure CancelDivMod = CancelDivModFun(CancelDivModData);

val cancel_div_mod_proc = NatArithUtils.prep_simproc
      ("cancel_div_mod", ["(m::nat) + n"], K CancelDivMod.proc);

Addsimprocs[cancel_div_mod_proc];
*}


subsubsection {* Remainder *}

lemmas DIVISION_BY_ZERO_MOD [simp] = mod_by_0 [of "a\<Colon>nat", standard]

lemma div_mult_self_is_m [simp]: "0<n ==> (m*n) div n = (m::nat)"
  by (induct m) (simp_all add: le_div_geq)

lemma mod_geq: "~ m < (n::nat) ==> m mod n = (m-n) mod n"
  by (simp add: le_mod_geq linorder_not_less)

lemma mod_1 [simp]: "m mod Suc 0 = 0"
  by (induct m) (simp_all add: mod_geq)

lemmas mod_self [simp] = semiring_div_class.mod_self [of "n\<Colon>nat", standard]

lemma mod_add_self2 [simp]: "(m+n) mod n = m mod (n::nat)"
  apply (subgoal_tac "(n + m) mod n = (n+m-n) mod n")
   apply (simp add: add_commute)
  apply (subst le_mod_geq [symmetric], simp_all)
  done

lemma mod_add_self1 [simp]: "(n+m) mod n = m mod (n::nat)"
  by (simp add: add_commute mod_add_self2)

lemma mod_mult_self1 [simp]: "(m + k*n) mod n = m mod (n::nat)"
  by (induct k) (simp_all add: add_left_commute [of _ n])

lemma mod_mult_self2 [simp]: "(m + n*k) mod n = m mod (n::nat)"
  by (simp add: mult_commute mod_mult_self1)

lemma mod_mult_distrib: "(m mod n) * (k::nat) = (m*k) mod (n*k)"
  apply (cases "n = 0", simp)
  apply (cases "k = 0", simp)
  apply (induct m rule: nat_less_induct)
  apply (subst mod_if, simp)
  apply (simp add: mod_geq diff_mult_distrib)
  done

lemma mod_mult_distrib2: "(k::nat) * (m mod n) = (k*m) mod (k*n)"
  by (simp add: mult_commute [of k] mod_mult_distrib)

lemma mod_mult_self_is_0 [simp]: "(m*n) mod n = (0::nat)"
  apply (cases "n = 0", simp)
  apply (induct m, simp)
  apply (rename_tac k)
  apply (cut_tac m = "k * n" and n = n in mod_add_self2)
  apply (simp add: add_commute)
  done

lemma mod_mult_self1_is_0 [simp]: "(n*m) mod n = (0::nat)"
  by (simp add: mult_commute mod_mult_self_is_0)


subsubsection{*Quotient*}

lemmas DIVISION_BY_ZERO_DIV [simp] = div_by_0 [of "a\<Colon>nat", standard]

lemma div_geq: "[| 0<n;  ~m<n |] ==> m div n = Suc((m-n) div n)"
  by (simp add: le_div_geq linorder_not_less)

lemma div_if: "0<n ==> m div n = (if m<n then 0 else Suc((m-n) div n))"
  by (simp add: div_geq)



(* a simple rearrangement of mod_div_equality: *)
lemma mult_div_cancel: "(n::nat) * (m div n) = m - (m mod n)"
  by (cut_tac m = m and n = n in mod_div_equality2, arith)

lemma mod_less_divisor [simp]: "0<n ==> m mod n < (n::nat)"
  apply (induct m rule: nat_less_induct)
  apply (rename_tac m)
  apply (case_tac "m<n", simp)
  txt{*case @{term "n \<le> m"}*}
  apply (simp add: mod_geq)
  done

lemma mod_le_divisor[simp]: "0 < n \<Longrightarrow> m mod n \<le> (n::nat)"
  apply (drule mod_less_divisor [where m = m])
  apply simp
  done

lemma div_mult_self1_is_m [simp]: "0<n ==> (n*m) div n = (m::nat)"
  by (simp add: mult_commute div_mult_self_is_m)

(*mod_mult_distrib2 above is the counterpart for remainder*)


subsubsection {* Proving advancedfacts about Quotient and Remainder *}

definition
  quorem :: "(nat*nat) * (nat*nat) => bool" where
  (*This definition helps prove the harder properties of div and mod.
    It is copied from IntDiv.thy; should it be overloaded?*)
  "quorem = (%((a,b), (q,r)).
                    a = b*q + r &
                    (if 0<b then 0\<le>r & r<b else b<r & r \<le>0))"

lemma unique_quotient_lemma:
     "[| b*q' + r'  \<le> b*q + r;  x < b;  r < b |]
      ==> q' \<le> (q::nat)"
  apply (rule leI)
  apply (subst less_iff_Suc_add)
  apply (auto simp add: add_mult_distrib2)
  done

lemma unique_quotient:
     "[| quorem ((a,b), (q,r));  quorem ((a,b), (q',r'));  0 < b |]
      ==> q = q'"
  apply (simp add: split_ifs quorem_def)
  apply (blast intro: order_antisym
    dest: order_eq_refl [THEN unique_quotient_lemma] sym)
  done

lemma unique_remainder:
     "[| quorem ((a,b), (q,r));  quorem ((a,b), (q',r'));  0 < b |]
      ==> r = r'"
  apply (subgoal_tac "q = q'")
   prefer 2 apply (blast intro: unique_quotient)
  apply (simp add: quorem_def)
  done

lemma quorem_div_mod: "b > 0 ==> quorem ((a, b), (a div b, a mod b))"
unfolding quorem_def by simp

lemma quorem_div: "[| quorem((a,b),(q,r));  b > 0 |] ==> a div b = q"
by (simp add: quorem_div_mod [THEN unique_quotient])

lemma quorem_mod: "[| quorem((a,b),(q,r));  b > 0 |] ==> a mod b = r"
by (simp add: quorem_div_mod [THEN unique_remainder])

(** A dividend of zero **)

lemmas div_0 [simp] = semiring_div_class.div_0 [of "n\<Colon>nat", standard]

lemmas mod_0 [simp] = semiring_div_class.mod_0 [of "n\<Colon>nat", standard]

(** proving (a*b) div c = a * (b div c) + a * (b mod c) **)

lemma quorem_mult1_eq:
  "[| quorem((b,c),(q,r)); c > 0 |]
   ==> quorem ((a*b, c), (a*q + a*r div c, a*r mod c))"
by (auto simp add: split_ifs mult_ac quorem_def add_mult_distrib2)

lemma div_mult1_eq: "(a*b) div c = a*(b div c) + a*(b mod c) div (c::nat)"
apply (cases "c = 0", simp)
thm DIVISION_BY_ZERO_DIV
apply (blast intro: quorem_div_mod [THEN quorem_mult1_eq, THEN quorem_div])
done

lemma mod_mult1_eq: "(a*b) mod c = a*(b mod c) mod (c::nat)"
apply (cases "c = 0", simp)
apply (blast intro: quorem_div_mod [THEN quorem_mult1_eq, THEN quorem_mod])
done

lemma mod_mult1_eq': "(a*b) mod (c::nat) = ((a mod c) * b) mod c"
  apply (rule trans)
   apply (rule_tac s = "b*a mod c" in trans)
    apply (rule_tac [2] mod_mult1_eq)
   apply (simp_all add: mult_commute)
  done

lemma mod_mult_distrib_mod:
  "(a*b) mod (c::nat) = ((a mod c) * (b mod c)) mod c"
apply (rule mod_mult1_eq' [THEN trans])
apply (rule mod_mult1_eq)
done

(** proving (a+b) div c = a div c + b div c + ((a mod c + b mod c) div c) **)

lemma quorem_add1_eq:
  "[| quorem((a,c),(aq,ar));  quorem((b,c),(bq,br));  c > 0 |]
   ==> quorem ((a+b, c), (aq + bq + (ar+br) div c, (ar+br) mod c))"
by (auto simp add: split_ifs mult_ac quorem_def add_mult_distrib2)

(*NOT suitable for rewriting: the RHS has an instance of the LHS*)
lemma div_add1_eq:
  "(a+b) div (c::nat) = a div c + b div c + ((a mod c + b mod c) div c)"
apply (cases "c = 0", simp)
apply (blast intro: quorem_add1_eq [THEN quorem_div] quorem_div_mod)
done

lemma mod_add1_eq: "(a+b) mod (c::nat) = (a mod c + b mod c) mod c"
apply (cases "c = 0", simp)
apply (blast intro: quorem_div_mod quorem_add1_eq [THEN quorem_mod])
done


subsubsection {* Proving @{prop "a div (b*c) = (a div b) div c"} *}

(** first, a lemma to bound the remainder **)

lemma mod_lemma: "[| (0::nat) < c; r < b |] ==> b * (q mod c) + r < b * c"
  apply (cut_tac m = q and n = c in mod_less_divisor)
  apply (drule_tac [2] m = "q mod c" in less_imp_Suc_add, auto)
  apply (erule_tac P = "%x. ?lhs < ?rhs x" in ssubst)
  apply (simp add: add_mult_distrib2)
  done

lemma quorem_mult2_eq: "[| quorem ((a,b), (q,r));  0 < b;  0 < c |]
      ==> quorem ((a, b*c), (q div c, b*(q mod c) + r))"
  by (auto simp add: mult_ac quorem_def add_mult_distrib2 [symmetric] mod_lemma)

lemma div_mult2_eq: "a div (b*c) = (a div b) div (c::nat)"
  apply (cases "b = 0", simp)
  apply (cases "c = 0", simp)
  apply (force simp add: quorem_div_mod [THEN quorem_mult2_eq, THEN quorem_div])
  done

lemma mod_mult2_eq: "a mod (b*c) = b*(a div b mod c) + a mod (b::nat)"
  apply (cases "b = 0", simp)
  apply (cases "c = 0", simp)
  apply (auto simp add: mult_commute quorem_div_mod [THEN quorem_mult2_eq, THEN quorem_mod])
  done


subsubsection{*Cancellation of Common Factors in Division*}

lemma div_mult_mult_lemma:
    "[| (0::nat) < b;  0 < c |] ==> (c*a) div (c*b) = a div b"
  by (auto simp add: div_mult2_eq)

lemma div_mult_mult1 [simp]: "(0::nat) < c ==> (c*a) div (c*b) = a div b"
  apply (cases "b = 0")
  apply (auto simp add: linorder_neq_iff [of b] div_mult_mult_lemma)
  done

lemma div_mult_mult2 [simp]: "(0::nat) < c ==> (a*c) div (b*c) = a div b"
  apply (drule div_mult_mult1)
  apply (auto simp add: mult_commute)
  done


subsubsection{*Further Facts about Quotient and Remainder*}

lemma div_1 [simp]: "m div Suc 0 = m"
  by (induct m) (simp_all add: div_geq)

lemmas div_self [simp] = semiring_div_class.div_self [of "n\<Colon>nat", standard]

lemma div_add_self2: "0<n ==> (m+n) div n = Suc (m div n)"
  apply (subgoal_tac "(n + m) div n = Suc ((n+m-n) div n) ")
   apply (simp add: add_commute)
  apply (subst div_geq [symmetric], simp_all)
  done

lemma div_add_self1: "0<n ==> (n+m) div n = Suc (m div n)"
  by (simp add: add_commute div_add_self2)

lemma div_mult_self1 [simp]: "!!n::nat. 0<n ==> (m + k*n) div n = k + m div n"
  apply (subst div_add1_eq)
  apply (subst div_mult1_eq, simp)
  done

lemma div_mult_self2 [simp]: "0<n ==> (m + n*k) div n = k + m div (n::nat)"
  by (simp add: mult_commute div_mult_self1)


(* Monotonicity of div in first argument *)
lemma div_le_mono [rule_format (no_asm)]:
    "\<forall>m::nat. m \<le> n --> (m div k) \<le> (n div k)"
apply (case_tac "k=0", simp)
apply (induct "n" rule: nat_less_induct, clarify)
apply (case_tac "n<k")
(* 1  case n<k *)
apply simp
(* 2  case n >= k *)
apply (case_tac "m<k")
(* 2.1  case m<k *)
apply simp
(* 2.2  case m>=k *)
apply (simp add: div_geq diff_le_mono)
done

(* Antimonotonicity of div in second argument *)
lemma div_le_mono2: "!!m::nat. [| 0<m; m\<le>n |] ==> (k div n) \<le> (k div m)"
apply (subgoal_tac "0<n")
 prefer 2 apply simp
apply (induct_tac k rule: nat_less_induct)
apply (rename_tac "k")
apply (case_tac "k<n", simp)
apply (subgoal_tac "~ (k<m) ")
 prefer 2 apply simp
apply (simp add: div_geq)
apply (subgoal_tac "(k-n) div n \<le> (k-m) div n")
 prefer 2
 apply (blast intro: div_le_mono diff_le_mono2)
apply (rule le_trans, simp)
apply (simp)
done

lemma div_le_dividend [simp]: "m div n \<le> (m::nat)"
apply (case_tac "n=0", simp)
apply (subgoal_tac "m div n \<le> m div 1", simp)
apply (rule div_le_mono2)
apply (simp_all (no_asm_simp))
done

(* Similar for "less than" *)
lemma div_less_dividend [rule_format]:
     "!!n::nat. 1<n ==> 0 < m --> m div n < m"
apply (induct_tac m rule: nat_less_induct)
apply (rename_tac "m")
apply (case_tac "m<n", simp)
apply (subgoal_tac "0<n")
 prefer 2 apply simp
apply (simp add: div_geq)
apply (case_tac "n<m")
 apply (subgoal_tac "(m-n) div n < (m-n) ")
  apply (rule impI less_trans_Suc)+
apply assumption
  apply (simp_all)
done

declare div_less_dividend [simp]

text{*A fact for the mutilated chess board*}
lemma mod_Suc: "Suc(m) mod n = (if Suc(m mod n) = n then 0 else Suc(m mod n))"
apply (case_tac "n=0", simp)
apply (induct "m" rule: nat_less_induct)
apply (case_tac "Suc (na) <n")
(* case Suc(na) < n *)
apply (frule lessI [THEN less_trans], simp add: less_not_refl3)
(* case n \<le> Suc(na) *)
apply (simp add: linorder_not_less le_Suc_eq mod_geq)
apply (auto simp add: Suc_diff_le le_mod_geq)
done

lemma nat_mod_div_trivial [simp]: "m mod n div n = (0 :: nat)"
  by (cases "n = 0") auto

lemma nat_mod_mod_trivial [simp]: "m mod n mod n = (m mod n :: nat)"
  by (cases "n = 0") auto


subsubsection{*The Divides Relation*}

lemma dvdI [intro?]: "n = m * k ==> m dvd n"
  unfolding dvd_def by blast

lemma dvdE [elim?]: "!!P. [|m dvd n;  !!k. n = m*k ==> P|] ==> P"
  unfolding dvd_def by blast

lemma dvd_0_right [iff]: "m dvd (0::nat)"
  unfolding dvd_def by (blast intro: mult_0_right [symmetric])

lemma dvd_0_left: "0 dvd m ==> m = (0::nat)"
  by (force simp add: dvd_def)

lemma dvd_0_left_iff [iff]: "(0 dvd (m::nat)) = (m = 0)"
  by (blast intro: dvd_0_left)

declare dvd_0_left_iff [noatp]

lemma dvd_1_left [iff]: "Suc 0 dvd k"
  unfolding dvd_def by simp

lemma dvd_1_iff_1 [simp]: "(m dvd Suc 0) = (m = Suc 0)"
  by (simp add: dvd_def)

lemmas dvd_refl [simp] = semiring_div_class.dvd_refl [of "m\<Colon>nat", standard]
lemmas dvd_trans [trans] = semiring_div_class.dvd_trans [of "m\<Colon>nat" n p, standard]

lemma dvd_anti_sym: "[| m dvd n; n dvd m |] ==> m = (n::nat)"
  unfolding dvd_def
  by (force dest: mult_eq_self_implies_10 simp add: mult_assoc mult_eq_1_iff)

text {* @{term "op dvd"} is a partial order *}

interpretation dvd: order ["op dvd" "\<lambda>n m \<Colon> nat. n dvd m \<and> n \<noteq> m"]
  by unfold_locales (auto intro: dvd_trans dvd_anti_sym)

lemma dvd_add: "[| k dvd m; k dvd n |] ==> k dvd (m+n :: nat)"
  unfolding dvd_def
  by (blast intro: add_mult_distrib2 [symmetric])

lemma dvd_diff: "[| k dvd m; k dvd n |] ==> k dvd (m-n :: nat)"
  unfolding dvd_def
  by (blast intro: diff_mult_distrib2 [symmetric])

lemma dvd_diffD: "[| k dvd m-n; k dvd n; n\<le>m |] ==> k dvd (m::nat)"
  apply (erule linorder_not_less [THEN iffD2, THEN add_diff_inverse, THEN subst])
  apply (blast intro: dvd_add)
  done

lemma dvd_diffD1: "[| k dvd m-n; k dvd m; n\<le>m |] ==> k dvd (n::nat)"
  by (drule_tac m = m in dvd_diff, auto)

lemma dvd_mult: "k dvd n ==> k dvd (m*n :: nat)"
  unfolding dvd_def by (blast intro: mult_left_commute)

lemma dvd_mult2: "k dvd m ==> k dvd (m*n :: nat)"
  apply (subst mult_commute)
  apply (erule dvd_mult)
  done

lemma dvd_triv_right [iff]: "k dvd (m*k :: nat)"
  by (rule dvd_refl [THEN dvd_mult])

lemma dvd_triv_left [iff]: "k dvd (k*m :: nat)"
  by (rule dvd_refl [THEN dvd_mult2])

lemma dvd_reduce: "(k dvd n + k) = (k dvd (n::nat))"
  apply (rule iffI)
   apply (erule_tac [2] dvd_add)
   apply (rule_tac [2] dvd_refl)
  apply (subgoal_tac "n = (n+k) -k")
   prefer 2 apply simp
  apply (erule ssubst)
  apply (erule dvd_diff)
  apply (rule dvd_refl)
  done

lemma dvd_mod: "!!n::nat. [| f dvd m; f dvd n |] ==> f dvd m mod n"
  unfolding dvd_def
  apply (case_tac "n = 0", auto)
  apply (blast intro: mod_mult_distrib2 [symmetric])
  done

lemma dvd_mod_imp_dvd: "[| (k::nat) dvd m mod n;  k dvd n |] ==> k dvd m"
  apply (subgoal_tac "k dvd (m div n) *n + m mod n")
   apply (simp add: mod_div_equality)
  apply (simp only: dvd_add dvd_mult)
  done

lemma dvd_mod_iff: "k dvd n ==> ((k::nat) dvd m mod n) = (k dvd m)"
  by (blast intro: dvd_mod_imp_dvd dvd_mod)

lemma dvd_mult_cancel: "!!k::nat. [| k*m dvd k*n; 0<k |] ==> m dvd n"
  unfolding dvd_def
  apply (erule exE)
  apply (simp add: mult_ac)
  done

lemma dvd_mult_cancel1: "0<m ==> (m*n dvd m) = (n = (1::nat))"
  apply auto
   apply (subgoal_tac "m*n dvd m*1")
   apply (drule dvd_mult_cancel, auto)
  done

lemma dvd_mult_cancel2: "0<m ==> (n*m dvd m) = (n = (1::nat))"
  apply (subst mult_commute)
  apply (erule dvd_mult_cancel1)
  done

lemma mult_dvd_mono: "[| i dvd m; j dvd n|] ==> i*j dvd (m*n :: nat)"
  apply (unfold dvd_def, clarify)
  apply (rule_tac x = "k*ka" in exI)
  apply (simp add: mult_ac)
  done

lemma dvd_mult_left: "(i*j :: nat) dvd k ==> i dvd k"
  by (simp add: dvd_def mult_assoc, blast)

lemma dvd_mult_right: "(i*j :: nat) dvd k ==> j dvd k"
  apply (unfold dvd_def, clarify)
  apply (rule_tac x = "i*k" in exI)
  apply (simp add: mult_ac)
  done

lemma dvd_imp_le: "[| k dvd n; 0 < n |] ==> k \<le> (n::nat)"
  apply (unfold dvd_def, clarify)
  apply (simp_all (no_asm_use) add: zero_less_mult_iff)
  apply (erule conjE)
  apply (rule le_trans)
   apply (rule_tac [2] le_refl [THEN mult_le_mono])
   apply (erule_tac [2] Suc_leI, simp)
  done

lemmas dvd_eq_mod_eq_0 = dvd_def_mod [of "k\<Colon>nat" n, standard]

lemma dvd_mult_div_cancel: "n dvd m ==> n * (m div n) = (m::nat)"
  apply (subgoal_tac "m mod n = 0")
   apply (simp add: mult_div_cancel)
  apply (simp only: dvd_eq_mod_eq_0)
  done

lemma le_imp_power_dvd: "!!i::nat. m \<le> n ==> i^m dvd i^n"
  apply (unfold dvd_def)
  apply (erule linorder_not_less [THEN iffD2, THEN add_diff_inverse, THEN subst])
  apply (simp add: power_add)
  done

lemma nat_zero_less_power_iff [simp]: "(x^n > 0) = (x > (0::nat) | n=0)"
  by (induct n) auto

lemma power_le_dvd [rule_format]: "k^j dvd n --> i\<le>j --> k^i dvd (n::nat)"
  apply (induct j)
   apply (simp_all add: le_Suc_eq)
  apply (blast dest!: dvd_mult_right)
  done

lemma power_dvd_imp_le: "[|i^m dvd i^n;  (1::nat) < i|] ==> m \<le> n"
  apply (rule power_le_imp_le_exp, assumption)
  apply (erule dvd_imp_le, simp)
  done

lemma mod_eq_0_iff: "(m mod d = 0) = (\<exists>q::nat. m = d*q)"
  by (auto simp add: dvd_eq_mod_eq_0 [symmetric] dvd_def)

lemmas mod_eq_0D [dest!] = mod_eq_0_iff [THEN iffD1]

(*Loses information, namely we also have r<d provided d is nonzero*)
lemma mod_eqD: "(m mod d = r) ==> \<exists>q::nat. m = r + q*d"
  apply (cut_tac m = m in mod_div_equality)
  apply (simp only: add_ac)
  apply (blast intro: sym)
  done


lemma split_div:
 "P(n div k :: nat) =
 ((k = 0 \<longrightarrow> P 0) \<and> (k \<noteq> 0 \<longrightarrow> (!i. !j<k. n = k*i + j \<longrightarrow> P i)))"
 (is "?P = ?Q" is "_ = (_ \<and> (_ \<longrightarrow> ?R))")
proof
  assume P: ?P
  show ?Q
  proof (cases)
    assume "k = 0"
    with P show ?Q by(simp add:DIVISION_BY_ZERO_DIV)
  next
    assume not0: "k \<noteq> 0"
    thus ?Q
    proof (simp, intro allI impI)
      fix i j
      assume n: "n = k*i + j" and j: "j < k"
      show "P i"
      proof (cases)
        assume "i = 0"
        with n j P show "P i" by simp
      next
        assume "i \<noteq> 0"
        with not0 n j P show "P i" by(simp add:add_ac)
      qed
    qed
  qed
next
  assume Q: ?Q
  show ?P
  proof (cases)
    assume "k = 0"
    with Q show ?P by(simp add:DIVISION_BY_ZERO_DIV)
  next
    assume not0: "k \<noteq> 0"
    with Q have R: ?R by simp
    from not0 R[THEN spec,of "n div k",THEN spec, of "n mod k"]
    show ?P by simp
  qed
qed

lemma split_div_lemma:
  "0 < n \<Longrightarrow> (n * q \<le> m \<and> m < n * (Suc q)) = (q = ((m::nat) div n))"
apply (rule iffI)
 apply (rule_tac a=m and r = "m - n * q" and r' = "m mod n" in unique_quotient)
   prefer 3; apply assumption
  apply (simp_all add: quorem_def)
 apply arith
apply (rule conjI)
 apply (rule_tac P="%x. n * (m div n) \<le> x" in
    subst [OF mod_div_equality [of _ n]])
 apply (simp only: add: mult_ac)
 apply (rule_tac P="%x. x < n + n * (m div n)" in
    subst [OF mod_div_equality [of _ n]])
apply (simp only: add: mult_ac add_ac)
apply (rule add_less_mono1, simp)
done

theorem split_div':
  "P ((m::nat) div n) = ((n = 0 \<and> P 0) \<or>
   (\<exists>q. (n * q \<le> m \<and> m < n * (Suc q)) \<and> P q))"
  apply (case_tac "0 < n")
  apply (simp only: add: split_div_lemma)
  apply (simp_all add: DIVISION_BY_ZERO_DIV)
  done

lemma split_mod:
 "P(n mod k :: nat) =
 ((k = 0 \<longrightarrow> P n) \<and> (k \<noteq> 0 \<longrightarrow> (!i. !j<k. n = k*i + j \<longrightarrow> P j)))"
 (is "?P = ?Q" is "_ = (_ \<and> (_ \<longrightarrow> ?R))")
proof
  assume P: ?P
  show ?Q
  proof (cases)
    assume "k = 0"
    with P show ?Q by(simp add:DIVISION_BY_ZERO_MOD)
  next
    assume not0: "k \<noteq> 0"
    thus ?Q
    proof (simp, intro allI impI)
      fix i j
      assume "n = k*i + j" "j < k"
      thus "P j" using not0 P by(simp add:add_ac mult_ac)
    qed
  qed
next
  assume Q: ?Q
  show ?P
  proof (cases)
    assume "k = 0"
    with Q show ?P by(simp add:DIVISION_BY_ZERO_MOD)
  next
    assume not0: "k \<noteq> 0"
    with Q have R: ?R by simp
    from not0 R[THEN spec,of "n div k",THEN spec, of "n mod k"]
    show ?P by simp
  qed
qed

theorem mod_div_equality': "(m::nat) mod n = m - (m div n) * n"
  apply (rule_tac P="%x. m mod n = x - (m div n) * n" in
    subst [OF mod_div_equality [of _ n]])
  apply arith
  done

lemma div_mod_equality':
  fixes m n :: nat
  shows "m div n * n = m - m mod n"
proof -
  have "m mod n \<le> m mod n" ..
  from div_mod_equality have 
    "m div n * n + m mod n - m mod n = m - m mod n" by simp
  with diff_add_assoc [OF `m mod n \<le> m mod n`, of "m div n * n"] have
    "m div n * n + (m mod n - m mod n) = m - m mod n"
    by simp
  then show ?thesis by simp
qed


subsubsection {*An ``induction'' law for modulus arithmetic.*}

lemma mod_induct_0:
  assumes step: "\<forall>i<p. P i \<longrightarrow> P ((Suc i) mod p)"
  and base: "P i" and i: "i<p"
  shows "P 0"
proof (rule ccontr)
  assume contra: "\<not>(P 0)"
  from i have p: "0<p" by simp
  have "\<forall>k. 0<k \<longrightarrow> \<not> P (p-k)" (is "\<forall>k. ?A k")
  proof
    fix k
    show "?A k"
    proof (induct k)
      show "?A 0" by simp  -- "by contradiction"
    next
      fix n
      assume ih: "?A n"
      show "?A (Suc n)"
      proof (clarsimp)
        assume y: "P (p - Suc n)"
        have n: "Suc n < p"
        proof (rule ccontr)
          assume "\<not>(Suc n < p)"
          hence "p - Suc n = 0"
            by simp
          with y contra show "False"
            by simp
        qed
        hence n2: "Suc (p - Suc n) = p-n" by arith
        from p have "p - Suc n < p" by arith
        with y step have z: "P ((Suc (p - Suc n)) mod p)"
          by blast
        show "False"
        proof (cases "n=0")
          case True
          with z n2 contra show ?thesis by simp
        next
          case False
          with p have "p-n < p" by arith
          with z n2 False ih show ?thesis by simp
        qed
      qed
    qed
  qed
  moreover
  from i obtain k where "0<k \<and> i+k=p"
    by (blast dest: less_imp_add_positive)
  hence "0<k \<and> i=p-k" by auto
  moreover
  note base
  ultimately
  show "False" by blast
qed

lemma mod_induct:
  assumes step: "\<forall>i<p. P i \<longrightarrow> P ((Suc i) mod p)"
  and base: "P i" and i: "i<p" and j: "j<p"
  shows "P j"
proof -
  have "\<forall>j<p. P j"
  proof
    fix j
    show "j<p \<longrightarrow> P j" (is "?A j")
    proof (induct j)
      from step base i show "?A 0"
        by (auto elim: mod_induct_0)
    next
      fix k
      assume ih: "?A k"
      show "?A (Suc k)"
      proof
        assume suc: "Suc k < p"
        hence k: "k<p" by simp
        with ih have "P k" ..
        with step k have "P (Suc k mod p)"
          by blast
        moreover
        from suc have "Suc k mod p = Suc k"
          by simp
        ultimately
        show "P (Suc k)" by simp
      qed
    qed
  qed
  with j show ?thesis by blast
qed


lemma mod_add_left_eq: "((a::nat) + b) mod c = (a mod c + b) mod c"
  apply (rule trans [symmetric])
   apply (rule mod_add1_eq, simp)
  apply (rule mod_add1_eq [symmetric])
  done

lemma mod_add_right_eq: "(a+b) mod (c::nat) = (a + (b mod c)) mod c"
  apply (rule trans [symmetric])
   apply (rule mod_add1_eq, simp)
  apply (rule mod_add1_eq [symmetric])
  done

lemma mod_div_decomp:
  fixes n k :: nat
  obtains m q where "m = n div k" and "q = n mod k"
    and "n = m * k + q"
proof -
  from mod_div_equality have "n = n div k * k + n mod k" by auto
  moreover have "n div k = n div k" ..
  moreover have "n mod k = n mod k" ..
  note that ultimately show thesis by blast
qed


subsubsection {* Code generation for div, mod and dvd on nat *}

definition [code func del]:
  "divmod (m\<Colon>nat) n = (m div n, m mod n)"

lemma divmod_zero [code]: "divmod m 0 = (0, m)"
  unfolding divmod_def by simp

lemma divmod_succ [code]:
  "divmod m (Suc k) = (if m < Suc k then (0, m) else
    let
      (p, q) = divmod (m - Suc k) (Suc k)
    in (Suc p, q))"
  unfolding divmod_def Let_def split_def
  by (auto intro: div_geq mod_geq)

lemma div_divmod [code]: "m div n = fst (divmod m n)"
  unfolding divmod_def by simp

lemma mod_divmod [code]: "m mod n = snd (divmod m n)"
  unfolding divmod_def by simp

code_modulename SML
  Divides Nat

code_modulename OCaml
  Divides Nat

code_modulename Haskell
  Divides Nat

hide (open) const divmod

end

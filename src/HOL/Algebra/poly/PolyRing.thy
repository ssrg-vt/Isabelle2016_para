(*
    Instantiate polynomials to form a ring and prove further properties
    $Id$
    Author: Clemens Ballarin, started 20 January 1997
*)

PolyRing = UnivPoly +

instance
  up :: (ring) ring
  (up_a_assoc, up_l_zero, up_l_neg, up_a_comm, 
   up_m_assoc, up_l_one, up_l_distr, up_m_comm,
   up_inverse_def, up_divide_def, up_power_def) {| ALLGOALS (rtac refl) |}

end

(*  Title:      Pure/Thy/export_theory.ML
    Author:     Makarius

Export foundational theory content and locale/class structure.
*)

signature EXPORT_THEORY =
sig
  val setup_presentation: (Thy_Info.presentation_context -> theory -> unit) -> unit
  val export_body: theory -> string -> XML.body -> unit
end;

structure Export_Theory: EXPORT_THEORY =
struct

(* approximative syntax *)

val get_syntax = Syntax.get_approx o Proof_Context.syn_of;
fun get_syntax_type ctxt = get_syntax ctxt o Lexicon.mark_type;
fun get_syntax_const ctxt = get_syntax ctxt o Lexicon.mark_const;
fun get_syntax_fixed ctxt = get_syntax ctxt o Lexicon.mark_fixed;

fun get_syntax_param ctxt loc x =
  let val thy = Proof_Context.theory_of ctxt in
    if Class.is_class thy loc then
      (case AList.lookup (op =) (Class.these_params thy [loc]) x of
        NONE => NONE
      | SOME (_, (c, _)) => get_syntax_const ctxt c)
    else get_syntax_fixed ctxt x
  end;

val encode_syntax =
  XML.Encode.variant
   [fn NONE => ([], []),
    fn SOME (Syntax.Prefix delim) => ([delim], []),
    fn SOME (Syntax.Infix {assoc, delim, pri}) =>
      let
        val ass =
          (case assoc of
            Printer.No_Assoc => 0
          | Printer.Left_Assoc => 1
          | Printer.Right_Assoc => 2);
        open XML.Encode Term_XML.Encode;
      in ([], triple int string int (ass, delim, pri)) end];


(* free variables: not declared in the context *)

val is_free = not oo Name.is_declared;

fun add_frees used =
  fold_aterms (fn Free (x, T) => is_free used x ? insert (op =) (x, T) | _ => I);

fun add_tfrees used =
  (fold_types o fold_atyps) (fn TFree (a, S) => is_free used a ? insert (op =) (a, S) | _ => I);


(* locales *)

fun locale_content thy loc =
  let
    val ctxt = Locale.init loc thy;
    val args =
      Locale.params_of thy loc
      |> map (fn ((x, T), _) => ((x, T), get_syntax_param ctxt loc x));
    val axioms =
      let
        val (asm, defs) = Locale.specification_of thy loc;
        val cprops = map (Thm.cterm_of ctxt) (the_list asm @ defs);
        val (intro1, intro2) = Locale.intros_of thy loc;
        val intros_tac = Method.try_intros_tac ctxt (the_list intro1 @ the_list intro2) [];
        val res =
          Goal.init (Conjunction.mk_conjunction_balanced cprops)
          |> (ALLGOALS Goal.conjunction_tac THEN intros_tac)
          |> try Seq.hd;
      in
        (case res of
          SOME goal => Thm.prems_of goal
        | NONE => raise Fail ("Cannot unfold locale " ^ quote loc))
      end;
    val typargs = rev (fold Term.add_tfrees (map (Free o #1) args @ axioms) []);
  in {typargs = typargs, args = args, axioms = axioms} end;

fun get_locales thy =
  Locale.get_locales thy |> map_filter (fn loc =>
    if Experiment.is_experiment thy loc then NONE else SOME (loc, ()));

fun get_dependencies prev_thys thy =
  Locale.dest_dependencies prev_thys thy |> map_filter (fn dep =>
    if Experiment.is_experiment thy (#source dep) orelse
      Experiment.is_experiment thy (#target dep) then NONE
    else
      let
        val (type_params, params) = Locale.parameters_of thy (#source dep);
        val typargs = fold (Term.add_tfreesT o #2 o #1) params type_params;
        val substT =
          typargs |> map_filter (fn v =>
            let
              val T = TFree v;
              val T' = Morphism.typ (#morphism dep) T;
            in if T = T' then NONE else SOME (v, T') end);
        val subst =
          params |> map_filter (fn (v, _) =>
            let
              val t = Free v;
              val t' = Morphism.term (#morphism dep) t;
            in if t aconv t' then NONE else SOME (v, t') end);
      in SOME (dep, (substT, subst)) end);


(* general setup *)

fun setup_presentation f =
  Theory.setup (Thy_Info.add_presentation (fn context => fn thy =>
    if Options.bool (#options context) "export_theory" then f context thy else ()));

fun export_body thy name body =
  if XML.is_empty_body body then ()
  else Export.export thy (Path.binding0 (Path.make ["theory", name])) body;


(* presentation *)

val _ = setup_presentation (fn context => fn thy =>
  let
    val parents = Theory.parents_of thy;
    val rep_tsig = Type.rep_tsig (Sign.tsig_of thy);

    val thy_ctxt = Proof_Context.init_global thy;

    val pos_properties = Thy_Info.adjust_pos_properties context;


    (* spec rules *)

    fun spec_rule_content {pos, name, rough_classification, terms, rules} =
      let
        val spec =
          terms @ map Thm.plain_prop_of rules
          |> Term_Subst.zero_var_indexes_list
          |> map Logic.unvarify_global;
      in
       {props = pos_properties pos,
        name = name,
        rough_classification = rough_classification,
        typargs = rev (fold Term.add_tfrees spec []),
        args = rev (fold Term.add_frees spec []),
        terms = map (fn t => (t, Term.type_of t)) (take (length terms) spec),
        rules = drop (length terms) spec}
      end;


    (* entities *)

    fun make_entity_markup name xname pos serial =
      let val props = pos_properties pos @ Markup.serial_properties serial;
      in (Markup.entityN, (Markup.nameN, name) :: (Markup.xnameN, xname) :: props) end;

    fun entity_markup space name =
      let
        val xname = Name_Space.extern_shortest thy_ctxt space name;
        val {serial, pos, ...} = Name_Space.the_entry space name;
      in make_entity_markup name xname pos serial end;

    fun export_entities export_name export get_space decls =
      let
        val parent_spaces = map get_space parents;
        val space = get_space thy;
      in
        (decls, []) |-> fold (fn (name, decl) =>
          if exists (fn space => Name_Space.declared space name) parent_spaces then I
          else
            (case export name decl of
              NONE => I
            | SOME body =>
                cons (#serial (Name_Space.the_entry space name),
                  XML.Elem (entity_markup space name, body))))
        |> sort (int_ord o apply2 #1) |> map #2
        |> export_body thy export_name
      end;


    (* types *)

    val encode_type =
      let open XML.Encode Term_XML.Encode
      in triple encode_syntax (list string) (option typ) end;

    fun export_type c (Type.LogicalType n) =
          SOME (encode_type (get_syntax_type thy_ctxt c, Name.invent Name.context Name.aT n, NONE))
      | export_type c (Type.Abbreviation (args, U, false)) =
          SOME (encode_type (get_syntax_type thy_ctxt c, args, SOME U))
      | export_type _ _ = NONE;

    val _ =
      export_entities "types" export_type Sign.type_space
        (Name_Space.dest_table (#types rep_tsig));


    (* consts *)

    val consts = Sign.consts_of thy;
    val encode_term = Term_XML.Encode.term consts;

    val encode_const =
      let open XML.Encode Term_XML.Encode
      in pair encode_syntax (pair (list string) (pair typ (pair (option encode_term) bool))) end;

    fun export_const c (T, abbrev) =
      let
        val syntax = get_syntax_const thy_ctxt c;
        val U = Logic.unvarifyT_global T;
        val U0 = Type.strip_sorts U;
        val abbrev' = abbrev
          |> Option.map (Proofterm.standard_vars_term Name.context #> map_types Type.strip_sorts);
        val args = map (#1 o dest_TFree) (Consts.typargs consts (c, U0));
        val propositional = Object_Logic.is_propositional thy_ctxt (Term.body_type U0);
      in encode_const (syntax, (args, (U0, (abbrev', propositional)))) end;

    val _ =
      export_entities "consts" (SOME oo export_const) Sign.const_space
        (#constants (Consts.dest consts));


    (* axioms *)

    fun standard_prop used extra_shyps raw_prop raw_proof =
      let
        val (prop, proof) = Proofterm.standard_vars used (raw_prop, raw_proof);
        val args = rev (add_frees used prop []);
        val typargs = rev (add_tfrees used prop []);
        val used_typargs = fold (Name.declare o #1) typargs used;
        val sorts = Name.invent used_typargs Name.aT (length extra_shyps) ~~ extra_shyps;
      in ((sorts @ typargs, args, prop), proof) end;

    fun standard_prop_of thm =
      standard_prop Name.context (Thm.extra_shyps thm) (Thm.full_prop_of thm);

    val encode_prop =
      let open XML.Encode Term_XML.Encode
      in triple (list (pair string sort)) (list (pair string typ)) encode_term end;

    fun encode_axiom used prop =
      encode_prop (#1 (standard_prop used [] prop NONE));

    val _ =
      export_entities "axioms" (K (SOME o encode_axiom Name.context))
        Theory.axiom_space (Theory.all_axioms_of thy);


    (* theorems and proof terms *)

    val clean_thm = Thm.check_hyps (Context.Theory thy) #> Thm.strip_shyps;
    val prep_thm = clean_thm #> Thm.unconstrainT #> Thm.strip_shyps;

    val lookup_thm_id = Global_Theory.lookup_thm_id thy;

    fun expand_name thm_id (header: Proofterm.thm_header) =
      if #serial header = #serial thm_id then ""
      else
        (case lookup_thm_id (Proofterm.thm_header_id header) of
          NONE => ""
        | SOME thm_name => Thm_Name.print thm_name);

    fun entity_markup_thm (serial, (name, i)) =
      let
        val space = Facts.space_of (Global_Theory.facts_of thy);
        val xname = Name_Space.extern_shortest thy_ctxt space name;
        val {pos, ...} = Name_Space.the_entry space name;
      in make_entity_markup (Thm_Name.print (name, i)) (Thm_Name.print (xname, i)) pos serial end;

    fun encode_thm thm_id raw_thm =
      let
        val deps = map (Thm_Name.print o #2) (Thm_Deps.thm_deps thy [raw_thm]);
        val thm = prep_thm raw_thm;

        val proof0 =
          if Proofterm.export_standard_enabled () then
            Proof_Syntax.standard_proof_of
              {full = true, expand_name = SOME o expand_name thm_id} thm
          else if Proofterm.export_enabled () then Thm.reconstruct_proof_of thm
          else MinProof;
        val (prop, SOME proof) = standard_prop_of thm (SOME proof0);
        val _ = Thm.expose_proofs thy [thm];
      in
        (prop, deps, proof) |>
          let
            open XML.Encode Term_XML.Encode;
            val encode_proof = Proofterm.encode_standard_proof consts;
          in triple encode_prop (list string) encode_proof end
      end;

    fun export_thm (thm_id, thm_name) =
      let
        val markup = entity_markup_thm (#serial thm_id, thm_name);
        val thm = Global_Theory.get_thm_name thy (thm_name, Position.none);
      in XML.Elem (markup, encode_thm thm_id thm) end;

    val _ = export_body thy "thms" (map export_thm (Global_Theory.dest_thm_names thy));


    (* type classes *)

    val encode_class =
      let open XML.Encode Term_XML.Encode
      in pair (list (pair string typ)) (list (encode_axiom Name.context)) end;

    fun export_class name =
      (case try (Axclass.get_info thy) name of
        NONE => ([], [])
      | SOME {params, axioms, ...} => (params, map (Thm.plain_prop_of o clean_thm) axioms))
      |> encode_class |> SOME;

    val _ =
      export_entities "classes" (fn name => fn () => export_class name)
        Sign.class_space (map (rpair ()) (Graph.keys (Sorts.classes_of (#2 (#classes rep_tsig)))));


    (* sort algebra *)

    local
      val prop = encode_axiom Name.context o Logic.varify_global;

      val encode_classrel =
        let open XML.Encode
        in list (pair prop (pair string string)) end;

      val encode_arities =
        let open XML.Encode Term_XML.Encode
        in list (pair prop (triple string (list sort) string)) end;
    in
      val export_classrel =
        maps (fn (c, cs) => map (pair c) cs) #> map (`Logic.mk_classrel) #> encode_classrel;

      val export_arities = map (`Logic.mk_arity) #> encode_arities;

      val {classrel, arities} =
        Sorts.dest_algebra (map (#2 o #classes o Type.rep_tsig o Sign.tsig_of) parents)
          (#2 (#classes rep_tsig));
    end;

    val _ = if null classrel then () else export_body thy "classrel" (export_classrel classrel);
    val _ = if null arities then () else export_body thy "arities" (export_arities arities);


    (* locales *)

    fun encode_locale used =
      let open XML.Encode Term_XML.Encode in
        triple (list (pair string sort)) (list (pair (pair string typ) encode_syntax))
          (list (encode_axiom used))
      end;

    fun export_locale loc =
      let
        val {typargs, args, axioms} = locale_content thy loc;
        val used = fold Name.declare (map #1 typargs @ map (#1 o #1) args) Name.context;
      in encode_locale used (typargs, args, axioms) end
      handle ERROR msg =>
        cat_error msg ("The error(s) above occurred in locale " ^
          quote (Locale.markup_name thy_ctxt loc));

    val _ =
      export_entities "locales" (fn loc => fn () => SOME (export_locale loc))
        Locale.locale_space (get_locales thy);


    (* locale dependencies *)

    fun encode_locale_dependency (dep: Locale.locale_dependency, subst) =
      (#source dep, (#target dep, (#prefix dep, subst))) |>
        let
          open XML.Encode Term_XML.Encode;
          val encode_subst =
            pair (list (pair (pair string sort) typ)) (list (pair (pair string typ) (term consts)));
        in pair string (pair string (pair (list (pair string bool)) encode_subst)) end;

    val _ =
      get_dependencies parents thy
      |> map_index (fn (i, dep) =>
        let
          val xname = string_of_int (i + 1);
          val name = Long_Name.implode [Context.theory_name thy, xname];
          val markup = make_entity_markup name xname (#pos (#1 dep)) (#serial (#1 dep));
          val body = encode_locale_dependency dep;
        in XML.Elem (markup, body) end)
      |> export_body thy "locale_dependencies";


    (* constdefs *)

    val constdefs =
      Defs.dest_constdefs (map Theory.defs_of (Theory.parents_of thy)) (Theory.defs_of thy)
      |> sort_by #1;

    val encode_constdefs =
      let open XML.Encode
      in list (pair string string) end;

    val _ =
      if null constdefs then () else export_body thy "constdefs" (encode_constdefs constdefs);


    (* spec rules *)

    val encode_specs =
      let open XML.Encode Term_XML.Encode in
        list (fn {props, name, rough_classification, typargs, args, terms, rules} =>
          pair properties (pair string (pair Spec_Rules.encode_rough_classification
            (pair (list (pair string sort)) (pair (list (pair string typ))
              (pair (list (pair encode_term typ)) (list encode_term))))))
              (props, (name, (rough_classification, (typargs, (args, (terms, rules)))))))
      end;

    val _ =
      (case Spec_Rules.dest_theory thy of
        [] => ()
      | spec_rules => export_body thy "spec_rules" (encode_specs (map spec_rule_content spec_rules)));


    (* parents *)

    val _ =
      Export.export thy \<^path_binding>\<open>theory/parents\<close>
        (XML.Encode.string (cat_lines (map Context.theory_long_name parents)));

  in () end);

end;

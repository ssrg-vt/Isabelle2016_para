(*  Title:      Pure/ML_Root.thy
    Author:     Makarius

Support for ML project ROOT file, with imitation of ML "use" commands.
*)

theory ML_Root
imports Pure
keywords "use" "use_debug" "use_no_debug" :: thy_load
begin

setup \<open>Context.theory_map ML_Env.init_bootstrap\<close>

ML \<open>
local

val _ =
  Outer_Syntax.command @{command_keyword use}
    "read and evaluate Isabelle/ML or SML file"
    (Resources.parse_files "use" --| @{keyword ";"} >> ML_File.use NONE);

val _ =
  Outer_Syntax.command @{command_keyword use_debug}
    "read and evaluate Isabelle/ML or SML file (with debugger information)"
    (Resources.parse_files "use_debug" --| @{keyword ";"} >> ML_File.use (SOME true));

val _ =
  Outer_Syntax.command @{command_keyword use_no_debug}
    "read and evaluate Isabelle/ML or SML file (no debugger information)"
    (Resources.parse_files "use_no_debug" --| @{keyword ";"} >> ML_File.use (SOME false));

in end
\<close>

end

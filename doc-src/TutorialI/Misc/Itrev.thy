(*<*)
theory Itrev = Main:;
(*>*)

text{*
Function @{term"rev"} has quadratic worst-case running time
because it calls function @{term"@"} for each element of the list and
@{term"@"} is linear in its first argument.  A linear time version of
@{term"rev"} reqires an extra argument where the result is accumulated
gradually, using only @{name"#"}:
*}

consts itrev :: "'a list \\<Rightarrow> 'a list \\<Rightarrow> 'a list";
primrec
"itrev []     ys = ys"
"itrev (x#xs) ys = itrev xs (x#ys)";

text{*\noindent
The behaviour of @{term"itrev"} is simple: it reverses
its first argument by stacking its elements onto the second argument,
and returning that second argument when the first one becomes
empty. Note that @{term"itrev"} is tail-recursive, i.e.\ it can be
compiled into a loop.

Naturally, we would like to show that @{term"itrev"} does indeed reverse
its first argument provided the second one is empty:
*};

lemma "itrev xs [] = rev xs";

txt{*\noindent
There is no choice as to the induction variable, and we immediately simplify:
*};

apply(induct_tac xs, simp_all);

txt{*\noindent
Unfortunately, this is not a complete success:
\begin{isabelle}
~1.~\dots~itrev~list~[]~=~rev~list~{\isasymLongrightarrow}~itrev~list~[a]~=~rev~list~@~[a]%
\end{isabelle}
Just as predicted above, the overall goal, and hence the induction
hypothesis, is too weak to solve the induction step because of the fixed
@{term"[]"}. The corresponding heuristic:
\begin{quote}
\emph{Generalize goals for induction by replacing constants by variables.}
\end{quote}
Of course one cannot do this na\"{\i}vely: @{term"itrev xs ys = rev xs"} is
just not true---the correct generalization is
*};
(*<*)oops;(*>*)
lemma "itrev xs ys = rev xs @ ys";

txt{*\noindent
If @{term"ys"} is replaced by @{term"[]"}, the right-hand side simplifies to
@{term"rev xs"}, just as required.

In this particular instance it was easy to guess the right generalization,
but in more complex situations a good deal of creativity is needed. This is
the main source of complications in inductive proofs.

Although we now have two variables, only @{term"xs"} is suitable for
induction, and we repeat our above proof attempt. Unfortunately, we are still
not there:
\begin{isabelle}
~1.~{\isasymAnd}a~list.\isanewline
~~~~~~~itrev~list~ys~=~rev~list~@~ys~{\isasymLongrightarrow}\isanewline
~~~~~~~itrev~list~(a~\#~ys)~=~rev~list~@~a~\#~ys
\end{isabelle}
The induction hypothesis is still too weak, but this time it takes no
intuition to generalize: the problem is that @{term"ys"} is fixed throughout
the subgoal, but the induction hypothesis needs to be applied with
@{term"a # ys"} instead of @{term"ys"}. Hence we prove the theorem
for all @{term"ys"} instead of a fixed one:
*};
(*<*)oops;(*>*)
lemma "\\<forall>ys. itrev xs ys = rev xs @ ys";

txt{*\noindent
This time induction on @{term"xs"} followed by simplification succeeds. This
leads to another heuristic for generalization:
\begin{quote}
\emph{Generalize goals for induction by universally quantifying all free
variables {\em(except the induction variable itself!)}.}
\end{quote}
This prevents trivial failures like the above and does not change the
provability of the goal. Because it is not always required, and may even
complicate matters in some cases, this heuristic is often not
applied blindly.

In general, if you have tried the above heuristics and still find your
induction does not go through, and no obvious lemma suggests itself, you may
need to generalize your proposition even further. This requires insight into
the problem at hand and is beyond simple rules of thumb. In a nutshell: you
will need to be creative. Additionally, you can read \S\ref{sec:advanced-ind}
to learn about some advanced techniques for inductive proofs.
*};

(*<*)
by(induct_tac xs, simp_all);
end
(*>*)

module ineq; % Inequalities and linear optimization.

% Author:       Herbert Melenk <melenk@zib-berlin.dbp.de>

% Driver for solving inequalities and inequality systems.

% Implemented methods:
%
%   -  linear multivariate system 
%   -  polynomial/rational univariate inequality and system

% Common algebraic interface:
%
%     ineq_solve(<ineq/ineqlist> [,<variable/variablelist>])

create!-package('(ineq linineq liqsimp1 liqsimp2 polineq),'(solve));

load!-package 'solve;  % Some routines from solve are needed.      

fluid '(solvemethods!*);

if not memq('ineqseval,solvemethods!*) then
      solvemethods!* := 'ineqseval!*!* . solvemethods!*;

if not get('geq,'simpfn) then
    <<mkop 'leq; mkop 'geq; mkop 'lessp; mkop 'greaterp>>;

if not get('!*interval!*,'simpfn) then
    <<mkop '!*interval!*;
      infix !*interval!*;
      put('!*interval!*,'prtch," .. ")
    >>;
      
symbolic procedure ineqseval!*!* u;
 % Interface to solve.
  (if null w then nil
    else if w='(failed) then if smemql('(leq geq lessp greaterp),u)
      then w else nil
    else w)
      where w=ineqseval u;

symbolic procedure ineqseval!* u;
 % Interface to ineq_solve.
  (if null w or w='(failed) then car u else w)
      where w=ineqseval u;

put('ineq_solve,'psopfn,'ineqseval!*);

symbolic procedure ineqseval(u);
  begin scalar s,s1,v,v1,l,w1,w2,err,ineqp,str;
   integer n;
   s:=reval car u;
   s:=if eqcar(s,'list) then cdr s else {s};
   if cdr u then
   <<v:= reval cadr u; 
     v:=if eqcar(v,'list) then cdr v else {v};
   >>;
   % test for linearity, collect variables.
   l:=t;
   s1:=for each q in s join if not err then
   <<if atom q or not memq(car q,'(leq geq lessp greaterp equal))
	then err:=t else
  << if not(car q eq 'equal) then ineqp := t;
     n:=n#+1;
     str := str or memq(car q,'(lessp greaterp));
     w1:=simp cadr q; w2:=simp caddr q;
     v1:=union(v1,solvevars{w1,w2});
     if not domainp denr w1 or not domainp denr w2 then l:=nil;
     {numr w1,denr w1,numr w2,denr w2}
   >> >>;
   if err or not ineqp then return nil;
   if null v then v:=v1;
   l := l and not nonlnrsys(s1,v);
   if length v1 > length v or not subsetp(v,v1) or not l and cdr v1 then
       return '(failed); % Too many indeterminates in inequality system;
%  if not l and n#>1 then
%      return '(failed); % Nonlinear system not implemented.
   if l and str then
       return '(failed); % No strict linear system.
   return if l then linineqseval u else polineqeval u;
  end;

endmodule;

end;
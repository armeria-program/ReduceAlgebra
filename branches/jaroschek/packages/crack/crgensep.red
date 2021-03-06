%*********************************************************************
module gensep_lin$
%*********************************************************************
%  Routines for generalized separation of de's
%  Author: Andreas Brand, Thomas Wolf 1990 1994 1997
%          Thomas Wolf since 1997

% BSDlicense: *****************************************************************
%                                                                             *
% Redistribution and use in source and binary forms, with or without          *
% modification, are permitted provided that the following conditions are met: *
%                                                                             *
%    * Redistributions of source code must retain the relevant copyright      *
%      notice, this list of conditions and the following disclaimer.          *
%    * Redistributions in binary form must reproduce the above copyright      *
%      notice, this list of conditions and the following disclaimer in the    *
%      documentation and/or other materials provided with the distribution.   *
%                                                                             *
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" *
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE   *
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  *
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE   *
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR         *
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF        *
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS    *
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     *
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)     *
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE  *
% POSSIBILITY OF SUCH DAMAGE.                                                 *
%******************************************************************************

symbolic procedure quick_gen_separation(arglist)$   
% Indirect separation of a pde
if vl_ then % otherwise not possible --> save time
begin scalar p,l,l1,pdes,stp$
 % pdes:=clean_up(car arglist)$
 % if pdes then l:=list(pdes,cadr arglist)$ 
 % because the bookeeping of to_drop is not complete instead:
 pdes:=car arglist$
 % to return the new list of pdes in case gensep is not successful
 if expert_mode then <<
   l1:=selectpdes(pdes,1);
   if get(car l1,'starde) then flag(l1,'to_gensep)
 >>             else l1:=cadddr arglist$
 if (p:=get_gen_separ_pde(l1,t,t)) then % high priority
    <<l:=gensep(p,pdes)$ % if l=1 then a case distinction has been
                         % put on to_do_list and simply the input
                         % has to be returned from this procedure
                         % to start to_do next
      if l neq 1 then <<
        pdes:=delete(p,pdes)$
        for each a in l do <<
          pdes:=eqinsert(a,pdes)$
          if member(a,pdes) and (stp:=get(a,'starde)) then
          to_do_list:=cons(list(if cdr stp=0 then 'separation
                                             else 'gen_separation,
                                %pdes,cadr arglist,caddr arglist,
                                list a),
                           to_do_list)
        >>
      >>$
      l:=list(pdes,cadr arglist)>>$
 return l$
end$

symbolic procedure case_gen_separation(arglist)$
% does a gen_separation of expressions where the coefficients
% that are divided through may be zero.
if null lin_problem then
begin scalar force_sep_bak,h$
 force_sep_bak:=force_sep$ force_sep:=t$
 h:=gen_separation(arglist)$
 force_sep:=force_sep_bak$
 return h
end$

symbolic procedure gen_separation(arglist)$      
% Indirect separation of a pde
if vl_ then % otherwise not possible --> save time
begin scalar p,l,l1,pdes,stp$
 % pdes:=clean_up(car arglist)$
 % if pdes then l:=list(pdes,cadr arglist)$ 
 % because the bookeeping of to_drop is not complete instead:
 pdes:=car arglist$
 % to return the new list of pdes in case gensep is not successful
 if expert_mode then <<
   l1:=selectpdes(pdes,1);
   if get(car l1,'starde) then flag(l1,'to_gensep)
 >>             else l1:=cadddr arglist$
%#% if (p:=get_gen_separ_pde(l1,nil,t)) then % low priority
 if (p:=get_gen_separ_pde(l1,nil,nil)) then % low priority
    <<l:=gensep(p,pdes)$ % if l=1 then a case distinction has been
                         % put on to_do_list and simply the input
                         % has to be returned from this procedure
                         % to start to_do next
      if l neq 1 then <<
        pdes:=delete(p,pdes)$
        for each a in l do <<
          pdes:=eqinsert(a,pdes)$
          if member(a,pdes) and (stp:=get(a,'starde)) then
          to_do_list:=cons(list(if cdr stp=0 then 'separation
                                             else 'gen_separation,
                                %pdes,cadr arglist,caddr arglist,
                                list a),
                           to_do_list)
        >>
      >>$
      l:=list(pdes,cadr arglist)>>$
 return l$
end$

symbolic procedure maxnoargs(fl,v)$            
% determines the maximal number of arguments of any of the 
% functions of fl
begin scalar f,n,m;
  n:=0;
  for each f in fl do
  <<m:=fctargs f;
    m:=if m and not_included(v,m) then length m
            else 0;
    if n<m then n:=m
  >>;
  return n
end$

symbolic procedure get_gen_separ_pde(pdes,high_priority,lin)$  
% looking for a pde in pdes which can be indirectly separated
% if lin then only a liner PDE
% p ...the next equation that will be chosen
% dw...whether p was already delt with
% na...number of variables in the equation
% nv...maximal number of arguments of any of the functions of p
% nf...min number of functions to be dropped before direct sep.
% leng...length of p
begin scalar p,nv,nf,dw,len,h1,h2,h3,h4,nvmax$ %na,h5
%  ncmax:=nvmax$
  if high_priority then <<
    nvmax:=0;
    for each p in pdes do if (h1:=get(p,'nvars))>nvmax then nvmax:=h1;
    p:=nil
  >>$
  while pdes do <<
    if (flagp(car pdes,'to_gensep                 ) or
        (force_sep and flagp(car pdes,'to_casesep))    ) and
%#%   if flagp(car pdes,'to_gensep)                  and
       (null lin or get(car pdes,'linear_))        and
         % not too many terms or enough terms
      <<h1:=get(car pdes,'length)$
        (null high_priority) or
        (get(car pdes,'nvars)=nvmax) or
        ( low_gensep>h1)     or      
        (high_gensep<h1)  
      >>                                           and 
         % no single function depending on all variables:
      (h3:=get(car pdes,'starde)                 ) and
         % not directly separable: 
      (cdr h3 neq 0                              ) and
         % Each time the equation is investigated and differentiated
         % wrt the first element of car h3, this element is dropped.
         % --> The equation should not already have been differentiated
         % wrt all variables:
      (not null car h3                           ) and     
         % If equations have been investigated by generalized
         % separation or if equations resulted from generalized
         % separation then they get the flag used_ to be solved
         % first, not to have too many unevaluated new functions
         % at a time
      ((h4:=flagp(car pdes,'used_)          ) or 
       (null dw)                                 ) and
         % The variables in h3 are the ones wrt which direct separation
         % shall be achieved after differentiation, therefore functions
         % of these variables have to be thrown out. The remaining
         % functions shall be of as many as possible arguments to
         % make quick progress:
      ((null p                              ) or
       (len > h1                            ) or   % neu
       ((len = h1) and (                           % neu
       (nv < (h2:=maxnoargs(
                  get(car pdes,'fcts),
                  car h3   ))               ) or
       ((nv = h2) and (
%       (na < (h5:=get(car pdes,'nvars))     ) or
%       ((na = h5) and (
       ((null dw) and flagp(car pdes,'used_)) or
       (( nf > cdr h3       ) or
        ((nf = cdr h3 ) and          
         (len > h1    )     )    )         )    ))))      then
    <<p:=car pdes;
      nv:=if (null nv) or (null h2) then maxnoargs(get(p,'fcts),car h3)
                                    else h2;
%      na:=if (null na) or (null h5) then get(car pdes,'nvars)
%                                    else h5;
      if h4 then dw:=h4;
      nf:=cdr h3;
      len:=h1>>$
    pdes:=cdr pdes$
  >>;
  return p
end$

%-----------------

symbolic procedure gensep(p,pdes)$   
%  generalized separation of pde p
if zerop cdr get(p,'starde) then separate(p,pdes)   % be dropped?
else                                                % e.g. a=((x y z).2)
% POSSIBLE REASONS FOR FAILURE: 
% - After the sequence of divisions and differentiations in the direct 
%   separation, if there explicit v-dependent coefficients are taken 
%   out which also contain later integration variables, then the integrands 
%   are not total derivatives anymore --> no backintegration is possible.
% - This corresponds to the case when all variables occur explicitly but
%   in a non-product expression, like sin(x*y*z)
begin    scalar a,pl$
  if print_ then <<terpri()$write "generalized separation of ",p>>$
  if tr_gensep then
  <<a:=get(p,'starde)$
    terpri()$write "de to be separated : "$
    typeeqlist list p$
    terpri()$write "variable list for separation : ",car a$
    terpri()$write "for each of these variables ",cdr a$
    if (cdr a)=1 then write" function does"
                 else write" functions"$
    write" depend on it "
  >>$

  cp_sq2p_val(p)$                              %#?#  to be dropped in later versions
  %--- so far only one DE p in the pool starlist of equations
  pl:=partitn(get(p,'pval),   % expression     %#?#  to be dropped in later versions
              nil,            % history of divisions/diff so far
              get(p,'fcts),   % functions
              get(p,'vars),   % variables
              car get(p,'starde)  % separation charac.
             );

  if pl then <<
    pl:=append(for each a in car pl collect simp cdr a,for each a in cadr pl collect simp a); % <--- old  22.8.08
%   pl:=append(for each a in car pl collect simp a,for each a in cadr pl collect simp a);  % <--- next
    pl:=mkeqsqlist(pl,nil,nil,fctsort union(ftem_,get(p,'fcts)),get(p,'vars), 
                   cons('to_drop,allflags_),t,get(p,'orderings),pdes)$
    drop_pde(p,nil,nil);
    flag(pl,'used_);
    if print_ then <<terpri()$
      a:=length pl$
      write "separation yields ",a," new equation"$
      if a > 1 then write"s"$ write" : "$
      if tr_gensep then typeeqlist pl
                   else listprint pl$
      terpri()
    >> 
  >> else <<
    remflag1(p,'to_gensep)$
    pl:=list p
  >>$
  return pl$
end$

%-----------------

symbolic procedure partitn(q,old_histy,ftem,vl,a)$  
%       This procedure calls itself recursively!
% q:    a **-expression to be separated (currently still in prefix form)
% old_histy: a list of elements {denom,v,{(divisor . expr_before),..}}
%       where a sequence of divisions through factors from the
%       list of divisors and differentiations wrt. v and 
%       afterwards multiplication with denom resulted in q
% ftem: functions in the expression
% vl:   variables in the expression
% a:    the variables for direct separation=car starp(), i.e. the variables
%       which occur in the fewest number of functions, these are the 
%       variables wrt. which we want to separate directly
%
% RETURNS {{(c1.q1),(c2.q2),(c3.q3),..},{s1,s2,s3,..},{r1,r2,..},{f1,f2,..}}
% where qi=0 are necessary consequences,
% qi are not **-expressions, and not *-expressions 
% sum_i ci*qi = q
% si=0 are consistency conditions determining constants/functions
% of integration 
% ri=0 are other cases to be checked --> case distinctions
% fi are new functions of integration
%
% Key to understanding the procedures partitn, felim and backint is the
% list histy. It is a list of elements, say e_i, where e_i are the steps
% taken to get rid of one function. One e_i consists of a denominator that 
% is dropped initially then the differentiation variable and then a list 
% where each element is a dotted pair where car is a factor that is dropped 
% before a differentiation and cdr is the expression before the factor is
% dropped.
%
begin scalar histy,l1,l4,nv,vl1,nv1,h,x,f,ft,aa,bb,cc,
      ruli,extra_cond,par,cases,newf$

  %--- ft: the list of functions to drop from q by differentiation
  %---     to do a direct separation wrt x:
  % x = any one variable in a on which a function with as 
  % many as possible variables does not depend on
  % Find such a function and variable x
  ft:=ftem;    
  nv:=0;
  while ft do <<
    vl1:=fctargs car ft;
    nv1:=if vl1 then length vl1
                else 0;
    if nv1 > nv then <<
      h:=setdiff(a,vl1);
      if h then <<   % i.e. the function car ft does not depend 
                     % on at least one variable from a
        x:=car h;
        % if possible find an x occuring explicitly in q
        while h and freeof(q,car h) do h:=cdr h;
        if h then x:=car h;
        f:=car ft;
        nv:=nv1
      >>
    >>;
    ft:=cdr ft
  >>; 
  if nv=0 then x:=car a;  % no x was found

  if tr_gensep then
  <<terpri()$write "--- The aim is to separate directly w.r.t. ",x$
    write " the expression : "$deprint list q  >>$

  % Find all functions ft in q depending on x
  ft:=nil$
  for each f in ftem do
  if member(x,fctargs f) and not freeof(q,f) then ft:=cons(f,ft)$
  ft:=fctsort reverse ft$      % sorting w.r.t. number of args

  ruli:=start_let_rules()$

  %--- throwing out functions ft until ft=nil
  %--- or until the expression lost the *-property
  if tr_gensep then
  <<terpri()$write "--- To separate w.r.t. ",x,
                   " we need to get rid of functions ", ft>>$

  while ft do << % for each function to get rid of 
                 % (possibly each time a different diff variable)   
    l1:=felim(q,car ft,ftem,vl);
    % felim returns:  nil if not successful (quotient) otherwise
    %  {the expression after all the divisions and differentiations,
    %   {diff variable, list of (factor . expression before)}   }
    if null l1 then ft:=nil  % to stop
               else << % Listing of all special cases to be considered
      for each h in cdadr l1 do 
      if null can_not_become_zerosq(simp car h,ftem) then cases:=cons(car h,cases);
      if cases then <<
        % add case distinctions to todo list
        to_do_list:=cons(list('split_into_cases,simp car cases),to_do_list);
        l1:=nil$
        ft:=nil 
      >>
    >>$

    if l1 then <<
      if zerop car l1 then <<
        % q:=reval {'QUOTIENT,cdr cadadr l1,car cadadr l1}; 
        % This division through car cadadr l1 had to be dropped because the
        % back-multiplication will not happen --> check_sum gets wrong --> loop
        q:={'quotient,reval {'quotient,cdr cadadr l1,car cadadr l1},
                      {'quotient,1,car cadadr l1}}$
        cc:=cadr l1$
        % We drop the last division and differentiation.
        cc:=cons(car cc,cddr cc)
        % where car cc is the differentiation variable
      >>              else <<
        q:=car l1$                            % new expression
        cc:=cadr l1;
      >>$
      if (pairp q) and (car q='quotient) then <<
        bb:=caddr q;                          % we take off the denimonator
        q:=cadr q                             % q is now only the numerator
      >>                                 else bb:=1$
      % Now bb is the denominator and q has denominator 1.

      histy:=cons(cons(bb,cc),histy)$         % extended history
      ftem:=smemberl(ftem,q)$                 % functions still in q
      aa:=stardep(ftem,argset(ftem))$         % still *-expression?
      if not aa or 
         zerop cdr aa then ft:=nil                   % to stop
                      else ft:=smemberl(cdr ft,ftem) % remain. fcts of x
    >>
  >>$

  stop_let_rules(ruli)$

  return 
  if null l1 then if tr_gensep then <<terpri()$
                    write"felim or newgensep gave nil!!"$terpri()$
                    write"q=",q; terpri();
                    nil 
                  >>           else nil
             else <<
    if tr_gensep then <<
      terpri()$
      write"Now ready for direct separation."
    >>;

    %--- prepare list of variables vl1 for direct separation
    % vl1:=nil$
    % for each h in vl do if my_freeof(ftem,h) then vl1:=cons(h,vl1);
    vl1:=vl$  % It is not good enough to separate wrt. vl1 because it could
    % be that further direct separability could be possible wrt. variables
    % the still occuring functions ftem do not depend on.

    %--- direct separation if useful (i.e. if aa(=stardep) neq nil)
    if vl1 and not (q=0) then
    <<if tr_gensep then
      <<terpri()$write "trying direct separation of "$
        deprint list q$
        write "Remaining variables: ",vl1>>$
      l1:=separ(q,ftem,vl1,nil,nil)$   % direct separation of the numerator
      if tr_gensep then
      <<terpri()$
        write "The result of direct separation: "$
        deprint for each bb in l1 collect cdr bb>>$
    >>             else <<
     if tr_gensep then <<
       terpri()$write"Direct Separation of "$
       deprint list q$
       write"was not tried."
     >>;
     l1:=list cons(1,q)$
    >>$

    % Although the vaiable x does not occur anymore
    % (each felim call removed one function of x
    %  and direct separation removed explicit occurences of x)
    % the remaining expression may still be indirectly separable
    % --> recursive call of partitn
    % l4 becomes a list of pairs (sep_coefficient . sep_remainding_factor) 

    while l1 do <<
      h:=car l1; l1:=cdr l1;    
      ft:=smemberl(ftem,cdr h);
      vl1:=argset(ft)$
      if null (aa:=stardep(ft,vl1)) or 
         (not pairp ft) or (car ft neq 'plus) then l4:=cons(h,l4)
                                              else <<
        par:=partitn(cdr h,   % expression
                     append(histy,      % history so far, 
                            old_histy), % needed to add new functions
                              % of integration properly differentiated
                              % to be able to integrate below
                     ft,      % functions
                     vl1,     % variables
                     car aa   % separation charac.
                    );
	% RETURNS {{(c1.q1),(c2.q2),(c3.q3),..},{s1,s2,s3,..},
	%          {r1,r2,..},{f1,f2,..}                      }
	% where qi=0 are necessary consequences,
	% qi are not *-expressions,
	% sum_i ci*qi = q
	% si=0 are consistency conditions determining constants/functions
	% of integration 
	% ri=0 are other cases to be checked --> case distinctions
        % fi are new functions of integration

        if par then <<
	  l4:=append(l4,for each f in car par collect 
			  ({'times,car h,car f} . cdr f));  
	  extra_cond:=append(extra_cond,cadr par); % collecting any
						   % appearing conditions
	  cases:=append(cases,caddr par);
	  newf:=cadddr par;
	  ftem:=append(ftem,newf);
        >>     else l1:=nil
      >>
    >>$

    %--- backintegration
    par:=backint(l4,old_histy,histy,ftem,vl)$
    if par then <<
     extra_cond:=append(extra_cond,cadr par); % collecting any conditions
     {car par,extra_cond,cases,append(newf,caddr par)}
    >>     else nil
  >>
end$

%-----------

symbolic procedure felim(q,f,ftem,vl)$
  % get rid of function f in q
  % returns:  nil if not successful (quotient) otherwise
  %  {the expression after all the divisions and differentiations,
  %   {diff variable, (factor . expression before), 
  %                   (factor . expression before), ... }
  %  }
begin scalar a,b,l,l1,ft1,v,prflag,f1$
  %--- getting rid of f through diff. wrt. v
  v:=car setdiff(vl,fctargs f)$  

  %--- ft1 are all v-independent functions
  %--- In the call to separ we want to separate wrt. v so in the call 
  %    of separ one has to pass on only v-independent functions ft1 as
  %    functions to be determined
  ft1:=nil$
  for each f1 in ftem do if my_freeof(f1,v) then ft1:=cons(f1,ft1)$

  %--- To run separ, functions ft1 should not be in the denominator
  %--- ?????? What if nonl. Problems?

  if pairp q and (car q='quotient) and smemberl(ft1,caddr q) then <<
   if tr_gensep then <<
    terpri()$
    write "The quotient of the expression to be separated contains one or more ",
          v,"-independent function: ",smemberl(ft1,caddr q),
          " which prevents further continuation. (This should not occur anymore.)"
   >>
  >>                                                         else
  <<prflag:=print_$print_:=nil$
    l:=separ(q,ft1,list v,nil,nil)$ % det. all lin. ind. factors with v

    % sorting elements of l such that those with many v-dependent terms come 
    % first in this list and further below come last in the divisions and 
    % differentiations
    l:=for each a in rev_idx_sort for each b in l collect 
                                  cons(if numberp car b then 0 
                                                        else delength car b,b)
       collect cdr a$

    if tr_gensep then
    <<terpri()$write "To get rid of ",f,
		     " we differentiate w.r.t. : ",v>>$
    print_:=prflag$

    %--- l is a list of dotted pairs a each representing a term in q 
    % where car(a) is the product of v-dep. factors and cdr(a) the
    % product of v-independent factors
    %--- A list l1 of car(a) is generated for which cdr(a) depends
    % on f. l1 is the list of divisions to be done before differen.
    % Here the list of divisions is reversed, so therefore the
    % divisions with the fewest terms come first.
    l1:=nil$
    while l do
    <<a:=car l$
      b:=nil$
      if not freeof(cdr a,f) and (not zerop car a) then
      l1:=cons(car a,l1)$
      l:=cdr l
    >>$
    if tr_gensep then
    <<terpri()$
      write v," - depending coefficients of terms containing ",f," : "$
      for each ss in l1 do eqprint ss>>$

    %--- Now the divisions and differentiations are done
    while l1 do <<
!#if (equal version!* "REDUCE 3.6")
      b:=reval aeval car l1$ %--- b is the v-dep. coefficient   
!#else          
      b:=reval car l1$ %--- b is the v-dep. coefficient   
!#endif
      l1:=cdr l1$
      %--- ????? If for non-linear Problems b includes ftem functions
      % then the extra case 0 = b has to be considered
      if zerop b then << 
       write"#### Planned division through zero in gensep! ####"$
       terpri()
      >>         else <<                    
!#if (equal version!* "REDUCE 3.6")
        a:=reval aeval list('quotient,q,b)$ 
!#else 
        a:=reval list('quotient,q,b)$ 
!#endif
        %--- for later backward integrations: extension of the history
        l:=cons(b . q ,l)$  %--- new: q is the equ. before division & diff.
        % l will be returned later by felim 
        %--- l1 has to be updated as the coefficients
        % change through division and differentiation
	l1:=for each c in l1 collect
	    reval list('df,list('quotient,c,b),v)$
        %--- the differentiation
	q:=reval list('df,a,v)$
	if tr_gensep then
	<<write "The new equation: "$
	  eqprint q$
	  write "The remaining factors:"$
	  for each ss in l1 do eqprint ss
	>>
      >>
    >>$

    %--- output
    if tr_gensep then
    <<terpri()$write "new expression (should not depend on ",f,") : "$
      eqprint q$>>$
    if tr_gensep and l then
    <<write"To invert the last steps one has to integr. wrt. ",v$ 
      terpri()$
      write "each time before multiplying with the following factors:"$
      for each aa in l do eqprint car aa
    >>$

    l1:=list(q,cons(v,l))
  >>$
  return l1
end$ % of felim

%-----------

symbolic procedure backint(l4,old_histy,histy,ftem,vl)$
% l4 is a list of pairs (sep_coefficient . 
%                        sep_remainding_factor_to_be_integrated) 
% old_histy, histy are lists of elements 
%       {denom,v,{(divisor . expr_before),..}}
%       where a sequence of divisions through factors from the
%       list of divisors and differentiations wrt. v and 
%       afterwards multiplication with denom resulted in q
%       Integrations should only be done inverting histy, but
%       in choosing functions of integration, both should be used
%
% returns {- integrated equivalent of l4 where the cdr of each element
%            is the integrated expression,
%          - a list of check_sum conditions,
%          - a list of new functions}
begin scalar succ,ft,q,l,v,v1,vf,s1,s2,p,f1,f2,fctr,check_sum,
             allfnew,new_cond,denomi$
  % start of the backintegration
  succ:=t$
  while histy and succ do
  <<l:=car histy$     % l={diff variable, sequence of (factor . exp before)}
    histy:=cdr histy$
    denomi:=car l$
    v:=cadr l$
    l:=cddr l$

    % At first putting the denominator back in
    % l4 is a list of pairs (sep_coefficient . sep_remainding_factor) 
    if denomi neq 1 then
    l4:=for each h in l4 collect (car h . {'quotient,cdr h,denomi});

    if tr_gensep then <<terpri()$ write "backward integration w.r.t. ",v>>$

    % Now the sequence of integrations wrt v
    % l is the list of (factor . expression before division & diff)
    while l and succ do <<         % while l and q do
      fctr:=caar l;
      check_sum:=cdar l;
      l:=cdr l;
      if tr_gensep then
      <<terpri()$
        write "The integrals of the following partitioned subexpressions"$
        terpri()$
        write "added up should be equal the original expression: "$
        terpri()$
        eqprint check_sum
      >>$

      % l4 is a list of pairs (sep_coefficient . sep_remainding_factor) 
      l4:=for each h in l4 collect if null car h then h % one integration    
                                                        % was not succ.ful
                                                 else <<
        ft:=smemberl(ftem,cdr h)$
        fnew_:=nil$
        if tr_gensep then
        <<terpri()$
          write "Backintegration of: "$eqprint cdr h$write" w.r.t. ",v$terpri()
        >>$
        q:=integratepde(cdr h,ft,v,nil,nil)$ % genflag:=nil, potflag=nil    %  <--- changed
        if null q then <<
          succ:=nil$
          if print_ then <<
            terpri()$
            write "#### Back integration of "$
            eqprint cdr h$
            write " wrt ",v," during generalized ",
                  "separation was not successful ####."$
            terpri()$
            write "The coeff. dropped in direct separation was "$
            mathprint car h
          >>
        >>        else <<
          if tr_gensep then
          <<terpri()$write "Backintegration gives: "$eqprint car q$
            terpri()$write "which is now multiplied with: "$eqprint fctr
          >>$
%          q:=reval list('TIMES,fctr,car h,car q)$  % One has to multiply with car h now %21.8.08
          q:=reval list('times,fctr,car q)$  % 22.8.08
          % One can not multiply with car h before the integratepde() call because car h 
          % can depend on extra independent variables on which the functions ft do
          % not depend and then the new functions of integration would not depend on 
          % them. But also after the integratepde() call, i.e. now, one can not multiply
          % with car h because further integrations may occur (partitn calls itself
          % recursively).
          % fctr is the next integrating factor
          
          % Neccessary: Substituting the new functions of integration by
          % derivatives of them such that back-integration can be made
          % hat fnew_ nur ein element, d.h. wird nur eine Integration gemacht
          % oder mehrere?
          for each f1 in fnew_ do
          <<f2:=f1$

            vf:=setdiff(vl,fctargs f1)$
            for each s1 in reverse append(histy,old_histy) do
            <<v1:=cadr s1$
              % The following also if not my_freeof(f1,v1)
              % The reason is that divisors may contain variables which
              % are later integration variables
              s2:=reverse cddr s1$
              while s2 do
              <<% only divisions through factors that can be swallowed by f1
                if not smemberl(vf,caar s2) then 
                f2:=list('quotient,f2,caar s2)$
                if not my_freeof(f1,v1) then f2:=reval list('df,f2,v1)$
                % actually only dividing through those factors of (caar s2)
                % which depend on v1 and which do not contain variables
                % which f2 does not depent on.
                s2:=cdr s2
              >>$
              if not smemberl(vf,car s1) then f2:=list('times,f2,car s1)$
            >>$
            % the remaining integrations in the current element of histy
            if histy then <<
              s2:=reverse l$ 
              while s2 do
              <<if not smemberl(vf,caar s2) then f2:=list('quotient,f2,caar s2)$
                if not my_freeof(f1,v1) then f2:=reval list('df,f2,v1)$
                s2:=cdr s2
              >>;
            >>;

            if f1 neq f2 then
            <<if tr_gensep then <<terpri()$
                                  write f1," is replaced by "$
                                  eqprint f2>>$
              q:=subst(f2,f1,q)$
            >>
          >>$
          allfnew:=append(fnew_,allfnew)$
          ftem:=union(fnew_,ftem);
          % car h is the coefficient dropped through direct separation          
          if succ then check_sum:={'difference,check_sum,{'times,q,car h}};     % <-------- changed  %22.8.08
%          if succ then check_sum:={'DIFFERENCE,check_sum,q};                     % <-------- new    %21.8.08
        >>$
        (car h . q) % the value to be collected to give the new l4              % <-------- changed %22.8.08
%         (1 . q) % the value to be collected to give the new l4                  % <-------- new  %21.8.08
      >>;
      if succ then <<
        check_sum:=reval check_sum$
        new_cond:=cons(check_sum,new_cond)$
        if succ and tr_gensep then
        <<terpri()$
          write "Consistency condition: "$eqprint check_sum
        >>
      >>
    >>
  >>$
  if succ then <<
    for each f in allfnew do <<
      ftem_:=fctinsert(f,ftem_)$
      flin_:=cons(f,flin_)$
    >>;
    flin_:=sort_according_to(flin_,ftem_)
  >>$

  if tr_gensep then if succ then <<terpri()$write "yields : "$
			 	   eqprint p$>>
			    else <<terpri()$
				   write "was not successful.">>$
  fnew_:=nil$
  return 
  if succ then {l4,new_cond,allfnew}
          else nil
end$

endmodule$

%*********************************************************************
module gensep_non_lin$
%*********************************************************************
%  Routines for generalized separation of de's
%  Author: Thomas Wolf since 1997

symbolic procedure my_smemberl(p,vl)$
begin scalar l,v;
 for each v in vl do
 if not my_freeof(p,v) then l:=cons(v,l);
 return reverse l
end$

%-----------

symbolic procedure stripcond(conds)$
begin scalar newconds,condi;
 newconds:=nil;
 while conds do <<
  condi:=cdar conds;
  conds:=cdr conds;
  if length condi=1 then condi:=car condi
		    else condi:=cons('plus,condi);
  newconds:=cons(condi,newconds)
 >>;
 return newconds
end$

%-----------

symbolic procedure checkli(exlist,condi)$
begin
 scalar ok,isincondi,isinexli,excopy,n;
 ok:=t;
 while condi and ok do <<
  % all i in the condition car condi
  isincondi:=car condi; %smemberl(ilist,car condi);
  n:=length isincondi;
  % are all isincondi contained in one of the elements of exlist?
  excopy:=exlist;
  while excopy and ok do <<
   isinexli:=smemberl(isincondi,car excopy);
   if isinexli then
   if length(isinexli) = n then ok:=nil;
   excopy:=cdr excopy
  >>;
  condi:=cdr condi
 >>;
 return ok
end$

%-----------

symbolic procedure longst(exlist)$
% returns the element of exlist which (is a list and)
% has the most elements
begin
 scalar lo;
 while exlist do <<
  if not lo then lo:=car exlist else
  if length(lo)<length(car exlist) then lo:=car exlist;
  exlist:=cdr exlist
 >>;
 return lo
end$

%-----------

symbolic procedure starequ(n,alindep,blindep)$
% alindep is a list of lists of factors ai which are all non-zero and
%         are all linear independent from each other within such a list
% blindep like alindep
% generates all cases each with all conditions with _i representing
% ai or bi, equations and new functions are not generated
begin
 COMMENT
  The equation to separate has the form 0 = sum_i ai*bi
  where the bi do not depend on some variable x. The
  procedure starequ generates cases:
  cases          ... ( all cases )
  each case      ... ( list of all a-conditions,
		       list of all b-conditions)
  each condition ... ( the ai,bi contained in the condition
		       with _i representing ai and bi )
 ;
 scalar i,j,cases,oldcases,case,ai,bi,ci,oldaconds,oldbconds,
	newaconds,newbcond,newbconds,newacond,
	ilist,cona,conb,unin,el,pri;  % ,oldpri

 % Determine the longest union of two list, one, ai, being element of
 % alindep and one, bi, being from blindep

 %pri:=t;
 i:=0;
 if alindep then for each cona in alindep do
 if blindep then for each conb in blindep do
 if (j:=length union(cona,conb)) > i then <<ai:=cona;bi:=conb;i:=j>>
				     else
	    else % no blindep given
 if (j:=length cona) > i then <<ai:=cona;i:=j>>
			 else
	    else % no alindep given
 if blindep then for each conb in blindep do
 if (j:=length conb) > i then <<bi:=conb;i:=j>>;

 % ai, bi will now be determined 

 % preparation of the sequence ilist of extensions
 ilist:=for i:=1:n collect i;
 if pri then <<write"222";terpri()>>$
 if i neq 0 then <<
  if ai then i:=length ai else i:=0;
  if bi then j:=length bi else j:=0;

  unin:=union(ai,bi);
  % extensions through bch should be done when elements from
  % bi are treated. This is coded in ilist through negative numbers
  ilist:=setdiff(ilist,unin);

  if i>j then <<
   for each el in setdiff(unin,ai) do ilist:=cons(-el,ilist);
   for each el in ai do ilist:=cons( el,ilist)
  >>     else <<
   for each el in setdiff(unin,bi) do ilist:=cons( el,ilist);
   for each el in bi do ilist:=cons(-el,ilist)
  >>;
  ilist:=reverse ilist
 >>;
 % ilist is prepared now
 if pri then <<write"333 ilist=",ilist;terpri()>>$

 % `cases' is a list of cases, each is a dotted pair with
 % the car being the a-conditions and cdr being the b-conditions
 % The first two cases
 i:=car ilist;
 if i<0 then i:=-i;
 ci:=mkid('_,i);
 cases:=list(list(list(list(ci)),       nil     ),
	     list(     nil      , list(list(ci))) );

% oldpri:=print_;
% print_:=nil;
 ilist:=cdr ilist;
 if pri then <<write"555";terpri()>>$
 while ilist do <<
  i:=car ilist;ilist:=cdr ilist;
  if pri then <<write"iii=",i;terpri()>>$

  if i>0 then ci:=mkid('_, i)
	 else ci:=mkid('_,-i);
  if pri then <<
   write"666 car ilist=",i;
   terpri()
  >>$

  % if i>0 then the list of cases is extended with ai else with bi

  oldcases:=cases;
  cases:=nil;
  while oldcases do <<  % for each old case do:
   case:=car oldcases;
   if pri then <<write"old case:",case;terpri()>>$
   oldcases:=cdr oldcases;
   if i>0 then <<
    oldaconds:=car case;
    if pri then <<write"888 oldaconds=",oldaconds;terpri()>>$
    % at first add condition i=0 to the case
    cases:=cons(cons(cons(list(ci),oldaconds), cdr case) ,
		cases);
    if pri then <<write"999 new case=",car cases;terpri()>>$
    % then: - add to each a-condition i
    %       - add one new b-condition with the first element `i'
    %         and furtherelements which are the first elements of
    %         the a-lists which have been extended
    newaconds:=nil;
    newbcond:=list(ci);
    while oldaconds do <<
     j:=caar oldaconds;
     newaconds:=cons(cons(j,cons(ci,cdar oldaconds)),
		     newaconds);
     newbcond:=cons(j,newbcond);
     oldaconds:=cdr oldaconds
    >>;
    if pri then <<write"newaconds=",newaconds,
		       " rev newbcond=",reverse newbcond;
		  terpri()>>$
    cases:=cons(list(newaconds, cons(reverse newbcond,cadr case)) ,
		cases);
    if pri then <<write"000 new case=",car cases;terpri()>>$
   >>            else <<
    oldbconds:=cadr case;
    if pri then <<write"888 oldbconds=",oldbconds;terpri()>>$
    % at first add condition bi=0 to the case
    cases:=cons(list(car case, cons(list(ci),oldbconds)),
		cases);
    if pri then <<write"999 new case=",car cases;terpri()>>$
    % then: - add to each b-condition i
    %       - add one new a-condition with the first element `i'
    %         and further elements which are the first elements of
    %         the b-lists which have been extended
    newbconds:=nil;
    newacond:=list(ci);
    while oldbconds do <<
     j:=caar oldbconds;
     newbconds:=cons(cons(j,cons(ci,cdar oldbconds)),
		     newbconds);
     newacond:=cons(j,newacond);
     oldbconds:=cdr oldbconds
    >>;
    cases:=cons(list(cons(reverse newacond,car case), newbconds),
		cases);
    if pri then <<write"000 new case=",car cases;terpri()>>$
   >>

  >>;
 >>;

 % Throwing out cases which are forbidden by alindep and blindep
 alindep:=for each ci in alindep collect
          for each i in ci collect mkid('_,i);
 blindep:=for each ci in blindep collect
          for each i in ci collect mkid('_,i);
 oldcases:=nil;
 % ilist:=for i:=1:n collect mkid('_,i);
 while cases do <<
  if checkli(alindep,caar cases%,ilist
) then
  if checkli(blindep,cadar cases%,ilist
) then
  oldcases:=cons(car cases,oldcases);
  cases:=cdr cases
 >>;

% print_:=oldpri;
 return oldcases
end$ % of starequ

%-----------

symbolic procedure pickfac(ex,indx)$
% returns the n'th element of ex where indx has the form _n
nth(ex,compress cdr explode indx)$

%-----------

symbolic procedure find_cond(bcons,ai)$
% find the element of bcons with ai as (automatically first) element
% (there must be an b-condition with ai as first element
% if that has not already been dropped
% because ai is not the first element of the a-condition)
begin
 while (pairp bcons) and (caar bcons neq ai) do bcons:=cdr bcons;
 return if pairp bcons then car bcons
		       else nil
end$

%-----------

symbolic procedure starsep(exx,ex,ftem,vl,x)$
% exx is the original expression to be separated
% ex is a *-expression returned from SEPAR
% vl are all variables which really occur in ex or 
%    on which ex depends on
% x is a variable on which the bi do not depend on
%
% RETURNS a list of cases, each case having the form
% {{new constants/functions of integration},
%  eq1,eq2,eq3,...} 
% where eqi are a set of necc and suff conditions
begin
 scalar cases,newcases,acons,bcons,acond,newca,alindep,blindep,aco,bco,
	ai,bi,ci,a1,avars,bvars,i,ili,cilist,ali,n,addex,bcopy,cntr,
	pri;

% pri:=t;

 ili:=for i:=1:length ex collect mkid('_,i);
 n:=length vl;

 % at first determining lists of non-vanishing and linear independent
 % a-factors alindep and b-factors blindep
 % does so far only the obvious test which is useful essentially for 
 % linear problems
 cntr:=0;
 for each ci in ex do <<
   cntr:=add1 cntr;
   if pri then <<
     write"a",cntr," = "$mathprint car ci$
     write"b",cntr," = "$mathprint cdr ci$
   >>$
   if null smemberl(ftem,car ci) then alindep:=cons(cntr,alindep)$
   if null smemberl(ftem,cdr ci) then blindep:=cons(cntr,blindep)$
 >>;
 if alindep then alindep:=list alindep$
 if blindep then blindep:=list blindep$

 % generation of all logical cases with the factors ai,bi
 % substituted by _i
 cases:=starequ(length ex,alindep,blindep);
 if pri then <<terpri()$write"Returned from STAREQU: ",cases>>;

 % newcases will be the new list of all cases
 newcases:=nil;

 while cases do << 
  % car cases is one case with alltogether n conditions which 
  % The conditions for the a-factors are called below acons
  % and for the b-factors bcons.

  acons:= caar cases;
  bcons:=cadar cases;
  cases:= cdr cases;
  if pri then <<write"acons=",acons,"  bcons=",bcons;terpri()>>$

  % The case will now be formulated with the terms of the expression ex
  newca:=nil;
  cilist:=nil;
  addex:=nil;
  bcopy:=nil;

  % extract at first all b-conditions with only one term as they do not
  % need constants of integration and are used for any grade of ex
  while bcons do <<
   if length car bcons=1 then
   newca:=cons(cdr pickfac(ex,caar bcons),newca)
			 else bcopy:=cons(car bcons,bcopy);
   bcons:=cdr bcons
  >>;
  bcons:=bcopy;

  % The a-factors may depend on all variables vl whereas the
  % b-factors do at least not depend on x.
  while acons do <<   % formulating all a-conditions
   aco:=car acons;    % aco encodes one condition for a-factors
   acons:=cdr acons;
   if pri then <<write"aco=",aco;terpri()>>$

   a1:=car aco;       % e.g. a1 = _7
   acond:=list car pickfac(ex,a1);
   if pri then <<write"acond=",acond;terpri()>>$
   % acond becomes a list of all a-factors encoded by aco

   % adding all a-conditions to the new case newca
   if (length aco)=1 then newca:=cons(car acond,newca)
		     else <<

    ali:=for each i in aco collect car pickfac(ex,i);
    avars:=my_smemberl(ali,vl);
    if length avars neq n then <<
     % The progress in this case is that all new equations will
     % have less variables.
     % Now determination on which variables the constants of back-
     % integration would depend on. This is the intersection of all
     % variables avars in the a-condition and the variables bvars in
     % the b-condition in which the constant of integration occurs. The
     % a-condition is known, it will be made from acond. The relevant
     % b-condition is determined through the current index of aco
     % from which the coefficient is to be determined (which is not the
     % first index of aco)

     aco:=cdr aco;    % a1 already in acond
     while aco do <<
      ai:=car aco;aco:=cdr aco;

      % find the list of variables bvers of the b-condition bco
      % which includes the b-factor corresponding to ai=car aco
      % disadvantage of this way: if bco has m elements then all
      % variables of bco are determined m-1 times.

      % determining bco as the b-condition which contains ai
      bco:=find_cond(bcopy,ai);
      % bcopy is used instead of bcons
      % the condition with ai may already have been dropped from
      % bcons because of ai depending on all variables, i.e. the
      % new functions in the b-conditions would depend on all
      % variables and be no help.

      if pri then <<write"bco=",bco;terpri()>>$
      % bcoli:=smemberl(ili,bco); % in case bco has already had subst.

      % determining bvars
      bvars:=nil;
      for each bi in bco do
      bvars:=union(my_smemberl(cdr pickfac(ex,bi),vl),bvars);
      if pri then <<write"bvars=",bvars$terpri()>>$

      % introducing new constants of integration
      ci:=newfct(fname_,intersection(avars,bvars),nfct_)$
      cilist:=cons(ci,cilist);
      nfct_:=nfct_+1;

      acond:=cons(list('minus,list('times,ci,car pickfac(ex,ai))),acond);
      if pri then <<write"acond=",acond;terpri()>>$

      if bco:=find_cond(bcons,ai) then <<
       bcons:=subst(subst(list('times,ci,a1),a1,bco),bco,bcons);
       if pri then <<write"bcons=",bcons;terpri()>>$
      >>

     >>;
     acond:=cons('plus,acond)

    >>
	       else << % The condition aco is a *-condition
     % progress in this case is that new a-conditions
     % have less functions
     addex:=t;
     ali:=reverse ali;
     aco:=reverse aco;
     while length ali > 1 do <<
      if pri then <<write"ali1=",ali;terpri()>>$
      % Generate the a-condition
      if pri then <<write"###";terpri()>>$

      ali:=
      if not zerop car ali then
      for each i in cdr ali collect
      reval list('df,list('quotient,i,car ali),x)
			   else cdr ali;
      if pri then <<write"ali2=",ali;terpri()>>$

      % Drop that element from bcons which includes
      % car ali (as first element)
      if bco:=find_cond(bcons,car aco) then 
      bcons:=setdiff(bcons,list bco);
      aco:=cdr aco

     >>;
     acond:=car ali;
     if (pairp acond) and (car acond = 'quotient) then
     acond:=cadr acond;

    >>;

    newca:=cons(acond,newca)

   >>;
   if pri then <<write"newca1=",newca;terpri()>>;
  >>;  % all a-conditions have been dealt with
  if pri then <<write"newca2=",newca;terpri()>>;

  % completing all b-conditions
  for each bi in ili do bcons:=subst(cdr pickfac(ex,bi),bi,bcons);

  % adding all b-conditions to the new case newca
  while bcons do <<
   if length car bcons = 1 then newca:=cons(caar bcons,newca)
			   else newca:=cons(cons('plus,car bcons),
						 newca);
   bcons:=cdr bcons
  >>;
  % if ex is an *-expression with grade>1 then possibly b-conditions
  % had to be dropped, so ex must be added
  if addex then newca:=cons(exx,newca);

  if pri then <<write"newca3=",newca;terpri()>>;

  % adding the list of constants of integeration
  newca:=cons(cilist,newca);
  if pri then <<write"cilist=",cilist;terpri()>>;

  newcases:=cons(newca,newcases)
 >>;
 return newcases
end$ % of starsep

%-----------

symbolic procedure separizable(p,ftem,vl)$
begin scalar x,ft,f,ex,v,a,b,vlcp,allvarcaara,print_bak$
  vlcp:=vl;
  repeat <<
    x:=car vl;  vl:=cdr vl;
     % Determining all x-dependent functions ft
    ft:=nil;
    for each f in ftem do
    if member(x,fctargs f) and
       not my_freeof(p,f) then ft:=cons(f,ft)$
    % ft are the x-depending functions in p which one needs to get rid of
    % if one wants to separate directly wrt. x

    f:=car reverse fctsort ft$     % sorting wrt. number of args
    v:=car setdiff(vlcp,fctargs f)$  % getting rid of f by v-differen.

    % preparation of the separ-call, ft are now v-indep. functions
    ft:=nil$
    for each f in ftem do if my_freeof(f,v) then ft:=cons(f,ft)$
    print_bak:=print_;  print_:=nil;
%   ex:=separ (p,ft,list v,nil)$ % det. all lin. ind. factors
    ex:=separ2(p,ft,list v)$     % det. all lin. ind. factors
    print_:=print_bak;
    a:=ex;

    while a and <<
      b:=vlcp;
      while b and not my_freeof(caar a,car b) do b:=cdr b;
      b
    >> do a:=cdr a;
    if a then allvarcaara:=cons(caar a,allvarcaara);

  >> until (null a) or (null vl);
  % if a then null vl then whatever x was, there is allways one
  % element (car a) of ex such that car of this element (caar a)
  % does depend on all variables --> no separability possible,
  % new functions would depend on all variables
  
  % if a then test whether separation would be possible by getting
  % rid of functions through differentiation 
  % (this would not be the case if e.g. sin(all variables) would occur)
  % --> use of smemberl

  vl:=vlcp;
  while allvarcaara and not not_included(vlcp,smemberl(vlcp,car allvarcaara)) do
  <<allvarcaara:=cdr allvarcaara; vl:=cdr vl>>$

  return if a and null allvarcaara then nil          % no chance
         else if a then {nil,car allvarcaara,car vl} % deleting functions first
                   else <<                           % separation now possible
    if tr_gensep then
    <<terpri()$write "To separate directly wrt. ",x$
      write " the expression : "$deprint list p$
      write "will be differentiated wrt. ",v," to get rid of ",ft," ">>$
    {ex,v}
  >>
end$

%-----------

symbolic procedure newgensep(p,starpro,ftem,vl)$
% ftem, vl should be correct:
% ftem:=smemberl(ftem_,p)$
% vl:=varslist(p,ftem,vl)$
% starpro:=stardep(ftem,vl)$
%    returns what starsep returns
begin 
scalar pl,v,ex,a,b$
%            ,gense,el1,el2,conds,newcali,l,clist$
%  if pairp p and (car p = 'QUOTIENT) then <<casecheck(caddr p,vl)$
%                                            p:=cadr p>>$
%  ftem:=smemberl(ftem,p)$
%  vl:=varslist(p,ftem,vl)$
%  if not (starpro:=stardep(ftem,vl)) then % then no *-equation
%  pl:=list list(nil,p)              % one case, no new functions
%			       else % e.g. starpro=((x y z).2)
%  if zerop cdr starpro then pl:=nil% ##############################
%                  %list cons(nil,separate(p,ftem,vl)) % direct sep
%		 else                 
%  if delength(p) leq gensep_ then   % generalized separation
%  <<
    if print_ then <<terpri()$write "generalized separation ">>$
    if tr_gensep then
    <<terpri()$write "de to be separated : "$
      deprint list p$
      terpri()$write "variable list for separation : ",car starpro$
      terpri()$write "for each of these variables ",cdr starpro,
		     " function(s) depend(s) on it.">>$

    for each v in car starpro do vl:=delete(v,vl);
    vl:=append(car starpro,vl);

    a:=separizable(p,ftem,vl)$
    if null a then return nil else 
    if null car a then return <<
      % functions to be deleted before separation are those in cadr a
      % ft:=smemberl(ftem,cadr a);
      if print_ then <<terpri()$
        write"In order to be separable with this procedure at first"$terpri()$
        write"one or more functions have to be eliminated through"$terpri()$
        write"differentiation and algebraic elimination, for example,"$terpri()$
        write"the functions: ",smemberl(ftem,cadr a)$terpri()$
      >>;
      nil
    >>            else <<ex:=car a;v:=cadr a>>$

    for each a in 
      rev_idx_sort for each b in ex collect cons(delength car b,b)
    collect cdr a$

    if tr_gensep then
    <<terpri()$write "Return from SEPAR: "$terpri()$prettyprint ex>>$

    % with v and v-dep. functions as first factors in the terms in ex
    pl:=starsep(p,ex,ftem,vl,v);
    if tr_gensep then
    <<terpri()$write "Return from STARSEP: "$terpri()$prettyprint pl>>$
%    print_:=oldpri$

%%############################################################
%    % l is a list of cases each (list of new fncts, cond1, cond2, ...)
%    % for each condition (neq p) in all cases calling gensep again
%    % if needed
%    pl:=nil;           % the final list of cases of only non-*-equ.
%    while l do         % checking all cases
%    <<clist:=caar l;   % list of new functions
%      conds:=cdar l;   % list of conditions
%      l:=cdr l;
%      newcali:=list list clist;
%      % newcali will be the list of new cases which starts as
%      % only one case and from this only the list of new functions
%      % but no conditions
%      while conds do % checking all conditions of one case
%      <<
%%        if car conds = ex then
%%        % ex aready investigated, not again
%%        % append ex to the conditions of all new cases
%%        newcali:=for each el1 in newcali collect
%%                 cons(car el1,cons(ex,cdr el1))
%%                          else <<
%          gense:=newgensep(car conds,append(ftem,clist),vl);
%          newcali:=for each el1 in gense join
%                   for each el2 in newcali collect
%                   cons(append(car el1,car el2),
%                        append(cdr el1,cdr el2));
%%        >>; 
%        conds:=cdr conds
%      >>;
%      pl:=append(newcali,pl)
%    >>
%  >>;
  return pl
end$ % of newgensep

%-----------

symbolic procedure gen_separation2(arglist)$
% Indirect separation of a pde, 2nd version for non-linear PDEs
begin scalar p,h,fl,l,l1,pdes,forg,n,result,d,contrad,newpdes$%,newfdep,bak,sol
  pdes:=car arglist$
  forg:=cadr arglist$
  if expert_mode then <<
    l1:=selectpdes(pdes,1);
    if get(car l1,'starde) then flag(l1,'to_gensep)
  >>             else l1:=pdes$
  if (p:=get_gen_separ_pde(l1,nil,nil)) then
  if <<
   cp_sq2p_val(p)$                       % #?# not in future version
   l:=newgensep(get(p,'pval),            % #?# sqval in future version
                get(p,'starde),
                get(p,'fcts),
                get(p,'vars)) 
  >> then
  if cdr l then << % more than one case
   if print_ then <<
    terpri()$
    write"The indirect separation leads to ",length l," cases."$terpri()$
    if keep_case_tree then <<
     write"Comment: The case tree can no longer be updated."$terpri()$
     keep_case_tree:=nil
    >>
   >>$
   contrad:=t$
   n:=0;
   remflag1(p,'to_gensep)$
   backup_to_file(pdes,forg,nil)$
   while l do <<
    d:=car l; l:=cdr l;
    if not memberl(cdr d,ineq_) then << % non of the equations is an inequality
     if n neq 0 then <<
      h:=restore_and_merge(l1,pdes,forg)$
      pdes:= car h; 
      forg:=cadr h; % was not assigned above as it has not changed probably
     >>;
     n:=n+1$
     start_level(n,list {'equal,0,cdr d})$
     if print_ then <<
      terpri()$
      write "CRACK is now called with the assumption : "$
      deprint(cdr d)
     >>$
     % formulation of new equations
     for each h in car d do <<
       ftem_:=fctinsert(h,ftem_);
       flin_:=cons(h,flin_)
     >>$
     flin_:=sort_according_to(flin_,ftem_);
     fl:=append(get(p,'fcts),car d);
     newpdes:=pdes$
     for each h in cdr d do 
     newpdes:=eqinsert(mkeqsq(nil,nil,h,fl,vl_,allflags_,t,list(0),nil,newpdes),newpdes); % #?#
     % further necessary step to call crackmain():
     recycle_fcts:=nil$  % such that functions generated in the sub-call 
                         % will not clash with existing functions
     if contradiction_ then <<l1:=nil;finish_level(0)>> 
                       else l1:=crackmain_if_possible_remote(newpdes,forg)$
     if not contradiction_ then contrad:=nil$ 
     if l1 and not contradiction_ then
        result:=merge_crack_returns(l1,result);
     contradiction_:=nil$                   

    >>
   >>;
   delete_backup()$
   contradiction_:=contrad$ 
   if contradiction_ then result:=nil$
   if print_ then <<
    terpri()$
    write"This completes the investigation of all cases of an ",
         "indirect separation."$
    terpri()$
   >>$
   result:=list result % to tell crackmain that computation is completed
  >>       else <<     % only one case
   l:=car l;
   for each h in car l do <<
     ftem_:=fctinsert(h,ftem_);
     flin_:=cons(h,flin_)
   >>;
   flin_:=sort_according_to(flin_,ftem_);

   fl:=append(get(p,'fcts),car l);
   pdes:=drop_pde(p,pdes,nil)$
   for each h in cdr l do 
%  pdes:=eqinsert(mkeq  (        h,fl,vl_,allflags_,t,list(0),nil,pdes),pdes);
   pdes:=eqinsert(mkeqsq(nil,nil,h,fl,vl_,allflags_,t,list(0),nil,pdes),pdes); % #?# 
   result:=list(pdes,forg)
  >>$
  return result$
end$

endmodule$

end$
%-----------------------------------------------------
% Having non-Reduce input at the end of a file even after "end$" causes trouble
% for simple source analysis tools.
%
%module gensep_lin:
%
%quick_gen_separation  (10)
%  get_gen_separ_pde
%    maxnoargs
%  gensep
%  eqinsert
%
%case_gen_separation   (30.4.2013: currently listed as module but not listed in full_proc_list_)
%  gen_separation
%
%gen_separation        (26)
%  get_gen_separ_pde
%  gensep
%  eqinsert
%
%gensep
%  cp_sq2p_val
%  partitn
%  mkeqSQlist
%
%module gensep_non_lin:
%
%gen_separation2       (48)
%  newgensep
%    separizable
%      separ2
%        sep(p,ftem,varl,nil,nil)$   (in linear case sep(p,ftem,varl,nonrat,pdes) )
%  eqinsert
%
%------------------------------------------------------
%
%module gensep_lin:
%
%tr quick_gen_separation
%tr case_gen_separation
%tr gen_separation
%tr maxnoargs
%tr get_gen_separ_pde
%tr gensep
%tr partitn
%tr felim
%tr backint
%tr separ
%
%tr my_smemberl
%tr stripcond
%tr checkli
%tr longst
%tr starequ
%tr pickfac
%tr find_cond
%tr starsep
%tr separizable
%tr newgensep
%tr gen_separation2
%tr separ2
%

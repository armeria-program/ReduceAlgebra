%
% catch/throw are expected to throuw even through an errorset...
%
% $Id: catchtest.red 2277 2014-01-06 10:33:50Z arthurcnorman $

lisp;
on comp,echo;

symbolic procedure dothrow n;
  if n = 0 then throw('throwtag, 'throwvalue)
  else <<
    print list('depth, n);
    dothrow(n-1);
    'should_never_return_this >>;

symbolic procedure errorset_protect();
  begin
    scalar r;
    printc "About to errorset";
    r := errorset('(dothrow 5), t, t);
    print list('erroset, 'value, r);
    return r
  end;

symbolic procedure trycatch();
  catch('throwtag, errorset_protect());

trycatch();

end;
